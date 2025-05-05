from pydantic import BaseModel


class BasePage(BaseModel):
    """ Base class for pagination. """
    page: int
    per_page: int
    total_data: int
    total_page: int