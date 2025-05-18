import 'package:finance_management_frontend/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardScreen extends ConsumerWidget{
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold (
      appBar: AppBar(
        title: Text("School Admin Dashboard"),
        actions: [
          CircleAvatar(
            backgroundImage: NetworkImage("https://via.placeholder.com/30"),
          ),
          SizedBox(width: 8,),
          Text("John Anderson"),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: Text("Logout")),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Metric Cards
                MetricCard(
                  title: "Total Users",
                  value: "248",
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                MetricCard(
                  title: "Total Students",
                  value: "1,234",
                  icon: Icons.school,
                  color: Colors.green,
                ),
                MetricCard(
                  title: "Active Grades",
                  value: "12",
                  icon: Icons.class_,
                  color: Colors.purple,
                ),
                MetricCard(
                  title: "Fee Structures",
                  value: "8",
                  icon: Icons.attach_money,
                  color: Colors.orange,
                ),
              ],
            ),
            SizedBox(height: 24),

            // Quick Actions
            Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {}, //TODO: Implement the page to redirect to
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("Users"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {}, //TODO: Implement the page to redirect to
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Students"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {}, //TODO: Implement the page to redirect to
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: Text("Fee Structure"),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Recent Activity
            Text(
              "Recent Activity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DataTable(
              columns: [
                DataColumn(label: Text("Action")),
                DataColumn(label: Text("User")),
                DataColumn(label: Text("Time")),
                DataColumn(label: Text("Status"))
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text("New User Created")),
                  DataCell(Text("Sarah Wilson")),
                  DataCell(Text("2 minutes ago")),
                  DataCell(Container(
                    padding: EdgeInsets.all(4),
                    color: Colors.lightGreenAccent,
                    child: Text("Completed"),
                  )),
                ]),
                DataRow(cells: [
                  DataCell(Text("Student Onboarded")),
                  DataCell(Text("Mike Johnson")),
                  DataCell(Text("15 minutes ago")),
                  DataCell(Container(
                    padding: EdgeInsets.all(4),
                    color: Colors.lightGreenAccent,
                    child: Text("Completed"),
                  )),
                ]),
                DataRow(cells: [
                  DataCell(Text("Fee Structure Updated")),
                  DataCell(Text("David Brown")),
                  DataCell(Text("1 hour ago")),
                  DataCell(Container(
                    padding: EdgeInsets.all(4),
                    color: Colors.lightGreenAccent,
                    child: Text("Completed"),
                  )),
                ]),
              ]
            )
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({super.key, 
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment:  CrossAxisAlignment.start,
              children: [
                Text(title, style:TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(title, style:TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ),
      ),
    );
  }
}