import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Toaster } from "@/components/ui/sonner";
import { AuthProvider } from "@/lib/auth-context";

// Kept loaded as the automatic fallback in the Arboria font stack (see
// globals.css) rather than a bare system-ui fallback — reliably available
// today (a real Google Font, no local files needed) and looks reasonable
// on its own, so the panel doesn't regress visually while Arboria's actual
// font files aren't in the repo yet. Renamed off "--font-sans" since that
// Tailwind theme token now points at the Arboria stack instead.
const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Strolla Health Admin",
  description: "Internal staff console for Strolla Health.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        <AuthProvider>
          <TooltipProvider delay={300}>
            {children}
            <Toaster position="bottom-right" />
          </TooltipProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
