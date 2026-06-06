import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../core/layout/main_layout.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/students/students_screen.dart';
import '../../features/classes/classes_screen.dart';
import '../../features/classes/class_details_screen.dart';
import '../../features/teachers/teachers_screen.dart';
import '../../features/payments/payments_screen.dart';
import '../../features/attendance/attendance_screen.dart';

// Fournisseur du routeur principal de l'application
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/classes',
            builder: (context, state) => const ClassesScreen(),
          ),
          GoRoute(
            path: '/classes/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ClassDetailsScreen(classIdStr: id);
            },
          ),
          GoRoute(
            path: '/teachers',
            builder: (context, state) => const TeachersScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
        ],
      ),
    ],
  );
});
