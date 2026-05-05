import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isPasswordVisible = false;

  void _login() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      context.go('/dashboard');
    } else if (auth.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite,
                  size: 80, color: Colors.deepPurpleAccent),

              const SizedBox(height: 20),

              const Text(
                'Jay Barade',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                decoration:  InputDecoration(
                    hintText: 'Enter Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
        )
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Enter Password",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),


                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return ElevatedButton(

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: auth.isLoading ? null : _login,
                    child: auth.isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Login" ,style: TextStyle(color: Colors.white)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}