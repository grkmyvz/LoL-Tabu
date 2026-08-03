import 'dart:convert';
import 'dart:io';

const List<String> _defaultLanguages = ['en', 'tr', 'zh'];

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);

  if (options.showHelp) {
    _printUsage();
    return;
  }

  final rootDir = Directory(options.rootPath);
  if (!await rootDir.exists()) {
    stderr.writeln('Data root not found: ${options.rootPath}');
    exitCode = 1;
    return;
  }

  final reporter = _AuditReporter();
  final masterIds = await _readMasterChampionIds(
    reporter: reporter,
    rootPath: options.rootPath,
  );
  final masterNormalized = masterIds.map(_normalizeChampionId).toList();
  final masterSet = masterNormalized.toSet();

  reporter.section('Master list');
  reporter.info('global/champions.json entries: ${masterIds.length}');
  reporter.info('Unique canonical ids: ${masterSet.length}');

  await _auditPubspecAssetDeclarations(
    reporter: reporter,
    languages: options.languages,
  );

  await _auditGlobalDirectory(
    reporter: reporter,
    rootPath: options.rootPath,
    masterIds: masterIds,
    masterSet: masterSet,
  );

  for (final languageCode in options.languages) {
    await _auditLanguageDirectory(
      reporter: reporter,
      rootPath: options.rootPath,
      languageCode: languageCode,
      masterIds: masterIds,
      masterSet: masterSet,
    );
  }

  reporter.finish();
  exitCode = reporter.hasErrors ? 1 : 0;
}

Future<List<String>> _readMasterChampionIds({
  required _AuditReporter reporter,
  required String rootPath,
}) async {
  final file = File(
    '$rootPath${Platform.pathSeparator}global${Platform.pathSeparator}champions.json',
  );
  if (!await file.exists()) {
    reporter.error('Missing master champion list: ${file.path}');
    return const [];
  }

  final decoded = await _readJson(file, reporter);
  if (decoded is! List) {
    reporter.error(
      'global/champions.json must be a JSON array of champion names.',
    );
    return const [];
  }

  final ids = <String>[];
  for (var i = 0; i < decoded.length; i++) {
    final value = decoded[i];
    if (value is! String || value.trim().isEmpty) {
      reporter.error(
        'global/champions.json entry at index $i is not a valid string.',
      );
      continue;
    }
    ids.add(value.trim());
  }

  final duplicates = _findDuplicates(ids.map(_normalizeChampionId));
  if (duplicates.isNotEmpty) {
    reporter.warn(
      'Duplicate canonical champion ids in master list: ${duplicates.join(', ')}',
    );
  }

  return ids;
}

Future<void> _auditGlobalDirectory({
  required _AuditReporter reporter,
  required String rootPath,
  required List<String> masterIds,
  required Set<String> masterSet,
}) async {
  final directoryPath =
      '$rootPath${Platform.pathSeparator}global${Platform.pathSeparator}champions';
  await _auditDirectory(
    reporter: reporter,
    label: 'global/champions',
    directoryPath: directoryPath,
    expectedIds: masterSet,
    expectedFileCount: masterIds.length,
    fileType: _ChampionFileType.global,
    rootPath: rootPath,
  );

  await _auditIndexFile(
    reporter: reporter,
    indexPath:
        '$rootPath${Platform.pathSeparator}global${Platform.pathSeparator}index.json',
    label: 'global/index.json',
    expectedIds: masterSet,
    directoryPrefix: 'champions/',
  );
}

Future<void> _auditPubspecAssetDeclarations({
  required _AuditReporter reporter,
  required List<String> languages,
}) async {
  const pubspecPath = 'pubspec.yaml';
  final pubspecFile = File(pubspecPath);

  reporter.section('pubspec assets');

  if (!await pubspecFile.exists()) {
    reporter.warn(
      'pubspec.yaml not found. Asset declaration checks were skipped.',
    );
    return;
  }

  final declaredAssets = await _readFlutterAssetEntries(pubspecFile);
  if (declaredAssets.isEmpty) {
    reporter.error('No flutter assets found in pubspec.yaml.');
    return;
  }

  final requiredAssets = <String>{
    'assets/data/global/champions.json',
    'assets/data/global/index.json',
    'assets/data/global/champions/',
  };

  for (final languageCode in languages) {
    requiredAssets.add('assets/data/$languageCode/index.json');
    requiredAssets.add('assets/data/$languageCode/champions/');
  }

  final missing =
      requiredAssets.where((asset) => !declaredAssets.contains(asset)).toList()
        ..sort();

  if (missing.isEmpty) {
    reporter.info('Required data assets are declared in pubspec.yaml.');
  } else {
    reporter.error(
      'Missing pubspec asset declarations (${missing.length}): ${missing.join(', ')}',
    );
  }
}

