import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:codemania/app_theme.dart';
import 'package:codemania/models/contest_model.dart';
import 'package:codemania/models/submission_model.dart';
import 'package:codemania/providers/contest_provider.dart';
import 'package:codemania/services/socket_service.dart';

class ContestRoomScreen extends ConsumerStatefulWidget {
  final ContestModel contest;
  final int teamId;

  const ContestRoomScreen({
    Key? key,
    required this.contest,
    required this.teamId,
  }) : super(key: key);

  @override
  ConsumerState<ContestRoomScreen> createState() => _ContestRoomScreenState();
}

class _ContestRoomScreenState extends ConsumerState<ContestRoomScreen> {
  int _selectedTab = 0;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _endTime = widget.contest.endTime;
    _startTimerUpdates();
    _initializeSocket();
  }

  void _initializeSocket() async {
    try {
      await SocketService.connect();
      SocketService.joinContest(widget.contest.id, widget.teamId, '');
      ref.read(contestProvider.notifier).fetchLeaderboard(widget.contest.id);
    } catch (e) {
      print('Socket error: $e');
    }
  }

  void _startTimerUpdates() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _endTime = widget.contest.endTime;
        });
        _startTimerUpdates();
      }
    });
  }

  @override
  void dispose() {
    SocketService.leaveContest(widget.contest.id, widget.teamId);
    SocketService.disconnect();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final contestState = ref.watch(contestProvider);
    final timeRemaining = _endTime.difference(DateTime.now());
    final isEnded = timeRemaining.isNegative;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contest.title),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.primaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Time Remaining', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  isEnded ? 'Contest Ended' : _formatDuration(timeRemaining),
                  style: TextStyle(
                    color: isEnded ? Colors.red : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Tab(
                    text: 'Problems',
                    icon: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      child: Icon(Icons.assignment, color: _selectedTab == 0 ? AppTheme.primaryColor : Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                    child: Icon(Icons.leaderboard, color: _selectedTab == 1 ? AppTheme.primaryColor : Colors.grey),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = 2;
                      });
                    },
                    child: Icon(Icons.feed, color: _selectedTab == 2 ? AppTheme.primaryColor : Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildTabContent(contestState),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ContestState contestState) {
    switch (_selectedTab) {
      case 0:
        return _buildProblemsTab();
      case 1:
        return _buildLeaderboardTab(contestState);
      case 2:
        return _buildTeamFeedTab(contestState);
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildProblemsTab() {
    if (widget.contest.problems == null || widget.contest.problems!.isEmpty) {
      return const Center(child: Text('No problems in this contest'));
    }

    return ListView.builder(
      itemCount: widget.contest.problems!.length,
      itemBuilder: (context, index) {
        final problem = widget.contest.problems![index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(problem.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(problem.difficulty),
                      backgroundColor: AppTheme.getDifficultyColor(problem.difficulty),
                      labelStyle: const TextStyle(color: Colors.white),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('${problem.points} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab(ContestState contestState) {
    if (contestState.leaderboard.isEmpty) {
      return const Center(child: Text('No leaderboard data'));
    }

    return ListView.builder(
      itemCount: contestState.leaderboard.length,
      itemBuilder: (context, index) {
        final team = contestState.leaderboard[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${index + 1}. ${team.teamName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(team.members.join(', '), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${team.score}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    Text('Solved: ${team.solvedCount}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamFeedTab(ContestState contestState) {
    if (contestState.teamFeed.isEmpty) {
      return const Center(child: Text('No submissions yet'));
    }

    return ListView.builder(
      reverse: true,
      itemCount: contestState.teamFeed.length,
      itemBuilder: (context, index) {
        final entry = contestState.teamFeed[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry['username'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getVerdictColor(entry['verdict'] ?? 'pending'),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        AppTheme.getVerdictLabel(entry['verdict'] ?? 'pending'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(entry['problemTitle'] ?? 'Unknown Problem'),
                const SizedBox(height: 4),
                Text(entry['timestamp'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
