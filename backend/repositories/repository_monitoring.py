from pymongo import mongo_client
from typing import List, Optional

from services.service_mongo import db
from models.model_monitoring import Monitoring
from dtos.dto_monitoring import FilterOption

class MonitoringRepository:
    def __init__(self):
        self.db = db
        self.monitoring_ref = self.db["monitoring_data"]
        
    async def get_list_monitoring(
        self,
        node_name: Optional[str] = None,
        page: int = 1,
        per_page: int = 5
    ) -> List[Monitoring]:
        query = self.monitoring_ref
        
        # 1. Collect filter data if any.
        if node_name is not None:
            query = query.where(filter=FieldFilter("node_id", "==", node_name))