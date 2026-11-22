import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

enum ChessDifficulty {
  easy('Mudah', 'Cocok untuk pemula, sering membuat langkah santai.'),
  medium('Sedang', 'Menghitung 2 langkah ke depan dan menjaga petak tengah.'),
  hard('Susah', 'Minimax Alpha-Beta 3 langkah dengan pemangkasan agresif.');

  const ChessDifficulty(this.label, this.description);

  final String label;
  final String description;
}

class ChessBot {
  const ChessBot._();

  static const int pawnVal = 100;
  static const int knightVal = 320;
  static const int bishopVal = 330;
  static const int rookVal = 500;
  static const int queenVal = 900;
  static const int kingVal = 20000;

  static int pieceValue(chess.PieceType? type) {
    if (type == null) return 0;
    switch (type) {
      case chess.PieceType.PAWN:
        return pawnVal;
      case chess.PieceType.KNIGHT:
        return knightVal;
      case chess.PieceType.BISHOP:
        return bishopVal;
      case chess.PieceType.ROOK:
        return rookVal;
      case chess.PieceType.QUEEN:
        return queenVal;
      case chess.PieceType.KING:
        return kingVal;
      default:
        return 0;
    }
  }

  /// Evaluasi posisi dari sudut pandang Hitam (Bot)
  static int evaluateBoard(chess.Chess game) {
    if (game.in_checkmate) {
      return game.turn == chess.Color.BLACK ? -100000 : 100000;
    }
    if (game.in_draw) return 0;

    int score = 0;
    for (var i = 0; i < 128; i++) {
      if ((i & 0x88) != 0) continue;
      final piece = game.board[i];
      if (piece == null) continue;

      int val = pieceValue(piece.type);

      // Bonus petak tengah (d4, e4, d5, e5) dan sekitarnya
      if (i == 51 || i == 52 || i == 67 || i == 68) {
        val += 30;
      } else if (i == 34 ||
          i == 35 ||
          i == 36 ||
          i == 37 ||
          i == 50 ||
          i == 53 ||
          i == 66 ||
          i == 69 ||
          i == 82 ||
          i == 83 ||
          i == 84 ||
          i == 85) {
        val += 10;
      }

      if (piece.color == chess.Color.BLACK) {
        score += val;
      } else {
        score -= val;
      }
    }
    return score;
  }

  /// Mencari langkah terbaik untuk bot sesuai tingkat kesulitan
  static Future<Map<String, String?>?> findBestMove(
    chess.Chess game,
    ChessDifficulty difficulty,
  ) async {
    if (game.game_over || game.turn != chess.Color.BLACK) {
      return null;
    }

    switch (difficulty) {
      case ChessDifficulty.easy:
        return _findEasyMove(game);
      case ChessDifficulty.medium:
        return _findMediumMove(game);
      case ChessDifficulty.hard:
        return compute(_hardBotCompute, game.fen);
    }
  }

  static Map<String, String?>? _findEasyMove(chess.Chess game) {
    final moves = game.moves({'verbose': true});
    if (moves.isEmpty) return null;

    final random = Random();
    final weightedMoves = <Map<String, dynamic>>[];

    for (final rawMove in moves) {
      if (rawMove is! Map) continue;
      final m = Map<String, dynamic>.from(rawMove);
      final hasCapture =
          m['captured'] != null || (m['flags']?.toString().contains('c') ?? false);
      final weight = hasCapture ? 4 : 1;
      for (var i = 0; i < weight; i++) {
        weightedMoves.add(m);
      }
    }

    if (weightedMoves.isEmpty) return null;
    final selected = weightedMoves[random.nextInt(weightedMoves.length)];
    return {
      'from': selected['from']?.toString(),
      'to': selected['to']?.toString(),
      'promotion': selected['promotion']?.toString() ?? 'q',
    };
  }

  static Map<String, String?>? _findMediumMove(chess.Chess game) {
    final moves = game.generate_moves();
    if (moves.isEmpty) return null;

    chess.Move? bestMove;
    int bestScore = -9999999;

    for (final move in moves) {
      game.make_move(move);

      int worstForBlack = 9999999;
      final whiteMoves = game.generate_moves();
      if (whiteMoves.isEmpty) {
        if (game.in_checkmate) {
          worstForBlack = 100000;
        } else {
          worstForBlack = 0;
        }
      } else {
        for (final wMove in whiteMoves) {
          game.make_move(wMove);
          final eval = evaluateBoard(game);
          game.undo_move();
          if (eval < worstForBlack) {
            worstForBlack = eval;
          }
        }
      }

      game.undo_move();

      if (worstForBlack > bestScore) {
        bestScore = worstForBlack;
        bestMove = move;
      }
    }

    if (bestMove == null) return null;
    return {
      'from': bestMove.fromAlgebraic,
      'to': bestMove.toAlgebraic,
      'promotion': bestMove.promotion?.name ?? 'q',
    };
  }
}

/// Fungsi top-level untuk isolate `compute()` pada level Hard
Map<String, String?>? _hardBotCompute(String fen) {
  final game = chess.Chess.fromFEN(fen);
  final moves = _orderMoves(game.generate_moves());
  if (moves.isEmpty) return null;

  chess.Move? bestMove;
  int bestScore = -9999999;
  int alpha = -9999999;
  const beta = 9999999;

  for (final move in moves) {
    game.make_move(move);
    final eval = _alphaBeta(game, 2, alpha, beta, false);
    game.undo_move();

    if (eval > bestScore) {
      bestScore = eval;
      bestMove = move;
    }
    if (eval > alpha) {
      alpha = eval;
    }
  }

  if (bestMove == null) return null;
  return {
    'from': bestMove.fromAlgebraic,
    'to': bestMove.toAlgebraic,
    'promotion': bestMove.promotion?.name ?? 'q',
  };
}

int _alphaBeta(
  chess.Chess game,
  int depth,
  int alpha,
  int beta,
  bool isMaximizing,
) {
  if (depth == 0 || game.game_over) {
    return ChessBot.evaluateBoard(game);
  }

  final moves = _orderMoves(game.generate_moves());
  if (moves.isEmpty) {
    return ChessBot.evaluateBoard(game);
  }

  if (isMaximizing) {
    int maxEval = -9999999;
    for (final move in moves) {
      game.make_move(move);
      final eval = _alphaBeta(game, depth - 1, alpha, beta, false);
      game.undo_move();
      if (eval > maxEval) maxEval = eval;
      if (eval > alpha) alpha = eval;
      if (beta <= alpha) break;
    }
    return maxEval;
  } else {
    int minEval = 9999999;
    for (final move in moves) {
      game.make_move(move);
      final eval = _alphaBeta(game, depth - 1, alpha, beta, true);
      game.undo_move();
      if (eval < minEval) minEval = eval;
      if (eval < beta) beta = eval;
      if (beta <= alpha) break;
    }
    return minEval;
  }
}

List<chess.Move> _orderMoves(List<chess.Move> moves) {
  moves.sort((a, b) {
    int scoreA = 0;
    int scoreB = 0;
    if (a.captured != null) {
      scoreA +=
          ChessBot.pieceValue(a.captured) * 10 - ChessBot.pieceValue(a.piece);
    }
    if (b.captured != null) {
      scoreB +=
          ChessBot.pieceValue(b.captured) * 10 - ChessBot.pieceValue(b.piece);
    }
    if ((a.flags & chess.Chess.BITS_PROMOTION) != 0) scoreA += 800;
    if ((b.flags & chess.Chess.BITS_PROMOTION) != 0) scoreB += 800;
    return scoreB.compareTo(scoreA);
  });
  return moves;
}
