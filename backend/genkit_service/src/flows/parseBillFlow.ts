import { genkit, z } from 'genkit';
import { googleAI, gemini20Flash } from '@genkit-ai/googleai';

// ── Genkit instance ────────────────────────────────────────────────────────────
const ai = genkit({
  plugins: [googleAI({ apiKey: process.env.GEMINI_API_KEY })],
});

// ── Output Schema ──────────────────────────────────────────────────────────────
// Must match the categories defined in AppStrings on the Flutter side.
export const ReceiptResultSchema = z.object({
  merchantName: z
    .string()
    .describe('The name of the merchant, shop, or payee shown on the receipt'),
  amount: z
    .number()
    .describe('The total/final amount paid. Must be a positive number without currency symbols'),
  date: z
    .string()
    .describe('Transaction date in YYYY-MM-DD format. Use today if not found'),
  category: z
    .string()
    .describe(
      'One of the exact category names from the allowed list that best matches this receipt',
    ),
  isIncome: z
    .boolean()
    .describe('True if this is income (e.g. salary slip, refund), false if it is an expense'),
  confidence: z
    .number()
    .min(0)
    .max(1)
    .describe(
      'Confidence score from 0.0 to 1.0. 1.0 = perfectly clear receipt. 0.0 = unreadable or not a receipt',
    ),
});

export type ReceiptResult = z.infer<typeof ReceiptResultSchema>;

// ── System Prompt ──────────────────────────────────────────────────────────────
const ALLOWED_CATEGORIES = [
  'Automobile / Car',
  'Bills / Utilities',
  'Charges / Fees',
  'Education',
  'Entertainment',
  'Food & Dining',
  'Gifts & Similar',
  'Health & Fitness',
  'Bonus',
  'Commission',
  'Interest',
  'Investments',
  'Received from Others',
  'Rental Income',
  'Salary',
  'Selling Assets',
  'Other',
];

const SYSTEM_PROMPT = `You are a financial data extractor for an expense tracker app.
Analyze the provided image (receipt, bill, invoice, payment screenshot, or utility bill).

Extract the following information:
1. merchantName: The exact name of the merchant, business, or payee. If it is a utility bill, use the company name. If it is a UPI/bank screenshot, use the recipient name.
2. amount: The TOTAL or FINAL amount paid. Must be a plain numeric value with NO commas and NO currency symbols (e.g. 1256.00 or 349.50, NEVER 1,256.00 or ₹1256). If multiple amounts appear, choose the largest one labeled as "Total", "Grand Total", "Amount", "Net Payable", or "Paid".
3. date: The transaction or bill date in YYYY-MM-DD format. If the date is ambiguous or missing, use today's date.
4. category: Select EXACTLY ONE category from this list:
${ALLOWED_CATEGORIES.map((c) => `   - "${c}"`).join('\n')}
   Match based on the merchant type: restaurants/food delivery → "Food & Dining", electricity/water/gas bills → "Bills / Utilities", Uber/Ola/fuel → "Automobile / Car", hospital/pharmacy → "Health & Fitness", movies/OTT → "Entertainment", school/course fees → "Education", salary/payslip → "Salary" (and set isIncome: true), etc.
5. isIncome: Set to true ONLY for salary slips, refunds, cashback credited, or income receipts. For all regular purchases/bills, set to false.
6. confidence: Rate from 0.0 to 1.0 how clearly the image shows a readable financial document:
   - 1.0: Crystal clear, all fields extracted with certainty
   - 0.8-0.9: Clear, minor ambiguity in one field
   - 0.6-0.7: Partially visible or slightly blurry, some fields estimated
   - 0.3-0.5: Very blurry, partially cropped, or low-light image
   - 0.0-0.2: Not a receipt, completely unreadable, or irrelevant image

Return ONLY valid JSON. Do not add any explanation or markdown formatting around it.`;

// ── Genkit Flow ────────────────────────────────────────────────────────────────
export const parseBillFlow = ai.defineFlow(
  {
    name: 'parseBillFlow',
    inputSchema: z.object({
      imageBase64: z.string().describe('Base64-encoded JPEG/PNG image of the receipt'),
      mimeType: z
        .string()
        .optional()
        .default('image/jpeg')
        .describe('MIME type of the image, e.g. image/jpeg or image/png'),
    }),
    outputSchema: ReceiptResultSchema,
  },
  async (input) => {
    const { output } = await ai.generate({
      model: gemini20Flash,
      prompt: [
        {
          media: {
            url: `data:${input.mimeType};base64,${input.imageBase64}`,
          },
        },
        { text: SYSTEM_PROMPT },
      ],
      output: { schema: ReceiptResultSchema },
      config: {
        temperature: 0.1, // Low temperature for deterministic data extraction
        maxOutputTokens: 512,
      },
    });

    if (!output) {
      throw new Error('Gemini returned an empty response. Please try again.');
    }

    // Clamp confidence to valid range
    output.confidence = Math.max(0, Math.min(1, output.confidence));

    // Ensure amount is positive
    output.amount = Math.abs(output.amount);

    return output;
  },
);

export { ai };
