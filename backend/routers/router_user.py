"""Router for authentication with Firebase Authentication.
- /api/v1/login: POST
- /api/v1/register: POST
- /api/v1/forgot-passwowrd: POST
"""

from fastapi import APIRouter, Depends

from dtos.dto_user import InputRegister, InputLogin, InputForgotPassword
from services.service_user import ServiceUser

router_user = APIRouter(prefix="/api/v1", tags=["User Auth"])

@router_user.post("/login") # /api/v1/login
async def login(input_login: InputLogin, service_user: ServiceUser = Depends()):
    """
    Login endpoint to authenticate a user.
    - Requires email and password.
    """
    response_login = await service_user.login(user=input_login)
    return response_login

@router_user.post("/register") # /api/v1/register
async def register(input_register: InputRegister, service_user: ServiceUser = Depends()):
    """
    Register endpoint to create a new user.
    - Requires full name, email, and password.
    """
    response_register = await service_user.register(new_user=input_register)
    return response_register

@router_user.post("/forgot-password") # /api/v1/forgot-password
async def forgot_password(input_forgot_password: InputForgotPassword, service_user: ServiceUser = Depends()):
    """
    Forgot password endpoint to send a password reset email.
    - Requires email.
    """
    response_forgot_password = await service_user.forgot_password(user=input_forgot_password)
    return response_forgot_password