// Adds a "Join" button to roblox.com/users/<id>/profile when that player is
// in a game you're allowed to join.
(() => {
  const m = location.pathname.match(/^\/users\/(\d+)\/profile/);
  if (!m) return;
  const userId = Number(m[1]);

  const send = (msg) =>
    new Promise((resolve) => chrome.runtime.sendMessage(msg, resolve));

  async function render() {
    const res = await send({ type: "presenceById", userId });
    document.getElementById("hsj-btn")?.remove();
    if (!res || !res.ok || !res.info.joinable) return;

    const { placeId, gameId, game } = res.info;
    const btn = document.createElement("button");
    btn.id = "hsj-btn";
    btn.textContent = `▶ Join in ${game}`;
    btn.onclick = () => send({ type: "join", placeId, gameId });
    document.body.appendChild(btn);
  }

  render();
  setInterval(render, 15000);
})();
