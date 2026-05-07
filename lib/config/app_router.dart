import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mchs_mobile_app/screens/login_screen.dart';
import 'package:mchs_mobile_app/screens/register_screen.dart';
import 'package:mchs_mobile_app/screens/forgot_password_screen.dart';
import 'package:mchs_mobile_app/screens/splash_screen.dart';
import 'package:mchs_mobile_app/screens/guest_conversion_screen.dart';
import 'package:mchs_mobile_app/providers/auth_provider.dart';
import 'package:mchs_mobile_app/screens/home_screen.dart';
import 'package:mchs_mobile_app/screens/lecture_detail_screen.dart';
import 'package:mchs_mobile_app/screens/lectures_screen.dart';
import 'package:mchs_mobile_app/screens/profile_screen.dart';
import 'package:mchs_mobile_app/screens/profile_security_screen.dart';
import 'package:mchs_mobile_app/screens/user_statistics_screen.dart';
import 'package:mchs_mobile_app/screens/test_detail_screen.dart';
import 'package:mchs_mobile_app/screens/test_result_screen.dart';
import 'package:mchs_mobile_app/screens/test_taking_screen.dart';
import 'package:mchs_mobile_app/screens/tests_screen.dart';
import 'package:mchs_mobile_app/screens/test_history_screen.dart';
import 'package:mchs_mobile_app/screens/admin_dashboard_screen.dart';
import 'package:mchs_mobile_app/screens/admin_users_screen.dart';
import 'package:mchs_mobile_app/screens/admin_tests_screen.dart';
import 'package:mchs_mobile_app/screens/admin_lectures_screen.dart';
import 'package:mchs_mobile_app/screens/admin_reports_screen.dart';
import 'package:mchs_mobile_app/screens/create_test_screen.dart';
import 'package:mchs_mobile_app/screens/create_lecture_screen.dart';
import 'package:mchs_mobile_app/screens/import_test_screen.dart';
import 'package:mchs_mobile_app/screens/edit_test_screen.dart';
import 'package:mchs_mobile_app/widgets/main_shell.dart';

class Routes {
  Routes._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';
  static const String guestConversion = 'guest-conversion';

  static const String home = 'home';
  static const String lectures = 'lectures';
  static const String lectureDetail = 'lecture-detail';
  static const String tests = 'tests';
  static const String testDetail = 'test-detail';
  static const String testTaking = 'test-taking';
  static const String testResult = 'test-result';
  static const String testHistory = 'test-history';
  static const String lectureTests = 'lecture-tests';
  static const String profile = 'profile';
  static const String profileSecurity = 'profile-security';
  static const String userStatistics = 'user-statistics';
  static const String adminDashboard = 'admin-dashboard';
  static const String adminUsers = 'admin-users';
  static const String adminTests = 'admin-tests';
  static const String adminLectures = 'admin-lectures';
  static const String adminReports = 'admin-reports';
  static const String createTest = 'create-test';
  static const String createLecture = 'create-lecture';
  static const String importTest = 'import-test';
  static const String editTest = 'edit-test';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
GoRouter? _cachedRouter;
final appRouterProvider = Provider<GoRouter>((ref) {
  if (_cachedRouter != null) {
    return _cachedRouter!;
  }

  _cachedRouter = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);

      final isLoggedIn = authState.isAuthenticated;
      final isGuest = authState.isGuest;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/splash';

      if (state.matchedLocation == '/splash') {
        return null;
      }

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn &&
          !isGuest &&
          isAuthRoute &&
          state.matchedLocation != '/splash') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/guest-conversion',
        name: Routes.guestConversion,
        builder: (context, state) => const GuestConversionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/lectures',
            name: Routes.lectures,
            builder: (context, state) => const LecturesScreen(),
          ),
          GoRoute(
            path: '/tests',
            name: Routes.tests,
            builder: (context, state) {
              final lectureIdStr = state.uri.queryParameters['lectureId'];
              final lectureId = lectureIdStr != null
                  ? int.tryParse(lectureIdStr)
                  : null;
              return TestsScreen(lectureId: lectureId);
            },
          ),
          GoRoute(
            path: '/profile',
            name: Routes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/admin-dashboard',
            name: Routes.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/lecture-detail/:id',
        name: Routes.lectureDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) return const _InvalidIdScreen();
          return LectureDetailScreen(lectureId: id);
        },
      ),
      GoRoute(
        path: '/test-detail/:id',
        name: Routes.testDetail,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) return const _InvalidIdScreen();
          return TestDetailScreen(testId: id);
        },
      ),
      GoRoute(
        path: '/lecture-tests/:lectureId',
        name: Routes.lectureTests,
        builder: (context, state) {
          final lectureId = int.tryParse(
            state.pathParameters['lectureId'] ?? '',
          );
          if (lectureId == null || lectureId <= 0) {
            return const _InvalidIdScreen();
          }
          return TestsScreen(lectureId: lectureId);
        },
      ),
      GoRoute(
        path: '/test-history',
        name: Routes.testHistory,
        builder: (context, state) => const TestHistoryScreen(),
      ),

      GoRoute(
        path: '/profile-security',
        name: Routes.profileSecurity,
        builder: (context, state) => const ProfileSecurityScreen(),
      ),
      GoRoute(
        path: '/user-statistics',
        name: Routes.userStatistics,
        builder: (context, state) => const UserStatisticsScreen(),
      ),
      GoRoute(
        path: '/admin-users',
        name: Routes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin-tests',
        name: Routes.adminTests,
        builder: (context, state) => const AdminTestsScreen(),
      ),
      GoRoute(
        path: '/admin-lectures',
        name: Routes.adminLectures,
        builder: (context, state) => const AdminLecturesScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: Routes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/create-test',
        name: Routes.createTest,
        builder: (context, state) => const CreateTestScreen(),
      ),
      GoRoute(
        path: '/admin/create-lecture',
        name: Routes.createLecture,
        builder: (context, state) => const CreateLectureScreen(),
      ),
      GoRoute(
        path: '/admin/import-test',
        name: Routes.importTest,
        builder: (context, state) => const ImportTestFromPdfScreen(),
      ),
      GoRoute(
        path: '/admin/edit-test/:testId',
        name: Routes.editTest,
        builder: (context, state) {
          final testId = int.tryParse(state.pathParameters['testId'] ?? '');
          if (testId == null || testId <= 0) return const _InvalidIdScreen();
          return EditTestScreen(testId: testId);
        },
      ),
      GoRoute(
        path: '/test-taking/:testId',
        name: Routes.testTaking,
        builder: (context, state) {
          final testId = int.tryParse(state.pathParameters['testId'] ?? '');
          if (testId == null || testId <= 0) return const _InvalidIdScreen();
          return TestTakingScreen(testId: testId);
        },
      ),
      GoRoute(
        path: '/test-result/:testResultId',
        name: Routes.testResult,
        builder: (context, state) {
          final testResultId = int.tryParse(
            state.pathParameters['testResultId'] ?? '',
          );
          if (testResultId == null || testResultId <= 0) {
            return const _InvalidIdScreen();
          }
          return TestResultScreen(testResultId: testResultId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Страница не найдена',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    ),
  );

  return _cachedRouter!;
});

class _InvalidIdScreen extends StatelessWidget {
  const _InvalidIdScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Некорректная ссылка',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Параметр запроса не распознан.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
