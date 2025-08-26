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

    final url = Uri.parse('$baseUrl/get
