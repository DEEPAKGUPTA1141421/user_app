import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/app_colors.dart';
import 'real_search_page.dart';

class SpeechSearchPage extends StatefulWidget {
  const SpeechSearchPage({super.key});

  @override
  State<SpeechSearchPage> createState() => _SpeechSearchPageState();
}

class _SpeechSearchPageState extends State<SpeechSearchPage>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _recognizedText = '';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _speech = stt.SpeechToText();
    _initAndListen();
  }

  Future<void> _initAndListen() async {
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
        _pulseCtrl.stop();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
          _pulseCtrl.stop();
          _navigateToSearch();
        }
      },
    );

    if (!mounted) return;
    setState(() => _speechAvailable = available);

    if (available) {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _recognizedText = '';
    });
    _pulseCtrl.repeat(reverse: true);

    _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _recognizedText = result.recognizedWords);
        }
      },
      listenMode: stt.ListenMode.search,
    );
  }

  void _stopAndSearch() {
    _speech.stop();
    _pulseCtrl.stop();
    setState(() => _isListening = false);
    _navigateToSearch();
  }

  void _navigateToSearch() {
    final query = _recognizedText.trim();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RealSearchPage(initialQuery: query.isEmpty ? null : query),
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Voice Search',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.border, height: 1),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMic(),
                    const SizedBox(height: 32),
                    _buildText(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMic() {
    return GestureDetector(
      onTap: _isListening ? _stopAndSearch : _startListening,
      child: Column(
        children: [
          ScaleTransition(
            scale: _isListening
                ? _pulseAnim
                : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _isListening ? AppColors.surface2 : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isListening ? AppColors.white : AppColors.border,
                  width: 2,
                ),
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? AppColors.white : AppColors.grey,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isListening ? 'Listening…' : 'Tap to speak',
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText() {
    if (_recognizedText.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        _recognizedText,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
