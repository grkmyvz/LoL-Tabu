import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppLocalization {
  static const supportedLanguages = ['tr', 'en', 'zh'];
  static final Map<String, Map<String, String>> _translations = {};
  static final Set<String> _missingKeyWarnings = <String>{};

  static Future<void> ensureLoaded(String languageCode) async {
    if (_translations.containsKey(languageCode)) {
      return;
    }

    final data = await rootBundle.loadString('assets/i18n/$languageCode.json');
    final decoded = json.decode(data) as Map<String, dynamic>;
    _translations[languageCode] = decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  static String languageName(String languageCode) {
    return _get(languageCode, 'languageName');
  }

  static String homeTitle(String languageCode) {
    return _get(languageCode, 'homeTitle');
  }

  static String languageLabel(String languageCode) {
    return _get(languageCode, 'languageLabel');
  }

  static String durationLabel(String languageCode) {
    return _get(languageCode, 'durationLabel');
  }

  static String startGame(String languageCode) {
    return _get(languageCode, 'startGame');
  }

  static String startButton(String languageCode) {
    return _get(languageCode, 'startButton');
  }

  static String forbiddenWords(String languageCode) {
    return _get(languageCode, 'forbiddenWords');
  }

  static String pause(String languageCode) {
    return _get(languageCode, 'pause');
  }

  static String resume(String languageCode) {
    return _get(languageCode, 'resume');
  }

  static String reset(String languageCode) {
    return _get(languageCode, 'reset');
  }

  static String next(String languageCode) {
    return _get(languageCode, 'next');
  }

  static String seconds(String languageCode) {
    return _get(languageCode, 'seconds');
  }

  static String loading(String languageCode) {
    return _get(languageCode, 'loading');
  }

  static String imageError(String languageCode) {
    return _get(languageCode, 'imageError');
  }

  static String description(String languageCode) {
    return _get(languageCode, 'description');
  }

  static String startError(String languageCode) {
    return _get(languageCode, 'startError');
  }

  static String championsFinished(String languageCode) {
    return _get(languageCode, 'championsFinished');
  }

  static String roundFinished(String languageCode) {
    return _get(languageCode, 'roundFinished');
  }

  static String aboutButton(String languageCode) {
    return _get(languageCode, 'aboutButton');
  }

  static String aboutPageTitle(String languageCode) {
    return _get(languageCode, 'aboutPageTitle');
  }

  static String aboutPageBody(String languageCode) {
    return _get(languageCode, 'aboutPageBody');
  }

  static String contactTitle(String languageCode) {
    return _get(languageCode, 'contactTitle');
  }

  static String contactBody(String languageCode) {
    return _get(languageCode, 'contactBody');
  }

  static String openSkins(String languageCode) {
    return _get(languageCode, 'openSkins');
  }

  static String skinsEnabled(String languageCode) {
    return _get(languageCode, 'skinsEnabled');
  }

  static String _get(String languageCode, String key) {
    final translation = _translations[languageCode]?[key];
    if (translation != null) {
      return translation;
    }

    if (kDebugMode) {
      final warningKey = '$languageCode::$key';
      if (_missingKeyWarnings.add(warningKey)) {
        debugPrint(
          'Missing localization key: $key for language: $languageCode',
        );
      }
    }

    return key;
  }
}
