import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      // picsum.photos stands in for real community-post photos in mock mode.
      { protocol: "https", hostname: "picsum.photos" },
      // Real community-post photos, served from Firebase Storage.
      {
        protocol: "https",
        hostname: "firebasestorage.googleapis.com",
        pathname: "/v0/b/strolla-health-4c93b.firebasestorage.app/o/**",
      },
    ],
  },
};

export default nextConfig;
