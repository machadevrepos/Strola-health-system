import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strola_health/core/constants/app_colors.dart';
import 'package:strola_health/domain/entities/challenge.dart';
import 'package:strola_health/domain/entities/community_post.dart';

// Mock community repository — swap for Firebase implementation when ready.
// All methods mirror what a real Firestore-backed repo would expose.

class CommunityRepository {
  List<CommunityPost> _posts = _seedPosts();
  List<Challenge> _challenges = _seedChallenges();

  Future<List<CommunityPost>> getPosts({int page = 0, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 600)); // simulate network
    final start = page * limit;
    if (start >= _posts.length) return [];
    return _posts.sublist(start, min(start + limit, _posts.length));
  }

  Future<CommunityPost> likePost(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) throw Exception('Post not found');
    final post = _posts[idx];
    final updated = post.copyWith(
      isLiked: !post.isLiked,
      likes: post.isLiked ? post.likes - 1 : post.likes + 1,
    );
    _posts = [..._posts]..[idx] = updated;
    return updated;
  }

  Future<CommunityPost> createPost(
    String content, {
    int? stepCount,
    String? imagePath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final post = CommunityPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'You',
      content: content,
      timestamp: DateTime.now(),
      avatarColor: AppColors.accent.toARGB32(),
      likes: 0,
      comments: 0,
      stepCount: stepCount,
      imageUrl: imagePath,
    );
    _posts = [post, ..._posts];
    return post;
  }

  Future<List<Challenge>> getChallenges() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _challenges;
  }

  Future<Challenge> joinChallenge(String challengeId) async {
    final idx = _challenges.indexWhere((c) => c.id == challengeId);
    if (idx < 0) throw Exception('Challenge not found');
    final updated = _challenges[idx].copyWith(isJoined: true);
    _challenges = [..._challenges]..[idx] = updated;
    return updated;
  }

  static List<CommunityPost> _seedPosts() {
    final now = DateTime.now();
    return [
      CommunityPost(
        id: '1',
        authorName: 'Sarah M',
        content:
            '🎉 Just hit 10,000 steps for the 5th day in a row! Consistency is key. Who else is on a streak?',
        timestamp: now.subtract(const Duration(minutes: 12)),
        avatarColor: 0xFF7C3AED,
        likes: 24,
        comments: 8,
        stepCount: 10247,
        badgeEmoji: '🔥',
      ),
      CommunityPost(
        id: '2',
        authorName: 'James K',
        content:
            'Morning walk at the park — absolutely love how the Strolla device tracks every step. 6.2 km done before breakfast! 🌅',
        timestamp: now.subtract(const Duration(hours: 1)),
        avatarColor: 0xFF0891B2,
        likes: 18,
        comments: 5,
        stepCount: 8100,
      ),
      CommunityPost(
        id: '3',
        authorName: 'Priya S',
        content:
            'Finally broke my 5k step barrier after my knee injury. Small wins matter. Thank you all for the support! 💪',
        timestamp: now.subtract(const Duration(hours: 3)),
        avatarColor: 0xFFDB2777,
        likes: 47,
        comments: 14,
        stepCount: 5320,
        badgeEmoji: '⭐',
      ),
      CommunityPost(
        id: '4',
        authorName: 'Tom B',
        content:
            'Pro tip: park further away from the entrance and take stairs instead of elevators. I added 2,000 steps to my daily count without any extra workout!',
        timestamp: now.subtract(const Duration(hours: 5)),
        avatarColor: 0xFF059669,
        likes: 33,
        comments: 11,
      ),
      CommunityPost(
        id: '5',
        authorName: 'Alex R',
        content:
            'Week 1 of the 70k Challenge complete ✅ Averaged 10,200 steps/day. This community keeps me going!',
        timestamp: now.subtract(const Duration(hours: 8)),
        avatarColor: 0xFFD97706,
        likes: 29,
        comments: 7,
        stepCount: 71400,
        badgeEmoji: '🏆',
      ),
      CommunityPost(
        id: '6',
        authorName: 'Mei L',
        content:
            'Rainy day = indoor steps. Paced my living room for 45 minutes and somehow got to 4,800 steps 😂 never giving up on that goal!',
        timestamp: now.subtract(const Duration(hours: 14)),
        avatarColor: 0xFF7C3AED,
        likes: 52,
        comments: 19,
        stepCount: 4800,
      ),
      CommunityPost(
        id: '7',
        authorName: 'Dan H',
        content:
            'New personal best: 18,432 steps! Went for a long hike with friends. Strolla BLE held the connection the entire time 🙌',
        timestamp: now.subtract(const Duration(days: 1)),
        avatarColor: 0xFF0891B2,
        likes: 61,
        comments: 22,
        stepCount: 18432,
        badgeEmoji: '🏔️',
      ),
    ];
  }

  static List<Challenge> _seedChallenges() {
    final now = DateTime.now();
    return [
      Challenge(
        id: 'c1',
        title: '10K Daily Streak',
        description: 'Hit 10,000 steps every day for 7 days straight.',
        goalSteps: 70000,
        startDate: now.subtract(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 4)),
        isJoined: true,
        badgeEmoji: '🔥',
        accentColorValue: AppColors.accent.toARGB32(),
        mySteps: 31200,
        participants: [
          const ChallengeParticipant(
            name: 'Alex R',
            steps: 42100,
            rank: 1,
            avatarColor: 0xFFD97706,
          ),
          const ChallengeParticipant(
            name: 'Sarah M',
            steps: 38500,
            rank: 2,
            avatarColor: 0xFF7C3AED,
          ),
          const ChallengeParticipant(
            name: 'You',
            steps: 31200,
            rank: 3,
            isMe: true,
          ),
          const ChallengeParticipant(
            name: 'Dan H',
            steps: 28900,
            rank: 4,
            avatarColor: 0xFF0891B2,
          ),
          const ChallengeParticipant(
            name: 'Priya S',
            steps: 21000,
            rank: 5,
            avatarColor: 0xFFDB2777,
          ),
        ],
      ),
      Challenge(
        id: 'c2',
        title: '50 km This Month',
        description: 'Walk or run 50 kilometres before the month ends.',
        goalSteps: 65616, // ~50km at 0.762m/step
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        isJoined: false,
        badgeEmoji: '🗺️',
        accentColorValue: AppColors.accentSecondary.toARGB32(),
        mySteps: 0,
        participants: [
          const ChallengeParticipant(
            name: 'Tom B',
            steps: 52400,
            rank: 1,
            avatarColor: 0xFF059669,
          ),
          const ChallengeParticipant(
            name: 'James K',
            steps: 48900,
            rank: 2,
            avatarColor: 0xFF0891B2,
          ),
          const ChallengeParticipant(
            name: 'Mei L',
            steps: 41200,
            rank: 3,
            avatarColor: 0xFF7C3AED,
          ),
          const ChallengeParticipant(
            name: 'Alex R',
            steps: 33100,
            rank: 4,
            avatarColor: 0xFFD97706,
          ),
        ],
      ),
      Challenge(
        id: 'c3',
        title: 'Weekend Warrior',
        description: 'Get 25,000 steps over Saturday and Sunday.',
        goalSteps: 25000,
        startDate: now.subtract(
          Duration(
            days: now.weekday - 6 < 0 ? 7 + (now.weekday - 6) : now.weekday - 6,
          ),
        ),
        endDate: now.add(Duration(days: 7 - now.weekday)),
        isJoined: true,
        badgeEmoji: '⚡',
        accentColorValue: AppColors.accent.toARGB32(),
        mySteps: 14300,
        participants: [
          const ChallengeParticipant(
            name: 'Dan H',
            steps: 22800,
            rank: 1,
            avatarColor: 0xFF0891B2,
          ),
          const ChallengeParticipant(
            name: 'You',
            steps: 14300,
            rank: 2,
            isMe: true,
          ),
          const ChallengeParticipant(
            name: 'Priya S',
            steps: 12100,
            rank: 3,
            avatarColor: 0xFFDB2777,
          ),
        ],
      ),
    ];
  }
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (_) => CommunityRepository(),
);
