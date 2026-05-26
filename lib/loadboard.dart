// ignore_for_file: prefer_interpolation_to_compose_strings, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Loadboard extends StatefulWidget {
  final String gameID;
  final String accessToken;

  Loadboard({required this.gameID, required this.accessToken});

  @override
  _LoadboardState createState() => _LoadboardState();
}

class _LoadboardState extends State<Loadboard> {
  bool isLoading = true;
  Map<String, String> boardState = {};
  String? selectedCell;
  int? gameStatus;

  @override
  void initState() {
    super.initState();
    fetchGameData();
  }

  Future<void> fetchGameData() async {
    var url = Uri.parse('http://165.227.117.48/games/${widget.gameID}');
    var response = await http.get(url, headers: {
      'Authorization': 'Bearer ${widget.accessToken}',
    });

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        isLoading = false;
        gameStatus = data['status'];
        for (var ship in data['ships']) {
          boardState[ship] = (boardState[ship] ?? '') + '🚢';
        }
        for (var wreck in data['wrecks']) {
          boardState[wreck] = (boardState[wreck] ?? '') + '💥';
        }
        for (var shot in data['shots']) {
          boardState[shot] = (boardState[shot] ?? '') + '💣';
        }
        for (var sunk in data['sunk']) {
          boardState[sunk] = (boardState[sunk] ?? '') + '🪦';
        }
        if (gameStatus == 1 || gameStatus == 2) {
          selectedCell = null;
        } else {
          checkForLoss();
        }
      });
    } else {
      print('Failed to fetch game data: ${response.statusCode}');
    }
  }

  void checkForLoss() {
    if (gameStatus == 3) {
      int explosionCount =
          boardState.values.where((v) => v.contains('💥')).length;
      if (explosionCount >= 5) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Game Over"),
            content: const Text("You Lost! Better luck next time."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gameboard'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(30, 20, 0, 0),
            child: Row(
              children: List.generate(
                5,
                (index) => Expanded(child: Center(child: Text('${index + 1}'))),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(
                        5, (index) => Text(String.fromCharCode(65 + index))),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                    ),
                    itemCount: 25,
                    itemBuilder: (context, index) {
                      String key =
                          "${String.fromCharCode(65 + index ~/ 5)}${index % 5 + 1}";
                      String value = boardState[key] ?? '';
                      return GestureDetector(
                        onTap: gameStatus == 3
                            ? () {
                                setState(() {
                                  if (selectedCell != null &&
                                      boardState[selectedCell!] == '🎯') {
                                    boardState[selectedCell!] = '';
                                  }
                                  selectedCell = key;
                                  boardState[key] = '🎯';
                                });
                              }
                            : null,
                        child: GridTile(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black38),
                            ),
                            alignment: Alignment.center,
                            child: Text(value,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed:
                selectedCell != null && gameStatus == 3 ? sendShot : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Submit Shot"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void sendShot() async {
    if (selectedCell != null &&
        boardState[selectedCell]!.contains('🎯') &&
        gameStatus == 3) {
      var url = Uri.parse('http://165.227.117.48/games/${widget.gameID}');
      var response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}'
        },
        body: jsonEncode({'shot': selectedCell}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          String newEmoji = data['sunk_ship'] ? '🪦' : '💣';
          boardState[selectedCell!] = newEmoji;
          selectedCell = null;
        });

        if (data['won']) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Game Over"),
              content: const Text("Congratulations! You have won the game!"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to submit shot. Please try again.")));
      }
    }
  }
}
