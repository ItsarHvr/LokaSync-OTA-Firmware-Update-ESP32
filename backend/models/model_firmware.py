from pydantic import BaseModel
from datetime import datetime


class Firmware(BaseModel):
    _id: str
    firmware_description: str
    firmware_version: str
    firmware_url: str
    latest_updated: datetime
    node_id: int
    node_location: str
