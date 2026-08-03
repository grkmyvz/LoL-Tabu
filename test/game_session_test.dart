import 'package:flutter_test/flutter_test.dart';
import 'package:lol_tabu/models/champion.dart';
import 'package:lol_tabu/services/champion_repository.dart';
import 'package:lol_tabu/state/game_session.dart';

void main() {
  test('start/pause/resume flow updates session state', () async {
    final session = GameSession(_FakeChampionRepository(_sampleChampions(3)));

    await session.initialize();
    expect(session.hasStarted, isFalse);
    expect(session.isRunning, isFalse);

    await session.startOrResume();
    expect(session.hasStarted, isTrue);
    expect(session.isRunning, isTrue);

    session.pause();
    expect(session.isRunning, isFalse);

    await session.startOrResume();
    expect(session.isRunning, isTrue);

    session.dispose();
  });

  test('round finished blocks moving to next champion', () async {
    final session = GameSession(_FakeChampionRepository(_sampleChampions(4)));

    await session.initialize();
    await session.startOrResume();
    session.pause();
    session.remainingSeconds = 0;

    final currentId = session.currentChampion?.id;
    await session.goToNextChampion();

    expect(session.isRoundFinished, isTrue);
    expect(session.currentChampion?.id, currentId);

    session.dispose();
  });

  test('single-champion pool locks next champion', () async {
    final session = GameSession(_FakeChampionRepository(_sampleChampions(1)));

    await session.initialize();

    expect(session.isNextChampionLocked, isTrue);
    expect(session.nextChampion, isNull);

    session.dispose();
  });

  test('setRoundDuration also updates remaining seconds', () async {
    final session = GameSession(_FakeChampionRepository(_sampleChampions(2)));

    session.setRoundDuration(30);

    expect(session.roundDurationSeconds, 30);
    expect(session.remainingSeconds, 30);

    session.dispose();
  });
}

class _FakeChampionRepository extends ChampionRepository {
  _FakeChampionRepository(this._champions);

  final List<Champion> _champions;

  @override
  Future<List<Champion>> loadChampions(String languageCode) async {
    return _champions;
  }
}

List<Champion> _sampleChampions(int count) {
  return List<Champion>.generate(count, (index) {
    final id = 'champion_$index';
    return Champion(
      id: id,
      name: 'Champion $index',
      imageSlug: 'Ahri',
      skins: const [ChampionSkin.defaultSkin()],
      forbiddenWords: const ['one', 'two', 'three', 'four', 'five'],
    );
  });
}
