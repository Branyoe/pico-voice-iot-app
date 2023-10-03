import 'dart:async';

import 'package:flutter/material.dart';

import 'package:picovoice_flutter/picovoice_manager.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:rhino_flutter/rhino.dart';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:highlight_text/highlight_text.dart';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:voice_commands/screens/home.dart';
import 'package:voice_commands/widgets/conect_loader.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String accessKey =
      'UCaNSBWu6LiB/0ACZWpiRbFYrzQB/VTa4ymwk+pEElW+u5FcBGY1Mg==';
  final String keywordPath = "assets/keyword.ppn";
  final String contextPath = "assets/context.rhn";
  final String porcupineModelPath = "assets/android/porcupine_params_es.pv";
  final String rhinoModelPath = "assets/android/rhino_params_es.pv";

  final TextStyle _highlightsStyle = const TextStyle(
      color: Colors.green, fontWeight: FontWeight.w400, fontSize: 30.0);
  late final Map<String, HighlightedWord> _highlights = {
    'arriba': HighlightedWord(textStyle: _highlightsStyle),
    'abajo': HighlightedWord(textStyle: _highlightsStyle),
    'derecha': HighlightedWord(textStyle: _highlightsStyle),
    'izquierda': HighlightedWord(textStyle: _highlightsStyle),
  };

  bool isError = false;
  String errorMessage = "";

  bool isButtonDisabled = false;
  bool isProcessing = false;
  bool wakeWordDetected = false;
  String? contextInfo;
  String contextName = "";
  String wakeWordName = "";
  String rhinoText = "Tap the button to start";
  PicovoiceManager? _picovoiceManager;

  String mqttStatusText = "Status Text";
  bool isConnected = false;
  bool hasError = false;
  String errorText = "";

  MqttServerClient client =
      MqttServerClient.withPort('broker.emqx.io', 'flutter_client', 1883);
  MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();

  @override
  void initState() {
    super.initState();
    setState(() {
      isButtonDisabled = true;
      rhinoText = "Tap the button to start";
    });

    initPicovoice();
    _connect();
  }

  Future<bool> mqttConnect() async {
    setState(() {
      mqttStatusText = "Conectando...";
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

  _connect() async {
    isConnected = await mqttConnect();
  }

  _disconnect() {
    client.disconnect();
  }

  void onConnected() {
    setState(() {
      mqttStatusText = 'Connected';
    });
  }

  void onDisconnected() {
    setState(() {
      mqttStatusText = 'Disconnected';
    });
  }

  void onSubscribed(String topic) {
    setState(() {
      mqttStatusText = 'Subscribed topic: $topic';
    });
  }

  void onSubscribeFail(String topic) {
    setState(() {
      mqttStatusText = 'Failed to subscribe topic: $topic';
    });
  }

  void onUnsubscribed(String? topic) {
    setState(() {
      mqttStatusText = 'Unsubscribed topic: $topic';
    });
  }

  void pong() {
    setState(() {
      mqttStatusText = 'Ping response client callback invoked';
    });
  }

  void publishMessage(String message){
    builder.addString(message);
    try {
      client.publishMessage('ihc/voice/commands', MqttQos.atLeastOnce,
          builder.payload!);
      builder.clear();
    } catch (e) {
      builder.clear();
      isConnected = false;
    }
  }

  Future<void> initPicovoice() async {
    _picovoiceManager = await PicovoiceManager.create(accessKey, keywordPath,
        wakeWordCallback, contextPath, inferenceCallback,
        porcupineModelPath: porcupineModelPath,
        rhinoModelPath: rhinoModelPath,
        processErrorCallback: errorCallback);
    setState(() {
      errorMessage =
          _picovoiceManager == null ? "Failed to initialize Picovoice" : "";
    });
  }

  Future<bool> _startPicovoice() async {
    if (_picovoiceManager == null) {
      throw PicovoiceInvalidStateException(
          "_picovoiceManager not initialized.");
    }

    try {
      await _picovoiceManager!.start();
      setState(() {
        contextInfo = _picovoiceManager!.contextInfo;
      });
      return true;
    } on PicovoiceInvalidArgumentException catch (ex) {
      errorCallback(PicovoiceInvalidArgumentException(
          "${ex.message}\nEnsure your accessKey '$accessKey' is valid."));
    } on PicovoiceActivationException {
      errorCallback(
          PicovoiceActivationException("AccessKey activation error."));
    } on PicovoiceActivationLimitException {
      errorCallback(PicovoiceActivationLimitException(
          "AccessKey reached its device limit."));
    } on PicovoiceActivationRefusedException {
      errorCallback(PicovoiceActivationRefusedException("AccessKey refused."));
    } on PicovoiceActivationThrottledException {
      errorCallback(PicovoiceActivationThrottledException(
          "AccessKey has been throttled."));
    } on PicovoiceException catch (ex) {
      errorCallback(ex);
    }
    return false;
  }

  Future<void> _startProcessing() async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isButtonDisabled = true;
    });

    if (await _startPicovoice()) {
      setState(() {
        isProcessing = true;
        rhinoText = "Listening...";
        isButtonDisabled = false;
      });
    }
  }

  Future<void> _stopProcessing() async {
    if (!isProcessing) {
      return;
    }

    setState(() {
      isButtonDisabled = true;
    });

    if (_picovoiceManager == null) {
      throw PicovoiceInvalidStateException(
          "_picovoiceManager not initialized.");
    }
    await _picovoiceManager!.stop();
    setState(() {
      isProcessing = false;
      rhinoText = "Tap the button to start";
      isButtonDisabled = false;
    });
  }

  void wakeWordCallback() {
    setState(() {
      wakeWordDetected = true;
      rhinoText = "Carrito ";
    });
  }

  void inferenceCallback(RhinoInference inference) {
    setState(() {
      if (inference.isUnderstood == true) {
        rhinoText = "carrito ${inference.intent}";
      } else {
        rhinoText = "Comando desconocido";
      }
      wakeWordDetected = false;
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (isProcessing) {
        if (wakeWordDetected) {
          rhinoText = "Carrito...";
        } else {
          setState(() {
            rhinoText = "Listening...";
          });
        }
      } else {
        setState(() {
          rhinoText = "Tap the button to start";
        });
      }
    });

    if (inference.intent == "arriba") {
      publishMessage("arriba");
    }else if (inference.intent == "abajo") {
      publishMessage("abajo");
    }else if (inference.intent == "derecha") {
      publishMessage("derecha");
    }else if (inference.intent == "izquierda") {
      publishMessage("izquierda");
    }
  }

  void errorCallback(PicovoiceException error) {
    if (error.message != null) {
      setState(() {
        isError = true;
        errorMessage = error.message!;
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isConnected ? buildMainScreen() : buildConnectingScreen();
  }

  buildMainScreen() {
    return Scaffold(
      // key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Picovoice Demo'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: TextHighlight(
              text: rhinoText,
              words: _highlights,
              textStyle: TextStyle(
                fontSize: 32.0,
                color: Colors.black,
                fontWeight: !isProcessing ? FontWeight.w200 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AvatarGlow(
        animate: !isButtonDisabled,
        glowColor: Theme.of(context).primaryColor,
        endRadius: 100.0,
        curve: Curves.easeInOut,
        duration: const Duration(milliseconds: 2000),
        repeat: true,
        child: FloatingActionButton.large(
          onPressed: isProcessing ? _stopProcessing : _startProcessing,
          tooltip: 'Listen',
          enableFeedback: true,
          child: Icon(isProcessing ? Icons.mic : Icons.play_arrow),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
