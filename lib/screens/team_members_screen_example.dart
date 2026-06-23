// /// Example: Team Members Screen with API Integration
// ///
// /// This file demonstrates best practices for using the API integration
// /// in your screens. Copy patterns from here to other screens.
//
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import '../providers/profile_provider.dart';
// import '../services/api_service.dart';
// import '../theme/app_theme.dart';
//
// /// Example screen showing how to integrate API calls
// class TeamMembersScreenExample extends StatefulWidget {
//   const TeamMembersScreenExample({Key? key}) : super(key: key);
//
//   @override
//   State<TeamMembersScreenExample> createState() =>
//       _TeamMembersScreenExampleState();
// }
//
// class _TeamMembersScreenExampleState extends State<TeamMembersScreenExample> {
//   @override
//   void initState() {
//     super.initState();
//     // Fetch data when screen loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadTeamMembers();
//     });
//   }
//
//   void _loadTeamMembers() {
//     final profileProvider = context.read<ProfileProvider>();
//     profileProvider.fetchUsers();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Team Members'),
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await context.read<ProfileProvider>().refreshUsers();
//         },
//         child: Consumer<ProfileProvider>(
//           builder: (context, profileProvider, _) {
//             // Show loading state
//             if (profileProvider.isLoading && profileProvider.users.isEmpty) {
//               return Center(
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                     AppTheme.primaryColor,
//                   ),
//                 ),
//               );
//             }
//
//             // Show error state
//             if (profileProvider.errorMessage != null) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.error_outline,
//                       size: 48,
//                       color: Colors.red.shade600,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Error',
//                       style: Theme.of(context).textTheme.headlineSmall,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       profileProvider.errorMessage ?? 'Unknown error',
//                       textAlign: TextAlign.center,
//                       style: Theme.of(context).textTheme.bodyMedium,
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: _loadTeamMembers,
//                       icon: const Icon(Icons.refresh),
//                       label: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             // Show empty state
//             if (profileProvider.users.isEmpty) {
//               return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       Icons.people_outline,
//                       size: 48,
//                       color: Colors.grey.shade400,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'No team members found',
//                       style: Theme.of(context).textTheme.bodyLarge,
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             // Show list of team members
//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: profileProvider.users.length,
//               itemBuilder: (context, index) {
//                 final user = profileProvider.users[index];
//                 return _buildTeamMemberCard(context, user);
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTeamMemberCard(BuildContext context, dynamic user) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   radius: 24,
//                   backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
//                   child: Icon(
//                     Icons.person,
//                     color: AppTheme.primaryColor,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         user.name,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         user.username,
//                         style: TextStyle(
//                           color: Colors.grey.shade600,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             _buildDetailRow('Role', user.role),
//             _buildDetailRow('Department', user.dept),
//             _buildDetailRow('Email', user.email),
//             _buildDetailRow('Join Date', user.joinDate),
//             if (user.salary != null && user.salary > 0)
//               _buildDetailRow('Salary', '₹${user.salary}'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Text(
//             '$label: ',
//             style: const TextStyle(
//               color: Colors.grey,
//               fontSize: 12,
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 fontWeight: FontWeight.w500,
//                 fontSize: 12,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// IMPLEMENTATION CHECKLIST:
// ///
// /// 1. Add ProfileProvider to main.dart:
// ///    ```dart
// ///    ChangeNotifierProvider<ProfileProvider>(
// ///      create: (context) => ProfileProvider(
// ///        apiService: context.read<ApiService>(),
// ///      ),
// ///    )
// ///    ```
// ///
// /// 2. Use Consumer widget to listen to state changes:
// ///    ✓ Already implemented in example
// ///
// /// 3. Handle three states:
// ///    ✓ Loading state
// ///    ✓ Error state
// ///    ✓ Success state with data
// ///    ✓ Empty state
// ///
// /// 4. Implement refresh functionality:
// ///    ✓ RefreshIndicator with pulldown
// ///    ✓ Retry button on error
// ///
// /// 5. Show appropriate UI for each state:
// ///    ✓ Loading spinner
// ///    ✓ Error message with retry
// ///    ✓ Empty state message
// ///    ✓ Data list with cards
// ///
// /// 6. Handle errors gracefully:
// ///    ✓ Display error message
// ///    ✓ Provide retry option
// ///    ✓ Check for 401 and trigger logout
