// firebase-admin is initialized once, at import time, in ./lib/admin —
// every function file below imports it transitively, so no separate
// initializeApp() call belongs here (that caused a duplicate-app crash).

export * from "./auth";
export * from "./users";
export * from "./devices";
export * from "./integrations";
export * from "./health";
export * from "./challenges";
export * from "./badges";
export * from "./community";
export * from "./moderation";
export * from "./premium";
export * from "./push";
export * from "./legal";
export * from "./settings";
export * from "./announcements";
export * from "./analytics";
