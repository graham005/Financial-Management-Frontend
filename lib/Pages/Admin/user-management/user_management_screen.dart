import 'package:finance_management_frontend/provider/user_management.dart';
import 'package:finance_management_frontend/widgets/confirmation_dialog.dart';
import 'package:finance_management_frontend/widgets/modal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_colors.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = "All Roles";
  List<User> _filteredUsers = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers(List<User> users) {
    setState(() {
      _filteredUsers = users.where((user) {
        final matchesSearch = user.username.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                             user.email.toLowerCase().contains(_searchController.text.toLowerCase());
        final matchesRole = _selectedRole == "All Roles" || user.role == _selectedRole;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: SelectableText("User Management", style: GoogleFonts.underdog(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Filter Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          usersAsyncValue.whenData((users) => _filterUsers(users));
                        },
                        style: GoogleFonts.underdog(),
                        decoration: InputDecoration(
                          hintText: "Search users...",
                          hintStyle: GoogleFonts.underdog(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.primary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      underline: const SizedBox(),
                      style: GoogleFonts.underdog(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      items: ["All Roles", "Admin", "Accountant"].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: SelectableText(role, style: GoogleFonts.underdog()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                        usersAsyncValue.whenData((users) => _filterUsers(users));
                      },
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showUserForm(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text("Add New User", style: GoogleFonts.underdog(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Users Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: usersAsyncValue.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          "Error loading users",
                          style: GoogleFonts.underdog(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          error.toString(),
                          style: GoogleFonts.underdog(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(userProvider.notifier).fetchUsers();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: SelectableText(
                            "Retry",
                            style: GoogleFonts.underdog(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (users) {
                    if (_filteredUsers.isEmpty && users.isNotEmpty) {
                      _filterUsers(users);
                    }
                    
                    if (_filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              "No users found",
                              style: GoogleFonts.underdog(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.primary.withValues(alpha: 0.1),
                        ),
                        columns: [
                          DataColumn(
                            label: SelectableText(
                              "ID",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: SelectableText(
                              "USER",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: SelectableText(
                              "EMAIL",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: SelectableText(
                              "ROLE",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                          DataColumn(
                            label: SelectableText(
                              "ACTIONS",
                              style: GoogleFonts.underdog(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                        rows: _filteredUsers.map((user) {
                          return DataRow(
                            cells: [
                              DataCell(SelectableText(user.id, style: GoogleFonts.underdog())),
                              DataCell(SelectableText(user.username, style: GoogleFonts.underdog())),
                              DataCell(SelectableText(user.email, style: GoogleFonts.underdog())),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: user.role == "Admin" 
                                        ? AppColors.primary.withValues(alpha: 0.2)
                                        : AppColors.secondary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: user.role == "Admin" 
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ),
                                  ),
                                  child: SelectableText(
                                    user.role,
                                    style: GoogleFonts.underdog(
                                      color: user.role == "Admin" 
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _showUserForm(context, userData: user.toJson()),
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColors.primary,
                                      ),
                                      tooltip: "Edit User",
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: AppColors.error,
                                      ),
                                      tooltip: "Delete User",
                                      onPressed: () async {
                                        final shouldDelete = await showConfirmationDialog(
                                          context,
                                          "Are you sure you want to delete this user?",
                                        );

                                        if (shouldDelete) {
                                          final success = await ref.read(userProvider.notifier).deleteUser(user.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: SelectableText(
                                                  success 
                                                      ? "User deleted successfully"
                                                      : "Failed to delete user",
                                                  style: GoogleFonts.underdog(),
                                                ),
                                                backgroundColor: success ? AppColors.success : AppColors.error,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          final username = usernameController.text.trim();
          final email = emailController.text.trim();
          final password = passwordController.text.trim();
          final role = selectedRole;

          if (username.isEmpty || email.isEmpty || (!isEdit && password.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText("Please fill all required fields", style: GoogleFonts.underdog()),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          bool success;
          if (isEdit) {
            success = await ref.read(userProvider.notifier).updateUser(
              id: userData["id"],
              username: username,
              email: email,
              role: role!,
            );
          } else {
            success = await ref.read(userProvider.notifier).addUser(
              username: username,
              email: email,
              password: password,
              role: role!,
            );
          }

          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectableText(
                  success
                      ? (isEdit ? "User updated successfully" : "User added successfully")
                      : "An error occurred",
                  style: GoogleFonts.underdog(),
                ),
                backgroundColor: success ? AppColors.success : AppColors.error,
              ),
            );
          }
        },
        children: [
          TextField(
            controller: usernameController,
            style: GoogleFonts.underdog(),
            decoration: InputDecoration(
              labelText: "Username",
              labelStyle: GoogleFonts.underdog(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            style: GoogleFonts.underdog(),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Email",
              labelStyle: GoogleFonts.underdog(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isEdit)
            TextField(
              controller: passwordController,
              style: GoogleFonts.underdog(),
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: GoogleFonts.underdog(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          if (!isEdit) const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedRole,
            style: GoogleFonts.underdog(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black,
            ),
            items: ["Admin", "Accountant"].map((role) {
              return DropdownMenuItem(
                value: role,
                child: SelectableText(role, style: GoogleFonts.underdog()),
              );
            }).toList(),
            onChanged: (value) => selectedRole = value,
            decoration: InputDecoration(
              labelText: "Role",
              labelStyle: GoogleFonts.underdog(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}