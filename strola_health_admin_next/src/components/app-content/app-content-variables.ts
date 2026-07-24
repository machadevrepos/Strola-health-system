export interface AppContentVariable {
  name: string;
  description: string;
  sample: string;
}

// One global catalog rather than per-category allowlists — keeps the editor
// simple, and nothing stops e.g. {FirstName} from being useful in an error
// message as much as a greeting.
export const APP_CONTENT_VARIABLES: AppContentVariable[] = [
  { name: "FirstName", description: "User's first name", sample: "Alex" },
  { name: "StepsToday", description: "Steps taken so far today", sample: "8,760" },
  { name: "StepsRemaining", description: "Steps left to hit today's goal", sample: "1,240" },
  { name: "StepGoal", description: "User's daily step goal", sample: "10,000" },
  { name: "StreakDays", description: "Current daily streak length", sample: "5" },
  { name: "ChallengeName", description: "Name of the relevant challenge", sample: "10K Daily Streak" },
  { name: "DaysLeft", description: "Days remaining in a challenge or trial", sample: "3" },
  { name: "DeviceBattery", description: "Paired tracker's battery percentage", sample: "18%" },
  { name: "AppVersion", description: "Latest available app version", sample: "2.4.0" },
];

const PLACEHOLDER_RE = /\{(\w+)\}/g;

/** Substitutes every {VariableName} with its catalog sample value, for a realistic preview. An unrecognized placeholder is left as-is so a typo stays visible rather than silently vanishing. */
export function renderAppContentPreview(text: string): string {
  return text.replace(PLACEHOLDER_RE, (match, name: string) => {
    const variable = APP_CONTENT_VARIABLES.find((v) => v.name === name);
    return variable ? variable.sample : match;
  });
}

/** Every {Word} placeholder in `text` that isn't a recognized variable — surfaced as a validation warning in the editor. */
export function unknownVariablesIn(text: string): string[] {
  const found = new Set<string>();
  for (const m of text.matchAll(PLACEHOLDER_RE)) {
    if (!APP_CONTENT_VARIABLES.some((v) => v.name === m[1])) found.add(m[1]);
  }
  return Array.from(found);
}

/** Inserts {name} into `text` at `cursor`, returning the new text and the cursor position just after the inserted placeholder (so the caller can restore focus there). */
export function insertVariableAt(text: string, cursor: number, name: string): { text: string; cursor: number } {
  const token = `{${name}}`;
  const next = text.slice(0, cursor) + token + text.slice(cursor);
  return { text: next, cursor: cursor + token.length };
}
