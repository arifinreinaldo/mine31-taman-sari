import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class SetPinScreen extends ConsumerStatefulWidget {
  final bool isChange;

  const SetPinScreen({super.key, this.isChange = false});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _currentPinController = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.isEmpty) {
      setState(() => _error = 'PIN cannot be empty');
      return;
    }
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 characters');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PINs do not match');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final repo = ref.read(authRepositoryProvider);

    if (widget.isChange) {
      final valid = await repo.verifyPin(_currentPinController.text.trim());
      if (!valid) {
        setState(() {
          _error = 'Current PIN is wrong';
          _loading = false;
        });
        return;
      }
    }

    await repo.setPin(pin);
    ref.invalidate(hasPinSetProvider);

    if (mounted) {
      if (widget.isChange) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully')),
        );
        context.pop();
      } else {
        // First-time setup — authenticate and go home
        ref.read(isAuthenticatedProvider.notifier).state = true;
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isChange ? AppBar(title: const Text('Change PIN')) : null,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isChange) ...[
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Set your PIN',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'This will be used to lock the app',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
              ],
              if (widget.isChange) ...[
                TextField(
                  controller: _currentPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current PIN',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'New PIN',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Confirm PIN',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isChange ? 'Change PIN' : 'Set PIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
