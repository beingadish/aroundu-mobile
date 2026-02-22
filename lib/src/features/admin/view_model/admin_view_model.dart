import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../data/admin_api.dart';

class AdminController extends AsyncNotifier<AdminOverview> {
  @override
  Future<AdminOverview> build() => _fetch();

  Future<AdminOverview> _fetch() {
    final auth = ref.read(authControllerProvider);
    final token = auth.token ?? '';
    return ref.read(adminApiProvider).fetchOverview(token);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminControllerProvider =
    AsyncNotifierProvider<AdminController, AdminOverview>(
  AdminController.new,
);
