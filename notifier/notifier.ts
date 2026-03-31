/**
 * notifier.ts — Gmail + Google Calendar native macOS notifications.
 *
 * Polls Gmail for new unread messages and Google Calendar for upcoming events,
 * sends native macOS notifications via terminal-notifier.
 *
 * Run:
 *   bun run notifier.ts          # long-running daemon
 *   bun run notifier.ts --once   # single check (for testing)
 */

import { google, type gmail_v1, type calendar_v3 } from "googleapis";
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";

// ── Config ────────────────────────────────────────────────────────
const GMAIL_POLL_INTERVAL_MS = 30_000;  // 30 seconds
const CALENDAR_POLL_INTERVAL_MS = 60_000;  // 60 seconds
const CALENDAR_LOOKAHEAD_MS = 15 * 60_000;  // 15 minutes
const CALENDAR_REMINDER_MS = 10 * 60_000;  // notify 10 min before

const CREDENTIALS_PATH = new URL("./credentials.json", import.meta.url).pathname;
const ICONS_DIR = new URL("./icons", import.meta.url).pathname;
const STATE_DIR = `${process.env.HOME}/.google-notifier`;
const STATE_PATH = `${STATE_DIR}/state.json`;
const LOG_PATH = `${STATE_DIR}/notifier.log`;

const KEYCHAIN_SERVICE = "google-notifier";
const KEYCHAIN_ACCOUNT = "oauth-tokens";

const RUN_ONCE = process.argv.includes("--once");

// ── Types ─────────────────────────────────────────────────────────
interface State {
  lastGmailHistoryId: string | null;
  lastGmailCheck: number;
  notifiedMessageIds: string[];
  notifiedEventIds: string[];
}

// ── Logging ───────────────────────────────────────────────────────
function log(msg: string): void {
  const ts = new Date().toISOString();
  const line = `[${ts}] ${msg}`;
  console.log(line);
  try {
    const fd = Bun.file(LOG_PATH);
    Bun.write(LOG_PATH, (existsSync(LOG_PATH) ? readFileSync(LOG_PATH, "utf-8") : "") + line + "\n");
  } catch { /* ignore */ }
}

// ── Keychain ──────────────────────────────────────────────────────
function loadFromKeychain(): { access_token: string; refresh_token: string; expiry_date: number } | null {
  const result = Bun.spawnSync([
    "security", "find-generic-password",
    "-s", KEYCHAIN_SERVICE,
    "-a", KEYCHAIN_ACCOUNT,
    "-w",
  ]);
  if (result.exitCode !== 0) return null;
  try {
    return JSON.parse(result.stdout.toString().trim());
  } catch {
    return null;
  }
}

function saveToKeychain(data: string): void {
  Bun.spawnSync(["security", "delete-generic-password", "-s", KEYCHAIN_SERVICE, "-a", KEYCHAIN_ACCOUNT], {
    stderr: "ignore",
  });
  Bun.spawnSync([
    "security", "add-generic-password",
    "-s", KEYCHAIN_SERVICE,
    "-a", KEYCHAIN_ACCOUNT,
    "-w", data,
    "-U",
  ]);
}

// ── State ─────────────────────────────────────────────────────────
function loadState(): State {
  try {
    return JSON.parse(readFileSync(STATE_PATH, "utf-8"));
  } catch {
    return {
      lastGmailHistoryId: null,
      lastGmailCheck: Date.now(),
      notifiedMessageIds: [],
      notifiedEventIds: [],
    };
  }
}

function saveState(state: State): void {
  // Keep only last 200 IDs to prevent unbounded growth
  state.notifiedMessageIds = state.notifiedMessageIds.slice(-200);
  state.notifiedEventIds = state.notifiedEventIds.slice(-200);
  writeFileSync(STATE_PATH, JSON.stringify(state, null, 2));
}

