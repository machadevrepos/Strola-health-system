// Build-time switch baked into the client bundle. Set NEXT_PUBLIC_MOCK_MODE=true
// before `next build` to ship a fully offline build (no backend, no Firebase)
// for client demos — see scripts/package.bat. Every other env var
// (NEXT_PUBLIC_API_URL, Firebase config) is irrelevant when this is true.
export const IS_MOCK_MODE = process.env.NEXT_PUBLIC_MOCK_MODE === "true";
