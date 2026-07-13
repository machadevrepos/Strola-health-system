"use client";

import * as React from "react";
import { toast } from "sonner";
import { PaperPlaneTilt, CircleNotch } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
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
import { sendPushNotification } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { useAuth } from "@/lib/auth-context";
import { logAction } from "@/lib/audit-log-store";
import { PUSH_SEGMENT_LABEL, findUserById, segmentAudienceIds, userDisplayName } from "@/lib/data/queries";
import { formatDateTime, formatNumber } from "@/lib/format";
import type {
  AnalyticsEvent,
  ChallengeParticipant,
  Device,
  PushNotification,
  PushSegment,
  UserProfile,
} from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

const SEGMENTS = Object.keys(PUSH_SEGMENT_LABEL) as PushSegment[];

const TEMPLATES = [
  { label: "New Challenge of the Month", title: "🎉 July Challenge is Live!", body: "Join now and compete for the top spot." },
  { label: "New Feature", title: "🚀 New Feature: Share your steps", body: "Share your daily step count straight to Instagram — try it from your profile." },
  { label: "Holiday Message", title: "🎄 Happy Holidays from Strolla", body: "However you're spending today, we hope it includes a good walk. See you in the new year!" },
  { label: "Maintenance Notice", title: "🔧 Scheduled maintenance", body: "Strolla will be briefly unavailable tonight between 2–3am for scheduled maintenance." },
];

export function NotificationsView({
  users,
  events,
  devices,
  participants,
  history: initialHistory,
  onSent,
}: {
  users: UserProfile[];
  events: AnalyticsEvent[];
  devices: Device[];
  participants: ChallengeParticipant[];
  history: PushNotification[];
  onSent: () => void;
}) {
  const { user } = useAuth();
  const [segment, setSegment] = React.useState<PushSegment>("everyone");
  const [title, setTitle] = React.useState("");
  const [body, setBody] = React.useState("");
  const [sending, setSending] = React.useState(false);
  const [history, setHistory] = React.useState(initialHistory);

  React.useEffect(() => setHistory(initialHistory), [initialHistory]);

  const audienceCount = segmentAudienceIds(segment, { users, events, participants, devices }).length;

  function applyTemplate(t: (typeof TEMPLATES)[number]) {
    setTitle(t.title);
    setBody(t.body);
  }

  async function handleSend() {
    setSending(true);
    try {
      const sent = await sendPushNotification({ segment, title: title.trim(), body: body.trim(), sentBy: user?.uid ?? null });
      setHistory((prev) => [sent, ...prev]);
      toast.success(`Sent to ${formatNumber(sent.recipient_count)} recipient${sent.recipient_count === 1 ? "" : "s"}`);
      logAction("Sent push notification", `${PUSH_SEGMENT_LABEL[segment]} — "${title.trim()}"`);
      setTitle("");
      setBody("");
      onSent();
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this notification"));
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
      <Card className="border-border shadow-none lg:col-span-2">
        <CardHeader>
          <CardTitle>Compose</CardTitle>
          <CardDescription>No push provider is wired in yet — sending here records history and reports the audience it would have reached.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex flex-wrap gap-1.5">
            {TEMPLATES.map((t) => (
              <Button key={t.label} type="button" variant="outline" size="sm" onClick={() => applyTemplate(t)}>
                {t.label}
              </Button>
            ))}
          </div>

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
            <Label htmlFor="push-title">Title</Label>
            <Input id="push-title" value={title} onChange={(e) => setTitle(e.target.value)} placeholder="🎉 July Challenge is Live!" />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="push-body">Body</Label>
            <Textarea id="push-body" rows={3} value={body} onChange={(e) => setBody(e.target.value)} placeholder="Join now and compete for the top spot." />
          </div>

          <div className="flex justify-end">
            <Button onClick={handleSend} disabled={title.trim().length === 0 || body.trim().length === 0 || sending}>
              {sending ? <CircleNotch size={14} className="animate-spin" /> : <PaperPlaneTilt size={14} />}
              Send to {formatNumber(audienceCount)}
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card className="border-border shadow-none">
        <CardHeader>
          <CardTitle>Send history</CardTitle>
          <CardDescription>{history.length} sent so far.</CardDescription>
        </CardHeader>
        <CardContent className="max-h-[520px] space-y-2 overflow-y-auto">
          {history.length === 0 && <p className="text-sm text-muted-foreground">Nothing sent yet.</p>}
          {history.map((h) => (
            <div key={h.id} className="rounded-md border border-border p-2.5">
              <div className="flex items-center justify-between gap-2">
                <Badge variant="outline" className="text-[11px]">{PUSH_SEGMENT_LABEL[h.segment]}</Badge>
                <span className="text-xs text-muted-foreground">{formatDateTime(h.sent_at)}</span>
              </div>
              <p className="mt-1.5 text-sm font-medium text-foreground">{h.title}</p>
              <p className="text-sm text-muted-foreground">{h.body}</p>
              <p className="mt-1 text-xs text-muted-foreground">
                {formatNumber(h.recipient_count)} recipient{h.recipient_count === 1 ? "" : "s"}
                {h.sent_by && <> · sent by {userDisplayName(findUserById(users, h.sent_by))}</>}
              </p>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
