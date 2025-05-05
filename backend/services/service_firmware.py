from fastapi import Depends
from fastapi.exceptions import HTTPException
from firebase_admin import firestore
from typing import List, Optional, Dict
from datetime import datetime
from math import ceil

from dtos.dto_firmware import OutputFirmwarePagination
from repositories.repository_firmware import FirmwareRepository


class ServiceFirmware:
    def __init__(self, firmware_repository: FirmwareRepository = Depends()):
        self.db = firestore.client().collection("firmware")
        self.firmware_repository = firmware_repository

    async def get_list_firmware(
        self,
        node_id: Optional[int] = None,
        node_location: Optional[str] = None,
        page: int = 1,
        per_page: int = 5
    ) -> OutputFirmwarePagination:
        # 1. Data firmware
        list_firmware: list = await self.firmware_repository.get_list_firmware(
            page=page,
            per_page=per_page,
            node_id=node_id,
            node_location=node_location
        )

        # 2. Total data
        total_data: int = await self.firmware_repository.count_list_firmware(
            node_id=node_id,
            node_location=node_location
        )

        # 3. Total page
        total_page: int = ceil(total_data / per_page) if total_data else 1

        # 4. Get filter options
        filter_options: dict = await self.firmware_repository.get_filter_options()

        # 6. Return response
        return OutputFirmwarePagination(
            page=page,
            per_page=per_page,
            total_data=total_data,
            total_page=total_page,
            filter_options=filter_options,
            firmware_data=list_firmware
        )