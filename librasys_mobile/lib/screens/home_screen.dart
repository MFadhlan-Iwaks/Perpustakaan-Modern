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

    final List<Widget> currentScreens = isAdmin ? _adminScreens : _userScreens;

    if (_selectedIndex >= currentScreens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LibraSys', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              authProvider.logout();
            },
          )
        ],
      ),
      body: currentScreens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: isAdmin
            ? const [
                BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Katalog'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transaksi'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Anggota'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              ]
            : const [
                BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Katalog'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              ],
      ),
    );
  }
}