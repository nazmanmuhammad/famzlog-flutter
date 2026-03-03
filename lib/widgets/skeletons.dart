import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;

  const Skeleton({super.key, this.width, this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class DriverDcListSkeleton extends StatelessWidget {
  const DriverDcListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Skeleton(height: 140, width: double.infinity, radius: 16),
    );
  }
}

class DropOffSkeleton extends StatelessWidget {
  const DropOffSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              const Skeleton(width: 44, height: 44, radius: 10),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Skeleton(width: 100, height: 20, radius: 4),
                  SizedBox(height: 8),
                  Skeleton(width: 60, height: 16, radius: 4),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const Skeleton(height: 180, width: double.infinity, radius: 16),
          ),
        ),
      ],
    );
  }
}

class ShipmentSkeleton extends StatelessWidget {
  const ShipmentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 150, height: 20, radius: 4),
          const SizedBox(height: 12),
          const Skeleton(height: 200, width: double.infinity, radius: 12),
        ],
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Skeleton(width: 100, height: 20, radius: 4),
              Skeleton(width: 60, height: 24, radius: 8),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Skeleton(width: 16, height: 16, radius: 8),
              SizedBox(width: 8),
              Skeleton(width: 120, height: 14, radius: 4),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Skeleton(width: 16, height: 16, radius: 8),
              SizedBox(width: 8),
              Skeleton(width: 80, height: 14, radius: 4),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Skeleton(width: 100, height: 12, radius: 4),
              Skeleton(width: 100, height: 12, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}
