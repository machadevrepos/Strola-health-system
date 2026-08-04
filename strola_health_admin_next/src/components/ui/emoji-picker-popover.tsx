"use client";

import * as React from "react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";

// A curated set covering what admins actually pick for badges/challenges/
// announcements in this app (achievements, streaks, milestones) — not a
// full emoji keyboard, just the common ones so there's no hunting through
// an OS picker for "trophy" every time. The input stays freely editable
// alongside this, so anything outside the set is still one paste away.
const COMMON_EMOJIS = [
  "🏅", "🏆", "🥇", "🥈", "🥉", "🎖️", "🏵️", "⭐", "🌟", "✨",
  "🔥", "⚡", "💪", "👟", "🚶", "🏃", "🧗", "🚴", "🏊", "🥾",
  "🎯", "🚀", "📈", "💯", "🎉", "🎊", "👑", "💎", "🛡️", "🧭",
  "🌅", "🌄", "🌈", "☀️", "🌙", "❄️", "🍀", "🌳", "🏔️", "🗺️",
  "📣", "📅", "✅", "❤️", "💙", "💚", "🧡", "💜", "🩷", "🏁",
];

export function EmojiPickerPopover({ value, onSelect }: { value: string; onSelect: (emoji: string) => void }) {
  const [open, setOpen] = React.useState(false);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger
        type="button"
        aria-label="Choose an emoji"
        className="flex size-9 shrink-0 items-center justify-center rounded-md border border-input bg-transparent text-base hover:bg-accent"
      >
        {value || "🏅"}
      </PopoverTrigger>
      <PopoverContent className="w-64" align="start">
        <div className="grid grid-cols-8 gap-1">
          {COMMON_EMOJIS.map((emoji) => (
            <button
              key={emoji}
              type="button"
              onClick={() => {
                onSelect(emoji);
                setOpen(false);
              }}
              className="flex size-7 items-center justify-center rounded-sm text-base hover:bg-accent"
            >
              {emoji}
            </button>
          ))}
        </div>
      </PopoverContent>
    </Popover>
  );
}
