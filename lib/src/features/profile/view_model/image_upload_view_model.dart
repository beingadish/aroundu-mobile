import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/view_model/auth_view_model.dart';

/// Maximum profile image size: 5 MB (matches backend constraint).
const _maxImageBytes = 5 * 1024 * 1024;

/// State for the image upload flow.
class ImageUploadState {
  const ImageUploadState({
    this.isUploading = false,
    this.errorMessage,
    this.successUrl,
  });

  final bool isUploading;
  final String? errorMessage;
  final String? successUrl;

  ImageUploadState copyWith({
    bool? isUploading,
    String? errorMessage,
    String? successUrl,
    bool clearError = false,
  }) {
    return ImageUploadState(
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successUrl: successUrl ?? this.successUrl,
    );
  }
}

/// Notifier that handles picking and uploading a profile image.
///
/// Flow:
/// 1. [pickAndUpload] opens the image picker.
/// 2. Selected image is validated (max 5 MB).
/// 3. Uploaded via [UserProfileApi.uploadProfileImage].
/// 4. On success, [authControllerProvider] is refreshed so the avatar updates.
class ImageUploadController extends Notifier<ImageUploadState> {
  @override
  ImageUploadState build() => const ImageUploadState();

  Future<bool> pickAndUpload() async {
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    final token = auth.token;

    if (userId == null || token == null || token.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Not authenticated. Please log in again.',
      );
      return false;
    }

    // 1. Pick image
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not open image picker.');
      return false;
    }

    if (picked == null) return false; // user cancelled

    // 2. Read bytes and validate size
    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not read the selected image.');
      return false;
    }

    if (bytes.lengthInBytes > _maxImageBytes) {
      state = state.copyWith(
        errorMessage: 'Image must be under 5 MB. Please choose a smaller file.',
      );
      return false;
    }

    // 3. Upload
    state = state.copyWith(isUploading: true, clearError: true);

    try {
      final userProfileApi = ref.read(userProfileApiProvider);
      final url = await userProfileApi.uploadProfileImage(
        token: token,
        userId: userId,
        imageBytes: bytes,
        fileName: picked.name,
      );

      state = state.copyWith(isUploading: false, successUrl: url);

      // 4. Refresh profile so avatar updates immediately in the UI
      await ref.read(authControllerProvider.notifier).refreshProfile();

      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: e.userMessage,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Upload failed. Please try again.',
      );
      return false;
    }
  }
}

final imageUploadControllerProvider =
    NotifierProvider<ImageUploadController, ImageUploadState>(
  ImageUploadController.new,
);
