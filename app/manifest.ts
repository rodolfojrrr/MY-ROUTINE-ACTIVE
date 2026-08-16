import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'My Routine Active',
    short_name: 'Routine Active',
    description: 'Estudos, treinos e finanças em uma única rotina.',
    start_url: '/dashboard',
    display: 'standalone',
    background_color: '#06101f',
    theme_color: '#06101f',
    orientation: 'portrait',
    icons: [
      { src: '/app-icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any' },
      { src: '/app-icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'maskable' },
    ],
  };
}
