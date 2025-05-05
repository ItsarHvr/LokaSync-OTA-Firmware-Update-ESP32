from fastapi import APIRouter, Depends, Query
from fastapi.responses import JSONResponse
from typing import Optional, Dict

from dtos.dto_firmware import InputFirmware, OutputFirmwarePagination
from services.service_firmware import ServiceFirmware

router_firmware = APIRouter(prefix="/api/v1", tags=["Firmware"])

@router_firmware.get(
    "/firmware",
    response_model=OutputFirmwarePagination,
    summary="Get list of available firmwares."
)
async def get_all_firmwares(
    node_id: Optional[int] = Query(default=None, ge=1),
    node_location: Optional[str] = Query(default=None, min_length=1, max_length=255),
    page: int = Query(1, ge=1),
    per_page: int = Query(5, ge=1, le=100),
    service_firmware: ServiceFirmware = Depends()
):
    response_get = await service_firmware.get_list_firmware(
        page=page,
        per_page=per_page,
        node_id=node_id or None,
        node_location=node_location or None
    )
    return response_get

@router_firmware.post("/firmware/add")
async def add_firmware(firmware: InputFirmware):
    return JSONResponse(status_code=200, content={"message": "Add firmware successfully."})

@router_firmware.put("/firmware/update/{node_id}")
async def update_firmware(node_id: str, firmware: InputFirmware):
    return JSONResponse(status_code=200, content={"message": "Update firmware successfully."})

@router_firmware.delete("/firmware/delete/{node_id}")
async def delete_firmware(node_id: str, firmware: InputFirmware):
    return JSONResponse(status_code=200, content={"message": "Delete firmware successfully."})