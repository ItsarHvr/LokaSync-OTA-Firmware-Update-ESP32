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
        # 1. Make filter
        filter_query = {}
        if node_name:
            filter_query["node_name"] = node_name
        
        # 2. set offset and limit
        offset = (page - 1) * per_page
        
        # 3. Query to MongoDB
        result = self.monitoring_ref.find(filter_query)\
            .skip(offset)\
            .limit(per_page)\
            .sort("timestamp", -1) #sort by timestamp descending
            
        #Convert to model
        return [Monitoring(**doc) for doc in result]