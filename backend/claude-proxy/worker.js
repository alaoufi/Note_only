/**
 * وسيط Claude API لتطبيق «مذكراتي / ملاحظات».
 * ─────────────────────────────────────────────
 * الغرض: إبقاء مفتاح Anthropic سرًّا على الخادم بعيدًا عن أجهزة المستخدمين.
 * يستقبل جسم رسائل Anthropic كما هو من التطبيق، يحقن المفتاح وترويسة الإصدار،
 * ثم يمرّره إلى https://api.anthropic.com/v1/messages ويعيد الردّ.
 *
 * النشر على Cloudflare Workers:
 *   1) أنشئ Worker جديدًا والصق هذا الملف.
 *   2) أضف متغيّرًا سرّيًّا:  ANTHROPIC_API_KEY = مفتاحك (sk-ant-…)
 *      (Settings → Variables → Add → Encrypt)
 *   3) (اختياريّ لكن موصى به) أضف سرًّا مشتركًا:  APP_SHARED_SECRET = نصّ عشوائيّ
 *      واضبط نفس القيمة في التطبيق: إعدادات المساعد ← «سرّ التطبيق».
 *   4) انشر، وضع رابط الـ Worker في التطبيق:
 *      - إمّا وقت البناء:  --dart-define=AI_ENDPOINT=https://your.workers.dev
 *      - أو في «إعدادات المساعد ← رابط الخدمة».
 *
 * ملاحظات أمان: يقتصر على POST، يتحقّق من السرّ المشترك إن ضُبط، ويحدّ من حجم
 * الطلب. أضِف Rate Limiting من لوحة Cloudflare لمنع الإساءة.
 */

const ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
const ANTHROPIC_VERSION = '2023-06-01';
const MAX_BODY_BYTES = 200 * 1024; // 200KB سقف للطلب

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'content-type, x-app-secret',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS });
    }
    if (request.method !== 'POST') {
      return json({ error: 'method_not_allowed' }, 405);
    }

    // تحقّق من السرّ المشترك (إن ضُبط في البيئة).
    if (env.APP_SHARED_SECRET) {
      const provided = request.headers.get('x-app-secret') || '';
      if (provided !== env.APP_SHARED_SECRET) {
        return json({ error: 'unauthorized' }, 401);
      }
    }

    if (!env.ANTHROPIC_API_KEY) {
      return json({ error: 'server_not_configured' }, 500);
    }

    const raw = await request.text();
    if (raw.length > MAX_BODY_BYTES) {
      return json({ error: 'payload_too_large' }, 413);
    }

    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      return json({ error: 'invalid_json' }, 400);
    }

    // حارس اختياريّ: قيّد max_tokens كي لا يُساء الاستخدام.
    if (typeof body.max_tokens !== 'number' || body.max_tokens > 8192) {
      body.max_tokens = Math.min(body.max_tokens || 4096, 8192);
    }

    let upstream;
    try {
      upstream = await fetch(ANTHROPIC_URL, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': ANTHROPIC_VERSION,
        },
        body: JSON.stringify(body),
      });
    } catch {
      return json({ error: 'upstream_unreachable' }, 502);
    }

    // مرّر جسم الردّ وحالته كما هما (يتضمّن content[].text المتوقَّع في التطبيق).
    const text = await upstream.text();
    return new Response(text, {
      status: upstream.status,
      headers: { 'content-type': 'application/json', ...CORS },
    });
  },
};

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json', ...CORS },
  });
}
