# Genkit Receipt Scanning Service

A lightweight Node.js microservice that uses **Firebase Genkit** + **Gemini 2.0 Flash** to extract structured data from receipt/bill photos.

## What it does

Exposes a single HTTP endpoint `POST /scan-receipt` that accepts a Base64-encoded image and returns:

```json
{
  "merchantName": "Swiggy",
  "amount": 349.00,
  "date": "2026-07-22",
  "category": "Food & Dining",
  "isIncome": false,
  "confidence": 0.95
}
```

The `category` field always matches one of the app's `AppStrings` category names so the Flutter form can auto-select it.

## Local Development

### Prerequisites
- Node.js 18+
- A Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey)

### Setup

```bash
cd backend/genkit_service

# Install dependencies
npm install

# Copy env file and add your key
cp .env.example .env
# Edit .env and set GEMINI_API_KEY=your_key_here

# Run in dev mode (hot reload)
npm run dev
```

The service starts at **http://localhost:3001**.

### Test it

```bash
# Health check
curl http://localhost:3001/health

# Scan a receipt image
# 1. Get a base64-encoded image:
base64 -w 0 your_receipt.jpg > receipt_b64.txt

# 2. Call the endpoint:
curl -X POST http://localhost:3001/scan-receipt \
  -H "Content-Type: application/json" \
  -d "{\"imageBase64\": \"$(cat receipt_b64.txt)\", \"mimeType\": \"image/jpeg\"}"
```

## With Docker Compose

The service is included in `backend/backend_server/docker-compose.yaml`:

```bash
cd backend/backend_server

# Set GEMINI_API_KEY in your shell or in a .env file
export GEMINI_API_KEY=your_key_here

# Start all services (postgres, redis, genkit)
docker compose up -d

# Check genkit logs
docker compose logs -f genkit
```

The service runs on port **3001** — accessible internally at `http://genkit:3001` from other Docker services.

## Flutter Integration

The Flutter app calls this service via `GenkitReceiptOcrDataSourceImpl`.

For local development:
- **Android emulator**: service is at `http://10.0.2.2:3001` (default)
- **Physical device on same network**: pass `--dart-define=GENKIT_URL=http://192.168.x.x:3001`
- **Production**: pass `--dart-define=GENKIT_URL=https://your-deployed-service-url`

```bash
# Run Flutter app pointing to local genkit service
flutter run --dart-define=GENKIT_URL=http://10.0.2.2:3001
```

## Production Deployment

Build and push the Docker image:

```bash
docker build -t genkit-receipt-service:latest .
# Push to your container registry and deploy
```

Or deploy to Cloud Run, Railway, Render, etc. — any Node.js-compatible host.

Set environment variables:
- `GEMINI_API_KEY` — required
- `PORT` — optional, defaults to 3001
