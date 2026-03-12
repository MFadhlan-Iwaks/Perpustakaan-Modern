'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { BASE_URL, getToken, clearTokens, getAuthHeaders, isAuthenticated } from '@/lib/api';

export default function DashboardPage() {
    const router = useRouter();

    const [userPayload, setUserPayload] = useState(null);
    const [activeTab, setActiveTab] = useState('books');
    
    const [books, setBooks] = useState([]);
    const [borrowings, setBorrowings] = useState([]);
    const [users, setUsers] = useState([]);

    const [isAddModalOpen, setIsAddModalOpen] = useState(false);
    const [editBookData, setEditBookData] = useState(null);

    useEffect(() => {
        if (!isAuthenticated()) {
            router.push('/login');
            return;
        }

        const token = getToken();
        try {
            const payload = JSON.parse(atob(token.split('.')[1]));
            setUserPayload(payload);
        } catch (e) {
            handleLogout();
        }
    }, [router]);

    useEffect(() => {
        if (!userPayload) return;
        if (activeTab === 'books') fetchBooks();
        if (activeTab === 'borrowings') fetchBorrowings();
        if (activeTab === 'users' && userPayload.role === 'ADMIN') fetchUsers();
    }, [activeTab, userPayload]);

    const isAdmin = userPayload?.role === 'ADMIN';

    const fetchBooks = async () => {
        try {
            const res = await fetch(`${BASE_URL}/books`, { headers: getAuthHeaders() });
            if (res.status === 401 || res.status === 403) return handleLogout();
            setBooks(await res.json());
        } catch (error) { console.error(error); }
    };

    const fetchBorrowings = async () => {
        try {
            const res = await fetch(`${BASE_URL}/borrowings`, { headers: getAuthHeaders() });
            setBorrowings(await res.json());
        } catch (error) { console.error(error); }
    };

    const fetchUsers = async () => {
        try {
            const res = await fetch(`${BASE_URL}/users`, { headers: getAuthHeaders() });
            setUsers(await res.json());
        } catch (error) { console.error(error); }
    };

    const handleAddBook = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        try {
            const res = await fetch(`${BASE_URL}/books`, {
                method: 'POST',
                headers: { 'Authorization': `Bearer ${getToken()}` },
                body: formData
            });
            if (res.ok) {
                setIsAddModalOpen(false);
                fetchBooks();
            } else { alert((await res.json()).message); }
        } catch (error) { console.error(error); }
    };

    const handleEditBook = async (e) => {
        e.preventDefault();
        const formData = new FormData(e.target);
        try {
            const res = await fetch(`${BASE_URL}/books/${editBookData.id}`, {
                method: 'PUT',
                headers: { 'Authorization': `Bearer ${getToken()}` },
                body: formData
            });
            if (res.ok) {
                setEditBookData(null);
                fetchBooks();
            }
        } catch (error) { console.error(error); }
    };

    const handleDeleteBook = async (id) => {
        if (!confirm('Hapus buku ini?')) return;
        await fetch(`${BASE_URL}/books/${id}`, { method: 'DELETE', headers: getAuthHeaders() });
        fetchBooks();
    };

    const handleBorrowBook = async (book_id) => {
        try {
            const res = await fetch(`${BASE_URL}/borrowings`, {
                method: 'POST',
                headers: getAuthHeaders(),
                body: JSON.stringify({ book_id })
            });
            alert((await res.json()).message);
            if (res.ok) fetchBooks();
        } catch (error) { console.error(error); }
    };

    const handleReturnBook = async (id) => {
        if (!confirm('Kembalikan buku ini?')) return;
        await fetch(`${BASE_URL}/borrowings/${id}/return`, { method: 'PUT', headers: getAuthHeaders() });
        fetchBorrowings();
    };

    const handleDeleteBorrowing = async (id) => {
        if (!confirm('Hapus riwayat peminjaman ini?')) return;
        await fetch(`${BASE_URL}/borrowings/${id}`, { method: 'DELETE', headers: getAuthHeaders() });
        fetchBorrowings();
    };

    const handleChangeRole = async (u) => {
        const newRole = u.role === 'ADMIN' ? 'USER' : 'ADMIN';
        if (!confirm(`Ubah role menjadi ${newRole}?`)) return;
        await fetch(`${BASE_URL}/users/${u.id}`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            body: JSON.stringify({ name: u.name, email: u.email, role: newRole })
        });
        fetchUsers();
    };

    const handleDeleteUser = async (id) => {
        if (!confirm('Hapus pengguna ini secara permanen?')) return;
        await fetch(`${BASE_URL}/users/${id}`, { method: 'DELETE', headers: getAuthHeaders() });
        fetchUsers();
    };

    const handleLogout = () => {
        clearTokens();
        router.push('/login');
    };

    if (!userPayload) return <div className="min-h-screen flex items-center justify-center">Memuat...</div>;

    return (
        <div className="bg-slate-50 min-h-screen pb-10">
            <nav className="bg-white border-b border-slate-200 sticky top-0 z-10">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between h-16 items-center">
                        <div className="flex items-center gap-2">
                            <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253"></path></svg>
                            <span className="font-bold text-xl text-slate-800">LibraSys</span>
                        </div>
                        <div className="flex items-center gap-4">
                            <span className="text-sm font-medium text-slate-600 bg-slate-100 px-3 py-1 rounded-full">{userPayload.name} ({userPayload.role})</span>
                            <button onClick={handleLogout} className="text-sm font-medium text-red-600 hover:text-red-800 transition">Logout</button>
                        </div>
                    </div>
                </div>
            </nav>

            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
                <div className="border-b border-slate-200 mb-6">
                    <nav className="-mb-px flex space-x-8">
                        <button onClick={() => setActiveTab('books')} className={`${activeTab === 'books' ? 'border-blue-500 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition`}>Katalog Buku</button>
                        <button onClick={() => setActiveTab('borrowings')} className={`${activeTab === 'borrowings' ? 'border-blue-500 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition`}>Riwayat Peminjaman</button>
                        {isAdmin && (
                            <button onClick={() => setActiveTab('users')} className={`${activeTab === 'users' ? 'border-blue-500 text-blue-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'} whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm transition`}>Kelola Anggota</button>
                        )}
                    </nav>
                </div>

                {activeTab === 'books' && (
                    <div>
                        <div className="flex justify-between items-center mb-4">
                            <h2 className="text-xl font-bold text-slate-800">Daftar Buku</h2>
                            {isAdmin && <button onClick={() => setIsAddModalOpen(true)} className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium shadow-sm">+ Tambah Buku</button>}
                        </div>
                        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-slate-50 border-b border-slate-200 text-sm text-slate-600">
                                        <th className="py-3 px-6">Sampul</th>
                                        <th className="py-3 px-6">Judul Buku</th>
                                        <th className="py-3 px-6">Penulis & Tahun</th>
                                        <th className="py-3 px-6">Stok</th>
                                        <th className="py-3 px-6 text-right">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody className="text-sm text-slate-700 divide-y divide-slate-100">
                                    {books.length === 0 ? <tr><td colSpan="5" className="py-8 text-center text-slate-500">Belum ada buku.</td></tr> : books.map(b => (
                                        <tr key={b.id} className="hover:bg-slate-50 transition">
                                            <td className="py-3 px-6"><img src={b.image ? `http://localhost:5000/uploads/${b.image}` : 'https://via.placeholder.com/50x70?text=No+Image'} alt="Sampul" className="h-16 w-12 object-cover rounded shadow-sm border border-slate-200" /></td>
                                            <td className="py-3 px-6 font-medium text-slate-900">{b.title}</td>
                                            <td className="py-3 px-6 text-slate-600">{b.author} ({b.published_year})</td>
                                            <td className="py-3 px-6"><span className={`px-2.5 py-1 rounded-full text-xs font-medium ${b.stock > 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>{b.stock > 0 ? `${b.stock} Tersedia` : 'Habis'}</span></td>
                                            <td className="py-3 px-6 text-right">
                                                <button onClick={() => handleBorrowBook(b.id)} disabled={b.stock < 1} className={`text-blue-600 font-medium ${b.stock < 1 ? 'opacity-50 cursor-not-allowed' : 'hover:text-blue-800'}`}>Pinjam</button>
                                                {isAdmin && (
                                                    <>
                                                        <button onClick={() => setEditBookData(b)} className="text-amber-500 hover:text-amber-700 font-medium ml-3">Edit</button>
                                                        <button onClick={() => handleDeleteBook(b.id)} className="text-red-500 hover:text-red-700 font-medium ml-3">Hapus</button>
                                                    </>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}

                {activeTab === 'borrowings' && (
                    <div>
                        <h2 className="text-xl font-bold text-slate-800 mb-4">Data Peminjaman</h2>
                        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-slate-50 border-b border-slate-200 text-sm text-slate-600">
                                        <th className="py-3 px-6">Buku</th>
                                        {isAdmin && <th className="py-3 px-6">Peminjam</th>}
                                        <th className="py-3 px-6">Tanggal Pinjam</th>
                                        <th className="py-3 px-6">Status</th>
                                        <th className="py-3 px-6 text-right">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody className="text-sm text-slate-700 divide-y divide-slate-100">
                                    {borrowings.length === 0 ? <tr><td colSpan="5" className="py-8 text-center text-slate-500">Belum ada riwayat.</td></tr> : borrowings.map(b => (
                                        <tr key={b.id} className="hover:bg-slate-50">
                                            <td className="py-3 px-6 font-medium text-slate-900">{b.book_title}</td>
                                            {isAdmin && <td className="py-3 px-6 text-slate-600">{b.user_name}</td>}
                                            <td className="py-3 px-6 text-slate-600">{new Date(b.borrow_date).toLocaleDateString('id-ID')}</td>
                                            <td className="py-3 px-6"><span className={`px-2.5 py-1 rounded-full text-xs font-medium ${b.status === 'RETURNED' ? 'bg-slate-100 text-slate-700' : 'bg-blue-100 text-blue-700'}`}>{b.status === 'RETURNED' ? 'Dikembalikan' : 'Dipinjam'}</span></td>
                                            <td className="py-3 px-6 text-right">
                                                {b.status !== 'RETURNED' && <button onClick={() => handleReturnBook(b.id)} className="text-green-600 hover:text-green-800 font-medium">Kembalikan</button>}
                                                {isAdmin && <button onClick={() => handleDeleteBorrowing(b.id)} className="text-red-500 hover:text-red-700 font-medium ml-3">Hapus</button>}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}

                {activeTab === 'users' && isAdmin && (
                    <div>
                        <h2 className="text-xl font-bold text-slate-800 mb-4">Daftar Pengguna</h2>
                        <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                            <table className="w-full text-left border-collapse">
                                <thead>
                                    <tr className="bg-slate-50 border-b border-slate-200 text-sm text-slate-600">
                                        <th className="py-3 px-6">Nama</th>
                                        <th className="py-3 px-6">Email</th>
                                        <th className="py-3 px-6">Role</th>
                                        <th className="py-3 px-6 text-right">Aksi</th>
                                    </tr>
                                </thead>
                                <tbody className="text-sm text-slate-700 divide-y divide-slate-100">
                                    {users.map(u => (
                                        <tr key={u.id} className="hover:bg-slate-50">
                                            <td className="py-3 px-6 font-medium text-slate-900">{u.name}</td>
                                            <td className="py-3 px-6 text-slate-600">{u.email}</td>
                                            <td className="py-3 px-6"><span className="px-2 py-1 bg-slate-100 text-xs rounded-lg">{u.role}</span></td>
                                            <td className="py-3 px-6 text-right">
                                                <button onClick={() => handleChangeRole(u)} className="text-blue-600 hover:text-blue-800 font-medium">Jadikan {u.role === 'ADMIN' ? 'User' : 'Admin'}</button>
                                                <button onClick={() => handleDeleteUser(u.id)} className="text-red-500 hover:text-red-700 font-medium ml-3">Hapus</button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </main>

            {isAddModalOpen && (
                <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50">
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-md mx-4 overflow-hidden">
                        <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
                            <h3 className="font-bold text-lg text-slate-800">Tambah Buku Baru</h3>
                            <button onClick={() => setIsAddModalOpen(false)} className="text-slate-400 hover:text-slate-600">&times;</button>
                        </div>
                        <form onSubmit={handleAddBook} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Sampul Buku</label>
                                <input type="file" name="image" accept="image/*" className="w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:bg-blue-50 file:text-blue-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Judul Buku</label>
                                <input type="text" name="title" required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Penulis</label>
                                <input type="text" name="author" required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Tahun Terbit</label>
                                    <input type="number" name="published_year" required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Stok</label>
                                    <input type="number" name="stock" min="1" required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                                </div>
                            </div>
                            <button type="submit" className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2.5 rounded-lg">Simpan Buku</button>
                        </form>
                    </div>
                </div>
            )}

            {editBookData && (
                <div className="fixed inset-0 bg-slate-900/50 flex items-center justify-center z-50">
                    <div className="bg-white rounded-2xl shadow-xl w-full max-w-md mx-4 overflow-hidden">
                        <div className="px-6 py-4 border-b border-slate-100 flex justify-between items-center">
                            <h3 className="font-bold text-lg text-slate-800">Edit Buku</h3>
                            <button onClick={() => setEditBookData(null)} className="text-slate-400 hover:text-slate-600">&times;</button>
                        </div>
                        <form onSubmit={handleEditBook} className="p-6 space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Ganti Sampul (Opsional)</label>
                                <input type="file" name="image" accept="image/*" className="w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:bg-blue-50 file:text-blue-700" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Judul Buku</label>
                                <input type="text" name="title" defaultValue={editBookData.title} required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                            </div>
                            <div>
                                <label className="block text-sm font-medium text-slate-700 mb-1">Penulis</label>
                                <input type="text" name="author" defaultValue={editBookData.author} required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Tahun</label>
                                    <input type="number" name="published_year" defaultValue={editBookData.published_year} required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                                </div>
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 mb-1">Stok</label>
                                    <input type="number" name="stock" min="0" defaultValue={editBookData.stock} required className="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" />
                                </div>
                            </div>
                            <button type="submit" className="w-full bg-slate-900 hover:bg-slate-800 text-white py-2.5 rounded-lg">Update Data</button>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
}