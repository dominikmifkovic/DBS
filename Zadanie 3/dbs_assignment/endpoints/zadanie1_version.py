from fastapi import APIRouter
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()
@router.get("/v1/status")
async def read_root():
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
    cursor.execute("SELECT version()")
    result = cursor.fetchone()[0]
    cursor.close()
    connection.close()
    return {"version": result}
