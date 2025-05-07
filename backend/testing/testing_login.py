import requests
import os
from dotenv import load_dotenv

dotenv_path = os.path.join(os.path.dirname(__file__), "../.env")
load_dotenv(dotenv_path=dotenv_path)

def login_user(email: str, password: str):
    API_KEY = os.getenv("API_KEY")
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    response = requests.post(url, json=payload)
    if response.status_code == 200:
        return response.json()  # contains idToken, refreshToken, etc
    else:
        raise ValueError("Login failed: " + response.json().get("error", {}).get("message", "Unknown error"))

# Testing.
user_email = os.getenv("TESTING_USER")
user_password = os.getenv("TESTING_PASSWORD")
print(login_user(email=user_email, password=user_password))
