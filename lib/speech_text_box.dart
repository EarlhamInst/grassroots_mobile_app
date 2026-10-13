import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';


class SpeechToTextWidget extends StatefulWidget {
  final String? initialValue;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final TextEditingController? controller;

  const SpeechToTextWidget({
    super.key,
    this.initialValue,
    this.decoration,
    this.keyboardType,
    this.style,
    this.controller,
  });

  @override
  _SpeechToTextWidget createState () => _SpeechToTextWidget ();
}

class _SpeechToTextWidget extends State <SpeechToTextWidget> {
  late TextEditingController _text_controller;

  /* Only dispose of the controller if we created it */
  bool _owns_controller = false;
  final SpeechToText _speech_to_text = SpeechToText ();
  bool _speechEnabled = false;


  void listenForPermissions () async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.denied:
        requestForPermission();
        break;
      case PermissionStatus.granted:
        break;
      case PermissionStatus.limited:
        break;
      case PermissionStatus.permanentlyDenied:
        break;
      case PermissionStatus.provisional:
        break;
      case PermissionStatus.restricted:
        break;
    }
  }

  Future<void> requestForPermission() async {
    await Permission.microphone.request();
  }

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _text_controller = widget.controller!;
    } else {
      _text_controller = TextEditingController (text: widget.initialValue);
      _owns_controller = true;
    }

    listenForPermissions();
    if (!_speechEnabled) {
      _initSpeech();
    }
  }

  @override
  void dispose() {
    _speech_to_text.cancel ();

    if (_owns_controller) {
      _text_controller.dispose ();
    }

    super.dispose();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speech_to_text.initialize();
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speech_to_text.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      localeId: "en_En",
      cancelOnError: false,
      partialResults: false,
      listenMode: ListenMode.confirmation,
    );

    if (mounted) {
      setState(() {});
    }
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() async {
    await _speech_to_text.stop ();

    if (mounted) {
      setState (() {});
    }
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult (SpeechRecognitionResult result) {
    if (!mounted) {
      return;
    }

    setState(() {
      String old_content = _text_controller.text;
      String new_content = "${old_content}${result.recognizedWords} ";
      _text_controller.text = new_content;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row (
      children: <Widget> [
        Expanded (
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _text_controller,
                  minLines: 6,
                  maxLines: 10,
                  decoration: widget.decoration,
                  keyboardType: widget.keyboardType,
                  style: widget.style,
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              FloatingActionButton.small(
                onPressed:
                // If not yet listening for speech start, otherwise stop
                _speech_to_text.isNotListening
                    ? _startListening
                    : _stopListening,
                tooltip: 'Listen',
                backgroundColor: Colors.blueGrey,
                child: Icon (_speech_to_text.isNotListening
                    ? Icons.mic_off
                    : Icons.mic),
              )
            ],
          ),

        ),
      ],
    );

  }
}