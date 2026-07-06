import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Admin Notifications screen — reachable from the notification bell on the
/// Admin Dashboard's top bar.
///
/// API:
///   GET    /api/notifications
///   DELETE /api/notifications/:id
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminNotificationsProvider>().fetchNotifications();
    });
  }

  Future<void> _handleDelete(AdminNotification notif) async {
    final provider = context.read<AdminNotificationsProvider>();
    final success = await provider.deleteNotification(notif.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notification removed', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.textDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Failed to delete notification.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notifications',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ),
      body: SafeArea(
        child: Consumer<AdminNotificationsProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return _buildShimmer();
            }
            if (provider.hasError && provider.notifications.isEmpty) {
              return _buildError(provider);
            }
            if (provider.notifications.isEmpty) {
              return _buildEmpty(provider);
            }
            return _buildList(provider);
          },
        ),
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────────────

  Widget _buildList(AdminNotificationsProvider provider) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.fetchNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notif = provider.notifications[index];
          return Dismissible(
            key: ValueKey(notif.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
            ),
            confirmDismiss: (_) async {
              final confirmed = await _confirmDelete(notif);
              return confirmed;
            },
            onDismissed: (_) => _handleDelete(notif),
            child: _buildNotifCard(notif),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(AdminNotification notif) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteConfirmSheet(title: notif.title),
    );
    return result ?? false;
  }

  Widget _buildNotifCard(AdminNotification notif) {
    final color = _colorForType(notif.type);
    final initials = (notif.senderName?.trim().isNotEmpty ?? false)
        ? notif.senderName!.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : null;

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      color: notif.isRead ? AppColors.background : AppColors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (initials != null)
                AppAvatar(
                  initials: initials,
                  size: 42,
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                )
              else
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_iconForType(notif.type), color: color, size: 20),
                ),
              if (!notif.isRead)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                if (notif.message.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    notif.message,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  _formatTime(notif.createdAt),
                  style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, color: AppColors.textLight, size: 18),
            onPressed: () async {
              final confirmed = await _confirmDelete(notif);
              if (confirmed) _handleDelete(notif);
            },
          ),
        ],
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'leave':
        return AppColors.primary;
      case 'attendance':
        return AppColors.warning;
      case 'salary':
        return AppColors.success;
      default:
        return AppColors.secondary;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'leave':
        return Icons.event_note_rounded;
      case 'attendance':
        return Icons.access_time_rounded;
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  // ─── Empty / Error / Loading states ────────────────────────────────────

  Widget _buildEmpty(AdminNotificationsProvider provider) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: provider.fetchNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Container(
            width: 72,
            height: 72,
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.notifications_off_outlined, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('No notifications yet',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text("You're all caught up.",
                style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AdminNotificationsProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Failed to load notifications',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: provider.fetchNotifications,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  boxShadow: AppShadow.strong,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Retry',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const ShimmerBox(width: 42, height: 42, borderRadius: BorderRadius.all(Radius.circular(14))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 140, height: 13),
                  SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  final String title;
  const _DeleteConfirmSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, size: 28, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Text('Delete notification?',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMid)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Delete',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
