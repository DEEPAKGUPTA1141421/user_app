import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechSearchPage extends StatefulWidget {
  const SpeechSearchPage({super.key});

  @override
  _SpeechSearchPageState createState() => _SpeechSearchPageState();
}

class _SpeechSearchPageState extends State<SpeechSearchPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  List<String> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _startListening();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() => _text = val.recognizedWords);
          if (!_speech.isListening) {
            _searchProducts(_text);
          }
        },
      );
    }
  }

  Future<void> _searchProducts(String query) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    final allProducts = ['mobile', 'tshirt', 'lays', 'jeans'];
    final results = allProducts
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Voice Search"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _text.isEmpty ? "Listening..." : _text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_results.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (_, index) =>
                      ListTile(title: Text(_results[index])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
