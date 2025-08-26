// lib/main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const String baseUrl = 'http://10.0.2.2:5000';

// spotify_api.py keys
const List<String> moods = [
  'happy','sad','energetic','relaxed','depressed','in love','focused','chill','lonely','hopeful','confident','nostalgic',
];

// Mood -> Emoji
const Map<String, String> moodEmojis = {
  'happy': '😊','sad': '😢','energetic': '🔥','relaxed': '🌿',
  'depressed': '🌧️','in love': '💖','focused': '🎯','chill': '🧊',
  'lonely': '🌙','hopeful': '🌈','confident': '🦁','nostalgic': '📼',
};

// Mood -> color
const Map<String, MaterialColor> moodColors = {
  'happy': Colors.amber,
  'sad': Colors.indigo,
  'energetic': Colors.deepOrange,
  'relaxed': Colors.teal,
  'depressed': Colors.blueGrey,
  'in love': Colors.pink,
  'focused': Colors.deepPurple,
  'chill': Colors.cyan,
  'lonely': Colors.blue,
  'hopeful': Colors.green,
  'confident': Colors.orange,
  'nostalgic': Colors.brown,
};

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
    );
    return MaterialApp(
      title: 'Harmonist',
      theme: theme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// --------------------------- Splash ---------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MoodHomePage()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// --------------------------- Auth ---------------------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final endpoint = _isLogin ? '/login' : '/register';
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _username.text.trim(),
          'password': _password.text.trim(),
        }),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (_isLogin) {
          final token = data['token'] as String?;
          if (token == null) throw Exception('Token not found');
          final sp = await SharedPreferences.getInstance();
          await sp.setString('token', token);
          await sp.setString('username', _username.text.trim());
          if (!mounted) return;
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MoodHomePage()));
        } else {
          setState(() => _isLogin = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up successful. Please sign in.')),
          );
        }
      } else {
        _showError(data['error']?.toString() ?? 'Request failed (${resp.statusCode})');
      }
    } catch (e) {
      _showError('Request error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(m),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Sign In' : 'Sign Up')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) => (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
                    ),
                    const SizedBox(height: 16),
                    _loading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: Text(_isLogin ? 'Sign In' : 'Sign Up'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(_isLogin
                          ? "Don't have an account? Sign up"
                          : 'Already have an account? Sign in'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --------------------------- Mood Home ---------------------------
class MoodHomePage extends StatefulWidget {
  const MoodHomePage({super.key});
  @override
  State<MoodHomePage> createState() => _MoodHomePageState();
}

class _MoodHomePageState extends State<MoodHomePage> {
  String selectedMood = '';
  List<Map<String, dynamic>> playList = [];
  bool isLoading = false;
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final sp = await SharedPreferences.getInstance();
    setState(() => username = sp.getString('username'));
  }

  String _labelize(String mood) =>
      '${moodEmojis[mood] ?? ''}  ' +
          mood.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  Future<void> _selectMood(String mood) async {
    setState(() {
      selectedMood = mood;
      playList = [];
      isLoading = true;
    });

    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token') ?? '';

    final url = Uri.parse('$baseUrl/get_playlist?mood=${Uri.encodeQueryComponent(mood.toLowerCase())}');
    try {
      final resp = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        setState(() => playList = data.cast<Map<String, dynamic>>());
      } else if (resp.statusCode == 401) {
        await sp.remove('token');
        await sp.remove('username');
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      } else {
        _showError('API error: ${resp.statusCode}');
      }
    } catch (e) {
      _showError('Request failed: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('username');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AuthScreen()), (_) => false);
  }

  void _showError(String m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(m),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _openTrack(Map<String, dynamic> track) async {
    final uri = track['uri'];
    final url = track['track_url'];
    try {
      if (uri != null && await canLaunchUrl(Uri.parse(uri))) {
        await launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
      } else if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showError("Cannot open track.");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = moodColors[selectedMood] ?? Colors.teal;
    final bg1 = base.withOpacity(0.08);
    return Scaffold(
      appBar: AppBar(
        title: Text('How do you feel? ${username != null ? "– $username" : ""}'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
        backgroundColor: base,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Select Mood:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          // Mood chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: moods.map((m) {
              final isSel = m == selectedMood;
              final color = moodColors[m] ?? Colors.grey;
              return ChoiceChip(
                label: Text(
                  _labelize(m),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : color.shade900.withOpacity(0.85),
                  ),
                ),
                selected: isSel,
                onSelected: (_) => _selectMood(m),
                selectedColor: color,
                backgroundColor: color.withOpacity(0.18),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          if (selectedMood.isNotEmpty)
            Text('Selected Mood: ${_labelize(selectedMood)}',
                style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 12),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (playList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: playList.length,
                itemBuilder: (_, i) {
                  final track = playList[i];
                  return Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: track['image_url'] != null
                          ? Image.network(track['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                          : const Icon(Icons.music_note),
                      title: Text(track['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(track['artist'] ?? ''),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => _openTrack(track),
                    ),
                  );
                },
              ),
            )
          else
            const SizedBox.shrink(),
        ]),
      ),
    );
  }
}
