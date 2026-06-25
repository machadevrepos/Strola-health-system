import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Strolla Health — single source of truth for all icons.
///
/// Rules:
///   • ALWAYS reference AppIcons constants — never use Icons.* directly in widgets.
///   • All icons are from the Material outline family (`_outlined` or `_outline`).
///   • Never use filled icon variants (no Icons.home, Icons.favorite, etc.).
///   • Where no `_outlined` variant exists, the closest outline-style equivalent
///     is used — see individual comments.
///   • Icon size is NOT specified here. Use AppTheme.iconS/M/L/XL at call site.
class AppIcons {
  AppIcons._();

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData home = Icons.home_outlined;
  static const IconData stats =
      Icons.bar_chart; // no _outlined — thin by design
  static const IconData start = Icons.directions_run_outlined;
  static const IconData community = Icons.group_outlined;
  static const IconData profile = Icons.person_outlined;

  // ─────────────────────────────────────────────────────────────────────────
  // APP BAR / GLOBAL ACTIONS
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData notifications = Icons.notifications_outlined;
  static const IconData search = Icons.search_outlined;
  static const IconData more =
      Icons.more_horiz; // no _outlined — already stroke-based
  static const IconData settings = Icons.settings_outlined;
  static const IconData filter =
      Icons.tune; // no _outlined — already line-based
  static const IconData back =
      Icons.arrow_back_ios_new; // no _outlined; stroke is thin by default
  static const IconData close =
      Icons.close; // no _outlined; already stroke-based
  static const IconData add = Icons.add; // no _outlined; stroke-based
  static const IconData remove = Icons.remove; // no _outlined; stroke-based
  static const IconData check = Icons.check; // stroke-based
  static const IconData chevronLeft = Icons.chevron_left; // stroke-based
  static const IconData chevronRight = Icons.chevron_right; // stroke-based
  static const IconData expandMore = Icons.expand_more_outlined; // dropdown
  static const IconData trendUp =
      Icons.arrow_upward_outlined; // positive trend indicator
  static const IconData trendDown =
      Icons.arrow_downward_outlined; // negative trend indicator

  // ─────────────────────────────────────────────────────────────────────────
  // FITNESS / ACTIVITY METRICS
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData steps = Icons.directions_walk_outlined;
  static const IconData run = Icons.directions_run_outlined;
  static const IconData walk = Icons.directions_walk_outlined;
  static const IconData calories = Icons.local_fire_department_outlined;
  static const IconData distance =
      Icons.straighten; // no _outlined; already line-based
  static const IconData route =
      Icons.route_outlined; // route path for GPS activities
  static const IconData showChart =
      Icons.show_chart; // line chart — no _outlined; stroke-based
  static const IconData duration = Icons.schedule_outlined;
  static const IconData pace = Icons.speed; // no _outlined variant in Material
  static const IconData heart =
      Icons.favorite_border; // "border" is the outline variant
  static const IconData heartRate = Icons.monitor_heart_outlined;
  static const IconData weight = Icons.monitor_weight_outlined;
  static const IconData sleep = Icons.bedtime_outlined;

  // ─────────────────────────────────────────────────────────────────────────
  // ACTIVITY TYPES — session picker icons
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData treadmill = Icons.fitness_center_outlined;
  static const IconData strength = Icons.sports_gymnastics_outlined;
  static const IconData yoga = Icons.self_improvement_outlined;
  static const IconData pilates = Icons.accessibility_new_outlined;
  static const IconData otherActivity = Icons.category_outlined;

  // ─────────────────────────────────────────────────────────────────────────
  // GOALS & ACHIEVEMENTS
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData goal = Icons.flag_outlined;
  static const IconData target = Icons.adjust; // bullseye — "% of goal"
  static const IconData goalReached = Icons.check_circle_outline;
  static const IconData milestone = Icons.outlined_flag;
  static const IconData streak = Icons.local_fire_department_outlined;
  static const IconData trophy = Icons.emoji_events_outlined;
  static const IconData premium = Icons.workspace_premium_outlined;
  static const IconData star =
      Icons.star_border; // no _outlined — already outline style
  static const IconData badge = Icons.verified_outlined;
  static const IconData earlyBird =
      Icons.wb_twilight_outlined; // "Early Bird" achievement badge

  // ─────────────────────────────────────────────────────────────────────────
  // SESSION / WORKOUT
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData play = Icons.play_circle_outline;
  static const IconData pause = Icons.pause_circle_outline;
  static const IconData stop =
      Icons.stop_circle_outlined; // confirmed exists in Material
  static const IconData controlPlay =
      Icons.play_arrow_outlined; // bare glyph for circular transport controls
  static const IconData controlPause =
      Icons.pause_outlined; // bare glyph for circular transport controls
  static const IconData controlStop =
      Icons.stop_outlined; // bare glyph for circular transport controls
  static const IconData map = Icons.map_outlined;
  static const IconData location = Icons.location_on_outlined;
  static const IconData gps = Icons.gps_fixed_outlined;
  static const IconData timer = Icons.timer_outlined;
  static const IconData lock = Icons.lock_outline;

