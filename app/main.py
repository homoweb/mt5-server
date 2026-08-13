from fastapi import FastAPI, HTTPException, Header, Depends
from pydantic import BaseModel, Field
from typing import Optional
import datetime
import os

app = FastAPI(
    title="Ultimate MT5 Bridge API - Full Suite",
    description="Complete and comprehensive REST API for MetaTrader 5 operations",
    version="3.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

API_SECRET = os.getenv("API_SECRET", "")
if not API_SECRET:
    raise RuntimeError("API_SECRET is not set")


def verify_token(x_api_key: Optional[str] = Header(default=None, alias="X-API-Key")):
    if x_api_key != API_SECRET:
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid API Key")
    return True


class MarketOrderRequest(BaseModel):
    symbol: str = Field(..., example="EURUSD")
    action: str = Field(..., example="BUY")
    volume: float = Field(..., example=0.1)
    sl: Optional[float] = Field(None, example=1.08500)
    tp: Optional[float] = Field(None, example=1.10500)
    deviation: Optional[int] = Field(20, example=20)
    magic: Optional[int] = Field(123456, example=123456)
    comment: Optional[str] = Field("API Market Order", example="MyOrder")


class PendingOrderRequest(BaseModel):
    symbol: str = Field(..., example="EURUSD")
    action: str = Field(..., example="BUY_LIMIT")
    volume: float = Field(..., example=0.1)
    price: float = Field(..., example=1.08000)
    sl: Optional[float] = Field(None, example=1.07500)
    tp: Optional[float] = Field(None, example=1.10000)
    magic: Optional[int] = Field(123456, example=123456)
    comment: Optional[str] = Field("API Pending Order", example="Pending1")


class ModifyPositionRequest(BaseModel):
    ticket: int = Field(..., example=12345678)
    sl: Optional[float] = Field(None, example=1.08500)
    tp: Optional[float] = Field(None, example=1.10500)


class PartialCloseRequest(BaseModel):
    ticket: int = Field(..., example=12345678)
    volume: float = Field(..., example=0.05)


@app.get("/", tags=["System"])
def root():
    return {"status": "online", "message": "Ultimate MT5 Bridge is running."}


@app.get("/api/account/info", tags=["Account"])
def get_account_info(authorized: bool = Depends(verify_token)):
    return {"status": "success", "data": {"login": 12345678}}


@app.post("/api/trade/open", tags=["Trading - Market"])
def open_market_order(order: MarketOrderRequest, authorized: bool = Depends(verify_token)):
    return {"status": "success", "message": f"{order.action} {order.symbol}", "ticket": 98765432}


@app.get("/api/market/price/{symbol}", tags=["Market & Positions"])
def get_symbol_price(symbol: str, authorized: bool = Depends(verify_token)):
    return {
        "status": "success",
        "symbol": symbol.upper(),
        "bid": 1.09348,
        "ask": 1.09352,
        "time": str(datetime.datetime.now())
    }
