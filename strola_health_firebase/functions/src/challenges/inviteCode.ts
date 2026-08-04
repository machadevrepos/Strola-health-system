import { db } from "../lib/admin";
import { Collections } from "../lib/constants";

const ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // no 0/O/1/I ambiguity

function randomCode(): string {
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  }
  return `INV-${code}`;
}

/** Server-generated, unlike the mock UI's client-side code — guarantees
 * uniqueness instead of hoping for the best. */
export async function generateUniqueInviteCode(): Promise<string> {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = randomCode();
    const existing = await db
      .collection(Collections.challenges)
      .where("invite_code", "==", code)
      .limit(1)
      .get();
    if (existing.empty) return code;
  }
  throw new Error("Could not generate a unique invite code after 10 attempts.");
}
