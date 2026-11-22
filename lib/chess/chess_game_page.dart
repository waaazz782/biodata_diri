import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import 'chess_bot.dart';
import 'chess_pieces.dart';

class ChessGamePage extends StatefulWidget {
  const ChessGamePage({
    required this.difficulty,
    super.key,
  });

  final ChessDifficulty difficulty;

  @override
  State<ChessGamePage> createState() => _ChessGamePageState();
}

class _ChessGamePageState extends State<ChessGamePage> {
  static const Color creamBg = Color(0xFFFAF6F0);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE5DEC9);
  static const Color navyColor = Color(0xFF0F172A);
  static const Color slateText = Color(0xFF64748B);
  static const Color lightSquare = Color(0xFFF3ECE1);
  static const Color darkSquare = Color(0xFF1E293B);
  static const Color sageGreen = Color(0xFF10B981);
  static const Color amberAccent = Color(0xFFF59E0B);

  late final chess.Chess _game;
  String? _selectedSquare;
  Set<String> _validDestinations = {};
  String? _lastMoveFrom;
  String? _lastMoveTo;
  bool _isBotThinking = false;

  @override
  void initState() {
    super.initState();
    _game = chess.Chess();
  }

  bool get _isPlayerTurn => _game.turn == chess.Color.WHITE && !_isBotThinking;

  bool get _canUndo =>
      !_isBotThinking && _game.history.isNotEmpty;

  Map<chess.PieceType, int> _getCapturedPieces(chess.Color color) {
    // Menghitung bidak milik 'color' yang sudah dimakan
    final standardCounts = <chess.PieceType, int>{
      chess.PieceType.PAWN: 8,
      chess.PieceType.KNIGHT: 2,
      chess.PieceType.BISHOP: 2,
      chess.PieceType.ROOK: 2,
      chess.PieceType.QUEEN: 1,
    };

    final currentCounts = <chess.PieceType, int>{
      chess.PieceType.PAWN: 0,
      chess.PieceType.KNIGHT: 0,
      chess.PieceType.BISHOP: 0,
      chess.PieceType.ROOK: 0,
      chess.PieceType.QUEEN: 0,
    };

    for (var i = 0; i < 128; i++) {
      if ((i & 0x88) != 0) continue;
      final piece = _game.board[i];
      if (piece != null && piece.color == color) {
        if (currentCounts.containsKey(piece.type)) {
          currentCounts[piece.type] = currentCounts[piece.type]! + 1;
        }
      }
    }

    final captured = <chess.PieceType, int>{};
    for (final entry in standardCounts.entries) {
      final diff = entry.value - (currentCounts[entry.key] ?? 0);
      if (diff > 0) {
        captured[entry.key] = diff;
      }
    }
    return captured;
  }

  void _onSquareTap(String square) {
    if (!_isPlayerTurn) return;

    final clickedPiece = _game.get(square);

    // Jika sudah ada bidak terpilih dan petak tujuan yang diklik sah
    if (_selectedSquare != null && _validDestinations.contains(square)) {
      _executePlayerMove(_selectedSquare!, square);
      return;
    }

    // Jika mengklik bidak sendiri (Putih)
    if (clickedPiece != null && clickedPiece.color == chess.Color.WHITE) {
      setState(() {
        _selectedSquare = square;
        final moves = _game.generate_moves({'square': square});
        _validDestinations = moves.map((m) => m.toAlgebraic).toSet();
      });
      return;
    }

    // Klik di luar langkah sah
    setState(() {
      _selectedSquare = null;
      _validDestinations.clear();
    });
  }

  Future<void> _executePlayerMove(String from, String to) async {
    final moves = _game.generate_moves({'square': from});
    final isPromotion = moves.any((m) => m.toAlgebraic == to && m.promotion != null);

    String promotionChoice = 'q';
    if (isPromotion) {
      final chosen = await _showPromotionDialog();
      if (chosen == null) return;
      promotionChoice = chosen;
    }

    final moveSuccess = _game.move({
      'from': from,
      'to': to,
      'promotion': promotionChoice,
    });

    if (!moveSuccess) return;

    setState(() {
      _lastMoveFrom = from;
      _lastMoveTo = to;
      _selectedSquare = null;
      _validDestinations.clear();
    });

    if (_checkGameOver()) return;

    // Giliran Bot
    _triggerBotMove();
  }

  Future<String?> _showPromotionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
        title: const Text(
          'Pilih Promosi Pion',
          style: TextStyle(
            color: navyColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _promotionOption(ctx, chess.PieceType.QUEEN, 'q', 'Menteri'),
            _promotionOption(ctx, chess.PieceType.ROOK, 'r', 'Benteng'),
            _promotionOption(ctx, chess.PieceType.BISHOP, 'b', 'Gajah'),
            _promotionOption(ctx, chess.PieceType.KNIGHT, 'n', 'Kuda'),
          ],
        ),
      ),
    );
  }

  Widget _promotionOption(
    BuildContext ctx,
    chess.PieceType type,
    String code,
    String label,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, code),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
          color: creamBg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChessPieceWidget(type: type, isWhite: true, size: 36),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: navyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _triggerBotMove() async {
    setState(() {
      _isBotThinking = true;
    });

    // Jeda alami agar pergerakan bot terlihat nyaman
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final botMove = await ChessBot.findBestMove(_game, widget.difficulty);
    if (!mounted) return;

    if (botMove != null) {
      _game.move(botMove);
      _lastMoveFrom = botMove['from'];
      _lastMoveTo = botMove['to'];
    }

    setState(() {
      _isBotThinking = false;
    });

    _checkGameOver();
  }

  bool _checkGameOver() {
    if (!_game.game_over) return false;

    String title;
    String message;

    if (_game.in_checkmate) {
      if (_game.turn == chess.Color.WHITE) {
        title = 'Skakmat! Bot Menang';
        message = 'Bot berhasil mengepung rajamu. Jangan patah semangat, coba lagi!';
      } else {
        title = 'Skakmat! Kamu Menang 🎉';
        message = 'Luar biasa! Kamu berhasil mengalahkan bot dengan strategi cemerlang.';
      }
    } else if (_game.in_stalemate) {
      title = 'Permainan Remis (Stalemate)';
      message = 'Tidak ada langkah sah yang tersisa, namun raja tidak sedang diskak.';
    } else if (_game.insufficient_material) {
      title = 'Permainan Remis';
      message = 'Bidak di papan tidak cukup untuk mencapai skakmat.';
    } else {
      title = 'Permainan Berakhir Remis';
      message = 'Permainan berakhir seri sesuai aturan catur.';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: borderColor),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: navyColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: slateText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Tutup', style: TextStyle(color: slateText)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _restartGame();
              },
              style: FilledButton.styleFrom(
                backgroundColor: navyColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Main Lagi'),
            ),
          ],
        ),
      );
    });

    return true;
  }

  void _undoMove() {
    if (!_canUndo) return;

    setState(() {
      // Jika bot sudah melangkah, batalkan langkah bot dan langkah pemain
      if (_game.history.length >= 2) {
        _game.undo();
        _game.undo();
      } else {
        _game.undo();
      }

      _selectedSquare = null;
      _validDestinations.clear();

      if (_game.history.isNotEmpty) {
        final last = _game.history.last.move;
        _lastMoveFrom = last.fromAlgebraic;
        _lastMoveTo = last.toAlgebraic;
      } else {
        _lastMoveFrom = null;
        _lastMoveTo = null;
      }
    });
  }

  Future<void> _confirmRestart() async {
    if (_game.history.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
        title: const Text(
          'Ulangi Permainan?',
          style: TextStyle(
            color: navyColor,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Seluruh susunan bidak catur akan dikembalikan ke posisi awal.',
          style: TextStyle(color: slateText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: slateText)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: navyColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Ulangi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _restartGame();
    }
  }

  void _restartGame() {
    setState(() {
      _game.reset();
      _selectedSquare = null;
      _validDestinations.clear();
      _lastMoveFrom = null;
      _lastMoveTo = null;
      _isBotThinking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBg,
      appBar: AppBar(
        backgroundColor: creamBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Catur Santai XII RPL',
          style: TextStyle(
            color: navyColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: navyColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.smart_toy_outlined, size: 14, color: navyColor),
                const SizedBox(width: 4),
                Text(
                  'Bot · ${widget.difficulty.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: navyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              _buildTopStatusCard(),
              const SizedBox(height: 16),
              _buildChessBoard(),
              const SizedBox(height: 20),
              _buildBottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusCard() {
    final isWhiteTurn = _game.turn == chess.Color.WHITE;
    final capturedBlack = _getCapturedPieces(chess.Color.BLACK);
    final capturedWhite = _getCapturedPieces(chess.Color.WHITE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isBotThinking
                      ? amberAccent
                      : (isWhiteTurn ? sageGreen : amberAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isBotThinking
                      ? 'Bot sedang berpikir...'
                      : (isWhiteTurn
                          ? 'Giliranmu (Putih)'
                          : 'Bot sedang bersiap...'),
                  style: const TextStyle(
                    color: navyColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isBotThinking)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: navyColor,
                  ),
                ),
            ],
          ),
          const Divider(color: borderColor, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCapturedList('Tertangkap olehmu:', capturedBlack, isWhite: false),
              _buildCapturedList('Tertangkap bot:', capturedWhite, isWhite: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedList(
    String label,
    Map<chess.PieceType, int> pieces, {
    required bool isWhite,
  }) {
    return Column(
      crossAxisAlignment:
          isWhite ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: slateText),
        ),
        const SizedBox(height: 4),
        if (pieces.isEmpty)
          const Text(
            '—',
            style: TextStyle(fontSize: 12, color: slateText),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: pieces.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ChessPieceWidget(
                      type: e.key,
                      isWhite: isWhite,
                      size: 16,
                    ),
                    if (e.value > 1)
                      Text(
                        'x${e.value}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: slateText,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildChessBoard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: navyColor, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: List.generate(8, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(8, (col) {
                    final square = '${'abcdefgh'[col]}${8 - row}';
                    return Expanded(
                      child: _buildSquare(square, row, col),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSquare(String square, int row, int col) {
    final isLight = (row + col) % 2 == 0;
    final tileColor = isLight ? lightSquare : darkSquare;
    final piece = _game.get(square);

    final isSelected = _selectedSquare == square;
    final isLastMove = square == _lastMoveFrom || square == _lastMoveTo;
    final isValidDest = _validDestinations.contains(square);
    final isTargetCapture = isValidDest && piece != null;

    return GestureDetector(
      onTap: () => _onSquareTap(square),
      child: Container(
        color: tileColor,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sorotan langkah terakhir
            if (isLastMove)
              Container(
                color: Colors.amber.withValues(alpha: 0.28),
              ),

            // Sorotan petak terpilih
            if (isSelected)
              Container(
                color: sageGreen.withValues(alpha: 0.28),
              ),

            // Indikator angka rank dan huruf file di tepian
            if (col == 0)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  '${8 - row}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isLight ? navyColor.withValues(alpha: 0.5) : lightSquare.withValues(alpha: 0.5),
                  ),
                ),
              ),
            if (row == 7)
              Positioned(
                bottom: 2,
                right: 3,
                child: Text(
                  'abcdefgh'[col],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isLight ? navyColor.withValues(alpha: 0.5) : lightSquare.withValues(alpha: 0.5),
                  ),
                ),
              ),

            // Bidak Catur
            if (piece != null)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: ChessPieceWidget(
                  type: piece.type,
                  isWhite: piece.color == chess.Color.WHITE,
                ),
              ),

            // Indikator langkah sah (Titik hijau sage jika petak kosong)
            if (isValidDest && !isTargetCapture)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: sageGreen,
                ),
              ),

            // Cincin border jika petak tujuan berisi bidak lawan yang bisa dimakan
            if (isTargetCapture)
              Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: sageGreen,
                    width: 2.8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _canUndo ? _undoMove : null,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Undo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: navyColor,
                disabledForegroundColor: slateText.withValues(alpha: 0.4),
                side: BorderSide(
                  color: _canUndo ? borderColor : borderColor.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _confirmRestart,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Ulangi'),
              style: FilledButton.styleFrom(
                backgroundColor: navyColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
