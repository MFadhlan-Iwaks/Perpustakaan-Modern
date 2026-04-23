import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'katalog_screen.dart';
import 'borrowing_screen.dart';
import 'profile_screen.dart';
import 'member_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _userScreens = [
    const KatalogScreen(),
    const BorrowingScreen(),
    const ProfileScreen(),
  ];

  final List<Widget> _adminScreens = [
    const KatalogScreen(),
    const BorrowingScreen(),
    const MemberManagementScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    final colorScheme = Theme.of(context).colorScheme;

    final List<Widget> currentScreens = isAdmin ? _adminScreens : _userScreens;

    if (_selectedIndex >= currentScreens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text('LibraSys', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Text(
                isAdmin ? 'ADMIN' : 'USER',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              authProvider.logout();
            },
          )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: currentScreens[_selectedIndex],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: const Color(0xFF748397),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
        showUnselectedLabels: true,
        items: isAdmin
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Katalog'),
                BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Transaksi'),
                BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Anggota'),
                BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Profil'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Katalog'),
                BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
                BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), label: 'Profil'),
              ],
      ),
    );
  }
}