import 'dart:math';
import 'package:flutter/material.dart';
import '../models/meal_model.dart';

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

class _MealCardDeckState extends State<MealCardDeck> {
  final Set<int> _selectedIndices = {};
  final Set<int> _flippedIndices = {};

  void _onCardTap(int index) {
    if (_selectedIndices.contains(index)) return;
    if (_selectedIndices.length >= widget.maxSelections) return;

    setState(() {
      _flippedIndices.add(index);
      _selectedIndices.add(index);
    });

    if (_selectedIndices.length == widget.maxSelections) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onSelectionComplete(
          _selectedIndices.map((i) => widget.meals[i]).toList(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pick ${widget.maxSelections - _selectedIndices.length} more meals!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 400,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(widget.meals.length, (index) {
                final isFlipped = _flippedIndices.contains(index);
                final angle = (index - widget.meals.length / 2) * 0.15;
                
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  left: isFlipped ? (MediaQuery.of(context).size.width / 2 - 80) : null,
                  top: isFlipped ? 50 : null,
                  child: Transform.rotate(
                    angle: isFlipped ? 0 : angle,
                    child: _DeckCard(
                      meal: widget.meals[index],
                      isFlipped: isFlipped,
                      onTap: () => _onCardTap(index),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Meal meal;
  final bool isFlipped;
  final VoidCallback onTap;

  const _DeckCard({
    required this.meal,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 160,
        height: 240,
        decoration: BoxDecoration(
          color: isFlipped ? Colors.white : Colors.green[800],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: isFlipped
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant, color: Colors.green, size: 40),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      meal.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${meal.calories} kcal', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'AT',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
