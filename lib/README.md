# Flutter App (`lib`)

This folder contains the Flutter client for Connectinno.

Structure
- `lib/main.dart` — app bootstrap, Supabase & Hive initialization, providers/cubits wiring.
- `lib/models` — `note.dart`, Hive adapter.
- `lib/repositories` — `note_repository.dart` (Hive + Supabase sync logic).
- `lib/services` — `auth_service.dart`, `note_service.dart` (business logic, ChangeNotifier wrappers).
- `lib/cubits` — Bloc/Cubit wrappers for global state.
- `lib/screens` — UI screens: login, signup, home, note create/edit/detail.

How it works (brief)
- Offline-first: reads come from Hive local cache. Background fetch merges server notes.
- Writes attempt Supabase writes and fall back to local Hive if unavailable.
- Authentication should use Supabase Auth. The app currently expects the Supabase anon key in `main.dart` initialization.

Running the app
1. Ensure Flutter is installed and your development device/emulator is ready.
2. From project root:
```bash
cd lib
flutter pub get
flutter run
```

Environment
- See `../.env.example` for required Supabase variables. Put your values in `.env` or initialize Supabase in `lib/main.dart` from secure storage when testing.

Further reading
- See top-level `README.md` and `/docs` for architecture, sync details, and AI feature ideas.
