# App-link association files

The files in this directory are deployment templates and must not be served
until their signing placeholders have been replaced.

1. Replace the Android fingerprint placeholder with every SHA-256 certificate
   fingerprint used to sign an installed production build, including Google
   Play App Signing and any directly distributed release certificate.
2. Confirm the production iOS bundle identifier and replace the Apple Team ID
   placeholder with the value from the production provisioning profile.
3. Copy the completed files into the web build as:

   - `web/.well-known/assetlinks.json`
   - `web/.well-known/apple-app-site-association`

4. Deploy with the repository's root Vercel deployment script.
5. Verify both hosts return the files directly with HTTP 200, no redirect, and
   a JSON content type:

   - `https://wreadom.in/.well-known/assetlinks.json`
   - `https://wreadom.in/.well-known/apple-app-site-association`

The Vercel rewrite configuration already exempts `/.well-known/` from the
Flutter single-page application fallback.
