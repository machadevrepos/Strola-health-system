"use client";

import * as React from "react";
import { toast } from "sonner";
import {
  AndroidLogo,
  AppleLogo,
  CalendarBlank,
  CircleNotch,
  FloppyDisk,
  LinkSimple,
  PaperPlaneTilt,
  PencilSimple,
  Trash,
  TrendUp,
} from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardAction, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  saveDraftPushNotification,
  schedulePushNotification,
  sendPushNotification,
  sendScheduledPushNotificationNow,
  deletePushNotification,
  sendTestPushNotification,
} from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { logAction } from "@/lib/audit-log-store";
import {
  PUSH_LINK_TARGET_LABEL,
  PUSH_SEGMENT_LABEL,
  findUserById,
  pushCTR,
  pushLinkDescription,
  segmentAudienceIds,
  userDisplayName,
} from "@/lib/data/queries";
import { formatDateTime, formatNumber, formatPercent } from "@/lib/format";
import { IOSNotificationPreview, AndroidNotificationPreview } from "@/components/notifications/notification-preview";
import { PUSH_BODY_MAX, PUSH_TEMPLATES, PUSH_TITLE_MAX } from "@/components/notifications/push-constants";
import { DiscardNotificationDialog, type DiscardNotificationTarget } from "@/components/notifications/discard-notification-dialog";
import type {
  AnalyticsEvent,
  Challenge,
  ChallengeParticipant,
  Device,
  PushLinkTarget,
  PushNotification,
  PushSegment,
  UserProfile,
} from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const SEGMENTS = Object.keys(PUSH_SEGMENT_LABEL) as PushSegment[];
const LINK_TARGETS = Object.keys(PUSH_LINK_TARGET_LABEL) as PushLinkTarget[];

function counterClass(len: number, max: number): string {
  if (len > max) return "text-destructive";
  if (len > max * 0.85) return "text-[color-mix(in_oklch,var(--brand-accent-strong)_100%,transparent)]";
  return "text-muted-foreground";
}

// yyyy-mm-dd / HH:mm <-> ISO, treated as UTC wall-clock throughout — this
// mock system has no timezone handling anywhere else (see `daysAgo` in
// mock-data.ts), so scheduling follows the same convention.
function toScheduledIso(date: string, time: string): string {
  return new Date(`${date}T${time}:00Z`).toISOString();
}
function isoToDatePart(iso: string): string {
  return iso.slice(0, 10);
}
function isoToTimePart(iso: string): string {
  return iso.slice(11, 16);
}

