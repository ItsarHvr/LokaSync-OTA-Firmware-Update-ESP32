from pydantic import BaseModel, Field
from typing import Optional, List, TypedDict

from dtos.dto_common import BasePage
from models.model_monitoring import Monitoring

class InputMonitoring(BaseModel):
    node_name:str = Field(min_length=1, max_length=255)
    node_location:str = Field(min_length=1, max_length=255)
    data: dict[str, any]

    class Config:
        json_schema_extra1 ={
            "topic": "lokasync/sensor/DHT22",
            "node_name": "depok-node1",
            "node_location": "Depok Greenhouse",
            "timestamp": "2025-05-12T13:12:30",
            "data": {
                "temperature": 26.5,
                "humidity": 60.2,
            }
        }
        json_schema_extra2 ={
            "topic": "lokasync/sensor/Water_Node",
            "node_name": "depok-node2",
            "node_location": "Depok Greenhouse",
            "timestamp": "2025-05-12T13:12:30",
            "data": {
                "temperature": 26.5,
                "tds value": 60.2,
            }
        }

class FilterOption(TypedDict):
    node_location: List[str]
    node_name: List[bool]

class OutputLogPagination(BasePage):
    filter_options: FilterOption = Field(default_factory=lambda:{"node_location": [], "node_name": []})
    monitoring_data: List[Monitoring] = Field(default_factory=list)
