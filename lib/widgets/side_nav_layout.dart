import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../provider/auth_provider.dart';
import '../provider/theme_provider.dart';

class SideNavLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const SideNavLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Side Navigation
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          authState.username?.substring(0, 1).toUpperCase() ??
                          authState.email?.substring(0, 1).toUpperCase() ?? 'U',
                          style: GoogleFonts.underdog(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      Column(
                        children: [
                          Text(
                            authState.username ?? authState.email ?? 'User',
                            style: GoogleFonts.underdog(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              authState.userRole ?? 'Admin',
                              style: GoogleFonts.underdog(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _buildNavItems(context, authState.userRole ?? 'Admin'),
                  ),
                ),
                
                // Theme Toggle and Logout
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Dark Mode',
                            style: GoogleFonts.underdog(),
                          ),
                          trailing: Switch(
                            value: isDark,
                            onChanged: (value) {
                              ref.read(themeProvider.notifier).toggleTheme();
                            },
                            activeColor: AppColors.primary,
                          ),
                          onTap: () {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.error,
                          ),
                          title: Text(
                            'Logout',
                            style: GoogleFonts.underdog(color: AppColors.error),
                          ),
                          onTap: () {
                            ref.read(authProvider.notifier).logout();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, String userRole) {
    final adminItems = [
      _NavItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        route: '/dashboard',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.people,
        title: 'User Management',
        route: '/user-management',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.grade,
        title: 'Grades',
        route: '/grades',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.school,
        title: 'Student Onboarding',
        route: '/student-onboarding',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.attach_money,
        title: 'Fee Structure',
        route: '/fee-structure',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.payment,
        title: 'Other Fees',
        route: '/other-fees',
        currentRoute: currentRoute,
      ),
      _NavItem(
      icon: Icons.assignment_turned_in,
      title: 'Required Items',
      route: '/requirement-list',
      currentRoute: currentRoute,
      ),
      _NavItem(
      icon: Icons.school_outlined,
      title: 'Student Requirements',
      route: '/student-requirement',
      currentRoute: currentRoute,
      ),
    ];

    final accountantItems = [
      _NavItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        route: '/dashboard',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.school,
        title: 'Students',
        route: 'accountant/students',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.attach_money,
        title: 'Fee Structure',
        route: '/accountant/fee-structure',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.payment,
        title: 'Payments',
        route: '/payments',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.receipt,
        title: 'Items Received',
        route: '/items-received',
        currentRoute: currentRoute,
      ),
      _NavItem(
        icon: Icons.analytics,
        title: 'Reports',
        route: '/reports',
        currentRoute: currentRoute,
      ),
    ];

    return userRole == 'Admin' ? adminItems : accountantItems;
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: AppColors.primary.withValues(alpha: 0.08),
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.currentRoute == widget.route;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : _isHovered
                      ? _colorAnimation.value
                      : Colors.transparent,
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
                  : _isHovered
                      ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                      : null,
              boxShadow: _isHovered && !isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: MouseRegion(
              onEnter: (_) {
                if (!isSelected) {
                  setState(() {
                    _isHovered = true;
                  });
                  _animationController.forward();
                }
              },
              onExit: (_) {
                if (!isSelected) {
                  setState(() {
                    _isHovered = false;
                  });
                  _animationController.reverse();
                }
              },
              child: ListTile(
                leading: Icon(
                  widget.icon,
                  color: isSelected
                      ? AppColors.primary
                      : _isHovered
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : (isDark ? Colors.white70 : Colors.black54),
                ),
                title: Text(
                  widget.title,
                  style: GoogleFonts.underdog(
                    color: isSelected
                        ? AppColors.primary
                        : _isHovered
                            ? AppColors.primary.withValues(alpha: 0.9)
                            : (isDark ? Colors.white : Colors.black87),
                    fontWeight: isSelected || _isHovered 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  if (widget.route != widget.currentRoute) {
                    Navigator.pushReplacementNamed(context, widget.route);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}