from fastapi import APIRouter
from typing import Dict
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()
@router.get("/v2/posts/{post_id}/users", response_model=Dict)
async def zadanie2_endpoint1(post_id: int):
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
    query = f"""
        SELECT u.id, u.reputation, TO_CHAR(u.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'),
               u.displayname, TO_CHAR(u.lastaccessdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'),
               u.websiteurl, u.location, u.aboutme, u.views, u.upvotes, u.downvotes, u.profileimageurl,
               u.age, u.accountid
        FROM users u
        JOIN comments c ON u.id = c.userid
        WHERE c.postid = '{post_id}'
        ORDER BY c.creationdate DESC
    """
    cursor.execute(query)
    results = cursor.fetchall()
    cursor.close()
    connection.close()
    return {"items": [{
                "id": result[0],
                "reputation": result[1],
                "creationdate": result[2],
                "displayname": result[3],
                "lastaccessdate": result[4],
                "websiteurl": result[5],
                "location": result[6],
                "aboutme": result[7],
                "views": result[8],
                "upvotes": result[9],
                "downvotes": result[10],
                "profileimageurl": result[11],
                "age": result[12],
                "accountid": result[13]}for result in results]}
