import json
import paho.mqtt.client as mqtt
import threading
from fastapi import Depends
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException
from firebase_admin import firestore
from typing import Optional
from datetime import datetime
from math import ceil
from dotenv import load_dotenv
import os

BROKER_ADDRESS = os.getenv("BROKER_ADDRESS")
BROKER_PORT = int(os.getenv("MQTT_PORT"))

db = firestore.client()

TOPICS = [
    ("sensor/DHT22", 0),
    ("OTA/Node-DHT", 0),
    ("Pollux/log/Firmware_Update", 0),
    ("sensor/temperature", 0),
    ("OTA/Water_Node", 0),
]

def on_connect(client, userdata, flags, rc):
    print("Connected with result code " + str(rc))
    for topic, qos in TOPICS:
        client.subscribe(topic)
        print(f"Subscribed to {topic}")

def on_message(client, userdata, msg):
    print(f"Received message on {msg.topic}: {msg.payload.decode()}")
    try:
        data = json.loads(msg.payload.decode())
        topic = msg.topic

        if topic == "sensor/DHT22":
            doc_ref = db.collection("log").document("dpk-node1")
                        
        elif topic == "Pollux/log/Firmware_Update":
            LogOTA.objects.create(
                millis=data.get("millis", 0),
                message=data.get("message", ""),
            )
        elif topic == "sensor/temperature":
            WaterNodeData.objects.create(
                temperature=data.get("temp", 0),
                ppm=data.get("ppm", 0),
            )
    except Exception as e:
        print("MQTT Data Error", e)

def start_mqtt():
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(BROKER_ADDRESS, BROKER_PORT, 60)

    thread = threading.Thread(target=client.loop_forever, name="MQTTThread")
    thread.daemon = True
    thread.start()
