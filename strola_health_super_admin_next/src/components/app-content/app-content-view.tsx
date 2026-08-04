"use client";

import * as React from "react";
import { toast } from "sonner";
import { CheckCircle, PencilSimple, CircleNotch, Eye, WarningCircle } from "@phosphor-icons/react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { updateAppContent } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { formatRelative } from "@/lib/format";
import { cn } from "@/lib/utils";
import { AppContentPreview, CATEGORY_LOCATION } from "@/components/app-content/app-content-preview";
import { AppContentRichTextEditor } from "@/components/app-content/app-content-rich-text-editor";
import {
  APP_CONTENT_VARIABLES,
  insertVariableAt,
  renderAppContentPreview,
  unknownVariablesIn,
} from "@/components/app-content/app-content-variables";
import { renderInlineMarkdown } from "@/lib/inline-markdown";
import type { AppContentCategory, AppContentEntry } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const CATEGORY_LABEL: Record<AppContentCategory, string> = {
  onboarding: "Onboarding",
  home: "Home",
  challenges: "Challenges",
  community: "Community",
  errors: "Errors",
  buttons: "Buttons",
  settings: "Settings",
  premium: "Premium",
  notifications: "Notifications",
  widget: "Widget text",
  device_pairing: "Device pairing",
  firmware: "Firmware messages",
};

const CATEGORIES = Object.keys(CATEGORY_LABEL) as AppContentCategory[];

export function AppContentView({ entries: initialEntries }: { entries: AppContentEntry[] }) {
  const [entries, setEntries] = React.useState(initialEntries);
  const [activeCategory, setActiveCategory] = React.useState<AppContentCategory>(CATEGORIES[0]);

  React.useEffect(() => setEntries(initialEntries), [initialEntries]);

  async function save(key: string, value: string) {
    try {
      const updated = await updateAppContent(key, value);
      setEntries((prev) => prev.map((e) => (e.key === key ? updated : e)));
      toast.success("Saved to the staging library");
      logAction("Edited app content", key);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this text"));
      throw err;
    }
  }

  const visibleEntries = entries.filter((e) => e.category === activeCategory);

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-[220px_1fr] lg:items-start">
      <Card className="border-border shadow-none lg:sticky lg:top-4">
        <CardContent className="p-2">
          <nav className="space-y-0.5">
            {CATEGORIES.map((c) => (
              <button
                key={c}
                type="button"
                onClick={() => setActiveCategory(c)}
                className={cn(
                  "flex w-full items-center justify-between rounded-md px-2.5 py-2 text-left text-sm transition-colors",
                  activeCategory === c
                    ? "bg-primary/10 font-medium text-primary"
                    : "text-muted-foreground hover:bg-muted hover:text-foreground"
                )}
              >
                <span>{CATEGORY_LABEL[c]}</span>
                <span className="font-mono text-xs tabular-nums text-muted-foreground">
                  {entries.filter((e) => e.category === c).length}
                </span>
              </button>
            ))}
          </nav>
        </CardContent>
      </Card>

      <div className="space-y-2">
        <p className="px-1 text-xs text-muted-foreground">{CATEGORY_LOCATION[activeCategory]}</p>
        {visibleEntries.map((entry) => (
          <ContentRow key={entry.key} entry={entry} onSave={save} />
        ))}
      </div>
    </div>
  );
}

function ContentRow({ entry, onSave }: { entry: AppContentEntry; onSave: (key: string, value: string) => Promise<void> }) {
  const [editing, setEditing] = React.useState(false);
  const [value, setValue] = React.useState(entry.value);
  const [saving, setSaving] = React.useState(false);
  const [previewOpen, setPreviewOpen] = React.useState(false);
  const textareaRef = React.useRef<HTMLTextAreaElement>(null);

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

  function insertVariable(name: string) {
    const el = textareaRef.current;
    const cursor = el?.selectionStart ?? value.length;
    const { text, cursor: nextCursor } = insertVariableAt(value, cursor, name);
    setValue(text);
    requestAnimationFrame(() => {
      el?.focus();
      el?.setSelectionRange(nextCursor, nextCursor);
    });
  }

  const previewText = editing ? value : entry.value;
  const unknownVariables = editing ? unknownVariablesIn(value) : [];

  return (
    <Card className="border-border shadow-none">
      <CardContent>
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="text-sm font-medium text-foreground">{entry.label}</p>
            <p className="font-mono text-xs text-muted-foreground">{entry.key}</p>
          </div>
          <div className="flex shrink-0 gap-1.5">
            <Button variant="outline" size="sm" onClick={() => setPreviewOpen(true)}>
              <Eye size={14} /> Preview
            </Button>
            {!editing && (
              <Button variant="outline" size="sm" onClick={() => setEditing(true)}>
                <PencilSimple size={14} /> Edit
              </Button>
            )}
          </div>
        </div>

        {editing ? (
          <div className="mt-2 space-y-2">
            <AppContentRichTextEditor value={value} onChange={setValue} textareaRef={textareaRef} />

            <div className="flex flex-wrap items-center gap-1.5">
              <span className="text-xs text-muted-foreground">Insert:</span>
              {APP_CONTENT_VARIABLES.map((v) => (
                <button
                  key={v.name}
                  type="button"
                  title={v.description}
                  onClick={() => insertVariable(v.name)}
                  className="rounded-full border border-border bg-secondary/50 px-2 py-0.5 font-mono text-[11px] text-muted-foreground transition-colors hover:bg-secondary hover:text-foreground"
                >
                  {"{" + v.name + "}"}
                </button>
              ))}
            </div>

            {unknownVariables.length > 0 && (
              <p className="flex items-center gap-1 text-xs text-destructive">
                <WarningCircle size={13} /> Unrecognized variable{unknownVariables.length === 1 ? "" : "s"}:{" "}
                {unknownVariables.map((v) => `{${v}}`).join(", ")}
              </p>
            )}

            <p className="text-xs text-muted-foreground">
              <span className="font-medium">Preview:</span>{" "}
              {value.trim() ? renderInlineMarkdown(renderAppContentPreview(value), "row-preview") : "—"}
            </p>

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
          <p className="mt-2 text-sm text-muted-foreground">{renderInlineMarkdown(entry.value, "row-value")}</p>
        )}

        <p className="mt-2 text-xs text-muted-foreground">Updated {formatRelative(entry.updated_at)}</p>
      </CardContent>

      <Dialog open={previewOpen} onOpenChange={setPreviewOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{entry.label}</DialogTitle>
            <DialogDescription>{CATEGORY_LOCATION[entry.category]}</DialogDescription>
          </DialogHeader>
          <AppContentPreview category={entry.category} text={renderAppContentPreview(previewText)} />
        </DialogContent>
      </Dialog>
    </Card>
  );
}
