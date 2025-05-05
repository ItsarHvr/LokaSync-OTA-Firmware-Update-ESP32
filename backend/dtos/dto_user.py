# HANDLE BODY REQUESTS FOR USER AUTHENTICATION

from pydantic import BaseModel, EmailStr, Field, field_validator

class InputLogin(BaseModel):
    email: EmailStr = Field(pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    password: str = Field(min_length=8)

    @field_validator("password")
    def validate_password(cls, value):
        if not any(char.isdigit() for char in value):
            raise ValueError("password must contain at least one digit.")
        if not any(char.isupper() for char in value):
            raise ValueError("password must contain at least one uppercase letter.")
        if not any(char.islower() for char in value):
            raise ValueError("password must contain at least one lowercase letter.")
        if not any(char in "!@#$%^&*()-_+=<>?{}[]|:;\"'`~" for char in value):
            raise ValueError("password must contain at least one special character.")
        return value

    class Config:
        json_schema_extra = {
            "example": {
                "email": "youremail@example.com",
                "password": "SupersecretPassword!23"
            }
        }

class InputRegister(BaseModel):
    full_name: str = Field(min_length=3)
    email: EmailStr = Field(pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    password: str = Field(min_length=8)
    
    @field_validator("password")
    def validate_password(cls, value):
        if not any(char.isdigit() for char in value):
            raise ValueError("password must contain at least one digit.")
        if not any(char.isupper() for char in value):
            raise ValueError("password must contain at least one uppercase letter.")
        if not any(char.islower() for char in value):
            raise ValueError("password must contain at least one lowercase letter.")
        if not any(char in "!@#$%^&*()-_+=<>?{}[]|:;\"'`~" for char in value):
            raise ValueError("password must contain at least one special character.")
        return value

    class Config:
        json_schema_extra = {
            "example": {
                "full_name": "John Doe",
                "email": "youremail@example.com",
                "password": "SupersecretPassword!23"
            }
        }

class InputForgotPassword(BaseModel):
    new_email: EmailStr = Field(pattern=r'^[\w\.-]+@[\w\.-]+\.\w+$')

    class Config:
        json_schema_extra = {
            "example": {
                "new_email": "yournewemail@example.com"
            }
        }