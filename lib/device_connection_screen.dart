import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'ui/components/components.dart';
import 'services/services.dart';
import 'ui/theme/theme.dart';
import 'main.dart'; // Import for getIt

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  final HealthService _healthService = getIt<HealthService>();
  final WearableSyncService _wearableSyncService = getIt<WearableSyncService>();

  bool _isLoading = true;
  bool _isHealthAvailable = false;
  bool _hasPermissions = false;
  Map<String, dynamic> _wearableStatus = {};
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkWearableStatus();
  }

  Future<void> _checkWearableStatus() async {
    setState(() => _isLoading = true);

    try {
      _isHealthAvailable = await _healthService.isHealthDataAvailable();
      _hasPermissions = await _healthService.requestPermissions();
      _wearableStatus = await _wearableSyncService.getWearableStatus();
    } catch (e) {
      print('Error checking wearable status: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      _hasPermissions = await _healthService.requestPermissions();
      _wearableStatus = await _wearableSyncService.getWearableStatus();
    } catch (e) {
      print('Error requesting permissions: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncHealthData() async {
    setState(() => _isSyncing = true);

    try {
      await _wearableSyncService.syncHealthData(days: 30);
      _wearableStatus = await _wearableSyncService.getWearableStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health data synced successfully!')),
        );
      }
    } catch (e) {
      print('Error syncing health data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync health data')),
        );
      }
    }

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitLifeTheme.background,
      appBar: FitLifeAppBar(
        title: 'Device Connection',
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingState(message: 'Checking device status...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(FitLifeTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  AppText(
                    'Connect Your Wearable Devices',
                    type: AppTextType.headingMedium,
                    color: FitLifeTheme.primaryText,
                    useCleanStyle: true,
                  ),
                  const SizedBox(height: FitLifeTheme.spacingS),
                  AppText(
                    'Sync your health data from Apple Health, Google Fit, and other wearable devices for more accurate fitness tracking.',
                    type: AppTextType.bodyMedium,
                    color: FitLifeTheme.primaryText.withOpacity(0.8),
                    useCleanStyle: true,
                  ),
                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Device Status Card
                  AppCard(
                    useCleanStyle: true,
                    child: Padding(
                      padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isHealthAvailable ? Icons.devices : Icons.devices_other,
                                color: _isHealthAvailable ? FitLifeTheme.accentGreen : FitLifeTheme.error,
                                size: 24,
                              ),
                              const SizedBox(width: FitLifeTheme.spacingS),
                              AppText(
                                'Device Status',
                                type: AppTextType.bodyLarge,
                                color: FitLifeTheme.primaryText,
                                useCleanStyle: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: FitLifeTheme.spacingM),

                          _buildStatusItem(
                            'Health Data Available',
                            _isHealthAvailable,
                            _isHealthAvailable ? 'Available' : 'Not Available',
                          ),

                          const SizedBox(height: FitLifeTheme.spacingM),

                          _buildStatusItem(
                            'Permissions Granted',
                            _hasPermissions,
                            _hasPermissions ? 'Granted' : 'Not Granted',
                          ),

                          if (_wearableStatus['lastSync'] != null) ...[
                            const SizedBox(height: FitLifeTheme.spacingM),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppText(
                                  'Last Sync',
                                  type: AppTextType.bodyMedium,
                                  color: FitLifeTheme.primaryText.withOpacity(0.8),
                                  useCleanStyle: true,
                                ),
                                AppText(
                                  _formatLastSync(_wearableStatus['lastSync']),
                                  type: AppTextType.bodyMedium,
                                  color: FitLifeTheme.primaryText,
                                  useCleanStyle: true,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Actions
                  if (!_hasPermissions) ...[
                    AppCard(
                      useCleanStyle: true,
                      child: Padding(
                        padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Grant Permissions',
                              type: AppTextType.bodyLarge,
                              color: FitLifeTheme.primaryText,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingS),
                            AppText(
                              'Allow Momentum to access your health data for accurate tracking.',
                              type: AppTextType.bodySmall,
                              color: FitLifeTheme.primaryText.withOpacity(0.7),
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingM),
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedButton(
                                text: 'Grant Permissions',
                                icon: Icons.security,
                                onPressed: _requestPermissions,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: FitLifeTheme.spacingXL),
                  ],

                  // Sync Actions
                  if (_hasPermissions) ...[
                    AppCard(
                      useCleanStyle: true,
                      child: Padding(
                        padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Sync Health Data',
                              type: AppTextType.bodyLarge,
                              color: FitLifeTheme.primaryText,
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingS),
                            AppText(
                              'Import your recent health data from connected devices.',
                              type: AppTextType.bodySmall,
                              color: FitLifeTheme.primaryText.withOpacity(0.7),
                              useCleanStyle: true,
                            ),
                            const SizedBox(height: FitLifeTheme.spacingM),
                            SizedBox(
                              width: double.infinity,
                              child: AnimatedButton(
                                text: _isSyncing ? 'Syncing...' : 'Sync Now',
                                icon: _isSyncing ? Icons.sync : Icons.sync_alt,
                                onPressed: _isSyncing ? null : _syncHealthData,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: FitLifeTheme.spacingXL),
                  ],

                  // Supported Devices
                  AppCard(
                    useCleanStyle: true,
                    child: Padding(
                      padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            'Supported Devices',
                            type: AppTextType.bodyLarge,
                            color: FitLifeTheme.primaryText,
                            useCleanStyle: true,
                          ),
                          const SizedBox(height: FitLifeTheme.spacingM),

                          _buildDeviceSupport('Apple Health', 'iOS devices with HealthKit'),
                          _buildDeviceSupport('Google Fit', 'Android devices with Google Fit'),
                          _buildDeviceSupport('Apple Watch', 'Direct watch integration'),
                          _buildDeviceSupport('Fitbit', 'Fitbit devices and app'),
                          _buildDeviceSupport('Garmin', 'Garmin devices and Connect'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: FitLifeTheme.spacingXL),

                  // Privacy Notice
                  Container(
                    padding: const EdgeInsets.all(FitLifeTheme.spacingM),
                    decoration: BoxDecoration(
                      color: FitLifeTheme.surfaceColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(FitLifeTheme.radiusM),
                      border: Border.all(
                        color: FitLifeTheme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: FitLifeTheme.accentBlue,
                              size: 20,
                            ),
                            const SizedBox(width: FitLifeTheme.spacingS),
                            AppText(
                              'Privacy & Security',
                              type: AppTextType.bodyMedium,
                              color: FitLifeTheme.primaryText,
                              useCleanStyle: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: FitLifeTheme.spacingS),
                        AppText(
                          'Your health data is stored securely and only used to improve your fitness tracking experience. Data is never shared with third parties without your explicit consent.',
                          type: AppTextType.bodySmall,
                          color: FitLifeTheme.primaryText.withOpacity(0.7),
                          useCleanStyle: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusItem(String label, bool isActive, String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          type: AppTextType.bodyMedium,
          color: FitLifeTheme.primaryText.withOpacity(0.8),
          useCleanStyle: true,
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? FitLifeTheme.accentGreen : FitLifeTheme.error,
              ),
            ),
            const SizedBox(width: FitLifeTheme.spacingS),
            AppText(
              status,
              type: AppTextType.bodySmall,
              color: isActive ? FitLifeTheme.accentGreen : FitLifeTheme.error,
              useCleanStyle: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeviceSupport(String device, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FitLifeTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: FitLifeTheme.accentGreen,
            size: 20,
          ),
          const SizedBox(width: FitLifeTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  device,
                  type: AppTextType.bodyMedium,
                  color: FitLifeTheme.primaryText,
                  useCleanStyle: true,
                ),
                AppText(
                  description,
                  type: AppTextType.bodySmall,
                  color: FitLifeTheme.primaryText.withOpacity(0.6),
                  useCleanStyle: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${lastSync.month}/${lastSync.day}/${lastSync.year}';
  }
}