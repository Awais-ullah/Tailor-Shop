# Project review

A review of the codebase as of commit `adc32e1` (October 2026), covering build health, correctness risks, repo hygiene and documentation accuracy. Items are ordered by impact. Items marked **✅ Resolved** were fixed on the `refactor/architecture-and-measurement-icons` branch; the rest are still open.

**Overall:** the architecture is clean and consistent. Layers are well separated, money logic lives in one place, offline behaviour is handled deliberately, and the Firestore rules enforce money integrity on the server, which is unusual and valuable. Most issues below concern build setup and repo hygiene rather than app logic.

> `flutter analyze` and `flutter test` were not run for this review. The local SDK (Dart 3.10.4) is older than the `^3.13.3` that `pubspec.yaml` requires, so `pub get` fails.

## Build and setup blockers

### Android builds fail without `key.properties`

**✅ Resolved.** Release signing is now only configured when `key.properties` exists; otherwise the debug key is used. The original finding follows.

[android/app/build.gradle.kts](../android/app/build.gradle.kts) loads `key.properties` only if it exists, but then always creates the release signing config with `keystoreProperties["keyAlias"] as String` (and the same for the other three keys). Without the file these values are `null`, the cast throws while Gradle configures the project, and **debug builds fail too**. Anyone cloning the repo hits this on their first `flutter run`.

**Fix:** only create and assign the release signing config when the file exists, and fall back to the debug key otherwise:

```kotlin
signingConfigs {
    if (keystorePropertiesFile.exists()) {
        create("release") { /* ...same as now... */ }
    }
}
buildTypes {
    release {
        signingConfig = if (keystorePropertiesFile.exists())
            signingConfigs.getByName("release")
        else signingConfigs.getByName("debug")
    }
}
```

### No `windows/` platform folder

The README lists Windows as supported and `installer/tailor_shop.iss` packages a Windows build, but `windows/` is neither committed nor git-ignored. `flutter build windows` fails on a fresh clone, and `firebase.json` has no Windows app entry.

**Fix:** run `flutter create --platforms=windows .`, then `flutterfire configure` with Windows selected, and commit the result.

### SDK requirement is undocumented and the README is wrong

`pubspec.yaml` requires Dart `^3.13.3`, and the code uses newer syntax such as `required this._shopRepository` in `ShopBootstrapper`. The README says "Flutter 3.27 or newer", which ships a much older Dart, so `pub get` fails with a version-solving error.

**Fix:** state the minimum Flutter version that bundles Dart 3.13.3 in the README, and consider pinning it with FVM (`.fvmrc`) or CI.

### Native splash config is nested in `pubspec.yaml`

`flutter_native_splash:` is indented under `flutter_launcher_icons:`, so it is a sub-key of the icons config instead of a top-level section. `dart run flutter_native_splash:create` (a step listed in the README) will not find its configuration.

**Fix:** un-indent the `flutter_native_splash:` block to column 0, or move it to `flutter_native_splash.yaml`.

## Correctness and data risks

### Language code `ru` is used for Roman Urdu

`AppLanguage('ru', 'Roman Urdu', flutterCode: 'en')`. `ru` is the ISO 639-1 code for **Russian**. `LocaleController._resolve` matches the device language against these codes, so a phone set to Russian defaults to Roman Urdu. The code would also collide with a real Russian translation later.

**Fix:** use a private-use or script-tagged code such as `ur_Latn` / `ur-Latn` for the internal id. Map any saved `'ru'` preference to the new code once, so existing users keep their choice.

### Editing an order can be rejected after a concurrent payment

