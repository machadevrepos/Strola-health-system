"use client";

// Faithful mockups of each OS's own notification chrome (not the admin
// panel's brand chrome) — that's deliberate: an admin previewing a push
// needs to see what iOS/Android actually render, radius lock and all,
// not a panel-styled stand-in. Only the sender's app icon carries brand
// color, everything else follows the two platforms' own conventions.

const IOS_FONT = '-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif';
const ANDROID_FONT = 'Roboto, "Segoe UI", sans-serif';

function AppGlyph({ size, radius }: { size: number; radius: number }) {
  return (
    <div
      className="flex shrink-0 items-center justify-center bg-[#E07A7A] font-semibold text-white"
      style={{ width: size, height: size, borderRadius: radius, fontSize: size * 0.42 }}
    >
      S
    </div>
  );
}

export function IOSNotificationPreview({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-[32px] bg-gradient-to-b from-[#3a3f52] to-[#111319] p-3.5">
      <div className="mb-3 text-center text-[13px] font-medium tracking-wide text-white/80" style={{ fontFamily: IOS_FONT }}>
        9:41
      </div>
      <div className="flex items-start gap-2.5 rounded-[18px] bg-white/95 p-3 shadow-[0_8px_24px_rgba(0,0,0,0.25)]" style={{ fontFamily: IOS_FONT }}>
        <AppGlyph size={32} radius={9} />
        <div className="min-w-0 flex-1">
          <div className="flex items-baseline justify-between gap-2">
            <span className="text-[10.5px] font-semibold uppercase tracking-wide text-black/45">Strolla Health</span>
            <span className="shrink-0 text-[11px] text-black/40">now</span>
          </div>
          <p className="truncate text-[14.5px] font-semibold leading-tight text-black">{title || "Notification title"}</p>
          <p className="line-clamp-2 text-[14px] leading-snug text-black/70">{body || "Notification body text goes here."}</p>
        </div>
      </div>
    </div>
  );
}

export function AndroidNotificationPreview({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-[24px] bg-[#eceef1] p-3.5">
      <div className="mb-3 flex items-center justify-between px-1 text-[12px] font-medium text-black/55" style={{ fontFamily: ANDROID_FONT }}>
        <span>9:41</span>
        <span className="text-[10px] uppercase tracking-wide text-black/35">now</span>
      </div>
      <div className="rounded-[14px] bg-white p-3 shadow-[0_1px_3px_rgba(0,0,0,0.12)]" style={{ fontFamily: ANDROID_FONT }}>
        <div className="mb-1.5 flex items-center gap-1.5 text-[11.5px] text-black/55">
          <AppGlyph size={16} radius={999} />
          <span>Strolla Health</span>
          <span className="text-black/30">•</span>
          <span>now</span>
        </div>
        <p className="truncate text-[14px] font-medium leading-tight text-black">{title || "Notification title"}</p>
        <p className="line-clamp-2 text-[13.5px] leading-snug text-black/65">{body || "Notification body text goes here."}</p>
      </div>
    </div>
  );
}
