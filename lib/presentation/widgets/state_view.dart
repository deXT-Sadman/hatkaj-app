import 'package:flutter/material.dart';

import '../providers/view_state.dart';

/// Renders the loading / error / empty / success states of a list screen,
/// with pull-to-refresh working in every state except loading.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.emptyMessage,
    required this.child,
    this.errorMessage,
  });

  final ViewState state;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final String? errorMessage;

  /// Shown for [ViewState.success]. Must be scrollable so pull-to-refresh works.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewState.loading => const Center(child: CircularProgressIndicator()),
      ViewState.error => RefreshIndicator(
        onRefresh: onRefresh,
        child: _Message(
          icon: Icons.cloud_off,
          message: errorMessage ?? 'Something went wrong.',
          actionLabel: 'Try again',
          onAction: onRefresh,
        ),
      ),
      ViewState.empty => RefreshIndicator(
        onRefresh: onRefresh,
        child: _Message(icon: Icons.inbox_outlined, message: emptyMessage),
      ),
      ViewState.success => RefreshIndicator(onRefresh: onRefresh, child: child),
    };
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 96),
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          Center(
            child: FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}
