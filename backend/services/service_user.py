from fastapi import Depends
from fastapi.responses import JSONResponse
from fastapi.exceptions import HTTPException
from firebase_admin import auth

from dtos.dto_user import InputRegister, InputLogin, InputForgotPassword
from repositories.repository_user import UserRepository


class ServiceUser:
    """ 
    Service user for login, register, and reset password.
    """
    def __init__(self, user_repository: UserRepository = Depends()):
        self.auth = auth
        self.user_repository = user_repository

    async def register(self, new_user: InputRegister) -> dict:
        """ Register a new user. """
        try:
            created_user = await self.user_repository.create_new_user(
                email=new_user.email,
                password=new_user.password,
                first_name=new_user.full_name.split(" ")[0] # Only display first name!.
            )
            email_verification_link = await self.user_repository.verify_email(email=created_user.email)

            user_data = {
                "uid": created_user.uid,
                "email": created_user.email,
                "display_name": created_user.display_name,
                "email_verification_link": email_verification_link
            }

            return JSONResponse(
                status_code=201,
                content={
                    "message": "User registered successfully. Please verify your email.",
                    "user_data": user_data
                }
            )
        except self.auth.EmailAlreadyExistsError:
            return HTTPException(status_code=400, detail="email already registered.")
        except ValueError as e:
            return HTTPException(status_code=400, detail=str(e))

    async def login(self, user: InputLogin) -> dict:
        """ Login user. """
        try:
            user = await self.user_repository.find_user_by_email(email=user.email)

            user_data = {
                "uid": user.uid,
                "email": user.email,
                "display_name": user.display_name.split(" ")[0]
            }

            return JSONResponse(
                status_code=200,
                content={
                    "message": "Login successfully.",
                    "user_data": user_data
                }
            )
        except self.auth.UserNotFoundError:
            return HTTPException(status_code=400, detail="user not found.")
        except ValueError as e:
            return HTTPException(status_code=400, detail=str(e))

    async def forgot_password(self, user: InputForgotPassword) -> dict:
        """ Send a password reset email to the user. """
        try:
            reset_password_link = await self.user_repository.reset_user_password(email=user.email)

            return JSONResponse(
                status_code=200,
                content={
                    "message": "Please follow the instructions in the reset password link.",
                    "reset_password_link": reset_password_link
                }
            )
        except self.auth.ResetPasswordExceedLimitError:
            return HTTPException(status_code=400, detail="reset password limit exceeded.")
        except self.auth.UnexpectedResponseError:
            return HTTPException(status_code=400, detail="Failed to generate reset password link.")
        except ValueError as e:
            return HTTPException(status_code=400, detail=str(e))