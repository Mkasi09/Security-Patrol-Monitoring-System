import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_drawer.dart';

class ActiveGuardsScreen extends StatelessWidget {
  const ActiveGuardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AdminAppBar(
        title: 'Active Guards',
      ),
      drawer: const AdminDrawer(),
      body: SafeArea(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_alt,
                size: 64,
                color: AppTheme.primaryColor,
              ),
              SizedBox(height: 16),
              Text(
                'Active Guards',
                style: AppTheme.heading2,
              ),
              SizedBox(height: 8),
              Text(
                'This feature is coming soon!',
                style: AppTheme.body1,
              ),
              SizedBox(height: 16),
              Text(
                'You will be able to view currently active guards,\ntheir locations, and patrol status here.',
                style: AppTheme.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
