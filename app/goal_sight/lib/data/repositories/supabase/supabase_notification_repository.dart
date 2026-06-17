// ---------------------------------------------------------------------------
// GoalSight — Supabase Notification Repository
//
// Reads/updates notifications for the signed-in admin. RLS ensures each
// admin sees only their own rows. Realtime stream keeps the badge live.
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notification_model.dart';

final class SupabaseNotificationRepository {
  const SupabaseNotificationRepository();

  SupabaseClient get _client => Supabase.instance.client;

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<List<NotificationModel>> fetchNotifications({
    bool unreadOnly = false,
  }) async {
    var query = _client.from('notifications').select();
    if (unreadOnly) {
      query = query.eq('is_read', false);
    }
    final rows = await query
        .order('created_at', ascending: false)
        .limit(60);
    return (rows as List)
        .map((r) => _map(r as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('is_read', false);
    return (rows as List).length;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> markAsRead(String id) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id);
  }

  Future<void> markAllAsRead() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', uid)
        .eq('is_read', false);
  }

  // ── Realtime ──────────────────────────────────────────────────────────────

  Stream<List<NotificationModel>> watchNotifications() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((r) => _map(r)).toList());
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  NotificationModel _map(Map<String, dynamic> r) => NotificationModel(
        id: r['id'].toString(),
        recipientId: (r['recipient_id'] ?? '').toString(),
        clubId: r['club_id']?.toString(),
        type: NotificationType.fromDb((r['type'] ?? 'upload_complete').toString()),
        title: (r['title'] ?? '').toString(),
        body: (r['body'] ?? '').toString(),
        relatedId: r['related_id']?.toString(),
        isRead: r['is_read'] == true,
        createdAt:
            DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
