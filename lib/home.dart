// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'completedgames.dart';
import 'gameboard.dart';
import 'loadboard.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String accessToken;

  HomeScreen({required this.username, required this.accessToken});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> activeGames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchActiveGames();
  }

  Future<void> fetchActiveGames() async {
    var url = Uri.parse('http://165.227.117.48/games');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.accessToken}',
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        activeGames =
            data['games'].where((game) => game['status'] == 3).toList();
        isLoading = false;
      });
    } else {
      print('Error fetching games: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Battleships"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchActiveGames,
            tooltip: 'Refresh Games',
          )
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            );
          },
        ),
      ),
      drawer: buildDrawer(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildGameList(context),
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
            title: const Text('Show Completed Games'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CompletedGames(
                            username: widget.username,
                            accessToken: widget.accessToken,
                          )));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              Navigator.pop(context);
              await logout();
            },
          ),
        ],
      ),
    );
  }

  Widget buildGameList(BuildContext context) {
    if (activeGames.isEmpty) {
      return const Center(child: Text('No active games.'));
    } else {
      return ListView.builder(
        itemCount: activeGames.length,
        itemBuilder: (context, index) {
          var game = activeGames[index];
          bool isMyTurn = game['turn'] == game['position'];
          return ListTile(
            title: Text(
                'Game ID: ${game['id']} - ${game['player1']} vs ${game['player2']}'),
            subtitle: Text(
                isMyTurn ? "It's your turn" : "Waiting for opponent's turn"),
            trailing: IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => cancelGame(game['id'].toString()),
              tooltip: 'Cancel/Forfeit Game',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Loadboard(
                      gameID: game['id'].toString(),
                      accessToken: widget.accessToken),
                ),
              );
            },
          );
        },
      );
    }
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

  void cancelGame(String gameId) async {
    var url = Uri.parse('http://165.227.117.48/games/$gameId');
    var response = await http.delete(url, headers: {
      'Authorization': 'Bearer ${widget.accessToken}',
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Game Cancelled"),
          content: Text(data['message']),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                fetchActiveGames();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (response.statusCode == 401) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: const Text("Unauthorized. Please log in again."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to cancel game: ${response.statusCode}"),
      ));
    }
  }
}