Future<Set<String>> _readFlutterAssetEntries(File pubspecFile) async {
  final lines = await pubspecFile.readAsLines();
  final assets = <String>{};

  var inFlutter = false;
  var inAssets = false;
  var flutterIndent = 0;
  var assetsIndent = 0;

  for (final rawLine in lines) {
    final trimmed = rawLine.trim();
    final indent = rawLine.length - rawLine.trimLeft().length;

    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    if (!inFlutter) {
      if (trimmed == 'flutter:') {
        inFlutter = true;
        flutterIndent = indent;
      }
      continue;
    }

    if (indent <= flutterIndent && !trimmed.startsWith('-')) {
      inFlutter = false;
      inAssets = false;
      continue;
    }

    if (!inAssets) {
      if (trimmed == 'assets:') {
        inAssets = true;
        assetsIndent = indent;
      }
      continue;
    }

    if (indent <= assetsIndent && !trimmed.startsWith('-')) {
      inAssets = false;
      continue;
    }

    if (trimmed.startsWith('- ')) {
      var path = trimmed.substring(2).trim();
      if ((path.startsWith('"') && path.endsWith('"')) ||
          (path.startsWith('\'') && path.endsWith('\''))) {
        path = path.substring(1, path.length - 1);
      }

      if (path.isNotEmpty) {
        assets.add(path);
      }
    }
  }

  return assets;
}

Future<void> _auditLanguageDirectory({
  required _AuditReporter reporter,
  required String rootPath,
  required String languageCode,
  required List<String> masterIds,
  required Set<String> masterSet,
}) async {
  final directoryPath =
      '$rootPath${Platform.pathSeparator}$languageCode${Platform.pathSeparator}champions';
  await _auditDirectory(
    reporter: reporter,
    label: '$languageCode/champions',
    directoryPath: directoryPath,
    expectedIds: masterSet,
    expectedFileCount: masterIds.length,
    fileType: _ChampionFileType.localized,
    rootPath: rootPath,
  );

  await _auditIndexFile(
    reporter: reporter,
    indexPath:
        '$rootPath${Platform.pathSeparator}$languageCode${Platform.pathSeparator}index.json',
    label: '$languageCode/index.json',
    expectedIds: masterSet,
    directoryPrefix: 'champions/',
  );
}

Future<void> _auditDirectory({
  required _AuditReporter reporter,
  required String label,
  required String directoryPath,
  required Set<String> expectedIds,
  required int expectedFileCount,
  required _ChampionFileType fileType,
  required String rootPath,
}) async {
  final directory = Directory(directoryPath);
  if (!await directory.exists()) {
    reporter.error('Missing directory: $label');
    return;
  }

  final files =
      directory
          .listSync(followLinks: false)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.json'))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  reporter.section(label);
  reporter.info('JSON files found: ${files.length}');
  reporter.info('Expected champion count: $expectedFileCount');

  final seenIds = <String>{};
  final fileIds = <String>{};

  for (final file in files) {
    final result = await _auditChampionFile(
      reporter: reporter,
      file: file,
      fileType: fileType,
      rootPath: rootPath,
    );

    if (result == null) {
      continue;
    }

    final normalizedId = _normalizeChampionId(result.id);
    fileIds.add(normalizedId);

    if (!seenIds.add(normalizedId)) {
      reporter.error(
        'Duplicate champion id in $label: ${result.id} (${_relativePath(rootPath, file.path)})',
      );
    }

    if (!expectedIds.contains(normalizedId)) {
      reporter.warn(
        'Unexpected champion not present in global/champions.json: ${result.id} (${_relativePath(rootPath, file.path)})',
      );
    }

    final expectedFileName = '$normalizedId.json';
    final actualFileName = file.uri.pathSegments.last.toLowerCase();
    if (actualFileName != expectedFileName) {
      reporter.error(
        'File name/id mismatch in $label: ${_relativePath(rootPath, file.path)} expects $expectedFileName for id ${result.id}',
      );
    }
  }

  final missing = expectedIds.difference(fileIds).toList()..sort();
  final extras = fileIds.difference(expectedIds).toList()..sort();

  if (missing.isEmpty) {
    reporter.info('Missing champions: none');
  } else {
    reporter.error(
      'Missing champions (${missing.length}): ${missing.join(', ')}',
    );
  }

  if (extras.isEmpty) {
    reporter.info('Extra champions: none');
  } else {
    reporter.warn('Extra champions (${extras.length}): ${extras.join(', ')}');
  }
}

