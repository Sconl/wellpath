// lib/spaces/space_admin/screens/screen_admin_trainers.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// ScreenAdminTrainers — Admin Trainer Management
// ─────────────────────────────────────────────────────────────────────────────
//
// CHANGELOG
//   v1.0.0 — Initial. Live Firestore CRUD for the `trainers` collection.
//            Split-pane layout: trainer list on the left, add/edit form on
//            the right. Firestore writes use the exact document shape that
//            SeedService and TrainerProfile.fromFirestore() expect, so no
//            migration is required.
//
// WIRING REQUIRED (in your router file):
//   Add this route nested under the QAdminShell ShellRoute:
//     GoRoute(
//       path: '/admin/trainers',
//       builder: (_, __) => const ScreenAdminTrainers(),
//     ),
//
// COLLECTION
//   Uses _kTrainersCollection = 'trainers'.
//   Matches trainer_model.dart kTrainersCollection — using local const here
//   to avoid circular import until trainer_model.dart is confirmed in scope.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/style/app_theme.dart';
import '../../../core/style/app_decorations.dart';
import '../q_admin_form.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIG
// ─────────────────────────────────────────────────────────────────────────────

// Matches trainer_model.dart kTrainersCollection — sync if that const changes.
const String _kTrainersCollection = 'trainers';

// Width of the trainer list column when the form panel is open.
const double _kListPanelWidth = 300.0;

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Streams ALL trainer documents ordered alphabetically.
/// Admin needs the full roster — kMaxFeaturedTrainers limit is NOT applied here.
final _allTrainersProvider =
    StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return FirebaseFirestore.instance
      .collection(_kTrainersCollection)
      .orderBy('displayName')
      .snapshots()
      .map((s) => s.docs);
});

// ─────────────────────────────────────────────────────────────────────────────
// ScreenAdminTrainers
// ─────────────────────────────────────────────────────────────────────────────

enum _PanelMode { none, add, edit }

class ScreenAdminTrainers extends ConsumerStatefulWidget {
  const ScreenAdminTrainers({super.key});

  @override
  ConsumerState<ScreenAdminTrainers> createState() =>
      _ScreenAdminTrainersState();
}

class _ScreenAdminTrainersState extends ConsumerState<ScreenAdminTrainers> {
  _PanelMode            _mode        = _PanelMode.none;
  String?               _editingId;
  Map<String, dynamic>? _editingData;

  void _openAdd() => setState(() {
        _mode        = _PanelMode.add;
        _editingId   = null;
        _editingData = null;
      });

  void _openEdit(String id, Map<String, dynamic> data) =>
      setState(() {
        _mode        = _PanelMode.edit;
        _editingId   = id;
        _editingData = data;
      });

  void _closePanel() => setState(() {
        _mode        = _PanelMode.none;
        _editingId   = null;
        _editingData = null;
      });

