import 'package:flutter/material.dart';
import 'otp_verification_page.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Enter your registered email to receive OTP',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Send OTP logic
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OTPVerificationPage()),
                  );
                },
                child: const Text('Send Link / OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
