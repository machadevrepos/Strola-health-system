"use client";

import * as React from "react";
import { toast } from "sonner";
import { CheckCircle, PencilSimple, CircleNotch } from "@phosphor-icons/react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { updateAppContent } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { formatRelative } from "@/lib/format";
import type { AppContentCategory, AppContentEntry } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const CATEGORY_LABEL: Record<AppContentCategory, string> = {
  welcome_messages: "Welcome messages",
  challenge_descriptions: "Challenge descriptions",
  motivational_quotes: "Motivational quotes",
  notification_text: "Notification text",
  empty_states: "Empty state text",
};

const CATEGORIES = Object.keys(CATEGORY_LABEL) as AppContentCategory[];

export function AppContentView({ entries: initialEntries }: { entries: AppContentEntry[] }) {
  const [entries, setEntries] = React.useState(initialEntries);

  React.useEffect(() => setEntries(initialEntries), [initialEntries]);

  async function save(key: string, value: string) {
    try {
      const updated = await updateAppContent(key, value);
      setEntries((prev) => prev.map((e) => (e.key === key ? updated : e)));
      toast.success("Saved — live immediately, no app update needed");
      logAction("Edited app content", key);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this text"));
      throw err;
    }
  }

  return (
    <Tabs defaultValue={CATEGORIES[0]}>
      <TabsList>
        {CATEGORIES.map((c) => (
          <TabsTrigger key={c} value={c}>
            {CATEGORY_LABEL[c]} ({entries.filter((e) => e.category === c).length})
          </TabsTrigger>
        ))}
      </TabsList>
      {CATEGORIES.map((c) => (
        <TabsContent key={c} value={c} className="mt-4 space-y-2">
          {entries
            .filter((e) => e.category === c)
            .map((entry) => (
              <ContentRow key={entry.key} entry={entry} onSave={save} />
            ))}
        </TabsContent>
      ))}
    </Tabs>
  );
}

function ContentRow({ entry, onSave }: { entry: AppContentEntry; onSave: (key: string, value: string) => Promise<void> }) {
  const [editing, setEditing] = React.useState(false);
  const [value, setValue] = React.useState(entry.value);
  const [saving, setSaving] = React.useState(false);

  React.useEffect(() => {
    if (!editing) setValue(entry.value);
  }, [entry.value, editing]);

  async function handleSave() {
    setSaving(true);
    try {
      await onSave(entry.key, value);
      setEditing(false);
    } catch {
      // toast already shown by onSave
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card className="border-border shadow-none">
      <CardContent>
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="text-sm font-medium text-foreground">{entry.label}</p>
            <p className="font-mono text-xs text-muted-foreground">{entry.key}</p>
          </div>
          {!editing && (
            <Button variant="outline" size="sm" onClick={() => setEditing(true)}>
              <PencilSimple size={14} /> Edit
            </Button>
          )}
        </div>

        {editing ? (
          <div className="mt-2 space-y-2">
            <Textarea value={value} onChange={(e) => setValue(e.target.value)} rows={2} autoFocus />
            <div className="flex justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  setValue(entry.value);
                  setEditing(false);
                }}
                disabled={saving}
              >
                Cancel
              </Button>
              <Button size="sm" onClick={handleSave} disabled={value.trim().length === 0 || saving}>
                {saving ? <CircleNotch size={14} className="animate-spin" /> : <CheckCircle size={14} />}
                Save
              </Button>
            </div>
          </div>
        ) : (
          <p className="mt-2 text-sm text-muted-foreground">{entry.value}</p>
        )}

        <p className="mt-2 text-xs text-muted-foreground">Updated {formatRelative(entry.updated_at)}</p>
      </CardContent>
    </Card>
  );
}
