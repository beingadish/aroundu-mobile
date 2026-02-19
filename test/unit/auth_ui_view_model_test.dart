import 'package:aroundu/src/features/auth/view_model/auth_ui_view_model.dart';
import 'package:aroundu/src/features/auth/view_model/auth_view_model.dart';
import 'package:aroundu/src/features/jobs/view_model/create_job_form_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth UI ViewModels', () {
    test(
      'register form UI controller updates role/country/currency/password',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final notifier = container.read(registerFormUiProvider.notifier);
        notifier.setRole(UserRole.worker);
        notifier.setCountry('US');
        notifier.setCurrency('USD');
        notifier.togglePasswordVisibility();

        final state = container.read(registerFormUiProvider);
        expect(state.selectedRole, UserRole.worker);
        expect(state.selectedCountry, 'US');
        expect(state.selectedCurrency, 'USD');
        expect(state.isPasswordObscured, isFalse);
      },
    );

    test('login password and onboarding page providers hold UI state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loginPasswordObscuredProvider.notifier).state = false;
      container.read(onboardingPageProvider.notifier).state = 2;

      expect(container.read(loginPasswordObscuredProvider), isFalse);
      expect(container.read(onboardingPageProvider), 2);
    });

    test(
      'create job selected category provider updates without widget state',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(createJobSelectedCategoryProvider.notifier).state =
            'Electrical';
        expect(container.read(createJobSelectedCategoryProvider), 'Electrical');
      },
    );
  });
}
