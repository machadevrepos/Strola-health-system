"use client";

import * as React from "react";
import { toast } from "sonner";
import {
  ArrowCounterClockwise,
  CaretLeft,
  CaretRight,
  CheckCircle,
  CircleNotch,
  Copy,
  Eye,
  FilePdf,
  LinkSimple,
  Plus,
  Trash,
  WarningCircle,
} from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { StatCard } from "@/components/shell/stat-card";
import { LegalMarkdown } from "@/components/legal/legal-markdown";
import { LegalRichTextEditor } from "@/components/legal/legal-rich-text-editor";
import { LegalDocumentPreview } from "@/components/legal/legal-document-preview";
import { LegalAcceptancePreview } from "@/components/legal/legal-acceptance-preview";
import { exportLegalDocumentPdf } from "@/components/legal/legal-pdf-export";
import { LegalConfirmDialog, type LegalConfirmTarget } from "@/components/legal/legal-confirm-dialog";
import { currentLegalVersion, draftLegalVersion, legalAcceptanceStats, legalVersionHistory } from "@/lib/data/queries";
import { deleteLegalDraft, publishLegalVersion, restoreLegalVersion, saveLegalDraft } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { logAction } from "@/lib/audit-log-store";
import { formatDate, formatPercent } from "@/lib/format";
import type { LegalAcceptance, LegalDocumentType, LegalDocumentVersion } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const DOC_LABEL: Record<LegalDocumentType, string> = {
  privacy_policy: "Privacy Policy",
  terms: "Terms of Service",
  community_guidelines: "Community Guidelines",
};
const DOC_TYPES = Object.keys(DOC_LABEL) as LegalDocumentType[];

// Publicly hosted by functions/src/legal/legalPage.ts via a Firebase Hosting
// rewrite (firebase.json) — single project, no dev/staging split, so this is
// hardcoded same as this app's own Firebase config. This is what goes in
// App Store Connect's Privacy Policy URL field and the app's own Settings
// screen links, once a version is actually published.
const LEGAL_PUBLIC_BASE_URL = "https://strolla-health-4c93b.web.app/legal";
const DOC_SLUG: Record<LegalDocumentType, string> = {
  privacy_policy: "privacy-policy",
  terms: "terms",
  community_guidelines: "community-guidelines",
};

const STATUS_BADGE: Record<LegalDocumentVersion["status"], React.ReactNode> = {
  published: <Badge className="bg-success/15 text-success">Published</Badge>,
  draft: <Badge className="bg-brand-accent/20 text-brand-accent-strong">Draft</Badge>,
  archived: <Badge variant="secondary">Archived</Badge>,
};

