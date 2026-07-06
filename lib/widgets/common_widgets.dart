import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ── Premium Card ──────────────────────────────────────────────────────────────
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;
  final Color? color;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.color,
    this.borderRadius,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? AppColors.white) : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? AppSpacing.cardRadius),
          boxShadow: shadows ?? AppShadow.card,
        ),
        child: child,
      ),
    );
  }
}

// ── Glass Card ────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: child,
    );
  }
}

// ── Avatar Widget ─────────────────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Gradient? gradient;
  final String? imageUrl;
  final bool showBadge;
  final Color badgeColor;

  const AppAvatar({
    super.key,
    required this.initials,
    this.size = 44,
    this.gradient,
    this.imageUrl,
    this.showBadge = false,
    this.badgeColor = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient ?? AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(size / 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Gradient gradient;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.gradient = AppColors.primaryGradient,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          boxShadow: AppShadow.strong,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag Badge ─────────────────────────────────────────────────────────────────
class TagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const TagBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Shimmer Box ───────────────────────────────────────────────────────────────
/// A self-contained animated shimmer placeholder (no external package needed).
/// Sweeps a soft gradient highlight left-to-right on a loop.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + t * 3, 0),
              end: Alignment(0.5 + t * 3, 0),
              colors: [
                AppColors.border.withOpacity(0.55),
                AppColors.border.withOpacity(0.15),
                AppColors.border.withOpacity(0.55),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ── Shimmer Stat Card ────────────────────────────────────────────────────────
/// Placeholder matching the dashboard's stat card while data is loading.
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 32, height: 32, borderRadius: BorderRadius.all(Radius.circular(10))),
          const SizedBox(height: 10),
          const ShimmerBox(width: 36, height: 18),
          const SizedBox(height: 6),
          const ShimmerBox(width: 48, height: 11),
        ],
      ),
    );
  }
}

// ── Shimmer Chip ──────────────────────────────────────────────────────────────
/// Placeholder matching StatChip while data is loading.
class ShimmerChip extends StatelessWidget {
  const ShimmerChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerBox(width: 14, height: 14, borderRadius: BorderRadius.all(Radius.circular(4))),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBox(width: 38, height: 13),
              SizedBox(height: 4),
              ShimmerBox(width: 58, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Error State Card ─────────────────────────────────────────────────────────
/// Shown when an API call fails — includes a Retry action.
class ErrorStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textMid,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Retry',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
