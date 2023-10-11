import axios from 'axios';

export async function getAsync(url, options = {}) {
   try {
      const defaultOptions = { method: 'get', url };
      const response = await axios({ ...defaultOptions, ...options });

      return response.data || null;
   } catch (error) {
      return null;
   }
}