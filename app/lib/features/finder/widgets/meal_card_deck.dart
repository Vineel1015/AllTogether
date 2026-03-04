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
  double _scrollOffset = 0.0;
  String? _hoveredMealId;

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
          height: 140,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._selectedMeals.map((meal) => _SelectedCard(
                meal: meal, 
                onTap: () => _unselectMeal(meal)
              )),
              ...List.generate(widget.maxSelections - _selectedMeals.length, (i) => _EmptySlot()),
            ],
          ),
        ),
        
        Text(
          'Pick ${widget.maxSelections - _selectedMeals.length} more cards',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AllTogetherColors.mascotBlue),
        ),

        const Spacer(),
        
        // Magician Radial Fan Deck
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _scrollOffset -= details.delta.dx / 200; // Sensibility
            });
          },
          child: Container(
            height: 550,
            width: double.infinity,
            color: Colors.transparent, // Capture gestures
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: List.generate(availableMeals.length, (index) {
                final meal = availableMeals[index];
                final total = availableMeals.length;
                
                // Calculate spread position with scroll offset
                final double centerIndex = (total - 1) / 2;
                final double relativePos = (index - centerIndex) + _scrollOffset;
                
                // Arc calculations
                final double arcSpread = pi / 4; // 45 degree spread
                final double angle = relativePos * (arcSpread / 3);
                final double radius = 600.0;
                
                return _RadialFanCard(
                  key: ValueKey(meal.id),
                  meal: meal,
                  angle: angle,
                  radius: radius,
                  isHovered: _hoveredMealId == meal.id,
                  onHover: (h) => setState(() => _hoveredMealId = h ? meal.id : null),
                  onSelected: () => _selectMeal(meal),
                );
              }),
            ),
          ),
        ),
        
        const SizedBox(height: 20),

        if (_selectedMeals.length == widget.maxSelections)
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AllTogetherColors.mascotBlue, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => widget.onSelectionComplete(_selectedMeals),
              child: const Text('READY FOR THE HAUL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
      ],
    );
  }
}

class _RadialFanCard extends StatelessWidget {
  final Meal meal;
  final double angle;
  final double radius;
  final bool isHovered;
  final Function(bool) onHover;
  final VoidCallback onSelected;

  const _RadialFanCard({
    super.key,
    required this.meal,
    required this.angle,
    required this.radius,
    required this.isHovered,
    required this.onHover,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Pivot from bottom center to create radial fan
    final double x = sin(angle) * radius;
    final double y = -cos(angle) * radius + radius;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: isHovered ? y + 80 : y,
      left: (MediaQuery.of(context).size.width / 2) + x - 140,
      child: Transform.rotate(
        angle: angle,
        child: MouseRegion(
          onEnter: (_) => onHover(true),
          onExit: (_) => onHover(false),
          child: _LargeFlipCard(
            meal: meal,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }
}

class _LargeFlipCard extends StatefulWidget {
  final Meal meal;
  final VoidCallback onSelected;

  const _LargeFlipCard({required this.meal, required this.onSelected});

  @override
  State<_LargeFlipCard> createState() => _LargeFlipCardState();
}

class _LargeFlipCardState extends State<_LargeFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFaceUp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFaceUp) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() => _isFaceUp = !_isFaceUp);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: Draggable<Meal>(
        data: widget.meal,
        axis: Axis.vertical,
        feedback: Material(
          color: Colors.transparent,
          child: _CardSide(meal: widget.meal, isFaceUp: true, isLarge: true),
        ),
        onDragEnd: (details) {
          if (details.offset.dy < 250) {
            widget.onSelected();
          }
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double value = _animation.value;
            final bool isBack = value < (pi / 2);
            
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(value),
              alignment: Alignment.center,
              child: isBack
                ? _CardSide(meal: widget.meal, isFaceUp: false, isLarge: true)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _CardSide(meal: widget.meal, isFaceUp: true, isLarge: true),
                  ),
            );
          },
        ),
      ),
    );
  }
}

class _CardSide extends StatelessWidget {
  final Meal meal;
  final bool isFaceUp;
  final bool isLarge;
  const _CardSide({required this.meal, required this.isFaceUp, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final color = AllTogetherColors.getMealColor(meal.id);
    final width = isLarge ? 280.0 : 70.0;
    final height = isLarge ? 420.0 : 100.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isFaceUp ? Colors.white : color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: isFaceUp 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, color: color, size: isLarge ? 80 : 20),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  meal.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: isLarge ? 24 : 8,
                    color: color.darken(0.3),
                  ),
                ),
              ),
              if (isLarge) ...[
                const SizedBox(height: 12),
                Text('${meal.calories} kcal', style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('DRAG UP TO DEAL', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2)),
              ],
            ],
          )
        : Center(
            child: Text(
              'AT',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: isLarge ? 100 : 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
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
      width: 70,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 3)),
      ),
      child: const Center(child: Icon(Icons.add, color: Colors.grey, size: 24)),
    );
  }
}
