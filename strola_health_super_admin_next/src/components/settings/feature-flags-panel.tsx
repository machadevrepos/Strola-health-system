"use client";

import * as React from "react";
import { toast } from "sonner";
import { Card, CardContent } from "@/components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { logAction } from "@/lib/audit-log-store";
import { updateFeatureFlag } from "@/lib/data/api";
import { ApiError } from "@/lib/api-client";
import { titleCase } from "@/lib/format";
import type { FeatureFlag, SubscriptionTier } from "@/lib/types";

function apiErrorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiError ? err.message : fallback;
}

export function FeatureFlagsPanel({ flags: initialFlags }: { flags: FeatureFlag[] }) {
  const [flags, setFlags] = React.useState(initialFlags);

  React.useEffect(() => setFlags(initialFlags), [initialFlags]);

  async function setTier(key: string, tier: SubscriptionTier) {
    const flag = flags.find((f) => f.key === key);
    try {
      const updated = await updateFeatureFlag(key, { required_tier: tier, description: flag?.description ?? null });
      setFlags((prev) => prev.map((f) => (f.key === key ? updated : f)));
      toast.success(`"${key}" now requires ${tier}`);
      logAction(`Set feature gate "${key}" to ${tier}`, key);
    } catch (err) {
      toast.error(apiErrorMessage(err, "Couldn't update feature flag"));
    }
  }

  return (
    <div>
      <p className="mb-3 text-xs text-muted-foreground">
        The free/premium split is still being decided product-side — this is where that decision becomes config
        instead of a code change.
      </p>
      <Card className="border-border shadow-none">
        <CardContent className="divide-y divide-border">
          {flags.map((flag) => (
            <div key={flag.key} className="flex items-center justify-between gap-4 py-3 first:pt-0 last:pb-0">
              <div>
                <p className="font-mono text-sm font-medium text-foreground">{flag.key}</p>
                <p className="text-xs text-muted-foreground">{flag.description}</p>
              </div>
              <Select value={flag.required_tier} onValueChange={(v) => v && setTier(flag.key, v as SubscriptionTier)}>
                <SelectTrigger size="sm" className="w-32">
                  <SelectValue>{titleCase(flag.required_tier)}</SelectValue>
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="free">Free</SelectItem>
                  <SelectItem value="premium">Premium</SelectItem>
                </SelectContent>
              </Select>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
