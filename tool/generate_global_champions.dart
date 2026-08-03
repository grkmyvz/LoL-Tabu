import 'dart:convert';
import 'dart:io';

const String _defaultVersion = '16.15.1';
const String _defaultInputPath = 'assets/data/global/champions.json';
const String _defaultOutputDir = 'assets/data/global/champions';

const Map<String, String> _ddragonAliases = {
  'Ksante': 'KSante',
  'Wukong': 'MonkeyKing',
};

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options.showHelp) {
    _printUsage();
    return;
  }

  final inputPath = options.inputPath ?? _defaultInputPath;
  final outputDirPath = options.outputDir ?? _defaultOutputDir;
  final version = options.version ?? _defaultVersion;

  final inputFile = File(inputPath);
  if (!await inputFile.exists()) {
    stderr.writeln('Input file not found: $inputPath');
    exitCode = 1;
    return;
  }

  final outputDir = Directory(outputDirPath);
  await outputDir.create(recursive: true);

  final championsRaw = await inputFile.readAsString();
  final championsDecoded = jsonDecode(championsRaw);
  if (championsDecoded is! List) {
    stderr.writeln('Input JSON must be an array of champion ids.');
    exitCode = 1;
    return;
  }

  final championIds = championsDecoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();

  if (championIds.isEmpty) {
    stdout.writeln('No champions found in $inputPath');
    return;
  }

  final client = HttpClient();
  final succeeded = <String>[];
  final failed = <String>[];

  try {
    for (final champion in championIds) {
      final outputChampionId = champion.toLowerCase();
      final requestChampionId = _ddragonAliases[champion] ?? champion;
      final url = Uri.parse(
        'https://ddragon.leagueoflegends.com/cdn/$version/data/en_US/champion/$requestChampionId.json',
      );

      stdout.writeln('Fetching: $champion');

      try {
        final responseBody = await _get(client, url);
        final mapped = _buildChampionData(outputChampionId, requestChampionId, responseBody);

        final fileName = '$outputChampionId.json';
        final outputFile = File('${outputDir.path}${Platform.pathSeparator}$fileName');
        final encoder = const JsonEncoder.withIndent('    ');
        await outputFile.writeAsString('${encoder.convert(mapped)}\n');

        succeeded.add(champion);
      } catch (error) {
        failed.add(champion);
        stderr.writeln('Failed for $champion: $error');
      }
    }
  } finally {
    client.close();
  }

  stdout.writeln('---');
  stdout.writeln('Completed. Success: ${succeeded.length}, Failed: ${failed.length}');

  if (failed.isNotEmpty) {
    stdout.writeln('Failed champions: ${failed.join(', ')}');
    exitCode = 2;
  }
}

Map<String, dynamic> _buildChampionData(
  String outputChampionId,
  String requestChampionId,
  String responseBody,
) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Response root is not an object.');
  }

  final data = decoded['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Response.data is missing or invalid.');
  }

  final championPayload = data[requestChampionId];
  if (championPayload is! Map<String, dynamic>) {
    throw FormatException('Response.data["$requestChampionId"] is missing.');
  }

  final skins = championPayload['skins'];
  if (skins is! List) {
    throw const FormatException('Champion skins is missing or invalid.');
  }

  final filteredSkins = skins
      .whereType<Map<String, dynamic>>()
      .where((skin) => !skin.containsKey('parentSkin'))
      .map(
        (skin) => {
          'id': skin['id']?.toString(),
          'num': skin['num'],
          'name': skin['name']?.toString(),
          'chromas': skin['chromas'] == true,
        },
      )
      .toList();

  return {
    'id': outputChampionId,
    'imageSlug': requestChampionId,
    'key': championPayload['key']?.toString() ?? '',
    'name': championPayload['name']?.toString() ?? '',
    'skins': filteredSkins,
  };
}

Future<String> _get(HttpClient client, Uri url) async {
  final request = await client.getUrl(url);
  final response = await request.close();

  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('HTTP ${response.statusCode} at $url\n$body');
  }

  return body;
}

_Options _parseArgs(List<String> args) {
  String? version;
  String? inputPath;
  String? outputDir;
  var showHelp = false;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    switch (arg) {
      case '--version':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --version');
        }
        version = args[++i];
        break;
      case '--input':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --input');
        }
        inputPath = args[++i];
        break;
      case '--out':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --out');
        }
        outputDir = args[++i];
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
    version: version,
    inputPath: inputPath,
    outputDir: outputDir,
    showHelp: showHelp,
  );
}

void _printUsage() {
  stdout.writeln('Generate global champion files from Data Dragon.');
  stdout.writeln('');
  stdout.writeln('Usage:');
  stdout.writeln('  dart run tool/generate_global_champions.dart [options]');
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln('  --version <ver>   Data Dragon version (default: $_defaultVersion)');
  stdout.writeln('  --input <path>    Input champion array JSON (default: $_defaultInputPath)');
  stdout.writeln('  --out <dir>       Output directory (default: $_defaultOutputDir)');
  stdout.writeln('  --help, -h        Show help');
}

class _Options {
  const _Options({
    required this.version,
    required this.inputPath,
    required this.outputDir,
    required this.showHelp,
  });

  final String? version;
  final String? inputPath;
  final String? outputDir;
  final bool showHelp;
}