export function LegalView({ versions: initialVersions, acceptances }: { versions: LegalDocumentVersion[]; acceptances: LegalAcceptance[] }) {
  const { user } = useAuth();
  const [versions, setVersions] = React.useState(initialVersions);
  const [selected, setSelected] = React.useState<LegalDocumentType | null>(null);

  React.useEffect(() => setVersions(initialVersions), [initialVersions]);

  function upsertVersion(v: LegalDocumentVersion) {
    setVersions((prev) => {
      const idx = prev.findIndex((p) => p.id === v.id);
      if (idx === -1) return [v, ...prev];
      const next = [...prev];
      next[idx] = v;
      return next;
    });
  }

  if (selected) {
    return (
      <LegalDocumentDetail
        docType={selected}
        versions={versions}
        acceptances={acceptances}
        onBack={() => setSelected(null)}
        onVersionChange={upsertVersion}
        onVersionRemoved={(id) => setVersions((prev) => prev.filter((v) => v.id !== id))}
        adminId={user?.uid ?? null}
      />
    );
  }

  return (
    <Card className="border-border shadow-none">
      <CardHeader>
        <CardTitle>Documents</CardTitle>
        <CardDescription>Click a document to manage its draft, version history, and acceptance.</CardDescription>
      </CardHeader>
      <CardContent className="p-0">
        <Table>
          <TableHeader>
            <TableRow className="hover:bg-transparent">
              <TableHead>Document</TableHead>
              <TableHead>Version</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Effective</TableHead>
              <TableHead className="w-10" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {DOC_TYPES.map((type) => {
              const current = currentLegalVersion(type, versions);
              const draft = draftLegalVersion(type, versions);
              return (
                <TableRow key={type} className="cursor-pointer" onClick={() => setSelected(type)}>
                  <TableCell className="font-medium text-foreground">{DOC_LABEL[type]}</TableCell>
                  <TableCell className="font-mono">{current ? `v${current.version}` : "—"}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-1.5">
                      {current ? STATUS_BADGE.published : <Badge variant="secondary">No published version</Badge>}
                      {draft && (
                        <Badge variant="outline" className="text-[11px]">
                          Draft in progress
                        </Badge>
                      )}
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{current ? formatDate(current.effective_date) : "—"}</TableCell>
                  <TableCell>
                    <CaretRight size={14} className="text-muted-foreground" />
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

function LegalDocumentDetail({
  docType,
  versions,
  acceptances,
  onBack,
  onVersionChange,
  onVersionRemoved,
  adminId,
}: {
  docType: LegalDocumentType;
  versions: LegalDocumentVersion[];
  acceptances: LegalAcceptance[];
  onBack: () => void;
  onVersionChange: (v: LegalDocumentVersion) => void;
  onVersionRemoved: (id: string) => void;
  adminId: string | null;
}) {
  const current = currentLegalVersion(docType, versions);
  const draft = draftLegalVersion(docType, versions);
  const history = legalVersionHistory(docType, versions);

  const [draftContent, setDraftContent] = React.useState(draft?.content ?? current?.content ?? "");
  const [draftEffectiveDate, setDraftEffectiveDate] = React.useState(
    (draft ?? current)?.effective_date.slice(0, 10) ?? new Date().toISOString().slice(0, 10)
  );
  const [draftRequiresReaccept, setDraftRequiresReaccept] = React.useState(draft?.requires_reaccept ?? false);
  const [savingDraft, setSavingDraft] = React.useState(false);
  const [publishing, setPublishing] = React.useState(false);
  const [changelogOpen, setChangelogOpen] = React.useState(false);
  const [changelog, setChangelog] = React.useState("");
  const [previewTarget, setPreviewTarget] = React.useState<LegalDocumentVersion | null>(null);
  const [acceptancePreviewOpen, setAcceptancePreviewOpen] = React.useState(false);
  const [confirmTarget, setConfirmTarget] = React.useState<LegalConfirmTarget | null>(null);

  React.useEffect(() => {
    setDraftContent(draft?.content ?? current?.content ?? "");
    setDraftEffectiveDate((draft ?? current)?.effective_date.slice(0, 10) ?? new Date().toISOString().slice(0, 10));
    setDraftRequiresReaccept(draft?.requires_reaccept ?? false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [draft?.id, current?.id]);

  async function startDraft() {
    if (!current) return;
    setSavingDraft(true);
    try {
      const newDraft = await saveLegalDraft({
        doc_type: docType,
        content: current.content,
        effective_date: new Date().toISOString().slice(0, 10),
        requires_reaccept: false,
        created_by: adminId,
      });
      onVersionChange(newDraft);
      toast.success("Draft started");
      logAction("Started legal document draft", DOC_LABEL[docType]);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't start a draft"));
    } finally {
      setSavingDraft(false);
    }
  }

  async function handleSaveDraft() {
    if (!draft) return;
    setSavingDraft(true);
    try {
      const saved = await saveLegalDraft({
        id: draft.id,
        doc_type: docType,
        content: draftContent,
        effective_date: draftEffectiveDate,
        requires_reaccept: draftRequiresReaccept,
        created_by: adminId,
      });
      onVersionChange(saved);
      toast.success("Draft saved");
      logAction("Saved legal document draft", DOC_LABEL[docType]);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this draft"));
    } finally {
      setSavingDraft(false);
    }
  }

  async function handlePublish() {
    if (!draft) return;
    setPublishing(true);
    try {
      const saved = await saveLegalDraft({
        id: draft.id,
        doc_type: docType,
        content: draftContent,
        effective_date: draftEffectiveDate,
        requires_reaccept: draftRequiresReaccept,
        created_by: adminId,
      });
      const published = await publishLegalVersion(saved.id, changelog);
      onVersionChange(published);
      toast.success(`${DOC_LABEL[docType]} v${published.version} published`);
      logAction("Published legal document", `${DOC_LABEL[docType]} v${published.version}`);
      setChangelogOpen(false);
      setChangelog("");
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't publish this version"));
    } finally {
      setPublishing(false);
    }
  }

  function confirmDiscardDraft() {
    if (!draft) return;
    setConfirmTarget({
      title: "Discard this draft?",
      description: "Your edits will be lost. The currently published version is not affected.",
      confirmLabel: "Discard draft",
      destructive: true,
      onConfirm: async () => {
        try {
          await deleteLegalDraft(draft.id);
          onVersionRemoved(draft.id);
          toast.success("Draft discarded");
          logAction("Discarded legal document draft", DOC_LABEL[docType]);
        } catch (err) {
          toast.error(apiErrorMessage(err, "Couldn't discard this draft"));
        } finally {
          setConfirmTarget(null);
        }
      },
    });
  }

  function confirmRestore(version: LegalDocumentVersion) {
    setConfirmTarget({
      title: `Restore v${version.version}?`,
      description: "Creates a new draft seeded from this version's content — it won't go live until you publish it.",
      confirmLabel: "Restore as draft",
      onConfirm: async () => {
        try {
          const newDraft = await restoreLegalVersion(version.id);
          onVersionChange(newDraft);
          toast.success(`v${version.version} restored as a new draft`);
          logAction("Restored legal document version", `${DOC_LABEL[docType]} v${version.version} → new draft`);
        } catch (err) {
          toast.error(apiErrorMessage(err, "Couldn't restore this version"));
        } finally {
          setConfirmTarget(null);
        }
      },
    });
  }

  const stats = current ? legalAcceptanceStats(docType, current.version, acceptances) : null;
  const draftDirty = draft
    ? draftContent !== draft.content || draftEffectiveDate !== draft.effective_date.slice(0, 10) || draftRequiresReaccept !== draft.requires_reaccept
    : false;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Button variant="ghost" size="sm" onClick={onBack}>
          <CaretLeft size={14} /> All documents
        </Button>
        {current && (
          <Button
            variant="outline"
            size="sm"
            onClick={() =>
              exportLegalDocumentPdf({
                title: DOC_LABEL[docType],
                version: current.version,
                effectiveDate: current.effective_date,
                content: current.content,
              })
            }
          >
            <FilePdf size={14} /> Export PDF
          </Button>
        )}
      </div>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>{DOC_LABEL[docType]}</CardTitle>
          <CardDescription>
            {current ? (
              <>
                Currently published: v{current.version} · Effective {formatDate(current.effective_date)}
              </>
            ) : (
              "No published version yet."
            )}
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap items-center gap-2 border-t border-border pt-3">
          <LinkSimple size={14} className="shrink-0 text-muted-foreground" />
          {current ? (
            <a
              href={`${LEGAL_PUBLIC_BASE_URL}/${DOC_SLUG[docType]}`}
              target="_blank"
              rel="noreferrer"
              className="truncate font-mono text-xs text-primary underline-offset-2 hover:underline"
            >
              {LEGAL_PUBLIC_BASE_URL}/{DOC_SLUG[docType]}
            </a>
          ) : (
            <span className="truncate font-mono text-xs text-muted-foreground">
              {LEGAL_PUBLIC_BASE_URL}/{DOC_SLUG[docType]} <span className="italic">(live once published)</span>
            </span>
          )}
          <Button
            variant="ghost"
            size="icon-sm"
            aria-label="Copy link"
            className="shrink-0"
            onClick={() => {
              navigator.clipboard.writeText(`${LEGAL_PUBLIC_BASE_URL}/${DOC_SLUG[docType]}`);
              toast.success("Link copied");
            }}
          >
            <Copy size={14} />
          </Button>
        </CardContent>
      </Card>

      <Tabs defaultValue="draft">
        <TabsList>
          <TabsTrigger value="draft">Draft</TabsTrigger>
          <TabsTrigger value="history">Version History ({history.length})</TabsTrigger>
          <TabsTrigger value="acceptance">Acceptance</TabsTrigger>
        </TabsList>

        <TabsContent value="draft" className="mt-4">
          {!draft ? (
            <Card className="border-border shadow-none">
              <CardContent className="space-y-3">
                <p className="text-sm text-muted-foreground">No draft in progress.</p>
                <Button size="sm" onClick={startDraft} disabled={!current || savingDraft}>
                  {savingDraft ? <CircleNotch size={14} className="animate-spin" /> : <Plus size={14} />}
                  Start a new draft
                </Button>
              </CardContent>
            </Card>
          ) : (
            <Card className="border-border shadow-none">
              <CardContent className="space-y-3">
                <div className="grid gap-3 sm:grid-cols-2">
                  <div className="grid gap-2">
                    <Label htmlFor="legal-effective">Effective date</Label>
                    <Input id="legal-effective" type="date" value={draftEffectiveDate} onChange={(e) => setDraftEffectiveDate(e.target.value)} />
                  </div>
                  <div className="grid gap-2">
                    <Label className="mb-0">Requires re-accept</Label>
                    <div className="flex items-center gap-2">
                      <Switch checked={draftRequiresReaccept} onCheckedChange={(v) => setDraftRequiresReaccept(!!v)} />
                      <span className="text-xs text-muted-foreground">
                        {draftRequiresReaccept ? "Blocks app usage until every user accepts again" : "Quiet republish — no user action needed"}
                      </span>
                    </div>
                  </div>
                </div>

                <LegalRichTextEditor value={draftContent} onChange={setDraftContent} />

                <div className="flex flex-wrap items-center justify-between gap-2">
                  <div className="flex flex-wrap gap-2">
                    <Button variant="outline" size="sm" onClick={() => setPreviewTarget({ ...draft, content: draftContent })}>
                      <Eye size={14} /> Preview
                    </Button>
                    <Button variant="outline" size="sm" disabled={!draftRequiresReaccept} onClick={() => setAcceptancePreviewOpen(true)}>
                      <WarningCircle size={14} /> Preview acceptance prompt
                    </Button>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Button variant="outline" size="sm" className="text-destructive hover:text-destructive" onClick={confirmDiscardDraft}>
                      <Trash size={14} /> Discard
                    </Button>
                    <Button variant="outline" size="sm" onClick={handleSaveDraft} disabled={!draftDirty || savingDraft}>
                      {savingDraft ? <CircleNotch size={14} className="animate-spin" /> : <CheckCircle size={14} />}
                      Save draft
                    </Button>
                    <Button size="sm" onClick={() => setChangelogOpen(true)} disabled={draftContent.trim().length === 0}>
                      Publish
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        <TabsContent value="history" className="mt-4">
          <Card className="border-border shadow-none">
            <CardContent className="space-y-2 pt-5">
              {history.map((v) => (
                <div key={v.id} className="rounded-md border border-border p-3">
                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge variant="outline" className="font-mono">
                        v{v.version}
                      </Badge>
                      {STATUS_BADGE[v.status]}
                      {v.requires_reaccept && (
                        <Badge className="gap-1 bg-destructive/12 text-destructive">
                          <WarningCircle size={11} /> Required re-accept
                        </Badge>
                      )}
                    </div>
                    <span className="text-xs text-muted-foreground">Effective {formatDate(v.effective_date)}</span>
                  </div>
                  {v.changelog && (
                    <div className="mt-2 border-t border-border pt-2">
                      <p className="mb-1 text-xs font-medium text-muted-foreground">What&apos;s changed</p>
                      <LegalMarkdown content={v.changelog} />
                    </div>
                  )}
                  <div className="mt-2 flex justify-end gap-1.5">
                    <Button variant="outline" size="sm" onClick={() => setPreviewTarget(v)}>
                      <Eye size={13} /> View
                    </Button>
                    {v.status === "archived" && (
                      <Button variant="outline" size="sm" onClick={() => confirmRestore(v)}>
                        <ArrowCounterClockwise size={13} /> Restore
                      </Button>
                    )}
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="acceptance" className="mt-4">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>{current ? `${DOC_LABEL[docType]} v${current.version}` : "Acceptance"}</CardTitle>
              <CardDescription>Response to the currently published version.</CardDescription>
            </CardHeader>
            <CardContent>
              {!current ? (
                <p className="text-sm text-muted-foreground">No published version yet.</p>
              ) : !stats ? (
                <p className="text-sm text-muted-foreground">No re-acceptance was required for this version.</p>
              ) : (
                <div className="grid grid-cols-3 gap-3">
                  <StatCard label="Accepted" value={formatPercent(stats.acceptedPct)} hint={`${stats.accepted} of ${stats.total}`} tone="success" />
                  <StatCard label="Pending" value={formatPercent(stats.pendingPct)} hint={`${stats.pending} of ${stats.total}`} />
                  <StatCard
                    label="Declined"
                    value={formatPercent(stats.declinedPct)}
                    hint={`${stats.declined} of ${stats.total}`}
                    tone={stats.declined > 0 ? "danger" : "default"}
                  />
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <Dialog open={!!previewTarget} onOpenChange={(open) => !open && setPreviewTarget(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {DOC_LABEL[docType]} — v{previewTarget?.version}
            </DialogTitle>
            <DialogDescription>What this version looks like in the app.</DialogDescription>
          </DialogHeader>
          {previewTarget && <LegalDocumentPreview title={DOC_LABEL[docType]} content={previewTarget.content} />}
        </DialogContent>
      </Dialog>

      <Dialog open={acceptancePreviewOpen} onOpenChange={setAcceptancePreviewOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Acceptance prompt preview</DialogTitle>
            <DialogDescription>What a user would see when asked to re-accept.</DialogDescription>
          </DialogHeader>
          <LegalAcceptancePreview title={DOC_LABEL[docType]} />
        </DialogContent>
      </Dialog>

      <Dialog open={changelogOpen} onOpenChange={setChangelogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Publish {DOC_LABEL[docType]}?</DialogTitle>
            <DialogDescription>
              {draftRequiresReaccept
                ? "Every user will be blocked from using the app until they accept this new version."
                : "This becomes the live version immediately — no user action required."}
            </DialogDescription>
          </DialogHeader>
          <div className="grid gap-2">
            <Label htmlFor="legal-changelog">What&apos;s changed? (optional, shown in Version History)</Label>
            <Textarea
              id="legal-changelog"
              rows={4}
              value={changelog}
              onChange={(e) => setChangelog(e.target.value)}
              placeholder={"- Added Health Connect integration\n- Clarified data retention"}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setChangelogOpen(false)} disabled={publishing}>
              Cancel
            </Button>
            <Button onClick={handlePublish} disabled={publishing}>
              {publishing && <CircleNotch size={14} className="animate-spin" />}
              Publish
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <LegalConfirmDialog target={confirmTarget} onOpenChange={(open) => !open && setConfirmTarget(null)} />
    </div>
  );
}
