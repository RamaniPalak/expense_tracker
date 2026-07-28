import 'dotenv/config';
import express, { Request, Response, NextFunction } from 'express';
import { parseBillFlow, ReceiptResult } from './flows/parseBillFlow';

// ── Validate required environment variables ────────────────────────────────────
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (!GEMINI_API_KEY) {
  console.error('[FATAL] GEMINI_API_KEY environment variable is not set.');
  process.exit(1);
}

const PORT = parseInt(process.env.PORT ?? '3001', 10);

// ── Express app ────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json({ limit: '10mb' })); // Allow up to 10MB for base64 images

// ── Health check ───────────────────────────────────────────────────────────────
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: 'genkit-receipt-service', version: '1.0.0' });
});

// ── POST /scan-receipt ─────────────────────────────────────────────────────────
// Body: { "imageBase64": "<base64 string>", "mimeType": "image/jpeg" }
// Returns: ReceiptResult JSON
app.post('/scan-receipt', async (req: Request, res: Response) => {
  try {
    const { imageBase64, mimeType } = req.body as {
      imageBase64?: string;
      mimeType?: string;
    };

    // ── Input validation ───────────────────────────────────────────────────────
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      res.status(400).json({ error: 'Missing or invalid "imageBase64" field in request body.' });
      return;
    }

    // Rough size check: Base64 of a 4MB file is ~5.3MB string
    const estimatedSizeBytes = (imageBase64.length * 3) / 4;
    if (estimatedSizeBytes > 5_000_000) {
      res.status(413).json({
        error: 'Image too large. Please compress the image to under 4MB before sending.',
      });
      return;
    }

    console.log(
      `[scan-receipt] Processing image (~${Math.round(estimatedSizeBytes / 1024)}KB)...`,
    );

    // ── Run the Genkit flow ────────────────────────────────────────────────────
    const result: ReceiptResult = await parseBillFlow({
      imageBase64,
      mimeType: mimeType ?? 'image/jpeg',
    });

    console.log(
      `[scan-receipt] Success: ${result.merchantName}, ₹${result.amount}, confidence=${result.confidence}`,
    );

    res.json(result);
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.error('[scan-receipt] Error:', message);
    res.status(500).json({
      error: `Failed to scan receipt: ${message}`,
    });
  }
});

// ── Global error handler ───────────────────────────────────────────────────────
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Unhandled error]', err.message);
  res.status(500).json({ error: 'Internal server error.' });
});

// ── Start server ───────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`[genkit-receipt-service] Listening on port ${PORT}`);
  console.log(`[genkit-receipt-service] Health check: http://localhost:${PORT}/health`);
  console.log(`[genkit-receipt-service] Scan endpoint: POST http://localhost:${PORT}/scan-receipt`);
});

export default app;
