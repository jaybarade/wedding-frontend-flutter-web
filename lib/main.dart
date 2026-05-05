import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/wedding_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/create_wedding_screen.dart';
import 'screens/upload_photos_screen.dart';
import 'screens/gallery_screen.dart';
import 'package:flutter_web_plugins/url_strategy.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, WeddingProvider>(
          create: (_) => WeddingProvider(),
          update: (_, auth, __) =>
              WeddingProvider(token: auth.user?.token),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: createRouter(auth),
          );
        },
      ),
    );
  }
}


GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,

    routes: [
      /// ROOT
      GoRoute(
        path: '/',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),

      /// ✅ CREATE
      GoRoute(
        path: '/create',
        builder: (_, __) => const CreateWeddingScreen(),
      ),

      /// ✅ 🔥 UPLOAD FIX (IMPORTANT)
      GoRoute(
        path: '/upload/:id',
        builder: (_, state) {
          final idStr = state.pathParameters['id'];

          if (idStr == null) {
            return const Scaffold(
              body: Center(child: Text("Invalid ID")),
            );
          }

          final id = int.tryParse(idStr);

          if (id == null) {
            return const Scaffold(
              body: Center(child: Text("Invalid ID format")),
            );
          }

          return UploadPhotosScreen(weddingId: id);
        },
      ),

      /// ✅ PUBLIC GALLERY
      GoRoute(
        path: '/gallery/:slug',
        builder: (_, state) {
          final slug = state.pathParameters['slug'];

          if (slug == null) {
            return const Scaffold(
              body: Center(child: Text("Slug missing")),
            );
          }

          return GalleryScreen(slug: slug);
        },
      ),
    ],

    redirect: (context, state) {
      if (!auth.isInitialized) return null;

      final path = state.uri.path;

      final isLoggedIn = auth.isAuthenticated;
      final isLoginPage = path == '/' || path == '/login';
      final isGallery = path.startsWith('/gallery/');

      /// ✅ PUBLIC ROUTE
      if (isGallery) return null;

      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }

      if (isLoggedIn && isLoginPage) {
        return '/dashboard';
      }

      return null;
    },
  );
}



final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) => const CreateWeddingScreen(),
    ),
    GoRoute(
      path: '/upload/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return UploadPhotosScreen(weddingId: id);
      },
    ),
    GoRoute(
      path: '/gallery/:slug',
      builder: (context, state) {
        final slug = state.pathParameters['slug']!;
        return GalleryScreen(slug: slug);
      },
    ),
  ],
  redirect: (context, state) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final loggingIn = state.matchedLocation == '/login';
    final viewingGallery = state.matchedLocation.startsWith('/gallery/');

    if (viewingGallery) return null; // Public routes

    if (!auth.isAuthenticated) {
      return loggingIn ? null : '/login';
    }

    if (loggingIn) {
      return '/dashboard';
    }

    return null;
  },
);
