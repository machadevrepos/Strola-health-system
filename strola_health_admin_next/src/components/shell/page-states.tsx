import { CircleNotch, WarningCircle } from "@phosphor-icons/react";
import { Button } from "@/components/ui/button";

export function PageLoading() {
  return (
    <div className="flex items-center justify-center py-24">
      <CircleNotch size={22} className="animate-spin text-muted-foreground" />
    </div>
  );
}

export function PageError({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-24 text-center">
      <WarningCircle size={24} className="text-destructive" />
      <p className="text-sm text-muted-foreground">{message}</p>
      <Button variant="outline" size="sm" onClick={onRetry}>
        Try again
      </Button>
    </div>
  );
}
