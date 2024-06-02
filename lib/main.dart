import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(TetrisApp());
}

class TetrisApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetris',
      home: TetrisGame(),
    );
  }
}

class GameBoard {
  static const int width = 10;
  static const int height = 20;
  List<List<bool>> board = List.generate(height, (_) => List.filled(width, false));

  void clearLine(int line) {
    for (int x = 0; x < width; x++) {
      board[line][x] = false;
    }
  }

  void shiftDown(int line) {
    for (int y = line; y > 0; y--) {
      for (int x = 0; x < width; x++) {
        board[y][x] = board[y - 1][x];
      }
    }
    for (int x = 0; x < width; x++) {
      board[0][x] = false;
    }
  }

  bool isLineFull(int line) {
    for (int x = 0; x < width; x++) {
      if (!board[line][x]) return false;
    }
    return true;
  }

  bool isGameOver() {
    for (int x = 0; x < width; x++) {
      if (board[0][x]) return true;
    }
    return false;
  }
}

class Tetromino {
  final List<Offset> shape;
  Tetromino(this.shape);

  static final List<Tetromino> all = [
    Tetromino([Offset(0, 0), Offset(1, 0), Offset(2, 0), Offset(3, 0)]), // I-kształt
    Tetromino([Offset(0, 0), Offset(0, 1), Offset(1, 0), Offset(1, 1)]), // O-kształt
    Tetromino([Offset(0, 0), Offset(1, 0), Offset(1, 1), Offset(2, 1)]), // S-kształt
    Tetromino([Offset(0, 1), Offset(1, 0), Offset(1, 1), Offset(2, 0)]), // Z-kształt
    Tetromino([Offset(0, 0), Offset(0, 1), Offset(0, 2), Offset(1, 0)]), // L-kształt
    Tetromino([Offset(0, 0), Offset(0, 1), Offset(0, 2), Offset(1, 2)]), // J-kształt
    Tetromino([Offset(0, 0), Offset(0, 1), Offset(1, 0), Offset(1, 1)]), // T-kształt
  ];

  Tetromino rotate() {
    List<Offset> rotatedShape = [];
    for (Offset offset in shape) {
      rotatedShape.add(Offset(-offset.dy, offset.dx));
    }
    return Tetromino(rotatedShape);
  }
}

class TetrisGame extends StatefulWidget {
  @override
  _TetrisGameState createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  late Tetromino currentTetromino;
  late Tetromino nextTetromino;
  Offset currentPosition = Offset(3, 0);
  GameBoard gameBoard = GameBoard();
  int score = 0;
  late Timer _timer;
  bool isGameOver = false;
  bool isGameStarted = false;

  @override
  void initState() {
    super.initState();
    nextTetromino = Tetromino.all[Random().nextInt(Tetromino.all.length)];
    _generateNewTetromino();
  }

