import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'sudoku_solver.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(SudokuApp());
}

class SudokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sudoku Game',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Color(0xFF1A1A1A),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(color: Colors.white, fontSize: 24),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black,
            backgroundColor: Colors.yellow,
            elevation: 8,
            shadowColor: Colors.yellow.withOpacity(0.5),
          ),
        ),
      ),
      home: SudokuHome(),
    );
  }
}

class SudokuHome extends StatefulWidget {
  @override
  _SudokuHomeState createState() => _SudokuHomeState();
}

class _SudokuHomeState extends State<SudokuHome> {
  final int size = 9;
  bool isNumbersVisible = false;
  bool isDifficultySelected = false;
  Color boxShadowColor = Colors.yellow;
  late List<List<int>> board;
  String selectedDifficulty = '';

  @override
  void initState() {
    super.initState();
    board = List.generate(size, (_) => List.generate(size, (_) => 0));
  }

  void generateSudokuBoard() {
    if (!isDifficultySelected) return;
    
    // Generate a complete solution
    board = SudokuSolver.generateUniquePuzzle(selectedDifficulty);
    
    // Remove numbers based on difficulty
    int cellsToRemove = selectedDifficulty == 'easy' ? 40 : 50; // Easy: 41 numbers shown, Hard: 31 numbers shown
    
    int removedCount = 0;
    while (removedCount < cellsToRemove) {
      int row = (DateTime.now().millisecondsSinceEpoch % 9).toInt();
      int col = ((DateTime.now().millisecondsSinceEpoch / 9) % 9).toInt();
      
      if (board[row][col] != 0) {
        board[row][col] = 0;
        removedCount++;
      }
    }
  }

  Widget buildDifficultySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF424242),
        border: Border.all(color: const Color.fromARGB(255, 185, 185, 185), width: 2),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: boxShadowColor.withOpacity(0.8),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Difficulty: ',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDifficulty = 'easy';
                isDifficultySelected = true;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: selectedDifficulty == 'easy' ? const Color.fromARGB(255, 56, 255, 63) : Color(0xFF424242),
                border: Border.all(
                  color: selectedDifficulty == 'easy' ? const Color.fromARGB(255, 56, 255, 63) : Colors.grey,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: selectedDifficulty == 'easy' ? const Color.fromARGB(255, 56, 255, 63).withOpacity(0.5) : Colors.transparent,
                    spreadRadius: 5,
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'Easy',
                style: TextStyle(
                  color: selectedDifficulty == 'easy' ? Colors.black : Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(width: 20),
          GestureDetector(
            onTap: () {
              setState(() {
                selectedDifficulty = 'hard';
                isDifficultySelected = true;
              });
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: selectedDifficulty == 'hard' ? Colors.red : Color(0xFF424242),
                border: Border.all(
                  color: selectedDifficulty == 'hard' ? Colors.red : Colors.grey,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: selectedDifficulty == 'hard' ? Colors.red.withOpacity(0.5) : Colors.transparent,
                    spreadRadius: 5,
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                'Hard',
                style: TextStyle(
                  color: selectedDifficulty == 'hard' ? Colors.black : Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
void shuffleBoard() async {
  if (!isDifficultySelected) {
    setState(() {
      boxShadowColor = Colors.red;
    });
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        boxShadowColor = Colors.yellow;
      });
    });
    return;
  }

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
        ),
      );
    },
  );

  try {
    // Generate board in a separate isolate
    final newBoard = await compute(SudokuSolver.generateUniquePuzzle, selectedDifficulty);
    
    // Update state with new board
    setState(() {
      board = newBoard;
      isNumbersVisible = true;
    });
  } catch (e) {
    print('Error generating puzzle: $e');
  } finally {
    // Hide loading indicator
    Navigator.of(context).pop();
  }
}

  Widget buildBoard() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildDifficultySelector(),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.yellow, width: 4),
            ),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
                childAspectRatio: 1.0,
              ),
              itemCount: 81,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                int row = index ~/ 9;
                int col = index % 9;
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        width: (col + 1) % 3 == 0 ? 2.0 : 1.0,
                        color: (col + 1) % 3 == 0 ? Colors.yellow : Colors.grey,
                      ),
                      bottom: BorderSide(
                        width: (row + 1) % 3 == 0 ? 2.0 : 1.0,
                        color: (row + 1) % 3 == 0 ? Colors.yellow : Colors.grey,
                      ),
                    ),
                    color: board[row][col] == 0 ? Color(0xFF424242) : Color(0xFF616161),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isNumbersVisible && board[row][col] != 0 ? board[row][col].toString() : '',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: shuffleBoard,
                child: Text('Shuffle Board'),
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  minimumSize: Size(50, 50),
                  textStyle: TextStyle(fontSize: 18),
                  shadowColor: Colors.yellow,
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (!isDifficultySelected) {
                    setState(() {
                      boxShadowColor = Colors.red;
                    });
                    Future.delayed(Duration(milliseconds: 500), () {
                      setState(() {
                        boxShadowColor = Colors.yellow;
                      });
                    });
                    return;
                  }
                  if (isNumbersVisible) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GameScreen(board: board, difficulty: '',),
                      ),
                    );
                  }
                },
                child: Text('Start Game!'),
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  minimumSize: Size(50, 50),
                  textStyle: TextStyle(fontSize: 18),
                  shadowColor: Colors.yellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text('Sudoku Game'),
  backgroundColor: Color(0xFF1A1A1A),  // Match scaffold background
  elevation: 8,
  shadowColor: Colors.white.withOpacity(0.5),  // Match button shadow style
  titleTextStyle: TextStyle(
    color: Colors.yellow,  // Match accent color
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),
      body: Center(
        child: buildBoard(),
      ),
    );
  }
}