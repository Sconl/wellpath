// lib/interface/admin/q_admin_form.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// QAdmin Form Controls
// ─────────────────────────────────────────────────────────────────────────────
// Reusable admin UI primitives used across all screen_admin_* screens.
//
// ATOMS
//   AdminTextField        — single-line text input wired to a manifest path
//   AdminTextArea         — multi-line text input
//   AdminToggle           — labelled boolean switch
//   AdminColorPicker      — hex color well + text field
//   AdminListEditor       — add / edit / remove items in a string list
//   AdminSectionCard      — labelled collapsible section container
//   AdminFieldLabel       — small label + optional manifest path hint
//   AdminDivider          — section separator
//   AdminEmptyState       — empty-state placeholder for lists
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../core/style/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminTextField
// ─────────────────────────────────────────────────────────────────────────────

class AdminTextField extends StatefulWidget {
  final String label;
  final String? hint;
  /// Manifest path shown in muted caption, e.g. section_core.hero.badge
  final String? manifestPath;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int? maxLines;
  final bool readOnly;

  const AdminTextField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.manifestPath,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  State<AdminTextField> createState() => _AdminTextFieldState();
}

class _AdminTextFieldState extends State<AdminTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(AdminTextField old) {
    super.didUpdateWidget(old);
    if (old.initialValue != widget.initialValue &&
        _ctrl.text != widget.initialValue) {
      _ctrl.text = widget.initialValue;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminFieldLabel(label: widget.label, manifestPath: widget.manifestPath),
      SizedBox(height: AppSpacing.xs),
      TextField(
        controller: _ctrl,
        readOnly:   widget.readOnly,
        maxLines:   widget.maxLines,
        style:      AppTypography.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText:        widget.hint,
          filled:          true,
          fillColor:       AppColors.surfaceMid,
          contentPadding:  EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          border: OutlineInputBorder(
            borderRadius: AppRadius.inputBR,
            borderSide:   BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.inputBR,
            borderSide:   BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.inputBR,
            borderSide:   BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminTextArea — same as AdminTextField but defaults to 4 lines
// ─────────────────────────────────────────────────────────────────────────────

class AdminTextArea extends AdminTextField {
  const AdminTextArea({
    super.key,
    required super.label,
    required super.initialValue,
    required super.onChanged,
    super.hint,
    super.manifestPath,
    super.readOnly,
    int lines = 4,
  }) : super(maxLines: lines);
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminToggle
// ─────────────────────────────────────────────────────────────────────────────

class AdminToggle extends StatelessWidget {
  final String label;
  final String? description;
  final String? manifestPath;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.manifestPath,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFieldLabel(label: label, manifestPath: manifestPath),
          if (description != null) ...[
            SizedBox(height: 2),
            Text(description!,
                style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ],
      )),
      Switch(
        value:           value,
        onChanged:       onChanged,
        activeColor:     AppColors.primary,
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.tint20(AppColors.primary)
                : AppColors.surfaceMid),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminColorPicker — color well + hex input
// ─────────────────────────────────────────────────────────────────────────────

class AdminColorPicker extends StatefulWidget {
  final String label;
  final String? manifestPath;
  final String hexValue;       // e.g. "#00CC66"
  final ValueChanged<String> onChanged;

  const AdminColorPicker({
    super.key,
    required this.label,
    required this.hexValue,
    required this.onChanged,
    this.manifestPath,
  });

  @override
  State<AdminColorPicker> createState() => _AdminColorPickerState();
}

class _AdminColorPickerState extends State<AdminColorPicker> {
  late final TextEditingController _ctrl;

  Color _parse(String hex) {
    final h = hex.replaceAll('#', '').padLeft(8, 'FF');
    try { return Color(int.parse(h, radix: 16)); } catch (_) { return Colors.transparent; }
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.hexValue);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = _parse(widget.hexValue);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminFieldLabel(label: widget.label, manifestPath: widget.manifestPath),
      SizedBox(height: AppSpacing.xs),
      Row(children: [
        // Color swatch
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: AppRadius.inputBR,
            border:       Border.all(color: AppColors.borderStrong),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        // Hex input
        Expanded(
          child: TextField(
            controller: _ctrl,
            style:      AppTypography.body.copyWith(fontSize: 13),
            decoration: InputDecoration(
              hintText:       '#RRGGBB',
              filled:         true,
              fillColor:      AppColors.surfaceMid,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              border: OutlineInputBorder(
                borderRadius: AppRadius.inputBR,
                borderSide:   BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.inputBR,
                borderSide:   BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.inputBR,
                borderSide:   BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (v) {
              setState(() {});
              widget.onChanged(v);
            },
          ),
        ),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminListEditor — editable string list with add / remove
// ─────────────────────────────────────────────────────────────────────────────

class AdminListEditor extends StatelessWidget {
  final String label;
  final String? manifestPath;
  final List<String> items;
  final String addLabel;
  final void Function(int index, String value) onItemChanged;
  final void Function(int index) onRemove;
  final VoidCallback onAdd;

  const AdminListEditor({
    super.key,
    required this.label,
    required this.items,
    required this.onItemChanged,
    required this.onRemove,
    required this.onAdd,
    this.manifestPath,
    this.addLabel = '+ Add item',
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminFieldLabel(label: label, manifestPath: manifestPath),
      SizedBox(height: AppSpacing.xs),
      ...items.asMap().entries.map((entry) => Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(children: [
          Expanded(
            child: _ListItemField(
              value:     entry.value,
              onChanged: (v) => onItemChanged(entry.key, v),
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: () => onRemove(entry.key),
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color:        AppColors.tint10(AppColors.error),
                borderRadius: AppRadius.inputBR,
                border:       Border.all(color: AppColors.tint20(AppColors.error)),
              ),
              child: Icon(Icons.remove_rounded, size: 14, color: AppColors.error),
            ),
          ),
        ]),
      )),
      SizedBox(height: AppSpacing.xs),
      GestureDetector(
        onTap: onAdd,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color:        AppColors.tint10(AppColors.primary),
            borderRadius: AppRadius.inputBR,
            border:       Border.all(color: AppColors.tint20(AppColors.primary)),
          ),
          child: Center(child: Text(addLabel,
            style: AppTypography.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600))),
        ),
      ),
    ]);
  }
}

class _ListItemField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _ListItemField({required this.value, required this.onChanged});

  @override
  State<_ListItemField> createState() => _ListItemFieldState();
}

class _ListItemFieldState extends State<_ListItemField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_ListItemField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      style:      AppTypography.body.copyWith(fontSize: 12),
      decoration: InputDecoration(
        filled:         true, fillColor: AppColors.surfaceMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputBR,
          borderSide:   BorderSide(color: AppColors.primary, width: 1.5)),
      ),
      onChanged: widget.onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminSectionCard — collapsible container for a group of fields
// ─────────────────────────────────────────────────────────────────────────────

class AdminSectionCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final IconData? icon;

  const AdminSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = true,
    this.icon,
  });

  @override
  State<AdminSectionCard> createState() => _AdminSectionCardState();
}

