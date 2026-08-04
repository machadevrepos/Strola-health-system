import { onRequest } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { db } from "../lib/admin";
import { Collections } from "../lib/constants";
import { OAUTH_PROVIDERS, isOAuthProvider } from "./providerConfig";
import { functionUrl, APP_OAUTH_REDIRECT_SCHEME } from "../lib/config";
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

interface TokenResponse {
  access_token: string;
  refresh_token?: string;
  expires_in?: number;
  athlete?: { id?: number | string };
}

/**
 * Function #55. Plain HTTPS (not callable) since this is a browser redirect
 * target that can't carry a Firebase ID token — identity instead comes from
 * the single-use `state` value startOAuthConnect minted. Completes the
 * exchange and bounces back into the app via its custom URL scheme, exactly
 * as backend_api.dart's OAuth flow already expects.
 */
export const oauthCallback = onRequest(
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
  async (req, res) => {
    const { code, state, error } = req.query as { code?: string; state?: string; error?: string };

    if (error || !code || !state) {
      res.redirect(`${APP_OAUTH_REDIRECT_SCHEME}integrations?status=error`);
      return;
    }

    const stateRef = db.collection("oauthStates").doc(state);
    const stateSnap = await stateRef.get();
    if (!stateSnap.exists) {
      res.redirect(`${APP_OAUTH_REDIRECT_SCHEME}integrations?status=error`);
      return;
    }
    const { uid, provider, expires_at_millis: expiresAt } = stateSnap.data() as {
      uid: string;
      provider: string;
      expires_at_millis: number;
    };
    await stateRef.delete();

    if (Date.now() > expiresAt || !isOAuthProvider(provider)) {
      res.redirect(`${APP_OAUTH_REDIRECT_SCHEME}integrations?status=error`);
      return;
    }

    const config = OAUTH_PROVIDERS[provider];
    try {
      const tokenRes = await fetch(config.tokenUrl, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          client_id: config.clientId.value(),
          client_secret: config.clientSecret.value(),
          code,
          grant_type: "authorization_code",
          redirect_uri: functionUrl("oauthCallback"),
        }),
      });

      if (!tokenRes.ok) {
        logger.error(`${provider} token exchange failed`, { status: tokenRes.status });
        res.redirect(`${APP_OAUTH_REDIRECT_SCHEME}integrations?status=error`);
        return;
      }

      const tokens = (await tokenRes.json()) as TokenResponse;
      const connectionRef = db.collection(Collections.integrationConnections).doc(`${uid}_${provider}`);
      await connectionRef.set(
        {
          id: `${uid}_${provider}`,
          user_id: uid,
          provider,
          status: "connected",
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token ?? null,
          expires_at: tokens.expires_in
            ? Timestamp.fromMillis(Date.now() + tokens.expires_in * 1000)
            : null,
          scopes: config.scope ? config.scope.split(" ") : [],
          external_athlete_id: tokens.athlete?.id != null ? String(tokens.athlete.id) : null,
          last_synced_at: null,
          connected_at: FieldValue.serverTimestamp(),
          error_message: null,
        },
        { merge: true }
      );

      res.redirect(`${APP_OAUTH_REDIRECT_SCHEME}integrations?status=success&provider=${provider}`);
    } catch (err) {
      logger.error(`${provider} oauthCallback error`, err as Error);
      res.redirect(`${APP_OAUTH_REDIRECT_SCHEME}integrations?status=error`);
    }
  }
);
