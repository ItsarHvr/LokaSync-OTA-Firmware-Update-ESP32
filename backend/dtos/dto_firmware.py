from pydantic import BaseModel, Field
from typing import Optional, List, TypedDict
from fastapi import Form, UploadFile, File

from dtos.dto_common import BasePage
from models.model_firmware import Firmware


class InputFirmware(BaseModel):
    firmware_description: Optional[str] = Field(min_length=1, max_length=255)
    firmware_version: str = Field(min_length=1, max_length=8, pattern=r'^\d+\.\d+\.\d+$') # MAJOR.MINOR.PATCH
    firmware_url: str = Field(min_length=1, pattern=r'^(http|https)://.*$') # URL FORMAT
    node_id: int = Field(min=1)
    node_location: str = Field(min_length=1, max_length=255)
    sensor_type: str = Field(min_length=1, max_length=255)

    class Config:
        json_schema_extra ={
            "example": {
                "firmware_version": "1.0.0",
                "firmware_url": "https://example.com/firmware/node_location/firmware.ino.bin",
                "firmware_description": "This is a firmware description.",
                "node_id": 1,
                "node_location": "Depok Greenhouse"
            }
        }

class UploadFirmwareForm:
    def __init__(
        self,
        firmware_version: str = Form(...),
        node_location : str = Form(...),
        node_id: int = Form(...),
        firmware_description : str = Form(...),
        sensor_type : str = Form(...),
        firmwarefile : UploadFile = File(...)
    ):
        self.firmware_version = firmware_version
        self.node_id = node_id
        self.node_location = node_location
        self.firmware_description = firmware_description
        self.firmwarefile = firmwarefile
        self.sensor_type = sensor_type
        
    def to_dto(self, firmware_url: str) -> InputFirmware:
        return InputFirmware(
            firmware_description=self.firmware_description,
            firmware_version=self.firmware_version,
            firmware_url=firmware_url,
            node_id=self.node_id,
            node_location=self.node_location,
            sensor_type=self.sensor_type
        )

class FilterOptions(TypedDict):
    node_id: List[int]
    node_location: List[str]


class OutputFirmwarePagination(BasePage):
    page: int
    per_page: int
    total_data: int
    total_page: int
    filter_options: FilterOptions = Field(default_factory=lambda: {"node_id": [], "node_location": []})
    firmware_data: List[Firmware] = Field(default_factory=list)