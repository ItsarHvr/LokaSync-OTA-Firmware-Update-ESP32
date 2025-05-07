from pydantic import BaseModel, field_validator
from datetime import datetime
from typing import Any

class Log(BaseModel):
    _id:int
    lokasi:str
    status:bool
    terakhir_diperbaharui:datetime
    versi_akhir:str
    versi_awal:str

    @field_validator("terakhir_diperbaharui", mode="before")
    @classmethod
    def parse_custom_datetime(cls, v: Any) -> datetime:
        if isinstance(v, str):
            return datetime.strptime(v.replace(" ", " "), "%B %d, %Y at %I:%M:%S %p UTC%z")
        return v