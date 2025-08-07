import requests
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime

# Firebase init
cred = credentials.Certificate("firebase-adminsdk.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# ThingSpeak details
channel_id = "YOUR_CHANNEL_ID"
read_key = "YOUR_READ_API_KEY"
url = f"https://api.thingspeak.com/channels/{channel_id}/feeds.json?api_key={read_key}&results=1"

def sync_alerts():
    r = requests.get(url)
    feed = r.json()['feeds'][0]
    pen_present = int(feed['field1'])
    temp = float(feed['field2'])

    if pen_present == 0:
        db.collection('alerts').add({
            'type': 'pen_absent',
            'message': 'Insulin pen missing!',
            'timestamp': datetime.utcnow()
        })

    if temp < 2 or temp > 8:
        db.collection('alerts').add({
            'type': 'temperature',
            'message': f'Temperature Alert: {temp}°C',
            'timestamp': datetime.utcnow()
        })

if __name__ == "__main__":
    sync_alerts()
