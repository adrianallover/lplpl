import {
  resolveUser, getPresence, getHeadshot, describePresence, joinUrl, deepLink,
} from "../lib/roblox.js";

const $ = (id) => document.getElementById(id);
const els = {
  form: $("form"), input: $("username"), go: $("go"),
  result: $("result"), avatar: $("avatar"), display: $("display"), handle: $("handle"),
  pill: $("pill"), game: $("game"), note: $("note"),
  join: $("join"), copy: $("copy"), watch: $("watch"), error: $("error"),
  recentWrap: $("recentWrap"), recent: $("recent"),
  watchWrap: $("watchWrap"), watching: $("watching"),
};

let current = null;   // { user, info }
let refreshTimer = null;

// ---------- storage helpers ----------
const store = {
  async get(key, fallback) {
    const o = await chrome.storage.local.get(key);
    return o[key] ?? fallback;
  },
  set: (key, value) => chrome.storage.local.set({ [key]: value }),
};

async function pushRecent(user) {
  let recent = await store.get("recent", []);
  recent = [user.name, ...recent.filter((n) => n.toLowerCase() !== user.name.toLowerCase())].slice(0, 8);
  await store.set("recent", recent);
  renderRecent(recent);
}

function renderRecent(recent) {
  els.recentWrap.hidden = recent.length === 0;
  els.recent.replaceChildren(
    ...recent.map((name) => {
      const c = document.createElement("span");
      c.className = "chip";
      c.textContent = name;
      c.onclick = () => { els.input.value = name; lookup(name); };
      return c;
    })
  );
}

async function renderWatch() {
  const watch = await store.get("watch", {});
  const entries = Object.entries(watch);
  els.watchWrap.hidden = entries.length === 0;
  els.watching.replaceChildren(
    ...entries.map(([id, w]) => {
      const c = document.createElement("span");
      c.className = "chip";
      c.textContent = w.name;
      c.title = "Click to look up";
      c.onclick = () => { els.input.value = w.name; lookup(w.name); };
      const x = document.createElement("span");
      x.className = "x"; x.textContent = "✕"; x.title = "Stop watching";
      x.onclick = async (e) => {
        e.stopPropagation();
        const cur = await store.get("watch", {});
        delete cur[id];
        await store.set("watch", cur);
        await renderWatch();
        updateWatchButton();
      };
      c.append(x);
      return c;
    })
  );
}

async function updateWatchButton() {
  if (!current) return;
  const watch = await store.get("watch", {});
  const on = String(current.user.id) in watch;
  els.watch.classList.toggle("on", on);
  els.watch.textContent = on ? "🔔 Watching" : "🔔 Notify me";
}

// ---------- rendering ----------
function showError(msg) {
  els.error.textContent = msg;
  els.error.hidden = !msg;
}

function renderInfo() {
  const { user, info } = current;
  els.display.textContent = user.displayName || user.name;
  els.handle.textContent = `@${user.name}`;
  els.pill.textContent = info.label;
  els.pill.className = `pill ${info.state}`;

  els.game.textContent = info.game ? `🎮 ${info.game}` : "";
  els.note.textContent = info.reason || (info.joinable ? "Joinable — hit the button!" : "");
  els.join.hidden = !info.joinable;
  els.copy.hidden = !info.joinable;
}

async function lookup(name, { quiet = false } = {}) {
  clearTimeout(refreshTimer);
  showError("");
  if (!quiet) els.go.disabled = true;
  try {
    const user = quiet && current ? current.user : await resolveUser(name);
    const [presence, avatar] = await Promise.all([
      getPresence([user.id]),
      quiet && current ? Promise.resolve(els.avatar.src) : getHeadshot(user.id),
    ]);
    current = { user, info: describePresence(presence.get(user.id)) };
    if (!quiet) {
      els.avatar.src = avatar;
      await pushRecent(user);
    }
    els.result.hidden = false;
    renderInfo();
    updateWatchButton();
    // Keep status fresh while the popup is open.
    refreshTimer = setTimeout(() => lookup(null, { quiet: true }), 8000);
  } catch (e) {
    if (!quiet) { els.result.hidden = true; current = null; }
    showError(e.message);
  } finally {
    els.go.disabled = false;
  }
}

// ---------- events ----------
els.form.addEventListener("submit", (e) => {
  e.preventDefault();
  lookup(els.input.value);
});

els.join.addEventListener("click", () => {
  const { info } = current;
  chrome.tabs.create({ url: joinUrl(info.placeId, info.gameId) });
});

els.copy.addEventListener("click", async () => {
  const { info } = current;
  await navigator.clipboard.writeText(deepLink(info.placeId, info.gameId));
  els.copy.textContent = "Copied!";
  setTimeout(() => (els.copy.textContent = "Copy link"), 1200);
});

els.watch.addEventListener("click", async () => {
  if (!current) return;
  const watch = await store.get("watch", {});
  const id = String(current.user.id);
  if (id in watch) delete watch[id];
  else watch[id] = { name: current.user.name, lastGameId: current.info.gameId || null };
  await store.set("watch", watch);
  await renderWatch();
  updateWatchButton();
});

// ---------- init ----------
(async () => {
  renderRecent(await store.get("recent", []));
  await renderWatch();
})();
