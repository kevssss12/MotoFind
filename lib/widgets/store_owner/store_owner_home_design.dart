import 'package:flutter/material.dart';

class StoreOwnerHomeDesign extends StatelessWidget {
  final String storeName;
  final String ownerName;
  final String? storeImageUrl;

  final int totalProducts;
  final int lowStockProducts;
  final int reservedOrders;
  final String totalSales;

  final bool hasSubscriptionAlert;
  final String? subscriptionMessage;

  final VoidCallback? onInventory;
  final VoidCallback? onAddProduct;
  final VoidCallback? onSales;
  final VoidCallback? onReservedOrders;
  final VoidCallback? onBills;
  final VoidCallback? onProfile;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  const StoreOwnerHomeDesign({
    super.key,
    required this.storeName,
    required this.ownerName,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.reservedOrders,
    required this.totalSales,
    this.storeImageUrl,
    this.hasSubscriptionAlert = false,
    this.subscriptionMessage,
    this.onInventory,
    this.onAddProduct,
    this.onSales,
    this.onReservedOrders,
    this.onBills,
    this.onProfile,
    this.onSettings,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      // ============================================================
      // APP BAR
      // ============================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        titleSpacing: 20,
        title: const Text(
          'Store Owner',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: onProfile,
            icon: const Icon(
              Icons.account_circle_outlined,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // DRAWER
      // ============================================================

      drawer: _buildDrawer(context),

      // ============================================================
      // BODY
      // ============================================================

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {},
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ==================================================
                // STORE HEADER
                // ==================================================

                _buildStoreHeader(),

                const SizedBox(height: 20),

                // ==================================================
                // SUBSCRIPTION ALERT
                // ==================================================

                if (hasSubscriptionAlert) ...[
                  _buildSubscriptionAlert(),
                  const SizedBox(height: 20),
                ],

                // ==================================================
                // OVERVIEW TITLE
                // ==================================================

                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // ==================================================
                // STAT CARDS
                // ==================================================

                _buildStats(),

                const SizedBox(height: 26),

                // ==================================================
                // QUICK ACTIONS
                // ==================================================

                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                _buildQuickActions(),

                const SizedBox(height: 26),

                // ==================================================
                // MANAGEMENT
                // ==================================================

                const Text(
                  'Store Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                _buildManagementCard(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // STORE HEADER
  // ==============================================================

  Widget _buildStoreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [

          // STORE IMAGE
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: storeImageUrl != null &&
                      storeImageUrl!.isNotEmpty
                  ? Image.network(
                      storeImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.storefront,
                          size: 34,
                          color: Colors.black54,
                        );
                      },
                    )
                  : const Icon(
                      Icons.storefront,
                      size: 34,
                      color: Colors.black54,
                    ),
            ),
          ),

          const SizedBox(width: 15),

          // STORE INFORMATION
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  ownerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SUBSCRIPTION ALERT
  // ==============================================================

  Widget _buildSubscriptionAlert() {
    return InkWell(
      onTap: onBills,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.orange.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
                size: 27,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subscription Alert',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subscriptionMessage ??
                        'Your subscription needs attention.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // STAT CARDS
  // ==============================================================

  Widget _buildStats() {
    return Column(
      children: [

        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                value: '$totalProducts',
                onTap: onInventory,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                icon: Icons.warning_amber_rounded,
                title: 'Low Stock',
                value: '$lowStockProducts',
                onTap: onInventory,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Reserved',
                value: '$reservedOrders',
                onTap: onReservedOrders,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _statCard(
                icon: Icons.payments_outlined,
                title: 'Sales',
                value: totalSales,
                onTap: onSales,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.black87,
                size: 23,
              ),
            ),

            const SizedBox(height: 13),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // QUICK ACTIONS
  // ==============================================================

  Widget _buildQuickActions() {
    return Row(
      children: [

        Expanded(
          child: _actionCard(
            icon: Icons.add_box_outlined,
            title: 'Add Product',
            onTap: onAddProduct,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _actionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory',
            onTap: onInventory,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _actionCard(
            icon: Icons.point_of_sale_outlined,
            title: 'Sales',
            onTap: onSales,
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [

            Icon(
              icon,
              size: 27,
              color: Colors.black87,
            ),

            const SizedBox(height: 9),

            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // STORE MANAGEMENT
  // ==============================================================

  Widget _buildManagementCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          _managementTile(
            icon: Icons.receipt_long_outlined,
            title: 'Reserved Orders',
            subtitle: 'View and manage customer reservations',
            onTap: onReservedOrders,
          ),

          _divider(),

          _managementTile(
            icon: Icons.receipt_outlined,
            title: 'Bills & Subscription',
            subtitle: 'View your subscription and payment status',
            onTap: onBills,
          ),

          _divider(),

          _managementTile(
            icon: Icons.store_outlined,
            title: 'Store Profile',
            subtitle: 'Manage your store information',
            onTap: onProfile,
          ),

          _divider(),

          _managementTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Manage your account settings',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [

            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.black87,
                size: 22,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 73,
      endIndent: 16,
      color: Colors.grey.shade200,
    );
  }

  // ==============================================================
  // DRAWER
  // ==============================================================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [

            // DRAWER HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                20,
                28,
                20,
                24,
              ),
              color: Colors.black87,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        storeImageUrl != null &&
                                storeImageUrl!.isNotEmpty
                            ? NetworkImage(storeImageUrl!)
                            : null,
                    child: storeImageUrl == null ||
                            storeImageUrl!.isEmpty
                        ? const Icon(
                            Icons.storefront,
                            size: 34,
                            color: Colors.black54,
                          )
                        : null,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    ownerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            _drawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
            ),

            _drawerItem(
              icon: Icons.inventory_2_outlined,
              title: 'Inventory',
              onTap: () {
                Navigator.pop(context);
                onInventory?.call();
              },
            ),

            _drawerItem(
              icon: Icons.add_box_outlined,
              title: 'Add Product',
              onTap: () {
                Navigator.pop(context);
                onAddProduct?.call();
              },
            ),

            _drawerItem(
              icon: Icons.point_of_sale_outlined,
              title: 'Sales',
              onTap: () {
                Navigator.pop(context);
                onSales?.call();
              },
            ),

            _drawerItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Reserved Orders',
              onTap: () {
                Navigator.pop(context);
                onReservedOrders?.call();
              },
            ),

            _drawerItem(
              icon: Icons.receipt_long_outlined,
              title: 'Bills',
              onTap: () {
                Navigator.pop(context);
                onBills?.call();
              },
            ),

            const Spacer(),

            const Divider(),

            _drawerItem(
              icon: Icons.store_outlined,
              title: 'Store Profile',
              onTap: () {
                Navigator.pop(context);
                onProfile?.call();
              },
            ),

            _drawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                onSettings?.call();
              },
            ),

            _drawerItem(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: onLogout,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}