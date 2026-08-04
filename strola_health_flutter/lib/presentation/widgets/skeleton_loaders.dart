import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/presentation/widgets/flat_card.dart';

// ── Reusable skeleton shimmer wrappers ────────────────────────────────────────
// Wrap any widget: Skeletonizer(enabled: isLoading, child: realWidget)
// Or use these prebuilt skeletons for specific sections.

class WorkoutLogSkeleton extends StatelessWidget {
  const WorkoutLogSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.accentSecondary.withValues(alpha: 0.15),
        highlightColor: AppColors.accentSecondary.withValues(alpha: 0.35),
        duration: const Duration(milliseconds: 1200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const _SessionCardSkeleton(),
      ),
    );
  }
}

class _SessionCardSkeleton extends StatelessWidget {
  const _SessionCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  color: AppColors.accentSecondary.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 80,
                  color: AppColors.accentSecondary.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: 16,
                width: 70,
                color: AppColors.accentSecondary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 6),
              Container(
                height: 11,
                width: 90,
                color: AppColors.accentSecondary.withValues(alpha: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PostFeedSkeleton extends StatelessWidget {
  const PostFeedSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.accentSecondary.withValues(alpha: 0.15),
        highlightColor: AppColors.accentSecondary.withValues(alpha: 0.35),
        duration: const Duration(milliseconds: 1200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _PostCardSkeleton(),
      ),
    );
  }
}

class _PostCardSkeleton extends StatelessWidget {
  const _PostCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    width: 100,
                    color: AppColors.accentSecondary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: 60,
                    color: AppColors.accentSecondary.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 13,
            width: double.infinity,
            color: AppColors.accentSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 6),
          Container(
            height: 13,
            width: 200,
            color: AppColors.accentSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                height: 11,
                width: 50,
                color: AppColors.accentSecondary.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              Container(
                height: 11,
                width: 60,
                color: AppColors.accentSecondary.withValues(alpha: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.accentSecondary.withValues(alpha: 0.15),
        highlightColor: AppColors.accentSecondary.withValues(alpha: 0.35),
        duration: const Duration(milliseconds: 1200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => FlatCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: 160,
                      color: AppColors.accentSecondary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 11,
                      width: 200,
                      color: AppColors.accentSecondary.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      color: AppColors.accentSecondary.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengeSkeleton extends StatelessWidget {
  const ChallengeSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.accentSecondary.withValues(alpha: 0.15),
        highlightColor: AppColors.accentSecondary.withValues(alpha: 0.35),
        duration: const Duration(milliseconds: 1200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => FlatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 15,
                          width: 160,
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 11,
                          width: 100,
                          color: AppColors.accentSecondary.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
