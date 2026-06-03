import 'package:codemania/features/problem/widgets/description_tab.dart';
import 'package:codemania/features/submissions/widgets/submissions_tab.dart';
import 'package:codemania/models/problem_model.dart';
import 'package:flutter/material.dart';

class TabBarPanel extends StatefulWidget {
  const TabBarPanel({
    super.key,
    required this.problem,
    required this.panelWidth,
    required this.problemId,
    required this.tabController,
  });

  final Problem problem;
  final double panelWidth;
  final int problemId;
  final TabController tabController;

  @override
  State<TabBarPanel> createState() => _TabBarPanelState();
}

class _TabBarPanelState extends State<TabBarPanel> {

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: widget.panelWidth,
      child: ClipRect(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: widget.tabController,
                  tabs: const [
                    Tab(text: 'Description'),
                    Tab(text: 'Solutions'),
                    Tab(text: 'Submissions'),
                  ],
                  indicatorColor: const Color(0xFFFFA116),
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: const Color(0xFFFFA116),
                  unselectedLabelColor:
                      isDark ? const Color(0xFF8A8A8A) : const Color(0xFF595959),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                  isScrollable: false,
                  padding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: widget.tabController,
                children: [
                  DescriptionTab(problem: widget.problem),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.construction_outlined,
                          size: 48,
                          color: Color(0xFF3A3A3A),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Solutions coming soon',
                          style: TextStyle(
                            color: Color(0xFF8A8A8A),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SubmissionsTab(
                    problemId: widget.problemId.toString(),
                  ),
                ],
              ),
            ),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF7F7F7),
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.thumb_up_outlined,
                    size: 15,
                    color: Color(0xFF8A8A8A),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '24.5K',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.thumb_down_outlined,
                    size: 15,
                    color: Color(0xFF8A8A8A),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: Color(0xFF8A8A8A),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '658',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                  ),
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2CBB5D),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Online',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
