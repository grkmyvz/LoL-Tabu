import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/champion.dart';

class ChampionRepository {
  Future<List<Champion>> loadChampions(String languageCode) async {
    final allowedChampionIds = await _loadAllowedChampionIds();

    final List<Champion> champions = [];

    for (final championId in allowedChampionIds) {
      final globalJson = await _loadGlobalChampionById(championId);
      final localizedJson = await _loadLocalizedChampionById(
        languageCode: languageCode,
        championId: championId,
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

  Future<Map<String, dynamic>> _loadGlobalChampionById(
    String championId,
  ) async {
    final rawData = await _loadAsset(
      'assets/data/global/champions/$championId.json',
    );
    final decoded = json.decode(rawData);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid global champion data for id: $championId');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _loadLocalizedChampionById({
    required String languageCode,
    required String championId,
  }) async {
    final path = 'assets/data/$languageCode/champions/$championId.json';
    final rawData = await _loadAsset(path);
    final decoded = json.decode(rawData);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Invalid localized champion data for id: $championId in $languageCode',
      );
    }

    return decoded;
  }

  Future<String> _loadAsset(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (error) {
      throw Exception('Failed to load asset at $path: $error');
    }
  }
}
