# AroundU Mobile Architecture (MVVM)

## Overview
The mobile app now follows a strict **MVVM** + **feature-first** structure with **Riverpod** for all business state management.

- **Model**: Pure data models (`features/*/model`)
- **ViewModel**: Riverpod notifiers/controllers (`features/*/view_model`)
- **View**: Flutter screens/widgets (`features/*/view`)

## Folder Structure

```text
lib/
  main.dart
  app.dart
  src/
    core/
      config/
        app_environment.dart
      storage/
        local_storage.dart
      network/
        api_client.dart
        api_exception.dart
      providers/
        core_providers.dart
      view_model/
        theme_view_model.dart
      theme/
        app_theme.dart
      widgets/
        primary_button.dart
    features/
      auth/
        data/
          auth_api.dart
        view/
          splash_view.dart
          onboarding_view.dart
          login_view.dart
          register_view.dart
          role_selection_view.dart
        view_model/
          auth_ui_view_model.dart
          auth_view_model.dart
      jobs/
        data/
          job_api.dart
        model/
          job_item.dart
        view/
          provider_shell_view.dart
          worker_shell_view.dart
          widgets/
            job_card.dart
            job_shared_widgets.dart
        view_model/
          create_job_form_view_model.dart
          job_view_model.dart
          navigation_view_model.dart
          worker_skills_view_model.dart
```

## State Management Rules
- Business/session/job state is managed in Riverpod ViewModels only.
- Views only hold widget lifecycle objects (e.g. text/page controllers).
- Ephemeral interactive state (toggle visibility, page index, selected dropdown values) is managed in Riverpod UI ViewModels/providers.
- API/network state is exposed via `AsyncNotifier` and `Notifier` state objects.
- Shared presentation widgets are placed in `features/*/view/widgets` to avoid duplicated screen code.
- Persistent app state (auth session, tab indexes, worker skills) is saved via `LocalStorage` and restored by Riverpod controllers.
- Theme mode is managed in `ThemeModeController` and persisted via `LocalStorage`.

## Data Flow
1. View triggers a ViewModel action (e.g. `login`, `register`, `submit job`).
2. ViewModel calls feature API data source (`AuthApi`, `JobApi`).
3. Data source uses core `ApiClient`.
4. ViewModel maps API data into Model objects and updates provider state.
5. View reacts to provider state changes.

## API Configuration
- Base URL is configured via `API_BASE_URL` dart define.
- Default (Android emulator): `http://10.0.2.2:20232`
- Default (iOS simulator): `http://localhost:20232`

Example run command:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:20232
```

## Cleanup Completed
Removed legacy non-MVVM code paths and unused old UI stacks from `lib/`:
- old auth/routes/provider/worker/constants/maps/models modules
- obsolete localization folder not used by the new runtime flow

The active runtime now uses only `lib/app.dart`, `lib/main.dart`, and `lib/src/**` in this MVVM layout.