`Order.toUpdateMap()` writes `remainingAmount = totalAmount - totalPaid` using the **local** `totalPaid`. If a payment recorded on another device reaches the server first, the rule `remainingAmount == totalAmount - totalPaid` (evaluated against the server's `totalPaid`) fails. The edit is then rejected, and the user only sees the late "change not saved" dialog.

This is a narrow case (multi-device, offline), but the data stays consistent: the rule prevents corruption.

**Fix options:** drop `remainingAmount` from order edits and let the rules and reads derive it, or note the behaviour in the README's known limitations.

### Duplicate order numbers across offline devices

This is already listed in the README's known limitations. `nextOrderNumber` is the highest known number + 1, so two devices creating orders while both offline can issue the same ticket number. Document ids stay unique, so no data is lost, but printed or written slips can clash. A per-device prefix or a server-assigned counter would fix it once multi-device use is common.

### Display currency is per device, not per shop

`CurrencyController` stores the currency in `SharedPreferences`, while the shop document is locked to `currency == 'PKR'` by the rules. Two devices on the same shop can show the same amounts with different currency symbols. Nothing is converted, so stored data is never wrong; it is a display inconsistency only.

**Fix:** if shops outside Pakistan are a goal, move the currency to the shop document and relax the rule to a list of allowed codes.

## Repo hygiene

| Item | Problem | Suggested action |
|---|---|---|
| `lib.zip` (≈160 KB) | A zipped copy of `lib/` committed in the last commit. It duplicates source and will drift. | **✅ Removed** |
| `tailor_shop_app/` | A separate default `flutter create` project (package `tailor_shop_app`, `com.yourname`) nested in the repo. It is not referenced anywhere, and `analysis_options.yaml` does not exclude it, so the root `flutter analyze` also sees its files. | **✅ Removed** |
| `app_strings.dart` header | Said "GENERATED by tools/gen_l10n.py", but no such script exists. | **✅ Header replaced**; the file is edited by hand and checked by `translations_test.dart` |
| Two `StatusPill` classes | `order_detail_screen.dart` had its own copy that silently shadowed the shared one in `status_chips.dart`. | **✅ Duplicate removed** |
| `lottie` dependency | Declared in `pubspec.yaml` but never imported. | Remove it |
| `applicationId = "com.example.tailor_app"` | Google Play rejects `com.example.*` ids. | Change it (and the Kotlin package) before the first store release; it cannot change afterwards |
| `pubspec.yaml` `description` | Still "A new Flutter project." | Describe the app |
| `firebase.json` | No `firestore` section, so rules can't be deployed with `firebase deploy`. | **✅ Added**, together with emulator settings |
| `firestore.rules` | `isValidShop` is defined in the middle of the `shops/{shopId}` block with misaligned indentation. It works, but is easy to misread. | Move it up with the other `isValid…` functions |

## Testing gaps

**✅ Resolved.** See the test table in [development.md](development.md#testing).
- Unit tests now cover `LedgerCalculator`, `DashboardSummary`, `ReportSummary`, `ReportPeriod.range`, `PhoneUtils` and `Money` in several currencies.
- `translations_test.dart` checks the string tables, `architecture_test.dart` guards the data layer, and the icon tests check every measurement drawing.
- The security rules have an emulator suite in [firestore-tests/](../firestore-tests/).

## Architecture follow-ups

These came out of the architecture review.

| Weak spot | Outcome |
|---|---|
| Data enums imported Flutter UI | **✅ Resolved.** Icons and colours moved to presentation extensions; garment and field icons moved to the measurement icon registry. A test keeps `data/` free of UI imports. |
| `Money` depended on a global setting | **✅ Resolved.** `Money.pkr(amount, {currency})`. The `S` and controller singletons stay on purpose; see [architecture.md](architecture.md#localisation). |
| Payment writes spread over two repositories | **✅ Resolved.** `PaymentRepository` owns every batch that changes `totalPaid`, including creating an order with an advance. |
| Very large screen files | **✅ Mostly resolved.** Sections moved into `presentation/widgets/`. Dashboard 823 → 390 lines, order detail 704 → 427, measurement form 591 → 430. The order form (737 → 536) still has one long `build` method. |
| Untested translations | **✅ Resolved** with `translations_test.dart` and its allowlist. |
| Full-collection loading hard-wired in four places | **✅ Seam added.** Every watched query comes from `ShopCollections`, which is where a "recent only" window would go. No paging yet, by design. |

## README accuracy

Fixed alongside these docs: the SDK prerequisite (now Dart ≥ 3.13.3), the Urdu/RTL roadmap item (now ticked), and the features list (now mentions languages, themes and currencies). Still open:

| README says | Code says |
|---|---|
| `firebase_options.dart`, `google-services.json` not committed | Correct. Note that the app won't compile until `flutterfire configure` has been run |
| Links to `LICENSE` and `docs/screenshots/*` | Neither exists yet |
| Author and clone URL | Still `<Your Name>` / `<your-username>` placeholders |
| Data model omits the shop document and `paymentStatus` / `lastPaymentId` notes | Both exist; see [data-model.md](data-model.md) |

## Strengths worth keeping

- **Server-side money integrity**: `getAfter`-based rules that tie every `totalPaid` change to a matching payment.
- **Atomic increments** for payments, which make offline multi-device payment recording safe.
- **Order snapshots** of measurements, so history never changes retroactively.
- **`awaitWriteBriefly`**: a clear, well-commented solution to Firestore's "write never completes offline" behaviour, with late rejections still reported to the user.
- **Sync indicator that costs no extra reads**, because its queries mirror the data queries.
- **Derived fields recomputed on read**, so stored `paymentStatus` / `remainingAmount` can't mislead the UI.
- **Consistent comments** that explain *why*, which make the codebase easy to pick up.
