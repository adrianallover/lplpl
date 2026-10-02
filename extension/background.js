import { resolveUser, getPresence, describePresence, joinUrl } from "./lib/roblox.js";

const WATCH_ALARM = "watch-poll";

// ---------- messaging (used by popup + profile content script) ----------

chrome.runtime.onMessage.addListener((msg, _sender, sendResponse) => {
  (async () => {
    switch (msg.type) {
      case "presenceById": {
        const map = await getPresence([msg.userId]);
        return { ok: true, info: describePresence(map.get(msg.userId)) };
      }
      case "join": {
        await chrome.tabs.create({ url: joinUrl(msg.placeId, msg.gameId) });
        return { ok: true };
      }
      default:
        return { ok: false, error: "Unknown message" };
    }
  })()
    .then(sendResponse)
    .catch((e) => sendResponse({ ok: false, error: e.message }));
  return true; // async response
});

// ---------- watch list: notify when someone hops into a joinable game ----------

async function getWatch() {
  const { watch = {} } = await chrome.storage.local.get("watch");
  return watch; // { [userId]: { name, lastGameId } }
}

async function syncAlarm() {
  const watch = await getWatch();
  if (Object.keys(watch).length) {
    chrome.alarms.create(WATCH_ALARM, { periodInMinutes: 0.5 });
  } else {
    chrome.alarms.clear(WATCH_ALARM);
  }
}

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "local" && changes.watch) syncAlarm();
});
chrome.runtime.onInstalled.addListener(syncAlarm);
chrome.runtime.onStartup.addListener(syncAlarm);

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name !== WATCH_ALARM) return;
  const watch = await getWatch();
  const ids = Object.keys(watch).map(Number);
  if (!ids.length) return;

  let presence;
  try {
    presence = await getPresence(ids);
  } catch {
    return; // transient (rate limit / logged out) — try next tick
  }

  let dirty = false;
  for (const id of ids) {
    const info = describePresence(presence.get(id));
    const entry = watch[id];
    const gameId = info.joinable ? info.gameId : null;

    if (gameId && gameId !== entry.lastGameId) {
      chrome.notifications.create(`join:${id}:${info.placeId}:${gameId}`, {
        type: "basic",
        iconUrl: "icons/icon128.png",
        title: `${entry.name} is in ${info.game}`,
        message: "Click to join their server.",
        priority: 2,
      });
    }
    if (entry.lastGameId !== gameId) {
      entry.lastGameId = gameId;
      dirty = true;
    }
  }
  if (dirty) await chrome.storage.local.set({ watch });
});

chrome.notifications.onClicked.addListener((notifId) => {
  const [kind, , placeId, gameId] = notifId.split(":");
  if (kind !== "join") return;
  chrome.tabs.create({ url: joinUrl(placeId, gameId) });
  chrome.notifications.clear(notifId);
});
