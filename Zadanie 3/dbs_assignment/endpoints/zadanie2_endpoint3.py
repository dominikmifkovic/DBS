from fastapi import APIRouter
from typing import Dict
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()
@router.get("/v2/tags/{tagname}/stats", response_model=Dict)
async def zadanie2_endpoint3(tagname: str):
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
    query = f"""
        SELECT TO_CHAR(p.creationdate, 'day') AS day,
            ROUND((((COUNT(pt.post_id) 
            FILTER (WHERE t.tagname = '{tagname}'))::numeric) /
            COUNT(DISTINCT pt.post_id)::numeric) * 100.0, 2)
        FROM posts p
        JOIN post_tags pt ON p.id = pt.post_id
        JOIN tags t ON pt.tag_id = t.id
        GROUP BY EXTRACT(ISODOW FROM creationdate), day
        ORDER BY EXTRACT(ISODOW FROM creationdate)
    """
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    connection.close()
    return {"result":{
                result[0].replace(" ", ""): float(result[1]) for result in results
        }
    }