export function NotificationsView({
  users,
  events,
  devices,
  participants,
  challenges,
  history: initialHistory,
  onChanged,
}: {
  users: UserProfile[];
  events: AnalyticsEvent[];
  devices: Device[];
  participants: ChallengeParticipant[];
  challenges: Challenge[];
  history: PushNotification[];
  onChanged: () => void;
}) {
  const { user } = useAuth();
  const [history, setHistory] = React.useState(initialHistory);
  React.useEffect(() => setHistory(initialHistory), [initialHistory]);

  const [editingId, setEditingId] = React.useState<string | null>(null);
  const [segment, setSegment] = React.useState<PushSegment>("everyone");
  const [title, setTitle] = React.useState("");
  const [body, setBody] = React.useState("");
  const [linkTarget, setLinkTarget] = React.useState<PushLinkTarget>("none");
  const [linkChallengeId, setLinkChallengeId] = React.useState("");
  const [linkCustomPath, setLinkCustomPath] = React.useState("");
  const [scheduleEnabled, setScheduleEnabled] = React.useState(false);
  const [scheduleDate, setScheduleDate] = React.useState("");
  const [scheduleTime, setScheduleTime] = React.useState("");
  const [testUserId, setTestUserId] = React.useState("");

  const [savingDraft, setSavingDraft] = React.useState(false);
  const [scheduling, setScheduling] = React.useState(false);
  const [sending, setSending] = React.useState(false);
  const [sendingTest, setSendingTest] = React.useState(false);
  const [rowBusyId, setRowBusyId] = React.useState<string | null>(null);
  const [discardTarget, setDiscardTarget] = React.useState<DiscardNotificationTarget | null>(null);
  const [sentSort, setSentSort] = React.useState<"ctr" | "recent">("ctr");

  const audienceCount = segmentAudienceIds(segment, { users, events, participants, devices }).length;
  const testCandidates = React.useMemo(() => users.filter((u) => u.role === "user" && !u.deleted), [users]);

  const titleOverMax = title.length > PUSH_TITLE_MAX;
  const bodyOverMax = body.length > PUSH_BODY_MAX;
  const composeEmpty = title.trim().length === 0 || body.trim().length === 0;
  const composeOverMax = titleOverMax || bodyOverMax;
  const scheduleTimeMissing = scheduleEnabled && (!scheduleDate || !scheduleTime);
  const primaryActionDisabled = composeEmpty || composeOverMax || scheduleTimeMissing || savingDraft || scheduling || sending;
  const draftDisabled = title.trim().length === 0 && body.trim().length === 0;

  const drafts = React.useMemo(() => history.filter((h) => h.status === "draft"), [history]);
  const scheduled = React.useMemo(
    () => [...history.filter((h) => h.status === "scheduled")].sort((a, b) => +new Date(a.scheduled_at!) - +new Date(b.scheduled_at!)),
    [history]
  );
  const sent = React.useMemo(() => {
    const list = history.filter((h) => h.status === "sent");
    if (sentSort === "recent") return [...list].sort((a, b) => +new Date(b.sent_at!) - +new Date(a.sent_at!));
    return [...list].sort((a, b) => (pushCTR(b) ?? -1) - (pushCTR(a) ?? -1));
  }, [history, sentSort]);

  function upsertHistory(record: PushNotification) {
    setHistory((prev) => {
      const idx = prev.findIndex((p) => p.id === record.id);
      if (idx === -1) return [record, ...prev];
      const next = [...prev];
      next[idx] = record;
      return next;
    });
  }

  function applyTemplate(t: (typeof PUSH_TEMPLATES)[number]) {
    setTitle(t.title);
    setBody(t.body);
  }

  function resetCompose() {
    setEditingId(null);
    setSegment("everyone");
    setTitle("");
    setBody("");
    setLinkTarget("none");
    setLinkChallengeId("");
    setLinkCustomPath("");
    setScheduleEnabled(false);
    setScheduleDate("");
    setScheduleTime("");
  }

  function loadIntoCompose(record: PushNotification) {
    setEditingId(record.id);
    setSegment(record.segment);
    setTitle(record.title);
    setBody(record.body);
    setLinkTarget(record.link_target);
    setLinkChallengeId(record.link_challenge_id ?? "");
    setLinkCustomPath(record.link_custom_path ?? "");
    if (record.scheduled_at) {
      setScheduleEnabled(true);
      setScheduleDate(isoToDatePart(record.scheduled_at));
      setScheduleTime(isoToTimePart(record.scheduled_at));
    } else {
      setScheduleEnabled(false);
      setScheduleDate("");
      setScheduleTime("");
    }
  }

  function composePayload() {
    return {
      id: editingId ?? undefined,
      segment,
      title: title.trim(),
      body: body.trim(),
      linkTarget,
      linkChallengeId: linkTarget === "challenge" ? linkChallengeId || null : null,
      linkCustomPath: linkTarget === "custom" ? linkCustomPath.trim() || null : null,
      sentBy: user?.uid ?? null,
    };
  }

  async function handleSaveDraft() {
    setSavingDraft(true);
    try {
      const draft = await saveDraftPushNotification(composePayload());
      upsertHistory(draft);
      setEditingId(draft.id);
      toast.success("Draft saved");
      logAction("Saved push notification draft", `"${title.trim()}"`);
      onChanged();
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save this draft"));
    } finally {
      setSavingDraft(false);
    }
  }

  async function handlePrimaryAction() {
    if (scheduleEnabled) {
      setScheduling(true);
      try {
        const scheduledAt = toScheduledIso(scheduleDate, scheduleTime);
        if (new Date(scheduledAt).getTime() <= Date.now()) {
          toast.error("Pick a time in the future");
          return;
        }
        const record = await schedulePushNotification({ ...composePayload(), scheduledAt });
        upsertHistory(record);
        toast.success(`Scheduled for ${formatDateTime(scheduledAt)}`);
        logAction("Scheduled push notification", `${PUSH_SEGMENT_LABEL[segment]} — "${title.trim()}" for ${formatDateTime(scheduledAt)}`);
        resetCompose();
        onChanged();
      } catch (err) {
        toast.error(apiErrorMessage(err, "Couldn't schedule this notification"));
      } finally {
        setScheduling(false);
      }
      return;
    }

    setSending(true);
    try {
      const sentRecord = await sendPushNotification(composePayload());
      upsertHistory(sentRecord);
      toast.success(`Sent to ${formatNumber(sentRecord.recipient_count)} recipient${sentRecord.recipient_count === 1 ? "" : "s"}`);
      logAction("Sent push notification", `${PUSH_SEGMENT_LABEL[segment]} — "${title.trim()}"`);
      resetCompose();
      onChanged();
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this notification"));
    } finally {
      setSending(false);
    }
  }

  async function handleSendNow(record: PushNotification) {
    setRowBusyId(record.id);
    try {
      const sentRecord = record.status === "scheduled"
        ? await sendScheduledPushNotificationNow(record.id)
        : await sendPushNotification({
            id: record.id,
            segment: record.segment,
            title: record.title,
            body: record.body,
            linkTarget: record.link_target,
            linkChallengeId: record.link_challenge_id,
            linkCustomPath: record.link_custom_path,
            sentBy: user?.uid ?? null,
          });
      upsertHistory(sentRecord);
      toast.success(`Sent to ${formatNumber(sentRecord.recipient_count)} recipient${sentRecord.recipient_count === 1 ? "" : "s"}`);
      logAction("Sent push notification", `${PUSH_SEGMENT_LABEL[sentRecord.segment]} — "${sentRecord.title}"`);
      if (editingId === record.id) resetCompose();
      onChanged();
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this notification"));
    } finally {
      setRowBusyId(null);
    }
  }

  async function handleDiscardConfirm() {
    if (!discardTarget) return;
    try {
      await deletePushNotification(discardTarget.id);
      setHistory((prev) => prev.filter((p) => p.id !== discardTarget.id));
      toast.success(discardTarget.mode === "scheduled" ? "Send cancelled" : "Draft deleted");
      logAction(discardTarget.mode === "scheduled" ? "Cancelled scheduled push notification" : "Deleted push notification draft", `"${discardTarget.title}"`);
      if (editingId === discardTarget.id) resetCompose();
      setDiscardTarget(null);
      onChanged();
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't remove this notification"));
    }
  }

  async function handleSendTest() {
    if (!testUserId) return;
    setSendingTest(true);
    try {
      await sendTestPushNotification({ userId: testUserId, title: title.trim(), body: body.trim() });
      toast.success(`Test sent to ${userDisplayName(findUserById(users, testUserId))}'s device`);
      logAction("Sent test push notification", `to ${userDisplayName(findUserById(users, testUserId))} — "${title.trim()}"`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send the test notification"));
    } finally {
      setSendingTest(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="border-border shadow-none lg:col-span-2">
          <CardHeader>
            <CardTitle>{editingId ? "Editing" : "Compose"}</CardTitle>
            <CardDescription>
              No push provider is wired in yet — sending here records history and simulates the audience, delivery, and
              open stats it would have produced.
              {editingId && (
                <>
                  {" "}
                  <button type="button" className="font-medium text-primary underline-offset-2 hover:underline" onClick={resetCompose}>
                    Start a new notification instead
                  </button>
                </>
              )}
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex flex-wrap gap-1.5">
              {PUSH_TEMPLATES.map((t) => (
                <Button key={t.label} type="button" variant="outline" size="sm" onClick={() => applyTemplate(t)}>
                  {t.label}
                </Button>
              ))}
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="grid gap-2">
                <Label htmlFor="push-segment">Send to</Label>
                <Select value={segment} onValueChange={(v) => v && setSegment(v as PushSegment)}>
                  <SelectTrigger id="push-segment"><SelectValue>{PUSH_SEGMENT_LABEL[segment]}</SelectValue></SelectTrigger>
                  <SelectContent>
                    {SEGMENTS.map((s) => (
                      <SelectItem key={s} value={s}>
                        {PUSH_SEGMENT_LABEL[s]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  ~{formatNumber(audienceCount)} recipient{audienceCount === 1 ? "" : "s"} right now.
                </p>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="push-link">Link destination</Label>
                <Select value={linkTarget} onValueChange={(v) => v && setLinkTarget(v as PushLinkTarget)}>
                  <SelectTrigger id="push-link"><SelectValue>{PUSH_LINK_TARGET_LABEL[linkTarget]}</SelectValue></SelectTrigger>
                  <SelectContent>
                    {LINK_TARGETS.map((t) => (
                      <SelectItem key={t} value={t}>
                        {PUSH_LINK_TARGET_LABEL[t]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {linkTarget === "challenge" && (
                  <Select value={linkChallengeId} onValueChange={(v) => v && setLinkChallengeId(v)}>
                    <SelectTrigger>
                      <SelectValue placeholder="Choose a challenge">
                        {challenges.find((c) => c.id === linkChallengeId)?.title ?? "Choose a challenge"}
                      </SelectValue>
                    </SelectTrigger>
                    <SelectContent>
                      {challenges.map((c) => (
                        <SelectItem key={c.id} value={c.id}>
                          {c.title}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                )}
                {linkTarget === "custom" && (
                  <Input value={linkCustomPath} onChange={(e) => setLinkCustomPath(e.target.value)} placeholder="/settings/units" />
                )}
              </div>
            </div>

            <div className="grid gap-1.5">
              <div className="flex items-center justify-between">
                <Label htmlFor="push-title">Title</Label>
                <span className={`text-xs tabular-nums ${counterClass(title.length, PUSH_TITLE_MAX)}`}>
                  {title.length}/{PUSH_TITLE_MAX}
                </span>
              </div>
              <Input id="push-title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="🎉 July Challenge is Live!" />
            </div>
            <div className="grid gap-1.5">
              <div className="flex items-center justify-between">
                <Label htmlFor="push-body">Body</Label>
                <span className={`text-xs tabular-nums ${counterClass(body.length, PUSH_BODY_MAX)}`}>
                  {body.length}/{PUSH_BODY_MAX}
                </span>
              </div>
              <Textarea id="push-body" rows={3} value={body} onChange={(e) => setBody(e.target.value)} placeholder="Join now and compete for the top spot." />
              {composeOverMax && (
                <p className="text-xs text-destructive">Over the limit will truncate on most devices — trim it before sending.</p>
              )}
            </div>

            <div className="grid gap-2 rounded-md border border-border bg-secondary/40 p-3">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <Label className="mb-0">When</Label>
                <div className="flex gap-1 rounded-md border border-border bg-background p-0.5">
                  <Button type="button" size="sm" variant={scheduleEnabled ? "ghost" : "secondary"} className="h-7" onClick={() => setScheduleEnabled(false)}>
                    Send now
                  </Button>
                  <Button type="button" size="sm" variant={scheduleEnabled ? "secondary" : "ghost"} className="h-7" onClick={() => setScheduleEnabled(true)}>
                    <CalendarBlank size={14} /> Schedule
                  </Button>
                </div>
              </div>
              {scheduleEnabled && (
                <div className="grid grid-cols-2 gap-2">
                  <Input type="date" value={scheduleDate} onChange={(e) => setScheduleDate(e.target.value)} />
                  <Input type="time" value={scheduleTime} onChange={(e) => setScheduleTime(e.target.value)} />
                </div>
              )}
            </div>

            <div className="flex flex-wrap items-center justify-end gap-2">
              <Button type="button" variant="outline" onClick={handleSaveDraft} disabled={draftDisabled || savingDraft}>
                {savingDraft ? <CircleNotch size={14} className="animate-spin" /> : <FloppyDisk size={14} />}
                Save draft
              </Button>
              <Button onClick={handlePrimaryAction} disabled={primaryActionDisabled}>
                {sending || scheduling ? (
                  <CircleNotch size={14} className="animate-spin" />
                ) : scheduleEnabled ? (
                  <CalendarBlank size={14} />
                ) : (
                  <PaperPlaneTilt size={14} />
                )}
                {scheduleEnabled ? "Schedule send" : `Send to ${formatNumber(audienceCount)}`}
              </Button>
            </div>

            <div className="flex flex-wrap items-center gap-2 border-t border-border pt-3">
              <Label className="mb-0 shrink-0 text-xs text-muted-foreground">Send a test to</Label>
              <Select value={testUserId} onValueChange={(v) => v && setTestUserId(v)}>
                <SelectTrigger size="sm" className="w-56">
                  <SelectValue placeholder="Choose a user">
                    {testUserId ? userDisplayName(findUserById(users, testUserId)) : "Choose a user"}
                  </SelectValue>
                </SelectTrigger>
                <SelectContent>
                  {testCandidates.map((u) => (
                    <SelectItem key={u.id} value={u.id}>
                      {userDisplayName(u)} — {u.email ?? `@${u.username}`}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button type="button" size="sm" variant="outline" onClick={handleSendTest} disabled={!testUserId || composeEmpty || composeOverMax || sendingTest}>
                {sendingTest && <CircleNotch size={14} className="animate-spin" />}
                Send test
              </Button>
            </div>
          </CardContent>
        </Card>

        <Card className="border-border shadow-none">
          <CardHeader>
            <CardTitle>Preview</CardTitle>
            <CardDescription>Updates as you type.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <AppleLogo size={14} /> iPhone
              </div>
              <IOSNotificationPreview title={title} body={body} />
            </div>
            <div className="space-y-1.5">
              <div className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <AndroidLogo size={14} /> Android
              </div>
              <AndroidNotificationPreview title={title} body={body} />
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="drafts">
        <TabsList>
          <TabsTrigger value="drafts">Drafts ({drafts.length})</TabsTrigger>
          <TabsTrigger value="scheduled">Scheduled ({scheduled.length})</TabsTrigger>
          <TabsTrigger value="sent">Performance ({sent.length})</TabsTrigger>
        </TabsList>

        <TabsContent value="drafts" className="mt-4">
          <Card className="border-border shadow-none">
            <CardContent className="space-y-2 pt-5">
              {drafts.length === 0 && <p className="text-sm text-muted-foreground">No drafts saved.</p>}
              {drafts.map((d) => (
                <NotificationRow
                  key={d.id}
                  record={d}
                  challenges={challenges}
                  busy={rowBusyId === d.id}
                  onEdit={() => loadIntoCompose(d)}
                  onSendNow={() => handleSendNow(d)}
                  onDelete={() => setDiscardTarget({ id: d.id, title: d.title, mode: "draft" })}
                />
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="scheduled" className="mt-4">
          <Card className="border-border shadow-none">
            <CardContent className="space-y-2 pt-5">
              {scheduled.length === 0 && <p className="text-sm text-muted-foreground">Nothing scheduled.</p>}
              {scheduled.map((s) => (
                <NotificationRow
                  key={s.id}
                  record={s}
                  challenges={challenges}
                  busy={rowBusyId === s.id}
                  onEdit={() => loadIntoCompose(s)}
                  onSendNow={() => handleSendNow(s)}
                  onDelete={() => setDiscardTarget({ id: s.id, title: s.title, mode: "scheduled" })}
                />
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="sent" className="mt-4">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle className="flex items-center gap-1.5"><TrendUp size={16} /> Performance</CardTitle>
              <CardDescription>Which sends actually get opened, at a glance.</CardDescription>
              <CardAction>
                <div className="flex gap-1 rounded-md border border-border bg-secondary/40 p-0.5">
                  <Button type="button" size="sm" variant={sentSort === "ctr" ? "secondary" : "ghost"} className="h-7" onClick={() => setSentSort("ctr")}>
                    Best performing
                  </Button>
                  <Button type="button" size="sm" variant={sentSort === "recent" ? "secondary" : "ghost"} className="h-7" onClick={() => setSentSort("recent")}>
                    Most recent
                  </Button>
                </div>
              </CardAction>
            </CardHeader>
            <CardContent>
              {sent.length === 0 ? (
                <p className="text-sm text-muted-foreground">Nothing sent yet.</p>
              ) : (
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Notification</TableHead>
                        <TableHead>Segment</TableHead>
                        <TableHead>Sent</TableHead>
                        <TableHead className="text-right"># Sent</TableHead>
                        <TableHead className="text-right">Delivered</TableHead>
                        <TableHead className="text-right">Opened</TableHead>
                        <TableHead className="text-right">CTR</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {sent.map((n) => {
                        const linkDesc = pushLinkDescription(n, challenges);
                        const ctr = pushCTR(n);
                        return (
                          <TableRow key={n.id}>
                            <TableCell className="max-w-64">
                              <p className="truncate font-medium text-foreground">{n.title}</p>
                              <p className="truncate text-xs text-muted-foreground">{n.body}</p>
                              {linkDesc && (
                                <span className="mt-0.5 inline-flex items-center gap-1 text-[11px] text-muted-foreground">
                                  <LinkSimple size={11} /> {linkDesc}
                                </span>
                              )}
                            </TableCell>
                            <TableCell>
                              <Badge variant="outline" className="text-[11px]">{PUSH_SEGMENT_LABEL[n.segment]}</Badge>
                            </TableCell>
                            <TableCell className="text-xs text-muted-foreground">{formatDateTime(n.sent_at!)}</TableCell>
                            <TableCell className="text-right font-mono tabular-nums">{formatNumber(n.recipient_count)}</TableCell>
                            <TableCell className="text-right font-mono tabular-nums">{formatNumber(n.delivered_count)}</TableCell>
                            <TableCell className="text-right font-mono tabular-nums">{formatNumber(n.opened_count)}</TableCell>
                            <TableCell className="text-right font-mono font-medium tabular-nums">{formatPercent(ctr)}</TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <DiscardNotificationDialog target={discardTarget} onOpenChange={(open) => !open && setDiscardTarget(null)} onConfirm={handleDiscardConfirm} />
    </div>
  );
}

function NotificationRow({
  record,
  challenges,
  busy,
  onEdit,
  onSendNow,
  onDelete,
}: {
  record: PushNotification;
  challenges: Challenge[];
  busy: boolean;
  onEdit: () => void;
  onSendNow: () => void;
  onDelete: () => void;
}) {
  const linkDesc = pushLinkDescription(record, challenges);
  return (
    <div className="rounded-md border border-border p-2.5">
      <div className="flex items-start justify-between gap-2">
        <div className="flex flex-wrap items-center gap-1.5">
          <Badge variant="outline" className="text-[11px]">{PUSH_SEGMENT_LABEL[record.segment]}</Badge>
          {linkDesc && (
            <span className="inline-flex items-center gap-1 text-[11px] text-muted-foreground">
              <LinkSimple size={11} /> {linkDesc}
            </span>
          )}
        </div>
        {record.scheduled_at && <span className="shrink-0 text-xs text-muted-foreground">{formatDateTime(record.scheduled_at)}</span>}
      </div>
      <p className="mt-1.5 text-sm font-medium text-foreground">{record.title || "(untitled)"}</p>
      <p className="text-sm text-muted-foreground">{record.body}</p>
      <div className="mt-2 flex justify-end gap-1.5">
        <Button type="button" size="sm" variant="outline" onClick={onEdit} disabled={busy}>
          <PencilSimple size={13} /> Edit
        </Button>
        <Button type="button" size="sm" variant="outline" onClick={onSendNow} disabled={busy}>
          {busy ? <CircleNotch size={13} className="animate-spin" /> : <PaperPlaneTilt size={13} />}
          Send now
        </Button>
        <Button type="button" size="sm" variant="outline" className="text-destructive hover:text-destructive" onClick={onDelete} disabled={busy}>
          <Trash size={13} />
        </Button>
      </div>
    </div>
  );
}
