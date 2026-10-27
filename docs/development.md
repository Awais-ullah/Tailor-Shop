# Development guide

Setting up, running, building and extending the app.

## Requirements

| Tool | Version / notes |
|---|---|
| Flutter SDK | One that bundles **Dart ≥ 3.13.3** (`environment.sdk` in [pubspec.yaml](../pubspec.yaml)). Older SDKs fail at `flutter pub get` with "version solving failed". |
| Firebase CLI | `npm install -g firebase-tools` |
| FlutterFire CLI | `dart pub global activate flutterfire_cli` |
| Android | Android Studio / SDK, plus a JDK compatible with the Gradle wrapper |
| Windows builds | Visual Studio 2022 with *Desktop development with C++*, plus a `windows/` platform folder (see below) |

Check with `flutter --version` and `flutter doctor`.

## First-time setup

```bash
flutter pub get
```

1. Create a Firebase project. Enable **Authentication → Email/Password** and create a **Firestore** database.
2. Publish the rules from [firestore.rules](../firestore.rules) (see [data-model.md](data-model.md#deploying-rules)).
3. Generate the Firebase config:
   ```bash
   firebase login
   flutterfire configure        # pick android (and windows / ios as needed)
   ```
   This writes `lib/firebase_options.dart` and `android/app/google-services.json`. Both are git-ignored, and the app will not compile without `firebase_options.dart`.
4. `flutter run`

### Windows platform folder

The repo has no `windows/` folder, although Windows is a target. Generate it once and commit it:

```bash
flutter create --platforms=windows --org <your.org> .
flutterfire configure            # re-run and tick windows
```

## Day-to-day commands

```bash
flutter analyze                  # lints from flutter_lints (see analysis_options.yaml)
flutter test                     # unit tests in test/
flutter run -d <device>
```

## Builds

```bash
# Android: create android/key.properties + keystore first (both git-ignored)
flutter build apk --release
flutter build appbundle --release

# Windows
flutter build windows --release
```

Android release signing reads `android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/absolute/path/to/upload-keystore.jks   # relative paths resolve from android/app/
```

Without `key.properties`, release builds are signed with the debug key so a fresh clone still builds. Never publish one of those to the Play Store.

**Windows installer.** [installer/tailor_shop.iss](../installer/tailor_shop.iss) is an Inno Setup script that packages `build/windows/x64/runner/Release/*` into `installer/output/TailorShopManager-Setup.exe`. Build the Windows release first, then compile the script in Inno Setup. Keep `AppVersion` in step with `version:` in `pubspec.yaml`.

## Icons and splash

| Asset | Purpose |
|---|---|
| `assets/icon/app_icon.png` | Source for launcher icons and the in-app logo |
| `assets/icon/splash_icon.png` | Icon centred on a 1152×1152 transparent canvas (generated) |
| `assets/icon/splash_blank.png` | Fully transparent image, so the native Android 12+ splash is plain white (generated) |

```bash
dart run flutter_launcher_icons
dart run tool/make_splash_icon.dart
dart run tool/make_blank_splash.dart
dart run flutter_native_splash:create
```

> The `flutter_native_splash:` block in `pubspec.yaml` is currently indented under `flutter_launcher_icons:`. It must be a top-level key for `flutter_native_splash:create` to find it. See [review.md](review.md#native-splash-config-is-nested-in-pubspecyaml).

The animated in-app splash is [splash_screen.dart](../lib/features/auth/presentation/screens/splash_screen.dart). The router keeps it on screen until it opens `SplashGate`.

## Project layout

```text
lib/
├── main.dart                  bootstrap (Firebase, persistence, preferences) + TailorShopApp
├── core/
│   ├── currency/              display currency (device setting)
│   ├── data/                  ShopCollections: Firestore paths and watched queries
│   ├── errors/                AppFailure + Firestore error → friendly message
│   ├── l10n/                  AppLanguage, S string tables, LocaleController
│   ├── responsive/            Breakpoints (600 / 1024)
│   ├── router/                GoRouter, route paths, splash gate
│   ├── theme/                 light/dark themes, palette, ThemeController
│   ├── utils/                 dates, money, inches, phone, validators, offline writes
│   └── widgets/               shared widgets (stat tile, state views, snackbar...)
└── features/
    ├── auth/                  login, signup, reset, splash, AuthCubit
    ├── customers/  measurements/  orders/  payments/
    ├── dashboard/  reports/   pure-Dart summaries + screens
    ├── settings/  more/       settings screen, mobile "More" menu
    ├── shop/                  shop document + bootstrapper
    ├── sync/                  sync status + rejected-write dialog
    └── shell/                 adaptive navigation + per-user providers
test/                          unit, architecture, translation and icon tests
firestore-tests/               security-rules tests (Node + Firestore emulator)
tool/                          one-off asset generators
installer/                     Inno Setup script (Windows)
```

## Conventions

- **Imports** use `package:tailor_app/...`.
- **No raw Firestore in UI or cubits.** Add a repository method instead.
- **No money arithmetic outside `OrderMoney` / `LedgerCalculator`.**
- **Every user-visible string goes through `S.current`.** Never hard-code text in widgets.
- **Ids stored in Firestore are permanent**: enum `id`s, measurement field keys, style option ids. Add new values; never rename existing ones.
- **Cubit write methods** validate, then `await awaitWriteBriefly(repo.write(...))`, and throw `AppFailure` with a translated message for user errors.
- Comments explain *why*, in plain language, matching the existing style.

## Common changes

### Add a user-facing string

`app_strings.dart` is edited by hand; there is no generator.

1. Add a getter to `S` in [app_strings.dart](../lib/core/l10n/app_strings.dart):
   ```dart
   String get printReceipt => _t('printReceipt');
   String paidOn(String date) => _p('paidOn', {'date': date});
   ```
2. Add the key to the `'en'` map (required, as it is the fallback).
3. Add translations to `'ur'`, `'ar'`, `'zh'`, `'hi'` and to `ruStrings` in [app_strings_ru.dart](../lib/core/l10n/app_strings_ru.dart).
4. Run `flutter test test/translations_test.dart`. It fails if a translation is missing, or if a `{placeholder}` doesn't match English. If you really must ship without a translation for now, refresh the allowlist with `UPDATE_L10N_ALLOWLIST=1 flutter test test/translations_test.dart`.

For plurals, add `key#one` / `key#other` (and `key#two` where the language needs it), and expose it with `_plural`.

### Add a garment type, field or style option

1. Add a value to `GarmentType` with a new, permanent `id`, or add the field or option to its `GarmentTemplate` in [measurement_templates.dart](../lib/features/measurements/data/measurement_templates.dart).
2. **Draw its icon** in [tailor_glyphs.dart](../lib/features/measurements/presentation/icons/tailor_glyphs.dart): a garment in `garment()`, a field under `_fields[type]`, an option under `_styles[type]['group.option']`. `test/icons/tailor_glyphs_test.dart` fails until you do. See [Measurement icons](#measurement-icons).
3. Add `garment.<id>`, `field.<key>`, `hint.<key>`, `group.<key>` and `opt.<id>` labels to the string tables.
4. For a new garment, add the id to the `garmentType in [...]` list in `isValidMeasurement` in [firestore.rules](../firestore.rules), and deploy the rules **before** releasing.

### Measurement icons

Icons are drawn on a 24 × 24 grid. Reuse the shared outlines at the top of `tailor_glyphs.dart` (`_kurta`, `_shalwar`, `_waistcoat`, plus close-ups such as `_neckline` and `_sleeveEnd`), and put only the measured part or the style detail in `marks`:

| Mark | Use for |
|---|---|
| `Span(from, to)` | Straight lengths: length, shoulder, sleeve |
| `Tape(from, to, bulge:)` | Circumferences: chest, waist, hip, thigh, knee, bottom |
| `Ring(center, rx, ry)` | Loops: collar, armhole |
| `Accent(path, fill:)` | Anything else, such as a cuff band, pocket or collar shape |
| `Dot(center, r)` | Buttons |

To see your drawing, regenerate the gallery and open the PNGs in `test/icons/goldens/`:

```bash
flutter test --update-goldens test/icons/tailor_icons_golden_test.dart
```

Check it at the 28 px size (`icons_light_28.png`), which is how it appears in the form. The goldens are tagged `golden`, because anti-aliasing differs between operating systems; skip them elsewhere with `flutter test -x golden`.

### Add a field to a document

1. Add it to the model's constructor, `fromMap` (with a default for old documents), `toMap` and, if editable, `toUpdateMap`.
2. Add it to the `keys().hasOnly([...])` list and add a type check in the matching `isValid…` rule function.
3. Deploy rules first, then ship the app.

### Add a screen or route

1. Add the path or path builder to [app_routes.dart](../lib/core/router/app_routes.dart).
2. Register it in [app_router.dart](../lib/core/router/app_router.dart) under the right shell branch. Put static segments (`new`) before parameters (`:id`).
3. For a new top-level section, add a `StatefulShellBranch` **and** a matching `_NavItem` with the same `branchIndex` in [app_shell.dart](../lib/features/shell/presentation/screens/app_shell.dart).

## Testing

None of the Dart tests needs Firebase.

| Test | Covers |
|---|---|
| `money_and_inches_test.dart` | `OrderMoney`, `Money` in several currencies, `InchFormat` |
| `ledger_calculator_test.dart`, `dashboard_summary_test.dart`, `report_summary_test.dart` | Balances, dashboard counts and windows, report periods and buckets |
| `phone_utils_test.dart` | Phone normalisation and validation |
| `translations_test.dart` | String tables match English (keys, placeholders, plurals, allowlisted gaps) |
| `architecture_test.dart` | No UI or theme imports under `features/*/data/` |
| `icons/tailor_glyphs_test.dart` | Every garment, field and style option has its own icon, and every path parses |
| `icons/tailor_icons_golden_test.dart` | Pictures of every icon (tag `golden`) |

Shared builders for orders, payments and customers live in `test/support/builders.dart`.

The security rules have their own Node suite, run against the emulator. See [data-model.md](data-model.md#testing-the-rules).
