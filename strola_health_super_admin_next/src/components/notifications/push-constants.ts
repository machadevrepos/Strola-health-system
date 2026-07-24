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