  // ─────────────────────────────────────────────────────────────────────────
  // BLE / DEVICE
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData bluetooth = Icons.bluetooth_outlined;
  static const IconData bluetoothSearch =
      Icons.bluetooth_searching; // no _outlined
  static const IconData watch = Icons.watch_outlined;
  static const IconData bluetoothConnected =
      Icons.bluetooth_connected; // no _outlined
  static const IconData bluetoothDisabled =
      Icons.bluetooth_disabled; // no _outlined; stroke-based
  static const IconData battery =
      Icons.battery_std; // no _outlined variant in Material

  // ─────────────────────────────────────────────────────────────────────────
  // COMMUNITY
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData like = Icons.favorite_border;
  static const IconData comment = Icons.chat_bubble_outline;
  static const IconData share =
      Icons.share_outlined; // classic share glyph — never mistaken for download
  static const IconData people = Icons.group_outlined;
  static const IconData personSearch =
      Icons.person_search_outlined; // "find friends" empty state
  static const IconData report = Icons.flag_outlined; // report user/post
  static const IconData addFriend =
      Icons.person_add_alt_1_outlined; // invite / add friend
  static const IconData public = Icons.public_outlined; // post visibility

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND GLYPHS — external platform identities. These are an intentional
  // exception to the outline-only rule (they represent third-party brands).
  // Used only inside BrandLogo. Never use as generic UI icons.
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData brandFacebook = Icons.facebook; // official "f" mark
  // FaIconData (Font Awesome) — render with FaIcon, not Icon.
  static const FaIconData brandWhatsapp =
      FontAwesomeIcons.whatsapp; // official WhatsApp mark
  static const FaIconData brandTiktok =
      FontAwesomeIcons.tiktok; // official TikTok mark
  static const IconData friends = Icons.people_outline;
  static const IconData challenge = Icons.emoji_events_outlined;

  // ─────────────────────────────────────────────────────────────────────────
  // HEALTH / BODY
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData cycle = Icons.water_drop_outlined;
  static const IconData integrations = Icons.link_outlined;
  static const IconData privacy = Icons.lock_outline;
  static const IconData apple =
      Icons.apple; // Apple Health (no _outlined variant)

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData info = Icons.info_outline;
  static const IconData sparkle = Icons.auto_awesome_outlined; // decorative sparkle accent
  static const IconData sun = Icons.wb_sunny_outlined; // decorative sun
  static const IconData park = Icons.park_outlined; // decorative nature
  static const IconData flora = Icons.local_florist_outlined; // decorative flower
  static const IconData ecology = Icons.eco_outlined; // leaf / laurel
  static const IconData leaderboard = Icons.leaderboard_outlined;
  static const IconData celebration = Icons.celebration_outlined;
  static const IconData groups = Icons.groups_outlined;
  static const IconData warning =
      Icons.warning_amber_rounded; // no _outlined — rounded is closest outline
  static const IconData error = Icons.error_outline;
  static const IconData calendar = Icons.calendar_today_outlined;
  static const IconData calendarMonth = Icons.calendar_month_outlined;
  static const IconData camera = Icons.camera_alt_outlined;
  static const IconData gallery = Icons.photo_library_outlined;
  static const IconData addPhoto = Icons.add_photo_alternate_outlined;
  static const IconData image = Icons.image_outlined;
  static const IconData copy = Icons.copy_outlined;
  static const IconData link = Icons.link_outlined;
  static const IconData email = Icons.mail_outline;
  static const IconData help = Icons.help_outline;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;

  // ─────────────────────────────────────────────────────────────────────────
  // PROFILE / ONBOARDING
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData edit = Icons.edit_outlined;
  static const IconData height = Icons.straighten; // ruler — line-based
  static const IconData gender = Icons.wc; // no _outlined variant
  static const IconData units = Icons.public_outlined; // globe
  static const IconData stroller = Icons.child_friendly_outlined;
  static const IconData work = Icons.work_outline;

  // ─────────────────────────────────────────────────────────────────────────
  // SETTINGS
  // ─────────────────────────────────────────────────────────────────────────

  static const IconData password = Icons.lock_outline;
  static const IconData block = Icons.block; // no-entry circle
  static const IconData connectedApps =
      Icons.extension_outlined; // puzzle piece
  static const IconData document = Icons.description_outlined;
  static const IconData shield = Icons.shield_outlined;
  static const IconData logout = Icons.logout;
}
