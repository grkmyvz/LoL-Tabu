import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/champion.dart';
import '../services/champion_repository.dart';

class GameSession extends ChangeNotifier {
  GameSession(this._repository);

  final ChampionRepository _repository;

  String languageCode = 'tr';
  bool useSkins = false;
  int roundDurationSeconds = 45;
  List<Champion> _champions = [];
  final Set<String> _seenChampionIds = <String>{};
  Champion? currentChampion;
  Champion? nextChampion;
  String? currentChampionImageUrl;
  String? nextChampionImageUrl;
  bool hasStarted = false;
  bool isRunning = false;
  int remainingSeconds = 45;
  Timer? _timer;

  Future<void> initialize() async {
    if (_champions.isEmpty) {
      _champions = await _repository.loadChampions(languageCode);
    }

    _seenChampionIds.clear();
    _setInitialChampionPair();
    remainingSeconds = roundDurationSeconds;
    hasStarted = false;
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    languageCode = language;
    _champions = [];
    _seenChampionIds.clear();
    await initialize();
  }

  void setRoundDuration(int seconds) {
    roundDurationSeconds = seconds;
    remainingSeconds = seconds;
    notifyListeners();
  }

  Future<void> startOrResume() async {
    if (_champions.isEmpty) {
      await initialize();
    }

    if (currentChampion == null) {
      _setInitialChampionPair();
    }

    hasStarted = true;

    if (isRunning) {
      return;
    }

    isRunning = true;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void reset() {
    _seenChampionIds.clear();
    _setInitialChampionPair();
    isRunning = false;
    hasStarted = false;
    _timer?.cancel();
    remainingSeconds = roundDurationSeconds;
    notifyListeners();
  }

  Future<void> goToNextChampion() async {
    if (isRoundFinished) {
      return;
    }

    if (_champions.isEmpty) {
      await initialize();
    }

    final previous = currentChampion;
    if (previous != null) {
      _markSeen(previous);
    }

    currentChampion = nextChampion ?? previous ?? _pickRandomChampion();
    currentChampionImageUrl =
        nextChampionImageUrl ?? _buildImageUrl(currentChampion);
    _markSeen(currentChampion);
    nextChampion = _pickRandomUnusedChampion(excluded: currentChampion);
    nextChampionImageUrl = _buildImageUrl(nextChampion);
    notifyListeners();
  }

  bool get isNextChampionLocked =>
      !_hasUnusedChampion(excluded: currentChampion);

  bool get isRoundFinished => hasStarted && remainingSeconds == 0;

  bool _hasUnusedChampion({Champion? excluded}) {
    if (_champions.isEmpty) {
      return false;
    }

    return _champions.any(
      (champion) =>
          champion.id != excluded?.id &&
          !_seenChampionIds.contains(champion.id),
    );
  }

  void _setInitialChampionPair() {
    currentChampion = _pickRandomChampion();
    currentChampionImageUrl = _buildImageUrl(currentChampion);
    _markSeen(currentChampion);
    nextChampion = _pickRandomUnusedChampion(excluded: currentChampion);
    nextChampionImageUrl = _buildImageUrl(nextChampion);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRunning) {
        return;
      }

      if (remainingSeconds > 1) {
        remainingSeconds -= 1;
        notifyListeners();
      } else {
        remainingSeconds = 0;
        isRunning = false;
        _timer?.cancel();
        notifyListeners();
      }
    });
  }

  Champion _pickRandomChampion({Champion? excluded}) {
    if (_champions.isEmpty) {
      return const Champion(
        id: 'empty',
        name: 'Empty',
        imageSlug: 'Ahri',
        skins: [ChampionSkin.defaultSkin()],
        forbiddenWords: [],
      );
    }

    final available = _champions
        .where(
          (champion) =>
              champion.id != excluded?.id &&
              !_seenChampionIds.contains(champion.id),
        )
        .toList();

    if (available.isNotEmpty) {
      return available[DateTime.now().millisecondsSinceEpoch %
          available.length];
    }

    final fallback = _champions
        .where((champion) => champion.id != excluded?.id)
        .toList();
    if (fallback.isEmpty) {
      return _champions.first;
    }
    return fallback[DateTime.now().millisecondsSinceEpoch % fallback.length];
  }

  Champion? _pickRandomUnusedChampion({Champion? excluded}) {
    if (_champions.isEmpty) {
      return null;
    }

    final available = _champions
        .where(
          (champion) =>
              champion.id != excluded?.id &&
              !_seenChampionIds.contains(champion.id),
        )
        .toList();

    if (available.isEmpty) {
      return null;
    }

    return available[DateTime.now().millisecondsSinceEpoch % available.length];
  }

  String? _buildImageUrl(Champion? champion) {
    if (champion == null) {
      return null;
    }

    if (champion.skins.isEmpty) {
      return champion.imageUrlForSkinNum(0);
    }

    final defaultSkin = champion.skins.firstWhere(
      (skin) => skin.num == 0,
      orElse: () => champion.skins.first,
    );

    if (!useSkins) {
      return champion.imageUrlForSkinNum(defaultSkin.num);
    }

    final skinCandidates = champion.skins
        .where((skin) => skin.num > 0)
        .toList();
    if (skinCandidates.isEmpty) {
      return champion.imageUrlForSkinNum(defaultSkin.num);
    }

    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % skinCandidates.length;
    return champion.imageUrlForSkinNum(skinCandidates[randomIndex].num);
  }

  void _markSeen(Champion? champion) {
    if (champion != null) {
      _seenChampionIds.add(champion.id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
