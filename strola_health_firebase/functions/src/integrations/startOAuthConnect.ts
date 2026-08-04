import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { randomUUID } from "crypto";
import { db } from "../lib/admin";
import { requireAuth, invalidArgument, failedPrecondition } from "../lib/auth-helpers";
import { OAUTH_PROVIDERS, isOAuthProvider } from "./providerConfig";
import { functionUrl } from "../lib/config";
import { PLACEHOLDER_SECRET_VALUE } from "../lib/constants";
import {
  STRAVA_CLIENT_ID,
  STRAVA_CLIENT_SECRET,
  GARMIN_CLIENT_ID,
  GARMIN_CLIENT_SECRET,
  OURA_CLIENT_ID,
  OURA_CLIENT_SECRET,
  MYFITNESSPAL_CLIENT_ID,
  MYFITNESSPAL_CLIENT_SECRET,
} from "../lib/secrets";

const STATE_TTL_MS = 10 * 60 * 1000;

/**
 * Function #54. Mirrors backend_api.dart's
 * `GET /integrations/{provider}/connect` -> `{authorization_url}` contract
 * exactly, so the Flutter app's existing FlutterWebAuth2 call site needs no
 * change beyond pointing at this callable instead.
 */
export const startOAuthConnect = onCall(
  {
    secrets: [
      STRAVA_CLIENT_ID,
      STRAVA_CLIENT_SECRET,
      GARMIN_CLIENT_ID,
      GARMIN_CLIENT_SECRET,
      OURA_CLIENT_ID,
      OURA_CLIENT_SECRET,
      MYFITNESSPAL_CLIENT_ID,
      MYFITNESSPAL_CLIENT_SECRET,
    ],
  },
  async (request) => {
    const uid = requireAuth(request);
    const { provider } = (request.data ?? {}) as { provider?: string };
    if (!provider || !isOAuthProvider(provider)) invalidArgument("A valid OAuth provider is required.");

    const config = OAUTH_PROVIDERS[provider];
    const clientId = config.clientId.value();
    if (!clientId || clientId === PLACEHOLDER_SECRET_VALUE || !config.authorizeUrl) {
      failedPrecondition(`${provider} isn't set up yet — no credentials/endpoint configured.`);
    }

    const state = randomUUID();
    await db.collection("oauthStates").doc(state).set({
      uid,
      provider,
      created_at: FieldValue.serverTimestamp(),
      expires_at_millis: Date.now() + STATE_TTL_MS,
    });

    const redirectUri = functionUrl("oauthCallback");
    const url = new URL(config.authorizeUrl);
    url.searchParams.set("client_id", clientId);
    url.searchParams.set("redirect_uri", redirectUri);
    url.searchParams.set("response_type", "code");
    url.searchParams.set("scope", config.scope);
    url.searchParams.set("state", state);

    return { authorization_url: url.toString() };
  }
);
