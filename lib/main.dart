import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(AquaVentureApp());
}

class AquaVentureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaVenture',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AquariumScreen(),
    );
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with TickerProviderStateMixin {
  final List<Fish> fishList = [];
  bool collisionEnabled = true;
  Color selectedColor = Colors.blue;
  double selectedSpeed = 1.0;
  final int maxFish = 10;
  bool isCollisionChecking = false;

  void _addFish() {
    if (fishList.length < maxFish) {
      setState(() {
        fishList.add(Fish(
          color: selectedColor,
          speed: selectedSpeed,
          screenSize: const Size(300, 300),
          vsync: this,
        ));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum number of fish reached!')),
      );
    }
  }

  void _removeFish() {
    if (fishList.isNotEmpty) {
      setState(() {
        fishList.removeLast();
      });
    }
  }

  /// Schedule the collision check safely without blocking the UI thread.
  void _scheduleCollisionCheck() {
    if (isCollisionChecking || !collisionEnabled) return;
    isCollisionChecking = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCollisions();
      isCollisionChecking = false;
    });
  }

  void _checkCollisions() {
    // Copy of the fish list to avoid concurrent modification.
    final List<Fish> fishCopy = List.from(fishList);

    for (int i = 0; i < fishCopy.length; i++) {
      for (int j = i + 1; j < fishCopy.length; j++) {
        Fish fish1 = fishCopy[i];
        Fish fish2 = fishCopy[j];

        if ((fish1.position - fish2.position).distance < 20) {
          // Safely update state and change direction/color of the fish.
          setState(() {
            fish1.reverseDirection();
            fish2.reverseDirection();
            fish1.color = _getRandomColor();
            fish2.color = _getRandomColor();
          });
        }
      }
    }
  }

  Color _getRandomColor() {
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AquaVenture'),
        actions: [
          Switch(
            value: collisionEnabled,
            onChanged: (value) {
              setState(() {
                collisionEnabled = value;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.lightBlueAccent,
            child: Stack(
              children: fishList.map((fish) {
                return fish.buildFish(_scheduleCollisionCheck);
              }).toList(),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addFish,
                child: Text('Add Fish'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _removeFish,
                child: Text('Remove Fish'),
              ),
            ],
          ),
          Slider(
            value: selectedSpeed,
            min: 0.5,
            max: 3.0,
            onChanged: (value) {
              setState(() {
                selectedSpeed = value;
              });
            },
          ),
          DropdownButton<Color>(
            value: selectedColor,
            items: [
              DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
              DropdownMenuItem(value: Colors.red, child: Text('Red')),
              DropdownMenuItem(value: Colors.green, child: Text('Green')),
            ],
            onChanged: (value) {
              setState(() {
                selectedColor = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}

class Fish {
  Color color;
  final double speed;
  final Size screenSize;
  Offset position;
  Offset direction;
  late AnimationController controller;

  Fish({
    required this.color,
    required this.speed,
    required this.screenSize,
    required TickerProvider vsync,
  })  : position = Offset(
          Random().nextDouble() * screenSize.width,
          Random().nextDouble() * screenSize.height,
        ),
        direction = Offset(
          (Random().nextDouble() - 0.5) * 2,
          (Random().nextDouble() - 0.5) * 2,
        ) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 30),
    );
    controller.addListener(_updatePosition);
    controller.repeat();
  }

  void _updatePosition() {
    position += direction * speed;

    if (position.dx <= 0 || position.dx >= screenSize.width - 20) {
      direction = Offset(-direction.dx, direction.dy);
    }
    if (position.dy <= 0 || position.dy >= screenSize.height - 20) {
      direction = Offset(direction.dx, -direction.dy);
    }
  }

  void reverseDirection() {
    direction = Offset(-direction.dx, -direction.dy);
  }

  Widget buildFish(VoidCallback scheduleCollisionCheck) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        scheduleCollisionCheck(); // Schedule collision check safely.
        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
