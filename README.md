# 🎶 Harmonist – Mood-Based Music Recommendation App  

Harmonist is a **mood-driven music recommendation app** built with **Flutter (frontend)** and **Python + Flask (backend)**.  
The app connects to **Spotify API** and generates personalized playlists depending on the user’s current mood.  



## ✨ Features  
- 🔐 **Authentication** – Sign up & Sign in system with JWT tokens  
- 🎭 **Mood Selection** – Choose from multiple moods (happy, sad, relaxed, energetic, in love, nostalgic, etc.)  
- 🎶 **Spotify Integration** – Open songs directly in the Spotify app  
- 🎨 **Mood-Themed UI** – Dynamic colors & emojis based on mood  
- 📜 **Secure Backend** – Python + Flask backend with token-based authentication  
- 📱 **Cross-Platform** – Works on Android & iOS (via Flutter)  



## 🛠️ Tech Stack  
**Frontend (Flutter)**  
- Dart  
- Flutter Widgets & Material Design  
- Google Fonts, SharedPreferences, url_launcher  

**Backend (Python + Flask)**  
- Flask REST API  
- Spotipy (Spotify Web API wrapper)  
- JWT Authentication  
- dotenv for secure keys  


## 🚀 How It Works  
1. User signs in / signs up.  
2. Chooses a mood (e.g. happy, sad, nostalgic).  
3. Backend fetches playlist(s) from Spotify API.  
4. Songs are displayed with cover images, artist names, and open directly in Spotify.  
5. Each mood generates a **randomized recommendation order** for variety.  



