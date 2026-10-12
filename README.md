# 🧵 Tailor Shop

**An offline-first shop manager for tailors**: customers, measurements, orders, payments and a ledger in one app, which keeps working when the internet doesn't.

![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%2B%20Auth-FFCA28?logo=firebase&logoColor=black)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20Windows-1D4ED8)
![License](https://img.shields.io/badge/License-MIT-green)

<!-- Add a hero screenshot or a short GIF here: docs/screenshots/hero.png -->

---

## Why this project

Tailor shops run on paper slips: a customer's measurements, a delivery date, "he paid 2,000 in advance". Slips get lost and balances get argued about. This app replaces the paper with one reliable system, and because shops often have patchy internet, **it is built offline-first**: every feature works without a connection and syncs automatically afterwards.

## Screenshots

| Dashboard | Customer profile | Measurements |
|---|---|---|
| ![](docs/screenshots/01-dashboard.png) | ![](docs/screenshots/02-customer.png) | ![](docs/screenshots/03-measurements.png) |

| Order detail | Ledger | Reports |
|---|---|---|
| ![](docs/screenshots/04-order.png) | ![](docs/screenshots/05-ledger.png) | ![](docs/screenshots/06-reports.png) |

| Offline indicator | Desktop layout | Splash |
|---|---|---|
| ![](docs/screenshots/07-offline.png) | ![](docs/screenshots/08-desktop.png) | ![](docs/screenshots/09-splash.gif) |

## Features

**Customers**
- Add, edit, archive and restore (customers are never deleted, so history is never lost)
- Live search by name or phone; `0300-1234567` and `+92 300 1234567` are treated as the same number
- Duplicate-phone warning (families often share a number, so it can be overridden)
- Profile with Overview, Measurements, Orders and Payments tabs

**Measurements**
- Templates for Shirt/Kurta, Shalwar/Trouser and Waistcoat, with tap-to-choose style options (collar, cuff, pockets...)
- Inch values accept `15.5`, `15 1/2` or `15½`; a fraction bar above the phone keyboard (⅛ ¼ ⅜ ½ ⅝ ¾ ⅞) makes fractions easy to enter
- Roman Urdu hints (Lambai, Teera, Chhati...), optional fields, notes, and "copy from previous set"

**Orders**
- Multiple items per order, order and delivery dates, ticket numbers (`#1`, `#2`...)
- Status workflow: Booked → Cutting → Stitching → Ready → Delivered (or Cancelled), with overdue highlighting
- Attached measurements are **copied into the order**, so editing a customer's measurements later never changes old orders

**Payments and ledger**
- Advance payment at booking, partial payments, Cash / Bank / Other
- Payments are **never edited or deleted, only voided**, which keeps a clean audit trail
- Per-order balance, per-customer ledger, outstanding balances, and a warning when delivering an unpaid order

**Dashboard and reports**
- Overdue, due today, ready for pickup, collected today, outstanding, and more, each tile tappable
- Reports by period (day, week, month, last month, year): income chart, income by payment method, orders by status, top customers

**Offline-first**
- Everything works offline; changes sync automatically on reconnect
- A slim status bar shows *Offline* / *Syncing*, and a dialog appears if the server ever rejects a change made offline

**Everything else**
- Email/password sign-in with friendly error messages
- Responsive layouts: bottom bar on phones, navigation rail on tablets, sidebar on desktop
- Animated splash screen, loading / empty / error states throughout

## Tech stack

| Area | Choice |
|---|---|
| UI | Flutter 3 (Material 3), Dart 3 |
| State management | `flutter_bloc` (Cubit) + `equatable` |
| Navigation | `go_router` (shell routes, auth redirects) |
| Backend | Firebase Authentication, Cloud Firestore (offline persistence) |
| Formatting | `intl` (PKR with lakh grouping, dates) |
| Native splash | `flutter_native_splash` |
| Tests | `flutter_test` (unit tests for the money and measurement logic) |

## Architecture

Feature-first folders, with one rule: **UI never talks to Firestore directly.**

```text
Screen / Widget
      ↓ calls
Cubit (state + business rules)
      ↓ calls
Repository (the only code that touches Firestore)
      ↓
Cloud Firestore  ⇄  local cache (offline)
```

All money and report maths live in small **pure-Dart classes** (`OrderMoney`, `LedgerCalculator`, `DashboardSummary`, `ReportSummary`, `InchFormat`), with no UI and no Firebase, so they are easy to test and reuse.

```text
lib/
├── core/            theme, router, responsive helpers, shared widgets, utils, error mapping
├── features/
│   ├── auth/        login, sign-up, password reset, session
│   ├── customers/   list, form, profile
│   ├── measurements/ templates, form, detail, global list
│   ├── orders/      list, form, detail, status workflow
│   ├── payments/    payments, ledger, customer ledger
│   ├── dashboard/   summary and screen
│   ├── reports/     summary and screen
│   ├── settings/    account and shop name
│   ├── shop/        shop document + bootstrap
│   ├── sync/        sync indicator, rejected-write notice
│   └── shell/       adaptive navigation, app-wide providers
├── firebase_options.dart   (generated, not committed)
└── main.dart
```

## Key design decisions

1. **Offline writes don't wait for the server.** A Firestore write only completes when the server confirms it, which can take hours offline. The UI reacts to the local data stream instead, waits at most one second to surface quick errors (such as permission problems), and reports a *late* rejection through a dialog.
2. **Money integrity is enforced twice.** The app computes balances in one place (`OrderMoney`), and the **Firestore security rules independently verify them**: an order's `totalPaid` can only change in the same batch as a matching payment document (`getAfter` checks), and a payment can only be created or voided together with its order update.
3. **Conflict-safe totals.** Payments update the order with atomic increments (`+2000`, never "set to 5000"), so two devices recording payments while offline both still count when they sync. The Paid/Partial/Unpaid label is always recomputed on read.
4. **Order snapshots.** Orders store a copy of the measurements used, so history never changes retroactively.
5. **Search without a search service.** Collections are held live in memory and filtered on the device, which gives "contains" matching, works offline, and costs nothing extra.
6. **Single-owner data model.** The shop id is the owner's uid (`shops/{uid}/...`), which makes the security rules one line and works offline from first launch.

## Firestore data model

```text
shops/{shopId}                  (shopId = owner's uid)
  ├── customers/{id}      name, nameLower, phone, phoneNormalized, address, notes, isArchived
  ├── measurements/{id}   customerId, garmentType, label, values{}, styles{}, notes
  ├── orders/{id}         customerId, orderNumber, items[], measurements[] (snapshots),
  │                       totalAmount, totalPaid, remainingAmount, status,
  │                       orderDate, deliveryDate, lastPaymentId
  └── payments/{id}       orderId, customerId, amount, method, note, paidAt, isVoided
```

Rules live in [`firestore.rules`](firestore.rules): owner-only access, strict field validation, no hard deletes for customers, orders or payments, and the money rules described above.

## Getting started

### Prerequisites
- Flutter 3.27 or newer (`flutter doctor` should be clean)
- A Google account for Firebase
- Node.js (for the Firebase CLI) and the FlutterFire CLI:
```bash
  npm install -g firebase-tools
  dart pub global activate flutterfire_cli
```
- Windows builds also need Visual Studio 2022 with *Desktop development with C++*

### Setup

```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
flutter pub get
```

1. In the [Firebase Console](https://console.firebase.google.com), create a project.
2. **Authentication → Sign-in method →** enable **Email/Password**.
3. **Firestore Database →** create a database (pick the region closest to you).
4. **Firestore → Rules →** paste the contents of `firestore.rules` and **Publish**.
5. Connect the app to your project (select `android` and `windows`):
```bash
   firebase login
   flutterfire configure
```
This generates `lib/firebase_options.dart` and `android/app/google-services.json`, which are intentionally **not** committed.
6. Run it:
```bash
   flutter run
```

### Tests and checks

```bash
flutter analyze
flutter test
```

### Build

```bash
# Android (needs your own signing key, see android/key.properties)
flutter build apk --release

# Windows
flutter build windows --release
```

A Windows installer script for [Inno Setup](https://jrsoftware.org/isinfo.php) is in `installer/tailor_shop.iss`.

To regenerate the app icon and splash after changing `assets/icon/app_icon.png`:

```bash
dart run flutter_launcher_icons
dart run tool/make_splash_icon.dart
dart run flutter_native_splash:create
```

## Platform support

| Platform | Status |
|---|---|
| Android | ✅ Supported |
| Windows | ✅ Supported |
| iOS | 🔧 Prepared, but needs a Mac to build (run `flutterfire configure` with `ios` selected) |
| Linux | ❌ Firebase's Flutter plugins don't support Linux. A web build is the realistic alternative. |

## Known limitations

- Order numbers use "highest known + 1", so two devices creating orders *while both offline* may briefly share a number (the real ids stay unique)
- Single owner only, with no staff accounts yet (the data model leaves room for them)
- No refunds or customer credit; a mistaken payment is voided
- No backup or export screen yet
- The whole data set is held in memory, which is comfortable up to roughly 10,000 orders
- No email verification or in-app change-password screen yet

## Roadmap

- [ ] Staff accounts with roles
- [ ] Printable receipts and order slips (PDF)
- [ ] Data export and backup
- [ ] Web build for Linux/desktop browsers
- [ ] Load only recent history for very large shops
- [ ] Urdu language and right-to-left layout

## What I learned

Designing for offline sync and conflict handling, enforcing business rules in Firestore security rules, clean separation between UI, state and data, responsive layouts that don't overflow, and shipping a Flutter app to more than one platform.

## License

MIT, see [LICENSE](LICENSE).

## Author

**<Your Name>**: [LinkedIn](<your-linkedin-url>) · [GitHub](https://github.com/<your-username>) · <your-email>