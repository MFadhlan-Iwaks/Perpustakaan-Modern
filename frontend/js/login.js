document.addEventListener('DOMContentLoaded', () => {
    const loginForm = document.getElementById('loginForm');

    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const email = document.getElementById('loginEmail').value;
            const password = document.getElementById('loginPassword').value;

            try {
                const response = await fetch(`${BASE_URL}/login`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ email, password })
                });

                const data = await response.json();

                if (response.ok) {
                    // Simpan JWT ke localStorage menggunakan helper dari api.js
                    setTokens(data.accessToken, data.refreshToken);
                    
                    // Pindah ke dashboard
                    window.location.href = 'dashboard.html';
                } else {
                    alert(`Login Gagal: ${data.message}`);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Terjadi kesalahan saat menghubungi server.');
            }
        });
    }
});