import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../finder/models/meal_model.dart';
import '../../finder/models/preset_meals.dart';
import '../../finder/providers/meal_catalog_provider.dart';
import '../../finder/providers/weekly_plan_provider.dart';
import '../widgets/discovery_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  int _currentIndex = 0;

  void _nextMeal(List<Meal> meals, bool accepted) async {
    if (accepted) {
      final meal = meals[_currentIndex];
      await ref.read(weeklyPlanNotifierProvider.notifier).addMeal(meal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${meal.name} to your plan!'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }

    setState(() {
      _currentIndex = (_currentIndex + 1) % (meals.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userMealsAsync = ref.watch(userMealsProvider);
    
    return userMealsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (userMeals) {
        final allMeals = [...presetMeals, ...userMeals];
        if (allMeals.isEmpty) {
          return const Center(child: Text('No meals found to discover!'));
        }

        // Ensure current index is within bounds if list changed
        if (_currentIndex >= allMeals.length) {
          _currentIndex = 0;
        }

        final currentMeal = allMeals[_currentIndex];
        final isWeb = Theme.of(context).platform != TargetPlatform.android && 
                     Theme.of(context).platform != TargetPlatform.iOS;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Discover Your Next Meal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      DiscoveryCard(
                        meal: currentMeal,
                        onSwipeLeft: () => _nextMeal(allMeals, false),
                        onSwipeRight: () => _nextMeal(allMeals, true),
                      ),
                      if (isWeb)
                        Positioned(
                          left: 20,
                          child: _buildArrowButton(Icons.arrow_back, () => _nextMeal(allMeals, false), Colors.red),
                        ),
                      if (isWeb)
                        Positioned(
                          right: 20,
                          child: _buildArrowButton(Icons.arrow_forward, () => _nextMeal(allMeals, true), Colors.green),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildActionButtons(allMeals),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActionButtons(List<Meal> meals) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(Icons.close, () => _nextMeal(meals, false), Colors.red),
        const SizedBox(width: 40),
        _buildCircleButton(Icons.favorite, () => _nextMeal(meals, true), Colors.green),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 30),
        onPressed: onPressed,
      ),
    );
  }
}
