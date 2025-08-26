import spotipy
from spotipy.oauth2 import SpotifyOAuth
import os
from dotenv import load_dotenv

# .env dosyasını yükle
load_dotenv()

scope = "playlist-read-private"

# Spotify bağlantısını oluştur
sp = spotipy.Spotify(auth_manager=SpotifyOAuth(
    client_id=os.getenv("SPOTIPY_CLIENT_ID"),
    client_secret=os.getenv("SPOTIPY_CLIENT_SECRET"),
    redirect_uri=os.getenv("SPOTIPY_REDIRECT_URI"),
    scope=scope
))

# Kullanıcı bilgilerini al
me = sp.current_user()
print(" Bağlantı başarılı!")
print("Spotify hesabı:", me["display_name"])
