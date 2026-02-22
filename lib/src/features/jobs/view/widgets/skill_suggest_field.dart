import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../view_model/skill_suggest_view_model.dart';
import '../../data/skill_api.dart';

/// A reusable text field that queries the skill auto-suggest endpoint and
/// renders a dropdown overlay with results.  Selected skills are shown as
/// removable chips below the field.
///
/// [controllerProvider] must be provided so the parent can access the
/// selected skill names or IDs after the user picks skills.
///
/// Example:
/// ```dart
/// SkillSuggestField(controllerProvider: skillSuggestControllerProvider)
/// ```
class SkillSuggestField extends ConsumerStatefulWidget {
  const SkillSuggestField({
    super.key,
    required this.controllerProvider,
    this.label = 'Required Skills',
    this.hintText = 'e.g. plumbing, painting…',
  });

  final NotifierProvider<SkillSuggestController, SkillSuggestState>
      controllerProvider;
  final String label;
  final String hintText;

  @override
  ConsumerState<SkillSuggestField> createState() => _SkillSuggestFieldState();
}

class _SkillSuggestFieldState extends ConsumerState<SkillSuggestField> {
  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _textCtrl.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  /// Chips any text before a comma; the remainder stays in the field.
  void _onQueryChanged(String query) {
    if (query.contains(',')) {
      final parts = query.split(',');
      // Everything except the last segment is a completed skill.
      for (final part in parts.sublist(0, parts.length - 1)) {
        _addAndClear(part);
      }
      // Leave whatever came after the last comma in the field.
      final remaining = parts.last;
      _textCtrl.value = _textCtrl.value.copyWith(
        text: remaining,
        selection: TextSelection.collapsed(offset: remaining.length),
      );
      ref.read(widget.controllerProvider.notifier).onQueryChanged(remaining);
      return;
    }
    ref.read(widget.controllerProvider.notifier).onQueryChanged(query);
  }

  /// Chips the current field text on Enter / Done.
  void _onSubmitted(String value) => _addAndClear(value);

  void _addAndClear(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) {
      ref.read(widget.controllerProvider.notifier).addCustomSkill(trimmed);
    }
    _textCtrl.clear();
    ref.read(widget.controllerProvider.notifier).onQueryChanged('');
    _removeOverlay();
  }

  void _selectSkill(SkillItem skill) {
    ref.read(widget.controllerProvider.notifier).selectSkill(skill);
    _textCtrl.clear();
    ref.read(widget.controllerProvider.notifier).onQueryChanged('');
    _removeOverlay();
    _focusNode.requestFocus();
  }

  void _removeSkill(int skillId) {
    ref.read(widget.controllerProvider.notifier).removeSkill(skillId);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay(List<SkillItem> items) {
    _removeOverlay();
    if (items.isEmpty) return;

    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: 280,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 12),
                  itemBuilder: (_, index) {
                    final skill = items[index];
                    return ListTile(
                      dense: true,
                      title: Text(skill.skillName),
                      onTap: () => _selectSkill(skill),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.controllerProvider);

    // Reactively manage overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (state.suggestions.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay(state.suggestions);
      } else {
        _removeOverlay();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search input ──
        CompositedTransformTarget(
          link: _layerLink,
          child: TextFormField(
            controller: _textCtrl,
            focusNode: _focusNode,
            onChanged: _onQueryChanged,
            onFieldSubmitted: _onSubmitted,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.handyman_outlined),
              suffixIcon: state.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        // ── Error message ──
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              state.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        // ── Selected chips ──
        if (state.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: state.selected.map((skill) {
                return Chip(
                  label: Text(skill.skillName),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeSkill(skill.id),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            state.selected.isEmpty
                ? 'Type skills and separate them with commas'
                : '${state.selected.length} skill${state.selected.length == 1 ? '' : 's'} added',
            style: TextStyle(
              fontSize: 12,
              color: state.selected.isEmpty
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
