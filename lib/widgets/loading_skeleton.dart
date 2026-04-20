import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                0.0,
                _animation.value - 0.3,
                _animation.value,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and time row
            Row(
              children: [
                LoadingSkeleton(
                  height: 24,
                  width: 80,
                  borderRadius: BorderRadius.circular(20),
                ),
                const Spacer(),
                LoadingSkeleton(
                  height: 20,
                  width: 60,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Guard info row
            Row(
              children: [
                LoadingSkeleton(
                  height: 16,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 8),
                LoadingSkeleton(
                  height: 16,
                  width: 120,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Location info row
            Row(
              children: [
                LoadingSkeleton(
                  height: 16,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 8),
                LoadingSkeleton(
                  height: 16,
                  width: 150,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Notes section
            LoadingSkeleton(
              height: 40,
              width: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

class GuardCardSkeleton extends StatelessWidget {
  const GuardCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar skeleton
            LoadingSkeleton(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(24),
            ),
            const SizedBox(width: 16),
            // Info skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    height: 16,
                    width: 100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  LoadingSkeleton(
                    height: 14,
                    width: 150,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 6),
                  LoadingSkeleton(
                    height: 12,
                    width: 80,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
            ),
            // Menu skeleton
            LoadingSkeleton(
              height: 24,
              width: 24,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationCardSkeleton extends StatelessWidget {
  const LocationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Location icon skeleton
            LoadingSkeleton(
              height: 48,
              width: 48,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 16),
            // Info skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton(
                    height: 16,
                    width: 120,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  LoadingSkeleton(
                    height: 14,
                    width: 180,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  LoadingSkeleton(
                    height: 12,
                    width: 100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
            // Menu skeleton
            LoadingSkeleton(
              height: 24,
              width: 24,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCardSkeleton extends StatelessWidget {
  const StatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          LoadingSkeleton(
            height: 24,
            width: 24,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 8),
          LoadingSkeleton(
            height: 20,
            width: 30,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 4),
          LoadingSkeleton(
            height: 12,
            width: 60,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}
