import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.radius = 18,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF262A2F) : const Color(0xFFE9EDF2),
      highlightColor: dark ? const Color(0xFF32373D) : Colors.white,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF262A2F) : const Color(0xFFE9EDF2),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class NewsSkeletonList extends StatelessWidget {
  const NewsSkeletonList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          LoadingSkeleton(height: 170, radius: 20),
          SizedBox(height: 10),
          LoadingSkeleton(height: 16, width: 220, radius: 8),
          SizedBox(height: 8),
          LoadingSkeleton(height: 14, width: 140, radius: 8),
        ],
      ),
    );
  }
}
