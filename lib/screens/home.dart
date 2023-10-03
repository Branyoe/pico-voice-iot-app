import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:voice_commands/widgets/SnackAlertBar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // properties
  String statusText = "Status Text";
  bool isConnected = false;
  bool hasError = false;
  String errorText = "";

  MqttServerClient client =
      MqttServerClient.withPort('broker.emqx.io', 'flutter_client', 1883);
  MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  // View
  @override
  Widget build(BuildContext context) {
    Widget view;
    if (isConnected) {
      view = connectedView();
    } else {
      view = unconnectedView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("MQTT Voice Controller"),
      ),
      body: Center(child: view),
    );
  }

  // Methods

  Widget connectedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          isConnected ? "Connected" : "Disconnected",
        ),
        Text(statusText),
        // ElevatedButton(onPressed: _connect, child: const Text("Connect")),
        ElevatedButton(
            onPressed: () {
              builder.addString('Hello MQTT');
              try {
                client.publishMessage('ihc/voice/commands', MqttQos.atLeastOnce,
                    builder.payload!);
                builder.clear();
              } catch (e) {
                builder.clear();
                isConnected = false;
              }
            },
            child: const Text("Publish")),
      ],
    );
  }

  Widget unconnectedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("No conectado"),
        ElevatedButton(onPressed: _connect, child: const Text("Conectar")),
      ],
    );
  }

  _showSnackBar(String text, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackAlertBar(
      text,
      color: color,
    ));
  }

  _connect() async {
    isConnected = await mqttConnect();
  }

  _disconnect() {
    client.disconnect();
  }

  Future<bool> mqttConnect() async {
    setState(() {
      statusText = "Conectando...";
    });

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    final MqttConnectMessage connMess =
        MqttConnectMessage().startClean().withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      setState(() {
        hasError = true;
        errorText = e.toString();
      });
      client.disconnect();
      return false;
    }

    return true;
  }

  // MQTT Events

  void onConnected() {
    setState(() {
      statusText = "Conectado";
    });
    _showSnackBar("Conectado", color: Colors.green);
  }

  void onUnsubscribed(String? topic) {
    print('Unsubscribed from topic: $topic');
  }

  void onDisconnected() {
    setState(() {
      statusText = "Desconectado";
      isConnected = false;
    });
    _showSnackBar("Desconectado", color: Colors.grey);
  }

  void onSubscribed(String topic) {
    // print('Subscribed topic: $topic');
  }

// subscribe to topic failed
  void onSubscribeFail(String? topic) {
    _showSnackBar('subscripción fallida', color: Colors.red);
  }

  void pong() {
    // print('Ping response client callback invoked');
  }
}
