from fastapi import APIRouter, Query
from typing import Dict, Optional
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()

@router.get("/v3/posts/{post_id}", response_model=Dict)
async def zadanie3_endpoint4(post_id: int, limit: Optional[int] = Query(alias='limit', default=None)):
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
        SELECT name, STRING_AGG(thread_posts.body, ''), 
               TO_CHAR(creationdate AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.FF3OF')
        FROM (
            SELECT 
                p.id,
                p.parentid,
                (SELECT displayname FROM users WHERE p.owneruserid = users.id) AS name,  
                p.body,
                p.creationdate
            FROM posts p
            WHERE p.id = {post_id}
            
            UNION
            
            SELECT
                p.id,
                p.parentid,
                (SELECT displayname FROM users WHERE p.owneruserid = users.id) AS name,
                p.body,
                p.creationdate
            FROM posts p
            JOIN (SELECT p.id 
                  FROM posts p
                  WHERE p.id = {post_id}
            ) AS tp ON p.parentid = tp.id 
        ) AS thread_posts
        GROUP BY thread_posts.creationdate, name
        ORDER BY creationdate ASC
        LIMIT {limit};
    """
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    connection.close()
    return {"items": [{
                "displayname": result[0],
                "body": result[1],
                "created_at": result[2]} for result in results]}