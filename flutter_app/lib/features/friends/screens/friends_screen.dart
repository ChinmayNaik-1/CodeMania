import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:codemania/features/friends/providers/friends_provider.dart';
import 'package:codemania/core/models/friend_model.dart';
import 'package:codemania/core/models/activity_model.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).loadFriends();
      ref.read(friendsProvider.notifier).loadRequests();
      ref.read(friendsProvider.notifier).loadFeed();
      ref.read(friendsProvider.notifier).loadLeaderboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FB),
      appBar: AppBar(
        title: const Text('Community'),
        backgroundColor: const Color(0xFFFDFDFF),
        foregroundColor: const Color(0xFF242453),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5E2ED5),
          unselectedLabelColor: const Color(0xFF8A8A8A),
          indicatorColor: const Color(0xFF5E2ED5),
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Feed'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: state.isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsTab(state.friends),
              _buildRequestsTab(state.pendingRequests),
              _buildFeedTab(state.feed),
              _buildLeaderboardTab(state.friendLeaderboard),
            ],
          ),
    );
  }

  Widget _buildFriendsTab(List<FriendModel> friends) {
    final filtered = friends.where((f) => f.username.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search friends...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              setState(() { _searchQuery = val; });
            },
          ),
        ),
        if (friends.isEmpty)
          const Expanded(child: Center(child: Text('No friends yet. Find users and send requests!')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final friend = filtered[i];
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
                        child: friend.avatarUrl == null ? Text(friend.username[0]) : null,
                      ),
                      if (friend.isOnline)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        )
                    ],
                  ),
                  title: Text(friend.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Solved: ${friend.solvedCount}  🔥${friend.currentStreak}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => context.push('/profile/${friend.id}'),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildRequestsTab(List<FriendModel> requests) {
    if (requests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (ctx, i) {
        final req = requests[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: req.avatarUrl != null ? NetworkImage(req.avatarUrl!) : null,
            child: req.avatarUrl == null ? Text(req.username[0]) : null,
          ),
          title: Text(req.username),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  ref.read(friendsProvider.notifier).respondRequest(req.id, 'accept');
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  ref.read(friendsProvider.notifier).respondRequest(req.id, 'reject');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedTab(List<ActivityModel> feed) {
    if (feed.isEmpty) {
      return const Center(child: Text('No recent activity'));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(friendsProvider.notifier).loadFeed();
      },
      child: ListView.builder(
        itemCount: feed.length,
        itemBuilder: (ctx, i) {
          final act = feed[i];
          String text = '';
          if (act.activityType == 'solved') {
            text = ' solved ${act.problemTitle}';
          } else if (act.activityType == 'contest_joined') {
            text = ' joined ${act.contestTitle}';
          } else if (act.activityType == 'friend_added') {
            text = ' and you are now friends';
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: act.avatarUrl != null ? NetworkImage(act.avatarUrl!) : null,
              child: act.avatarUrl == null ? Text(act.username[0]) : null,
            ),
            title: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(text: act.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: text),
                ],
              ),
            ),
            subtitle: Text(act.createdAt.toLocal().toString().split('.')[0]),
            onTap: () {
              if (act.problemId != null) {
                context.push('/problems/${act.problemId}');
              } else if (act.contestId != null) {
                context.push('/contests/${act.contestId}');
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardTab(List<FriendModel> leaderboard) {
    if (leaderboard.isEmpty) {
      return const Center(child: Text('No leaderboard data'));
    }
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Friends Leaderboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (ctx, i) {
              final user = leaderboard[i];
              return ListTile(
                leading: SizedBox(
                  width: 60,
                  child: Row(
                    children: [
                      Text('#${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                        child: user.avatarUrl == null ? Text(user.username[0], style: const TextStyle(fontSize: 10)) : null,
                      ),
                    ],
                  ),
                ),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${user.solvedCount} solved   🔥${user.currentStreak}', style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
      ],
    );
  }
}
