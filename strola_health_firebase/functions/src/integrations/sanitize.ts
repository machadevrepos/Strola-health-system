import type { IntegrationConnection } from "../lib/types";

/** Strips access_token/refresh_token — shared by every callable that's
 * allowed to hand an integrationConnections doc back to a client, since
 * that collection is otherwise entirely Functions-only in firestore.rules. */
export function sanitizeConnection(id: string, data: IntegrationConnection) {
  return {
    id,
    user_id: data.user_id,
    provider: data.provider,
    status: data.status,
    scopes: data.scopes,
    external_athlete_id: data.external_athlete_id,
    last_synced_at: data.last_synced_at,
    connected_at: data.connected_at,
    error_message: data.error_message,
  };
}
