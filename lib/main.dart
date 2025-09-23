//import 'package:finance_management_frontend/Pages/Accountant/record_item_transaction_screen.dart';
import 'package:finance_management_frontend/Pages/Accountant/accountant_dashboard.dart';
import 'package:finance_management_frontend/Pages/Admin/grades_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/requirement_list_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/student_requirements_screen.dart';
import 'Pages/Accountant/fee_structure_display_screen.dart';
import 'Pages/Accountant/print_history_screen.dart';
import 'Pages/Accountant/record_item_transaction_screen.dart';
import 'Pages/Accountant/students_display_screen.dart';
import 'Pages/Accountant/thermal_receipt_preview_screen.dart';
import 'Pages/Admin/fee_structure_screen.dart';
import 'Pages/Admin/other_fees_screen.dart';
import 'Pages/Admin/printer_settings_screen.dart';
import 'Pages/Admin/requirement/requirement_list_details_screen.dart';
import 'Pages/Admin/requirement/student_requirement_details_screen.dart';
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
import 'Pages/Accountant/payment/student_selection_screen.dart';

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
        "/payments": (context) => const SideNavLayout(
              currentRoute: '/payments',
              child: StudentSelectionScreen(),
            ),
        "/accountant/dashboard": (context) => const SideNavLayout(
              currentRoute: '/accountant/dashboard',
              child: AccountantDashboardScreen(),
            ),
        "accountant/students": (context) => const SideNavLayout(
              currentRoute: 'accountant/students',
              child: StudentsDisplayScreen(),
            ),
        "/accountant/fee-structure": (context) => const SideNavLayout(
              currentRoute: '/accountant/fee-structure',
              child: FeeStructureDisplayScreen(),
            ),
        "/requirement-list": (context) => const SideNavLayout(
              currentRoute: '/requirement-list',
              child: RequirementListsScreen(),
            ),
        "/requirement-list-details": (context) {
          final requirementListId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return SideNavLayout(
            currentRoute: '/requirement-list-details',
            child: RequirementListDetailsScreen(
                requirementListId: requirementListId),
          );
        },
        "/student-requirement": (context) => const SideNavLayout(
              currentRoute: '/student-requirement',
              child: StudentRequirementsScreen(),
            ),
        "/student-requirement-details": (context) {
          final studentRequirementId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return SideNavLayout(
            currentRoute: '/student-requirement-details',
            child: StudentRequirementDetailsScreen(
                studentRequirementId: studentRequirementId),
          );
        },
        "/record-transaction": (context) {
          final studentRequirementId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return SideNavLayout(
            currentRoute: '/record-transaction',
            child: RecordTransactionScreen(
                studentRequirementId: studentRequirementId),
          );
        },
        "/thermal-receipt-preview": (context) {
          final transactionId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return SideNavLayout(
            currentRoute: '/thermal-receipt-preview',
            child: ThermalReceiptPreviewScreen(transactionId: transactionId),
          );
        },
        "/printer-settings": (context) => const SideNavLayout(
              currentRoute: '/printer-settings',
              child: PrinterSettingsScreen(),
            ),
        "/accountant/print-history": (context) => const SideNavLayout(
              currentRoute: '/accountant/print-history',
              child: PrintHistoryScreen(),
            ),
      },
    );
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
