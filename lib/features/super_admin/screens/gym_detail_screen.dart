import 'package:flutter/material.dart';
import '../../../core/localization/app_strings.dart';
import '../../../core/providers/gym_branding_provider.dart';
import '../../../shared/models/gym_model.dart';
import 'super_admin_dashboard.dart';

class GymDetailScreen extends StatelessWidget {
  final GymModel gym;

  const GymDetailScreen({super.key, required this.gym});

  @override
  Widget build(BuildContext context) {
    final primaryColor = GymBrandingProvider.hexToColor(gym.primaryColor);
    final secondaryColor = GymBrandingProvider.hexToColor(gym.secondaryColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(gym.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gym Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.15),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Gym Icon / Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: gym.logoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              gym.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.fitness_center,
                                color: primaryColor,
                                size: 40,
                              ),
                            ),
                          )
                        : Icon(Icons.fitness_center, color: primaryColor, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    gym.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: gym.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      gym.isActive ? S.active : S.inactive,
                      style: TextStyle(
                        color: gym.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats
            Text(
              S.statistics,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatTile(context, S.branches, '${gym.branchCount}', Icons.store, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatTile(context, S.customers, '${gym.customerCount}', Icons.people, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatTile(context, S.staff, '${gym.staffCount}', Icons.badge, Colors.purple)),
              ],
            ),

            const SizedBox(height: 24),

            // Owner Info
            Text(
              S.ownerInformation,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(context, Icons.person, S.name, gym.ownerName ?? S.notAssigned),
                    const Divider(height: 24),
                    _buildInfoRow(context, Icons.alternate_email, S.username, gym.ownerUsername ?? S.na),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Branding
            Text(
              S.branding,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text(S.primaryColor),
                        const Spacer(),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(gym.primaryColor, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.palette_outlined, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text(S.secondaryColor),
                        const Spacer(),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(gym.secondaryColor, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text(S.emailDomain),
                        const Spacer(),
                        Text(
                          '@${gym.emailDomain}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.settings,
                      S.setupComplete,
                      gym.isSetupComplete ? S.yes : S.setupPending,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Created at
            if (gym.createdAt != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    S.created,
                    '${gym.createdAt!.day}/${gym.createdAt!.month}/${gym.createdAt!.year}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
