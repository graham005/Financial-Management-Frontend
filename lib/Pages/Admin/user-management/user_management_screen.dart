import 'package:finance_management_frontend/provider/user_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserManagementScreen extends ConsumerWidget{
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   final users = ref.watch(userProvider);
   // final userNotifier = ref.read(userProvider.notifier);

   return Scaffold(
    appBar: AppBar(
      title: Text("User Management"),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextField(
                decoration: InputDecoration(
                  hintText: "Search users...",
                  prefixIcon: Icon(Icons.search),
                ),
              )),
              SizedBox(width: 16),
              DropdownButton(
                value: "All Roles",
                items: ["All Roles", "Admin", "Accountant"].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role)
                  );
                }).toList(), 
                onChanged: (value) {},
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},  //TODO: Redirect to add new user page 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("+ Add New User")
              )
            ],
          ),
          SizedBox(height: 16),
          DataTable(
            columns: [
              DataColumn(label: Text("ID")),
              DataColumn(label: Text("USER")),
              DataColumn(label: Text("EMAIL")),
              DataColumn(label: Text("ROLE")),
              DataColumn(label: Text("ACTIONs")),
            ], 
            rows: users.map((user) {
              return DataRow(cells: [
                DataCell(Text(user.id)),
                DataCell(Text(user.username)),
                DataCell(Text(user.email)),
                DataCell(Container(
                  padding: EdgeInsets.all(4),
                  color: user.role == "Admin" ? Colors.blue : Colors.green,
                  child: Text(user.role),
                )),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},  // TODO: redirect to edit user page
                        icon: Icon(Icons.edit)
                      ),
                      IconButton(
                        onPressed: () {}, // TODO: redirect to delete user page 
                        icon: Icon(Icons.delete)
                      )
                    ],
                  )
                )
              ]);
            }).toList(),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {},  //TODO: Implement previous paging
                child: Text("Previous")
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {}, // TODO: Impement next paging
                child: Text("Next")
              )
            ],
          )
        ],
      ),
    ),
   );
  }
}