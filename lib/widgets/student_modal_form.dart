import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../provider/grade_provider.dart';

class StudentModalForm extends ConsumerStatefulWidget {
  final String title;
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSave;

  const StudentModalForm({
    super.key,
    required this.title,
    this.initialData,
    required this.onSave,
  });

  @override
  ConsumerState<StudentModalForm> createState() => _StudentModalFormState();
}

class _StudentModalFormState extends ConsumerState<StudentModalForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Student Controllers
  late TextEditingController _admissionNumberController;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _birthdateController;
  
  // Parent Controllers
  late TextEditingController _parentFirstNameController;
  late TextEditingController _parentLastNameController;
  late TextEditingController _parentPhoneNumberController;
  
  String? _selectedGradeId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data if editing
    _admissionNumberController = TextEditingController(text: widget.initialData?['admissionNumber'] ?? '');
    _firstNameController = TextEditingController(text: widget.initialData?['firstName'] ?? '');
    _middleNameController = TextEditingController(text: widget.initialData?['middleName'] ?? '');
    _lastNameController = TextEditingController(text: widget.initialData?['lastName'] ?? '');
    _birthdateController = TextEditingController(text: widget.initialData?['birthdate'] ?? '');
    _parentFirstNameController = TextEditingController(text: widget.initialData?['parentFirstName'] ?? '');
    _parentLastNameController = TextEditingController(text: widget.initialData?['parentLastName'] ?? '');
    _parentPhoneNumberController = TextEditingController(text: widget.initialData?['parentPhoneNumber'] ?? '');
    
    _selectedGradeId = widget.initialData?['gradeName'];
    
    if (widget.initialData?['birthdate'] != null && widget.initialData!['birthdate'].isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(widget.initialData!['birthdate']);
      } catch (e) {
        _selectedDate = null;
      }
    }
  }

  @override
  void dispose() {
    _admissionNumberController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _parentFirstNameController.dispose();
    _parentLastNameController.dispose();
    _parentPhoneNumberController.dispose();
    super.dispose();
  }

  String _generateFullName() {
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    
    List<String> nameParts = [];
    if (firstName.isNotEmpty) nameParts.add(firstName);
    if (middleName.isNotEmpty) nameParts.add(middleName);
    if (lastName.isNotEmpty) nameParts.add(lastName);
    
    return nameParts.join(' ');
  }

  String _generateParentName() {
    final firstName = _parentFirstNameController.text.trim();
    final lastName = _parentLastNameController.text.trim();
    
    List<String> nameParts = [];
    if (firstName.isNotEmpty) nameParts.add(firstName);
    if (lastName.isNotEmpty) nameParts.add(lastName);
    
    return nameParts.join(' ');
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: isDark ? Brightness.dark : Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthdateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradesAsyncValue = ref.watch(gradeProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Center(
        child: Text(
          widget.title,
          style: GoogleFonts.underdog(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      content: SizedBox(
        width: 700,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Information Section
                Text(
                  'Student Information',
                  style: GoogleFonts.underdog(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Admission Number (Full Width)
                TextFormField(
                  controller: _admissionNumberController,
                  style: GoogleFonts.underdog(),
                  decoration: _buildInputDecoration('Admission Number *', Icons.numbers),
                  validator: (value) => value?.isEmpty ?? true ? 'Admission number is required' : null,
                ),
                const SizedBox(height: 16),
                
                // First Name and Last Name Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        style: GoogleFonts.underdog(),
                        decoration: _buildInputDecoration('First Name *', Icons.person),
                        validator: (value) => value?.isEmpty ?? true ? 'First name is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        style: GoogleFonts.underdog(),
                        decoration: _buildInputDecoration('Last Name *', Icons.person),
                        validator: (value) => value?.isEmpty ?? true ? 'Last name is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Middle Name and Grade Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _middleNameController,
                        style: GoogleFonts.underdog(),
                        decoration: _buildInputDecoration('Middle Name', Icons.person_outline),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: gradesAsyncValue.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('Error loading grades', style: GoogleFonts.underdog()),
                        data: (grades) => DropdownButtonFormField<String>(
                          value: _selectedGradeId,
                          style: GoogleFonts.underdog(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: _buildInputDecoration('Grade *', Icons.school),
                          items: grades.map((grade) {
                            return DropdownMenuItem(
                              value: grade.name,
                              child: Text(grade.name, style: GoogleFonts.underdog()),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedGradeId = value),
                          validator: (value) => value == null ? 'Please select a grade' : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Birthdate
                TextFormField(
                  controller: _birthdateController,
                  style: GoogleFonts.underdog(),
                  readOnly: true,
                  decoration: _buildInputDecoration('Birthdate *', Icons.calendar_today).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_today, color: AppColors.primary),
                      onPressed: _selectDate,
                    ),
                  ),
                  onTap: _selectDate,
                  validator: (value) => value?.isEmpty ?? true ? 'Birthdate is required' : null,
                ),
                const SizedBox(height: 24),
                
                // Parent Information Section
                Text(
                  'Parent Information',
                  style: GoogleFonts.underdog(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Parent First Name and Last Name Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _parentFirstNameController,
                        style: GoogleFonts.underdog(),
                        decoration: _buildInputDecoration('Parent First Name *', Icons.person),
                        validator: (value) => value?.isEmpty ?? true ? 'Parent first name is required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _parentLastNameController,
                        style: GoogleFonts.underdog(),
                        decoration: _buildInputDecoration('Parent Last Name *', Icons.person),
                        validator: (value) => value?.isEmpty ?? true ? 'Parent last name is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Parent Phone Number
                TextFormField(
                  controller: _parentPhoneNumberController,
                  style: GoogleFonts.underdog(),
                  decoration: _buildInputDecoration('Parent Phone Number *', Icons.phone),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Parent phone number is required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: GoogleFonts.underdog(fontSize: 16),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 32),
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: GoogleFonts.underdog(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: const Text('Save Student'),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.underdog(
        color: isDark ? Colors.white70 : Colors.black54,
      ),
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha:0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withValues(alpha:0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      filled: true,
      fillColor: isDark 
          ? AppColors.darkBackground.withValues(alpha:0.5)
          : AppColors.lightBackground.withValues(alpha:0.5),
    );
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final studentData = {
        'admissionNumber': _admissionNumberController.text.trim(),
        'name': _generateFullName(),
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'birthdate': _birthdateController.text.trim(),
        'gradeName': _selectedGradeId,
        'parentName': _generateParentName(),
        'parentFirstName': _parentFirstNameController.text.trim(),
        'parentLastName': _parentLastNameController.text.trim(),
        'parentPhoneNumber': _parentPhoneNumberController.text.trim(),
      };
      
      widget.onSave(studentData);
    }
  }
}