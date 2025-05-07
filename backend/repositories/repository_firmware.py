from firebase_admin import firestore
from typing import List, Optional
from google.cloud.firestore_v1.base_query import FieldFilter

from models.model_firmware import Firmware
from dtos.dto_firmware import FilterOptions


class FirmwareRepository:
    def __init__(self):
        self.db = firestore.client()
        self.firmware_ref = self.db.collection("firmware")
    
    async def get_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None,
        page: int = 1,
        per_page: int = 5
    ) -> List[Firmware]:
        query = self.firmware_ref
        
        # 1. Collect filter data if any.
        if node_id is not None:
            query = query.where(filter=FieldFilter("node_id", "==", node_id))
        if node_location is not None:
            query = query.where(filter=FieldFilter("node_location", "==", node_location))

        # 2. Order filtered data by latest_updated field.
        query = query.order_by("latest_updated", direction=firestore.Query.DESCENDING)

        # 3. Set offset dan limit.
        # Offset itu intinya pertambahan item di halaman berikutnya (skip kalau di mongo).
        # Limit itu batasan item yang ditampilkan di halaman tersebut (per page)
        offset = (page - 1) * per_page
        query = query.limit(per_page).offset(offset)

        # 4. Get the results.
        results = query.stream()
        firmwares = [Firmware(**doc.to_dict()) for doc in results]

        return firmwares
    
    async def count_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None
    ) -> int:
        query = self.firmware_ref
        
        # 1. Collect filter data if any.
        if node_id is not None:
            query = query.where(filter=FieldFilter("node_id", "==", node_id))
        if node_location is not None:
            query = query.where(filter=FieldFilter("node_location", "==", node_location))

        # 2. Count the documents.
        docs = query.stream()

        # 3. Count the number of documents.
        count = sum(1 for _ in docs)

        return count
    
    async def get_filter_options(self) -> FilterOptions:
        # 1. Stream the documents from the collection.
        docs = self.firmware_ref.stream()
        
        # 2. Initialize empty lists for node_id and node_location.
        node_ids = set()
        node_locations = set()
        
        # 3. Iterate through the documents and collect node_id and node_location.
        for doc in docs:
            data = doc.to_dict()
            node_ids.add(data["node_id"])
            node_locations.add(data["node_location"])
            
        # 4. Convert sets to lists and sort them.
        node_ids = sorted(list(node_ids))
        node_locations = sorted(list(node_locations))
        
        # 5. Return the filter options as a dictionary.
        return {
            "node_id": node_ids, # List[int]
            "node_location": node_locations # List[str]
        }