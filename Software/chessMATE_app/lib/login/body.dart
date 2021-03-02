import 'package:chessMATE_app/backEnd_conn/game_communication.dart';
import 'package:chessMATE_app/buttons_login-signIn-forgotPassword/rounded_button.dart';
import 'package:chessMATE_app/buttons_login-signIn-forgotPassword/rounded_input_field.dart';
import 'package:chessMATE_app/buttons_login-signIn-forgotPassword/rounded_password_field.dart';
import 'package:chessMATE_app/login/already_have_an_account_check.dart';
import 'package:chessMATE_app/screens/forgotPass_screen.dart';
import 'package:chessMATE_app/screens/game_mode_screen.dart';
import 'package:chessMATE_app/screens/signInScreen.dart';
import 'package:flutter/material.dart';
import 'package:chessMATE_app/backEnd_conn/websockets.dart';

import 'login_validate.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  List topics = [
    "Invalid email",
    "Invalid password",
    "Invalid email & password"
  ];
  List msgs = [
    "Enter a valid email",
    "Enter a valid password",
    "Enter valid email & password"
  ];
  static int isValid;
  // static final TextEditingController _name = new TextEditingController();
  static String _userName;
  static String _password;
  String playerName;
  List<dynamic> playersList = <dynamic>[];
  bool userCorrect;
  String userError = "";
  List<String> dataMsgLogin = <String>[];

  @override
  void initState() {
    super.initState();
    // Ask to be notified when messages related to the game are sent by the server
    game.addListener(_onGameDataReceived);
  }

  @override
  void dispose() {
    game.removeListener(_onGameDataReceived);
    super.dispose();
  }

  _onGameDataReceived(message) {
    switch (message["action"]) {

      // Each time a new player joins, we need to
      //   * record the new list of players
      //   * rebuild the list of all the players

      case 'userValidity':
        userCorrect = message["data"];
        if (userCorrect == false) {
          // force rebuild
          setState(() {
            userError = 'Username or Password is incorrect!!';
          });
        } else {
          Navigator.pushNamed(context, GameModeScreen.id);
        }

        break;

      ///
      /// When a game is launched by another player, we accept the new game and automatically redirect to the game board.
      /// As we are not the new game initiator, we will be playing "black" (temp)
      ///

    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                "assets/logo.png",
                height: size.height * 0.2,
              ),
              SizedBox(
                height: size.height * 0.05,
              ),
              Text(
                "LOGIN",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 40,
                  color: Colors.white,
                  fontFamily: "Acme",
                  letterSpacing: 7,
                ),
              ),
              Container(
                  child: sockets.socketStatus()
                      ? null
                      : Text(
                          "Server not connected",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.red),
                        )),
              SizedBox(
                height: size.height * 0.01,
              ),
              Text(
                userError,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: "Acme",
                  letterSpacing: 5,
                  color: Colors.red,
                ),
              ),
              RoudedInputField(
                hintText: "Email Address",
                onChanged: (value) {
                  _userName = value;
                },
                icon: Icons.email,
              ),
              RoundedPasswordField(
                onChanged: (value) {
                  _password = value;
                },
                text: "Password",
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Container(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, ForgotPassScreen.id);
                    },
                    child: Text(
                      'Forgot Password ? ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.0,
                        color: Colors.lightBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              RoundedButton(
                text: "LOGIN",
                press: sockets.socketStatus()
                    ? () => {
                          isValid = validate_login(_userName, _password),
                          if (isValid == 4)
                            {
                              dataMsgLogin = [_userName, _password],
                              game.send('join', dataMsgLogin.join(':')),
                            }
                          else
                            {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: new Text(
                                        topics[isValid],
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      content: new Text(
                                        msgs[isValid],
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.lightBlue[900],
                                      actions: <Widget>[
                                        new FlatButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: new Text(
                                              "ok",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                              ),
                                            ))
                                      ],
                                    );
                                  }),
                            }
                          // game.send('join', _userName),
                          // Navigator.pushNamed(context, GameModeScreen.id)
                        }
                    : null,
              ),
              Text(
                'Or',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(
                height: size.height * 0.03,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color: Colors.lightBlue,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/google.png',
                      height: size.height * 0.1,
                      width: size.width * 0.08,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 2,
                        color: Colors.lightBlue,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/facebook.png',
                      height: size.height * 0.1,
                      width: size.width * 0.08,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: size.height * 0.03,
              ),
              AlreadyHaveAnAccountCheck(
                press: () {
                  Navigator.pushNamed(context, SignInScreen.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
