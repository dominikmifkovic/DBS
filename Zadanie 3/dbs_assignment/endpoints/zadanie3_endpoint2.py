from fastapi import APIRouter, Query
from typing import Dict
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()

@router.get("/v3/tags/{tag}/comments", response_model=Dict)
async def zadanie3_endpoint2(tag: str, count: int = Query(alias = 'count', default = 0)):
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
        
    query = f"""
        SELECT post_id, post_title, author_displayname, text,
               TO_CHAR(p_created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.FF3OF'),
               TO_CHAR(created_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.FF3OF'),
               diff::text,
               (AVG(diff) OVER (PARTITION BY post_id ORDER BY created_at))::text 
        FROM (
            SELECT
                p.id AS post_id,
                p.title AS post_title,
                u.displayname AS author_displayname,
                c.text as text,
                p.creationdate AS p_created_at,
                c.creationdate AS created_at,
                CASE 
                    WHEN LAG(c.creationdate) OVER (PARTITION BY c.postid ORDER BY c.creationdate) IS NULL THEN c.creationdate - p.creationdate
                    ELSE c.creationdate - LAG(c.creationdate) OVER (PARTITION BY c.postid ORDER BY c.creationdate)
                END AS diff
            FROM comments c
            LEFT JOIN posts p ON c.postid = p.id
            LEFT JOIN users u ON c.userid = u.id
            JOIN post_tags pt ON p.id = pt.post_id
            JOIN tags t ON pt.tag_id = t.id
            WHERE t.tagname = '{tag}'
            AND p.commentcount > {count}
        ) AS sub
        ORDER BY post_id, created_at;
    """
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    connection.close()
    return {"items": [{
                "post_id": result[0],
                "title": result[1],
                "displayname": result[2],
                "text": result[3],
                "post_created_at": result[4],
                "created_at": result[5],
                "diff": result[6],
                "avg": result[7]} for result in results]}