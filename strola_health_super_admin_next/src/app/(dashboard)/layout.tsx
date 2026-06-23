import { Sidebar } from "@/components/shell/sidebar";
import { Topbar } from "@/components/shell/topbar";
import { RequireRole } from "@/components/shell/require-role";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <RequireRole allow={["super_admin"]}>
      <div className="flex h-dvh w-full overflow-hidden bg-background">
        <Sidebar />
        <div className="flex min-w-0 flex-1 flex-col">
          <Topbar />
          <main className="flex-1 overflow-y-auto px-6 py-5">
            <div className="mx-auto max-w-[1400px]">{children}</div>
          </main>
        </div>
      </div>
    </RequireRole>
  );
}
