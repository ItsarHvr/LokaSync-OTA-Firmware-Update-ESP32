from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

import firebase_admin
from firebase_admin import credentials

from routers.router_firmware import router_firmware
from routers.router_log import router_log
from mqtts.service_mqtt import start_mqtt

app = FastAPI(
    title="LokaSync API",
    description="API for LokaSync, a system for updating IoT devices firmware via OTA.",
    version="1.0.0",
    docs_url="/api/v1/docs",
    redoc_url="/api/v1/redoc",
    openapi_url="/api/v1/openapi.json",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",     # Production
        "http://localhost:3000" # Development
    ],  # Allow all development ports
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods including OPTIONS
    allow_headers=["*"],  # Allow all headers
)

# Initialize firebase admin SDK
sa_path = "./serviceAccountKey.json"
print("Inisialisasi Firebase...")
if not firebase_admin._apps:
    cred = credentials.Certificate(sa_path)
    firebase_admin.initialize_app(cred)
    print("Firebase berhasil diinisialisasi!")
else:
    print("Firebase sudah terinisialisasi.")

# Include the router for user auth.
app.include_router(router_firmware)
app.include_router(router_log)

start_mqtt()