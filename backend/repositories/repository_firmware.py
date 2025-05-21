from typing import List, Optional
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection
from models.model_firmware import Firmware
from dtos.dto_firmware import FilterOptions
from datetime import datetime, timezone

class FirmwareRepository:
    def __init__(self, collection: AsyncIOMotorCollection):
        self.collection = collection
    
    async def get_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None,
        sensor_type: Optional[str] = None,
        page: int = 1,
        per_page: int = 5
    ) -> List[Firmware]:
        # Base query for filtering by parameters
        match_query = {}
        if node_id is not None:
            match_query["node_id"] = node_id
        if node_location is not None:
            match_query["node_location"] = node_location
        if sensor_type is not None:
            match_query["sensor_type"] = sensor_type
        
        # MongoDB aggregation pipeline to get only the latest firmware version for each node
        pipeline = [
            # Stage 1: Match documents based on query filters
            {"$match": match_query},
            # Stage 2: Sort by node_id, node_location, node_name, and latest_updated
            {"$sort": {"node_id": 1, "node_location": 1, "node_name": 1, "latest_updated": -1}},
            # Stage 3: Group by node identifier and keep only the first (latest) document
            {"$group": {
                "_id": "$node_name",  # Group by node_name (could also use a combination like {node_id, sensor_type})
                "doc": {"$first": "$$ROOT"}  # Keep the first document in each group (latest by updated date)
            }},
            # Stage 4: Replace the root with the original document
            {"$replaceRoot": {"newRoot": "$doc"}},
            # Stage 5: Sort results again by latest_updated for global ordering
            {"$sort": {"latest_updated": -1}},
            # Stage 6: Skip for pagination
            {"$skip": (page - 1) * per_page},
            # Stage 7: Limit results per page
            {"$limit": per_page}
        ]
    
        # Execute the aggregation pipeline
        cursor = self.collection.aggregate(pipeline)
        docs = await cursor.to_list(length=per_page)
        
        # Convert MongoDB documents to Firmware model objects
        return [
            Firmware(
                _id=str(doc["_id"]),
                firmware_description=doc.get("firmware_description", ""),
                firmware_version=doc["firmware_version"],
                firmware_url=doc["firmware_url"],
                latest_updated=doc["latest_updated"],
                node_id=doc["node_id"],
                node_location=doc["node_location"],
                node_name=doc["node_name"],
                sensor_type=doc["sensor_type"]
            )
            for doc in docs
        ]
    
    async def count_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None,
        sensor_type: Optional[str] = None
    ) -> int:
        query = {}
        if node_id is not None:
            query["node_id"] = node_id
        if node_location is not None:
            query["node_location"] = node_location
        if sensor_type is not None:
            query["sensor_type"] = sensor_type
        

        # MongoDB aggregation pipeline to count unique nodes
        pipeline = [
            # Stage 1: Match documents based on query filters
            {"$match": query},
            # Stage 2: Group by node identifier to get unique nodes
            {"$group": {"_id": "$node_name"}},
            # Stage 3: Count the number of unique nodes
            {"$count": "count"}
        ]

        # Execute the aggregation pipeline
        cursor = self.collection.aggregate(pipeline)
        result = await cursor.to_list(length=1)

        # Return the count or 0 if no results
        return result[0]["count"] if result else 0
    
    async def get_filter_options(self) -> FilterOptions:
        node_ids = await self.collection.distinct("node_id")
        node_locations = await self.collection.distinct("node_location")
        sensor_type = await self.collection.distinct("sensor_type")

        return {
            "node_id": node_ids, # List[int]
            "node_location": node_locations, # List[str]
            "sensor_type": sensor_type # List[str]
        }
    
    async def get_by_node_name(
            self,
            node_name: str,
            page: int = 1,
            per_page: int = 10
    ) -> List[Firmware]:
        pipeline = [
            # Stage 1: Match documents based on query filters
            {"$match": {"node_name": node_name}},
            # Stage 2: Sort by latest_updated
            {"$sort": {"latest_updated": -1}},
            # Stage 3: Skip for pagination
            {"$skip": (page - 1) * per_page},
            # Stage 4: Limit results per page
            {"$limit": per_page}
        ]

        cursor = self.collection.aggregate(pipeline)
        docs = await cursor.to_list(length=per_page)

        # Convert MongoDB documents to Firmware model objects
        return [
            Firmware(
                _id=str(doc["_id"]),
                firmware_description=doc.get("firmware_description", ""),
                firmware_version=doc["firmware_version"],
                firmware_url=doc["firmware_url"],
                latest_updated=doc["latest_updated"],
                node_id=doc["node_id"],
                node_location=doc["node_location"],
                node_name=doc["node_name"],
                sensor_type=doc["sensor_type"]
            )
            for doc in docs
        ]
    
    async def count_by_node_name(
            self,
            node_name: str
    ) -> int:
        return await self.collection.count_documents({"node_name":node_name})
    
    async def add_firmware(self, firmware_data: dict):
        firmware_data["latest_updated"] = datetime.now(timezone.utc)
        await self.collection.insert_one(firmware_data)
    
    async def update_firmware(
            self, 
            node_name: str,
            firmware_data: dict
    ):
        existing_data = await self.collection.find_one({"node_name": node_name})
        if not existing_data:
            return None
        
        new_firmware = {
            "node_id": existing_data["node_id"],
            "node_location": existing_data["node_location"],
            "sensor_type": existing_data["sensor_type"],
            "node_name": node_name,
            "firmware_description": firmware_data.get("firmware_description", ""),
            "firmware_version": firmware_data["firmware_version"],
            "firmware_url": firmware_data["firmware_url"],
            "latest_updated": datetime.now(timezone.utc),
        }
        await self.collection.insert_one(new_firmware)
        return new_firmware
    
    async def update_firmware_description(
            self,
            node_name: str,
            firmware_version: str,
            firmware_data: dict
    ):
        existing_data = await self.collection.find_one({
            "node_name": node_name,
            "firmware_version": firmware_version,
        })
        if not existing_data:
            return None
        
        result = await self.collection.update_one(
            {
                "node_name": node_name,
                "firmware_version": firmware_version
            },
            {
                "$set": {
                    "firmware_description": firmware_data.get("firmware_description", ""),
                    "latest_updated": datetime.now(timezone.utc)
                }
            }
        )
        return result.modified_count > 0
    
    async def delete_by_firmware_verison(
            self,
            node_name: str,
            firmware_version: str
    ):
        await self.collection.delete_one({
            "node_name": node_name,
            "firmware_version": firmware_version
        })

    async def delete_all_by_node_name(
            self,
            node_name: str
    ):
        await self.collection.delete_many({
            "node_name": node_name
        })