import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/profile/profile_header_card.dart';
import '../widgets/profile/profile_info_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = user?.role == 'ADMIN';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileHeaderCard(
            name: user?.name ?? 'Pengguna',
            role: user?.role ?? 'USER',
          ),
          const SizedBox(height: 28),
          const Text(
            'Informasi Akun',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ProfileInfoTile(
            icon: Icons.badge_outlined,
            label: 'ID Pengguna',
            value: user?.id.toString() ?? '-',
          ),
          const SizedBox(height: 10),
          ProfileInfoTile(
            icon: Icons.person_outline,
            label: 'Nama',
            value: user?.name ?? '-',
          ),
          const SizedBox(height: 10),
          ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '-',
          ),
          const SizedBox(height: 10),
          ProfileInfoTile(
            icon: Icons.security_outlined,
            label: 'Role',
            value: user?.role ?? '-',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => authProvider.logout(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAdmin ? const Color(0xFF7C3AED) : colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
