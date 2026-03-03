import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_result.dart';
import '../../../core/utils/string_utils.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../models/user_preferences_model.dart';
import '../providers/preferences_provider.dart';
import '../widgets/allergy_selector.dart';
import '../widgets/diet_type_selector.dart';

// ── Options ────────────────────────────────────────────────────────────────────

const _budgetOptions = [
  r'$0–$50',
  r'$50–$100',
  r'$100–$150',
  r'$150–$200',
  r'$200+',
];

const _healthGoalOptions = [
  (value: 'lose_weight', label: 'Lose Weight'),
  (value: 'gain_weight', label: 'Gain Weight'),
  (value: 'maintain', label: 'Maintain'),
  (value: 'build_muscle', label: 'Build Muscle'),
];

const _dietStyleOptions = [
  (value: 'standard', label: 'Standard'),
  (value: 'keto', label: 'Keto'),
  (value: 'high_protein', label: 'High Protein'),
  (value: 'low_carb', label: 'Low Carb'),
  (value: 'mediterranean', label: 'Mediterranean'),
];

// ── Entry point ────────────────────────────────────────────────────────────────

/// Shows the preferences modal bottom sheet.
///
/// [isOnboarding] = true → non-dismissible, shown after sign-up.
/// [isOnboarding] = false → dismissible, opened from settings.
class CustomizationsScreen extends ConsumerStatefulWidget {
  const CustomizationsScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  ConsumerState<CustomizationsScreen> createState() =>
      _CustomizationsScreenState();
}

class _CustomizationsScreenState extends ConsumerState<CustomizationsScreen> {
  @override
  void initState() {
    super.initState();
    // Show the sheet after the first frame so the route is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: !widget.isOnboarding,
      enableDrag: !widget.isOnboarding,
      backgroundColor: Colors.transparent,
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _PrefsSheet(isOnboarding: widget.isOnboarding),
      ),
    );
    // If dismissed without saving (non-onboarding), pop the route.
    if (!widget.isOnboarding && mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Transparent scaffold — the real UI is in the modal.
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}

// ── Sheet content ──────────────────────────────────────────────────────────────

class _PrefsSheet extends ConsumerStatefulWidget {
  const _PrefsSheet({required this.isOnboarding});
  final bool isOnboarding;

  @override
  ConsumerState<_PrefsSheet> createState() => _PrefsSheetState();
}

class _PrefsSheetState extends ConsumerState<_PrefsSheet> {
  // ── Preference state ────────────────────────────────────────────────────────
  String _dietType = 'omnivore';
  String _healthGoal = 'maintain';
  String _dietStyle = 'standard';
  List<String> _allergies = [];
  int _householdSize = 1;
  String _budgetRange = r'$50–$100';

