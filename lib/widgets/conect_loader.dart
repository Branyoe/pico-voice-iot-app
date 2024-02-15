import 'package:flutter/material.dart';

Widget buildConnectingScreen(){
  return Scaffold(
    appBar: AppBar(
      title: const Text("Voice controller"),
      backgroundColor: Colors.blueAccent,
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text("Connecting to MQTT Broker..."),
        ],
      ),
    ),
  );
}