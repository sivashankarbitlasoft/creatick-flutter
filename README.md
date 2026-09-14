# BA Ticket App (Flutter + Riverpod)

## Setup

This is just the `lib/` source + `pubspec.yaml` — you still need Flutter's
own generated platform folders (android/ios/etc). Steps:

1. Create a fresh Flutter project:
   ```
   flutter create ticket_ba_app
   ```
2. Delete the generated `lib/` folder and `pubspec.yaml` inside it, and copy
   in the `lib/` folder and `pubspec.yaml` from this zip instead.
3. Install packages:
   ```
   cd ticket_ba_app
   flutter pub get
   ```
4. **Set your backend URL** in `lib/core/constants.dart`:
   - Android emulator → `http://10.0.2.2:8000` (already set)
   - iOS simulator → `http://127.0.0.1:8000`
   - Physical phone → your computer's LAN IP, e.g. `http://192.168.1.5:8000`
     (phone and computer must be on the same Wi-Fi; make sure your FastAPI
     backend is run with `--host 0.0.0.0` so it accepts non-localhost traffic)
5. Make sure the FastAPI backend from earlier is running.
6. Run the app:
   ```
   flutter run
   ```

## What's included

- `screens/auth/auth_screen.dart` — single screen that toggles between
  Login and Sign Up. Sign-up validates that password and confirm-password
  match before submitting (client-side only, no DB column for it).
- `providers/auth_provider.dart` — Riverpod StateNotifier for
  login/register/logout/update-profile. On app start it checks local
  storage (`shared_preferences`) for a saved user and skips straight to
  Home if found — you only see the login screen again after Logout.
- `screens/home/home_screen.dart` — 3 tabs (Dashboard, Create Ticket,
  Profile) + a floating action button that jumps to the Create Ticket tab.
- `screens/home/dashboard_tab.dart` — lists the logged-in user's tickets as
  cards (ticket number, sub-domain, status) with an Update button that opens
  `update_ticket_screen.dart`.
- `screens/home/create_ticket_tab.dart` — the ticket creation form.
  Checking both Android and iOS submits `app_type: "both"`, and the backend
  returns 2 tickets — the app shows "Created 2 tickets" in that case.
- `screens/home/profile_tab.dart` — view/edit name, phone, and optionally
  change password; Logout clears local storage and returns to the login
  screen.

## Known gap to fix before production

`shared_preferences` stores the logged-in user's info in plaintext on the
device (fine for a small internal tool, but don't store anything more
sensitive there without adding encryption).

## Not yet tested

I don't have a Flutter/Dart SDK available in this environment, so this code
was written carefully but not run through `flutter analyze` or a live build.
Please run `flutter analyze` after step 3 above and let me know if anything
needs fixing — happy to patch quickly.
