import 'package:flutter/material.dart';
import 'package:leasure_nft/app/core/widgets/shimmer_loader.dart';

class TaskShimmer extends StatelessWidget {
  const TaskShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4, // Show 4 shimmer items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task title shimmer
              const ShimmerLoader(
                height: 20,
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              const SizedBox(height: 8),

              // Task description shimmer
              const ShimmerLoader(
                height: 16,
                width: double.infinity,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              const SizedBox(height: 4),
              const ShimmerLoader(
                height: 16,
                width: 200,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              const SizedBox(height: 12),

              // Task reward shimmer
              const ShimmerLoader(
                height: 18,
                width: 120,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              const SizedBox(height: 16),

              // Button shimmer
              Row(
                children: [
                  Expanded(
                    child: ShimmerLoader(
                      height: 40,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class TaskListShimmer extends StatelessWidget {
  const TaskListShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const TaskShimmer(),
    );
  }
}
