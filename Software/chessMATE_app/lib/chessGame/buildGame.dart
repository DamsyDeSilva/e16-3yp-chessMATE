import 'package:chessMATE_app/screens/results_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chess_board.dart';
import 'package:chessMATE_app/backEnd_conn/game_communication.dart';

class PlayGame extends StatefulWidget {
  PlayGame({
    Key key,
    this.opponentName,
    this.character,
  }) : super(key: key);

  // Name of the opponent
  final String opponentName;

  // color to be used by the player for his/her moves ("w" or "b")
  final String character;

  @override
  _PlayGameState createState() => _PlayGameState();
}

class _PlayGameState extends State<PlayGame> {
  static ChessBoardController controller;
  static List<String> gameHistory = [];
  bool isMyMove;

  // will call this method exactly once for each [State] object it creates.
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]); // fix the orientation up for this game interface
    controller = ChessBoardController();

    // Ask to be notified when a message from the server comes in.
    game.addListener(_onAction);

    isMyMove = _firstStatusMyTurn();
  }

  @override
  void dispose() {
    game.removeListener(_onAction);
    super.dispose();
  }

  // method to check first satus of move
  _firstStatusMyTurn() {
    if (widget.character == 'w') {
      return true;
    }
    return false;
  }

  // method to return white name
  String returnWhiteName() {
    if (widget.character == 'w') {
      return ('You');
    }
    return (widget.opponentName);
  }

  // method to return white name
  String returnBlackName() {
    if (widget.character == 'b') {
      return ('You');
    }
    return (widget.opponentName);
  }

  // ---------------------------------------------------------
  // The opponent took an action
  // Handler of these actions
  // ---------------------------------------------------------
  _onAction(message) {
    switch (message["action"]) {

      // The opponent resigned, so let's leave this screen
      case 'resigned':
        Navigator.of(context).pop();
        break;

      // The opponent played a move. So record it and rebuild the board
      case 'onMove':
        var data = (message["data"] as String).split(';');
        gameHistory.add(data[0]);
        controller.makeMove(data[1], data[2]);
        isMyMove = true; // after recieving move the local player has the turn
        // Force rebuild
        setState(() {});
        break;
    }
  }

  // ---------------------------------------------------------
  // This player resigns
  // We need to send this notification to the other player
  // Then, leave this screen
  // ---------------------------------------------------------
  _doResign() {
    game.send('resign', '');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromRGBO(4, 7, 40, 3),
        body: SafeArea(
          child: ListView(children: <Widget>[
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Image.asset(
                    "assets/logo.png",
                    height: size.height * 0.12,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "White :  " + returnWhiteName(),
                      style: TextStyle(
                          color: Colors.white,
                          height: 5,
                          fontFamily: "Acme",
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Black :  " + returnBlackName(),
                      style: TextStyle(
                          color: Colors.white,
                          height: 5,
                          fontFamily: "Acme",
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            _buildChessBoard(),
            _buildGameHistory(),
            _buildOptionButtons(),
          ]),
        ),
      ),
    );
  }

  // method to return the chessboard widget
  Widget _buildChessBoard() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: ChessBoard(
        size: MediaQuery.of(context).size.width,
        enableUserMoves: isMyMove,
        whiteSideTowardsUser: isPlayerWhite(),
        onMove: (moveNotation, from, to) {
          isMyMove = false;
          gameHistory.add(moveNotation);
          // To send a move, we provide the starting square and end square
          game.send('onMove', '$moveNotation;$from;$to');
          // Force rebuild
          setState(() {});
        },
        onCheckMate: (winColor) {
          // --> todo : pass the winning deatils to results screen
          Navigator.pushNamed(context, ResultsScreen.id);
        },
        onDraw: () {
          Navigator.pushNamed(context, ResultsScreen.id);
        },
        chessBoardController: controller,
      ),
    );
  }

  // method to flip the board side (white side or black side)
  bool isPlayerWhite() {
    if (widget.character == 'b') {
      return false;
    }
    return true;
  }

  // method to return the widget containing option buttons
  Widget _buildOptionButtons() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlatButton(
                  child: Text(
                    "Reset Game",
                    style: TextStyle(
                      fontFamily: "Acme",
                      fontSize: 20,
                    ),
                  ),
                  color: Colors.blue[400],
                  textColor: Colors.black,
                  onPressed: () {
                    _resetGame();
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlatButton(
                  child: Text(
                    "Undo Move",
                    style: TextStyle(
                      fontFamily: "Acme",
                      fontSize: 20,
                    ),
                  ),
                  color: Colors.blue[400],
                  textColor: Colors.black,
                  onPressed: () {
                    _undoMove();
                  },
                ),
              ),
            ),
          ]),
    );
  }

  // method to reset the game
  void _resetGame() {
    controller.resetBoard();
    gameHistory.clear();
    setState(() {});
  }

  // method to undo the last move
  void _undoMove() {
    controller.game.undo_move();
    if (gameHistory.length != 0) {
      gameHistory.removeLast();
    }
    setState(() {});
  }

  // method to return a widget containing gameHistory
  Widget _buildGameHistory() {
    return Text(
      _buildMovesString(),
      style: TextStyle(color: Colors.white),
    );
  }

  // method to retun the gamehistory as a string
  String _buildMovesString() {
    String history = '';
    if (gameHistory.length > 0) {
      for (int i = 0; i < gameHistory.length; i++) {
        if (i % 2 == 0) {
          history += "${(i / 2 + 1).toInt()}" + "." + gameHistory[i] + " ";
          if (gameHistory.length > (i + 1)) {
            history += gameHistory[i + 1] + "   ";
          }
        }
      }
    }
    return history;
  }
}
