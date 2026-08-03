import 'package:flutter/material.dart';

import '../localization/app_localization.dart';
import '../services/champion_repository.dart';
import '../state/game_session.dart';
import '../widgets/lol_button.dart';
import 'about_screen.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _languageCode = _defaultLanguageCode();
  int _roundDuration = 60;
  bool _loading = false;
  bool _useSkins = false;

  @override
  void initState() {
    super.initState();
    Future.wait(
      AppLocalization.supportedLanguages
          .map(AppLocalization.ensureLoaded)
          .toList(),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  static String _defaultLanguageCode() {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (AppLocalization.supportedLanguages.contains(languageCode)) {
      return languageCode;
    }

    return 'en';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        color: const Color(0xFF050816),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.28,
              child: Image.network(
                'https://ddragon.leagueoflegends.com/cdn/img/champion/loading/Zeri_0.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF050816));
                },
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x2202030A), Color(0x66050816)],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: [
                            const SizedBox(height: 10),
                            Image.asset(
                              'assets/images/lol_tabu_logo.png',
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLocalization.homeTitle(_languageCode),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              AppLocalization.description(_languageCode),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.25,
                                letterSpacing: 0.25,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildOptionCard(
                              context,
                              title: AppLocalization.languageLabel(
                                _languageCode,
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _languageCode,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 22,
                                ),
                                items: AppLocalization.supportedLanguages
                                    .map(
                                      (language) => DropdownMenuItem(
                                        value: language,
                                        child: Text(
                                          AppLocalization.languageName(
                                            language,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _languageCode = value);
                                    await AppLocalization.ensureLoaded(
                                      _languageCode,
                                    );
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildOptionCard(
                              context,
                              title: AppLocalization.durationLabel(
                                _languageCode,
                              ),
                              child: DropdownButtonFormField<int>(
                                initialValue: _roundDuration,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 22,
                                ),
                                items: [30, 45, 60]
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(
                                          '$value ${AppLocalization.seconds(_languageCode)}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _roundDuration = value);
                                  }
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: LolButton(
                                height: 72,
                                onPressed: _loading ? null : _startGame,
                                loading: _loading,
                                label: _loading
                                    ? AppLocalization.loading(_languageCode)
                                    : AppLocalization.startGame(_languageCode),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LolButton(
                              width: 150,
                              height: 44,
                              textScale: 0.58,
                              selected: _useSkins,
                              onPressed: () {
                                setState(() => _useSkins = !_useSkins);
                              },
                              label: _useSkins
                                  ? AppLocalization.skinsEnabled(_languageCode)
                                  : AppLocalization.openSkins(_languageCode),
                            ),
                            LolButton(
                              width: 130,
                              height: 44,
                              textScale: 0.56,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AboutScreen(
                                      languageCode: _languageCode,
                                    ),
                                  ),
                                );
                              },
                              label: AppLocalization.aboutButton(_languageCode),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Future<void> _startGame() async {
    setState(() => _loading = true);

    try {
      final session = GameSession(ChampionRepository())
        ..languageCode = _languageCode
        ..roundDurationSeconds = _roundDuration
        ..useSkins = _useSkins;

      await session.initialize();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameScreen(session: session)),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to start game: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalization.startError(_languageCode))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}
