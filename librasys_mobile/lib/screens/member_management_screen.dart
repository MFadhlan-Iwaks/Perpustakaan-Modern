import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<User> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _apiService.fetchUsers();
      if (!mounted) return;
      setState(() {
        _members = users;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreateMemberDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final password = passwordController.text;

              if (name.isEmpty || email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama, email, dan password wajib diisi.')),
                );
                return;
              }

              setDialogState(() {
                isSubmitting = true;
              });

              try {
                await _apiService.createMember(
                  name: name,
                  email: email,
                  password: password,
                );

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadMembers();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Anggota berhasil ditambahkan'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Tambah Anggota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditMemberDialog(User member) async {
    final nameController = TextEditingController(text: member.name);
    final emailController = TextEditingController(text: member.email);
    String selectedRole = member.role;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isEmpty || email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama dan email wajib diisi.')),
                );
                return;
              }

              setDialogState(() {
                isSubmitting = true;
              });

              try {
                await _apiService.updateUser(
                  id: member.id,
                  name: name,
                  email: email,
                  role: selectedRole,
                );

                if (!mounted) return;
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadMembers();
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Data anggota berhasil diperbarui'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('Edit Anggota'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'USER', child: Text('USER')),
                        DropdownMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedRole = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: Text(isSubmitting ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteMember(User member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: Text('Yakin ingin menghapus ${member.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteUser(member.id);
      if (!mounted) return;
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anggota berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 42),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadMembers,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMemberDialog,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah Anggota'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembers,
        child: _members.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Icon(Icons.groups_2_outlined, size: 56, color: Colors.blueGrey.shade300),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Belum ada data anggota.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _members.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  final isAdmin = member.role == 'ADMIN';

                  return Card(
                    elevation: 1.6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: isAdmin
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFDCFCE7),
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          color: isAdmin
                              ? const Color(0xFF6D28D9)
                              : const Color(0xFF15803D),
                        ),
                      ),
                      title: Text(
                        member.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${member.email}\nRole: ${member.role}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Edit anggota',
                            onPressed: () => _openEditMemberDialog(member),
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF0F766E)),
                          ),
                          IconButton(
                            tooltip: 'Hapus anggota',
                            onPressed: () => _deleteMember(member),
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
