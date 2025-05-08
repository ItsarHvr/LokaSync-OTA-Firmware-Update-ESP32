from pydantic import BaseModel, field_validator
from datetime import datetime
from typing import Any

class Log(BaseModel):
    _id:int
    location:str
    status:bool
    latest_update:datetime
    first_version:str
    latest_version:str

    @field_validator("terakhir_diperbaharui", mode="before")
    @classmethod
    def parse_custom_datetime(cls, v: Any) -> datetime:
        if isinstance(v, str):
            return datetime.strptime(v.replace(" ", " "), "%d %B %Y %H:%M:%S")
        return v