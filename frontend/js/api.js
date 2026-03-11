// Konfigurasi URL Backend
const BASE_URL = 'http://localhost:5000/api';

// Helper untuk menyimpan token setelah login
const setTokens = (accessToken, refreshToken) => {
    localStorage.setItem('accessToken', accessToken);
    localStorage.setItem('refreshToken', refreshToken);
};

// Helper untuk mengambil access token
const getToken = () => {
    return localStorage.getItem('accessToken');
};

// Helper untuk menghapus token (saat logout)
const clearTokens = () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
};

// Helper untuk membuat Headers yang otomatis menyisipkan JWT Token
const getAuthHeaders = () => {
    const token = getToken();
    return {
        'Content-Type': 'application/json',
        'Authorization': token ? `Bearer ${token}` : ''
    };
};

// Cek apakah user sudah login (punya token)
const isAuthenticated = () => {
    return !!getToken();
};