  // ── UI state ────────────────────────────────────────────────────────────────
  final _expanded = <int>{};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefsAsync = ref.read(userPreferencesProvider);
      prefsAsync.whenData((prefs) {
        if (prefs != null && mounted) _populate(prefs);
      });
    });
  }

  void _populate(UserPreferences prefs) {
    setState(() {
      _dietType = prefs.dietType;
      _healthGoal = prefs.healthGoal;
      _dietStyle = prefs.dietStyle;
      _allergies = List.from(prefs.allergies);
      _householdSize = prefs.householdSize;
      _budgetRange = prefs.budgetRange;
    });
  }

  void _toggle(int index) {
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        _expanded.add(index);
      }
    });
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final prefs = UserPreferences(
      userId: user.id,
      dietType: _dietType,
      healthGoal: _healthGoal,
      dietStyle: _dietStyle,
      allergies: _allergies,
      householdSize: _householdSize,
      budgetRange: _budgetRange,
    );

    final result =
        await ref.read(preferencesServiceProvider).savePreferences(prefs);

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case AppSuccess():
        ref.invalidate(userPreferencesProvider);
        if (mounted) Navigator.of(context).pop();
      case AppFailure(:final code):
        setState(() => _errorMessage = toUserMessage(code));
    }
  }

  // ── Summary helpers ─────────────────────────────────────────────────────────

  String _goalLabel(String value) =>
      _healthGoalOptions
          .firstWhere((o) => o.value == value,
              orElse: () => (value: value, label: value))
          .label;

  String _styleLabel(String value) =>
      _dietStyleOptions
          .firstWhere((o) => o.value == value,
              orElse: () => (value: value, label: value))
          .label;

  String _allergySummary() => _allergies.isEmpty
      ? 'None'
      : _allergies
          .map((a) => a[0].toUpperCase() + a.substring(1))
          .join(', ');

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle + header ────────────────────────────────────────────
              _SheetHeader(
                isOnboarding: widget.isOnboarding,
                textTheme: textTheme,
                onClose: () => Navigator.of(context).pop(),
              ),

              // ── Accordion sections ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _AccordionSection(
                      index: 0,
                      label: 'Diet Type',
                      summary: _dietType[0].toUpperCase() +
                          _dietType.substring(1),
                      isExpanded: _expanded.contains(0),
                      onTap: () => _toggle(0),
                      child: DietTypeSelector(
                        selected: _dietType,
                        onChanged: (v) {
                          setState(() => _dietType = v);
                          _toggle(0);
                        },
                      ),
                    ),
                    _AccordionSection(
                      index: 1,
                      label: 'Health Goal',
                      summary: _goalLabel(_healthGoal),
                      isExpanded: _expanded.contains(1),
                      onTap: () => _toggle(1),
                      child: _ChipGroup(
                        options: _healthGoalOptions,
                        selected: _healthGoal,
                        onChanged: (v) {
                          setState(() => _healthGoal = v);
                          _toggle(1);
                        },
                      ),
                    ),
                    _AccordionSection(
                      index: 2,
                      label: 'Eating Style',
                      summary: _styleLabel(_dietStyle),
                      isExpanded: _expanded.contains(2),
                      onTap: () => _toggle(2),
                      child: _ChipGroup(
                        options: _dietStyleOptions,
                        selected: _dietStyle,
                        onChanged: (v) {
                          setState(() => _dietStyle = v);
                          _toggle(2);
                        },
                      ),
                    ),
                    _AccordionSection(
                      index: 3,
                      label: 'Allergies & Intolerances',
                      summary: _allergySummary(),
                      isExpanded: _expanded.contains(3),
                      onTap: () => _toggle(3),
                      child: AllergySelector(
                        selected: _allergies,
                        onChanged: (v) => setState(() => _allergies = v),
                      ),
                    ),
                    _AccordionSection(
                      index: 4,
                      label: 'Household Size',
                      summary: '$_householdSize '
                          '${_householdSize == 1 ? 'person' : 'people'}',
                      isExpanded: _expanded.contains(4),
                      onTap: () => _toggle(4),
                      child: _HouseholdCounter(
                        value: _householdSize,
                        onChanged: (v) => setState(() => _householdSize = v),
                      ),
                    ),
                    _AccordionSection(
                      index: 5,
                      label: 'Weekly Grocery Budget',
                      summary: _budgetRange,
                      isExpanded: _expanded.contains(5),
                      onTap: () => _toggle(5),
                      child: _BudgetPicker(
                        selected: _budgetRange,
                        onChanged: (v) {
                          setState(() => _budgetRange = v);
                          _toggle(5);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // ── Error + save button ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                              color: scheme.error, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    _isLoading
                        ? const LoadingIndicator()
                        : FilledButton(
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(0),
                            ),
                            child: Text(
                              widget.isOnboarding ? 'Get Started' : 'Save',
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sheet header ───────────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.isOnboarding,
    required this.textTheme,
    required this.onClose,
  });

  final bool isOnboarding;
  final TextTheme textTheme;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnboarding ? 'Set up your profile' : 'Your Preferences',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isOnboarding) ...[
                      const SizedBox(height: 2),
                      Text(
                        'We\'ll use this to personalise your meal plans.',
                        style: textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isOnboarding)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }
}

// ── Accordion section ──────────────────────────────────────────────────────────

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.index,
    required this.label,
    required this.summary,
    required this.isExpanded,
    required this.onTap,
    required this.child,
  });

  final int index;
  final String label;
  final String summary;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!isExpanded)
                  Text(
                    summary,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: child,
                )
              : const SizedBox.shrink(),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// ── Small reusable sub-widgets ─────────────────────────────────────────────────

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<({String value, String label})> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((opt) {
          return ChoiceChip(
            label: Text(opt.label),
            selected: selected == opt.value,
            onSelected: (_) => onChanged(opt.value),
          );
        }).toList(),
      ),
    );
  }
}

class _HouseholdCounter extends StatelessWidget {
  const _HouseholdCounter({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value', style: Theme.of(context).textTheme.titleLarge),
        IconButton(
          onPressed: value < 10 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
        Text(
          value == 1 ? 'person' : 'people',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _BudgetPicker extends StatelessWidget {
  const _BudgetPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _budgetOptions.map((b) {
          return ChoiceChip(
            label: Text(b),
            selected: selected == b,
            onSelected: (_) => onChanged(b),
          );
        }).toList(),
      ),
    );
  }
}
