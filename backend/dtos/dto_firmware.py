from pydantic import BaseModel, Field, field_validator
from typing import Optional, Dict, List, Union, TypedDict

from dtos.dto_common import BasePage
from models.model_firmware import Firmware


# For POST, PUT (NODE_ID), AND DELETE (NODE_ID)
class InputFirmware(BaseModel):
    firmware_description: Optional[str] = Field(min_length=1)
    firmware_version: str = Field(min_length=1, max_length=5, pattern=r'^\d+\.\d+\.\d+$') # MAJOR.MINOR.PATCH
    firmware_url: str = Field(min_length=1, pattern=r'^(http|https)://.*$') # URL FORMAT
    node_id: int = Field(min=1)
    node_location: str = Field(min_length=1, max_length=255)

    @field_validator("firmware_version")
    def validate_firmware_version(cls, value):
        if any(char.isdigit() for char in value):
            raise ValueError("Firmware version must be in the format X.Y.Z")
        return value
    
    @field_validator("firmware_url")
    def validate_firmware_link(cls, value):
        pass

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


class FilterOptions(TypedDict):
    node_id: List[int]
    node_location: List[str]

class OutputFirmwarePagination(BasePage):
    filter_options: FilterOptions = Field(default_factory=lambda: {"node_id": [], "node_location": []})
    firmware_data: List[Firmware] = Field(default_factory=list)