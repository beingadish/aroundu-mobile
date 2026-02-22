import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../view_model/profile_view_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _experienceController;
  late final TextEditingController _certificationsController;
  late final TextEditingController _payoutController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(editProfileControllerProvider);
    _nameController = TextEditingController(text: state.name);
    _emailController = TextEditingController(text: state.email);
    _phoneController = TextEditingController(text: state.phoneNumber);
    _imageUrlController = TextEditingController(text: state.profileImageUrl);
    _experienceController = TextEditingController(
      text: state.experienceYears?.toString() ?? '',
    );
    _certificationsController = TextEditingController(
      text: state.certifications,
    );
    _payoutController = TextEditingController(text: state.payoutAccount);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    _experienceController.dispose();
    _certificationsController.dispose();
    _payoutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(editProfileControllerProvider.notifier);
    notifier.updateName(_nameController.text);
    notifier.updateEmail(_emailController.text);
    notifier.updatePhoneNumber(_phoneController.text);
    notifier.updateProfileImageUrl(_imageUrlController.text);
    notifier.updateCertifications(_certificationsController.text);
    notifier.updatePayoutAccount(_payoutController.text);

    final expText = _experienceController.text.trim();
    if (expText.isNotEmpty) {
      notifier.updateExperienceYears(int.tryParse(expText));
    }

    final success = await notifier.save();

    if (!mounted) return;

    if (success) {
      AppNotifier.showSuccess(context, 'Profile updated');
      Navigator.of(context).pop();
    } else {
      final error = ref.read(editProfileControllerProvider).errorMessage;
      if (error != null) {
        AppNotifier.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(editProfileControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final isWorker = auth.role == UserRole.worker;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Profile Image URL'),
              keyboardType: TextInputType.url,
            ),
            if (isWorker) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _certificationsController,
                decoration: const InputDecoration(labelText: 'Certifications'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _payoutController,
                decoration: const InputDecoration(labelText: 'Payout Account'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('On Duty'),
                subtitle: const Text('Toggle availability for new tasks'),
                value: editState.isOnDuty,
                onChanged: (_) => ref
                    .read(editProfileControllerProvider.notifier)
                    .toggleOnDuty(),
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Save Changes',
              isLoading: editState.isSubmitting,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
