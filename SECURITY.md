# Security baseline

- The project requests no Android permissions and contains no API keys or credentials.
- Do not place payment validation, currency balances, rankings, or secret keys in the client.
- When online features are added, validate critical actions on a server over HTTPS.
- Export release builds only; never distribute a debug build to players.
- Keep Godot, Android SDK, and dependencies updated before release.

Offline games cannot be made impossible to modify. The safe design is to keep only non-critical local data on the device.
