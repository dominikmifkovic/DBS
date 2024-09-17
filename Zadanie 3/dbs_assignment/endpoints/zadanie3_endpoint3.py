from fastapi import APIRouter, Query
from typing import Dict, Optional
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()

@router.get("/v3/tags/{tag}/comments/{position}", response_model=Dict)
async def zadanie3_endpoint3(tag: str, position: int, limit: Optional[int] = Query(alias='limit', default=None)):
    if limit is None:
        limit = "ALL"
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
        
    query = f"""
        SELECT id, displayname, body, text, score, position
            FROM(
                SELECT ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY c.creationdate) as position,
                c.id,c.text,c.score, p.body, u.displayname
                FROM comments c
                JOIN posts p ON p.id = c.postid
                JOIN post_tags pt ON p.id = pt.post_id
                JOIN tags t ON pt.tag_id = t.id
                JOIN users u ON u.id = c.userid
                WHERE t.tagname = '{tag}'
                ORDER BY p.creationdate
            ) AS sub
        WHERE position = {position}
        LIMIT {limit};
    """
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    connection.close()
    return {"items": [{
                "id": result[0],
                "displayname": result[1],
                "body": result[2],
                "text": result[3],
                "score": result[4],
                "position": result[5]} for result in results]}