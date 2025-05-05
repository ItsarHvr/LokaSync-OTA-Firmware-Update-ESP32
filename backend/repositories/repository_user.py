# Handle user-related database operations.

from firebase_admin import auth


class UserRepository:
    """ User repository to interact / query with Firebase Authentication. """
    def __init__(self):
        self.auth = auth
        
    # Create user / register.
    async def create_new_user(self, email: str, password: str, first_name: str) -> dict:
        """ Create a new user to Firebase Auth. """
        return self.auth.create_user(
            email=email,
            password=password,
            display_name=first_name
        )
    
    # After Register -> Send email verification link.
    async def verify_email(self, email: str) -> str:
        return self.auth.generate_email_verification_link(email=email, action_code_settings=None)

    # Login -> search specific user email.
    async def find_user_by_email(self, email: str) -> dict:
        """ Find a user by email in Firebase Auth. """
        return self.auth.get_user_by_email(email=email)
    
    # Generate user reset password link.
    async def reset_user_password(self, new_email: str) -> str:
        return self.auth.generate_password_reset_link(email=new_email, action_code_settings=None)

    # Delete user account.
    async def delete_user(self, uid: str) -> dict:
        return self.auth.delete_user(uid=uid)