import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:my_mobile_app/constants/theme_data.dart';
import 'package:my_mobile_app/data/repositories/product_repository.dart';
import 'package:my_mobile_app/data/services/cloudinary_service.dart';
import 'package:my_mobile_app/firebase_options.dart';
import 'package:my_mobile_app/providers/cart_provider.dart';
import 'package:my_mobile_app/providers/wishlist_provider.dart';
import 'package:my_mobile_app/providers/theme_provider.dart';
import 'package:my_mobile_app/providers/user_provider.dart';
import 'package:my_mobile_app/root_screen.dart';
import 'package:my_mobile_app/ui/screens/admin/admin_screen.dart';
import 'package:my_mobile_app/ui/screens/auth/login_screen.dart';
import 'package:my_mobile_app/ui/screens/auth/signup_screen.dart';
import 'package:my_mobile_app/ui/screens/auth/startup_screen.dart';
import 'package:my_mobile_app/ui/screens/home_screen.dart';
import 'package:my_mobile_app/ui/screens/profilescreen.dart';
import 'package:my_mobile_app/ui/screens/wishlist_screen.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/auth_startup_viewmodel.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/category_viewmodel.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/login_viewmodel.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/product_viewmodel.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/register_viewmodel.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/user_management_viewmodel.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/category_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: .env file not found');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) =>
              LoginViewModel(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<RegisterViewModel>(
          create: (context) =>
              RegisterViewModel(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider<AuthStartupViewModel>(
          create: (context) => AuthStartupViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<UserManagementViewModel>(
          create: (context) => UserManagementViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        Provider<ProductRepository>(create: (_) => ProductRepository()),
        Provider<CloudinaryService>(create: (_) => CloudinaryService()),
        ChangeNotifierProvider<ProductViewModel>(
          create: (context) => ProductViewModel(
            productRepository: context.read<ProductRepository>(),
            cloudinaryService: context.read<CloudinaryService>(),
          ),
        ),
        Provider<CategoryRepository>(create: (_) => CategoryRepository()),
        ChangeNotifierProvider<CategoryViewModel>(
          create: (context) =>
              CategoryViewModel(repository: context.read<CategoryRepository>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              isDarkTheme: themeProvider.getIsDarkTHeme,
              context: context,
            ),
            home: const AuthStartupScreen(),
            routes: {
              LoginScreen.routName: (context) => const LoginScreen(),
              RegisterScreen.routName: (context) => const RegisterScreen(),
              RootsScreen.routName: (context) => const RootsScreen(),
              ProfileScreen.routName: (context) => const ProfileScreen(),
              HomeScreen.routName: (context) => const HomeScreen(),
              WishlistScreen.routName: (context) => const WishlistScreen(),
              AdminScreen.routeName: (context) => const AdminScreen(),
            },
          );
        },
      ),
    );
  }
}