// ── Notifications ─────────────────────────────────────────────────
function notify(opts: {
  title: string;
  subtitle?: string;
  message: string;
  url?: string;
  group: string;
  sound?: boolean;
  icon?: "gmail" | "gcal";
  activate?: string;
}): void {
  // Chrome PWA bundle IDs
  const activateMap: Record<string, string> = {
    gmail: "com.google.Chrome.app.fmgjjmmmlfnkbppncabfkddbjimcfncm",
    gcal: "com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep",
  };

  // Native app binaries (proper macOS icons)
  const NOTIFIERS_DIR = `${process.env.HOME}/Applications/Notifiers`;
  const nativeAppMap: Record<string, string> = {
    gmail: `${NOTIFIERS_DIR}/GmailNotify.app/Contents/MacOS/GmailNotify`,
    gcal: `${NOTIFIERS_DIR}/CalNotify.app/Contents/MacOS/CalNotify`,
  };

  const binary = opts.icon && nativeAppMap[opts.icon];

  if (binary && existsSync(binary)) {
    // Use native Swift app — shows correct icon
    Bun.spawnSync([binary, opts.title, opts.subtitle || "", opts.message]);

    // Open the Chrome PWA on click isn't supported natively,
    // so activate the app separately after sending
    const bundleId = opts.activate || (opts.icon && activateMap[opts.icon]);
    // Note: native notifications handle click via Notification Center
  } else {
    // Fallback to terminal-notifier
    const args: string[] = [
      "-title", opts.title,
      "-message", opts.message,
      "-group", opts.group,
    ];
    if (opts.subtitle) args.push("-subtitle", opts.subtitle);
    if (opts.sound !== false) args.push("-sound", "default");

    const bundleId = opts.activate || (opts.icon && activateMap[opts.icon]);
    if (bundleId) {
      args.push("-activate", bundleId);
    } else if (opts.url) {
      args.push("-open", opts.url);
    }

    const result = Bun.spawnSync(["terminal-notifier", ...args]);
    if (result.exitCode !== 0) {
      const escaped = opts.message.replace(/"/g, '\\"');
      const titleEscaped = opts.title.replace(/"/g, '\\"');
      Bun.spawnSync(["osascript", "-e", `display notification "${escaped}" with title "${titleEscaped}"`]);
    }
  }
}

// ── OAuth2 client ─────────────────────────────────────────────────
function createAuthClient(): ReturnType<typeof google.auth.OAuth2.prototype.constructor> {
  const credentials = JSON.parse(readFileSync(CREDENTIALS_PATH, "utf-8"));
  const { client_id, client_secret } = credentials.installed;
  const oauth2 = new google.auth.OAuth2(client_id, client_secret);

  const tokens = loadFromKeychain();
  if (!tokens) {
    console.error("No tokens found. Run: bun run auth.ts");
    process.exit(1);
  }
  oauth2.setCredentials(tokens);

  // Auto-refresh and persist new tokens
  oauth2.on("tokens", (newTokens) => {
    const current = loadFromKeychain();
    const merged = { ...current, ...newTokens };
    saveToKeychain(JSON.stringify(merged));
    log("OAuth tokens refreshed");
  });

  return oauth2;
}

// ── Gmail poller ──────────────────────────────────────────────────
async function checkGmail(
  gmail: gmail_v1.Gmail,
  state: State,
): Promise<void> {
  try {
    // Get unread messages in inbox
    const response = await gmail.users.messages.list({
      userId: "me",
      q: "is:unread is:inbox",
      maxResults: 10,
    });

    const messages = response.data.messages || [];
    const newMessages: Array<{ id: string; from: string; subject: string }> = [];

    for (const msg of messages) {
      if (!msg.id || state.notifiedMessageIds.includes(msg.id)) continue;

      const detail = await gmail.users.messages.get({
        userId: "me",
        id: msg.id,
        format: "metadata",
        metadataHeaders: ["From", "Subject"],
      });

      const headers = detail.data.payload?.headers || [];
      const from = headers.find((h) => h.name === "From")?.value || "Unknown";
      const subject = headers.find((h) => h.name === "Subject")?.value || "(no subject)";

      newMessages.push({ id: msg.id, from, subject });
      state.notifiedMessageIds.push(msg.id);
    }

    if (newMessages.length === 1) {
      const msg = newMessages[0];
      // Extract display name from "Name <email>" format
      const fromName = msg.from.replace(/<.*>/, "").trim() || msg.from;
      notify({
        title: "Gmail",
        subtitle: fromName,
        message: msg.subject,
        url: `https://mail.google.com/mail/u/0/#inbox/${msg.id}`,
        group: `gmail-${msg.id}`,
        icon: "gmail",
      });
      log(`Gmail: notified — ${fromName}: ${msg.subject}`);
    } else if (newMessages.length > 1) {
      const firstFrom = newMessages[0].from.replace(/<.*>/, "").trim();
      notify({
        title: "Gmail",
        subtitle: `${newMessages.length} new messages`,
        message: `${firstFrom}: ${newMessages[0].subject} and ${newMessages.length - 1} more`,
        url: "https://mail.google.com/mail/u/0/#inbox",
        group: "gmail-batch",
        icon: "gmail",
      });
      log(`Gmail: notified — ${newMessages.length} new messages`);
    }

    state.lastGmailCheck = Date.now();
  } catch (err: any) {
    if (err?.code === 401) {
      log("Gmail: auth error — run 'bun run auth.ts' to re-authorize");
      notify({
        title: "Google Notifier",
        message: "Authentication expired. Run: cd ~/setup/claude-code-config/notifier && bun run auth.ts",
        group: "notifier-auth-error",
        sound: true,
      });
    } else {
      log(`Gmail error: ${err?.message || err}`);
    }
  }
}

// ── Calendar poller ───────────────────────────────────────────────
async function checkCalendar(
  calendar: calendar_v3.Calendar,
  state: State,
): Promise<void> {
  try {
    const now = new Date();
    const lookahead = new Date(now.getTime() + CALENDAR_LOOKAHEAD_MS);

    const response = await calendar.events.list({
      calendarId: "primary",
      timeMin: now.toISOString(),
      timeMax: lookahead.toISOString(),
      singleEvents: true,
      orderBy: "startTime",
      maxResults: 10,
    });

    const events = response.data.items || [];

    for (const event of events) {
      if (!event.id || !event.start?.dateTime) continue;
      if (state.notifiedEventIds.includes(event.id)) continue;

      const startTime = new Date(event.start.dateTime);
      const timeUntilMs = startTime.getTime() - now.getTime();

      // Notify if event is within the reminder window
      if (timeUntilMs <= CALENDAR_REMINDER_MS && timeUntilMs > 0) {
        const minutesUntil = Math.round(timeUntilMs / 60_000);
        const timeStr = startTime.toLocaleTimeString("en-US", {
          hour: "numeric",
          minute: "2-digit",
          hour12: true,
        });

        const location = event.location ? ` — ${event.location}` : "";
        const meetLink = event.hangoutLink || event.htmlLink || "";

        notify({
          title: "Google Calendar",
          subtitle: `in ${minutesUntil} min — ${timeStr}`,
          message: `${event.summary || "(no title)"}${location}`,
          url: meetLink,
          group: `gcal-${event.id}`,
          icon: "gcal",
        });

        state.notifiedEventIds.push(event.id);
        log(`Calendar: notified — ${event.summary} in ${minutesUntil}min`);
      }
    }

    // Also notify for events starting RIGHT NOW (0-1 min window)
    for (const event of events) {
      if (!event.id || !event.start?.dateTime) continue;
      const startTime = new Date(event.start.dateTime);
      const timeUntilMs = startTime.getTime() - now.getTime();
      const nowKey = `${event.id}-now`;

      if (timeUntilMs <= 60_000 && timeUntilMs >= -60_000 && !state.notifiedEventIds.includes(nowKey)) {
        const meetLink = event.hangoutLink || event.htmlLink || "";
        notify({
          title: "Google Calendar",
          subtitle: "Starting now",
          message: `${event.summary || "(no title)"}`,
          url: meetLink,
          group: `gcal-now-${event.id}`,
          icon: "gcal",
          sound: true,
        });
        state.notifiedEventIds.push(nowKey);
        log(`Calendar: notified — ${event.summary} starting NOW`);
      }
    }
  } catch (err: any) {
    if (err?.code === 401) {
      log("Calendar: auth error — run 'bun run auth.ts' to re-authorize");
    } else {
      log(`Calendar error: ${err?.message || err}`);
    }
  }
}

// ── Main loop ─────────────────────────────────────────────────────
async function main(): Promise<void> {
  mkdirSync(STATE_DIR, { recursive: true });

  const auth = createAuthClient();
  const gmail = google.gmail({ version: "v1", auth });
  const calendar = google.calendar({ version: "v3", auth });
  const state = loadState();

  log("Google Notifier started");

  if (RUN_ONCE) {
    await checkGmail(gmail, state);
    await checkCalendar(calendar, state);
    saveState(state);
    log("Single check complete");
    return;
  }

  // Stagger the initial checks
  await checkGmail(gmail, state);
  saveState(state);

  await checkCalendar(calendar, state);
  saveState(state);

  // Gmail poll loop
  setInterval(async () => {
    await checkGmail(gmail, state);
    saveState(state);
  }, GMAIL_POLL_INTERVAL_MS);

  // Calendar poll loop
  setInterval(async () => {
    await checkCalendar(calendar, state);
    saveState(state);
  }, CALENDAR_POLL_INTERVAL_MS);

  log(`Polling: Gmail every ${GMAIL_POLL_INTERVAL_MS / 1000}s, Calendar every ${CALENDAR_POLL_INTERVAL_MS / 1000}s`);

  // Keep process alive
  process.on("SIGINT", () => {
    log("Shutting down");
    saveState(state);
    process.exit(0);
  });
  process.on("SIGTERM", () => {
    log("Shutting down");
    saveState(state);
    process.exit(0);
  });
}

main().catch((err) => {
  log(`Fatal: ${err}`);
  process.exit(1);
});
