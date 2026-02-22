import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../data/skill_api.dart';

class SkillSuggestState {
  const SkillSuggestState({
    this.query = '',
    this.suggestions = const <SkillItem>[],
    this.selected = const <SkillItem>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final String query;
  final List<SkillItem> suggestions;
  final List<SkillItem> selected;
  final bool isLoading;
  final String? errorMessage;

  SkillSuggestState copyWith({
    String? query,
    List<SkillItem>? suggestions,
    List<SkillItem>? selected,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearSuggestions = false,
  }) {
    return SkillSuggestState(
      query: query ?? this.query,
      suggestions: clearSuggestions
          ? const <SkillItem>[]
          : (suggestions ?? this.suggestions),
      selected: selected ?? this.selected,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Riverpod notifier that handles skill auto-suggest with a 300ms debounce.
///
/// Usage:
/// ```dart
/// ref.read(skillSuggestControllerProvider.notifier).onQueryChanged('plu');
/// final state = ref.watch(skillSuggestControllerProvider);
/// ```
class SkillSuggestController extends Notifier<SkillSuggestState> {
  static const _debounceMs = 300;

  Timer? _debounce;

  @override
  SkillSuggestState build() => const SkillSuggestState();

  /// Called whenever the user types in the skill search field.
  void onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        clearSuggestions: true,
        clearError: true,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(query: query, isLoading: true, clearError: true);

    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _fetchSuggestions(query.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final token = ref.read(authControllerProvider).token ?? '';
      final skillApi = ref.read(skillApiProvider);
      final results = await skillApi.suggestSkills(query, bearerToken: token, limit: 10);

      // Remove already-selected skills from suggestions
      final selectedIds = state.selected.map((s) => s.id).toSet();
      final filtered =
          results.where((s) => !selectedIds.contains(s.id)).toList();

      state = state.copyWith(
        suggestions: filtered,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        clearSuggestions: true,
        errorMessage: error.toString(),
      );
    }
  }

  /// Add a skill to the selected list.
  void selectSkill(SkillItem skill) {
    final alreadySelected =
        state.selected.any((s) => s.id == skill.id);
    if (alreadySelected) return;

    state = state.copyWith(
      selected: [...state.selected, skill],
      // Remove from suggestions
      suggestions:
          state.suggestions.where((s) => s.id != skill.id).toList(),
    );
  }

  /// Remove a skill from the selected list.
  void removeSkill(int skillId) {
    state = state.copyWith(
      selected: state.selected.where((s) => s.id != skillId).toList(),
    );
  }

  /// Clear all selected skills and suggestions (e.g. after form submit).
  void clearAll() {
    _debounce?.cancel();
    state = const SkillSuggestState();
  }

  /// Adds a freeform skill name typed by the user.
  ///
  /// Normalises the name (trim, collapse whitespace, lowercase) to match
  /// backend behaviour.  Duplicates (by normalised name) are silently ignored.
  /// A synthetic negative [id] is assigned — these skills don't exist on the
  /// server yet, so they will be submitted via `requiredSkillNames` and
  /// auto-created by the backend.
  void addCustomSkill(String rawName) {
    final normalised = rawName.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalised.isEmpty) return;

    final alreadySelected = state.selected
        .any((s) => s.skillName.toLowerCase() == normalised);
    if (alreadySelected) return;

    // Use a negative sentinel ID so these can't clash with real API IDs.
    final syntheticId = -(DateTime.now().millisecondsSinceEpoch % 1000000);
    final skill = SkillItem(id: syntheticId, skillName: normalised);
    state = state.copyWith(
      selected: [...state.selected, skill],
      clearSuggestions: true,
      clearError: true,
    );
  }

  /// Convenience: get selected skill names as a plain string list.
  /// Names are already normalised (lowercased) at selection time.
  List<String> get selectedNames =>
      state.selected.map((s) => s.skillName).toList();

  /// Convenience: get selected skill IDs (only meaningful for API-backed skills).
  List<int> get selectedIds => state.selected.map((s) => s.id).toList();
}

final skillSuggestControllerProvider =
    NotifierProvider<SkillSuggestController, SkillSuggestState>(
  SkillSuggestController.new,
);
