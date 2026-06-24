import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the active tab inside [MainShell] — 0:Home, 1:Stats,
/// 2:Community, 3:Challenges.
///
/// Lets screens nested inside MainShell (e.g. HomeScreen's "View Stats"
/// link or streak card) switch tabs directly, instead of pushing a new
/// route that would escape MainShell's gradient background and bottom nav.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);
