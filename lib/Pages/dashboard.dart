
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: SelectableText("Dashboard"),   
      ),
      body: Center(
        child: SelectableText("Welcome to the Dashboard!"),
      )
    );
  }
}