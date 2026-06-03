import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/features/friends/providers/friends_provider.dart';
import 'package:codemania/core/models/friend_model.dart';
import 'package:codemania/models/friend_request.dart';
import 'package:codemania/widgets/app_sidebar.dart';
import 'package:codemania/services/api_service.dart';
import 'package:flutter/foundation.dart';

// ─── Design tokens (match app light theme exactly) ────────────────────────────
const _kBg       = Color(0xFFF0F0F8);
const _kCard     = Color(0xFFFFFFFF);
const _kBorder   = Color(0xFFE5E5F0);
const _kAccent   = Color(0xFF6C3CE1);  // primary purple
const _kTextPri  = Color(0xFF1A1A2E);
const _kTextSec  = Color(0xFF666680);
const _kGreen    = Color(0xFF22C55E);
const _kDanger   = Color(0xFFEF4444);

// ═══════════════════════════════════════════════════════════════════════════
// Screen
// ═══════════════════════════════════════════════════════════════════════════

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _serverReachable = true;
  bool _pingDone = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ping();
      ref.read(friendsProvider.notifier).loadFriends();
      ref.read(friendsProvider.notifier).fetchIncomingRequests();
      ref.read(friendsProvider.notifier).loadLeaderboard();
    });
  }

  Future<void> _ping() async {
    try {
      final res = await ApiService.get('/api/friends/ping');
      if (kDebugMode) debugPrint('[Friends] ping → ${res.statusCode} ${res.data}');
      setState(() { _serverReachable = res.statusCode == 200; _pingDone = true; });
    } catch (e) {
      if (kDebugMode) debugPrint('[Friends] ping failed: $e');
      setState(() { _serverReachable = false; _pingDone = true; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? _kDanger : _kAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);
    final requestCount = state.incomingRequests.length;
    final isCompact = MediaQuery.of(context).size.width < 1080;

    Widget body = Column(
      children: [
        // ── Server unreachable banner ─────────────────────────────────────
        if (_pingDone && !_serverReachable)
          Container(
            width: double.infinity,
            color: _kDanger.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: _kDanger, size: 16),
                const SizedBox(width: 8),
                const Text('Cannot reach server. Check backend is running.',
                    style: TextStyle(color: _kDanger, fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: _ping,
                  child: const Text('Retry', style: TextStyle(color: _kDanger)),
                ),
              ],
            ),
          ),

        // ── Tab bar ───────────────────────────────────────────────────────
        Container(
          color: _kCard,
          child: TabBar(
            controller: _tabController,
            indicatorColor: _kAccent,
            indicatorWeight: 2.5,
            labelColor: _kAccent,
            unselectedLabelColor: _kTextSec,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: [
              const Tab(text: 'My Friends'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (requestCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _kDanger,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$requestCount',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Find Users'),
            ],
          ),
        ),

        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FriendsTab(state: state, onSnack: _snack),
              _RequestsTab(state: state, onSnack: _snack),
              _FindUsersTab(state: state, onSnack: _snack),
            ],
          ),
        ),
      ],
    );

    // Wrap with sidebar on wide screens
    return Scaffold(
      backgroundColor: _kBg,
      drawer: isCompact
          ? Drawer(
              child: SafeArea(
                child: SizedBox(
                  width: 220,
                  child: const AppSidebar(activePage: 'friends'),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const SizedBox(
                width: 220,
                child: AppSidebar(activePage: 'friends'),
              ),
            Expanded(
              child: Column(
                children: [
                  // Top bar matching home_screen
                  _FriendsTopBar(
                    onMenuTap: isCompact
                        ? () => Scaffold.of(context).openDrawer()
                        : null,
                  ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _FriendsTopBar extends StatelessWidget {
  const _FriendsTopBar({this.onMenuTap});
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFDFF),
        border: Border(bottom: BorderSide(color: Color(0xFFE9E4F4))),
      ),
      child: Row(
        children: [
          if (onMenuTap != null) ...[
            IconButton(onPressed: onMenuTap, icon: const Icon(Icons.menu)),
            const SizedBox(width: 4),
          ],
          const Text(
            'Friends',
            style: TextStyle(
              color: Color(0xFF202547),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined, color: Color(0xFF7B7892)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — My Friends
// ─────────────────────────────────────────────────────────────────────────────

class _FriendsTab extends ConsumerStatefulWidget {
  const _FriendsTab({required this.state, required this.onSnack});
  final FriendsState state;
  final void Function(String, {bool isError}) onSnack;

  @override
  ConsumerState<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends ConsumerState<_FriendsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final friends = widget.state.friends
        .where((f) => f.username.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        _SearchBar(
          hint: 'Search your friends…',
          onChanged: (v) => setState(() => _query = v),
        ),
        if (widget.state.isLoading && friends.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator(color: _kAccent)))
        else if (friends.isEmpty)
          Expanded(
            child: _EmptyState(
              icon: Icons.people_outline,
              title: _query.isEmpty ? 'No friends yet' : 'No matches',
              subtitle: _query.isEmpty
                  ? 'Use the Find Users tab to send requests!'
                  : 'Try a different search term.',
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              color: _kAccent,
              onRefresh: () => ref.read(friendsProvider.notifier).loadFriends(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _FriendCard(friend: friends[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});
  final FriendModel friend;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          _Avatar(username: friend.username, avatarUrl: friend.avatarUrl, isOnline: friend.isOnline),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.username,
                    style: const TextStyle(
                        color: _kTextPri, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.check_circle_outline, size: 13, color: _kGreen),
                  const SizedBox(width: 4),
                  Text('${friend.solvedCount} solved',
                      style: const TextStyle(color: _kTextSec, fontSize: 12)),
                  const SizedBox(width: 12),
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  Text(' ${friend.currentStreak}d streak',
                      style: const TextStyle(color: _kTextSec, fontSize: 12)),
                ]),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => context.push('/profile/${friend.id}'),
            style: FilledButton.styleFrom(
              backgroundColor: _kAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('View Profile', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Requests
// ─────────────────────────────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.state, required this.onSnack});
  final FriendsState state;
  final void Function(String, {bool isError}) onSnack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = state.incomingRequests;

    if (state.isLoading && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.mail_outline,
        title: 'No pending requests',
        subtitle: 'When someone sends you a friend request it will appear here.',
      );
    }

    return RefreshIndicator(
      color: _kAccent,
      onRefresh: () => ref.read(friendsProvider.notifier).fetchIncomingRequests(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final req = requests[i];
          return _RequestCard(
            request: req,
            onAccept: () async {
              try {
                await ref.read(friendsProvider.notifier).respondToRequest(req.id, 'accept');
                onSnack('Friend request accepted 🎉');
              } catch (e) {
                onSnack(e.toString(), isError: true);
              }
            },
            onDecline: () async {
              try {
                await ref.read(friendsProvider.notifier).respondToRequest(req.id, 'decline');
                onSnack('Request declined');
              } catch (e) {
                onSnack(e.toString(), isError: true);
              }
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onAccept, required this.onDecline});
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Row(
        children: [
          _Avatar(username: request.senderUsername, avatarUrl: request.senderAvatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.senderUsername,
                    style: const TextStyle(
                        color: _kTextPri, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                const Text('wants to be your friend',
                    style: TextStyle(color: _kTextSec, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: _kDanger,
              side: const BorderSide(color: _kDanger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Decline', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: _kGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Accept', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Find Users (with 300ms debounce, ILIKE search via /api/users/search)
// ─────────────────────────────────────────────────────────────────────────────

class _FindUsersTab extends ConsumerStatefulWidget {
  const _FindUsersTab({required this.state, required this.onSnack});
  final FriendsState state;
  final void Function(String, {bool isError}) onSnack;

  @override
  ConsumerState<_FindUsersTab> createState() => _FindUsersTabState();
}

class _FindUsersTabState extends ConsumerState<_FindUsersTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  String _searchError = '';
  List<Map<String, dynamic>> _results = [];
  final Set<int> _pendingIds = {};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() { _results = []; _searching = false; _searchError = ''; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(query.trim()));
  }

  Future<void> _runSearch(String q) async {
    setState(() { _searching = true; _searchError = ''; });
    try {
      final res = await ApiService.get('/api/users/search', params: {'q': q});
      if (kDebugMode) debugPrint('[FindUsers] GET /api/users/search?q=$q → ${res.statusCode}');
      if (res.statusCode == 200) {
        final users = res.data['users'] as List? ?? [];
        setState(() { _results = users.cast<Map<String, dynamic>>(); _searching = false; });
      } else {
        setState(() { _searchError = res.data['error']?.toString() ?? 'Search failed'; _searching = false; });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FindUsers] search error: $e');
      setState(() { _searchError = 'Could not reach server'; _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchBar(
          controller: _searchCtrl,
          hint: 'Find users by username…',
          onChanged: _onChanged,
        ),

        if (_searchError.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kDanger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kDanger.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: _kDanger, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_searchError, style: const TextStyle(color: _kDanger, fontSize: 12))),
            ]),
          ),

        if (_searching)
          const Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: _kAccent),
          )
        else if (_results.isEmpty && _searchCtrl.text.isNotEmpty && _searchError.isEmpty)
          const _EmptyState(
            icon: Icons.search_off,
            title: 'No users found',
            subtitle: 'Try a different username.',
          )
        else if (_results.isEmpty)
          const _EmptyState(
            icon: Icons.person_search,
            title: 'Search for a user',
            subtitle: 'Type a username above to find and add friends.',
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final u = _results[i];
                final id = u['id'] as int;
                final isFriend = u['is_friend'] as bool? ?? false;
                final reqSent = (u['request_sent'] as bool? ?? false) || _pendingIds.contains(id);

                return _card(
                  child: Row(
                    children: [
                      _Avatar(username: u['username'] as String, avatarUrl: u['avatar_url'] as String?),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['username'] as String,
                                style: const TextStyle(color: _kTextPri, fontWeight: FontWeight.w700, fontSize: 15)),
                            if ((u['solved_count'] as int? ?? 0) > 0)
                              Text('${u['solved_count']} solved',
                                  style: const TextStyle(color: _kTextSec, fontSize: 12)),
                          ],
                        ),
                      ),
                      isFriend
                          ? _statusChip('Friends ✓', _kGreen)
                          : reqSent
                              ? _statusChip('Pending', _kTextSec)
                              : FilledButton(
                                  onPressed: () async {
                                    setState(() => _pendingIds.add(id));
                                    try {
                                      await ref.read(friendsProvider.notifier).sendFriendRequest(id);
                                      widget.onSnack('Request sent to ${u['username']}!');
                                    } catch (e) {
                                      setState(() => _pendingIds.remove(id));
                                      widget.onSnack(e.toString(), isError: true);
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: const Text('Send Request', style: TextStyle(fontSize: 12)),
                                ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

Widget _card({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _kCard,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
    ),
    child: child,
  );
}

Widget _statusChip(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, this.avatarUrl, this.isOnline = false});
  final String username;
  final String? avatarUrl;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: _kAccent.withOpacity(0.15),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: _kAccent, fontWeight: FontWeight.bold, fontSize: 16),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _kGreen,
                shape: BoxShape.circle,
                border: Border.all(color: _kCard, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.controller, required this.hint, required this.onChanged});
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: _kTextPri, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _kTextSec),
          prefixIcon: const Icon(Icons.search, color: _kTextSec, size: 18),
          filled: true,
          fillColor: _kBg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAccent, width: 2),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: _kTextSec.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: _kTextPri, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSec, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
