from pydantic import BaseModel, field_validator
from datetime import datetime
from typing import Any

class Monitoring(BaseModel):
    _id:str
    node_name:str
    node_location:str
    timestamp:datetime
    data: dict[str, Any]

    @field_validator("timestamp", mode="before")
    @classmethod
    def parse_custom_datetime(cls, v: Any) -> datetime:
        if isinstance(v, str):
            return datetime.strptime(v.replace(" ", " "), "%d %B %Y %H:%M:%S")
        return v

