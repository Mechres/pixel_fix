import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations to landscape for better fullscreen experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const PixelFixApp());
}

class PixelFixApp extends StatelessWidget {
  const PixelFixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Fix App',
      theme: ThemeData(primarySwatch: Colors.blue, brightness: Brightness.dark),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pixel Fix Utility')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Pixel Fix Utility',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This app helps fix stuck pixels on your screen by displaying various patterns and colors.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PixelFixScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text(
                'Start Pixel Fix',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StressTestScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                backgroundColor: Colors.orange,
              ),
              child: const Text(
                'Display Stress Test',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class PixelFixScreen extends StatefulWidget {
  const PixelFixScreen({Key? key}) : super(key: key);

  @override
  State<PixelFixScreen> createState() => _PixelFixScreenState();
}

class _PixelFixScreenState extends State<PixelFixScreen> {
  bool _isFullScreen = false;
  bool _isRunning = false;
  Timer? _timer;
  Color _currentColor = Colors.red;
  int _patternIndex = 0;
  double _speedInSeconds = 2.0;

  // Speed options in seconds
  final List<Map<String, dynamic>> _speedOptions = [
    {'value': 0.3, 'label': 'Ultra Fast (0.3s)'},
    {'value': 0.5, 'label': 'Very Fast (0.5s)'},
    {'value': 1.0, 'label': 'Fast (1s)'},
    {'value': 2.0, 'label': 'Medium (2s)'},
    {'value': 5.0, 'label': 'Slow (5s)'},
    {'value': 10.0, 'label': 'Very Slow (10s)'},
  ];

  final List<String> _patternNames = [
    'Solid Colors',
    'RGB Flashing',
    'White Flashing',
    'RGB Cycling',
    'Random Colors',
    'Checkerboard',
    'Concentric Circles',
    'Diagonal Sweep',
    'Gradient Wave',
  ];

  final List<Color> _basicColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.white,
    Colors.black,
  ];

  int _colorIndex = 0;
  int _animFrame = 0;
  List<List<Color>> _pixelGrid = [];
  Size _screenSize = const Size(100, 100);
  late bool _isGridInitialized;

  @override
  void initState() {
    super.initState();
    _isGridInitialized = false;
    _loadPreferences();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _savePreferences();
    // Return to normal screen mode when leaving
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    super.dispose();
  }

  // Initialize grid for patterns that need it (checkerboard, concentric circles, etc.)
  void _initializePixelGrid() {
    if (_isGridInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Get screen size
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        _screenSize = renderBox.size;

        // Calculate grid size (use a smaller resolution for performance)
        final int gridWidth = 50;
        final int gridHeight =
            (gridWidth * _screenSize.height / _screenSize.width).round();

        // Initialize grid with black
        _pixelGrid = List.generate(
          gridHeight,
          (_) => List.generate(gridWidth, (_) => Colors.black),
        );

        _isGridInitialized = true;
      });
    });
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _patternIndex = prefs.getInt('patternIndex') ?? 0;
        _speedInSeconds = prefs.getDouble('speedInSeconds') ?? 2.0;
      });
    } catch (e) {
      // If loading fails, use default values
      print('Failed to load preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('patternIndex', _patternIndex);
      await prefs.setDouble('speedInSeconds', _speedInSeconds);
    } catch (e) {
      print('Failed to save preferences: $e');
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    });
  }

  void _toggleFixing() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _startPixelFix();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _startPixelFix() {
    _timer?.cancel();
    // Reset indices when starting
    _colorIndex = 0;
    _animFrame = 0;

    // Initialize grid for patterns that need it
    if (_patternIndex >= 5) {
      _initializePixelGrid();
    }

    // Create a periodic timer based on selected pattern
    _timer = Timer.periodic(
      Duration(milliseconds: (_speedInSeconds * 1000).round()),
      (timer) {
        setState(() {
          switch (_patternIndex) {
            case 0: // Solid Colors
              _currentColor = _basicColors[_colorIndex % _basicColors.length];
              _colorIndex++;
              break;

            case 1: // RGB Flashing
              if (_colorIndex % 3 == 0)
                _currentColor = Colors.red;
              else if (_colorIndex % 3 == 1)
                _currentColor = Colors.green;
              else
                _currentColor = Colors.blue;
              _colorIndex++;
              break;

            case 2: // White Flashing
              _currentColor =
                  _colorIndex % 2 == 0 ? Colors.white : Colors.black;
              _colorIndex++;
              break;

            case 3: // RGB Cycling
              // Smooth cycling through RGB spectrum
              final double position = (_colorIndex % 100) / 100.0;
              if (position < 1 / 3) {
                final double factor = position * 3;
                _currentColor = Color.fromRGBO(
                  255,
                  (255 * factor).round(),
                  0,
                  1.0,
                );
              } else if (position < 2 / 3) {
                final double factor = (position - 1 / 3) * 3;
                _currentColor = Color.fromRGBO(
                  255 - (255 * factor).round(),
                  255,
                  0,
                  1.0,
                );
              } else {
                final double factor = (position - 2 / 3) * 3;
                _currentColor = Color.fromRGBO(
                  0,
                  255 - (255 * factor).round(),
                  (255 * factor).round(),
                  1.0,
                );
              }
              _colorIndex++;
              break;

            case 4: // Random Colors
              final random = Random();
              _currentColor = Color.fromRGBO(
                random.nextInt(256),
                random.nextInt(256),
                random.nextInt(256),
                1.0,
              );
              break;

            case 5: // Checkerboard
              _generateCheckerboardPattern();
              _animFrame++;
              break;

            case 6: // Concentric Circles
              _generateConcentricCircles();
              _animFrame++;
              break;

            case 7: // Diagonal Sweep
              _generateDiagonalSweep();
              _animFrame++;
              break;

            case 8: // Gradient Wave
              _generateGradientWave();
              _animFrame++;
              break;
          }
        });
      },
    );
  }

  // Generate a checkerboard pattern that alternates colors
  void _generateCheckerboardPattern() {
    if (!_isGridInitialized) return;

    final bool isAlternateFrame = _animFrame % 2 == 0;
    final Color color1 = isAlternateFrame ? Colors.white : Colors.black;
    final Color color2 = !isAlternateFrame ? Colors.white : Colors.black;

    final gridHeight = _pixelGrid.length;
    final gridWidth = _pixelGrid[0].length;

    // Size of each checker square (in pixels)
    final int checkerSize = 4;

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        final bool isEvenRow = (y ~/ checkerSize) % 2 == 0;
        final bool isEvenCol = (x ~/ checkerSize) % 2 == 0;

        // If row and column have same parity, use color1, otherwise color2
        _pixelGrid[y][x] = (isEvenRow == isEvenCol) ? color1 : color2;
      }
    }
  }

  // Generate concentric circles pattern that expand outward
  void _generateConcentricCircles() {
    if (!_isGridInitialized) return;

    final gridHeight = _pixelGrid.length;
    final gridWidth = _pixelGrid[0].length;

    // Center of the grid
    final centerX = gridWidth / 2;
    final centerY = gridHeight / 2;

    // Maximum radius
    final maxRadius = sqrt(centerX * centerX + centerY * centerY);

    // Number of rings
    const int ringCount = 5;

    // Animation: rings moving outward
    final ringOffset = _animFrame % 20 / 20;

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        // Distance from center
        final dx = x - centerX;
        final dy = y - centerY;
        final distance = sqrt(dx * dx + dy * dy);

        // Normalized distance (0 to 1)
        final normalizedDist = distance / maxRadius;

        // Adding ring offset for animation
        final adjustedDist = (normalizedDist + ringOffset) % 1.0;

        // Determine which ring this pixel belongs to
        final ringIndex = (adjustedDist * ringCount).floor();

        // Alternate colors for adjacent rings
        if (ringIndex % 2 == 0) {
          _pixelGrid[y][x] = Colors.white;
        } else {
          _pixelGrid[y][x] = Colors.black;
        }
      }
    }
  }

  // Generate diagonal sweep pattern
  void _generateDiagonalSweep() {
    if (!_isGridInitialized) return;

    final gridHeight = _pixelGrid.length;
    final gridWidth = _pixelGrid[0].length;

    // Colors to cycle through
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
    ];

    // Width of each color band
    const int bandWidth = 10;

    // Animation: moving diagonal stripes
    final offset = _animFrame % 50;

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        // Calculate diagonal position with moving offset
        final int diagonalPos = (x + y + offset) ~/ bandWidth;

        // Pick color based on position
        final colorIndex = diagonalPos % colors.length;
        _pixelGrid[y][x] = colors[colorIndex];
      }
    }
  }

  // Generate gradient wave pattern
  void _generateGradientWave() {
    if (!_isGridInitialized) return;

    final gridHeight = _pixelGrid.length;
    final gridWidth = _pixelGrid[0].length;

    // Animation time
    final time = _animFrame * 0.05;

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        // Normalized coordinates (0 to 1)
        final nx = x / gridWidth;
        final ny = y / gridHeight;

        // Create wave effect
        final wave1 = sin(nx * 5 + time);
        final wave2 = cos(ny * 5 + time * 0.7);
        final wave = (wave1 + wave2) * 0.5;

        // Map wave (-1 to 1) to RGB values
        int r = ((wave + 1) * 127.5).round();
        int g = ((1 - wave) * 127.5).round();
        int b = (sin(wave * pi) * 255).round();

        _pixelGrid[y][x] = Color.fromRGBO(r, g, b, 1.0);
      }
    }
  }

  void _changePattern(int index) {
    setState(() {
      _patternIndex = index;

      // Reset flags when changing patterns
      _isGridInitialized = false;

      if (_isRunning) {
        _timer?.cancel();
        _startPixelFix();
      }
    });
  }

  void _changeSpeed(double seconds) {
    setState(() {
      _speedInSeconds = seconds;
      if (_isRunning) {
        _timer?.cancel();
        _startPixelFix();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _isFullScreen ? null : AppBar(title: const Text('Pixel Fix Utility')),
      body: GestureDetector(
        onTap: () {
          if (_isFullScreen) {
            _toggleFullScreen();
          }
        },
        child: Stack(
          children: [
            // Advanced patterns need to render the pixel grid
            if (_patternIndex >= 5 && _isGridInitialized)
              SizedBox.expand(
                child: CustomPaint(painter: PixelGridPainter(_pixelGrid)),
              )
            // Basic patterns just use a solid color container
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: _currentColor,
                width: double.infinity,
                height: double.infinity,
              ),

            // Controls - only visible when not in fullscreen mode
            if (!_isFullScreen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pattern selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Pattern: ',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: _patternIndex,
                            dropdownColor: Colors.black87,
                            items: List.generate(_patternNames.length, (index) {
                              return DropdownMenuItem(
                                value: index,
                                child: Text(_patternNames[index]),
                              );
                            }),
                            onChanged: (value) {
                              if (value != null) _changePattern(value);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Speed selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Speed: ', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          DropdownButton<double>(
                            value: _speedInSeconds,
                            dropdownColor: Colors.black87,
                            items:
                                _speedOptions.map((option) {
                                  return DropdownMenuItem<double>(
                                    value: option['value'],
                                    child: Text(option['label']),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) _changeSpeed(value);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              _isRunning ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(_isRunning ? 'Pause' : 'Start'),
                            onPressed: _toggleFixing,
                          ),
                          ElevatedButton.icon(
                            icon: Icon(
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                            ),
                            label: Text(
                              _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                            ),
                            onPressed: _toggleFullScreen,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Instructions
                      const Text(
                        'Tap anywhere on the screen in fullscreen mode to exit',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Recommended: Run each pattern for 10-15 minutes per stuck pixel',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PixelGridPainter extends CustomPainter {
  final List<List<Color>> pixelGrid;

  PixelGridPainter(this.pixelGrid);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final cellWidth = size.width / pixelGrid[0].length;
    final cellHeight = size.height / pixelGrid.length;

    for (int y = 0; y < pixelGrid.length; y++) {
      for (int x = 0; x < pixelGrid[y].length; x++) {
        paint.color = pixelGrid[y][x];
        canvas.drawRect(
          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PixelGridScreen extends StatefulWidget {
  const PixelGridScreen({Key? key}) : super(key: key);

  @override
  State<PixelGridScreen> createState() => _PixelGridScreenState();
}

class _PixelGridScreenState extends State<PixelGridScreen> {
  // Default grid dimensions
  int rows = 10;
  int columns = 10;

  // Selected color
  Color currentColor = Colors.blue;

  // List of available colors
  final List<Color> colorPalette = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.cyan,
  ];

  // Grid state - stores color for each pixel
  late List<List<Color>> pixelColors;

  // Controller for grid size input
  final TextEditingController _rowController = TextEditingController();
  final TextEditingController _columnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rowController.text = rows.toString();
    _columnController.text = columns.toString();
    _initializeGrid();
  }

  @override
  void dispose() {
    _rowController.dispose();
    _columnController.dispose();
    super.dispose();
  }

  void _initializeGrid() {
    // Initialize grid with default color (black)
    pixelColors = List.generate(
      rows,
      (i) => List.generate(columns, (j) => Colors.black),
    );
  }

  void _resetGrid() {
    setState(() {
      _initializeGrid();
    });
  }

  void _randomizeGrid() {
    final random = Random();
    setState(() {
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
          pixelColors[i][j] = colorPalette[random.nextInt(colorPalette.length)];
        }
      }
    });
  }

  void _updateGridSize() {
    // Parse new dimensions
    final newRows = int.tryParse(_rowController.text) ?? rows;
    final newColumns = int.tryParse(_columnController.text) ?? columns;

    // Update grid if values are valid
    if (newRows > 0 &&
        newColumns > 0 &&
        (newRows != rows || newColumns != columns)) {
      setState(() {
        rows = newRows;
        columns = newColumns;
        _initializeGrid();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel Drawing Tool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGrid,
            tooltip: 'Reset Grid',
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _randomizeGrid,
            tooltip: 'Randomize Colors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Color palette
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colorPalette.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        currentColor = colorPalette[index];
                      });
                    },
                    child: Container(
                      width: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: colorPalette[index],
                        border: Border.all(
                          color:
                              currentColor == colorPalette[index]
                                  ? Colors.white
                                  : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Grid size controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _rowController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rows'),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _columnController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cols'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _updateGridSize,
                  child: const Text('Update Grid'),
                ),
              ],
            ),
          ),

          // Pixel grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = constraints.maxWidth / columns;
                  final cellHeight = constraints.maxHeight / rows;

                  return GestureDetector(
                    onPanUpdate: (details) {
                      // Calculate the cell position directly from the local position
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final localPosition = box.globalToLocal(
                        details.globalPosition,
                      );

                      final int col = (localPosition.dx / cellWidth).floor();
                      final int row = (localPosition.dy / cellHeight).floor();

                      // Update if within bounds
                      if (row >= 0 && row < rows && col >= 0 && col < columns) {
                        setState(() {
                          pixelColors[row][col] = currentColor;
                        });
                      }
                    },
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: rows * columns,
                      itemBuilder: (context, index) {
                        final row = index ~/ columns;
                        final col = index % columns;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              pixelColors[row][col] = currentColor;
                            });
                          },
                          child: Container(color: pixelColors[row][col]),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StressTestScreen extends StatefulWidget {
  const StressTestScreen({Key? key}) : super(key: key);

  @override
  State<StressTestScreen> createState() => _StressTestScreenState();
}

class _StressTestScreenState extends State<StressTestScreen> {
  bool _isFullScreen = false;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _testTimer;
  Timer? _countdownTimer;
  Timer? _uncappedTimer;

  // Test options
  int _testPatternIndex = 0;
  int _testDurationIndex = 1; // Default to 5 minutes
  int _elapsedSeconds = 0;
  int _totalDurationSeconds = 5 * 60; // Default 5 minutes

  // Visual elements
  Color _currentColor = Colors.black;
  int _animFrame = 0;
  List<List<Color>> _pixelGrid = [];
  Size _screenSize = const Size(100, 100);
  bool _isGridInitialized = false;

  // Test results data
  double _maxFps = 0;
  double _minFps = double.infinity;
  double _avgFps = 0;
  int _frameCount = 0;
  int _lastFrameTime = 0;
  List<double> _fpsReadings = [];

  // Uncapped FPS measurement
  bool _measureUncappedFps = true;
  double _uncappedFps = 0;
  double _maxUncappedFps = 0;
  int _uncappedFrameCount = 0;
  int _lastUncappedTime = 0;
  Stopwatch _fpsStopwatch = Stopwatch();

  // Pattern definitions
  final List<String> _testPatterns = [
    'Extreme RGB Cycling',
    'High Contrast Flashing',
    'Pixel Inversion Test',
    'Thermal Stress Pattern',
    'Response Time Test',
    'Burn-in Detection',
  ];

  // Duration options
  final List<Map<String, dynamic>> _durationOptions = [
    {'value': 60, 'label': '1 Minute'},
    {'value': 5 * 60, 'label': '5 Minutes'},
    {'value': 15 * 60, 'label': '15 Minutes'},
    {'value': 30 * 60, 'label': '30 Minutes'},
    {'value': 60 * 60, 'label': '1 Hour'},
  ];

  @override
  void initState() {
    super.initState();
    _initFrameRateMonitor();
    _fpsStopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _testTimer?.cancel();
    _countdownTimer?.cancel();
    _uncappedTimer?.cancel();
    // Return to normal screen mode when leaving
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
    super.dispose();
  }

  void _initFrameRateMonitor() {
    // Initialize frame rate monitoring
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
    _frameCount = 0;
    _fpsReadings = [];
  }

  void _initializePixelGrid() {
    if (_isGridInitialized) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // Get screen size
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        _screenSize = renderBox.size;

        // Calculate grid size (use a smaller resolution for performance)
        final int gridWidth = 60;
        final int gridHeight =
            (gridWidth * _screenSize.height / _screenSize.width).round();

        // Initialize grid with black
        _pixelGrid = List.generate(
          gridHeight,
          (_) => List.generate(gridWidth, (_) => Colors.black),
        );

        _isGridInitialized = true;
      });
    });
  }

  void _updateFrameRate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastFrameTime;
    _lastFrameTime = now;

    if (elapsed > 0) {
      final fps = 1000 / elapsed;
      _frameCount++;

      // Update statistics every second
      if (_frameCount % 10 == 0) {
        // Add reading to history
        _fpsReadings.add(fps);

        // Update min/max fps
        if (fps > _maxFps) _maxFps = fps;
        if (fps < _minFps) _minFps = fps;

        // Calculate average
        double sum = 0;
        for (var reading in _fpsReadings) {
          sum += reading;
        }
        _avgFps = sum / _fpsReadings.length;
      }
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    });
  }

  void _startTest() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _elapsedSeconds = 0;
      _totalDurationSeconds =
          _durationOptions[_testDurationIndex]['value'] as int;

      // Reset statistics
      _initFrameRateMonitor();

      // Start uncapped FPS measuring
      _startUncappedFpsMeasurement();

      // Initialize pixel grid if needed
      _initializePixelGrid();
    });

    // Set up countdown timer
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          if (_elapsedSeconds >= _totalDurationSeconds) {
            _stopTest();
          }
        });
      }
    });

    // Set up animation timer - run faster for stress test
    _testTimer?.cancel();
    _testTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      // Only update if not paused
      if (!_isPaused) {
        setState(() {
          // Run the selected test pattern
          _runSelectedPattern();

          // Update animation frame counter
          _animFrame++;

          // Update frame rate statistics
          _updateFrameRate();
        });
      }
    });
  }

  void _startUncappedFpsMeasurement() {
    // Reset uncapped FPS tracking
    _uncappedFps = 0;
    _maxUncappedFps = 0;
    _uncappedFrameCount = 0;
    _lastUncappedTime = DateTime.now().millisecondsSinceEpoch;
    _fpsStopwatch.reset();
    _fpsStopwatch.start();

    // Cancel any existing timer
    _uncappedTimer?.cancel();

    // Start a timer that runs as fast as possible (not tied to vsync)
    _uncappedTimer = Timer.periodic(const Duration(microseconds: 1), (timer) {
      if (_isPaused || !_isRunning) return;

      // Count frame
      _uncappedFrameCount++;

      // Measure every 100ms
      final elapsed = _fpsStopwatch.elapsedMilliseconds;
      if (elapsed > 100) {
        // Calculate uncapped FPS
        _uncappedFps = (_uncappedFrameCount / elapsed) * 1000;

        // Update max uncapped FPS
        if (_uncappedFps > _maxUncappedFps) {
          _maxUncappedFps = _uncappedFps;
        }

        // Reset for next measurement
        _uncappedFrameCount = 0;
        _fpsStopwatch.reset();
        _fpsStopwatch.start();
      }
    });
  }

  void _stopTest() {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _testTimer?.cancel();
      _countdownTimer?.cancel();
      _uncappedTimer?.cancel();
      _fpsStopwatch.stop();
    });

    // Show results dialog
    if (_elapsedSeconds > 5) {
      _showTestResults();
    }
  }

  void _pauseResumeTest() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _changeTestPattern(int index) {
    setState(() {
      _testPatternIndex = index;
      if (_isRunning) {
        // If test is already running, restart it with new pattern
        _testTimer?.cancel();
        _animFrame = 0;
        _runSelectedPattern();
      }
    });
  }

  void _changeDuration(int index) {
    setState(() {
      _testDurationIndex = index;
      _totalDurationSeconds = _durationOptions[index]['value'] as int;

      // If test is running, update duration
      if (_isRunning) {
        // If elapsed time already exceeds new duration, stop test
        if (_elapsedSeconds >= _totalDurationSeconds) {
          _stopTest();
        }
      }
    });
  }

  void _runSelectedPattern() {
    switch (_testPatternIndex) {
      case 0: // Extreme RGB Cycling (ultra-fast cycling through RGB values)
        _runExtremeRGBCycling();
        break;
      case 1: // High Contrast Flashing (rapid alternation between bright and dark)
        _runHighContrastFlashing();
        break;
      case 2: // Pixel Inversion Test (checkerboard pattern that alternates pixels)
        _runPixelInversionTest();
        break;
      case 3: // Thermal Stress Pattern (color-heavy pattern to generate heat)
        _runThermalStressPattern();
        break;
      case 4: // Response Time Test (fast-moving elements)
        _runResponseTimeTest();
        break;
      case 5: // Burn-in Detection (alternating patterns to reveal burn-in)
        _runBurnInDetectionTest();
        break;
    }
  }

  void _runExtremeRGBCycling() {
    // Ultra-fast RGB cycling - cycles through entire RGB spectrum rapidly
    final position = (_animFrame % 60) / 60.0;

    if (position < 1 / 3) {
      final factor = position * 3;
      _currentColor = Color.fromRGBO(255, (255 * factor).round(), 0, 1.0);
    } else if (position < 2 / 3) {
      final factor = (position - 1 / 3) * 3;
      _currentColor = Color.fromRGBO(255 - (255 * factor).round(), 255, 0, 1.0);
    } else {
      final factor = (position - 2 / 3) * 3;
      _currentColor = Color.fromRGBO(
        0,
        255 - (255 * factor).round(),
        (255 * factor).round(),
        1.0,
      );
    }
  }

  void _runHighContrastFlashing() {
    // High-contrast flashing between extremes
    if (_animFrame % 2 == 0) {
      _currentColor = Colors.white;
    } else {
      _currentColor = Colors.black;
    }
  }

  void _runPixelInversionTest() {
    if (!_isGridInitialized) return;

    final gridHeight = _pixelGrid.length;
    final gridWidth = _pixelGrid[0].length;

    // Alternate checkerboard pattern every frame
    final isEvenFrame = _animFrame % 2 == 0;

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        final isEvenCell = (x + y) % 2 == 0;
        // Alternate black and white based on position and frame
        if (isEvenCell == isEvenFrame) {
          _pixelGrid[y][x] = Colors.white;
        } else {
          _pixelGrid[y][x] = Colors.black;
        }
      }
    }
  }

  void _runThermalStressPattern() {
    // Rapidly cycle through high-intensity colors to generate heat
    final colorIndex = _animFrame % 4;

    switch (colorIndex) {
      case 0:
        _currentColor = Colors.red; // Full red - high heat
        break;
      case 1:
        _currentColor = Colors.white; // Full RGB - max heat
        break;
      case 2:
        _currentColor = Colors.blue; // Full blue
        break;
      case 3:
        _currentColor = Color.fromRGBO(255, 0, 255, 1); // Purple (red+blue)
        break;
    }
  }

  void _runResponseTimeTest() {
    if (!_isGridInitialized) return;

    final gridHeight = _pixelGrid.length;
    final gridWidth = _pixelGrid[0].length;

    // Clear grid
    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        _pixelGrid[y][x] = Colors.black;
      }
    }

    // Draw fast moving horizontal bars
    final barWidth = 3;
    final position = (_animFrame * 2) % gridHeight;

    // Draw the bar
    for (int y = position; y < position + barWidth && y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        _pixelGrid[y][x] = Colors.white;
      }
    }

    // Draw vertical bar
    final vertPosition = (_animFrame * 3) % gridWidth;
    for (
      int x = vertPosition;
      x < vertPosition + barWidth && x < gridWidth;
      x++
    ) {
      for (int y = 0; y < gridHeight; y++) {
        _pixelGrid[y][x] = Colors.white;
      }
    }
  }

  void _runBurnInDetectionTest() {
    // Pattern switches between full white and primary colors
    final frameGroup = (_animFrame ~/ 30) % 5;

    switch (frameGroup) {
      case 0:
        _currentColor = Colors.white;
        break;
      case 1:
        _currentColor = Colors.red;
        break;
      case 2:
        _currentColor = Colors.green;
        break;
      case 3:
        _currentColor = Colors.blue;
        break;
      case 4:
        _currentColor = Colors.black;
        break;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showTestResults() {
    final percentComplete =
        (_elapsedSeconds / _totalDurationSeconds * 100).round();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Stress Test Results (${percentComplete}% Complete)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test Duration: ${_formatTime(_elapsedSeconds)} / ${_formatTime(_totalDurationSeconds)}',
              ),
              const SizedBox(height: 10),
              const Text(
                'Performance Metrics:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Max Frame Rate: ${_maxFps.toStringAsFixed(1)} FPS'),
              Text(
                '• Min Frame Rate: ${_minFps == double.infinity ? 'N/A' : _minFps.toStringAsFixed(1)} FPS',
              ),
              Text('• Average Frame Rate: ${_avgFps.toStringAsFixed(1)} FPS'),
              const Divider(),
              const Text(
                'Uncapped Performance:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• Max Uncapped FPS: ${_maxUncappedFps.toStringAsFixed(1)} FPS',
                style: TextStyle(color: Colors.amber[700]),
              ),
              Text(
                '• Current Uncapped FPS: ${_uncappedFps.toStringAsFixed(1)} FPS',
                style: TextStyle(color: Colors.amber[700]),
              ),
              const SizedBox(height: 10),
              const Text(
                'Assessment:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              _getPerformanceAssessment(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTest(); // Restart the test
              },
              child: const Text('Run Again'),
            ),
          ],
        );
      },
    );
  }

  Widget _getPerformanceAssessment() {
    String assessment;
    Color assessmentColor;

    if (_avgFps < 30) {
      assessment =
          'Poor display response - significant frame drops detected which may indicate an underlying display issue.';
      assessmentColor = Colors.red;
    } else if (_avgFps < 50) {
      assessment =
          'Average performance - minor frame inconsistencies detected. Consider running longer tests.';
      assessmentColor = Colors.orange;
    } else {
      assessment =
          'Good performance - display responds well to rapid changes with consistent frame rates.';
      assessmentColor = Colors.green;
    }

    return Text(assessment, style: TextStyle(color: assessmentColor));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final progress = _isRunning ? _elapsedSeconds / _totalDurationSeconds : 0.0;

    return Scaffold(
      appBar:
          _isFullScreen
              ? null
              : AppBar(
                title: const Text('Display Stress Test'),
                backgroundColor: Colors.deepOrange,
              ),
      body: Stack(
        children: [
          // Stress test pattern display
          _testPatternIndex == 2 || _testPatternIndex == 4
              ? SizedBox.expand(
                child:
                    _isGridInitialized
                        ? CustomPaint(painter: PixelGridPainter(_pixelGrid))
                        : Container(color: Colors.black),
              )
              : Container(
                width: double.infinity,
                height: double.infinity,
                color: _currentColor,
              ),

          // Controls overlay (when not in fullscreen)
          if (!_isFullScreen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar (only visible when test is running)
                    if (_isRunning)
                      Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Progress: ${_formatTime(_elapsedSeconds)} / ${_formatTime(_totalDurationSeconds)}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Displayed FPS: ${_avgFps.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Uncapped FPS: ${_uncappedFps.toStringAsFixed(1)}',
                                    style: TextStyle(color: Colors.amber[300]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isPaused ? Colors.orange : Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Test pattern selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Test Pattern:',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: _testPatternIndex,
                          dropdownColor: Colors.black87,
                          underline: Container(
                            height: 1,
                            color: Colors.deepOrange,
                          ),
                          items: List.generate(_testPatterns.length, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text(
                                _testPatterns[index],
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }),
                          onChanged:
                              !_isRunning
                                  ? (value) {
                                    if (value != null)
                                      _changeTestPattern(value);
                                  }
                                  : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Test duration selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Duration:',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: _testDurationIndex,
                          dropdownColor: Colors.black87,
                          underline: Container(
                            height: 1,
                            color: Colors.deepOrange,
                          ),
                          items: List.generate(_durationOptions.length, (
                            index,
                          ) {
                            return DropdownMenuItem(
                              value: index,
                              child: Text(
                                _durationOptions[index]['label'] as String,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }),
                          onChanged:
                              !_isRunning
                                  ? (value) {
                                    if (value != null) _changeDuration(value);
                                  }
                                  : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!_isRunning)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Test'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _startTest,
                          )
                        else
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(
                                  _isPaused ? Icons.play_arrow : Icons.pause,
                                ),
                                label: Text(_isPaused ? 'Resume' : 'Pause'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _isPaused ? Colors.green : Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _pauseResumeTest,
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.stop),
                                label: const Text('Stop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _stopTest,
                              ),
                            ],
                          ),

                        ElevatedButton.icon(
                          icon: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                          ),
                          label: Text(
                            _isFullScreen ? 'Exit Fullscreen' : 'Fullscreen',
                          ),
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Information text
                    const Text(
                      'Tap anywhere in fullscreen mode to exit',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Testing pattern: ${_testPatterns[_testPatternIndex]}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Fullscreen tap handler
          if (_isFullScreen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFullScreen,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),

          // Show pattern explanation
          if (_isFullScreen && _isRunning)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _testPatterns[_testPatternIndex],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_formatTime(_elapsedSeconds)} / ${_formatTime(_totalDurationSeconds)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
