import { getChatGPTUser, type ChatGPTUser } from '../chatgpt-auth';

export async function getCurrentUser(): Promise<ChatGPTUser | null> {
  const user = await getChatGPTUser();
  if (user) return user;
  if (process.env.NODE_ENV !== 'production') {
    return {
      displayName: 'Usuário de teste',
      email: 'usuario@preview.local',
      fullName: 'Usuário de teste',
    };
  }
  return null;
}
