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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => widget.onSelectionComplete(_selectedMeals),
              child: const Text('Confirm Selections'),
            ),
          ),

        const Spacer(),
        
        // Magician Deck Area
        SizedBox(
          height: 400,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (!_isShuffling)
                ...List.generate(availableMeals.length, (index) {
                  final meal = availableMeals[index];
                  final total = availableMeals.length;
                  final angle = (index - total / 2) * (pi / 12); // Arc spread
                  final radius = 300.0;
                  
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
                const Center(child: CircularProgressIndicator(color: AllTogetherColors.mascotOrange)),
            ],
          ),
        ),
        const SizedBox(height: 40),
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
    final x = sin(angle) * radius;
    final y = -cos(angle) * radius + radius;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      bottom: isHovered ? y + 40 : y,
      left: MediaQuery.of(context).size.width / 2 + x - 60,
      child: Transform.rotate(
        angle: angle,
        child: MouseRegion(
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: Draggable<Meal>(
            data: meal,
            feedback: Material(
              color: Colors.transparent,
              child: _CardBack(meal: meal, isFaceUp: true),
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              // If dragged high enough, select it
              if (details.offset.dy < 300) {
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
    final color = AllTogetherColors.getMealColor(meal.id); // Determine by ID prefix or type
    
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: isFaceUp 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant, color: color, size: 30),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(meal.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          )
        : Center(
            child: Text('AT', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 32, fontWeight: FontWeight.w900)),
          ),
    );
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
        width: 60,
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 16, color: color),
            const SizedBox(height: 4),
            Text(meal.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
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
