import 'dart:convert';
import 'dart:io';

const String _defaultRoot = 'assets/data';
const List<String> _defaultLanguages = ['en', 'tr', 'zh'];
const String _globalChampionListPath = 'global/champions.json';

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

  final championIds = await _readChampionIds(options.rootPath);
  if (championIds.isEmpty) {
    stderr.writeln('No champion ids found in $_globalChampionListPath');
    exitCode = 1;
    return;
  }

  final globalBundle = await _buildBundle(
    rootPath: options.rootPath,
    folder: 'global',
    championIds: championIds,
  );

  await _writeBundle(
    rootPath: options.rootPath,
    folder: 'global',
    bundle: globalBundle,
  );

  for (final languageCode in options.languages) {
    final localizedBundle = await _buildBundle(
      rootPath: options.rootPath,
      folder: languageCode,
      championIds: championIds,
    );

    await _writeBundle(
      rootPath: options.rootPath,
      folder: languageCode,
      bundle: localizedBundle,
    );
  }

  stdout.writeln(
    'Champion bundles generated for global and languages: ${options.languages.join(', ')}',
  );
}

Future<List<String>> _readChampionIds(String rootPath) async {
  final file = File(
    '$rootPath${Platform.pathSeparator}$_globalChampionListPath',
  );
  if (!await file.exists()) {
    throw Exception('Missing champion list: ${file.path}');
  }

  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! List) {
    throw const FormatException('global/champions.json must be a JSON array');
  }

  final ids = decoded
      .map((value) => value.toString().trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList();

  final uniqueCount = ids.toSet().length;
  if (uniqueCount != ids.length) {
    throw const FormatException('global/champions.json has duplicate ids');
  }

  return ids;
}

Future<Map<String, dynamic>> _buildBundle({
  required String rootPath,
  required String folder,
  required List<String> championIds,
}) async {
  final bundle = <String, dynamic>{};

  for (final championId in championIds) {
    final file = File(
      '$rootPath${Platform.pathSeparator}$folder${Platform.pathSeparator}champions${Platform.pathSeparator}$championId.json',
    );

    if (!await file.exists()) {
      throw Exception('Missing champion file: ${file.path}');
    }

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid JSON object in ${file.path}');
    }

    final jsonId = decoded['id']?.toString().trim().toLowerCase();
    if (jsonId != championId) {
      throw FormatException(
        'Champion id mismatch in ${file.path}. Expected "$championId", got "$jsonId"',
      );
    }

    bundle[championId] = decoded;
  }

  return bundle;
}

Future<void> _writeBundle({
  required String rootPath,
  required String folder,
  required Map<String, dynamic> bundle,
}) async {
  final file = File(
    '$rootPath${Platform.pathSeparator}$folder${Platform.pathSeparator}champion_bundle.json',
  );

  final encoder = const JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(bundle)}\n');
}

_Options _parseArgs(List<String> args) {
  var rootPath = _defaultRoot;
  var showHelp = false;
  List<String>? languages;

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
        final raw = args[++i].split(',');
        languages = raw
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

  return _Options(
    rootPath: rootPath,
    languages: languages ?? _defaultLanguages,
    showHelp: showHelp,
  );
}

void _printUsage() {
  stdout.writeln('Generate runtime champion bundles from per-champion files.');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run tool/generate_champion_bundles.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --root <path>          Data root directory (default: $_defaultRoot)',
  );
  stdout.writeln(
    '  --languages <codes>    Comma-separated languages (default: en,tr,zh)',
  );
  stdout.writeln('  --help, -h             Show help');
}

class _Options {
  const _Options({
    required this.rootPath,
    required this.languages,
    required this.showHelp,
  });

  final String rootPath;
  final List<String> languages;
  final bool showHelp;
}
