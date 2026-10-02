// Thin wrapper around Roblox's public web APIs.
//
// Everything here goes through the same endpoints roblox.com itself uses, with
// the signed-in user's own cookies. Roblox decides what each viewer is allowed
// to see: if a player's "Who can join me?" setting doesn't allow you, the
// presence API simply won't hand back a server id, and neither can we.

const PRESENCE = {
  OFFLINE: 0,
  ONLINE: 1,
  IN_GAME: 2,
  IN_STUDIO: 3,
};

let csrfToken = "";

async function rbxFetch(url, { method = "GET", body } = {}) {
  const run = () =>
    fetch(url, {
      method,
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
        ...(method !== "GET" && csrfToken ? { "x-csrf-token": csrfToken } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });

  let res = await run();
  // Roblox answers the first mutating/POST call with 403 + a fresh token.
  if (res.status === 403 && res.headers.get("x-csrf-token")) {
    csrfToken = res.headers.get("x-csrf-token");
    res = await run();
  }
  if (res.status === 429) throw new Error("Roblox is rate-limiting requests. Wait a few seconds.");
  if (res.status === 401) throw new Error("Not logged in. Sign in at roblox.com first.");
  if (!res.ok) throw new Error(`Roblox returned ${res.status}`);
  return res.json();
}

/** Resolve a username (or numeric id) to { id, name, displayName }. */
export async function resolveUser(input) {
  const q = String(input || "").trim().replace(/^@/, "");
  if (!q) throw new Error("Enter a username.");

  if (/^\d+$/.test(q)) {
    // Could be a numeric id *or* an all-digit username; try id first.
    try {
      const u = await rbxFetch(`https://users.roblox.com/v1/users/${q}`);
      if (u && u.id) return { id: u.id, name: u.name, displayName: u.displayName };
    } catch {
      /* fall through to username lookup */
    }
  }

  const res = await rbxFetch("https://users.roblox.com/v1/usernames/users", {
    method: "POST",
    body: { usernames: [q], excludeBannedUsers: true },
  });
  const hit = res.data && res.data[0];
  if (!hit) throw new Error(`No Roblox user called "${q}".`);
  return { id: hit.id, name: hit.name, displayName: hit.displayName };
}

/** Presence for a list of user ids. Returns a Map<userId, presence>. */
export async function getPresence(userIds) {
  const res = await rbxFetch("https://presence.roblox.com/v1/presence/users", {
    method: "POST",
    body: { userIds },
  });
  const out = new Map();
  for (const p of res.userPresences || []) out.set(p.userId, p);
  return out;
}

export async function getHeadshot(userId) {
  try {
    const res = await rbxFetch(
      `https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${userId}&size=150x150&format=Png&isCircular=false`
    );
    return (res.data && res.data[0] && res.data[0].imageUrl) || "";
  } catch {
    return "";
  }
}

/** Turn a raw presence record into something the UI can render directly. */
export function describePresence(p) {
  if (!p) return { state: "unknown", label: "Unknown", joinable: false };

  switch (p.userPresenceType) {
    case PRESENCE.IN_GAME: {
      const joinable = Boolean(p.placeId && p.gameId);
      return {
        state: "ingame",
        label: "In game",
        game: p.lastLocation || "a game",
        placeId: p.placeId || null,
        gameId: p.gameId || null,
        joinable,
        reason: joinable
          ? ""
          : "They're in a game, but their privacy settings don't let you join them. " +
            "Ask them to set Settings → Privacy → \"Who can join me?\" to Everyone (or add you as a friend).",
      };
    }
    case PRESENCE.IN_STUDIO:
      return { state: "studio", label: "In Studio", game: p.lastLocation || "", joinable: false, reason: "They're in Roblox Studio." };
    case PRESENCE.ONLINE:
      return { state: "online", label: "Online", joinable: false, reason: "They're online but not in a game yet." };
    default:
      return { state: "offline", label: "Offline", joinable: false, reason: "They're offline right now." };
  }
}

/** URL that makes roblox.com launch the client straight into that server. */
export function joinUrl(placeId, gameId) {
  const u = new URL("https://www.roblox.com/games/start");
  u.searchParams.set("placeId", placeId);
  if (gameId) u.searchParams.set("gameInstanceId", gameId);
  return u.toString();
}

/** roblox:// deep link, handy to copy for friends. */
export function deepLink(placeId, gameId) {
  return `roblox://experiences/start?placeId=${placeId}&gameInstanceId=${gameId}`;
}
