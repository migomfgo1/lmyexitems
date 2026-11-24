# Notes for App Review — L my ex items

**What the app does:** it helps people find a sport or a game to play with sports gear they already own, and keeps a list of friends to invite.

No sign-in is needed, and nothing is hidden behind a login, feature flag, server switch, location or date. Everything works offline. All data (items, photos, players, games, profile) is stored only on the device.

## Screens
1. **Find a game.** Add photos of your gear with the camera or photo library, describe what you enjoy and pick tags. "Match me with a game" scores 8 sports on the device and shows the top 3, with the reason for each.
2. **Gear & players.** Add, edit or delete items (photo, name, description, sport), and keep a list of players for each sport. "Invite" copies a ready-made invite message to the clipboard, so you can paste it into any chat app.
3. **Your game.** Invent a game: name, idea, rules, number of players, date and a cover photo. Saving it copies the invite text. Tap a saved game to record the result: whether it happened, how many people came, and a rating.
4. **Analytics.** Charts of your recorded games by day of the week: sign-ups, success rate and average rating. This screen is a local HTML file bundled with the app (`assets/web/analytics.html`) and shown in a WebView. It loads nothing from the internet: the app passes its own saved data into the page. With no games recorded yet, the screen offers a button that adds sample games, clearly labelled "(sample)", along with a "Remove" button.
5. **Profile.** Edit your name, photo, date of birth and an "About me" text. See your counts of items, games played, games created and people invited. "Delete all my data" erases everything on the device.

## Permissions
- **Camera** and **Photo Library**: only when the user taps to add a photo.

## To test quickly
Tap **Get started**. In **Find a game**, add a photo of any ball and name it "Soccer ball", then tap **Match me with a game**. Then open **Analytics** and tap **Show sample games** to see the charts.
