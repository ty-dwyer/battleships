// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'gameboard.dart';
import 'home.dart';
import 'loadboard.dart';
import 'login.dart';

class CompletedGames extends StatefulWidget {
  final String username;
  final String accessToken;

  CompletedGames({required this.username, required this.accessToken});

  @override
  _CompletedGamesState createState() => _CompletedGamesState();
}

class _CompletedGamesState extends State<CompletedGames> {
  List<dynamic> games = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  Future<void> fetchGames() async {
    var url = Uri.parse('http://165.227.117.48/games');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.accessToken}',
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        games = data['games']
            .where((game) => game['status'] == 1 || game['status'] == 2)
            .toList();
        isLoading = false;
      });
    } else {
      print('Failed to load games: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Games"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchGames,
            tooltip: 'Refresh Games',
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: games.length,
              itemBuilder: (context, index) {
                var game = games[index];
                String winner =
                    game['status'] == 1 ? game['player1'] : game['player2'];
                return ListTile(
                  title: Text(
                      'Game ${game['id']}: ${game['player1']} vs ${game['player2']}'),
                  subtitle: Text('Winner: $winner'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Loadboard(
                          gameID: game['id'].toString(),
                          accessToken: widget.accessToken,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Drawer buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Battleships',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                Text(
                  'Logged in as: ${widget.username}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New Game'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Gameboard(
                            playAgainst: "Player",
                            accessToken: widget.accessToken,
                          )));
            },
          ),
          ListTile(
            leading: const Icon(Icons.android),
            title: const Text('New Game (AI)'),
            onTap: () {
              Navigator.pop(context);
              _showAIDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.gamepad),
            title: const Text('Show Active Games'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeScreen(
                            username: widget.username,
                            accessToken: widget.accessToken,
                          )));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              await logout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void _showAIDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Which AI do you want to play against?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text("Random"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Gameboard(
                                playAgainst: "Random",
                                accessToken: widget.accessToken,
                              )));
                },
              ),
              ListTile(
                title: const Text("Perfect"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Gameboard(
                                playAgainst: "Perfect",
                                accessToken: widget.accessToken,
                              )));
                },
              ),
              ListTile(
                title: const Text("One Ship (A1)"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Gameboard(
                                playAgainst: "One Ship",
                                accessToken: widget.accessToken,
                              )));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
