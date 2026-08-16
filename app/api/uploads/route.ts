import { getCurrentUser } from '../../lib/current-user';

export const dynamic = 'force-dynamic';

type RoutineBucket = {
  put(key: string, value: ArrayBuffer, options?: { httpMetadata?: { contentType?: string } }): Promise<unknown>;
  get(key: string): Promise<{ body: ReadableStream<Uint8Array>; httpMetadata?: { contentType?: string } } | null>;
  delete(key: string): Promise<unknown>;
};

const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif']);

async function getBucket(): Promise<RoutineBucket> {
  const { env } = await import('cloudflare:workers');
  const bucket = (env as unknown as { BUCKET?: RoutineBucket }).BUCKET;
  if (!bucket) throw new Error('Armazenamento de imagens indisponível.');
  return bucket;
}

async function ownerPrefix(email: string) {
  const bytes = new TextEncoder().encode(email.trim().toLowerCase());
  const digest = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(digest)).map(value => value.toString(16).padStart(2, '0')).join('').slice(0, 24);
}

function extensionFor(contentType: string) {
  if (contentType === 'image/jpeg') return 'jpg';
  if (contentType === 'image/png') return 'png';
  if (contentType === 'image/webp') return 'webp';
  return 'gif';
}

export async function POST(request: Request) {
  const user = await getCurrentUser();
  if (!user) return Response.json({ error: 'Não autenticado.' }, { status: 401 });

  try {
    const form = await request.formData();
    const file = form.get('file');
    const requestedScope = String(form.get('scope') ?? 'study');
    const scope = requestedScope === 'training' || requestedScope === 'finance' ? requestedScope : 'study';
    if (!(file instanceof File)) return Response.json({ error: 'Selecione uma imagem.' }, { status: 400 });
    if (!ALLOWED_TYPES.has(file.type)) return Response.json({ error: 'Use JPG, PNG, WEBP ou GIF.' }, { status: 415 });
    if (file.size <= 0 || file.size > MAX_IMAGE_BYTES) return Response.json({ error: 'A imagem deve ter no máximo 8 MB.' }, { status: 413 });

    const prefix = await ownerPrefix(user.email);
    const key = `${prefix}/${scope}/${Date.now()}-${crypto.randomUUID()}.${extensionFor(file.type)}`;
    const bucket = await getBucket();
    await bucket.put(key, await file.arrayBuffer(), { httpMetadata: { contentType: file.type } });

    return Response.json({
      attachment: {
        id: crypto.randomUUID(),
        storageKey: key,
        name: file.name || 'imagem',
        contentType: file.type,
        size: file.size,
        url: `/api/uploads?key=${encodeURIComponent(key)}`,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Não foi possível enviar a imagem.';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function GET(request: Request) {
  const user = await getCurrentUser();
  if (!user) return Response.json({ error: 'Não autenticado.' }, { status: 401 });

  try {
    const key = new URL(request.url).searchParams.get('key') ?? '';
    const prefix = await ownerPrefix(user.email);
    if (!key.startsWith(`${prefix}/`)) return Response.json({ error: 'Imagem não encontrada.' }, { status: 404 });

    const object = await (await getBucket()).get(key);
    if (!object) return Response.json({ error: 'Imagem não encontrada.' }, { status: 404 });
    return new Response(object.body, {
      headers: {
        'content-type': object.httpMetadata?.contentType ?? 'application/octet-stream',
        'cache-control': 'private, max-age=3600',
        'x-content-type-options': 'nosniff',
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Não foi possível abrir a imagem.';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function DELETE(request: Request) {
  const user = await getCurrentUser();
  if (!user) return Response.json({ error: 'Não autenticado.' }, { status: 401 });

  try {
    const key = new URL(request.url).searchParams.get('key') ?? '';
    const prefix = await ownerPrefix(user.email);
    if (!key.startsWith(`${prefix}/`)) return Response.json({ error: 'Imagem não encontrada.' }, { status: 404 });
    await (await getBucket()).delete(key);
    return Response.json({ deleted: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Não foi possível remover a imagem.';
    return Response.json({ error: message }, { status: 500 });
  }
}
