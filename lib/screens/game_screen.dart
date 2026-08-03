import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../state/game_session.dart';
import '../widgets/champion_card.dart';
import '../widgets/lol_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.session});

  final GameSession session;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _imageError = false;
  String? _lastChampionId;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_handleSessionChange);
    AppLocalization.ensureLoaded(widget.session.languageCode).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    if (widget.session.currentChampion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.session.initialize();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_handleSessionChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final champion = session.currentChampion;
    final currentImageUrl = session.currentChampionImageUrl;
    final roundFinished = session.isRoundFinished;

    return Scaffold(
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
            child: Column(
              children: [
                Text(
                  '${session.remainingSeconds}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                if (champion == null || currentImageUrl == null)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          flex: 10,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  child: ChampionCard(
                                    key: ValueKey(
                                      '${champion.id}|$currentImageUrl',
                                    ),
                                    champion: champion,
                                    imageUrl: currentImageUrl,
                                    onError: () =>
                                        setState(() => _imageError = true),
                                  ),
                                ),
                              ),
                              if (roundFinished)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.grey.withValues(alpha: 0.45),
                                    alignment: Alignment.center,
                                    child: Text(
                                      AppLocalization.roundFinished(
                                        session.languageCode,
                                      ),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (_imageError)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              AppLocalization.imageError(session.languageCode),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: LolButton(
                                height: 50,
                                onPressed: () {
                                  if (!session.hasStarted) {
                                    session.startOrResume();
                                  } else if (session.isRunning) {
                                    session.pause();
                                  } else {
                                    session.startOrResume();
                                  }
                                },
                                label: !session.hasStarted
                                    ? AppLocalization.startButton(
                                        session.languageCode,
                                      )
                                    : session.isRunning
                                    ? AppLocalization.pause(
                                        session.languageCode,
                                      )
                                    : AppLocalization.resume(
                                        session.languageCode,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LolButton(
                                height: 50,
                                onPressed:
                                    (!session.hasStarted ||
                                        roundFinished ||
                                        session.isNextChampionLocked)
                                    ? null
                                    : () => session.goToNextChampion(),
                                label: session.isNextChampionLocked
                                    ? AppLocalization.championsFinished(
                                        session.languageCode,
                                      )
                                    : roundFinished
                                    ? AppLocalization.roundFinished(
                                        session.languageCode,
                                      )
                                    : AppLocalization.next(
                                        session.languageCode,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LolButton(
                                height: 50,
                                onPressed: () => session.reset(),
                                label: AppLocalization.reset(
                                  session.languageCode,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSessionChange() {
    final currentId = widget.session.currentChampion?.id;
    if (currentId != null && currentId != _lastChampionId) {
      _lastChampionId = currentId;
      _imageError = false;
    }

    final nextImageUrl = widget.session.nextChampionImageUrl;
    if (nextImageUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          precacheImage(NetworkImage(nextImageUrl), context);
        }
      });
    }

    if (mounted) {
      setState(() {});
    }
  }
}
