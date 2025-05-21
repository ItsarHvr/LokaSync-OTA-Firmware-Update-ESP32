from fastapi import APIRouter, Depends, Query
from fastapi.responses import JSONResponse
from typing import Optional

from dtos.dto_firmware import InputFirmware, UploadFirmwareForm, UpdateFirmwareForm, UpdateFirmwareDescriptionForm, OutputFirmwarePagination, OuputFirmwareByNodeName
from services.service_firmware import ServiceFirmware

router_firmware = APIRouter(prefix="/api/v1", tags=["Firmware"])

@router_firmware.get(
    "/firmware",
    response_model=OutputFirmwarePagination,
    summary="Get list of available firmwares."
)
async def get_list_firmware(
    node_id: Optional[int] = Query(default=None, ge=1),
    node_location: Optional[str] = Query(default=None, min_length=1, max_length=255),
    sensor_type: Optional[str] = Query(default=None, min_length=1, max_length=255),
    page: int = Query(1, ge=1),
    per_page: int = Query(5, ge=1, le=100),
    service_firmware: ServiceFirmware = Depends()
):
    response_get = await service_firmware.get_list_firmware(
        page=page,
        per_page=per_page,
        node_id=node_id or None,
        node_location=node_location or None,
        sensor_type=sensor_type or None
    )
    return response_get

@router_firmware.get(
    "/firmware/get_by_node_name/{node_name}",
    response_model=OuputFirmwareByNodeName,
    summary="Get list firmware by node_name."
)
async def get_by_node_name(
    node_name: str,
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    service_firmware: ServiceFirmware = Depends()
):
    response_get = await service_firmware.get_by_node_name(
        node_name,
        page=page,
        per_page=per_page,
    )
    return response_get 

@router_firmware.post("/firmware/add")
async def add_firmware(
    form: UploadFirmwareForm = Depends(),
    service: ServiceFirmware = Depends()
):
    try:
        await service.add_firmware(form)
        return JSONResponse(status_code=200, content={"message": "Add firmware successfully."})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})    

@router_firmware.put("/firmware/update/")
async def update_firmware(
    node_name: Optional[str] = Query(...),
    form: UpdateFirmwareForm = Depends(),
    service_firmware: ServiceFirmware = Depends()
):
    try:
        await service_firmware.update_firmware(node_name, form)
        return JSONResponse(status_code=200, content={"message": "Update firmware successfully."})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

@router_firmware.put("/firmware/update/firmware_description/")
async def update_firmware_description(
    node_name: str = Query(...),
    firmware_version: str = Query(...),
    form: UpdateFirmwareDescriptionForm = Depends(),
    service_firmware: ServiceFirmware = Depends()
):
    try:
        await service_firmware.update_firmware_description(node_name, firmware_version, form)
        return JSONResponse(status_code=200, content={"message": "Update firmware description successfully."})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})

@router_firmware.delete("/firmware/delete/")
async def delete_firmware(
    node_name: str = Query(...),
    firmware_version: Optional[str] = Query(None),
    service_firmware: ServiceFirmware = Depends()
):
    try:
        if firmware_version:
            await service_firmware.delete_by_firmware_version(node_name, firmware_version)
            msg = f"Deleted firmware '{firmware_version}' from node '{node_name}'"
        else:
            await service_firmware.delete_all_by_node_name(node_name)
            msg = f"Deleted all firmwares from node '{node_name}'"

        return JSONResponse(status_code=200, content={"message": msg})
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
        