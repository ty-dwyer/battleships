// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Gameboard extends StatefulWidget {
  final String playAgainst;
  final String accessToken;

  Gameboard({required this.playAgainst, required this.accessToken});

  @override
  _GameboardState createState() => _GameboardState();
}

class _GameboardState extends State<Gameboard> {
  List<bool> buttonStates = List.filled(25, false);
  List<String> selectedShips = [];
  final int maxShips = 5;

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
                  (index) => Expanded(
                        child: Center(child: Text('${index + 1}')),
                      )),
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
                      childAspectRatio: 1 / 1,
                      mainAxisSpacing: 1,
                      crossAxisSpacing: 1,
                    ),
                    itemCount: 25,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black38),
                        ),
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                return buttonStates[index]
                                    ? Colors.blue
                                    : Colors.grey[200]!;
                              },
                            ),
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                            ),
                            padding: MaterialStateProperty.all(EdgeInsets.zero),
                          ),
                          onPressed: () {
                            setState(() {
                              if (!buttonStates[index] &&
                                  selectedShips.length < maxShips) {
                                buttonStates[index] = true;
                                selectedShips.add(
                                    "${String.fromCharCode(65 + index ~/ 5)}${index % 5 + 1}");
                              } else if (buttonStates[index]) {
                                buttonStates[index] = false;
                                selectedShips.remove(
                                    "${String.fromCharCode(65 + index ~/ 5)}${index % 5 + 1}");
                              }
                            });
                          },
                          child: Container(),
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
            onPressed: selectedShips.length == maxShips ? _submitGame : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("Submit"),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _submitGame() async {
    var aiValue = _getAIValue(widget.playAgainst);
    var url = Uri.parse('http://165.227.117.48/games');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
      body: jsonEncode({
        'ships': selectedShips,
        if (aiValue != null) 'ai': aiValue,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Session expired. Please log in again.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to submit game. Please try again.")));
      print("Error during game submission: ${response.body}");
    }
  }

  String? _getAIValue(String playAgainst) {
    if (playAgainst.contains("Player")) {
      return null;
    } else if (playAgainst.contains("Random")) {
      return "random";
    } else if (playAgainst.contains("Perfect")) {
      return "perfect";
    } else if (playAgainst.contains("One Ship")) {
      return "oneship";
    }
    return null;
  }
}
