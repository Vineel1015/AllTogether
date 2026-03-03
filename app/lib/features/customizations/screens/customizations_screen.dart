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

/// User preferences setup screen.
///
/// [isOnboarding] = true → shown right after sign-up (no back button).
/// [isOnboarding] = false → shown from settings (editable).
class CustomizationsScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const CustomizationsScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<CustomizationsScreen> createState() =>
      _CustomizationsScreenState();
}

class _CustomizationsScreenState extends ConsumerState<CustomizationsScreen> {
  String _dietType = 'omnivore';
  String _healthGoal = 'maintain';
  String _dietStyle = 'standard';
  List<String> _allergies = [];
  int _householdSize = 1;
  String _budgetRange = r'$50–$100';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate if editing existing preferences.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefsAsync = ref.read(userPreferencesProvider);
      prefsAsync.whenData((prefs) {
        if (prefs != null) _populate(prefs);
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
        // Invalidate so MainAppRouter re-evaluates and routes to AppScaffold.
        ref.invalidate(userPreferencesProvider);
        if (!widget.isOnboarding && mounted) Navigator.of(context).pop();
      case AppFailure(:final code):
        setState(() => _errorMessage = toUserMessage(code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isOnboarding
          ? null
          : AppBar(title: const Text('Your Preferences')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isOnboarding) ...[
                const SizedBox(height: 16),
                Text(
                  'Set up your profile',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll use this to personalise your meal plans.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),
              ],

              // ── Diet Type ──────────────────────────────────────────────
              _sectionLabel(context, 'Diet Type'),
              const SizedBox(height: 8),
              DietTypeSelector(
                selected: _dietType,
                onChanged: (v) => setState(() => _dietType = v),
              ),
              const SizedBox(height: 24),

              // ── Health Goal ────────────────────────────────────────────
              _sectionLabel(context, 'Health Goal'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _healthGoalOptions.map((opt) {
                  return ChoiceChip(
                    label: Text(opt.label),
                    selected: _healthGoal == opt.value,
                    onSelected: (_) => setState(() => _healthGoal = opt.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Diet Style ─────────────────────────────────────────────
              _sectionLabel(context, 'Eating Style'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dietStyleOptions.map((opt) {
                  return ChoiceChip(
                    label: Text(opt.label),
                    selected: _dietStyle == opt.value,
                    onSelected: (_) => setState(() => _dietStyle = opt.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Allergies ──────────────────────────────────────────────
              _sectionLabel(context, 'Allergies & Intolerances'),
              const SizedBox(height: 4),
              Text(
                'Select all that apply',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              AllergySelector(
                selected: _allergies,
                onChanged: (v) => setState(() => _allergies = v),
              ),
              const SizedBox(height: 24),

              // ── Household Size ─────────────────────────────────────────
              _sectionLabel(context, 'Household Size'),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: _householdSize > 1
                        ? () => setState(() => _householdSize--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_householdSize',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: _householdSize < 10
                        ? () => setState(() => _householdSize++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  Text(
                    _householdSize == 1 ? 'person' : 'people',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Weekly Budget ──────────────────────────────────────────
              _sectionLabel(context, 'Weekly Grocery Budget'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _budgetRange,
                items: _budgetOptions
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _budgetRange = v);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 32),

              // ── Error ──────────────────────────────────────────────────
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // ── Save Button ────────────────────────────────────────────
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
