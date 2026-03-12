// src/lib/api.js

export const BASE_URL = 'http://localhost:5000/api';

export const setTokens = (accessToken, refreshToken) => {
    if (typeof window !== 'undefined') {
        localStorage.setItem('accessToken', accessToken);
        localStorage.setItem('refreshToken', refreshToken);
    }
};

export const getToken = () => {
    if (typeof window !== 'undefined') {
        return localStorage.getItem('accessToken');
    }
    return null;
};

export const clearTokens = () => {
    if (typeof window !== 'undefined') {
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
    }
};

export const getAuthHeaders = () => {
    const token = getToken();
    return {
        'Content-Type': 'application/json', // <-- Tambahkan baris ini
        'Authorization': token ? `Bearer ${token}` : ''
    };
};

export const isAuthenticated = () => {
    return !!getToken();
};