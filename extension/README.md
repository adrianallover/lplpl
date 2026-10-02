# HideSeek Joiner

A Chrome / Edge / Brave extension: type a Roblox username, see what they're playing, and jump into their server.

## Install
1. Open `chrome://extensions`, enable **Developer mode**.
2. **Load unpacked** → select this `extension/` folder.
3. Log in at roblox.com (the extension uses your own session).

## Features
- **Find by username** (or user id) with live status refresh while the popup is open.
- **Join button** that launches Roblox straight into their exact server.
- **Copy link** (`roblox://` deep link) to send to friends.
- **Notify me**: watch players and get a notification when they enter a joinable game.
- **Profile page button**: a floating "Join" button on `roblox.com/users/<id>/profile`.

## Making it work with friends (not-added players)
The extension asks Roblox's own presence API where a player is. Roblox only returns the server
if that player's privacy setting allows you. So each player should set:

**Roblox → Settings → Privacy → "Who can join me?" → Everyone**

(Default is Friends.) If a player has it off, the popup tells you instead of guessing; the
extension deliberately does not try to work around someone's privacy choice.
