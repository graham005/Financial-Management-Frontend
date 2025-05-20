import 'package:dio/dio.dart';
import 'package:finance_management_frontend/provider/user_management.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends ConsumerWidget{
  const UserManagementScreen({super.key});

  void _showUserForm(BuildContext context, {Map<String, dynamic>? userData}) {
    final isEdit = userData != null;
    final usernameController = TextEditingController(text: userData?["username"]);
    final emailController = TextEditingController(text: userData?["email"]);
    final passwordController = TextEditingController();
    String? selectedRole = userData?["role"] ?? "Admin";

    showDialog(
      context: context, 
      builder: (context) => ModalForm(
        title: isEdit ? "Edit User" : "Add New User", 
        onSave: () async {
          final username = usernameController.text;
          final email = emailController.text;
          final password = passwordController.text;
          final role = selectedRole;


          if(username.isEmpty || email.isEmpty || (!isEdit && password.isEmpty)){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Please fill all fields")),
            );
            return;
          }

          try {
            final dio = Dio(BaseOptions(baseUrl: "")); //TODO: Add URL from .env
            if (isEdit) {
              await dio.put("/user/${userData["id"]}", data: {
                "username": username,
                "email": email,
                "role": role,
              });
            } else {
              await dio.post("/user", data: {
                "username": username,
                "email": email,
                "password": password,
                "role": role,
              });
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isEdit ? "User updated successfully" : "User added successfully"))
            );
          } catch (e){
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("An error occured: $e"))
            );
          }
        },
        children: [
          TextField(
            controller: usernameController,
            decoration: InputDecoration(labelText: "Username"),
          ),
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: "Password"),
          ),

          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedRole,
            items: ["Admin", "Accountant"].map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(), 
            onChanged: (value) => selectedRole = value,
            decoration: InputDecoration(labelText: "Role"),
            )
        ], 
      )
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   final users = ref.watch(userProvider);
   // final userNotifier = ref.read(userProvider.notifier);

   return Scaffold(
    appBar: AppBar(
      title: Text("User Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
                SizedBox(
                width: 200, // Adjust the width as needed
                child: TextField(
                  decoration: InputDecoration(
                  hintText: "Search users...",
                  prefixIcon: Icon(Icons.search),
                  ),
                ),
                ),
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
                Spacer(),
                ElevatedButton(
                onPressed: () => _showUserForm(context),  
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: Text("+ Add New User", style: GoogleFonts.underdog(color: Colors.white)),
                ),
            ],
          ),
          SizedBox(height: 16),
          DataTable(
            columns: [
              DataColumn(label: Text("ID", style: GoogleFonts.underdog())),
              DataColumn(label: Text("USER", style: GoogleFonts.underdog())),
              DataColumn(label: Text("EMAIL", style: GoogleFonts.underdog())),
              DataColumn(label: Text("ROLE", style: GoogleFonts.underdog())),
              DataColumn(label: Text("ACTIONs", style: GoogleFonts.underdog())),
            ], 
            rows: users.map((user) {
              return DataRow(cells: [
                DataCell(Text(user.id, style: GoogleFonts.underdog())),
                DataCell(Text(user.username, style: GoogleFonts.underdog())),
                DataCell(Text(user.email, style: GoogleFonts.underdog())),
                DataCell(Container(
                  padding: EdgeInsets.all(4),
                  color: user.role == "Admin" ? Colors.blue : Colors.green,
                  child: Text(user.role, style: GoogleFonts.underdog()),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},  //TODO: Implement previous paging
                child: Text("Previous", style: GoogleFonts.underdog())
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {}, // TODO: Impement next paging
                child: Text("Next", style: GoogleFonts.underdog())
              )
            ],
          )
        ],
      ),
    ),
   );
  }
}