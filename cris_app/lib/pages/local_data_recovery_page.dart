import 'package:flutter/material.dart';

import '../theme.dart';

class LocalDataRecoveryApp extends StatelessWidget {
  const LocalDataRecoveryApp({
    required this.failedBoxName,
    required this.canBackUpReports,
    required this.onTryAgain,
    required this.onResetReports,
    required this.onContinue,
    super.key,
  });

  final String failedBoxName;
  final bool canBackUpReports;
  final Future<void> Function() onTryAgain;
  final Future<int> Function() onResetReports;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRIS App',
      theme: AppTheme.lightTheme(),
      home: LocalDataRecoveryPage(
        failedBoxName: failedBoxName,
        canBackUpReports: canBackUpReports,
        onTryAgain: onTryAgain,
        onResetReports: onResetReports,
        onContinue: onContinue,
      ),
    );
  }
}

class LocalDataRecoveryPage extends StatefulWidget {
  const LocalDataRecoveryPage({
    required this.failedBoxName,
    required this.canBackUpReports,
    required this.onTryAgain,
    required this.onResetReports,
    required this.onContinue,
    super.key,
  });

  final String failedBoxName;
  final bool canBackUpReports;
  final Future<void> Function() onTryAgain;
  final Future<int> Function() onResetReports;
  final VoidCallback onContinue;

  @override
  State<LocalDataRecoveryPage> createState() => _LocalDataRecoveryPageState();
}

class _LocalDataRecoveryPageState extends State<LocalDataRecoveryPage> {
  bool _isWorking = false;
  String? _errorMessage;
  int? _copiedFiles;

  bool get _canResetReports =>
      widget.canBackUpReports &&
      (widget.failedBoxName == 'reports' ||
          widget.failedBoxName == 'sab_reports');

  Future<void> _tryAgain() async {
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });
    try {
      await widget.onTryAgain();
      if (mounted) widget.onContinue();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage =
              'CRIS still cannot open the local data. No data was removed.';
        });
      }
    }
  }

  Future<void> _confirmAndReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset local reports?'),
        content: const Text(
          'This permanently removes bite and suspicious-animal reports stored on this device. '
          'CRIS will first create an on-device backup of the report files. The backup is not uploaded to the internet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Back up and reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });
    try {
      final copiedFiles = await widget.onResetReports();
      if (mounted) {
        setState(() {
          _isWorking = false;
          _copiedFiles = copiedFiles;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isWorking = false;
          _errorMessage =
              'The reset could not be completed. A backup may have been created; no further data was removed.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resetComplete = _copiedFiles != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.folder_off_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        resetComplete
                            ? 'Local reports were reset'
                            : 'Local reports need attention',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        resetComplete
                            ? (_copiedFiles! > 0
                                ? '${_copiedFiles!} local report file(s) were backed up before the reset.'
                                : 'No existing report files were found to back up before the reset.')
                            : 'CRIS could not open local data (${widget.failedBoxName}). To protect your information, nothing has been deleted.',
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                      if (!_canResetReports &&
                          (widget.failedBoxName == 'reports' ||
                              widget.failedBoxName == 'sab_reports')) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'To protect browser-stored reports, reset is unavailable here because CRIS cannot create a file backup in a browser.',
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_isWorking)
                        const Center(child: CircularProgressIndicator())
                      else if (resetComplete)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: widget.onContinue,
                            child: const Text('Continue to CRIS'),
                          ),
                        )
                      else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _tryAgain,
                            child: const Text('Try again'),
                          ),
                        ),
                        if (_canResetReports) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _confirmAndReset,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                              ),
                              child: const Text('Reset local reports'),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
