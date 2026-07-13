"use client";

import * as React from "react";
import { toast } from "sonner";
import { CircleNotch, WarningCircle } from "@phosphor-icons/react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { updateLegalDocument } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { logAction } from "@/lib/audit-log-store";
import { formatDateTime } from "@/lib/format";
import type { LegalDocument, LegalDocumentType } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const DOC_LABEL: Record<LegalDocumentType, string> = {
  privacy_policy: "Privacy Policy",
  terms: "Terms",
  community_guidelines: "Community Guidelines",
};

const DOC_TYPES = Object.keys(DOC_LABEL) as LegalDocumentType[];

export function LegalView({ documents: initialDocuments }: { documents: LegalDocument[] }) {
  const [documents, setDocuments] = React.useState(initialDocuments);

  React.useEffect(() => setDocuments(initialDocuments), [initialDocuments]);

  async function save(type: LegalDocumentType, content: string, forceReaccept: boolean) {
    try {
      const updated = await updateLegalDocument(type, content, forceReaccept);
      setDocuments((prev) => prev.map((d) => (d.type === type ? updated : d)));
      toast.success(forceReaccept ? `${DOC_LABEL[type]} updated — users must re-accept` : `${DOC_LABEL[type]} updated`);
      logAction(forceReaccept ? "Updated legal doc (forced re-accept)" : "Updated legal doc", DOC_LABEL[type]);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this document"));
      throw err;
    }
  }

  return (
    <Tabs defaultValue={DOC_TYPES[0]}>
      <TabsList>
        {DOC_TYPES.map((t) => (
          <TabsTrigger key={t} value={t}>
            {DOC_LABEL[t]}
          </TabsTrigger>
        ))}
      </TabsList>
      {DOC_TYPES.map((t) => {
        const doc = documents.find((d) => d.type === t);
        return (
          <TabsContent key={t} value={t} className="mt-4">
            {doc && <LegalDocEditor doc={doc} onSave={(content, force) => save(t, content, force)} />}
          </TabsContent>
        );
      })}
    </Tabs>
  );
}

function LegalDocEditor({
  doc,
  onSave,
}: {
  doc: LegalDocument;
  onSave: (content: string, forceReaccept: boolean) => Promise<void>;
}) {
  const [content, setContent] = React.useState(doc.content);
  const [saving, setSaving] = React.useState(false);
  const [confirmForce, setConfirmForce] = React.useState(false);

  React.useEffect(() => setContent(doc.content), [doc.content]);

  const dirty = content !== doc.content;

  async function handleSave(forceReaccept: boolean) {
    setSaving(true);
    try {
      await onSave(content, forceReaccept);
    } catch {
      // toast already shown
    } finally {
      setSaving(false);
      setConfirmForce(false);
    }
  }

  return (
    <Card className="border-border shadow-none">
      <CardContent className="space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Badge variant="outline">v{doc.version}</Badge>
            {doc.requires_reaccept && (
              <Badge className="gap-1 bg-destructive/12 text-destructive">
                <WarningCircle size={12} /> Requires re-accept
              </Badge>
            )}
          </div>
          <span className="text-xs text-muted-foreground">Updated {formatDateTime(doc.updated_at)}</span>
        </div>

        <Textarea value={content} onChange={(e) => setContent(e.target.value)} rows={10} className="font-mono text-sm" />

        <div className="flex items-center justify-between">
          <p className="text-xs text-muted-foreground">
            &quot;Save&quot; is a routine copy fix, same version. &quot;Save &amp; force re-accept&quot; bumps the
            version and blocks app usage until every user accepts it again — use for material changes only.
          </p>
          <div className="flex shrink-0 gap-2">
            <Button variant="outline" size="sm" disabled={!dirty || saving} onClick={() => handleSave(false)}>
              {saving && <CircleNotch size={14} className="animate-spin" />}
              Save
            </Button>
            <Button variant="destructive" size="sm" disabled={!dirty || saving} onClick={() => setConfirmForce(true)}>
              Save &amp; force re-accept
            </Button>
          </div>
        </div>
      </CardContent>

      <AlertDialog open={confirmForce} onOpenChange={setConfirmForce}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Force everyone to re-accept?</AlertDialogTitle>
            <AlertDialogDescription>
              Every user will be blocked from using the app until they accept this new version. Only do this for a
              material change to what users agreed to — not a wording fix.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={saving}>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={() => handleSave(true)} disabled={saving} className="bg-destructive text-white hover:bg-destructive/90">
              {saving && <CircleNotch size={14} className="animate-spin" />}
              Save &amp; force re-accept
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </Card>
  );
}
