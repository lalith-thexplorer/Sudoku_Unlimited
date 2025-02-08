import 'dart:math';
import 'dart:isolate';

class SudokuSolver {
  static final Random _random = Random();
  static const int maxAttempts = 100; // Maximum attempts to find a unique solution

  static List<List<int>> generateUniquePuzzle(String difficulty) {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Generate a complete board
      List<List<int>> board = _generateFullBoard();
      List<List<int>> puzzle = List.generate(9, (i) => List.from(board[i]));
      
      int cellsToRemove = difficulty == 'easy' ? 40 : 50;
      List<int> positions = List.generate(81, (i) => i);
      positions.shuffle(_random);
      
      int removed = 0;
      bool isUnique = true;
      
      for (int i = 0; i < positions.length && removed < cellsToRemove; i++) {
        int row = positions[i] ~/ 9;
        int col = positions[i] % 9;
        
        if (puzzle[row][col] == 0) continue;
        
        int temp = puzzle[row][col];
        puzzle[row][col] = 0;
        
        // Check if the puzzle still has a unique solution
        if (!_hasUniqueSolution(puzzle)) {
          puzzle[row][col] = temp; // Restore the number
          isUnique = false;
        } else {
          removed++;
        }
      }
      
      // If we removed enough cells and maintained uniqueness, return the puzzle
      if (removed >= cellsToRemove - 5) { // Allow slight variation in difficulty
        return puzzle;
      }
    }
    
    // If we couldn't generate a unique puzzle after max attempts,
    // generate a simpler puzzle as fallback
    return _generateSimplePuzzle(difficulty);
  }

  static bool _hasUniqueSolution(List<List<int>> board) {
    List<List<int>> tempBoard = List.generate(9, (i) => List.from(board[i]));
    int solutions = 0;
    
    bool solve(int position) {
      if (solutions > 1) return false; // Stop if we found multiple solutions
      
      if (position == 81) {
        solutions++;
        return solutions == 1; // Continue only if this is the first solution
      }
      
      int row = position ~/ 9;
      int col = position % 9;
      
      if (tempBoard[row][col] != 0) {
        return solve(position + 1);
      }
      
      for (int num = 1; num <= 9; num++) {
        if (isValid(tempBoard, row, col, num)) {
          tempBoard[row][col] = num;
          if (!solve(position + 1)) return false;
          tempBoard[row][col] = 0;
        }
      }
      
      return solutions == 1;
    }
    
    solve(0);
    return solutions == 1;
  }

  static List<List<int>> _generateSimplePuzzle(String difficulty) {
    List<List<int>> board = _generateFullBoard();
    int cellsToRemove = difficulty == 'easy' ? 35 : 45; // Remove fewer cells for fallback
    
    List<int> positions = List.generate(81, (i) => i);
    positions.shuffle(_random);
    
    for (int i = 0; i < cellsToRemove; i++) {
      int row = positions[i] ~/ 9;
      int col = positions[i] % 9;
      board[row][col] = 0;
    }
    
    return board;
  }

  static List<List<int>> _generateFullBoard() {
    List<List<int>> board = List.generate(9, (_) => List.filled(9, 0));
    _fillDiagonal(board);
    solveSudoku(board);
    return board;
  }

  static void _fillDiagonal(List<List<int>> board) {
    for (int box = 0; box < 9; box += 3) {
      _fillBox(board, box, box);
    }
  }

  static void _fillBox(List<List<int>> board, int row, int col) {
    List<int> numbers = List.generate(9, (i) => i + 1)..shuffle(_random);
    int index = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        board[row + i][col + j] = numbers[index++];
      }
    }
  }

  static bool solveSudoku(List<List<int>> board) {
    int row = -1, col = -1;
    bool isEmpty = false;
    
    // Find empty cell
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (board[i][j] == 0) {
          row = i;
          col = j;
          isEmpty = true;
          break;
        }
      }
      if (isEmpty) break;
    }

    if (!isEmpty) return true;

    List<int> numbers = List.generate(9, (i) => i + 1);
    numbers.shuffle(_random);
    
    for (int num in numbers) {
      if (isValid(board, row, col, num)) {
        board[row][col] = num;
        if (solveSudoku(board)) return true;
        board[row][col] = 0;
      }
    }
    return false;
  }

  static bool isValid(List<List<int>> board, int row, int col, int number) {
    // Check row
    for (int x = 0; x < 9; x++) {
      if (x != col && board[row][x] == number) return false;
    }
    
    // Check column
    for (int x = 0; x < 9; x++) {
      if (x != row && board[x][col] == number) return false;
    }

    // Check 3x3 box
    int startRow = row - row % 3, startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if ((i + startRow != row || j + startCol != col) && 
            board[i + startRow][j + startCol] == number) {
          return false;
        }
      }
    }

    return true;
  }
}