  @override
  Widget build(BuildContext context) {
    final trainersAsync = ref.watch(_allTrainersProvider);
    final showForm      = _mode != _PanelMode.none;

    return Column(children: [

      // ── Header ──────────────────────────────────────────────────────────
      _TrainersHeader(onAdd: _openAdd),

      // ── Body: list + optional form panel ────────────────────────────────
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Trainer list — expands to fill when form is closed,
            // collapses to fixed width when form is open.
            if (showForm)
              SizedBox(
                width: _kListPanelWidth,
                child: _TrainerListPanel(
                  trainersAsync:  trainersAsync,
                  selectedId:     _editingId,
                  onSelect:       _openEdit,
                  onAdd:          _openAdd,
                  showInlineAdd:  false,
                ),
              )
            else
              Expanded(
                child: _TrainerListPanel(
                  trainersAsync: trainersAsync,
                  selectedId:    _editingId,
                  onSelect:      _openEdit,
                  onAdd:         _openAdd,
                  showInlineAdd: true,
                ),
              ),

            // Vertical divider
            if (showForm)
              Container(width: 1, color: AppColors.border),

            // Form panel — fills remaining space
            if (showForm)
              Expanded(
                child: _TrainerFormPanel(
                  // Key on the editing ID so controllers re-init on trainer switch
                  key:      ValueKey(_editingId ?? '__new__'),
                  mode:     _mode,
                  docId:    _editingId,
                  initial:  _editingData,
                  onClose:  _closePanel,
                  onSaved:  _closePanel,
                  onDeleted: _closePanel,
                ),
              ),

          ],
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainersHeader
// ─────────────────────────────────────────────────────────────────────────────

class _TrainersHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const _TrainersHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color:  AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Icon(Icons.fitness_center_outlined, size: 17, color: AppColors.primary),
        SizedBox(width: AppSpacing.sm),
        Text('Trainer Management',
            style: AppTypography.h4.copyWith(fontSize: 15)),
        SizedBox(width: AppSpacing.xs),
        Text('· Live Firestore',
            style: AppTypography.caption.copyWith(
                color: AppColors.textMuted, fontSize: 10)),
        const Spacer(),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
            decoration: BoxDecoration(
              gradient:     AppGradients.button,
              borderRadius: AppRadius.pillBR,
              boxShadow:    AppShadows.buttonGlow,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add_rounded,
                  size: 14, color: AppColors.textPrimary),
              SizedBox(width: 4),
              Text('Add Trainer',
                  style: AppTypography.button.copyWith(fontSize: 12)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerListPanel
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerListPanel extends StatelessWidget {
  final AsyncValue<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      trainersAsync;
  final String?  selectedId;
  final void Function(String id, Map<String, dynamic> data) onSelect;
  final VoidCallback onAdd;
  final bool showInlineAdd;

  const _TrainerListPanel({
    required this.trainersAsync,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
    required this.showInlineAdd,
  });

  @override
  Widget build(BuildContext context) {
    return trainersAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text('Could not load trainers: $e',
              style: AppTypography.bodySmall),
        ),
      ),
      data: (docs) {
        if (docs.isEmpty && !showInlineAdd) {
          // Narrow list with no trainers — just show a prompt
          return Center(
            child: Text('No trainers',
                style: AppTypography.bodySmall),
          );
        }
        if (docs.isEmpty) {
          return _EmptyTrainerState(onAdd: onAdd);
        }

        final itemCount = docs.length + (showInlineAdd ? 1 : 0);
        return ListView.separated(
          padding: EdgeInsets.all(AppSpacing.md),
          itemCount: itemCount,
          separatorBuilder: (_, __) =>
              SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, i) {
            // First slot is the inline "Add" button when not in form mode
            if (showInlineAdd && i == 0) {
              return _AddTrainerTile(onTap: onAdd);
            }
            final doc  = docs[showInlineAdd ? i - 1 : i];
            final data = doc.data();
            return _TrainerTile(
              docId:      doc.id,
              data:       data,
              isSelected: doc.id == selectedId,
              onTap:      () => onSelect(doc.id, data),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerTile
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerTile extends StatefulWidget {
  final String             docId;
  final Map<String, dynamic> data;
  final bool               isSelected;
  final VoidCallback       onTap;

  const _TrainerTile({
    required this.docId,
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TrainerTile> createState() => _TrainerTileState();
}

class _TrainerTileState extends State<_TrainerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final name       = widget.data['displayName'] as String? ?? 'Unnamed';
    final location   = widget.data['locationName'] as String? ?? '';
    final verified   = widget.data['isVerified']  as bool?   ?? false;
    final rating     = (widget.data['rating']      as num?)?.toDouble() ?? 0.0;
    final yoe        = widget.data['yearsExperience'] as int? ?? 0;
    final specialties =
        List<String>.from(widget.data['specialties'] as List? ?? []);

    final bg = widget.isSelected
        ? AppColors.primary.withValues(alpha: 0.12)
        : _hovered
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surface;

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color:        bg,
            borderRadius: AppRadius.cardBR,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : AppColors.border,
            ),
          ),
          child: Row(children: [
            // Initials avatar
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color:  AppColors.tint20(AppColors.primary),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.h5.copyWith(
                      color: AppColors.primary, fontSize: 16),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),

            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(name,
                          style: AppTypography.h5.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (verified) ...[
                      SizedBox(width: 3),
                      Icon(Icons.verified_rounded,
                          size: 11, color: AppColors.primary),
                    ],
                  ]),
                  if (location.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(location,
                        style: AppTypography.caption.copyWith(
                            fontSize: 10),
                        overflow: TextOverflow.ellipsis),
                  ],
                  if (specialties.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      specialties.take(2).join(' · '),
                      style: AppTypography.caption.copyWith(
                          fontSize: 9, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Right column: rating + years
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.star_rounded,
                      size: 10, color: AppColors.tertiary),
                  SizedBox(width: 2),
                  Text(rating.toStringAsFixed(1),
                      style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
                SizedBox(height: 2),
                Text('${yoe}yr${yoe == 1 ? '' : 's'}',
                    style: AppTypography.caption.copyWith(
                        fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddTrainerTile — inline shortcut in the full-width list view
// ─────────────────────────────────────────────────────────────────────────────

class _AddTrainerTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTrainerTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color:        AppColors.tint10(AppColors.primary),
          borderRadius: AppRadius.cardBR,
          border:       Border.all(
              color: AppColors.tint20(AppColors.primary)),
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 14, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Add new trainer',
                style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyTrainerState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyTrainerState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTrainerState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.fitness_center_outlined,
            size: 44, color: AppColors.textMuted),
        SizedBox(height: AppSpacing.md),
        Text('No trainers yet',
            style: AppTypography.h4.copyWith(fontSize: 17)),
        SizedBox(height: AppSpacing.xs),
        Text('Add your first trainer to start taking bookings.',
            style: AppTypography.bodySmall),
        SizedBox(height: AppSpacing.xl),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              gradient:     AppGradients.button,
              borderRadius: AppRadius.pillBR,
              boxShadow:    AppShadows.buttonGlow,
            ),
            child: Text('Add Trainer',
                style: AppTypography.button.copyWith(fontSize: 13)),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrainerFormPanel — full add / edit form
// ─────────────────────────────────────────────────────────────────────────────

class _TrainerFormPanel extends StatefulWidget {
  final _PanelMode            mode;
  final String?               docId;
  final Map<String, dynamic>? initial;
  final VoidCallback          onClose;
  final VoidCallback          onSaved;
  final VoidCallback          onDeleted;

  const _TrainerFormPanel({
    super.key,
    required this.mode,
    required this.docId,
    required this.initial,
    required this.onClose,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<_TrainerFormPanel> createState() => _TrainerFormPanelState();
}

class _TrainerFormPanelState extends State<_TrainerFormPanel> {

  // ── Mutable form state ────────────────────────────────────────────────────
  // Strings for text fields (parsed on save), bools for toggles,
  // lists for AdminListEditor. All initialised from widget.initial in initState.

  late String       _displayName;
  late String       _bio;
  late String       _locationName;
  late List<String> _specialties;
  late List<String> _certifications;
  late String       _priceKes;        // empty → null (Contact trainer)
  late String       _lat;
  late String       _lng;
  late String       _yearsExperience;
  late String       _rating;          // only editable on edit mode
  late String       _reviewCount;     // only editable on edit mode
  late bool         _isVerified;

  bool    _saving   = false;
  bool    _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.initial ?? const {};
    _displayName     = d['displayName']     as String? ?? '';
    _bio             = d['bio']             as String? ?? '';
    _locationName    = d['locationName']    as String? ?? '';
    _specialties     = List<String>.from(d['specialties']    as List? ?? []);
    _certifications  = List<String>.from(d['certifications'] as List? ?? []);
    _priceKes        = (d['priceKes']        as num?)?.toString() ?? '';
    _lat             = (d['lat']             as num?)?.toString() ?? '';
    _lng             = (d['lng']             as num?)?.toString() ?? '';
    _yearsExperience = (d['yearsExperience'] as int?)?.toString() ?? '';
    _rating          = (d['rating']          as num?)?.toString() ?? '0.0';
    _reviewCount     = (d['reviewCount']     as int?)?.toString() ?? '0';
    _isVerified      = d['isVerified']       as bool? ?? true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────

  String? _validate() {
    if (_displayName.trim().isEmpty) return 'Display name is required.';
    if (_bio.trim().isEmpty)          return 'Bio is required.';
    if (_locationName.trim().isEmpty) return 'Location name is required.';
    if (_yearsExperience.isNotEmpty &&
        int.tryParse(_yearsExperience) == null) {
      return 'Years of experience must be a whole number (e.g. 7).';
    }
    if (_lat.isNotEmpty && double.tryParse(_lat) == null) {
      return 'Latitude must be a decimal number (e.g. −4.0570).';
    }
    if (_lng.isNotEmpty && double.tryParse(_lng) == null) {
      return 'Longitude must be a decimal number (e.g. 39.6644).';
    }
    if (_priceKes.isNotEmpty && double.tryParse(_priceKes) == null) {
      return 'Price must be a number (e.g. 2500). Leave blank for "Contact trainer".';
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Save — direct Firestore write
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    setState(() { _saving = true; _error = null; });

    try {
      final coll = FirebaseFirestore.instance.collection(_kTrainersCollection);

      // Build the canonical payload — mirrors SeedService's write shape exactly
      // so TrainerProfile.fromFirestore() (trainer_model.dart) reads it cleanly.
      final payload = <String, dynamic>{
        'displayName':    _displayName.trim(),
        'bio':            _bio.trim(),
        'locationName':   _locationName.trim(),
        'specialties':    _specialties
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'certifications': _certifications
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'priceKes':       _priceKes.trim().isNotEmpty
            ? double.tryParse(_priceKes.trim())
            : null,
        'lat':            _lat.trim().isNotEmpty
            ? double.tryParse(_lat.trim())
            : null,
        'lng':            _lng.trim().isNotEmpty
            ? double.tryParse(_lng.trim())
            : null,
        'yearsExperience': _yearsExperience.trim().isNotEmpty
            ? (int.tryParse(_yearsExperience.trim()) ?? 0)
            : 0,
        'rating':         double.tryParse(_rating.trim())   ?? 0.0,
        'reviewCount':    int.tryParse(_reviewCount.trim()) ?? 0,
        'isVerified':     _isVerified,
        'role':           'trainer',
        // Preserve existing photoUrl — not editable in this UI yet.
        'photoUrl':       widget.initial?['photoUrl'],
      };

      if (widget.mode == _PanelMode.add) {
        // Auto-ID for admin-created trainers. Safer than slugs because
        // trainer names can change — auto-IDs never collide or go stale.
        await coll.add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // merge: true preserves fields this form doesn't touch (e.g. FCM
        // tokens, any future fields added by the trainer app directly).
        await coll.doc(widget.docId).set({
          ...payload,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (mounted) widget.onSaved();
    } on FirebaseException catch (e) {
      setState(() => _error = 'Firebase error: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delete — hard delete after confirmation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        name: _displayName.trim().isEmpty
            ? 'this trainer'
            : _displayName.trim(),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _deleting = true; _error = null; });
    try {
      await FirebaseFirestore.instance
          .collection(_kTrainersCollection)
          .doc(widget.docId)
          .delete();
      if (mounted) widget.onDeleted();
    } on FirebaseException catch (e) {
      setState(() => _error = 'Delete failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == _PanelMode.edit;

    return Column(children: [

      // ── Form header ────────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color:  AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Icon(
            isEdit
                ? Icons.edit_outlined
                : Icons.person_add_outlined,
            size: 15, color: AppColors.primary,
          ),
          SizedBox(width: AppSpacing.xs),
          Text(isEdit ? 'Edit Trainer' : 'Add Trainer',
              style: AppTypography.h5.copyWith(fontSize: 13)),
          if (isEdit && _displayName.trim().isNotEmpty) ...[
            SizedBox(width: AppSpacing.xs),
            Text('· ${_displayName.trim()}',
                style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
          const Spacer(),
          // Close button
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color:        AppColors.surfaceMid,
                borderRadius: AppRadius.cardBR,
                border:       Border.all(color: AppColors.border),
              ),
              child: Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textMuted),
            ),
          ),
        ]),
      ),

      // ── Scrollable form body ───────────────────────────────────────────
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Error banner
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                SizedBox(height: AppSpacing.md),
              ],

              // ── Identity ──────────────────────────────────────────────
              AdminSectionCard(
                title: 'Identity',
                icon:  Icons.person_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminTextField(
                      label:        'Display Name',
                      manifestPath: 'trainers.displayName',
                      initialValue: _displayName,
                      hint:         'e.g. Amira Hassan',
                      onChanged:    (v) => _displayName = v,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AdminTextArea(
                      label:        'Bio',
                      manifestPath: 'trainers.bio',
                      initialValue: _bio,
                      hint:         "Trainer's background, style, and approach…",
                      lines:        5,
                      onChanged:    (v) => _bio = v,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AdminTextField(
                      label:        'Location Name',
                      manifestPath: 'trainers.locationName',
                      initialValue: _locationName,
                      hint:         'e.g. Mombasa Sports Club',
                      onChanged:    (v) => _locationName = v,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: AdminTextField(
                          label:        'Years Experience',
                          manifestPath: 'trainers.yearsExperience',
                          initialValue: _yearsExperience,
                          hint:         'e.g. 7',
                          onChanged:    (v) => _yearsExperience = v,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AdminTextField(
                          label:        'Price (KES)',
                          manifestPath: 'trainers.priceKes',
                          initialValue: _priceKes,
                          hint:         'e.g. 2500  (blank = Contact trainer)',
                          onChanged:    (v) => _priceKes = v,
                        ),
                      ),
                    ]),
                    SizedBox(height: AppSpacing.md),
                    AdminToggle(
                      label:       'Verified Trainer',
                      description: 'Shows verified badge on the trainer card.',
                      value:       _isVerified,
                      onChanged:   (v) => setState(() => _isVerified = v),
                    ),
                  ],
                ),
              ),

              // ── Expertise ─────────────────────────────────────────────
              AdminSectionCard(
                title: 'Expertise',
                icon:  Icons.local_fire_department_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminListEditor(
                      label:        'Specialties',
                      manifestPath: 'trainers.specialties',
                      items:        _specialties,
                      addLabel:     '+ Add specialty',
                      onItemChanged: (i, v) =>
                          setState(() => _specialties[i] = v),
                      onRemove: (i) =>
                          setState(() => _specialties.removeAt(i)),
                      onAdd: () =>
                          setState(() => _specialties.add('')),
                    ),
                    SizedBox(height: AppSpacing.md),
                    AdminListEditor(
                      label:        'Certifications',
                      manifestPath: 'trainers.certifications',
                      items:        _certifications,
                      addLabel:     '+ Add certification',
                      onItemChanged: (i, v) =>
                          setState(() => _certifications[i] = v),
                      onRemove: (i) =>
                          setState(() => _certifications.removeAt(i)),
                      onAdd: () =>
                          setState(() => _certifications.add('')),
                    ),
                  ],
                ),
              ),

              // ── Map Coordinates ───────────────────────────────────────
              AdminSectionCard(
                title:             'Map Coordinates',
                icon:              Icons.location_on_outlined,
                initiallyExpanded: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color:        AppColors.tint10(AppColors.secondary),
                        borderRadius: AppRadius.cardBR,
                        border:       Border.all(
                            color: AppColors.tint20(AppColors.secondary)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 12, color: AppColors.secondary),
                          SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Pins this trainer on the Discovery map. '
                              'Open Google Maps, right-click the exact location, '
                              'and copy the coordinates shown at the top of the menu.',
                              style: AppTypography.caption.copyWith(
                                  fontSize: 10, height: 1.6,
                                  color: AppColors.secondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Row(children: [
                      Expanded(
                        child: AdminTextField(
                          label:        'Latitude',
                          manifestPath: 'trainers.lat',
                          initialValue: _lat,
                          hint:         '−4.0570',
                          onChanged:    (v) => _lat = v,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AdminTextField(
                          label:        'Longitude',
                          manifestPath: 'trainers.lng',
                          initialValue: _lng,
                          hint:         '39.6644',
                          onChanged:    (v) => _lng = v,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),

              // ── Social Proof — edit mode only ─────────────────────────
              // Hidden on add: new trainers start at 0 / 0 by default.
              // The toggle is shown (with a warning note) so the admin can
              // seed realistic numbers without running SeedService again.
              if (isEdit)
                AdminSectionCard(
                  title:             'Social Proof',
                  icon:              Icons.star_outline_rounded,
                  subtitle:          '(edit with care)',
                  initiallyExpanded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color:        AppColors.tint10(AppColors.warning),
                          borderRadius: AppRadius.cardBR,
                          border:       Border.all(
                              color: AppColors.tint20(AppColors.warning)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 12, color: AppColors.warning),
                            SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Rating and review count are displayed directly '
                                'on trainer cards and affect user trust. '
                                'Only update these to reflect verified data.',
                                style: AppTypography.caption.copyWith(
                                    fontSize: 10, height: 1.6,
                                    color: AppColors.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(children: [
                        Expanded(
                          child: AdminTextField(
                            label:        'Rating',
                            manifestPath: 'trainers.rating',
                            initialValue: _rating,
                            hint:         '0.0 – 5.0',
                            onChanged:    (v) => _rating = v,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AdminTextField(
                            label:        'Review Count',
                            manifestPath: 'trainers.reviewCount',
                            initialValue: _reviewCount,
                            hint:         '0',
                            onChanged:    (v) => _reviewCount = v,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

              // Bottom padding so the last card isn't flush with the footer
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),

      // ── Footer actions ─────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color:  AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [

          // Delete — edit mode only
          if (isEdit) ...[
            GestureDetector(
              onTap: (_deleting || _saving) ? null : _confirmDelete,
              child: AnimatedOpacity(
                opacity: (_deleting || _saving) ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color:        AppColors.tint10(AppColors.error),
                    borderRadius: AppRadius.pillBR,
                    border:       Border.all(
                        color: AppColors.tint20(AppColors.error)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (_deleting)
                      SizedBox(
                        width: 10, height: 10,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppColors.error),
                      )
                    else
                      Icon(Icons.delete_outline_rounded,
                          size: 13, color: AppColors.error),
                    SizedBox(width: 4),
                    Text(_deleting ? 'Deleting…' : 'Delete',
                        style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Cancel
          GestureDetector(
            onTap: (_saving || _deleting) ? null : widget.onClose,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color:        AppColors.surfaceMid,
                borderRadius: AppRadius.pillBR,
                border:       Border.all(color: AppColors.border),
              ),
              child: Text('Cancel',
                  style: AppTypography.caption.copyWith(fontSize: 12)),
            ),
          ),
          SizedBox(width: AppSpacing.sm),

          // Save / Add
          GestureDetector(
            onTap: (_saving || _deleting) ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                gradient:     (_saving || _deleting) ? null : AppGradients.button,
                color:        (_saving || _deleting) ? AppColors.surfaceMid : null,
                borderRadius: AppRadius.pillBR,
                boxShadow:    (_saving || _deleting) ? null : AppShadows.buttonGlow,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (_saving)
                  SizedBox(
                    width: 11, height: 11,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: AppColors.textPrimary),
                  )
                else
                  Icon(Icons.cloud_upload_outlined,
                      size: 13, color: AppColors.textPrimary),
                SizedBox(width: 4),
                Text(
                  _saving
                      ? 'Saving…'
                      : isEdit ? 'Save Changes' : 'Add to Firestore',
                  style: AppTypography.button.copyWith(fontSize: 12),
                ),
              ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DeleteConfirmDialog
// ─────────────────────────────────────────────────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final String name;
  const _DeleteConfirmDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBR),
      title: Text('Delete $name?',
          style: AppTypography.h4.copyWith(fontSize: 15)),
      content: Text(
        'This permanently removes the trainer profile from Firestore. '
        'Existing bookings that reference this trainer are not deleted — '
        'they will still appear in booking history, but the trainer '
        'card will no longer show in Discovery.',
        style: AppTypography.bodySmall.copyWith(height: 1.65),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel',
              style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete',
              style: AppTypography.caption.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBanner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color:        AppColors.tint10(AppColors.error),
        borderRadius: AppRadius.cardBR,
        border:       Border.all(color: AppColors.tint20(AppColors.error)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded,
            size: 14, color: AppColors.error),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(message,
              style: AppTypography.caption.copyWith(
                  color: AppColors.error, fontSize: 11)),
        ),
      ]),
    );
  }
}