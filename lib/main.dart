import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:picovoice_flutter/picovoice_error.dart';
import 'package:rhino_flutter/rhino.dart';
import 'package:picovoice_flutter/picovoice_manager.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String accessKey =
      'UCaNSBWu6LiB/0ACZWpiRbFYrzQB/VTa4ymwk+pEElW+u5FcBGY1Mg==';
  final String keywordPath = "assets/keyword.ppn";
  final String contextPath = "assets/context.rhn";
  final String porcupineModelPath = "assets/android/porcupine_params_es.pv";
  final String rhinoModelPath = "assets/android/rhino_params_es.pv";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  final TextStyle _highlightsStyle = const TextStyle(
    color: Colors.green, 
    fontWeight: FontWeight.w400, 
    fontSize: 30.0
  );

  late final Map<String, HighlightedWord> _highlights = {
    'arriba': HighlightedWord(textStyle: _highlightsStyle),
    'abajo': HighlightedWord(textStyle: _highlightsStyle),
    'derecha': HighlightedWord(textStyle: _highlightsStyle),
    'izquierda': HighlightedWord(textStyle: _highlightsStyle),
  };

  @override
  void initState() {
    super.initState();
    setState(() {
      isButtonDisabled = true;
      rhinoText = "Tap the button to start";
    });

    initPicovoice();
    setState(() {
      errorMessage = "yessss";
    });
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
      }else{
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

    if(inference.intent == "arriba"){
      
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
    return Scaffold(
      key: _scaffoldKey,
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