class _AdminSectionCardState extends State<AdminSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        // Header
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color:        _expanded ? AppColors.surfaceMid : AppColors.surface,
              borderRadius: _expanded
                  ? BorderRadius.only(
                      topLeft:  Radius.circular(AppRadius.card),
                      topRight: Radius.circular(AppRadius.card))
                  : AppRadius.cardBR,
            ),
            child: Row(children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 15, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
              ],
              Text(widget.title,
                  style: AppTypography.h5.copyWith(fontSize: 13)),
              if (widget.subtitle != null) ...[
                SizedBox(width: AppSpacing.xs),
                Text(widget.subtitle!,
                    style: AppTypography.caption.copyWith(fontSize: 10)),
              ],
              const Spacer(),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textMuted,
              ),
            ]),
          ),
        ),
        // Body
        AnimatedSize(
          duration: AppDurations.normal, curve: Curves.easeInOut,
          child: _expanded
              ? Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: widget.child)
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminFieldLabel
// ─────────────────────────────────────────────────────────────────────────────

class AdminFieldLabel extends StatelessWidget {
  final String label;
  final String? manifestPath;

  const AdminFieldLabel({super.key, required this.label, this.manifestPath});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
      Text(label, style: AppTypography.h5.copyWith(fontSize: 12)),
      if (manifestPath != null) ...[
        SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(manifestPath!,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(fontSize: 9,
                color: AppColors.textMuted.withAlpha(120))),
        ),
      ],
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminDivider
// ─────────────────────────────────────────────────────────────────────────────

class AdminDivider extends StatelessWidget {
  final String? label;
  const AdminDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Container(height: 1, color: AppColors.border),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Container(height: 1, width: 16, color: AppColors.border),
        SizedBox(width: AppSpacing.xs),
        Text(label!.toUpperCase(),
            style: AppTypography.overline.copyWith(fontSize: 9)),
        SizedBox(width: AppSpacing.xs),
        Expanded(child: Container(height: 1, color: AppColors.border)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminEmptyState
// ─────────────────────────────────────────────────────────────────────────────

class AdminEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const AdminEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 32, color: AppColors.textMuted),
      SizedBox(height: AppSpacing.sm),
      Text(message, style: AppTypography.bodySmall),
    ]));
  }
}