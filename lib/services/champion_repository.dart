import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/champion.dart';

class ChampionRepository {
  Future<List<Champion>> loadChampions(String languageCode) async {
    final allowedChampionIds = await _loadAllowedChampionIds();
    final globalBundle = await _loadChampionBundle(
      'assets/data/global/champion_bundle.json',
      description: 'global champion bundle',
    );
    final localizedBundle = await _loadChampionBundle(
      'assets/data/$languageCode/champion_bundle.json',
      description: 'localized champion bundle for $languageCode',
    );

    final List<Champion> champions = [];

    for (final championId in allowedChampionIds) {
      final globalJson = _championDataFromBundle(
        bundle: globalBundle,
        championId: championId,
        bundleDescription: 'global champion bundle',
      );
      final localizedJson = _championDataFromBundle(
        bundle: localizedBundle,
        championId: championId,
        bundleDescription: 'localized champion bundle for $languageCode',
      );

      champions.add(
        Champion.fromMergedJson(
          globalJson: globalJson,
          localizedJson: localizedJson,
        ),
      );
    }

    return champions;
  }

  Future<List<String>> _loadAllowedChampionIds() async {
    final allowedRaw = await _loadAsset('assets/data/global/champions.json');
    final decoded = json.decode(allowedRaw);
    if (decoded is! List) {
      throw Exception('Invalid champions.json format.');
    }

    return decoded
        .map((item) => item.toString().trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _loadChampionBundle(
    String path, {
    required String description,
  }) async {
    final rawData = await _loadAsset(path);
    final decoded = json.decode(rawData);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid $description at $path');
    }
    return decoded;
  }

  Map<String, dynamic> _championDataFromBundle({
    required Map<String, dynamic> bundle,
    required String championId,
    required String bundleDescription,
  }) {
    final championData = bundle[championId];
    if (championData is! Map<String, dynamic>) {
      throw Exception(
        'Champion "$championId" is missing or invalid in $bundleDescription',
      );
    }
    return championData;
  }

  Future<String> _loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (error) {
      throw Exception('Failed to load asset at $path: $error');
    }
  }
}
