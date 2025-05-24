import 'package:finance_management_frontend/Pages/Admin/fee-structure/fee_structure_screen.dart';
import 'package:finance_management_frontend/Pages/Admin/user-management/user_management_screen.dart';
//import 'package:finance_management_frontend/Pages/Auth/login.dart';
import 'package:finance_management_frontend/Pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(ProviderScope(
      child: MyApp(),
    ));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(textTheme: TextTheme(bodyMedium: TextStyle(fontFamily: GoogleFonts.underdog().fontFamily))),
      initialRoute: "/",
      routes: {
        "/": (context) => UserManagementScreen(),
        "/dashboard": (context) => DashboardScreen(),
      }
    );
  }
}


