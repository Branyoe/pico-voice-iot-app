// import 'package:avatar_glow/avatar_glow.dart';
// import 'package:flutter/material.dart';
// import 'package:highlight_text/highlight_text.dart';

// class Speech extends StatefulWidget {
//   const Speech({Key? key}) : super(key: key);

//   @override
//   State<Speech> createState() => _SpeechState();
// }

// class _SpeechState extends State<Speech> {
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   String _text = 'Tap the button and say something';
//   double _confidence = 1.0;
//   double level = 0.0;
//   double minSoundLevel = 50000;
//   double maxSoundLevel = -50000;
//   final Map<String, HighlightedWord> _highlights = {
//     'arriba': HighlightedWord(
//         textStyle:
//             const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
//     'abajo': HighlightedWord(
//         textStyle:
//             const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
//     'derecha': HighlightedWord(
//         textStyle:
//             const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
//     'izquierda': HighlightedWord(
//         textStyle:
//             const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
//   };

//   @override
//   void initState() {
//     super.initState();

//     _speech = stt.SpeechToText();
//   }

//   void _listen() async {
//     if (!_isListening) {
//       bool avaliable = await _speech.initialize(
//         onStatus: (val) => print('onStatus: $val'),
//         onError: (val) => print('onError: $val'),
//       );
//       if (avaliable) {
//         setState(() => _isListening = true);
//         _speech.listen(
//             onResult: (val) => setState(() {
//                   _text = val.recognizedWords;
//                   if (val.hasConfidenceRating && val.confidence > 0) {
//                     _confidence = val.confidence;
//                   }
//                 }));
//       }
//     } else {
//       setState(() => _isListening = false);
//       _speech.stop();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Controller'),
//         ),
//         body: Center(
//           child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Padding(
//                   padding: const EdgeInsets.all(30.0),
//                   child: TextHighlight(
//                     text: _text,
//                     words: _highlights,
//                     textStyle: const TextStyle(
//                         fontSize: 32.0,
//                         color: Colors.black,
//                         fontWeight: FontWeight.w400),
//                   ),
//                 )
//               ]),
//         ),
        // floatingActionButton: AvatarGlow(
        //     animate: _isListening,
        //     glowColor: Theme.of(context).primaryColor,
        //     endRadius: 100.0,
        //     curve: Curves.easeInOut,
        //     duration: const Duration(milliseconds: 2000),
        //     repeat: true,
        //     child: FloatingActionButton.large(
        //       onPressed: _listen,
        //       tooltip: 'Listen',
        //       enableFeedback: true,
        //       child: Icon(_isListening ? Icons.mic : Icons.mic_off),
        //     )),
//         floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat);
//   }
// }