Future<void> _auditIndexFile({
  required _AuditReporter reporter,
  required String indexPath,
  required String label,
  required Set<String> expectedIds,
  required String directoryPrefix,
}) async {
  final file = File(indexPath);
  if (!await file.exists()) {
    reporter.error('Missing index file: $label');
    return;
  }

  final decoded = await _readJson(file, reporter);
  if (decoded is! List) {
    reporter.error('$label must be a JSON array of file paths.');
    return;
  }

  final entries = <String>[];
  final entryIds = <String>{};

  for (var i = 0; i < decoded.length; i++) {
    final value = decoded[i];
    if (value is! String || value.trim().isEmpty) {
      reporter.error('$label entry at index $i is not a valid string.');
      continue;
    }

    final normalizedEntry = value.trim().replaceAll('\\', '/');
    entries.add(normalizedEntry);

    if (!normalizedEntry.startsWith(directoryPrefix)) {
      reporter.error(
        '$label entry at index $i does not start with $directoryPrefix: $normalizedEntry',
      );
      continue;
    }

    final fileName = normalizedEntry.split('/').last;
    if (!fileName.toLowerCase().endsWith('.json')) {
      reporter.error(
        '$label entry at index $i is not a json file: $normalizedEntry',
      );
      continue;
    }

    final championId = fileName.substring(0, fileName.length - 5);
    entryIds.add(_normalizeChampionId(championId));
  }

  final duplicates = _findDuplicates(entries);
  if (duplicates.isNotEmpty) {
    reporter.warn('Duplicate paths in $label: ${duplicates.join(', ')}');
  }

  reporter.info('$label entries: ${entries.length}');

  final missing = expectedIds.difference(entryIds).toList()..sort();
  final extras = entryIds.difference(expectedIds).toList()..sort();

  if (missing.isEmpty) {
    reporter.info('$label missing references: none');
  } else {
    reporter.error(
      '$label missing references (${missing.length}): ${missing.join(', ')}',
    );
  }

  if (extras.isEmpty) {
    reporter.info('$label unexpected references: none');
  } else {
    reporter.warn(
      '$label unexpected references (${extras.length}): ${extras.join(', ')}',
    );
  }
}

Future<_ChampionFileAudit?> _auditChampionFile({
  required _AuditReporter reporter,
  required File file,
  required _ChampionFileType fileType,
  required String rootPath,
}) async {
  final relativePath = _relativePath(rootPath, file.path);
  final decoded = await _readJson(file, reporter);
  if (decoded == null) {
    return null;
  }

  if (decoded is! Map<String, dynamic>) {
    reporter.error(
      '$relativePath must contain a single JSON object, not ${decoded.runtimeType}.',
    );
    return null;
  }

  if (fileType == _ChampionFileType.global) {
    return _auditGlobalChampionObject(reporter, decoded, relativePath);
  }

  return _auditLocalizedChampionObject(reporter, decoded, relativePath);
}

Future<dynamic> _readJson(File file, _AuditReporter reporter) async {
  try {
    return jsonDecode(await file.readAsString());
  } catch (error) {
    reporter.error('Failed to parse ${file.path}: $error');
    return null;
  }
}

_ChampionFileAudit? _auditGlobalChampionObject(
  _AuditReporter reporter,
  Map<String, dynamic> data,
  String relativePath,
) {
  final requiredStrings = ['id', 'imageSlug', 'key', 'name'];
  for (final field in requiredStrings) {
    final value = data[field];
    if (value is! String || value.trim().isEmpty) {
      reporter.error('$relativePath missing or invalid $field string.');
    }
  }

  final id = data['id']?.toString().trim() ?? '';
  final skins = data['skins'];

  if (skins is! List) {
    reporter.error('$relativePath skins must be a JSON array.');
  } else {
    if (skins.isEmpty) {
      reporter.warn('$relativePath has no skins.');
    }

    final seenSkinNums = <int>{};
    var hasDefaultSkin = false;

    for (var i = 0; i < skins.length; i++) {
      final skin = skins[i];
      if (skin is! Map<String, dynamic>) {
        reporter.error('$relativePath skins[$i] must be an object.');
        continue;
      }

      final skinId = skin['id'];
      final skinNum = skin['num'];
      final skinName = skin['name'];
      final chromas = skin['chromas'];

      if (skinId is! String || skinId.trim().isEmpty) {
        reporter.error(
          '$relativePath skins[$i].id must be a non-empty string.',
        );
      }

      final parsedNum = skinNum is int
          ? skinNum
          : int.tryParse(skinNum?.toString() ?? '');
      if (parsedNum == null) {
        reporter.error('$relativePath skins[$i].num must be an integer.');
      } else {
        if (!seenSkinNums.add(parsedNum)) {
          reporter.warn('$relativePath has duplicate skin num $parsedNum.');
        }
        if (parsedNum == 0) {
          hasDefaultSkin = true;
        }
      }

      if (skinName is! String || skinName.trim().isEmpty) {
        reporter.error(
          '$relativePath skins[$i].name must be a non-empty string.',
        );
      }

      if (chromas is! bool) {
        reporter.error('$relativePath skins[$i].chromas must be a boolean.');
      }
    }

    if (!hasDefaultSkin) {
      reporter.warn(
        '$relativePath does not contain a default skin with num 0.',
      );
    }
  }

  if (id.isEmpty) {
    reporter.error('$relativePath has empty id.');
  }

  return _ChampionFileAudit(id: id, relativePath: relativePath);
}

