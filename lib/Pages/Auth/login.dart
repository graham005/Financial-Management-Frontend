import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../provider/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int selectedColorIndex = 0;
  bool showColorOptions = false;
  bool _obscureText = true;
  bool _isLoading = false;

  // Color palette options for background
  final List<Color> backgroundColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.richBlackPrimary,
    AppColors.richBlackSecondary,
    AppColors.accent,
  ];

  final List<String> colorNames = [
    'Orange',
    'Coral',
    'Dark',
    'Navy',
    'Red',
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        height: 49,
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: showColorOptions
                  ? ShowUpAnimation(
                      delay: 100,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: backgroundColors.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColorIndex = index;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: selectedColorIndex == index
                                    ? Colors.white
                                    : Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: backgroundColors[index],
                                    child: SelectableText(
                                      colorNames[index].substring(0, 1),
                                      style: GoogleFonts.underdog(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : const SizedBox(),
            ),
            const SizedBox(width: 20),
            showColorOptions
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        showColorOptions = false;
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        showColorOptions = true;
                      });
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: backgroundColors[selectedColorIndex],
                          child: Icon(
                            Icons.palette,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColors[selectedColorIndex],
              backgroundColors[selectedColorIndex].withValues(alpha: 0.8),
              backgroundColors[selectedColorIndex].withValues(alpha: 0.6),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          height: 500,
          width: 400,
          margin: const EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
            color: Colors.black.withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 15, sigmaX: 15),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      // Logo and Title
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              child: Icon(
                                Icons.school,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SelectableText(
                              "Finance Management",
                              style: GoogleFonts.underdog(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              "Destiny Junior Academy",
                              style: GoogleFonts.underdog(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      
                      // Email Field
                      SelectableText(
                        "Email",
                        style: GoogleFonts.underdog(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextFormField(
                          style: GoogleFonts.underdog(color: Colors.white),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: "Enter your email",
                            hintStyle: GoogleFonts.underdog(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            suffixIcon: const Icon(
                              Icons.email,
                              color: Colors.white,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Password Field
                      SelectableText(
                        "Password",
                        style: GoogleFonts.underdog(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: TextFormField(
                          style: GoogleFonts.underdog(color: Colors.white),
                          controller: _passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            hintStyle: GoogleFonts.underdog(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      
                      // Login Button
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.white.withValues(alpha: 0.9)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        backgroundColors[selectedColorIndex],
                                      ),
                                    ),
                                  )
                                : SelectableText(
                                    "Sign In",
                                    style: GoogleFonts.underdog(
                                      color: backgroundColors[selectedColorIndex],
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar("Please enter both email and password");
      return;
    }

    // Basic email validation
    if (!_isValidEmail(email)) {
      _showErrorSnackBar("Please enter a valid email address");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).login(email, password);
      if (mounted) {
        Navigator.pushReplacementNamed(context, "/dashboard");
      }
    } catch (e) {
      if (mounted) {
        print(e);
        _showErrorSnackBar("Invalid credentials. Please try again.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          message,
          style: GoogleFonts.underdog(),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
