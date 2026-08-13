# MetaTrader 5 + FastAPI Middleware Server

[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://www.docker.com/)
[![Laravel](https://img.shields.io/badge/Laravel-Compatible-FF2D20.svg)](https://laravel.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.0.0.0%3A8000-009688.svg)](https://fastapi.tiangolo.com/)
[![MetaTrader 5](https://img.shields.io/badge/MetaTrader-5-0078D7.svg)](https://www.mql5.com/)

A fully automated, Dockerized environment designed to run **MetaTrader 5** (via Wine / noVNC) alongside a lightweight **FastAPI REST API Bridge**. This enables web backends like **Laravel**, Node.js, or PHP to programmatically execute trades on MT5 with zero-latency.

---

## 🚀 Features

* **noVNC Web Interface:** Access and manage your MT5 terminal directly via browser over HTTPS.
* **FastAPI Bridge:** Native Python `MetaTrader5` integration running in Wine background.
* **Auto-generated Docs:** Built-in Interactive **Swagger UI** and **ReDoc**.
* **Laravel Ready:** Pre-configured REST endpoints for `BUY` / `SELL` execution.
* **SSL & Reverse Proxy:** Automated Nginx configuration with Certbot SSL certificates.

---

## ⚙️ Initial MetaTrader 5 Setup

Once the deployment script completes, open your domain (`https://your-domain.com`) in a web browser:

1. **Broker Login:**
   * Finish the MT5 setup wizard inside the noVNC interface.
   * Go to **File > Login to Trade Account** and enter your broker credentials.
2. **Enable Algo Trading:**
   * Open **Tools > Options** (or press `Ctrl + O`).
   * Navigate to the **Expert Advisors** tab.
   * Check **Allow Algo Trading** and click **OK**.

---

## 📚 API Documentation & Interactive Swagger

The FastAPI service generates real-time OpenAPI schemas and interactive testing pages:

| Resource | Endpoint / URL | Description |
| :--- | :--- | :--- |
| **Swagger UI** | `https://your-domain.com/docs` | Interactive API tester & payload schemas |
| **ReDoc** | `https://your-domain.com/redoc` | Structured technical API reference |
| **OpenAPI Spec** | `https://your-domain.com/openapi.json` | Import directly into **Postman** or **Insomnia** |

---

## 💻 Laravel Integration Example

Use Laravel's `Http` client to dispatch trade execution requests to the Python bridge:

```php
namespace App\Services;

use Illuminate\Support\Facades\Http;

class MetaTraderService
{
    protected string $baseUrl;
    protected string $apiKey;

    public function __construct()
    {
        $this->baseUrl = config('services.mt5.url', '[http://127.0.0.1:8000](http://127.0.0.1:8000)');
        $this->apiKey = config('services.mt5.key', 'MY_SECURE_TOKEN_123');
    }

    public function openPosition(string $symbol, string$action, float $volume, float$sl = 0.0, float $tp = 0.0)     {$response = Http::withHeaders([
            'x-api-key' => $this->apiKey,
            'Content-Type' => 'application/json',
        ])->post("{$this->baseUrl}/api/trade", [
            'symbol' => $symbol,
            'action' => strtoupper($action), // BUY or SELL
            'volume' => $volume,
            'sl'     => $sl,
            'tp'     => $tp,
        ]);

        if ($response->successful()) {
            return $response->json(); // Example response: ["status" => "success", "order_id" => 1029384]
        }

        throw new \Exception("MT5 Execution Failed: " . $response->body());
    }
}
```
## ⚡ One-Line Installation

Run the following command on a clean Ubuntu server (requires root / sudo permissions):

```bash
git clone https://github.com/homoweb/mt5-server.git ~/mt5-server && cd ~/mt5-server && chmod +x deploy/install.sh docker/entrypoint.sh && ./deploy/install.sh


