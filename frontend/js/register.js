document.addEventListener('DOMContentLoaded', () => {
    const registerForm = document.getElementById('registerForm');

    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault(); // Mencegah reload halaman

            // Ambil nilai dari input
            const name = document.getElementById('regName').value;
            const email = document.getElementById('regEmail').value;
            const password = document.getElementById('regPassword').value;

            try {
                const response = await fetch(`${BASE_URL}/register`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ name, email, password })
                });

                const data = await response.json();

                if (response.ok) {
                    alert('Registrasi berhasil! Silakan login.');
                    window.location.href = 'login.html'; // Pindah ke halaman login
                } else {
                    alert(`Gagal: ${data.message}`);
                }
            } catch (error) {
                console.error('Error:', error);
                alert('Terjadi kesalahan saat menghubungi server.');
            }
        });
    }
});