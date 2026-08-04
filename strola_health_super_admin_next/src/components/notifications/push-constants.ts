// iOS visually truncates a notification body around ~178 characters (2-3
// lines) before collapsing to "…"; Android wraps a touch more generously,
// around ~240. Capping both fields to the tighter iOS figures keeps a
// message intact — untruncated — on either platform.
export const PUSH_TITLE_MAX = 65;
export const PUSH_BODY_MAX = 178;

export const PUSH_TEMPLATES = [
  { label: "New Challenge of the Month", title: "🎉 July Challenge is Live!", body: "Join now and compete for the top spot." },
  { label: "New Feature", title: "🚀 New Feature: Share your steps", body: "Share your daily step count straight to Instagram — try it from your profile." },
  { label: "Holiday Message", title: "🎄 Happy Holidays from Strolla", body: "However you're spending today, we hope it includes a good walk. See you in the new year!" },
  { label: "Maintenance Notice", title: "🔧 Scheduled maintenance", body: "Strolla will be briefly unavailable tonight between 2–3am for scheduled maintenance." },
] as const;

// Reference only — these aren't composed here, they fire automatically from
// app/backend logic. Source of truth is notification_copy.dart and
// notification_providers.dart (device) and functions/src/push/notifyEvents.ts
// (server) in the other two repos — keep this list in sync if either changes.
export type NotificationTriggerSource = "device" | "server";

export interface NotificationTrigger {
  category: string;
  title: string;
  cause: string;
  sample: string;
  source: NotificationTriggerSource;
}

export const NOTIFICATION_TRIGGERS: NotificationTrigger[] = [
  {
    category: "Goal reminder",
    title: "Daily Goal",
    cause: "Evening nudge if a user is 75%+ of the way to their daily step goal but hasn't hit it by 7pm.",
    sample: "You're only 1,200 steps away from today's goal.",
    source: "device",
  },
  {
    category: "Goal achieved",
    title: "Goal Achieved",
    cause: "The moment a user's step count crosses their daily goal.",
    sample: "Goal achieved! Nice work today.",
    source: "device",
  },
  {
    category: "Streak milestone",
    title: "Streak",
    cause: "Current streak reaches 3 or 7 days, then every 7 days after that.",
    sample: "You're on a 7-day streak.",
    source: "device",
  },
  {
    category: "Streak record eve",
    title: "Streak",
    cause: "Tomorrow would set a new personal-best streak if it continues.",
    sample: "One more day and you'll hit a new streak record.",
    source: "device",
  },
  {
    category: "Challenge started",
    title: "Challenge Update",
    cause: "First time a challenge the user has joined shows up as live.",
    sample: "The July Challenge has begun!",
    source: "device",
  },
  {
    category: "Challenge rank",
    title: "Challenge Update",
    cause: "The user's leaderboard position improves in a challenge they've joined.",
    sample: "You've moved up 3 places this week in July Challenge.",
    source: "device",
  },
  {
    category: "Challenge ending soon",
    title: "Challenge Update",
    cause: "A joined challenge has 3 or fewer days left.",
    sample: "Only 2 days left in July Challenge.",
    source: "device",
  },
  {
    category: "Device disconnected",
    title: "Device",
    cause: "The paired Strolla device drops its Bluetooth connection mid-use.",
    sample: "Your Strolla device disconnected. Reconnect to keep tracking steps.",
    source: "device",
  },
  {
    category: "Low battery",
    title: "Battery",
    cause: "Stub — the device firmware doesn't report a battery level yet, so this can't actually fire in production.",
    sample: "Your Strolla battery is running low.",
    source: "device",
  },
  {
    category: "Personal record",
    title: "New Personal Record",
    cause: "A completed session beats the user's prior best for its category.",
    sample: "You just set a new record: Longest walk!",
    source: "device",
  },
  {
    category: "New comment",
    title: "New comment",
    cause: "Someone else comments on the user's post.",
    sample: "Someone commented on your post.",
    source: "server",
  },
  {
    category: "New like",
    title: "New like",
    cause: "Someone else likes the user's post.",
    sample: "Someone liked your post.",
    source: "server",
  },
  {
    category: "Challenge joined",
    title: "Challenge joined",
    cause: "Confirmation sent to a user right after they join a challenge.",
    sample: "You're in — good luck in July Challenge!",
    source: "server",
  },
];
