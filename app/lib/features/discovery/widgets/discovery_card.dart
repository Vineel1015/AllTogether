import 'package:flutter/material.dart';
import '../../finder/models/meal_model.dart';
import '../../../core/constants/brand_colors.dart';

class DiscoveryCard extends StatefulWidget {
  final Meal meal;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const DiscoveryCard({
    super.key,
    required this.meal,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<DiscoveryCard> {
  // 0: Main View, 1: Ingredients, 2: Sustainability
  int _viewMode = 0;
  double _swipePosition = 0;

  @override
  Widget build(BuildContext context) {
    return Draggable<Meal>(
      data: widget.meal,
      feedback: Opacity(
        opacity: 0.8,
        child: Material(
          color: Colors.transparent,
          child: _buildCardContent(),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(),
      ),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _swipePosition += details.delta.dx;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_swipePosition > 100) {
            widget.onSwipeRight();
          } else if (_swipePosition < -100) {
            widget.onSwipeLeft();
          }
          setState(() {
            _swipePosition = 0;
          });
        },
        onTap: () {
          setState(() {
            _viewMode = (_viewMode + 1) % 3;
          });
        },
        child: Transform.translate(
          offset: Offset(_swipePosition, 0),
          child: Transform.rotate(
            angle: _swipePosition / 1000,
            child: _buildCardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return Container(
      width: 320,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Expanded(
              child: _buildContent(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case 1:
        return _buildIngredientsView();
      case 2:
        return _buildSustainabilityView();
      default:
        return _buildMainView();
    }
  }

  Widget _buildMainView() {
    final color = AllTogetherColors.getMealColor(widget.meal.id);
    return Stack(
      children: [
        // Meal Image Placeholder with Category Color
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.restaurant, size: 100, color: Colors.white70),
          ),
        ),
        // Gradient overlay for text readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              stops: const [0.6, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.meal.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatLabel(Icons.local_fire_department, '${widget.meal.calories} kcal'),
                  const SizedBox(width: 16),
                  _buildStatLabel(Icons.timer, '${widget.meal.prepMinutes} min'),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap for Ingredients',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsView() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: widget.meal.ingredients.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.meal.ingredients[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Center(
            child: Text(
              'Tap for Sustainability Score',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSustainabilityView() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFEFE8D3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.eco, size: 80, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            'Sustainability Score',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '9.5 / 10', // Placeholder score
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.green),
          ),
          const SizedBox(height: 24),
          const Text(
            'This meal uses 100% locally sourced ingredients and has a minimal carbon footprint.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 40),
          const Text(
            'Tap to return to main view',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SWIPE LEFT TO SKIP',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10),
          ),
          Text(
            'SWIPE RIGHT TO SAVE',
            style: TextStyle(color: AllTogetherColors.mascotBlue, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
