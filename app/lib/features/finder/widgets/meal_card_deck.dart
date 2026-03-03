import 'dart:math';
import 'package:flutter/material.dart';
import '../models/meal_model.dart';
import '../../../core/constants/brand_colors.dart';

class MealCardDeck extends StatefulWidget {
  final List<Meal> meals;
  final int maxSelections;
  final Function(List<Meal>) onSelectionComplete;

  const MealCardDeck({
    super.key,
    required this.meals,
    required this.maxSelections,
    required this.onSelectionComplete,
  });

  @override
  State<MealCardDeck> createState() => _MealCardDeckState();
}

class _MealCardDeckState extends State<MealCardDeck> with TickerProviderStateMixin {
  final List<Meal> _selectedMeals = [];
  final Set<String> _dealtMealIds = {};
  String? _hoveredMealId;
  bool _isShuffling = false;

  @override
  void initState() {
    super.initState();
    _triggerShuffle();
  }

  void _triggerShuffle() {
    setState(() => _isShuffling = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _isShuffling = false);
    });
  }

  void _selectMeal(Meal meal) {
    if (_selectedMeals.length < widget.maxSelections && !_dealtMealIds.contains(meal.id)) {
      setState(() {
        _selectedMeals.add(meal);
        _dealtMealIds.add(meal.id);
      });
    }
  }

  void _unselectMeal(Meal meal) {
    setState(() {
      _selectedMeals.removeWhere((m) => m.id == meal.id);
      _dealtMealIds.remove(meal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableMeals = widget.meals.where((m) => !_dealtMealIds.contains(m.id)).toList();

    return Column(
      children: [
        // Hand / Selection Area
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._selectedMeals.map((meal) => _SelectedCard(
                meal: meal, 
                onTap: () => _unselectMeal(meal)
              )),
              // Placeholders
              ...List.generate(widget.maxSelections - _selectedMeals.length, (i) => _EmptySlot()),
            ],
          ),
        ),
        
        if (_selectedMeals.length == widget.maxSelections)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AllTogetherColors.mascotBlue, foregroundColor: Colors.white),
              onPressed: () => widget.onSelectionComplete(_selectedMeals),
              child: const Text('Confirm Selections', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

        const Spacer(),
        
        // Magician Deck Area
        SizedBox(
          height: 450,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (!_isShuffling)
                ...List.generate(availableMeals.length, (index) {
                  final meal = availableMeals[index];
                  final total = availableMeals.length;
                  // Pivot from the bottom center, fan out in an arc
                  final double arcSpread = pi / 3; // 60 degrees total spread
                  final double startAngle = -arcSpread / 2;
                  final double angle = startAngle + (index / (total - 1)) * arcSpread;
                  final radius = 400.0;
                  
                  return _DraggableCard(
                    meal: meal,
                    angle: angle,
                    radius: radius,
                    isHovered: _hoveredMealId == meal.id,
                    onHover: (hovering) {
                      setState(() => _hoveredMealId = hovering ? meal.id : null);
                    },
                    onSelected: () => _selectMeal(meal),
                  );
                }),
              if (_isShuffling)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AllTogetherColors.mascotOrange),
                      SizedBox(height: 16),
                      Text('Shuffling Deck...', style: TextStyle(color: AllTogetherColors.mascotOrange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _DraggableCard extends StatelessWidget {
  final Meal meal;
  final double angle;
  final double radius;
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onSelected;

  const _DraggableCard({
    required this.meal,
    required this.angle,
    required this.radius,
    required this.isHovered,
    required this.onHover,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Pivot from bottom center
    final double xOffset = sin(angle) * radius;
    final double yOffset = -cos(angle) * radius + radius;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      bottom: isHovered ? yOffset + 60 : yOffset,
      left: (MediaQuery.of(context).size.width / 2) + xOffset - 60,
      child: Transform.rotate(
        angle: angle,
        child: MouseRegion(
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: Draggable<Meal>(
            data: meal,
            axis: Axis.vertical,
            feedback: Material(
              color: Colors.transparent,
              child: _CardBack(meal: meal, isFaceUp: true),
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              // Select if dragged up past a threshold
              if (details.offset.dy < MediaQuery.of(context).size.height * 0.5) {
                onSelected();
              }
            },
            child: _CardBack(meal: meal, isFaceUp: false),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final Meal meal;
  final bool isFaceUp;
  const _CardBack({required this.meal, this.isFaceUp = false});

  @override
  Widget build(BuildContext context) {
    final color = AllTogetherColors.getMealColor(meal.id);
    
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: isFaceUp 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, color: color, size: 40),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  meal.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: color.darken(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${meal.calories} kcal',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          )
        : Center(
            child: Text(
              'AT',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class _SelectedCard extends StatelessWidget {
  final Meal meal;
  final VoidCallback onTap;
  const _SelectedCard({required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AllTogetherColors.getMealColor(meal.id);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 3),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 20, color: color),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                meal.name, 
                maxLines: 2, 
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis, 
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color.darken(0.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 2)),
      ),
      child: const Center(child: Icon(Icons.add, color: Colors.grey, size: 20)),
    );
  }
}
