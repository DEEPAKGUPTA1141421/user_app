import 'package:flutter/material.dart';

class Address {
  final String id;
  final String name;
  final String address;
  final bool isSelected;

  Address({
    required this.id,
    required this.name,
    required this.address,
    required this.isSelected,
  });

  Address copyWith({bool? isSelected}) {
    return Address(
      id: id,
      name: name,
      address: address,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class DeliveryAddressSelector extends StatefulWidget {
  final VoidCallback? onClose;
  final ValueChanged<Address>? onAddressSelect;

  const DeliveryAddressSelector(
      {super.key, this.onClose, this.onAddressSelect});

  @override
  State<DeliveryAddressSelector> createState() =>
      _DeliveryAddressSelectorState();
}

class _DeliveryAddressSelectorState extends State<DeliveryAddressSelector> {
  String searchQuery = '';
  List<Address> addresses = [
    Address(
        id: '1',
        name: 'Deepak',
        address: '403, zolo darren, 153 50, Maruthi Nagar, Madival...',
        isSelected: true),
    Address(
        id: '2',
        name: 'Himanshu Kumar Gupta',
        address: 'Bus stand kursakanta, Sub Health Centre, Sikti...',
        isSelected: false),
    Address(
        id: '3',
        name: 'DEEPAK KUMAR GUPTA',
        address: 'Chitkara university darwin hostel, Rajpura Subdi...',
        isSelected: false),
    Address(
        id: '4',
        name: 'Himanshu Kumar Gupta Gupta',
        address: 'Bus, Bus stand area, Araria',
        isSelected: false),
    Address(
        id: '5',
        name: 'Himanshugupta',
        address: 'PRANAV dresses, PRANAV DRESSES, Araria Dis...',
        isSelected: false),
    Address(
        id: '6',
        name: 'Vijay Gupta',
        address: 'mandir ke samne, SP Sharma Vashist Niwas, D...',
        isSelected: false),
  ];

  void handleAddressSelect(String selectedId) {
    setState(() {
      addresses = addresses
          .map((addr) => addr.copyWith(isSelected: addr.id == selectedId))
          .toList();
    });
    final selectedAddress =
        addresses.firstWhere((addr) => addr.id == selectedId);
    widget.onAddressSelect?.call(selectedAddress);
  }

  void handleUseCurrentLocation() {
    debugPrint('Using current location...');
  }

  void handleAddNewAddress() {
    debugPrint('Adding new address...');
  }

  @override
  Widget build(BuildContext context) {
    final filteredAddresses = addresses.where((addr) {
      final q = searchQuery.toLowerCase();
      return addr.name.toLowerCase().contains(q) ||
          addr.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Search
            _buildSearchBar(),

            // Use Current Location
            _buildCurrentLocationButton(),

            // Saved Addresses
            _buildSavedAddressesTitle(),

            // Address List
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: filteredAddresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final address = filteredAddresses[index];
                  return _buildAddressCard(address);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Select delivery address",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Search by area, street name, pin code",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _buildCurrentLocationButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: handleUseCurrentLocation,
        icon: const Icon(Icons.location_on, color: Colors.white),
        label: const Text("Use my current location"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          minimumSize: const Size.fromHeight(48),
        ),
      ),
    );
  }

  Widget _buildSavedAddressesTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Saved addresses",
              style: TextStyle(fontWeight: FontWeight.w600)),
          TextButton.icon(
            onPressed: handleAddNewAddress,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Add New"),
          )
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address address) {
    return InkWell(
      onTap: () => handleAddressSelect(address.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: address.isSelected
              ? Colors.orange.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: address.isSelected ? Colors.orange : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.home, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(address.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      if (address.isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Currently selected",
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.address,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                debugPrint("More options for ${address.name}");
              },
              icon: const Icon(Icons.more_horiz),
            )
          ],
        ),
      ),
    );
  }
}
