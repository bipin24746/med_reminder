import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),
              Text('Welcome Back',
                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w900)),
              SizedBox(height: 8.h),
              Text('Sign in to continue',
                  style: TextStyle(fontSize: 16.sp, color: Colors.black54)),
              SizedBox(height: 24.h),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 14.h),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                  setState(() => _loading = true);
                  final ok = await ref
                      .read(authControllerProvider.notifier)
                      .signIn(_email.text.trim(), _pass.text.trim());
                  setState(() => _loading = false);

                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid credentials')),
                    );
                  } else if (mounted) {
                    context.go('/');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text(_loading ? 'Signing in...' : 'Sign In',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
              ),
              SizedBox(height: 14.h),
              OutlinedButton(
                onPressed: () => context.go('/signup'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('Create account',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800)),
              ),
              const Spacer(),
              Text(
                'Demo note: This is offline login stored locally in SQLite.\nLater we will replace with API auth.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.black45),
              )
            ],
          ),
        ),
      ),
    );
  }
}
