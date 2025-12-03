//import 'package:finance_management_frontend/Pages/Accountant/record_item_transaction_screen.dart';
import 'package:finance_management_frontend/Pages/Accountant/accountant_dashboard.dart';
import 'package:finance_management_frontend/Pages/Admin/grades_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/report/reports_main_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/requirement_list_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/requirement_transaction_history_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/student_requirements_screen.dart';
import 'package:finance_management_frontend/provider/receipt_provider.dart';
import 'package:finance_management_frontend/provider/auth_provider.dart';
import 'package:finance_management_frontend/Pages/Accountant/fee_structure_display_screen.dart';
import 'package:finance_management_frontend/Pages/Accountant/print_history_screen.dart';
import 'package:finance_management_frontend/Pages/Accountant/record_item_transaction_screen.dart';
import 'package:finance_management_frontend/Pages/Accountant/students_display_screen.dart';
import 'package:finance_management_frontend/Pages/Accountant/thermal_receipt_preview_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/fee_structure_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/other_fees_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/printer_settings_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/requirement_list_details_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/requirement/student_requirement_details_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/student_onboarding_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/user_management_screen.dart';
import '../Pages/Admin/admin_dashboard_screen.dart';
import '../Pages/Auth/login.dart';
import 'package:finance_management_frontend/provider/theme_provider.dart';
import '../widgets/side_nav_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_management_frontend/Pages/Accountant/payment/student_selection_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/report/report_detail_screen.dart';


/// Main entry point for the Financial Management System
/// 
/// Initializes:
/// - Flutter bindings
/// - Environment variables from .env file
/// - Portrait-only orientation
/// - Riverpod state management
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (API_BASE_URL, etc.)
  await dotenv.load();
  
  // Lock app to portrait orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const ProviderScope(
      child: MyApp(),
    ));
  });
}

/// Root application widget with theme and routing configuration
class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Listen for auth state changes and handle logout
    // This MUST be done in build method, not initState
    ref.listen<AuthState>(authProvider, (previous, next) {
      // User was authenticated but is now logged out
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        print('🚪 Auth state changed: User logged out (token refresh failed)');
        
        // Navigate to login screen and clear navigation stack
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
        
        // Show session expired message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = _navigatorKey.currentContext;
          if (context != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your session has expired. Please log in again.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
      }
    });

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Finance Management System',
      debugShowCheckedModeBanner: false,
      theme: theme,
      initialRoute: authState.isAuthenticated ? _getInitialRoute(authState.userRole) : "/login",
      navigatorObservers: [routeObserver],
      
      // Handle dynamic routes with arguments
      onGenerateRoute: (settings) {
        // Payment route with student argument
        if (settings.name == '/payment') {
          return MaterialPageRoute(
            builder: (context) => SideNavLayout(
              currentRoute: '/payment',
              child: StudentSelectionScreen(),
            ),
          );
        }
        
        // Item transaction recording route
        if (settings.name == '/record-transaction') {
          final studentRequirementId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => SideNavLayout(
              currentRoute: '/record-transaction',
              child: RecordTransactionScreen(studentRequirementId: studentRequirementId),
            ),
          );
        }

        // Requirement list details route
        if (settings.name == '/requirement-list-details') {
          final requirementListId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => SideNavLayout(
              currentRoute: '/requirement-list-details',
              child: RequirementListDetailsScreen(requirementListId: requirementListId),
            ),
          );
        }

        // Student requirement details route
        if (settings.name == '/student-requirement-details') {
          final studentRequirementId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => SideNavLayout(
              currentRoute: '/student-requirement-details',
              child: StudentRequirementDetailsScreen(studentRequirementId: studentRequirementId),
            ),
          );
        }

        // Thermal receipt preview route
        if (settings.name == '/thermal-receipt-preview') {
          final transactionId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => SideNavLayout(
              currentRoute: '/thermal-receipt-preview',
              child: ThermalReceiptPreviewScreen(transactionId: transactionId),
            ),
          );
        }

        // This handles navigation to specific report types with filters
        if (settings.name == '/report-detail') {
          final reportType = settings.arguments as ReportType;
          return MaterialPageRoute(
            builder: (context) => SideNavLayout(
              currentRoute: '/report-detail',
              child: ReportDetailScreen(reportType: reportType),
            ),
          );
        }

        // Return null for unhandled routes (falls back to named routes below)
        return null;
      },
      
      // Named routes for static navigation
      routes: {
        // ==================== AUTHENTICATION ====================
        "/login": (context) => const LoginScreen(),

        // ==================== ADMIN ROUTES ====================
        "/dashboard": (context) => const SideNavLayout(
          currentRoute: '/dashboard',
          child: AdminDashboardScreen(),
        ),
        "/user-management": (context) => SideNavLayout(
          currentRoute: '/user-management',
          child: UserManagementScreen(),
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
        "/grades": (context) => const SideNavLayout(
          currentRoute: '/grades',
          child: GradesScreen(),
        ),
        "/printer-settings": (context) => const SideNavLayout(
          currentRoute: '/printer-settings',
          child: PrinterSettingsScreen(),
        ),

        // Main reports dashboard showing all report types
        "/reports": (context) => const SideNavLayout(
          currentRoute: '/reports',
          child: ReportsScreen(),
        ),
        
        // ==================== ACCOUNTANT ROUTES ====================
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
        "/accountant/print-history": (context) => const SideNavLayout(
          currentRoute: '/accountant/print-history',
          child: PrintHistoryScreen(),
        ),

        // ==================== PAYMENT ROUTES ====================
        "/payments": (context) => const SideNavLayout(
          currentRoute: '/payments',
          child: StudentSelectionScreen(),
        ),

        // ==================== ITEM LEDGER ROUTES ====================
        "/requirement-list": (context) => const SideNavLayout(
          currentRoute: '/requirement-list',
          child: RequirementListsScreen(),
        ),
        "/student-requirement": (context) => const SideNavLayout(
          currentRoute: '/student-requirement',
          child: StudentRequirementsScreen(),
        ),
        "/requirement-transaction-history": (context) {
          final studentRequirementId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return SideNavLayout(
            currentRoute: '/requirement-transaction-history',
            child: RequirementTransactionHistoryScreen(
              studentRequirementId: studentRequirementId,
            ),
          );
        },
      },
    );
  }

  /// Determine initial route based on user role
  String _getInitialRoute(String? userRole) {
    if (userRole == null) return "/login";
    
    switch (userRole.toLowerCase()) {
      case 'accountant':
        return '/accountant/dashboard';
      case 'admin':
      default:
        return '/dashboard';
    }
  }
}

/// Global route observer for tracking navigation lifecycle
/// Used for refreshing data when returning to screens
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
