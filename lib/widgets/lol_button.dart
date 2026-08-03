import 'package:flutter/material.dart';

class LolButton extends StatelessWidget {
  const LolButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 64,
    this.loading = false,
    this.selected = false,
    this.textScale = 1.0,
  });

  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final bool loading;
  final bool selected;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final borderRadius = BorderRadius.circular(7);
    final isSelected = selected && enabled;
    final backgroundTop = isSelected
        ? const Color(0xFFB9882D)
        : enabled
        ? const Color(0xFF8A5F20)
        : const Color(0xFF5C4520);
    final backgroundBottom = isSelected
        ? const Color(0xFF6F4B14)
        : enabled
        ? const Color(0xFF4F3412)
        : const Color(0xFF36260E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: enabled ? onPressed : null,
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [backgroundTop, backgroundBottom],
            ),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFF6D89B)
                  : enabled
                  ? const Color(0xFFD6A24A)
                  : const Color(0xFF7B5A22),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: enabled
                    ? const Color(0xB01A1005)
                    : const Color(0x80120B04),
                blurRadius: isSelected ? 8 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _TextureLayer(enabled: enabled)),
              Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : _EmbossedTitle(
                        label: label,
                        enabled: enabled,
                        textScale: textScale,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextureLayer extends StatelessWidget {
  const _TextureLayer({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          enabled ? const Color(0xFFE0B24A) : const Color(0xFF7E5B22),
          BlendMode.modulate,
        ),
        child: Opacity(
          opacity: enabled ? 0.28 : 0.18,
          child: Image.asset(
            'assets/images/button_texture.jpg',
            fit: BoxFit.cover,
            repeat: ImageRepeat.repeat,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _EmbossedTitle extends StatelessWidget {
  const _EmbossedTitle({
    required this.label,
    required this.enabled,
    required this.textScale,
  });

  final String label;
  final bool enabled;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final baseTitle = Theme.of(context).textTheme.titleLarge;
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: ((baseTitle?.fontSize ?? 22) + 3) * textScale,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w900,
      color: enabled ? const Color(0xFFFCFEFF) : const Color(0xFFE9EDF2),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: enabled ? 0.75 : 0.5),
          offset: const Offset(0, 2),
          blurRadius: 1,
        ),
        Shadow(
          color: Colors.black.withValues(alpha: enabled ? 0.32 : 0.2),
          offset: const Offset(0, 1),
          blurRadius: 0,
        ),
      ],
    );

    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
