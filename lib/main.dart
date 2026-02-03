import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/note_service.dart';
import 'cubits/auth_cubit.dart';
import 'cubits/note_cubit.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (replace with your own URL/ANON key or env config)
  await Supabase.initialize(
    url: 'https://adtwqzfegspzcmelpkpc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkdHdxemZlZ3NwemNtZWxwa3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAxMTYzMTQsImV4cCI6MjA4NTY5MjMxNH0.SxHXT6_saCqqXsN-EoId_GwhbrMpyBBVlWo_a7wxCQY',
  );

  // Initialize repository (which initializes Hive)
  final repo = await NoteRepository.init();
  final authService = AuthService();
  final noteService = NoteService(repo);

  runApp(MyApp(authService: authService, noteService: noteService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final NoteService noteService;

  const MyApp({super.key, required this.authService, required this.noteService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => noteService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(authService)),
          BlocProvider(create: (_) => NoteCubit(noteService)),
        ],
        child: MaterialApp(
          title: 'Connectinno Mock Auth',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const Root(),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/signup': (_) => const SignupScreen(),
            '/home': (_) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