  void _startGame() {
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      score = 0;
      gameBoard = GameBoard();
      _generateNewTetromino();
      _timer = Timer.periodic(Duration(milliseconds: 500), (_) => _tick());
    });
  }

  void _restartGame() {
    setState(() {
      isGameOver = false;
      score = 0;
      gameBoard = GameBoard();
      _startGame();
    });
  }

  void _generateNewTetromino() {
    currentTetromino = nextTetromino;
    nextTetromino = Tetromino.all[Random().nextInt(Tetromino.all.length)];
    currentPosition = Offset(3, 0);
  }

  void _moveLeft() {
    if (_canMove(-1, 0)) {
      setState(() {
        currentPosition += Offset(-1, 0);
      });
    }
  }

  void _moveRight() {
    if (_canMove(1, 0)) {
      setState(() {
        currentPosition += Offset(1, 0);
      });
    }
  }

  void _rotate() {
    Tetromino rotatedTetromino = currentTetromino.rotate();
    if (_canMove(0, 0, rotatedTetromino)) {
      setState(() {
        currentTetromino = rotatedTetromino;
      });
    }
  }

  void _tick() {
    if (_canMove(0, 1)) {
      setState(() {
        currentPosition += Offset(0, 1);
      });
    } else {
      _lockTetromino();
      _clearFullLines();
      if (gameBoard.isGameOver()) {
        _timer.cancel();
        setState(() {
          isGameOver = true;
        });
      } else {
        _generateNewTetromino();
      }
    }
  }

  void _lockTetromino() {
    for (Offset offset in currentTetromino.shape) {
      int x = currentPosition.dx.toInt() + offset.dx.toInt();
      int y = currentPosition.dy.toInt() + offset.dy.toInt();
      gameBoard.board[y][x] = true;
    }
  }

  void _clearFullLines() {
    int linesCleared = 0;
    for (int y = GameBoard.height - 1; y >= 0; y--) {
      if (gameBoard.isLineFull(y)) {
        gameBoard.clearLine(y);
        gameBoard.shiftDown(y);
        linesCleared++;
        y++;
      }
    }
    if (linesCleared > 0) {
      setState(() {
        score += 100 * linesCleared;
      });
    }
  }

  bool _canMove(int dx, int dy, [Tetromino? tetromino]) {
    tetromino ??= currentTetromino;
    for (Offset offset in tetromino.shape) {
      int x = currentPosition.dx.toInt() + offset.dx.toInt() + dx;
      int y = currentPosition.dy.toInt() + offset.dy.toInt() + dy;
      if (x < 0 || x >= GameBoard.width || y >= GameBoard.height || gameBoard.board[y][x]) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tetris'),
      ),
      backgroundColor: Color.fromRGBO(119, 141, 169, 100),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isGameStarted)
              Column(
                children: [
                  Text('Score: $score', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70, width: 2.0),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        child: CustomPaint(
                          painter: NextTetrominoPainter(nextTetromino),
                        ),
                      ),
                      SizedBox(width: 25),
                      Container(
                        width: GameBoard.width * 28.0,
                        height: GameBoard.height * 28.0,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70, width: 2.0),
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        ),
                        child: CustomPaint(
                          painter: TetrisPainter(gameBoard, currentTetromino, currentPosition),
                        ),
                      ),
                    ],
                  ),
                  if (isGameOver)
                    Column(
                      children: [
                        SizedBox(height: 20),
                        Text('Game Over', style: TextStyle(fontSize: 24, color: Colors.red)),
                        ElevatedButton(
                          onPressed: _restartGame,
                          child: Text('Restart'),
                        ),
                        SizedBox(height: 50),
                      ],
                    ),
                ],
              )
            else
              StartScreen(startGame: _startGame),
          ],
        ),
      ),
      floatingActionButton: isGameStarted && !isGameOver
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: _moveLeft,
            child: Icon(Icons.arrow_left),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _moveRight,
            child: Icon(Icons.arrow_right),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _rotate,
            child: Icon(Icons.rotate_right),
          ),
          SizedBox(width: 16),
          FloatingActionButton(
            onPressed: _tick,
            child: Icon(Icons.arrow_downward),
          ),
        ],
      )
          : null,
    );
  }
}

class StartScreen extends StatelessWidget {
  final VoidCallback startGame;

  StartScreen({required this.startGame});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Tetris', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: startGame,
            child: Text('Start Game', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }
}

class TetrisPainter extends CustomPainter {
  final GameBoard gameBoard;
  final Tetromino currentTetromino;
  final Offset currentPosition;

  TetrisPainter(this.gameBoard, this.currentTetromino, this.currentPosition);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / GameBoard.width;
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    // Rysowanie planszy
    for (int y = 0; y < GameBoard.height; y++) {
      for (int x = 0; x < GameBoard.width; x++) {
        if (gameBoard.board[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            paint,
          );
        }
      }
    }

    // Rysowanie aktualnego bloku
    paint.color = Colors.blue;
    for (Offset offset in currentTetromino.shape) {
      int x = (currentPosition.dx + offset.dx).toInt();
      int y = (currentPosition.dy + offset.dy).toInt();
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
        paint,
      );
    }

    // Rysowanie siatki
    paint.color = Colors.grey.withOpacity(0.5);
    paint.strokeWidth = 1.0;
    for (int x = 0; x <= GameBoard.width; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, GameBoard.height * cellSize),
        paint,
      );
    }
    for (int y = 0; y <= GameBoard.height; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(GameBoard.width * cellSize, y * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TetrisPainter oldDelegate) {
    return oldDelegate.gameBoard != gameBoard ||
        oldDelegate.currentTetromino != currentTetromino ||
        oldDelegate.currentPosition != currentPosition;
  }
}

class NextTetrominoPainter extends CustomPainter {
  final Tetromino nextTetromino;

  NextTetrominoPainter(this.nextTetromino);

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 4;
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Rysowanie następnego bloku
    for (Offset offset in nextTetromino.shape) {
      int x = (offset.dx).toInt(); // Centruj blok w oknie
      int y = (offset.dy + 1).toInt(); // Centruj blok w oknie
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
        paint,
      );
    }

    // Rysowanie siatki
    paint.color = Colors.grey.withOpacity(0.5);
    paint.strokeWidth = 1.0;
    for (int x = 0; x <= 4; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, 4 * cellSize),
        paint,
      );
    }
    for (int y = 0; y <= 4; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(4 * cellSize, y * cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NextTetrominoPainter oldDelegate) {
    return oldDelegate.nextTetromino != nextTetromino;
  }
}
