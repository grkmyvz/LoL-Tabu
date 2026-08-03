import 'package:flutter/material.dart';

import '../models/champion.dart';

class ChampionCard extends StatefulWidget {
  const ChampionCard({
    super.key,
    required this.champion,
    required this.imageUrl,
    required this.onError,
  });

  final Champion champion;
  final String imageUrl;
  final VoidCallback onError;

  @override
  State<ChampionCard> createState() => _ChampionCardState();
}

class _ChampionCardState extends State<ChampionCard> {
  bool _imageLoaded = false;
  bool _errorReported = false;

  @override
  void didUpdateWidget(covariant ChampionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.champion.id != widget.champion.id ||
        oldWidget.imageUrl != widget.imageUrl) {
      _imageLoaded = false;
      _errorReported = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSkinName = _resolveCurrentSkinName();

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
              child: Column(
                children: [
                  Text(
                    widget.champion.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          offset: const Offset(0, 1),
                          blurRadius: 0.35,
                        ),
                      ],
                    ),
                  ),
                  if (currentSkinName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      currentSkinName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 1),
                            blurRadius: 0.3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  Positioned.fill(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null && !_imageLoaded) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _imageLoaded = true);
                            }
                          });
                        }
                        return child;
                      },
                      errorBuilder: (context, error, stackTrace) {
                        if (!_errorReported) {
                          _errorReported = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              widget.onError();
                            }
                          });
                        }
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                  if (!_imageLoaded)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.42),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 40,
                    child: Column(
                      children: widget.champion.forbiddenWords.take(5).map((
                        word,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: SizedBox(
                            width: 220,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                word,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 0.3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _resolveCurrentSkinName() {
    if (widget.champion.skins.isEmpty) {
      return null;
    }

    final match = RegExp(r'_(\d+)\.jpg$').firstMatch(widget.imageUrl);
    final skinNum = int.tryParse(match?.group(1) ?? '');
    if (skinNum == 0) {
      return null;
    }

    if (skinNum == null) {
      return null;
    }

    final matchingSkins = widget.champion.skins
        .where((item) => item.num == skinNum)
        .toList();
    if (matchingSkins.isEmpty) {
      return null;
    }

    final skin = matchingSkins.first;
    final normalizedName = skin.name.trim().toLowerCase();
    if (normalizedName.isEmpty || normalizedName == 'default') {
      return null;
    }

    return skin.name;
  }
}
