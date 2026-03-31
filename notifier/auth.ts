/**
 * auth.ts — One-time OAuth2 authorization flow for Gmail + Google Calendar.
 *
 * Usage:
 *   1. Create a Google Cloud project at https://console.cloud.google.com
 *   2. Enable Gmail API and Google Calendar API
 *   3. Create OAuth2 credentials (Desktop App type)
 *   4. Download the credentials JSON to ./credentials.json
 *   5. Run: bun run auth.ts
 *   6. Authorize in browser → tokens saved to macOS Keychain
 */

import { google } from "googleapis";
import { readFileSync } from "fs";
import { createServer } from "http";

const CREDENTIALS_PATH = new URL("./credentials.json", import.meta.url).pathname;
const SCOPES = [
  "https://www.googleapis.com/auth/gmail.readonly",
  "https://www.googleapis.com/auth/calendar.readonly",
];
const REDIRECT_PORT = 8234;
const REDIRECT_URI = `http://localhost:${REDIRECT_PORT}/callback`;

const KEYCHAIN_SERVICE = "google-notifier";
const KEYCHAIN_ACCOUNT = "oauth-tokens";

// ── Keychain helpers ──────────────────────────────────────────────
async function saveToKeychain(data: string): Promise<void> {
  // Delete existing entry if present
  Bun.spawnSync(["security", "delete-generic-password", "-s", KEYCHAIN_SERVICE, "-a", KEYCHAIN_ACCOUNT], {
    stderr: "ignore",
  });
  const result = Bun.spawnSync([
    "security", "add-generic-password",
    "-s", KEYCHAIN_SERVICE,
    "-a", KEYCHAIN_ACCOUNT,
    "-w", data,
    "-U",
  ]);
  if (result.exitCode !== 0) {
    throw new Error(`Failed to save to Keychain: ${result.stderr.toString()}`);
  }
}

// ── Main ──────────────────────────────────────────────────────────
async function main(): Promise<void> {
  let credentials: { installed?: { client_id: string; client_secret: string } };
  try {
    credentials = JSON.parse(readFileSync(CREDENTIALS_PATH, "utf-8"));
  } catch {
    console.error("Error: credentials.json not found.");
    console.error("");
    console.error("Steps:");
    console.error("  1. Go to https://console.cloud.google.com/apis/credentials");
    console.error("  2. Create OAuth 2.0 Client ID (Desktop App type)");
    console.error("  3. Download JSON and save as ./credentials.json");
    console.error("  4. Enable Gmail API: https://console.cloud.google.com/apis/library/gmail.googleapis.com");
    console.error("  5. Enable Calendar API: https://console.cloud.google.com/apis/library/calendar-json.googleapis.com");
    process.exit(1);
  }

  const { client_id, client_secret } = credentials.installed!;
  const oauth2 = new google.auth.OAuth2(client_id, client_secret, REDIRECT_URI);

  const authUrl = oauth2.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: SCOPES,
  });

  // Start local server to receive the callback
  const code = await new Promise<string>((resolve, reject) => {
    const server = createServer((req, res) => {
      const url = new URL(req.url!, `http://localhost:${REDIRECT_PORT}`);
      if (url.pathname === "/callback") {
        const authCode = url.searchParams.get("code");
        if (authCode) {
          res.writeHead(200, { "Content-Type": "text/html" });
          res.end("<html><body><h1>Authorized! You can close this tab.</h1></body></html>");
          server.close();
          resolve(authCode);
        } else {
          res.writeHead(400);
          res.end("Missing code parameter");
          server.close();
          reject(new Error("No auth code received"));
        }
      }
    });
    server.listen(REDIRECT_PORT, () => {
      console.log(`Opening browser for authorization...`);
      console.log(`If it doesn't open, visit:\n  ${authUrl}\n`);
      Bun.spawn(["open", authUrl]);
    });
    // Timeout after 2 minutes
    setTimeout(() => {
      server.close();
      reject(new Error("Authorization timed out"));
    }, 120_000);
  });

  // Exchange code for tokens
  const { tokens } = await oauth2.getToken(code);

  if (!tokens.refresh_token) {
    console.error("Error: No refresh token received. Try revoking access at");
    console.error("  https://myaccount.google.com/permissions");
    console.error("and running this again.");
    process.exit(1);
  }

  // Save to macOS Keychain
  await saveToKeychain(JSON.stringify(tokens));

  console.log("\nTokens saved to macOS Keychain.");
  console.log("You can now start the notifier: bun run start");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
