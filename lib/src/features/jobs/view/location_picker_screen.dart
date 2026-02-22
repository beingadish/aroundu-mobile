import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/view_model/auth_view_model.dart';
import '../../../core/config/app_environment.dart';

// ── Places autocomplete suggestion ────────────────────────────────────────────

class _PlaceSuggestion {
  const _PlaceSuggestion({required this.description, required this.placeId});
  final String description;
  final String placeId;
}

// ── Reverse-geocoding result ──────────────────────────────────────────────────

class _GeoResult {
  const _GeoResult({
    this.fullAddress,
    this.area,
    this.city,
    this.postalCode,
    this.country,
  });
  final String? fullAddress;
  final String? area;
  final String? city;
  final String? postalCode;
  final String? country; // 2-letter ISO code, e.g. "IN"
}

// ── Main screen ───────────────────────────────────────────────────────────────

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  // tabs
  late final TabController _tabController;

  // map
  GoogleMapController? _mapController;
  LatLng _centre = const LatLng(28.6139, 77.2090);
  bool _mapReady = false;
  MapType _mapType = MapType.normal;

  // location
  bool _isGettingLocation = false;

  // places search
  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio();
  List<_PlaceSuggestion> _suggestions = const [];
  bool _isSearching = false;
  bool _showSuggestions = false;

  // dark-mode map style ("Night" palette)
  static const String _darkMapStyle = '''[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"poi.park","elementType":"labels.text.stroke","stylers":[{"color":"#1b1b1b"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
  {"featureType":"road.highway.controlled_access","elementType":"geometry","stylers":[{"color":"#4e4e4e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}]''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addr = ref.read(authControllerProvider).currentAddressFull;
      if (addr?.latitude != null && addr?.longitude != null) {
        setState(() => _centre = LatLng(addr!.latitude!, addr.longitude!));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  // ── map ───────────────────────────────────────────────────────────────────
  void _onMapCreated(GoogleMapController c) {
    _mapController = c;
    setState(() => _mapReady = true);
  }

  void _onCameraMove(CameraPosition pos) => _centre = pos.target;

  void _toggleMapType() => setState(() {
        _mapType =
            _mapType == MapType.normal ? MapType.satellite : MapType.normal;
      });

  // ── current location ──────────────────────────────────────────────────────
  Future<void> _goToCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permanently denied. Enable it in Settings.'),
          ));
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final target = LatLng(pos.latitude, pos.longitude);
      _centre = target;
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  // ── reverse geocoding ─────────────────────────────────────────────────────
  Future<_GeoResult> _reverseGeocode(LatLng point) async {
    try {
      final key = AppEnvironment.googleMapsApiKey;
      final res = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${point.latitude},${point.longitude}',
          'key': key,
        },
      );
      final data = res.data;
      if (data == null || data['status'] != 'OK') return const _GeoResult();

      final results = data['results'] as List;
      if (results.isEmpty) return const _GeoResult();

      final first = results.first as Map<String, dynamic>;
      final formatted = first['formatted_address'] as String?;
      final components = first['address_components'] as List;

      String? area, city, postalCode, country;
      for (final c in components) {
        final types = List<String>.from(c['types'] as List);
        final longName = c['long_name'] as String;
        final shortName = c['short_name'] as String;
        if (types.contains('sublocality_level_1') ||
            types.contains('sublocality') ||
            types.contains('neighborhood')) {
          area ??= longName;
        } else if (types.contains('locality')) {
          city ??= longName;
        } else if (types.contains('postal_code')) {
          postalCode ??= longName;
        } else if (types.contains('country')) {
          country ??= shortName; // e.g. "IN"
        }
      }

      return _GeoResult(
        fullAddress: formatted,
        area: area,
        city: city,
        postalCode: postalCode,
        country: country,
      );
    } catch (_) {
      return const _GeoResult();
    }
  }

  // ── address confirmation bottom sheet ─────────────────────────────────────
  Future<AddressInfo?> _showAddressSheet(_GeoResult geo) async {
    final result = await showModalBottomSheet<AddressInfo>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddressConfirmSheet(geo: geo, centre: _centre),
    );
    return result;
  }

  // ── confirm pinned location ───────────────────────────────────────────────
  Future<void> _confirmPinnedLocation() async {
    // 1. Reverse-geocode the current pin position
    final geo = await _reverseGeocode(_centre);

    // If search bar has text, prefer it as fullAddress
    final finalGeo = _searchController.text.isNotEmpty
        ? _GeoResult(
            fullAddress: _searchController.text,
            area: geo.area,
            city: geo.city,
            postalCode: geo.postalCode,
            country: geo.country,
          )
        : geo;

    // 2. Show address confirmation sheet
    if (!mounted) return;
    final confirmed = await _showAddressSheet(finalGeo);
    if (confirmed == null || !mounted) return;

    // 3. Return the completed AddressInfo to the caller
    Navigator.of(context).pop(confirmed);
  }

  void _selectSavedAddress(AddressInfo address) =>
      Navigator.of(context).pop(address);

  // ── places search ─────────────────────────────────────────────────────────
  Future<void> _searchPlaces(String input) async {
    if (input.trim().isEmpty) {
      setState(() {
        _suggestions = const [];
        _showSuggestions = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final key = AppEnvironment.googleMapsApiKey;
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: <String, String>{
          'input': input.trim(),
          'key': key,
          // No 'types' filter → all places (restaurants, POIs, addresses…)
        },
      );
      final data = response.data;
      if (data != null && data['status'] == 'OK') {
        final predictions = data['predictions'] as List<dynamic>;
        setState(() {
          _suggestions = predictions
              .map((p) => _PlaceSuggestion(
                    description: p['description'] as String,
                    placeId: p['place_id'] as String,
                  ))
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      } else {
        setState(() {
          _suggestions = const [];
          _showSuggestions = false;
        });
      }
    } catch (_) {
      setState(() {
        _suggestions = const [];
        _showSuggestions = false;
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectPlace(_PlaceSuggestion suggestion) async {
    setState(() {
      _showSuggestions = false;
      _suggestions = const [];
    });
    _searchController.text = suggestion.description;
    FocusScope.of(context).unfocus();
    try {
      final key = AppEnvironment.googleMapsApiKey;
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: <String, String>{
          'place_id': suggestion.placeId,
          'fields': 'geometry',
          'key': key,
        },
      );
      final data = response.data;
      if (data != null && data['status'] == 'OK') {
        final loc =
            data['result']['geometry']['location'] as Map<String, dynamic>;
        final target = LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );
        _centre = target;
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
              CameraPosition(target: target, zoom: 15)),
        );
      }
    } catch (_) {}
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allAddresses = <AddressInfo>[
      if (auth.currentAddressFull != null) auth.currentAddressFull!,
      ...auth.savedAddresses
          .where((a) => a.id != auth.currentAddressFull?.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Location'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bookmark_outline_rounded), text: 'Saved'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Pin on Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _SavedAddressesTab(
            addresses: allAddresses,
            onSelect: _selectSavedAddress,
            currentAddressId: auth.currentAddressId,
          ),
          _buildMapTab(isDark),
        ],
      ),
    );
  }

  Widget _buildMapTab(bool isDark) {
    final mapStyle =
        isDark && _mapType == MapType.normal ? _darkMapStyle : null;

    return Stack(
      children: [
        // ── Google Map ──────────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(target: _centre, zoom: 14),
          onCameraMove: _onCameraMove,
          mapType: _mapType,
          style: mapStyle,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          mapToolbarEnabled: false,
        ),

        // ── Fixed centre pin ───────────────────────────────────────────────
        if (_mapReady)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, size: 52, color: Colors.red),
            ),
          ),

        // ── Floating search bar + autocomplete ─────────────────────────────
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                shadowColor: Colors.black38,
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchPlaces,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search places…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _suggestions = const [];
                                    _showSuggestions = false;
                                  });
                                },
                              )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              if (_showSuggestions && _suggestions.isNotEmpty)
                Material(
                  elevation: 6,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14)),
                  shadowColor: Colors.black38,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14)),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length.clamp(0, 5),
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 48),
                      itemBuilder: (context, i) {
                        final s = _suggestions[i];
                        return ListTile(
                          dense: true,
                          leading:
                              const Icon(Icons.place_outlined, size: 20),
                          title: Text(
                            s.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => _selectPlace(s),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Right-side FABs ────────────────────────────────────────────────
        Positioned(
          right: 12,
          bottom: 92,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'mapType',
                tooltip: _mapType == MapType.normal
                    ? 'Switch to Satellite'
                    : 'Switch to Road map',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 4,
                onPressed: _toggleMapType,
                child: Icon(
                  _mapType == MapType.normal
                      ? Icons.satellite_alt_rounded
                      : Icons.map_rounded,
                ),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.small(
                heroTag: 'myLocation',
                tooltip: 'Go to my location',
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.primary,
                elevation: 4,
                onPressed:
                    _isGettingLocation ? null : _goToCurrentLocation,
                child: _isGettingLocation
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
        ),

        // ── Confirm button ─────────────────────────────────────────────────
        Positioned(
          bottom: 24,
          left: 16,
          right: 70,
          child: FilledButton.icon(
            onPressed: _mapReady ? _confirmPinnedLocation : null,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Confirm Location'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ],
    );
  }
}

// ── Saved Addresses Tab ───────────────────────────────────────────────────────

// ── Address Confirm Sheet ─────────────────────────────────────────────────────

/// A self-contained StatefulWidget for the address confirmation bottom sheet.
/// Managing controllers here ties their lifecycle to this widget's State,
/// preventing the use-after-dispose crash that occurs when controllers are
/// created in a method and disposed before the sheet animation finishes.
class _AddressConfirmSheet extends StatefulWidget {
  const _AddressConfirmSheet({
    required this.geo,
    required this.centre,
  });

  final _GeoResult geo;
  final LatLng centre;

  @override
  State<_AddressConfirmSheet> createState() => _AddressConfirmSheetState();
}

class _AddressConfirmSheetState extends State<_AddressConfirmSheet> {
  late final TextEditingController _areaCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _countryCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _areaCtrl = TextEditingController(text: widget.geo.area ?? '');
    _cityCtrl = TextEditingController(text: widget.geo.city ?? '');
    _postalCtrl = TextEditingController(text: widget.geo.postalCode ?? '');
    _countryCtrl = TextEditingController(text: widget.geo.country ?? 'IN');
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'Confirm Address Details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Pre-filled from the map — edit anything that looks off.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // Full address banner (read-only)
              if (widget.geo.fullAddress != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.geo.fullAddress!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Area / Neighbourhood
              TextFormField(
                controller: _areaCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Area / Neighbourhood',
                  hintText: 'e.g. Connaught Place',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // City
              TextFormField(
                controller: _cityCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'City',
                  hintText: 'e.g. New Delhi',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Postal Code — REQUIRED
              TextFormField(
                controller: _postalCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Postal Code *',
                  hintText: 'e.g. 110001',
                  prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Country — REQUIRED (ISO 2-letter)
              TextFormField(
                controller: _countryCtrl,
                textInputAction: TextInputAction.done,
                maxLength: 2,
                decoration: const InputDecoration(
                  labelText: 'Country Code *',
                  hintText: 'e.g. IN',
                  prefixIcon: Icon(Icons.flag_outlined),
                  counterText: '',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use This Location'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop(
                        AddressInfo(
                          fullAddress: widget.geo.fullAddress,
                          area: _areaCtrl.text.trim().isEmpty
                              ? null
                              : _areaCtrl.text.trim(),
                          city: _cityCtrl.text.trim().isEmpty
                              ? null
                              : _cityCtrl.text.trim(),
                          postalCode: _postalCtrl.text.trim(),
                          country:
                              _countryCtrl.text.trim().toUpperCase(),
                          latitude: widget.centre.latitude,
                          longitude: widget.centre.longitude,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Saved Addresses Tab ───────────────────────────────────────────────────────

class _SavedAddressesTab extends StatelessWidget {
  const _SavedAddressesTab({
    required this.addresses,
    required this.onSelect,
    this.currentAddressId,
  });

  final List<AddressInfo> addresses;
  final void Function(AddressInfo) onSelect;
  final int? currentAddressId;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text('No saved addresses yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Switch to the Pin on Map tab to pick any location.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final addr = addresses[index];
        final isCurrent =
            addr.id != null && addr.id == currentAddressId;

        return Card(
          child: ListTile(
            leading: Icon(
              isCurrent ? Icons.home_rounded : Icons.location_on_outlined,
              color:
                  isCurrent ? Theme.of(context).colorScheme.primary : null,
            ),
            title: Text(
              // Prefer fullAddress as the primary title — it's the richest text
              addr.fullAddress ?? addr.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: addr.displayName != (addr.fullAddress ?? addr.displayName)
                ? Text(
                    addr.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: isCurrent
                ? Chip(
                    label: const Text('Current'),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 6),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: () => onSelect(addr),
          ),
        );
      },
    );
  }
}
