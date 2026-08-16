import type { Metadata } from "next";
import "./globals.css";
import { ServiceWorkerRegistration } from './components/service-worker';

export const metadata: Metadata = {
  title: {
    default: 'My Routine Active',
    template: '%s · My Routine Active',
  },
  description: 'Estudos, treinos e finanças organizados em uma única rotina.',
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
    apple: '/app-icon.svg',
  },
  manifest: '/manifest.webmanifest',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR">
      <body className="antialiased">
        {children}
        <ServiceWorkerRegistration />
      </body>
    </html>
  );
}
