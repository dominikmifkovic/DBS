from fastapi import APIRouter, Query
from typing import Dict
from dbs_assignment.config import settings
import psycopg2
router = APIRouter()

######################################################################################
# Endpointy 4 a 5 su zkombinovane kedze oba davaju poziadavku na /v2/posts/          #
# a potrebuju parameter limit. Rozdelenie je determinovane v kode na zaklade         #
# toho, ci je poskytnuta premenna duration pre endpoint4 alebo query pre endppoint5  #
######################################################################################

@router.get("/v2/posts/", response_model=Dict)
async def zadanie2_endpoint4a5(limit: int = Query(alias='limit'),duration: int = Query(alias='duration', default=None),_query: str = Query(alias='query', default=None)):
    connection = psycopg2.connect(
        host=settings.DATABASE_HOST,
        port=settings.DATABASE_PORT,
        dbname=settings.DATABASE_NAME,
        user=settings.DATABASE_USER,
        password=settings.DATABASE_PASSWORD
    )
    cursor = connection.cursor()
    if duration is not None:
        #Implementacia endpointu 4
        query = f"""
            SELECT p.id, TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'), 
                   p.viewcount, TO_CHAR(p.lasteditdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'), 
                   TO_CHAR(p.lastactivitydate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'), p.title, 
                   TO_CHAR(p.closeddate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF') AS cd,
            ROUND(EXTRACT(EPOCH FROM (p.closeddate - p.creationdate)) / 60.0, 2)
            FROM posts p
            WHERE p.closeddate IS NOT NULL
            AND EXTRACT(EPOCH FROM (p.closeddate - p.creationdate)) / 60.0 <= '{duration}'
            ORDER BY cd DESC
            LIMIT '{limit}';
        """
        cursor.execute(query)
        results = cursor.fetchall()
        cursor.close()
        connection.close()
        return {"items": [{
                    "id": result[0],
                    "creationdate": result[1],
                    "viewcount": result[2],
                    "lasteditdate": result[3],
                    "lastactivitydate": result[4],
                    "title": result[5],
                    "closeddate": result[6],
                    "duration": float(result[7])} for result in results]}

    elif _query is not None:
        #Implementacia endpointu 5
        cursor = connection.cursor()
        query = f"""
            SELECT p.id, TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF') AS cd,
                   p.viewcount, TO_CHAR(p.lasteditdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'), 
                   TO_CHAR(p.lastactivitydate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'), 
                   p.title, p.body, p.answercount, 
                   TO_CHAR(p.closeddate, 'YYYY-MM-DD"T"HH24:MI:SS.MSOF'), ARRAY_AGG(t.tagname)
            FROM posts p
            JOIN post_tags pt ON p.id = pt.post_id
            JOIN tags t ON pt.tag_id = t.id
            WHERE UNACCENT(LOWER(p.title)) LIKE UNACCENT(LOWER('%{_query}%')) OR UNACCENT(LOWER(p.body)) LIKE UNACCENT(LOWER('%{_query}%'))
            GROUP BY p.id, p.creationdate, p.viewcount, p.lasteditdate, p.lastactivitydate,
            p.title, p.body, p.answercount, p.closeddate
            ORDER BY cd DESC
            LIMIT {limit};
        """
        cursor.execute(query)
        results = cursor.fetchall()
        cursor.close()
        connection.close()
        return {"items": [{
                    "id": result[0],
                    "creationdate": result[1],
                    "viewcount": result[2],
                    "lasteditdate": result[3],
                    "lastactivitydate": result[4],
                    "title": result[5],
                    "body": result[6],
                    "answercount": result[7],
                    "closeddate": result[8],
                    "tags": result[9]} for result in results]}
    else:
        pass
    