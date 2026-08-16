import { sql } from 'drizzle-orm';
import { sqliteTable, text } from 'drizzle-orm/sqlite-core';

export const appStates = sqliteTable('app_states', {
  userEmail: text('user_email').primaryKey(),
  payload: text('payload').notNull(),
  updatedAt: text('updated_at').notNull().default(sql`CURRENT_TIMESTAMP`),
});
