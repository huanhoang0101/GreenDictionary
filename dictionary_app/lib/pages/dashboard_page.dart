import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const DashboardPage({super.key, this.onNavigate});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfile();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature sẽ được phát triển sau.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = _profile?['full_name']?.toString().trim().isNotEmpty == true
        ? _profile!['full_name'].toString()
        : user?.email ?? 'Bạn';

    final avatarUrl = _profile?['avatar_url']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(name, avatarUrl),
                        const SizedBox(height: 32),

                        const Text(
                          'Tổng quan học tập',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 700 ? 3 : 1;

                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: columns == 3 ? 1.8 : 3.2,
                              children: [
                                InkWell(
                                  onTap: () {
                                    widget.onNavigate?.call(1);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: const _StatCard(
                                    icon: Icons.bookmark_outline,
                                    title: 'Từ vựng đã lưu',
                                    value: 'Quản lý từ vựng',
                                    color: Color(0xFF35A995),
                                  ),
                                ),

                                const _StatCard(
                                  icon: Icons.local_fire_department_outlined,
                                  title: 'Chuỗi ngày học',
                                  value: 'Chưa có dữ liệu',
                                  color: Color(0xFFFFA726),
                                ),

                                const _StatCard(
                                  icon: Icons.flag_outlined,
                                  title: 'Tiến độ JLPT',
                                  value: 'Chưa có dữ liệu',
                                  color: Color(0xFF5C6BC0),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 36),

                        const Text(
                          'Công cụ học tập',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 700 ? 4 : 2;

                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.2,
                              children: [
                                _FeatureCard(
                                  icon: Icons.menu_book_rounded,
                                  title: 'Từ điển',
                                  onTap: () => _showComingSoon('Từ điển'),
                                ),
                                _FeatureCard(
                                  icon: Icons.translate_rounded,
                                  title: 'Kanji',
                                  onTap: () => _showComingSoon('Kanji'),
                                ),
                                _FeatureCard(
                                  icon: Icons.edit_note_rounded,
                                  title: 'Ngữ pháp',
                                  onTap: () => widget.onNavigate?.call(2),
                                ),
                                _FeatureCard(
                                  icon: Icons.style_outlined,
                                  title: 'Flashcard',
                                  onTap: () => _showComingSoon('Flashcard'),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 36),

                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2EF),
                              child: Icon(
                                Icons.person_outline,
                                color: Color(0xFF35A995),
                              ),
                            ),
                            title: const Text(
                              'Thông tin tài khoản',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              'Quản lý tên, ảnh đại diện và thông tin cá nhân',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String name, String? avatarUrl) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chào mừng trở lại, $name!',
                style: const TextStyle(fontSize: 15, color: Color(0xFF607D8B)),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFE0F2EF),
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? const Icon(Icons.person, color: Color(0xFF35A995))
              : null,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF607D8B), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: const Color(0xFF35A995)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF263238),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
