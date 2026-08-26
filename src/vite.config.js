import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { fileURLToPath, URL } from 'node:url';

export default defineConfig({
   plugins: [react()],

   // Beholder REACT_APP_-prefikset slik at .env-filene kan stå urørt.
   // Nye variabler kan gjerne bruke VITE_.
   envPrefix: ['VITE_', 'REACT_APP_'],

   // Erstatter baseUrl i jsconfig.json, som ga oss 'components/...' og 'utils/...'
   resolve: {
      alias: {
         components: fileURLToPath(new URL('./src/components', import.meta.url)),
         utils: fileURLToPath(new URL('./src/utils', import.meta.url))
      }
   },

   server: {
      port: 3000
   },

   // Octopus-pakkingen henter fra src/build, så output må ligge der og ikke i dist/
   build: {
      outDir: 'build'
   }
});
