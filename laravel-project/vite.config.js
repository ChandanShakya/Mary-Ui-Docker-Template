import { defineConfig } from 'vite';
import laravel from 'laravel-vite-plugin';
import tailwindcss from '@tailwindcss/vite';
import livewire from '@defstudio/vite-livewire-plugin';

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: false, // Disable laravel's auto-refresh to avoid conflicts with livewire
        }),
        tailwindcss(),
        livewire({
            refresh: ['resources/css/app.css'], // Will refresh CSS as well when Livewire components change
        }),
    ],
    server: {
        host: '0.0.0.0',
        port: 5173,
        hmr: {
            host: '192.168.18.153',  // Changed to use specific IP address
            protocol: 'ws',
            port: 5173,
        },
    },
});
