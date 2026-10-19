# One-time ABTC/ABC Firestore import

This tool is separate from the mobile application. It never runs during normal
app startup and does not make the ABTC Locator depend on a CSV file.

Run the importer manually from `flutter_application_1`:

```powershell
flutter run -d chrome -t tool/import_abtcs_web.dart
```

Choose the real `ABTC_ABC-Coordinates-Sheet1.csv` file in the importer. It
validates every row, shows total/valid/invalid/create/update counts, lists every
invalid CSV row, and requires an explicit confirmation before writing the
existing `abtcs` collection. The browser must be signed in with an account that
is allowed by the existing Firestore security rules.
