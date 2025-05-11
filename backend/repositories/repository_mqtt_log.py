from firebase_admin import firestore
from typing import List, Optional
from datetime import datetime, timezone
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException
from google.cloud.firestore_v1.base_query import FieldFilter

from dtos.dto_log import InputLog

class MQTTLogRepository:
    def __init__(self):
        self.db = firestore.client()
        self.log_ref = self.db.collection("log")

    async def add_log(self, log: InputLog, node_name:str):
        try:
            log_data = log.model_dump()
            log_data["latest_updated"] = datetime.now(timezone.utc)

            # Simpan log ke Firestore
            await self.log_ref.document(node_name).set(log_data, merge=True)

            return {"message": f"Log Added successfully to {node_name}."}
        
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))