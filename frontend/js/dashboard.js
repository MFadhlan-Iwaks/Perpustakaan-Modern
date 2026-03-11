document.addEventListener('DOMContentLoaded', () => {
    // --- 1. INISIALISASI & PROTEKSI ---
    if (!isAuthenticated()) {
        window.location.href = 'login.html';
        return;
    }

    // Helper untuk membongkar isi Payload JWT tanpa verifikasi (karena verifikasi dilakukan di backend)
    const parseJwt = (token) => {
        try {
            return JSON.parse(atob(token.split('.')[1]));
        } catch (e) {
            return null;
        }
    };

    const token = getToken();
    const userPayload = parseJwt(token);
    const IS_ADMIN = userPayload?.role === 'ADMIN';

    // Tampilkan info user di Navbar
    document.getElementById('userInfo').textContent = `${userPayload.name} (${userPayload.role})`;

    // Tampilkan elemen khusus Admin
    if (IS_ADMIN) {
        document.getElementById('tabUsers').classList.remove('hidden');
        document.getElementById('btnOpenAddModal').classList.remove('hidden');
        
        // Tampilkan header kolom "Peminjam" di tabel peminjaman
        document.querySelectorAll('.admin-only').forEach(el => el.classList.remove('hidden'));
    }

    // --- 2. LOGIKA TAB NAVIGASI ---
    window.switchTab = (tabName) => {
        // Sembunyikan semua section
        document.getElementById('sectionBooks').classList.add('hidden');
        document.getElementById('sectionBorrowings').classList.add('hidden');
        document.getElementById('sectionUsers').classList.add('hidden');

        // Reset warna tab
        const tabs = ['tabBooks', 'tabBorrowings', 'tabUsers'];
        tabs.forEach(tab => {
            const el = document.getElementById(tab);
            if (el) {
                el.classList.remove('border-blue-500', 'text-blue-600');
                el.classList.add('border-transparent', 'text-slate-500');
            }
        });

        // Tampilkan section yang dipilih
        document.getElementById(`section${tabName.charAt(0).toUpperCase() + tabName.slice(1)}`).classList.remove('hidden');
        document.getElementById(`tab${tabName.charAt(0).toUpperCase() + tabName.slice(1)}`).classList.remove('border-transparent', 'text-slate-500');
        document.getElementById(`tab${tabName.charAt(0).toUpperCase() + tabName.slice(1)}`).classList.add('border-blue-500', 'text-blue-600');

        // Panggil data sesuai tab
        if (tabName === 'books') fetchBooks();
        if (tabName === 'borrowings') fetchBorrowings();
        if (tabName === 'users' && IS_ADMIN) fetchUsers();
    };

    // --- 3. KONTROL MODAL ---
    const toggleModal = (modal, show) => {
        if (show) {
            modal.classList.remove('hidden');
            setTimeout(() => {
                modal.classList.remove('opacity-0');
                modal.children[0].classList.remove('scale-95');
            }, 10);
        } else {
            modal.classList.add('opacity-0');
            modal.children[0].classList.add('scale-95');
            setTimeout(() => modal.classList.add('hidden'), 300);
        }
    };

    if (IS_ADMIN) {
        document.getElementById('btnOpenAddModal').addEventListener('click', () => toggleModal(document.getElementById('modalAddBook'), true));
    }
    document.querySelectorAll('.closeModalBtn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            toggleModal(e.target.closest('.fixed'), false);
        });
    });

    // --- 4. FITUR KATALOG BUKU ---
    const fetchBooks = async () => {
        try {
            const res = await fetch(`${BASE_URL}/books`, { headers: getAuthHeaders() });
            if (res.status === 401 || res.status === 403) return forceLogout();
            const books = await res.json();
            renderBooks(books);
        } catch (error) { console.error(error); }
    };

    const renderBooks = (books) => {
        const tbody = document.getElementById('booksTableBody');
        tbody.innerHTML = '';
        if (books.length === 0) return tbody.innerHTML = `<tr><td colspan="5" class="py-8 text-center text-slate-500">Belum ada buku.</td></tr>`;

        books.forEach(book => {
            const isAvailable = book.stock > 0;
            const imgUrl = book.image ? `http://localhost:5000/uploads/${book.image}` : 'https://via.placeholder.com/50x70?text=No+Image';
            
            // Tombol Aksi (Hanya tampilkan Edit/Hapus jika Admin)
            let actionBtns = `<button onclick="borrowBook(${book.id})" class="text-blue-600 hover:text-blue-800 font-medium ${!isAvailable ? 'opacity-50 cursor-not-allowed' : ''}" ${!isAvailable ? 'disabled' : ''}>Pinjam</button>`;
            
            if (IS_ADMIN) {
                actionBtns += `
                    <button onclick="openEditModal(${book.id}, '${book.title}', '${book.author}', ${book.published_year}, ${book.stock})" class="text-amber-500 hover:text-amber-700 font-medium ml-3">Edit</button>
                    <button onclick="deleteBook(${book.id})" class="text-red-500 hover:text-red-700 font-medium ml-3">Hapus</button>
                `;
            }

            const tr = document.createElement('tr');
            tr.className = 'hover:bg-slate-50 transition';
            tr.innerHTML = `
                <td class="py-3 px-6"><img src="${imgUrl}" alt="Sampul" class="h-16 w-12 object-cover rounded shadow-sm border border-slate-200"></td>
                <td class="py-3 px-6 font-medium text-slate-900">${book.title}</td>
                <td class="py-3 px-6 text-slate-600">${book.author} (${book.published_year})</td>
                <td class="py-3 px-6"><span class="px-2.5 py-1 rounded-full text-xs font-medium ${isAvailable ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}">${isAvailable ? book.stock + ' Tersedia' : 'Habis'}</span></td>
                <td class="py-3 px-6 text-right">${actionBtns}</td>
            `;
            tbody.appendChild(tr);
        });
    };

    // Tambah Buku (FormData)
    document.getElementById('formAddBook')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const formData = new FormData();
        formData.append('title', document.getElementById('addTitle').value);
        formData.append('author', document.getElementById('addAuthor').value);
        formData.append('published_year', document.getElementById('addYear').value);
        formData.append('stock', document.getElementById('addStock').value);
        
        const imageFile = document.getElementById('addImage').files[0];
        if (imageFile) formData.append('image', imageFile);

        try {
            // PERHATIAN: Jangan set 'Content-Type' saat menggunakan FormData, biarkan browser yang mengaturnya
            const res = await fetch(`${BASE_URL}/books`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${token}` },
                body: formData
            });
            if (res.ok) {
                document.getElementById('formAddBook').reset();
                toggleModal(document.getElementById('modalAddBook'), false);
                fetchBooks();
            } else { alert((await res.json()).message); }
        } catch (error) { console.error(error); }
    });

    // Buka Modal Edit
    window.openEditModal = (id, title, author, year, stock) => {
        document.getElementById('editBookId').value = id;
        document.getElementById('editTitle').value = title;
        document.getElementById('editAuthor').value = author;
        document.getElementById('editYear').value = year;
        document.getElementById('editStock').value = stock;
        toggleModal(document.getElementById('modalEditBook'), true);
    };

    // Update Buku (FormData)
    document.getElementById('formEditBook')?.addEventListener('submit', async (e) => {
        e.preventDefault();
        const id = document.getElementById('editBookId').value;
        const formData = new FormData();
        formData.append('title', document.getElementById('editTitle').value);
        formData.append('author', document.getElementById('editAuthor').value);
        formData.append('published_year', document.getElementById('editYear').value);
        formData.append('stock', document.getElementById('editStock').value);
        
        const imageFile = document.getElementById('editImage').files[0];
        if (imageFile) formData.append('image', imageFile);

        try {
            const res = await fetch(`${BASE_URL}/books/${id}`, {
                method: 'PUT',
                headers: { 'Authorization': `Bearer ${token}` },
                body: formData
            });
            if (res.ok) {
                document.getElementById('formEditBook').reset();
                toggleModal(document.getElementById('modalEditBook'), false);
                fetchBooks();
            }
        } catch (error) { console.error(error); }
    });

    window.deleteBook = async (id) => {
        if (!confirm('Hapus buku ini?')) return;
        await fetch(`${BASE_URL}/books/${id}`, { method: 'DELETE', headers: getAuthHeaders() });
        fetchBooks();
    };

    // --- 5. FITUR PEMINJAMAN ---
    window.borrowBook = async (book_id) => {
        try {
            const res = await fetch(`${BASE_URL}/borrowings`, {
                method: 'POST',
                headers: getAuthHeaders(),
                body: JSON.stringify({ book_id })
            });
            const data = await res.json();
            alert(data.message);
            if (res.ok) fetchBooks();
        } catch (error) { console.error(error); }
    };

    const fetchBorrowings = async () => {
        try {
            const res = await fetch(`${BASE_URL}/borrowings`, { headers: getAuthHeaders() });
            const borrowings = await res.json();
            const tbody = document.getElementById('borrowingsTableBody');
            tbody.innerHTML = '';

            if (borrowings.length === 0) return tbody.innerHTML = `<tr><td colspan="5" class="py-8 text-center text-slate-500">Belum ada riwayat peminjaman.</td></tr>`;

            borrowings.forEach(b => {
                const isReturned = b.status === 'RETURNED';
                
                let actionBtns = '';
                if (!isReturned) actionBtns += `<button onclick="returnBook(${b.id})" class="text-green-600 hover:text-green-800 font-medium">Kembalikan</button>`;
                if (IS_ADMIN) actionBtns += `<button onclick="deleteBorrowing(${b.id})" class="text-red-500 hover:text-red-700 font-medium ml-3">Hapus Riwayat</button>`;

                const tr = document.createElement('tr');
                tr.className = 'hover:bg-slate-50 transition';
                tr.innerHTML = `
                    <td class="py-3 px-6 font-medium text-slate-900">${b.book_title}</td>
                    ${IS_ADMIN ? `<td class="py-3 px-6 text-slate-600">${b.user_name}</td>` : ''}
                    <td class="py-3 px-6 text-slate-600">${new Date(b.borrow_date).toLocaleDateString('id-ID')}</td>
                    <td class="py-3 px-6"><span class="px-2.5 py-1 rounded-full text-xs font-medium ${isReturned ? 'bg-slate-100 text-slate-700' : 'bg-blue-100 text-blue-700'}">${isReturned ? 'Dikembalikan' : 'Dipinjam'}</span></td>
                    <td class="py-3 px-6 text-right">${actionBtns}</td>
                `;
                tbody.appendChild(tr);
            });
        } catch (error) { console.error(error); }
    };

    window.returnBook = async (id) => {
        if (!confirm('Kembalikan buku ini?')) return;
        await fetch(`${BASE_URL}/borrowings/${id}/return`, { method: 'PUT', headers: getAuthHeaders() });
        fetchBorrowings();
    };

    window.deleteBorrowing = async (id) => {
        if (!confirm('Hapus riwayat peminjaman ini?')) return;
        await fetch(`${BASE_URL}/borrowings/${id}`, { method: 'DELETE', headers: getAuthHeaders() });
        fetchBorrowings();
    };

    // --- 6. FITUR KELOLA ANGGOTA (KHUSUS ADMIN) ---
    const fetchUsers = async () => {
        try {
            const res = await fetch(`${BASE_URL}/users`, { headers: getAuthHeaders() });
            const users = await res.json();
            const tbody = document.getElementById('usersTableBody');
            tbody.innerHTML = '';

            users.forEach(u => {
                const tr = document.createElement('tr');
                tr.innerHTML = `
                    <td class="py-3 px-6 font-medium text-slate-900">${u.name}</td>
                    <td class="py-3 px-6 text-slate-600">${u.email}</td>
                    <td class="py-3 px-6"><span class="px-2 py-1 bg-slate-100 text-xs rounded-lg">${u.role}</span></td>
                    <td class="py-3 px-6 text-right">
                        <button onclick="changeRole(${u.id}, '${u.name}', '${u.email}', '${u.role === 'ADMIN' ? 'USER' : 'ADMIN'}')" class="text-blue-600 hover:text-blue-800 font-medium">Jadikan ${u.role === 'ADMIN' ? 'User' : 'Admin'}</button>
                        <button onclick="deleteUser(${u.id})" class="text-red-500 hover:text-red-700 font-medium ml-3">Hapus</button>
                    </td>
                `;
                tbody.appendChild(tr);
            });
        } catch (error) { console.error(error); }
    };

    window.changeRole = async (id, name, email, newRole) => {
        if (!confirm(`Ubah role menjadi ${newRole}?`)) return;
        await fetch(`${BASE_URL}/users/${id}`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify({ name, email, role: newRole })
        });
        fetchUsers();
    };

    window.deleteUser = async (id) => {
        if (!confirm('Hapus pengguna ini secara permanen?')) return;
        await fetch(`${BASE_URL}/users/${id}`, { method: 'DELETE', headers: getAuthHeaders() });
        fetchUsers();
    };

    // --- 7. LOGOUT ---
    const forceLogout = () => {
        clearTokens();
        window.location.href = 'login.html';
    };
    document.getElementById('btnLogout').addEventListener('click', forceLogout);

    // Render awal
    fetchBooks();
});