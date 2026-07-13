"use client";

import * as React from "react";
import Link from "next/link";
import { toast } from "sonner";
import {
  ArrowLeft,
  PencilSimple,
  Prohibit,
  CheckCircle,
  Trash,
  Footprints,
  DeviceMobile,
  Medal,
  Trophy,
  BatteryMedium,
  Key,
  EnvelopeSimple,
  ProhibitInset,
  X,
} from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge as UiBadge } from "@/components/ui/badge";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Switch } from "@/components/ui/switch";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  AccountStatusBadge,
  RoleBadge,
  SubscriptionBadge,
} from "@/components/shell/status-badges";
import { StepsBarChart } from "@/components/charts/steps-bar-chart";
import { EditProfileSheet, type ProfileEdits } from "@/components/users/edit-profile-sheet";
import { BanUserDialog } from "@/components/users/ban-user-dialog";
import { GrantPremiumMenu } from "@/components/users/grant-premium-menu";
import { DeleteAccountDialog } from "@/components/users/delete-account-dialog";
import { RoleChangeDialog, type PendingRoleChange } from "@/components/users/role-change-dialog";
import { SendEmailDialog } from "@/components/users/send-email-dialog";
import { BanFromPostingDialog } from "@/components/moderation/ban-from-posting-dialog";
import { logAction } from "@/lib/audit-log-store";
import { hasAdminGrantedPremium, userDisplayName } from "@/lib/data/queries";
import {
  adminUnpairDevice,
  awardBadge as apiAwardBadge,
  banUser,
  banUserFromPosting,
  changeUserRole,
  deleteUser,
  fetchUser,
  grantPremium as apiGrantPremium,
  resetUserPassword,
  revokeBadge as apiRevokeBadge,
  revokePremium as apiRevokePremium,
  sendUserEmail,
  unbanUser,
  unbanUserFromPosting,
  updateUser,
  updateUserPrivacy,
} from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { ROLE_LABEL, formatDate, formatDateTime, formatDistance, formatNumber, initials, titleCase } from "@/lib/format";
import type {
  Badge,
  Challenge,
  DailyActivitySummary,
  Device,
  PrivacySettings as PrivacySettingsT,
  UserBadge as UserBadgeT,
  UserProfile,
  WorkoutSession,
} from "@/lib/types";
import type { EnrichedAward, EnrichedParticipant } from "@/lib/data/queries";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function UserDetailView({
  user: initialUser,
  sessions,
  dailySummary,
  devices: initialDevices,
  badges: initialBadges,
  allBadges,
  participations,
  challenges,
}: {
  user: UserProfile;
  sessions: WorkoutSession[];
  dailySummary: DailyActivitySummary[];
  devices: Device[];
  badges: EnrichedAward[];
  allBadges: Badge[];
  participations: EnrichedParticipant[];
  challenges: Challenge[];
}) {
  const [user, setUser] = React.useState(initialUser);
  const [devices, setDevices] = React.useState(initialDevices);
  const [badges, setBadges] = React.useState(initialBadges);
  const [editOpen, setEditOpen] = React.useState(false);
  const [banOpen, setBanOpen] = React.useState(false);
  const [deleteOpen, setDeleteOpen] = React.useState(false);
  const [pendingRole, setPendingRole] = React.useState<PendingRoleChange | null>(null);
  const [pickedBadgeId, setPickedBadgeId] = React.useState("");
  const [emailOpen, setEmailOpen] = React.useState(false);
  const [resettingPassword, setResettingPassword] = React.useState(false);
  const [postingBanOpen, setPostingBanOpen] = React.useState(false);

  const name = userDisplayName(user);
  const awardable = allBadges.filter((b) => !badges.some((a) => a.badge_id === b.id));

  async function saveProfile(edits: ProfileEdits) {
    try {
      const updated = await updateUser(user.id, {
        name: edits.name,
        username: edits.username,
        bio: edits.bio || null,
        location: edits.location || null,
        height_cm: edits.height_cm,
        weight_kg: edits.weight_kg,
        gender: edits.gender,
        daily_goal_steps: edits.daily_goal_steps,
        units: edits.units,
      });
      setUser(updated);
      toast.success("Profile updated");
      logAction("Edited profile", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't save profile changes"));
    }
  }

  async function toggleAmbassador() {
    try {
      const updated = await updateUser(user.id, { is_ambassador: !user.is_ambassador });
      setUser(updated);
      logAction(updated.is_ambassador ? "Marked ambassador" : "Unmarked ambassador", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update ambassador status"));
    }
  }

  async function togglePrivacy(key: keyof PrivacySettingsT) {
    const next = !user.privacy[key];
    try {
      const updated = await updateUserPrivacy(user.id, { [key]: next });
      setUser(updated);
      logAction(`Toggled privacy setting "${key}"`, name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update privacy setting"));
    }
  }

  function requestRoleChange(role: UserProfile["role"]) {
    if (role === user.role) return;
    setPendingRole({ userName: name, role });
  }

  async function confirmRoleChange() {
    if (!pendingRole) return;
    const { role } = pendingRole;
    try {
      await changeUserRole(user.id, role);
      setUser((u) => ({ ...u, role }));
      toast.success(`${name} is now ${ROLE_LABEL[role]}`);
      logAction(`Changed role to ${ROLE_LABEL[role]}`, name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't change role"));
    } finally {
      setPendingRole(null);
    }
  }

  async function ban(reason: string) {
    try {
      await banUser(user.id, reason);
      setUser((u) => ({ ...u, banned: true, ban_reason: reason }));
      toast.success(`${name} banned`);
      logAction("Banned user", `${name} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't ban this user"));
    } finally {
      setBanOpen(false);
    }
  }

  async function unban() {
    try {
      await unbanUser(user.id);
      setUser((u) => ({ ...u, banned: false, ban_reason: null }));
      toast.success(`${name} unbanned`);
      logAction("Unbanned user", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't unban this user"));
    }
  }

  async function deleteAccount() {
    try {
      await deleteUser(user.id);
      const refreshed = await fetchUser(user.id);
      setUser(refreshed);
      toast.success("Account deleted — profile scrubbed, activity retained per policy");
      logAction("Deleted account", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't delete this account"));
    } finally {
      setDeleteOpen(false);
    }
  }

  async function grantPremium(until: Date, reason: string) {
    try {
      await apiGrantPremium(user.id, until.toISOString(), reason);
      setUser((u) => ({ ...u, subscription: { ...u.subscription, comp_until: until.toISOString(), comp_reason: reason } }));
      toast.success(`Premium granted to ${name} until ${formatDate(until.toISOString())}`);
      logAction("Granted premium", `${name} until ${formatDate(until.toISOString())}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't grant premium"));
    }
  }

  async function revokePremium() {
    try {
      await apiRevokePremium(user.id);
      setUser((u) => ({ ...u, subscription: { ...u.subscription, comp_until: null, comp_reason: null } }));
      toast.success(`Comp premium revoked for ${name}`);
      logAction("Revoked comp premium", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't revoke premium"));
    }
  }

  async function sendPasswordReset() {
    setResettingPassword(true);
    try {
      await resetUserPassword(user.id);
      toast.success(`Password reset email sent to ${user.email ?? name}`);
      logAction("Sent password reset email", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send the reset email"));
    } finally {
      setResettingPassword(false);
    }
  }

  async function sendEmail(values: { subject: string; body: string }) {
    try {
      await sendUserEmail(user.id, values);
      toast.success(`Email sent to ${user.email ?? name}`);
      logAction(`Sent email "${values.subject}"`, name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't send this email"));
    } finally {
      setEmailOpen(false);
    }
  }

  async function banFromPosting(reason: string) {
    try {
      await banUserFromPosting(user.id, reason);
      setUser((u) => ({ ...u, posting_banned: true, posting_ban_reason: reason }));
      toast.success(`${name} banned from posting`);
      logAction("Banned user from posting", `${name} — ${reason}`);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't ban this user from posting"));
    } finally {
      setPostingBanOpen(false);
    }
  }

  async function unbanFromPosting() {
    try {
      await unbanUserFromPosting(user.id);
      setUser((u) => ({ ...u, posting_banned: false, posting_ban_reason: null }));
      toast.success(`${name} can post again`);
      logAction("Unbanned user from posting", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't lift this posting ban"));
    }
  }

  async function unpairDevice(deviceId: string) {
    try {
      await adminUnpairDevice(deviceId);
      setDevices((prev) => prev.filter((d) => d.id !== deviceId));
      toast.success("Device unpaired");
      logAction("Unpaired device", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't unpair this device"));
    }
  }

  async function revokeBadge(award: EnrichedAward) {
    try {
      await apiRevokeBadge(award.badge_id, award.user_id);
      setBadges((prev) => prev.filter((b) => b.id !== award.id));
      toast.success("Badge revoked");
      logAction("Revoked badge", name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't revoke badge"));
    }
  }

  async function awardBadgeToUser(badgeId: string) {
    const badge = allBadges.find((b) => b.id === badgeId);
    if (!badge) return;
    try {
      const created = await apiAwardBadge(badgeId, user.id);
      setBadges((prev) => [...prev, { ...created, user, badge }]);
      toast.success(`Awarded "${badge.name}"`);
      logAction(`Awarded badge "${badge.name}"`, name);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't award badge"));
    }
  }

  const hasComp = hasAdminGrantedPremium(user);

  return (
    <div>
      <Link href="/users" className="mb-4 inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft size={14} /> All users
      </Link>

      <div className="flex flex-wrap items-start justify-between gap-4 pb-5">
        <div className="flex items-center gap-3">
          <Avatar className="size-12">
            {user.photo_url && <AvatarImage src={user.photo_url} alt={name} />}
            <AvatarFallback className="text-base">{initials(name)}</AvatarFallback>
          </Avatar>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-lg font-semibold tracking-tight text-foreground">{name}</h1>
              <RoleBadge role={user.role} />
              <AccountStatusBadge user={user} />
              <SubscriptionBadge subscription={user.subscription} />
              {user.posting_banned && <UiBadge className="bg-destructive/12 text-destructive">Posting banned</UiBadge>}
            </div>
            <p className="text-sm text-muted-foreground">
              {user.email ?? `@${user.username}`} {"·"} joined {formatDate(user.created_at)}
            </p>
            {user.banned && user.ban_reason && (
              <p className="mt-1 text-sm text-destructive">Ban reason: {user.ban_reason}</p>
            )}
            {user.posting_banned && user.posting_ban_reason && (
              <p className="mt-1 text-sm text-destructive">Posting ban reason: {user.posting_ban_reason}</p>
            )}
          </div>
        </div>

        {!user.deleted && (
          <div className="flex flex-wrap items-center gap-2">
            {/* Routine actions */}
            <Button variant="outline" size="sm" onClick={() => setEditOpen(true)}>
              <PencilSimple size={14} /> Edit profile
            </Button>
            <Button variant="outline" size="sm" onClick={() => setEmailOpen(true)}>
              <EnvelopeSimple size={14} /> Send email
            </Button>
            <Button variant="outline" size="sm" onClick={sendPasswordReset} disabled={resettingPassword}>
              <Key size={14} /> Reset password
            </Button>
            {hasComp ? (
              <Button variant="outline" size="sm" onClick={revokePremium}>
                <X size={14} /> Revoke premium
              </Button>
            ) : (
              <GrantPremiumMenu userName={name} onGrant={grantPremium} />
            )}

            <Separator orientation="vertical" className="h-6" />

            {/* Sensitive / irreversible-leaning actions */}
            <Select value={user.role} onValueChange={(v) => v && requestRoleChange(v as UserProfile["role"])}>
              <SelectTrigger size="sm" className="w-[140px]" aria-label="Change role">
                <SelectValue>{ROLE_LABEL[user.role]}</SelectValue>
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="user">{ROLE_LABEL.user}</SelectItem>
                <SelectItem value="admin">{ROLE_LABEL.admin}</SelectItem>
                <SelectItem value="super_admin">{ROLE_LABEL.super_admin}</SelectItem>
              </SelectContent>
            </Select>
            {user.posting_banned ? (
              <Button variant="outline" size="sm" onClick={unbanFromPosting}>
                <CheckCircle size={14} /> Unban from posting
              </Button>
            ) : (
              <Button variant="outline" size="sm" onClick={() => setPostingBanOpen(true)}>
                <ProhibitInset size={14} /> Ban from posting
              </Button>
            )}
            {user.banned ? (
              <Button variant="outline" size="sm" onClick={unban}>
                <CheckCircle size={14} /> Unban
              </Button>
            ) : (
              <Button variant="destructive" size="sm" onClick={() => setBanOpen(true)}>
                <Prohibit size={14} /> Ban
              </Button>
            )}
            <Button variant="destructive" size="sm" onClick={() => setDeleteOpen(true)}>
              <Trash size={14} /> Delete
            </Button>
          </div>
        )}
      </div>

      <Tabs defaultValue="profile">
        <TabsList>
          <TabsTrigger value="profile">Profile</TabsTrigger>
          <TabsTrigger value="activity">Activity</TabsTrigger>
          <TabsTrigger value="devices">Devices ({devices.length})</TabsTrigger>
          <TabsTrigger value="badges">Badges ({badges.length})</TabsTrigger>
          <TabsTrigger value="challenges">Challenges ({participations.length})</TabsTrigger>
        </TabsList>

        <TabsContent value="profile" className="mt-4 grid grid-cols-1 items-start gap-3 lg:grid-cols-2">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Profile details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DetailRow label="Bio" value={user.bio ?? "—"} />
              <DetailRow label="Location" value={user.location ?? "—"} />
              <DetailRow label="Height" value={`${user.height_cm} cm`} />
              <DetailRow label="Weight" value={user.weight_kg ? `${user.weight_kg} kg` : "—"} />
              <DetailRow label="Gender" value={titleCase(user.gender)} />
              <DetailRow label="Units" value={titleCase(user.units)} />
              <DetailRow label="Daily goal" value={`${formatNumber(user.daily_goal_steps)} steps`} />
              <DetailRow label="Date of birth" value={user.date_of_birth ? formatDate(user.date_of_birth) : "—"} />
              <DetailRow
                label="Why they use Strolla"
                value={user.reasons.length > 0 ? user.reasons.map(titleCase).join(", ") : "—"}
              />
              <DetailRow label="Onboarding" value={user.onboarding_complete ? "Complete" : "Incomplete"} />
              <div className="flex items-center justify-between border-b border-border py-1.5 last:border-0">
                <span className="text-sm text-muted-foreground">Ambassador</span>
                <Switch checked={user.is_ambassador} onCheckedChange={toggleAmbassador} />
              </div>
            </CardContent>
          </Card>
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Privacy settings</CardTitle>
              <CardDescription>Controls what other members can see on their profile.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-1">
              {(
                [
                  ["public_profile", "Public profile"],
                  ["share_activity", "Share activity"],
                  ["show_in_leaderboards", "Show in leaderboards"],
                  ["allow_friend_requests", "Allow friend requests"],
                  ["hide_activity_data", "Hide activity data"],
                  ["hide_achievements", "Hide achievements"],
                  ["hide_recent_activity", "Hide recent activity"],
                ] as [keyof PrivacySettingsT, string][]
              ).map(([key, label]) => (
                <div key={key} className="flex items-center justify-between py-1.5">
                  <span className="text-sm text-muted-foreground">{label}</span>
                  <Switch checked={user.privacy[key]} onCheckedChange={() => togglePrivacy(key)} />
                </div>
              ))}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="activity" className="mt-4 space-y-3">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Daily steps</CardTitle>
              <CardDescription>Last 30 days. The dashed line marks their daily goal.</CardDescription>
            </CardHeader>
            <CardContent>
              {dailySummary.length > 0 ? (
                <StepsBarChart data={dailySummary.map((d) => ({ date: d.date, steps: d.steps }))} goal={user.daily_goal_steps} />
              ) : (
                <EmptyState icon={<Footprints size={20} />} text="No daily activity recorded yet." />
              )}
            </CardContent>
          </Card>
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Recent sessions</CardTitle>
            </CardHeader>
            <CardContent>
              {sessions.length === 0 ? (
                <EmptyState icon={<Footprints size={20} />} text="No workout sessions yet." />
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead>Activity</TableHead>
                      <TableHead>Steps</TableHead>
                      <TableHead>Distance</TableHead>
                      <TableHead>Calories</TableHead>
                      <TableHead>Started</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {sessions.map((s) => (
                      <TableRow key={s.id}>
                        <TableCell className="capitalize">{s.custom_activity_name ?? s.activity_type.replace(/_/g, " ")}</TableCell>
                        <TableCell className="font-mono">{formatNumber(s.steps)}</TableCell>
                        <TableCell className="font-mono">{formatDistance(s.distance_meters)}</TableCell>
                        <TableCell className="font-mono">{s.calories_burned ?? "—"}</TableCell>
                        <TableCell className="text-muted-foreground">{formatDateTime(s.start_time)}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="devices" className="mt-4">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Paired devices</CardTitle>
            </CardHeader>
            <CardContent>
              {devices.length === 0 ? (
                <EmptyState icon={<DeviceMobile size={20} />} text="No device paired." />
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead>Serial</TableHead>
                      <TableHead>Firmware</TableHead>
                      <TableHead>Battery</TableHead>
                      <TableHead>Last seen</TableHead>
                      <TableHead className="w-10" />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {devices.map((d) => (
                      <TableRow key={d.id}>
                        <TableCell className="font-mono">{d.serial_number}</TableCell>
                        <TableCell>{d.firmware_version ?? "—"}</TableCell>
                        <TableCell>
                          <span className="inline-flex items-center gap-1 font-mono">
                            <BatteryMedium size={14} className={d.battery_level && d.battery_level < 15 ? "text-destructive" : "text-muted-foreground"} />
                            {d.battery_level ?? "—"}%
                          </span>
                        </TableCell>
                        <TableCell className="text-muted-foreground">{d.last_seen_at ? formatDateTime(d.last_seen_at) : "—"}</TableCell>
                        <TableCell>
                          <Button variant="ghost" size="sm" onClick={() => unpairDevice(d.id)}>
                            Unpair
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="badges" className="mt-4 space-y-3">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Awarded badges</CardTitle>
              {awardable.length > 0 && (
                <CardAction>
                  <Select
                    value={pickedBadgeId}
                    onValueChange={(v) => {
                      if (!v) return;
                      awardBadgeToUser(v as string);
                      setPickedBadgeId("");
                    }}
                  >
                    <SelectTrigger size="sm" className="w-44"><SelectValue placeholder="Award a badge..." /></SelectTrigger>
                    <SelectContent>
                      {awardable.map((b) => (
                        <SelectItem key={b.id} value={b.id}>
                          {b.emoji} {b.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </CardAction>
              )}
            </CardHeader>
            <CardContent>
              {badges.length === 0 ? (
                <EmptyState icon={<Medal size={20} />} text="No badges awarded yet." />
              ) : (
                <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                  {badges.map((a: EnrichedAward & UserBadgeT) => (
                    <div key={a.id} className="flex items-center justify-between rounded-md border border-border p-2.5">
                      <div className="flex items-center gap-2.5">
                        <span className="text-xl">{a.badge?.emoji}</span>
                        <div>
                          <p className="text-sm font-medium text-foreground">{a.badge?.name}</p>
                          <p className="text-xs text-muted-foreground">{formatDate(a.awarded_at)}</p>
                        </div>
                      </div>
                      <Button variant="ghost" size="icon-sm" onClick={() => revokeBadge(a)} aria-label="Revoke badge">
                        <X size={14} />
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="challenges" className="mt-4">
          <Card className="border-border shadow-none">
            <CardHeader>
              <CardTitle>Challenge participation</CardTitle>
            </CardHeader>
            <CardContent>
              {participations.length === 0 ? (
                <EmptyState icon={<Trophy size={20} />} text="Not in any challenges." />
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow className="hover:bg-transparent">
                      <TableHead>Challenge</TableHead>
                      <TableHead>Steps</TableHead>
                      <TableHead>Locked goal</TableHead>
                      <TableHead>Joined</TableHead>
                      <TableHead>Status</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {participations.map((p) => (
                      <TableRow key={p.id}>
                        <TableCell>
                          <Link href={`/challenges/${p.challenge_id}`} className="hover:underline">
                            {challenges.find((c) => c.id === p.challenge_id)?.title ?? p.challenge_id}
                          </Link>
                        </TableCell>
                        <TableCell className="font-mono">{formatNumber(p.steps)}</TableCell>
                        <TableCell className="font-mono">{formatNumber(p.locked_daily_goal)}</TableCell>
                        <TableCell className="text-muted-foreground">{formatDate(p.joined_at)}</TableCell>
                        <TableCell>{p.left_at ? "Left" : "Active"}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <EditProfileSheet user={user} open={editOpen} onOpenChange={setEditOpen} onSave={saveProfile} />
      <BanUserDialog user={banOpen ? user : null} onOpenChange={setBanOpen} onConfirm={ban} />
      <DeleteAccountDialog user={user} open={deleteOpen} onOpenChange={setDeleteOpen} onConfirm={deleteAccount} />
      <RoleChangeDialog pending={pendingRole} onOpenChange={(open) => !open && setPendingRole(null)} onConfirm={confirmRoleChange} />
      <SendEmailDialog user={emailOpen ? user : null} onOpenChange={setEmailOpen} onConfirm={sendEmail} />
      <BanFromPostingDialog
        target={postingBanOpen ? { userId: user.id, userName: name } : null}
        onOpenChange={setPostingBanOpen}
        onConfirm={banFromPosting}
      />
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between border-b border-border py-1.5 last:border-0">
      <span className="text-sm text-muted-foreground">{label}</span>
      <span className="text-sm text-foreground">{value}</span>
    </div>
  );
}

function EmptyState({ icon, text }: { icon: React.ReactNode; text: string }) {
  return (
    <div className="flex flex-col items-center gap-2 py-8 text-center text-muted-foreground">
      {icon}
      <p className="text-sm">{text}</p>
    </div>
  );
}
