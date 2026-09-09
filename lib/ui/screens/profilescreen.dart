import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:my_mobile_app/providers/user_provider.dart';
import 'package:my_mobile_app/providers/theme_provider.dart';
import 'package:my_mobile_app/ui/screens/auth/login_screen.dart';
import 'package:my_mobile_app/ui/screens/wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routName = "/ProfileScreen";
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUser();
    });
  }

  Future<void> _pickImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  await userProvider.uploadProfileImage(image);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  await userProvider.uploadProfileImage(image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await userProvider.clearUser();
              navigator.pushReplacementNamed(LoginScreen.routName);
            },
          ),
        ],
      ),
      body: userProvider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: user?.userImage != null && user!.userImage.isNotEmpty
                              ? NetworkImage(user.userImage)
                              : null,
                          child: user?.userImage == null || user!.userImage.isEmpty
                              ? const Icon(Icons.person, size: 70, color: Colors.blue)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.name ?? 'User Name',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? 'user@email.com',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  _profileTile(
                    title: 'My Orders',
                    icon: Icons.shopping_bag_outlined,
                    onTap: () {},
                  ),
                  _profileTile(
                    title: 'Wishlist',
                    icon: Icons.favorite_outline,
                    onTap: () {
                      Navigator.pushNamed(context, WishlistScreen.routName);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: Icon(themeProvider.getIsDarkTHeme ? Icons.dark_mode : Icons.light_mode),
                    title: const Text('Dark Mode'),
                    value: themeProvider.getIsDarkTHeme,
                    onChanged: (val) {
                      themeProvider.setDarkTheme(val);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _profileTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
