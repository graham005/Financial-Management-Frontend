import 'package:finance_management_frontend/Pages/Admin/grades_screen.dart';
import 'Pages/Accountant/payment_screen.dart';
import 'Pages/Admin/fee_structure_screen.dart';
import 'Pages/Admin/items_management.dart';
import 'Pages/Admin/other_fees_screen.dart';
import 'Pages/Admin/student_onboarding_screen.dart';
import 'Pages/Admin/user_management_screen.dart';
import '../Pages/Admin/admin_dashboard_screen.dart';
import '../Pages/Auth/login.dart';
import 'package:finance_management_frontend/provider/theme_provider.dart';
import '../widgets/side_nav_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(ProviderScope(
      child: MyApp(),
    ));
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Finance Management System',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: "/login",
      navigatorObservers: [routeObserver],
      routes: {
        "/login": (context) => const LoginScreen(),
        "/dashboard": (context) => const SideNavLayout(
              currentRoute: '/dashboard',
              child: AdminDashboardScreen(),
            ),
        "/user-management": (context) => SideNavLayout(
              currentRoute: '/user-management',
              child: UserManagementScreen(),
            ),
            "/grades": (context) => const SideNavLayout(
              currentRoute: '/grades',
              child: GradesScreen(),
            ),
        "/student-onboarding": (context) => SideNavLayout(
              currentRoute: '/student-onboarding',
              child: StudentOnboardingScreen(),
            ),
        "/fee-structure": (context) => SideNavLayout(
              currentRoute: '/fee-structure',
              child: FeeStructureScreen(),
            ),
        "/other-fees": (context) => const SideNavLayout(
              currentRoute: '/other-fees',
              child: OtherFeesScreen(),
            ),
        "/required-items": (context) => const SideNavLayout(
              currentRoute: '/required-items',
              child: ItemsManagementScreen(),
            ),
        "/payments": (context) => const SideNavLayout(
              currentRoute: '/payments',
              child: PaymentScreen(),
            ),
      },
    );
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();


