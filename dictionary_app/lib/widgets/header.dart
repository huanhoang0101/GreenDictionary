
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../localization/app_language.dart';
import '../localization/app_strings.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/profile_page.dart';
import 'language_selector.dart';

class Header extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;

  const Header({
    super.key,
    required this.selectedIndex,
    required this.onMenuSelected,
  });

  static const List<String> menuTitles = [
    'Tra cứu từ',
    'Từ đã lưu',
    'Ngữ pháp',
    'Dịch',
    'Thi thử',
  ];

  static const List<IconData> menuIcons = [
    Icons.search,
    Icons.bookmark_outline,
    Icons.book_outlined,
    Icons.translate,
    Icons.assignment_outlined,
  ];

  void _openLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _openDashboard() {
    onMenuSelected(5);
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.signOut();

      if (!context.mounted) return;

      // Sau khi đăng xuất, trở về trang tra cứu từ.
      onMenuSelected(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đăng xuất thành công.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng xuất thất bại. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        final user = AuthService.currentUser;
        final isLoggedIn = user != null;

        final userName =
            user?.userMetadata?['full_name']?.toString().trim().isNotEmpty ==
                    true
                ? user!.userMetadata!['full_name'].toString()
                : user?.email ?? 'Tài khoản';

        return ValueListenableBuilder<AppLanguage>(
          valueListenable: appLanguage,
          builder: (context, language, child) {
            final strings = AppStrings(language);

            return Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 750;

                      return Row(
                        children: [
                          // Logo: luôn trở về trang Tra cứu từ.
                          InkWell(
                            onTap: () => onMenuSelected(0),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF35A995),
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  strings.appName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263238),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Menu trên desktop.
                          if (!isMobile) ...[
                            for (int i = 0; i < menuTitles.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: TextButton(
                                  onPressed: () => onMenuSelected(i),
                                  style: TextButton.styleFrom(
                                    foregroundColor: selectedIndex == i
                                        ? const Color(0xFF35A995)
                                        : const Color(0xFF455A64),
                                  ),
                                  child: Text(
                                    menuTitles[i],
                                    style: TextStyle(
                                      fontWeight: selectedIndex == i
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(width: 12),

                            if (isLoggedIn) ...[
                              // Tên tài khoản: mở Dashboard trong AppShell.
                              InkWell(
                                onTap: _openDashboard,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.account_circle_outlined,
                                        color: Color(0xFF35A995),
                                      ),
                                      const SizedBox(width: 6),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 130,
                                        ),
                                        child: Text(
                                          userName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF263238),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _logout(context),
                                child: const Text('Đăng xuất'),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: () => _openLogin(context),
                                child: Text(strings.login),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton(
                                onPressed: () => _openRegister(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF35A995),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(strings.register),
                              ),
                            ],

                            const SizedBox(width: 12),
                          ],

                          const LanguageSelector(),

                          // Menu trên điện thoại.
                          if (isMobile) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () {
                                _showMobileMenu(
                                  context,
                                  strings,
                                  isLoggedIn,
                                  userName,
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMobileMenu(
    BuildContext context,
    AppStrings strings,
    bool isLoggedIn,
    String userName,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Năm menu chính.
              for (int i = 0; i < menuTitles.length; i++)
                ListTile(
                  leading: Icon(
                    menuIcons[i],
                    color: selectedIndex == i
                        ? const Color(0xFF35A995)
                        : null,
                  ),
                  title: Text(menuTitles[i]),
                  selected: selectedIndex == i,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onMenuSelected(i);
                  },
                ),

              const Divider(),

              if (isLoggedIn) ...[
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openDashboard();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('Hồ sơ cá nhân'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfilePage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Đăng xuất'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _logout(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(strings.login),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openLogin(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: Text(strings.register),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openRegister(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