_ChampionFileAudit? _auditLocalizedChampionObject(
  _AuditReporter reporter,
  Map<String, dynamic> data,
  String relativePath,
) {
  final id = data['id']?.toString().trim() ?? '';
  final forbiddenWords = data['forbiddenWords'];

  if (id.isEmpty) {
    reporter.error('$relativePath missing or invalid id string.');
  }

  if (forbiddenWords is! List) {
    reporter.error('$relativePath forbiddenWords must be a JSON array.');
  } else {
    if (forbiddenWords.length != 5) {
      reporter.error(
        '$relativePath must contain exactly 5 forbiddenWords, found ${forbiddenWords.length}.',
      );
    }

    final normalizedWords = <String>[];
    for (var i = 0; i < forbiddenWords.length; i++) {
      final word = forbiddenWords[i];
      if (word is! String || word.trim().isEmpty) {
        reporter.error(
          '$relativePath forbiddenWords[$i] must be a non-empty string.',
        );
        continue;
      }
      normalizedWords.add(word.trim());
    }

    final duplicateWords = _findDuplicates(normalizedWords);
    if (duplicateWords.isNotEmpty) {
      reporter.warn(
        '$relativePath contains duplicate forbidden words: ${duplicateWords.join(', ')}',
      );
    }
  }

  return _ChampionFileAudit(id: id, relativePath: relativePath);
}

List<String> _findDuplicates(Iterable<String> values) {
  final seen = <String>{};
  final duplicates = <String>{};

  for (final value in values) {
    if (!seen.add(value)) {
      duplicates.add(value);
    }
  }

  final result = duplicates.toList()..sort();
  return result;
}

String _normalizeChampionId(String value) {
  return value.trim().toLowerCase();
}

String _relativePath(String rootPath, String absolutePath) {
  final normalizedRoot = rootPath.replaceAll('\\', '/');
  final normalizedAbsolute = absolutePath.replaceAll('\\', '/');
  if (normalizedAbsolute.startsWith('$normalizedRoot/')) {
    return normalizedAbsolute.substring(normalizedRoot.length + 1);
  }
  return normalizedAbsolute;
}

void _printUsage() {
  stdout.writeln(
    'Audit champion data and report consistency issues without modifying files.',
  );
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run tool/audit_champion_data.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --root <path>        Data root directory (default: assets/data)',
  );
  stdout.writeln(
    '  --languages <list>   Comma-separated languages to audit (default: en,tr,zh)',
  );
  stdout.writeln('  --help, -h           Show help');
}

_AuditOptions _parseArgs(List<String> args) {
  var rootPath = 'assets/data';
  var languages = List<String>.from(_defaultLanguages);
  var showHelp = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--root':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --root');
        }
        rootPath = args[++i];
        break;
      case '--languages':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --languages');
        }
        languages = args[++i]
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList();
        break;
      case '--help':
      case '-h':
        showHelp = true;
        break;
      default:
        throw ArgumentError('Unknown argument: $arg');
    }
  }

  if (languages.isEmpty) {
    languages = List<String>.from(_defaultLanguages);
  }

  return _AuditOptions(
    rootPath: rootPath,
    languages: languages,
    showHelp: showHelp,
  );
}

enum _ChampionFileType { global, localized }

class _AuditOptions {
  const _AuditOptions({
    required this.rootPath,
    required this.languages,
    required this.showHelp,
  });

  final String rootPath;
  final List<String> languages;
  final bool showHelp;
}

class _AuditReporter {
  final List<String> _lines = [];
  var _errorCount = 0;
  var _warnCount = 0;

  bool get hasErrors => _errorCount > 0;

  void section(String title) {
    _lines.add('');
    _lines.add('== $title ==');
  }

  void info(String message) {
    _lines.add('[OK] $message');
  }

  void warn(String message) {
    _warnCount++;
    _lines.add('[WARN] $message');
  }

  void error(String message) {
    _errorCount++;
    _lines.add('[ERROR] $message');
  }

  void finish() {
    _lines.add('');
    _lines.add('Summary: errors=$_errorCount, warnings=$_warnCount');
    stdout.writeln(_lines.join('\n'));
  }
}

class _ChampionFileAudit {
  const _ChampionFileAudit({required this.id, required this.relativePath});

  final String id;
  final String relativePath;
}
