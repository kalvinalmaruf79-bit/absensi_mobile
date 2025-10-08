import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi untuk memuat data profil pengguna
  Future<void> _loadUserData() async {
    // Jika data user sudah ada dari halaman login, gunakan itu
    if (widget.user != null) {
      setState(() {
        _currentUser = widget.user;
        _isLoading = false;
      });
    } else {
      // Jika tidak (misalnya, membuka aplikasi kembali), ambil dari API
      try {
        final user = await _authService.getProfile();
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      } catch (e) {
        // Jika gagal (misal: token kedaluwarsa), logout
        _logout();
      }
    }
  }

  // Fungsi untuk logout
  Future<void> _logout() async {
    await _authService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          // Tombol logout di app bar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? const Center(child: Text('Gagal memuat data pengguna.'))
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Selamat Datang Kembali!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Tampilkan nama pengguna
                  Text(
                    _currentUser!.name,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  // Tampilkan role pengguna
                  Text(
                    'Anda login sebagai: ${_currentUser!.role}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
