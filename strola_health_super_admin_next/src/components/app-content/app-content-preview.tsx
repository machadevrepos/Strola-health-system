"use client";

import * as React from "react";
import {
  BluetoothConnected,
  CaretRight,
  ChartBar,
  Crown,
  DownloadSimple,
  GridFour,
  WarningCircle,
} from "@phosphor-icons/react";
import { IOSNotificationPreview } from "@/components/notifications/notification-preview";
import { renderInlineMarkdown } from "@/lib/inline-markdown";
import type { AppContentCategory } from "@/lib/types";

// Renders the same "**bold**"/"[text](url)" syntax the App Content editor's
// toolbar produces, so what an admin sees here matches what they styled.
function Rich({ text }: { text: string }) {
  return <>{renderInlineMarkdown(text, "app-content-preview")}</>;
}

// One representative, simplified scene per screen area — not a pixel-exact
// clone of the Flutter screen, just enough real layout to show an admin
// where a string lands without them having to open the app.
export const CATEGORY_LOCATION: Record<AppContentCategory, string> = {
  onboarding: "Sign-up wizard and the 3-slide welcome carousel, shown before first sign-in.",
  home: "Home tab — the dashboard a signed-in user lands on.",
  challenges: "Challenges tab, challenge cards, and the Challenges bottom-nav label.",
  community: "Community tab — the social feed and post composer.",
  errors: "Inline error banners/toasts shown wherever a request fails.",
  buttons: "Reusable button labels used across multiple screens.",
  settings: "Settings screen — the profile menu's list of rows.",
  premium: "The Premium paywall screen.",
  notifications: "Push notifications sent to the device.",
  widget: "The home-screen / lock-screen widget.",
  device_pairing: "The Bluetooth pairing flow when connecting a Strolla tracker.",
  firmware: "Firmware-update prompts shown once a tracker is paired.",
};

function Phone({ children }: { children: React.ReactNode }) {
  return <div className="mx-auto w-full max-w-[280px] rounded-[28px] bg-secondary p-3">{children}</div>;
}

function Screen({ children }: { children: React.ReactNode }) {
  return <div className="min-h-[220px] rounded-2xl bg-background p-3.5">{children}</div>;
}

function OnboardingScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="mb-4 flex justify-center gap-1.5">
        {[0, 1, 2].map((i) => (
          <span key={i} className={`h-1.5 w-1.5 rounded-full ${i === 0 ? "bg-primary" : "bg-border"}`} />
        ))}
      </div>
      <p className="text-center text-base font-semibold text-foreground"><Rich text={text} /></p>
      <div className="mt-6 h-9 rounded-full bg-primary/90" />
    </Screen>
  );
}

function HomeScene({ text }: { text: string }) {
  return (
    <Screen>
      <p className="text-sm font-semibold text-foreground"><Rich text={text} /></p>
      <div className="mt-4 flex justify-center">
        <div className="flex h-24 w-24 items-center justify-center rounded-full border-[6px] border-primary/70">
          <ChartBar size={22} className="text-primary" />
        </div>
      </div>
    </Screen>
  );
}

function ChallengesScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="mb-2 flex items-center justify-between text-xs font-semibold text-muted-foreground">
        <span>Home</span>
        <span className="rounded-full bg-primary/15 px-2 py-0.5 text-primary">Challenges</span>
        <span>Community</span>
      </div>
      <div className="rounded-xl border border-border bg-secondary/50 p-3">
        <p className="text-lg leading-none">🔥</p>
        <p className="mt-1.5 text-sm text-foreground"><Rich text={text} /></p>
      </div>
    </Screen>
  );
}

function CommunityScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="rounded-xl border border-border p-3">
        <div className="flex items-center gap-2">
          <div className="h-6 w-6 rounded-full bg-primary/60" />
          <div className="h-2 w-16 rounded-full bg-border" />
        </div>
        <p className="mt-2.5 text-sm text-muted-foreground"><Rich text={text} /></p>
      </div>
    </Screen>
  );
}

function ErrorsScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="flex items-start gap-2 rounded-xl bg-destructive/10 p-3">
        <WarningCircle size={18} className="mt-0.5 shrink-0 text-destructive" />
        <p className="text-sm text-destructive"><Rich text={text} /></p>
      </div>
    </Screen>
  );
}

function ButtonsScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="flex h-full items-center justify-center">
        <div className="rounded-full bg-primary px-6 py-2.5 text-sm font-semibold text-primary-foreground"><Rich text={text} /></div>
      </div>
    </Screen>
  );
}

function SettingsScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="space-y-2">
        {[0, 1].map((i) => (
          <div key={i} className="h-8 rounded-lg bg-secondary/50" />
        ))}
        <div className="flex items-center justify-between rounded-lg border border-primary/30 bg-primary/10 px-2.5 py-2">
          <span className="text-sm font-medium text-foreground"><Rich text={text} /></span>
          <CaretRight size={14} className="text-muted-foreground" />
        </div>
      </div>
    </Screen>
  );
}

function PremiumScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="flex flex-col items-center text-center">
        <Crown size={26} className="text-primary" weight="fill" />
        <p className="mt-2 text-sm font-semibold text-foreground"><Rich text={text} /></p>
        <div className="mt-4 h-9 w-full rounded-full bg-primary" />
      </div>
    </Screen>
  );
}

function NotificationsScene({ text }: { text: string }) {
  return (
    <div className="pt-2">
      <IOSNotificationPreview title="Strolla Health" body={text} />
    </div>
  );
}

function WidgetScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="flex h-full items-center justify-center">
        <div className="flex h-32 w-32 flex-col items-center justify-center gap-1 rounded-[22px] bg-secondary/60 p-3 text-center">
          <GridFour size={16} className="text-primary" />
          <p className="text-[11px] font-medium leading-tight text-foreground"><Rich text={text} /></p>
        </div>
      </div>
    </Screen>
  );
}

function DevicePairingScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="flex flex-col items-center pt-2 text-center">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-primary/15">
          <BluetoothConnected size={22} className="text-primary" />
        </div>
        <p className="mt-3 text-sm text-foreground"><Rich text={text} /></p>
      </div>
    </Screen>
  );
}

function FirmwareScene({ text }: { text: string }) {
  return (
    <Screen>
      <div className="flex items-start gap-2.5 rounded-xl border border-border bg-secondary/40 p-3">
        <DownloadSimple size={18} className="mt-0.5 shrink-0 text-primary" />
        <p className="text-sm text-foreground"><Rich text={text} /></p>
      </div>
    </Screen>
  );
}

const SCENES: Record<AppContentCategory, React.ComponentType<{ text: string }>> = {
  onboarding: OnboardingScene,
  home: HomeScene,
  challenges: ChallengesScene,
  community: CommunityScene,
  errors: ErrorsScene,
  buttons: ButtonsScene,
  settings: SettingsScene,
  premium: PremiumScene,
  notifications: NotificationsScene,
  widget: WidgetScene,
  device_pairing: DevicePairingScene,
  firmware: FirmwareScene,
};

export function AppContentPreview({ category, text }: { category: AppContentCategory; text: string }) {
  const Scene = SCENES[category];
  return (
    <Phone>
      <Scene text={text || "Your text goes here"} />
    </Phone>
  );
}

