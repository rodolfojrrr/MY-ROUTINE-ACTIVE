import { eq, sql } from 'drizzle-orm';
import { getDb } from '../../../db';
import { appStates } from '../../../db/schema';
import { mergeState } from '../../lib/app-data';
import { getCurrentUser } from '../../lib/current-user';

export const dynamic = 'force-dynamic';

export async function GET() {
  const user = await getCurrentUser();
  if (!user) {
    return Response.json({ error: 'Não autenticado.' }, { status: 401 });
  }

  try {
    const db = await getDb();
    const [row] = await db
      .select()
      .from(appStates)
      .where(eq(appStates.userEmail, user.email))
      .limit(1);

    if (!row) {
      return Response.json({ state: null, updatedAt: null });
    }

    return Response.json({
      state: mergeState(JSON.parse(row.payload), user.displayName),
      updatedAt: row.updatedAt,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Falha ao carregar os dados.';
    return Response.json({ error: message }, { status: 500 });
  }
}

export async function PUT(request: Request) {
  const user = await getCurrentUser();
  if (!user) {
    return Response.json({ error: 'Não autenticado.' }, { status: 401 });
  }

  try {
    const body = (await request.json()) as { state?: unknown };
    const state = mergeState(body.state, user.displayName);
    const payload = JSON.stringify(state);

    if (payload.length > 900_000) {
      return Response.json({ error: 'O backup ultrapassou o limite permitido.' }, { status: 413 });
    }

    const db = await getDb();
    await db
      .insert(appStates)
      .values({ userEmail: user.email, payload })
      .onConflictDoUpdate({
        target: appStates.userEmail,
        set: { payload, updatedAt: sql`CURRENT_TIMESTAMP` },
      });

    return Response.json({ saved: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Falha ao salvar os dados.';
    return Response.json({ error: message }, { status: 500 });
  }
}
