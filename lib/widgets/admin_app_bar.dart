import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;

  const AdminAppBar({ 
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.flexibleSpace,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: backgroundColor != null 
            ? [backgroundColor!, backgroundColor!]
            : [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: _buildTitle(context),
        leading: leading ?? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: elevation ?? 0,
        flexibleSpace: flexibleSpace,
        bottom: bottom,
        actions: actions,
        iconTheme: IconThemeData(
          color: foregroundColor ?? Colors.white,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          color: foregroundColor ?? Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (centerTitle) ...[
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: TextStyle(
            color: foregroundColor ?? Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        if (centerTitle) ...[
          const SizedBox(width: 12),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
