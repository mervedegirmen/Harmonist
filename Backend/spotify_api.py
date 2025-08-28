# spotify_api.py
# Spotify'dan playlist verilerini çeken fonksiyonlar (GÜNCEL)
import os
import random
from typing import List, Dict, Any

from dotenv import load_dotenv
import spotipy
from spotipy.oauth2 import SpotifyOAuth

load_dotenv()

# Sadece okuma için yeterli
SCOPE = "playlist-read-private"

sp = spotipy.Spotify(
    auth_manager=SpotifyOAuth(
        client_id=os.getenv("SPOTIPY_CLIENT_ID"),
        client_secret=os.getenv("SPOTIPY_CLIENT_SECRET"),
        redirect_uri=os.getenv("SPOTIPY_REDIRECT_URI"),
        scope=SCOPE,
    )
)

# ------------------------------------------------------------
# Mood (ruh hali) → Birden fazla Spotify Playlist ID listesi (en gunceli !

# ------------------------------------------------------------
MOOD_PLAYLISTS: Dict[str, List[str]] = {
    "sad": [
        "7GyDlxXF2EnTImgYJU8JIx",  # eski
        "2ZnAWYy4AOs8tpRUCGF6Py",  # yeni
    ],
    "energetic": [
        "09C8ZGUepJGErYZcI7s2Ns",
        "6i71oduwXihfSJBTrLoYOR",
    ],
    "in love": [
        "6oNsYDhN95gkENsdFcAwTh",
        "60OmycS2YaYLN63oiGPr2p",
    ],
    "happy": [
        "4Fh0313D3PitYzICKHhZ7r",
        "7ue0JFwZLLUezhvF8HcDyq",
        
    ],
    "relaxed": [
        "4rFthP2CHmFD6Cszc9mT9A",
        "44mWcJNKGzFQNICUBnrYLL",
    ],
    "depressed": [
        "7I4DQjGPwh8YTc6iW1GN7f",
        "2t4BAQJ4IWurz4wznvTxw1",
    ],
    "focused": [
        "14KtkIpsvzDSCXR24EqHCL",
        "4Qxy1JjPBbohRQIlMj6xBA",
    ],
    "chill": [
        "6IKQrtMc4c00YzONcUt7QH",
        "4pJNEInSLpsE696XUU00l8",
    ],
    "lonely": [
        "79bxZXB7zD8KWit9ud6lKk",
        "1M1ogQ10BKAdnW1SsMfsEc",
    ],
    "hopeful": [
        "77qvKHsd1c9YGbGcnZVNzE",
        "1M1ogQ10BKAdnW1SsMfsEc",  
    ],
    "confident": [
        "1krayF0y1dJhfLaGm0jHww",
        "3RuTobXDwJWJArbuMpBVr8",
    ],
    "nostalgic": [
        "7GRnA1buU09xvdDoSJlyEw",
        "4GasCSnkoRMY373VFUbinP",
        "27qET95DJqZLtNHmHSpuAG",
    ],
}

def _track_to_dict(track: Dict[str, Any]) -> Dict[str, Any]:
   
    if not track:
        return {}

    images = track.get("album", {}).get("images", []) or []
    image_url = images[1]["url"] if len(images) > 1 else (images[0]["url"] if images else None)

    return {
        "id": track.get("id", ""),  # spotify:track:<id> deep link için
        "title": track.get("name", ""),
        "artist": ", ".join(a.get("name", "") for a in track.get("artists", []) if a) or "",
        "track_url": (track.get("external_urls") or {}).get("spotify", ""),  # https://open.spotify.com/track/...
        "uri": track.get("uri", None),            # spotify:track:...
        "image_url": image_url,                   # kapak görselii icin (bu önemli!
        "preview_url": track.get("preview_url"),  # 30sn preview olabilir
    }

def _fetch_tracks_from_playlist(playlist_id: str, max_per_playlist: int = 150) -> List[Dict[str, Any]]:
    """Tek bir playlist'ten şarkıları çeker (sayfalama dahil), track dict listesi döner."""
    results = sp.playlist_tracks(playlist_id, limit=100)
    items = results.get("items", []) or []

    while results.get("next"):
        results = sp.next(results)
        items.extend(results.get("items", []) or [])
        if len(items) >= max_per_playlist:
            break

    tracks: List[Dict[str, Any]] = []
    for item in items:
        track = (item or {}).get("track")
        td = _track_to_dict(track)
        if td.get("id") or td.get("track_url"):
            tracks.append(td)

    return tracks

def get_playlist_by_mood(mood: str, limit: int = 30) -> List[Dict[str, Any]]:
    """
    Verilen mood'a uygun playlist'ten şarkıları döndürür.
    Mantık:
      1) Mood içindeki playlistlerden RASTGELE birini seç (buraya bak!
      2) O playlist'in şarkılarını çek
      3) Şarkıları KARISTIR (random.shuffle)
      4) 'limit' kadarını döndür

    Flutter alanları:
      id, title, artist, track_url, uri, image_url, preview_url
    """
    mood = (mood or "").lower().strip()
    playlist_ids = MOOD_PLAYLISTS.get(mood)
    if not playlist_ids:
        return []

    chosen = random.choice(playlist_ids)       # 1) rastgele playlist
    pool = _fetch_tracks_from_playlist(chosen) # 2) şarkıları çek
    random.shuffle(pool)                       # 3) karıştır

    seen = set()
    unique: List[Dict[str, Any]] = []
    for t in pool:
        key = t.get("id") or t.get("track_url")
        if key and key not in seen:
            seen.add(key)
            unique.append(t)

    return unique[:limit]                      # 4) limit için
