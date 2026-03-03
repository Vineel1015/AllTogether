import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../finder/models/meal_model.dart';
import '../widgets/discovery_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  // Using some mock meals for discovery
  final List<Meal> _meals = [
    const Meal(
      id: 'd1',
      name: 'Vegan Avocado Toast',
      ingredients: ['Sourdough bread', 'Avocado', 'Red pepper flakes', 'Lemon', 'Sea salt'],
      calories: 280,
      prepMinutes: 10,
      price: 5.50,
    ),
    const Meal(
      id: 'd2',
      name: 'Sustainable Salmon Salad',
      ingredients: ['Wild-caught salmon', 'Kale', 'Cherry tomatoes', 'Cucumber', 'Lemon vinaigrette'],
      calories: 420,
      prepMinutes: 15,
      price: 12.00,
    ),
    const Meal(
      id: 'd3',
      name: 'Quinoa Power Bowl',
      ingredients: ['Quinoa', 'Black beans', 'Corn', 'Spinach', 'Tahini dressing'],
      calories: 380,
      prepMinutes: 20,
      price: 9.75,
    ),
  ];

  int _currentIndex = 0;

  void _nextMeal(bool accepted) {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _meals.length;
    });
    
    // In a real app, you'd save the meal if accepted
    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved ${_meals[_currentIndex == 0 ? _meals.length - 1 : _currentIndex - 1].name}!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_meals.isEmpty) {
      return const Center(child: Text('No more meals to discover!'));
    }

    final currentMeal = _meals[_currentIndex];
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
                  // Tinder style card
                  DiscoveryCard(
                    meal: currentMeal,
                    onSwipeLeft: () => _nextMeal(false),
                    onSwipeRight: () => _nextMeal(true),
                  ),
                  
                  // Web/Desktop Arrows
                  if (isWeb)
                    Positioned(
                      left: 20,
                      child: _buildArrowButton(Icons.arrow_back, () => _nextMeal(false), Colors.red),
                    ),
                  if (isWeb)
                    Positioned(
                      right: 20,
                      child: _buildArrowButton(Icons.arrow_forward, () => _nextMeal(true), Colors.green),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircleButton(Icons.close, () => _nextMeal(false), Colors.red),
        const SizedBox(width: 40),
        _buildCircleButton(Icons.favorite, () => _nextMeal(true), Colors.green),
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
