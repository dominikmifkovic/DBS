from fastapi import APIRouter

from dbs_assignment.endpoints import zadanie1_version
from dbs_assignment.endpoints import zadanie2_endpoint1
from dbs_assignment.endpoints import zadanie2_endpoint2
from dbs_assignment.endpoints import zadanie2_endpoint3
from dbs_assignment.endpoints import zadanie2_endpoint4a5
from dbs_assignment.endpoints import zadanie3_endpoint1
from dbs_assignment.endpoints import zadanie3_endpoint2
from dbs_assignment.endpoints import zadanie3_endpoint3
from dbs_assignment.endpoints import zadanie3_endpoint4

router = APIRouter()
router.include_router(zadanie1_version.router, tags=["zadanie1_version"])
router.include_router(zadanie2_endpoint1.router, tags=["zadanie2_endpoint1"])
router.include_router(zadanie2_endpoint2.router, tags=["zadanie2_endpoint2"])
router.include_router(zadanie2_endpoint3.router, tags=["zadanie2_endpoint3"])
router.include_router(zadanie2_endpoint4a5.router, tags=["zadanie2_endpoint4a5"])
router.include_router(zadanie3_endpoint1.router, tags=["zadanie3_endpoint1"])
router.include_router(zadanie3_endpoint2.router, tags=["zadanie3_endpoint2"])
router.include_router(zadanie3_endpoint3.router, tags=["zadanie3_endpoint3"])
router.include_router(zadanie3_endpoint4.router, tags=["zadanie3_endpoint4"])
