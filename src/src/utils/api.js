export async function getAsync(url, { params } = {}) {
   try {
      const query = params ? `?${new URLSearchParams(params)}` : '';
      const response = await fetch(`${url}${query}`);

      if (!response.ok) {
         return null;
      }

      return await response.json();
   } catch (error) {
      return null;
   }
}
