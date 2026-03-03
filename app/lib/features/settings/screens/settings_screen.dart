import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/models/app_result.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['name'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authServiceProvider).updateUserName(newName);

    if (mounted) {
      setState(() => _isLoading = false);

      switch (result) {
        case AppSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username updated successfully!')),
          );
        case AppFailure(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              helperText: 'You can only change this once every 24 hours.',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _updateName,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Update Username'),
          ),
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            'Account Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onPressed: () => ref.read(authServiceProvider).signOut(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
