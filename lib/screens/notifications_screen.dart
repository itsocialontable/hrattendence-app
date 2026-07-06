import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Employee-facing Notifications screen.
///
/// Wired to the SAME API used by the Admin Notifications screen:
///   GET    /api/notifications
///   DELETE /api/notifications/:id
/// via the shared `AdminNotificationsProvider` (registered globally in
/// main.dart, so it works for both admin and employee sessions — the
/// backend scopes the results by the logged-in user's auth token).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

  Future<bool> _confirmDelete(AdminNotification notif) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteConfirmSheet(title: notif.title),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Consumer<AdminNotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return _buildShimmer();
          }
          if (provider.hasError && provider.notifications.isEmpty) {
            return _buildError(provider);
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: provider.fetchNotifications,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(child: _buildHeader(provider)),
                ),
                if (provider.notifications.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmpty(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    sliver: SliverList.separated(
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
                          confirmDismiss: (_) => _confirmDelete(notif),
                          onDismissed: (_) => _handleDelete(notif),
                          child: _buildNotifCard(notif),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdminNotificationsProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Notifications',
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        if (provider.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${provider.unreadCount} unread',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
      ],
    );
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.notifications_off_outlined, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text('No notifications yet',
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            Text("You're all caught up.",
                style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textLight)),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
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