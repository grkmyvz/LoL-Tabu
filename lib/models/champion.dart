class Champion {
  const Champion({
    required this.id,
    required this.name,
    required this.imageSlug,
    required this.skins,
    required this.forbiddenWords,
  });

  final String id;
  final String name;
  final String imageSlug;
  final List<ChampionSkin> skins;
  final List<String> forbiddenWords;

  factory Champion.fromMergedJson({
    required Map<String, dynamic> globalJson,
    required Map<String, dynamic> localizedJson,
  }) {
    final skins = globalJson['skins'];
    final globalId = globalJson['id'] as String;
    final localizedId = localizedJson['id'] as String;

    if (globalId != localizedId) {
      throw Exception(
        'Champion id mismatch. Global id: $globalId, localized id: $localizedId',
      );
    }

    return Champion(
      id: globalId,
      name: globalJson['name'] as String,
      imageSlug: _resolveImageSlug(globalJson),
      skins: skins is List
          ? skins
                .whereType<Map<String, dynamic>>()
                .map(ChampionSkin.fromJson)
                .toList()
          : const [ChampionSkin.defaultSkin()],
      forbiddenWords: List<String>.from(localizedJson['forbiddenWords'] as List),
    );
  }

  String imageUrlForSkinNum(int skinNum) {
    final normalizedSlug = '${imageSlug}_$skinNum';
    return 'https://ddragon.leagueoflegends.com/cdn/img/champion/loading/$normalizedSlug.jpg';
  }

  static String _resolveImageSlug(Map<String, dynamic> globalJson) {
    final imageSlug = globalJson['imageSlug']?.toString();
    if (imageSlug != null && imageSlug.isNotEmpty) {
      return imageSlug;
    }

    final key = globalJson['key']?.toString();
    if (key == '62') {
      return 'MonkeyKing';
    }
    if (key == '897') {
      return 'KSante';
    }

    final fallbackName = globalJson['name']?.toString();
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return fallbackName.replaceAll("'", '').replaceAll(' ', '');
    }

    return 'Ahri';
  }
}

class ChampionSkin {
  const ChampionSkin({
    required this.id,
    required this.num,
    required this.name,
    required this.chromas,
  });

  const ChampionSkin.defaultSkin()
      : id = '0',
        num = 0,
        name = 'default',
        chromas = false;

  final String id;
  final int num;
  final String name;
  final bool chromas;

  factory ChampionSkin.fromJson(Map<String, dynamic> json) {
    final numValue = json['num'];

    return ChampionSkin(
      id: json['id']?.toString() ?? '0',
      num: numValue is int
          ? numValue
          : int.tryParse(numValue?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'default',
      chromas: json['chromas'] == true,
    );
  }
}
