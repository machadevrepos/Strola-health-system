import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    // picsum.photos stands in for real community-post photos in the mock
    // data set — swap for the real storage bucket's hostname once posts
    // are backed by live data.
    remotePatterns: [{ protocol: "https", hostname: "picsum.photos" }],
  },
};

export default nextConfig;
