from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import ASCENDING

client = AsyncIOMotorClient("mongodb://localhost:27017")
db = client["iot_database"]
monitoring_colletion = db[""]
log_collection = db[""]
firmware_collection = db[""]