import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/api/api_service.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/localization/app_strings.dart';

class OperationalMonitorScreen extends StatefulWidget {
  const OperationalMonitorScreen({super.key});

  @override
  State<OperationalMonitorScreen> createState() => _OperationalMonitorScreenState();
}

class _OperationalMonitorScreenState extends State<OperationalMonitorScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _operationalData;
  ApiService? _apiService;

  @override
  void initState() {
    super.initState();
    // Delay loading to next frame to ensure Provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOperationalData();
    });
    // Auto-refresh every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) _loadOperationalData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely get ApiService in didChangeDependencies
    _apiService ??= context.read<ApiService>();
  }

  Future<void> _loadOperationalData() async {
    if (!mounted || _apiService == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the cached apiService instance
      final apiService = _apiService!;

      // In a real app, this would be a dedicated operational endpoint
      final response = await apiService.get(ApiEndpoints.reportsDaily);

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _operationalData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = S.failedToLoadOperational;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.operationalMonitor),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOperationalData,
          ),
        ],
      ),
      body: _isLoading
          ? const DashboardSkeleton()
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOperationalData,
                          child: Text(S.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOperationalData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Status Banner
                        _buildLiveStatusBanner(),
                        const SizedBox(height: 24),

                        // Gym Capacity Section
                        _buildCapacitySection(S.gymFloor, Icons.fitness_center, Colors.blue),
                        const SizedBox(height: 16),

                        // Pool Capacity Section
                        _buildCapacitySection(S.swimmingPool, Icons.pool, Colors.cyan),
                        const SizedBox(height: 16),

                        // Karate Area Section
                        _buildCapacitySection(S.karateArea, Icons.sports_kabaddi, Colors.orange),
                        const SizedBox(height: 24),

                        // Today's Classes Schedule
                        Text(
                          S.todaysClasses,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _buildClassSchedule(),
                        const SizedBox(height: 24),

                        // Staff Attendance
                        Text(
                          S.staffAttendance,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _buildStaffAttendance(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildLiveStatusBanner() {
    return Card(
      color: Colors.green.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.liveMonitoring,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Last updated: ${DateHelper.formatDateTime(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _loadOperationalData,
              icon: const Icon(Icons.refresh),
              label: Text(S.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection(String title, IconData icon, Color color) {
    // Mock data - in production this would come from _operationalData
    final currentOccupancy = 45;
    final maxCapacity = 100;
    final percentFull = (currentOccupancy / maxCapacity * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text('$percentFull%'),
                  backgroundColor: _getCapacityColor(percentFull).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _getCapacityColor(percentFull),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentOccupancy / $maxCapacity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  S.spotsLeft(maxCapacity - currentOccupancy),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Color(0xFF6B7590),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: currentOccupancy / maxCapacity,
                minHeight: 12,
                backgroundColor: Color(0xFF1B2748),
                valueColor: AlwaysStoppedAnimation(_getCapacityColor(percentFull)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCapacityColor(int percent) {
    if (percent >= 90) return Colors.red;
    if (percent >= 70) return Colors.orange;
    return Colors.green;
  }

  Widget _buildClassSchedule() {
    // Mock data - in production this would come from _operationalData
    final classes = [
      {
        'name': S.yogaClass,
        'time': '09:00 AM',
        'instructor': 'Sarah Johnson',
        'capacity': '15/20',
        'status': 'ongoing',
      },
      {
        'name': S.karateBasics,
        'time': '11:00 AM',
        'instructor': 'Ahmed Ali',
        'capacity': '12/15',
        'status': 'upcoming',
      },
      {
        'name': S.swimmingLessons,
        'time': '02:00 PM',
        'instructor': 'Mike Chen',
        'capacity': '8/10',
        'status': 'upcoming',
      },
      {
        'name': S.advancedKarate,
        'time': '05:00 PM',
        'instructor': 'Ahmed Ali',
        'capacity': '0/12',
        'status': 'upcoming',
      },
    ];

    return Column(
      children: classes.map((classInfo) {
        final isOngoing = classInfo['status'] == 'ongoing';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOngoing
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.event,
                color: isOngoing ? Colors.green : Colors.blue,
              ),
            ),
            title: Text(
              classInfo['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Color(0xFF6B7590)),
                    const SizedBox(width: 4),
                    Text(classInfo['time'] as String),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Color(0xFF6B7590)),
                    const SizedBox(width: 4),
                    Text(classInfo['instructor'] as String),
                  ],
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOngoing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      S.live,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  classInfo['capacity'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStaffAttendance() {
    // Mock data - in production this would come from _operationalData
    final staff = [
      {'name': 'Ahmed Ali', 'role': 'Manager', 'status': 'present', 'time': '08:00 AM'},
      {'name': 'Sarah Johnson', 'role': 'Trainer', 'status': 'present', 'time': '08:30 AM'},
      {'name': 'Mike Chen', 'role': 'Trainer', 'status': 'present', 'time': '09:00 AM'},
      {'name': 'Fatima Hassan', 'role': 'Receptionist', 'status': 'present', 'time': '08:15 AM'},
      {'name': 'Omar Khalil', 'role': 'Trainer', 'status': 'absent', 'time': null},
    ];

    return Column(
      children: staff.map((member) {
        final isPresent = member['status'] == 'present';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              child: Icon(
                isPresent ? Icons.check : Icons.close,
                color: isPresent ? Colors.green : Colors.red,
              ),
            ),
            title: Text(member['name'] as String),
            subtitle: Text(member['role'] as String),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    isPresent ? S.present : S.absent,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: isPresent
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isPresent ? Colors.green : Colors.red,
                  ),
                ),
                if (member['time'] != null)
                  Text(
                    member['time'] as String,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
