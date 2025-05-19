import os
import json
from dotenv import load_dotenv
import paho.mqtt.publish as publish
from fastapi import Depends, UploadFile
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException
from typing import Optional
from datetime import datetime, timezone
from math import ceil
from bson import ObjectId

from motor.motor_asyncio import AsyncIOMotorClient
from services.service_drive import upload_to_drive
from dtos.dto_firmware import UploadFirmwareForm, UpdateFirmwareForm, OutputFirmwarePagination
from repositories.repository_firmware import FirmwareRepository

load_dotenv()

MONGO_URL = os.getenv("MONGO_URL")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME")
MQTT_ADDRESS = os.getenv("MQTT_ADDRESS")

client = AsyncIOMotorClient(MONGO_URL)
mongo_db = client[MONGO_DB_NAME]
firmware_collection = mongo_db["firmware"]

def get_firmware_repository():
    return FirmwareRepository(firmware_collection)

class ServiceFirmware:
    def __init__(self, firmware_repository: FirmwareRepository = Depends(get_firmware_repository)):
        self.firmware_repository = firmware_repository
        self.folder_id = os.getenv("GOOGLE_DRIVE_FOLDER_ID", "").strip()
        print("DEBUG folder_id:", repr(self.folder_id))

    async def get_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None,
        page: int = 1,
        per_page: int = 5
    ) -> OutputFirmwarePagination:
        try:
            # 1. Data firmware
            list_firmware = await self.firmware_repository.get_list_firmware(
                page=page,
                per_page=per_page,
                node_id=node_id,
                node_location=node_location
            )

            # 2. Total data
            total_data = await self.firmware_repository.count_list_firmware(
                node_id=node_id,
                node_location=node_location
            )

            # 3. Total page
            total_page = ceil(total_data / per_page) if total_data else 1

            # 4. Get filter options
            filter_options = await self.firmware_repository.get_filter_options()

            # 5. Return response
            return OutputFirmwarePagination(
                page=page,
                per_page=per_page,
                total_data=total_data,
                total_page=total_page,
                filter_options=filter_options,
                firmware_data=list_firmware
            )
        except Exception as e:
            return HTTPException(status_code=500, detail=f"Gagal mengambil data firmware: {str(e)}")
        
    async def add_firmware(self, form: UploadFirmwareForm):
        filename = form.firmwarefile.filename
        save_path = f"tmp/{filename}"
        
        if not os.path.exists("tmp"):
            os.makedirs("tmp")
            
        try:
            with open(save_path, "wb+") as f:
                content = await form.firmwarefile.read()
                f.write(content)
        except Exception as e:
            raise Exception(f"Gagal menyimpan file: {str(e)}")
        
        #Upload Ke GDrive
        try:
            firmware_url = upload_to_drive(save_path, filename, self.folder_id)
        except Exception as e:
            raise Exception(f"Gagal Upload ke GDrive: {str(e)}")
        
        
        firmware_dto = form.to_dto(firmware_url)
        firmware_data = firmware_dto.model_dump()
        firmware_data["latest_updated"] = datetime.now(timezone.utc)

        #Make node_name
        node_location = firmware_data.get("node_location", "Unknown")
        node_id = firmware_data.get("node_id", "0")
        sensor_type = firmware_data.get("sensor_type", "Unknown")
        node_name = f"{node_location}-node{node_id}-{sensor_type}".lower()
        firmware_data["node_name"] = node_name

        #Input to MongoDB
        try:
            await firmware_collection.insert_one(firmware_data)
        except Exception as e:
            raise Exception(f"Gagal input ke MongoDB: {str(e)}")
        
        #Publish ke MQTT
        try:
            topic = "LokaSync/CloudOTA/Firmware"
            payload = json.dumps({
                "node_name":node_name,
                "url": firmware_url
                })
            publish.single(topic, payload, hostname=MQTT_ADDRESS)
        except Exception as e:
            raise Exception(f"Gagal Mengirim ke MQTT: {str(e)}")
        
    async def update_firmware(self, node_name: str, form: UpdateFirmwareForm):
        filename = form.firmwarefile.filename
        save_path = f"tmp/{filename}"
        
        if not os.path.exists("tmp"):
            os.makedirs("tmp")
        
        try:
            with open(save_path, "wb+") as f:
                content = await form.firmwarefile.read()
                f.write(content)
        except Exception as e:
            raise Exception(f"Gagal menyimpan file: {str(e)}")
            
        
        return True

    async def delete_firmware(self, node_id: str):
        # Dummy atau implementasi logika delete
        return True