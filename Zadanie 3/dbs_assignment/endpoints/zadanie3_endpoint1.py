from fastapi import APIRouter, Query
from typing import Dict
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()

@router.get("/v3/users/{user_id}/badge_history", response_model=Dict)
async def zadanie3_endpoint1(user_id: int):
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
        
    query = f"""
        SELECT id, title, type, TO_CHAR(date AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.FF3OF'), 
            CASE 
                WHEN type = 'post' THEN (ROW_NUMBER() OVER ()) - 10 
                ELSE ROW_NUMBER() OVER () 
            END AS rank
        FROM (
            SELECT *,
                ROW_NUMBER() OVER (PARTITION BY type, post_group ORDER BY date, id) AS rank
            FROM (
                SELECT *,
                    LEAD(type) OVER (ORDER BY date) AS next_type,
                    SUM(CASE WHEN type = 'post' THEN 1 ELSE 0 END) OVER (ORDER BY date) AS post_group
                FROM (
                    SELECT p.id, p.title, p.creationdate AS date, 'post' AS type
                    FROM posts p
                    WHERE p.owneruserid = {user_id}
                    
                    UNION ALL
                    
                    SELECT b.id, b.name, b.date AS date, 'badge' AS type
                    FROM badges b
                    JOIN (
                        SELECT id, creationdate AS date, LEAD(creationdate) OVER (ORDER BY creationdate) AS next_post_date
                        FROM posts
                        WHERE owneruserid = {user_id}
                    ) p ON b.date > p.date AND (b.date < p.next_post_date OR p.next_post_date IS NULL)
                    WHERE b.userid = {user_id}
                ) AS unioned_posts_badges
            ) AS grouped_posts_badges
            WHERE NOT (type = 'post' AND next_type = 'post')
        ) AS ranked_posts_badges
        WHERE CASE WHEN type = 'badge' THEN rank = 1 ELSE TRUE END
        ORDER BY date;
    """
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    connection.close()
    return {"items": [{
                "id": result[0],
                "title": result[1],
                "type": result[2],
                "created_at": result[3],
                "position": result[4]} for result in results]}