import 'package:flutter/material.dart';
import 'package:flutter_iconly_plus/flutter_iconly_plus.dart';
import 'package:provider/provider.dart';
import 'package:my_mobile_app/providers/cart_provider.dart';
import 'package:my_mobile_app/providers/user_provider.dart';
import 'package:my_mobile_app/ui/screens/admin/admin_screen.dart';
import 'package:my_mobile_app/ui/screens/auth/login_screen.dart';
import 'package:my_mobile_app/ui/screens/cartscreen.dart';
import 'package:my_mobile_app/ui/screens/home_screen.dart';
import 'package:my_mobile_app/ui/screens/profilescreen.dart';
import 'package:my_mobile_app/ui/screens/searchscreen.dart';
import 'package:my_mobile_app/ui/screens/viewmodels/auth_startup_viewmodel.dart';

class RootsScreen extends StatefulWidget {
  static const routName = "/RootsScreen";
  const RootsScreen({super.key});

  @override
  State<RootsScreen> createState() => _RootsScreenState();
}

class _RootsScreenState extends State<RootsScreen> {
  late List<Widget> screens;
  int currentScreen = 0;
  late PageController controller;

  @override
  void initState() {
    screens = [const HomeScreen(), const SearchScreen(), const CartScreen(), const ProfileScreen()];
    controller = PageController(initialPage: currentScreen);

    super.initState();
  }

  Future<void> _logout() async {
    final viewModel = context.read<AuthStartupViewModel>();

    final success = await viewModel.logout();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Failed to sign out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                'Shopify',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(IconlyLight.home),
              title: const Text('Home'),
              onTap: () {
                setState(() {
                  currentScreen = 0;
                });
                controller.jumpToPage(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(IconlyLight.search),
              title: const Text('Search'),
              onTap: () {
                setState(() {
                  currentScreen = 1;
                });
                controller.jumpToPage(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Consumer<CartProvider>(
                builder: (context, cart, child) => Badge(
                  label: Text(cart.itemCount.toString()),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(IconlyLight.bag_2),
                ),
              ),
              title: const Text('Cart'),
              onTap: () {
                setState(() {
                  currentScreen = 2;
                });
                controller.jumpToPage(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(IconlyLight.profile),
              title: const Text('Profile'),
              onTap: () {
                setState(() {
                  currentScreen = 3;
                });
                controller.jumpToPage(3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.user?.role == 'admin') {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('Admin Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AdminScreen.routeName);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);

                await _logout();
              },
            ),
          ],
        ),
      ),
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentScreen,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        height: kBottomNavigationBarHeight,

        onDestinationSelected: (index) {
          setState(() {
            currentScreen = index;
          });
          controller.jumpToPage(index);
        },
        destinations: [
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.activity),
            icon: Icon(IconlyLight.activity),
            label: "Home",
          ),
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.search),
            icon: Icon(IconlyLight.search),
            label: "Search",
          ),
          NavigationDestination(
            selectedIcon: Consumer<CartProvider>(
              builder: (context, cart, child) => Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: const Icon(IconlyBold.bag_2),
              ),
            ),
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) => Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: const Icon(IconlyLight.bag_2),
              ),
            ),
            label: "Cart",
          ),
          const NavigationDestination(
            selectedIcon: Icon(IconlyBold.profile),
            icon: Icon(IconlyLight.profile),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
