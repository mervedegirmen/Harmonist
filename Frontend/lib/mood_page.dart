// lib/mood_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({Key? key}) : super(key: key);
  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  String selectedMood = '';
  List<String> playList = [];
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
        setState(() => playList = data.map((e) => e.toString()).toList());
      } else if (resp.statusCode == 401) {
        _showError('Oturum süresi dolmuş veya token yok. Lütfen tekrar giriş yap.');
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
    Navigator.of(context).pop(); // login sayfasına geri
  }

  void _showError(String m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hata'),
        content: Text(m),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('How do you feel? ${username != null ? "– $username" : ""}'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Select Mood:', style: TextStyle(fontSize: 22)),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10, runSpacing: 10,
                children: moods.map((m) {
                  return ElevatedButton(onPressed: () => _selectMood(m), child: Text(_labelize(m)));
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (selectedMood.isNotEmpty) Text('Selected Mood: ${_labelize(selectedMood)}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          if (isLoading) const Center(child: CircularProgressIndicator())
          else if (playList.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: playList.length,
                itemBuilder: (_, i) => ListTile(leading: const Icon(Icons.music_note), title: Text(playList[i])),
              ),
            )
          else
            const SizedBox.shrink(),
        ]),
      ),
    );
  }
}
