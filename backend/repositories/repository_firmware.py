from typing import List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from models.model_firmware import Firmware
from dtos.dto_firmware import FilterOptions

class FirmwareRepository:
    def __init__(self, collection: AsyncIOMotorCollection):
        self.collection = collection
    
    async def get_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None,
        page: int = 1,
        per_page: int = 5
    ) -> List[Firmware]:
        query = {}

        if node_id is not None:
            query["node_id"] = node_id
        if node_location is not None:
            query["node_location"] = node_location

        skip = (page - 1) * per_page

        cursor = (
            self.collection.find(query)
            .sort("latest_updated", -1)
            .skip(skip)
            .limit(per_page)
        )

        docs = await cursor.to_list(length=per_page)

        return [
            Firmware(
                _id=str(doc["_id"]),
                firmware_description=doc.get("firmware_description", ""),
                firmware_version=doc["firmware_version"],
                firmware_url=doc["firmware_url"],
                latest_updated=doc["latest_updated"],
                node_id=doc["node_id"],
                node_location=doc["node_location"],
                node_name=doc["node_name"]
            )
            for doc in docs
        ]
    
    async def count_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None
    ) -> int:
        query = {}
        if node_id is not None:
            query["node_id"] = node_id
        if node_location is not None:
            query["node_location"] = node_location

        return await self.collection.count_documents(query)
    
    async def get_filter_options(self) -> FilterOptions:
        node_ids = await self.collection.distinct("node_id")
        node_locations = await self.collection.distinct("node_location")

        return {
            "node_id": node_ids, # List[int]
            "node_location": node_locations # List[str]
        }