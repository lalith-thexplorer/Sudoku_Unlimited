
import 'package:flutter/material.dart';
import 'dart:async';
import 'sudoku_solver.dart';

class GameScreen extends StatefulWidget {
  final List<List<int>> board;
  final String difficulty;
  
  const GameScreen({
    Key? key, 
    required this.board,
    required this.difficulty,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late List<List<int>> currentBoard;
  late List<List<int>> solvedBoard;
  late List<List<bool>> isOriginalCell;
  int? selectedRow;
  int? selectedCol;
  late Timer _timer;
  int _seconds = 0;
  List<Map<String, dynamic>> _undoStack = [];
  bool _isInitialized = false;
  late int _lives;
  late int _remainingHints;
  
  Set<String> highlightedSections = {};
  Set<String> incorrectCells = {};
  Timer? _highlightTimer;
  Timer? _incorrectTimer;

  @override
  void initState() {
    super.initState();
    currentBoard = List.generate(9, (i) => List.from(widget.board[i]));
    solvedBoard = List.generate(9, (i) => List.from(widget.board[i]));
    SudokuSolver.solveSudoku(solvedBoard);
    
    isOriginalCell = List.generate(
      9,
      (i) => List.generate(9, (j) => widget.board[i][j] != 0),
    );
    
   final bool isEasy = widget.difficulty.toLowerCase() == 'easy';
    _lives = isEasy ? 5 : 3;
    _remainingHints = isEasy ? 10 : 5; // Set initial hints based on difficulty
    
    _startTimer();
    _isInitialized = true;
  }

  @override
  void dispose() {
    _timer.cancel();
    _highlightTimer?.cancel();
    _incorrectTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _selectCell(int row, int col) {
    if (isOriginalCell[row][col]) return;
    setState(() {
      selectedRow = selectedRow == row && selectedCol == col ? null : row;
      selectedCol = selectedRow == null ? null : col;
    });
  }

  void _highlightIncorrectCell(int row, int col) {
    setState(() {
      incorrectCells.add('${row}_$col');
    });

    _incorrectTimer?.cancel();
    _incorrectTimer = Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          incorrectCells.remove('${row}_$col');
        });
      }
    });
  }

  void _onNumberSelected(int number) {
    if (selectedRow == null || selectedCol == null) return;
    if (isOriginalCell[selectedRow!][selectedCol!]) return;

    setState(() {
      _undoStack.add({
        'row': selectedRow,
        'col': selectedCol,
        'value': currentBoard[selectedRow!][selectedCol!],
      });

      currentBoard[selectedRow!][selectedCol!] = number;

      // Only check correctness and decrease lives if not clearing the cell
      if (number != 0) {
        if (currentBoard[selectedRow!][selectedCol!] == solvedBoard[selectedRow!][selectedCol!]) {
          _checkCompletedSections(selectedRow!, selectedCol!);
          _checkWinCondition();
        } else {
          _lives--;
          _highlightIncorrectCell(selectedRow!, selectedCol!);
          
          if (_lives <= 0) {
            _gameOver();
          }
        }
      }
    });
  }

  void _undo() {
    if (_undoStack.isEmpty) return;

    setState(() {
      var lastMove = _undoStack.removeLast();
      currentBoard[lastMove['row']][lastMove['col']] = lastMove['value'];
      incorrectCells.remove('${lastMove['row']}_${lastMove['col']}');
    });
  }

  void _gameOver() {
  _timer.cancel();
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      backgroundColor: Color(0xFF424242), // Dark background
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Game Over',
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Out of lives, Try again!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Back to Menu',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  bool _isRowCompleted(int row) {
    Set<int> numbers = Set();
    for (int i = 0; i < 9; i++) {
      if (currentBoard[row][i] == 0) return false;
      if (!numbers.add(currentBoard[row][i])) return false;
    }
    return numbers.length == 9;
  }

  bool _isColumnCompleted(int col) {
    Set<int> numbers = Set();
    for (int i = 0; i < 9; i++) {
      if (currentBoard[i][col] == 0) return false;
      if (!numbers.add(currentBoard[i][col])) return false;
    }
    return numbers.length == 9;
  }

  bool _isBoxCompleted(int boxRow, int boxCol) {
    Set<int> numbers = Set();
    for (int row = boxRow * 3; row < (boxRow + 1) * 3; row++) {
      for (int col = boxCol * 3; col < (boxCol + 1) * 3; col++) {
        if (currentBoard[row][col] == 0) return false;
        if (!numbers.add(currentBoard[row][col])) return false;
      }
    }
    return numbers.length == 9;
  }

  void _checkWinCondition() {
  bool isSolved = true;
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      if (currentBoard[i][j] != solvedBoard[i][j]) {
        isSolved = false;
        break;
      }
    }
    if (!isSolved) break;
  }

  if (isSolved) {
    _timer.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: Color(0xFF1A237E), // Dark blue background
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.yellow,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Congratulations!',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'You solved the puzzle in ${_formatTime(_seconds)} minutes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back to Menu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

 
  void _showHint() {
    if (selectedRow == null || selectedCol == null) return;
    if (isOriginalCell[selectedRow!][selectedCol!]) return;
    if (_remainingHints <= 0) {
      // Show a message when no hints are remaining
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hints remaining!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      currentBoard[selectedRow!][selectedCol!] = solvedBoard[selectedRow!][selectedCol!];
      _remainingHints--; // Decrease remaining hints
      _checkCompletedSections(selectedRow!, selectedCol!);
      _checkWinCondition();
    });
  }

  void _checkCompletedSections(int row, int col) {
    if (_isRowCompleted(row)) {
      _highlightSection('row_$row');
    }
    
    if (_isColumnCompleted(col)) {
      _highlightSection('col_$col');
    }
    
    int boxRow = row ~/ 3;
    int boxCol = col ~/ 3;
    if (_isBoxCompleted(boxRow, boxCol)) {
      _highlightSection('box_${boxRow}_${boxCol}');
    }
  }

  void _highlightSection(String sectionId) {
    setState(() {
      highlightedSections.add(sectionId);
    });

    Timer(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          highlightedSections.remove(sectionId);
        });
      }
    });
  }

  
  Widget _buildCell(int row, int col) {
    bool isSelected = selectedRow == row && selectedCol == col;
    bool isInSelectedRow = selectedRow == row;
    bool isInSelectedCol = selectedCol == col;
    bool isInSelectedBox = selectedRow != null && selectedCol != null &&
        (row ~/ 3 == selectedRow! ~/ 3 && col ~/ 3 == selectedCol! ~/ 3);
    bool isIncorrect = incorrectCells.contains('${row}_$col');
    bool isHighlighted = highlightedSections.contains('row_$row') ||
                        highlightedSections.contains('col_$col') ||
                        highlightedSections.contains('box_${row ~/ 3}_${col ~/ 3}');

    Color getCellColor() {
      if (isIncorrect) return Colors.red.withOpacity(0.3);
      if (isHighlighted) return Colors.yellow.withOpacity(0.5);
      if (isSelected) return Colors.yellow.withOpacity(0.3);
      if (isInSelectedRow || isInSelectedCol) return Colors.yellow.withOpacity(0.1);
      if (isInSelectedBox) return Colors.yellow.withOpacity(0.05);
      return isOriginalCell[row][col] ? Color(0xFF616161) : Color(0xFF424242);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: col == 0 ? 2.0 : (col % 3 == 0 ? 2.0 : 1.0),
            color: col == 0 ? Colors.yellow : (col % 3 == 0 ? Colors.yellow : Colors.grey),
          ),
          top: BorderSide(
            width: row == 0 ? 2.0 : (row % 3 == 0 ? 2.0 : 1.0),
            color: row == 0 ? Colors.yellow : (row % 3 == 0 ? Colors.yellow : Colors.grey),
          ),
          right: BorderSide(
            width: col == 8 ? 2.0 : 0.0,
            color: col == 8 ? Colors.yellow : Colors.grey,
          ),
          bottom: BorderSide(
            width: row == 8 ? 2.0 : 0.0,
            color: row == 8 ? Colors.yellow : Colors.grey,
          ),
        ),
        color: getCellColor(),
      ),
      child: Center(
        child: Text(
          currentBoard[row][col] == 0 ? '' : currentBoard[row][col].toString(),
          style: TextStyle(
            color: isIncorrect ? Colors.red : 
                   isOriginalCell[row][col] ? Colors.white : Colors.yellow,
            fontSize: 20, // Reduced font size
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
   @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return Container();

    return Scaffold(
      backgroundColor: Color(0xFF212121), // Dark background for the scaffold
      appBar: AppBar(
        title: Text(
          'Solve Sudoku',
          style: TextStyle(
            color: Colors.yellow, // Yellow text to match game theme
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF424242), // Dark background for app bar
        elevation: 8, // Add shadow
        iconTheme: IconThemeData(color: Colors.yellow), // Yellow back button
        actions: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF616161), // Slightly lighter background for stats
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.yellow),
                      SizedBox(width: 4),
                      Text(
                        'x $_remainingHints',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF616161),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'x $_lives',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF616161),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatTime(_seconds),
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3, // Adjust this value to control board size
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
                    maxHeight: MediaQuery.of(context).size.width * 0.9, // Keep it square
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
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
                        return GestureDetector(
                          onTap: () => _selectCell(row, col),
                          child: _buildCell(row, col),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  height: 70,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(9, (index) {
                        return Padding(
                          padding: EdgeInsets.all(2.0),
                          child: ElevatedButton(
                            onPressed: () => _onNumberSelected(index + 1),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(fontSize: 20),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(16),
                              shape: CircleBorder(),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _undo,
                        icon: Icon(Icons.undo),
                        label: Text('Undo'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _onNumberSelected(0),
                        icon: Icon(Icons.clear),
                        label: Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showHint,
                        icon: Icon(Icons.lightbulb_outline),
                        label: Text('Hint'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}