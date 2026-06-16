// ---------------------------------------------------------------------------
// GoalSight — Lightweight In-Memory Cache
//
// TTL-based cache for repository responses. Reduces redundant Supabase queries
// during a single app session. Not persisted across restarts.
// ---------------------------------------------------------------------------

class CacheService {
  static final _store = <String, _Entry>{};

  static T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  static void set<T>(
    String key,
    T value, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    _store[key] = _Entry(value, DateTime.now().add(ttl));
  }

  static void invalidate(String key) => _store.remove(key);

  static void invalidatePrefix(String prefix) =>
      _store.removeWhere((k, _) => k.startsWith(prefix));

  static void clear() => _store.clear();

  static bool has(String key) {
    final entry = _store[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _store.remove(key);
      return false;
    }
    return true;
  }
}

class _Entry {
  const _Entry(this.value, this.expiresAt);
  final Object? value;
  final DateTime expiresAt;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
