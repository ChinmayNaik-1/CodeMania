import 'package:codemania/screens/admin/admin_dashboard.dart';
import 'package:codemania/features/admin/screens/admin_contests_screen.dart';
import 'package:codemania/features/admin/screens/create_contest_screen.dart';
import 'package:codemania/screens/admin/create_problem_screen.dart';
import 'package:codemania/screens/admin/manage_problems_screen.dart';
import 'package:codemania/screens/auth/google_signup_completion_screen.dart';
import 'package:codemania/screens/auth/login_screen.dart';
import 'package:codemania/screens/auth/register_screen.dart';
import 'package:codemania/features/contests/screens/contest_detail_screen.dart';
import 'package:codemania/features/contests/screens/contest_problem_screen.dart';
import 'package:codemania/screens/problem_page/problem_page.dart';
import 'package:codemania/screens/public/landing_screen.dart';
import 'package:codemania/screens/user/home_screen.dart';
import 'package:codemania/screens/user/profile_screen.dart';
import 'package:codemania/features/friends/screens/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/google-signup-complete',
        name: 'googleSignupComplete',
        builder: (context, state) => const GoogleSignupCompletionScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/problems/create',
        name: 'createProblem',
        builder: (context, state) => const CreateProblemScreen(),
      ),
      GoRoute(
        path: '/admin/problems/:id/edit',
        name: 'editProblem',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return CreateProblemScreen(editingProblemId: id);
        },
      ),
      GoRoute(
        path: '/admin/problems/manage',
        name: 'manageProblems',
        builder: (context, state) => const ManageProblemsScreen(),
      ),
      GoRoute(
        path: '/admin/contests/create',
        name: 'createContest',
        builder: (context, state) => const CreateContestScreen(),
      ),
      GoRoute(
        path: '/admin/contests/:id/edit',
        name: 'editContest',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return CreateContestScreen(contestId: id);
        },
      ),
      GoRoute(
        path: '/admin/contests',
        name: 'adminContests',
        builder: (context, state) => const AdminContestsScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/profile/:userId',
        name: 'profile',
        builder: (context, state) {
          final userId = int.tryParse(state.pathParameters['userId'] ?? '0') ?? 0;
          return ProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/friends',
        name: 'friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/problems',
        name: 'problemList',
        builder: (context, state) => const HomeScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/problems/:id',
        name: 'problemDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ProblemPage(problemId: id);
        },
      ),
      GoRoute(
        path: '/contests',
        name: 'contestList',
        builder: (context, state) => const HomeScreen(initialTab: 2),
      ),
      GoRoute(
        path: '/contests/:contestId',
        name: 'contestDetail',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['contestId'] ?? '0') ?? 0;
          return ContestDetailScreen(contestId: id);
        },
      ),
      GoRoute(
        path: '/contests/:contestId/problems/:problemId',
        name: 'contestProblemDetail',
        builder: (context, state) {
          final contestId = int.tryParse(state.pathParameters['contestId'] ?? '0') ?? 0;
          final problemId = int.tryParse(state.pathParameters['problemId'] ?? '0') ?? 0;
          return ContestProblemScreen(contestId: contestId, problemId: problemId);
        },
      ),
    ],
    redirect: (context, routerState) {
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '404',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFA116),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Page not found',
              style: TextStyle(color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

