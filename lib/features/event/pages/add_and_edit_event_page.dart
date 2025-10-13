import 'dart:convert';
import 'dart:io';

import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mymink/core/constants/api_constants.dart';
import 'package:mymink/core/constants/collections.dart';

import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/contries_list.dart';
import 'package:mymink/core/services/aws_uploader.dart';
import 'package:mymink/core/services/deep_link_service.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/services/image_service.dart';
import 'package:mymink/core/utils/common_input_decoration.dart';
import 'package:mymink/core/utils/image_picker_dialog.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/custom_button.dart';
import 'package:mymink/core/widgets/custom_dialog.dart';
import 'package:mymink/core/widgets/dismiss_keyboard_ontap.dart';
import 'package:mymink/core/widgets/images_picker.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/event/data/models/event.dart';
import 'package:mymink/features/event/data/models/places_suggestion.dart';

class AddAndEditEventPage extends StatefulWidget {
  const AddAndEditEventPage({Key? key, this.event}) : super(key: key);

  /// null => Add mode; non-null => Edit mode
  final EventModel? event;

  @override
  State<AddAndEditEventPage> createState() => _AddAndEditEventPageState();
}

class _AddAndEditEventPageState extends State<AddAndEditEventPage> {
  // -------------------- state & flags --------------------
  final _formKey = GlobalKey<FormState>();

  bool get isEdit => widget.event != null;

  // Local image files chosen in this session (aligned with preview URLs)
  final List<File?> _images = [null];

  // Existing image URLs for edit mode (shown when file is null)
  final List<String> _existingImageUrls = [];

  String currency = 'AUD';

  String _title = '';
  String _location = '';
  String _description = '';
  String _ticketPrice = '';
  bool _isLoading = false;
  String? _loadingMessage;

  // Location textfield
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocus = FocusNode();

  // Autocomplete state
  List<PlaceSuggestion> _suggestions = [];
  DateTime _lastQueryAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Selected place details (kept for submit)
  String? _selectedPlaceName;
  double? _selectedLat;
  double? _selectedLng;
  String countryCode = '';

  // Date/time
  final TextEditingController _startDateController = TextEditingController();
  DateTime? _eventStartDateTime;

  // Google Places API key from .env
  static final String kGooglePlacesApiKey = ApiConstants.googlePlacesApiKey;

  @override
  void initState() {
    super.initState();
    if (isEdit) _hydrateFromEvent(widget.event!);
    _detectUserCountryCodeIfNeeded();
    _locationController.addListener(_onLocationChanged);
    _locationFocus.addListener(() {
      if (!_locationFocus.hasFocus) {
        setState(() => _suggestions = []);
      }
    });
  }

  // -------------------- init helpers --------------------

  void _hydrateFromEvent(EventModel e) {
    // Basic fields
    _title = e.title;
    _description = e.description;
    _location = e.address;
    _selectedPlaceName = e.addressName;
    _selectedLat = e.latitude;
    _selectedLng = e.longitude;
    countryCode = (e.countryCode).toUpperCase();

    // Date/time
    _eventStartDateTime = e.startDate;
    if (_eventStartDateTime != null) {
      final fmt = DateFormat('EEE, MMM d • h:mm a', 'en_US');
      _startDateController.text = fmt.format(_eventStartDateTime!);
    }

    // Ticket price parsing (e.g., "50 AUD" or "AUD 50")
    final parsedCurrency = _extractCurrency(e.ticketPrice ?? '');
    final parsedPrice = _extractPrice(e.ticketPrice ?? '');
    if (parsedCurrency != null) currency = parsedCurrency;
    if (parsedPrice != null) _ticketPrice = parsedPrice;

    // Images
    final imgs = (e.eventImages).take(4).toList();
    _existingImageUrls
      ..clear()
      ..addAll(imgs);
    // Align local files length for slots
    _images
      ..clear()
      ..addAll(List<File?>.filled(
          _existingImageUrls.length == 0 ? 1 : _existingImageUrls.length,
          null));

    // UI fields
    _locationController.text = _location;
    setState(() {});
  }

  void _detectUserCountryCodeIfNeeded() async {
    // If we already have a currency from the event, skip detection
    if (isEdit && currency.isNotEmpty) return;
    try {
      final localeString = await Devicelocale.currentLocale; // "en-US"
      if (localeString != null) {
        final parts = localeString.contains('-')
            ? localeString.split('-')
            : localeString.split('_');
        if (parts.length >= 2) {
          countryCode = parts[1].toUpperCase();
          _applyCountryCurrency(countryCode);
        }
      }
    } catch (_) {
      // ignore
    }
  }

  void _applyCountryCurrency(String code) {
    final country = countryList.firstWhere(
      (e) => (e['code'] ?? '').toUpperCase() == code,
      orElse: () => {"currency": "AUD"},
    );
    setState(() => currency = (country['currency'] ?? 'AUD').toUpperCase());
  }

  String? _extractCurrency(String cost) {
    final match = RegExp(r'\b([A-Z]{3})\b').firstMatch(cost.toUpperCase());
    return match?.group(1);
  }

  String? _extractPrice(String cost) {
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(cost);
    final raw = match?.group(1);
    return raw?.replaceAll(',', '.');
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _locationController.removeListener(_onLocationChanged);
    _locationController.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  // -------------------- pickers --------------------

  Future<void> _pickEventStart() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _eventStartDateTime ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: 'Select event date',
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Select start time',
    );
    if (pickedTime == null) return;

    final dt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final fmt = DateFormat('EEE, MMM d • h:mm a', 'en_US');

    setState(() {
      _eventStartDateTime = dt;
      _startDateController.text = fmt.format(dt);
    });
  }

  // -------------------- autocomplete --------------------

  void _onLocationChanged() {
    final text = _locationController.text.trim();
    final now = DateTime.now();
    if (now.difference(_lastQueryAt) < const Duration(milliseconds: 300))
      return;
    _lastQueryAt = now;

    if (text.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _fetchSuggestions(text);
  }

  Future<void> _fetchSuggestions(String input) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': input,
          'key': kGooglePlacesApiKey,
          'language': 'en',
        },
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;

      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') return;

      final preds = (data['predictions'] as List)
          .map((e) => PlaceSuggestion.fromJson(e))
          .toList();

      if (!mounted) return;
      setState(() => _suggestions = preds);
    } catch (_) {}
  }

  Future<void> _resolvePlace(String placeId, String fallbackDescription) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': placeId,
          'fields': 'name,geometry/location,formatted_address',
          'key': kGooglePlacesApiKey,
          'language': 'en',
        },
      );
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return;

      final data = json.decode(resp.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return;

      final result = data['result'] as Map<String, dynamic>;
      final name = (result['name'] as String?) ??
          (result['formatted_address'] as String?) ??
          fallbackDescription;

      final loc =
          (result['geometry']?['location'] as Map<String, dynamic>?) ?? {};
      final lat = (loc['lat'] as num?)?.toDouble();
      final lng = (loc['lng'] as num?)?.toDouble();

      if (!mounted) return;
      setState(() {
        _selectedPlaceName = name;
        _selectedLat = lat;
        _selectedLng = lng;
      });
    } catch (_) {}
  }

  // -------------------- submit / delete --------------------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    _formKey.currentState?.save();

    final firebase = FirebaseService();
    final uid = firebase.auth.currentUser!.uid;

    final id = isEdit
        ? widget.event!.id
        : firebase.db.collection(Collections.events).doc().id;

    final model = EventModel(
      id: id,
      eventCreateDate: isEdit ? widget.event!.eventCreateDate : DateTime.now(),
    );

    model.title = _title;
    model.eventOrganizerUid = isEdit ? (widget.event!.eventOrganizerUid) : uid;
    model.description = _description;
    model.ticketPrice = '$_ticketPrice $currency';
    model.isActive = isEdit ? (widget.event!.isActive) : true;
    model.startDate = _eventStartDateTime;
    model.latitude = _selectedLat;
    model.longitude = _selectedLng;
    model.address = _location;
    model.countryCode = countryCode;
    model.addressName = _selectedPlaceName ?? '';
    model.eventUrl = isEdit ? (widget.event!.eventUrl) : '';

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Images Uploading...';
    });

    // Upload new files and merge with existing URLs by slot index
    final mergedUrls = <String>[];
    final slotCount = [_existingImageUrls.length, _images.length, 4]
        .reduce((a, b) => a > b ? a : b); // max, capped by 4

    for (int i = 0; i < slotCount && i < 4; i++) {
      final file = (i < _images.length) ? _images[i] : null;
      final existingUrl =
          (i < _existingImageUrls.length) ? _existingImageUrls[i] : null;

      if (file != null) {
        final result = await AWSUploader.uploadFile(
          folderName: 'EventImages',
          postType: PostType.image,
          previousKey: null,
          photo: file,
          context: context,
        );
        if (result.hasData && result.data!.isNotEmpty) {
          mergedUrls.add(result.data!);
        } else if (existingUrl != null && existingUrl.isNotEmpty) {
          mergedUrls.add(existingUrl);
        }
      } else if (existingUrl != null && existingUrl.isNotEmpty) {
        mergedUrls.add(existingUrl);
      }
    }

    if (mergedUrls.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload at least 1 event image.")),
      );
      return;
    }

    model.eventImages = mergedUrls;

    // Create deep link for NEW events or if missing in existing
    if (!isEdit || (model.eventUrl.isEmpty)) {
      final dl = await DeepLinkService.createDeepLinkForEvent(model);
      if (dl.hasData) {
        model.eventUrl = dl.data ?? '';
      }
    }

    try {
      setState(() => _loadingMessage = 'Saving...');
      await FirebaseService()
          .db
          .collection(Collections.events)
          .doc(model.id)
          .set(model.toJson());

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Event Updated' : 'Event Added')),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _isLoading = false);
      CustomDialog.show(context, title: 'ERROR', message: e.toString());
    }
  }

  Future<void> _deleteEvent() async {
    if (!isEdit) return;
    await FirebaseService()
        .db
        .collection(Collections.events)
        .doc(widget.event!.id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Deleted')),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) context.pop(true);
  }

  // -------------------- ui --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DismissKeyboardOnTap(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomAppBar(
                    title: isEdit ? 'Edit Event' : 'Create Event',
                    width: 90,
                    gestureDetector: isEdit
                        ? GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    "DELETE",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  content: const Text(
                                      "Are you sure you want to delete this event?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                            color: AppColors.textDarkGrey),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _deleteEvent();
                                      },
                                      child: const Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        color: AppColors.white),
                                    SizedBox(width: 4),
                                    Text('Delete',
                                        style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ---------------- Images ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Image',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use a high quality images: (9: 5 ratio).',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDarkGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ImagesPicker(
                          images: _images,
                          previewUrls: _existingImageUrls,
                          onTapSlot: (index) async {
                            while (_images.length <= index) {
                              _images.add(null);
                            }
                            final source =
                                await ImagePickerDialog.show(context);
                            if (source != null) {
                              final image = await ImageService().pickImage(
                                  context, source,
                                  ratioX: 9, ratioY: 5);
                              if (image != null) {
                                setState(() => _images[index] = image);
                              }
                            }
                          },
                          onAddMore: () {
                            if ((_images.length >= 4) &&
                                (_existingImageUrls.length >= 4)) return;
                            setState(() => _images.add(null));
                          },
                          canAddMore: (_images.length < 4) ||
                              (_existingImageUrls.length < 4),
                        ),
                        const SizedBox(height: 10),

                        // ---------------- FORM ----------------
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Basic Info',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Name your event and tell event-goers why they should come.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Title
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  initialValue: isEdit ? _title : null,
                                  textCapitalization: TextCapitalization.words,
                                  onSaved: (v) => _title = (v ?? '').trim(),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? "Enter Title"
                                          : null,
                                  decoration: buildInputDecoration(
                                    labelText: "Title",
                                    prefixIcon: null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Location labels
                              const Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Help people in the area discover your event.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Location TextField
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _locationController,
                                  focusNode: _locationFocus,
                                  keyboardType: TextInputType.name,
                                  autocorrect: false,
                                  textCapitalization: TextCapitalization.words,
                                  onSaved: (v) => _location = (v ?? '').trim(),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? "Enter Location"
                                          : null,
                                  decoration: buildInputDecoration(
                                    labelText: "Location",
                                    prefixIcon: null,
                                  ),
                                ),
                              ),

                              // Suggestions list
                              if (_suggestions.isNotEmpty &&
                                  _locationFocus.hasFocus)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        color: Color(0x11000000),
                                      ),
                                    ],
                                    border: Border.all(
                                        color: const Color(0x11000000)),
                                  ),
                                  constraints:
                                      const BoxConstraints(maxHeight: 260),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _suggestions.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (ctx, i) {
                                      final s = _suggestions[i];
                                      return ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.location_on_outlined,
                                          color: AppColors.textDarkGrey,
                                        ),
                                        title: Text(
                                          s.mainText.isNotEmpty
                                              ? s.mainText
                                              : s.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.textBlack,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: s.secondaryText.isNotEmpty
                                            ? Text(
                                                s.secondaryText,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.textDarkGrey,
                                                  fontSize: 12,
                                                ),
                                              )
                                            : null,
                                        onTap: () async {
                                          _locationController.text =
                                              s.description;
                                          _locationController.selection =
                                              TextSelection.fromPosition(
                                            TextPosition(
                                              offset: _locationController
                                                  .text.length,
                                            ),
                                          );
                                          setState(() => _suggestions = []);
                                          _locationFocus.unfocus();
                                          FocusScope.of(context).unfocus();
                                          await _resolvePlace(
                                              s.placeId, s.description);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 20),

                              // Date/time labels
                              const Text(
                                'Date and time',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tell event-goers when your event starts.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Start Date (readOnly)
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _startDateController,
                                  readOnly: true,
                                  onTap: _pickEventStart,
                                  keyboardType: TextInputType.datetime,
                                  autocorrect: false,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? "Enter Date"
                                          : null,
                                  decoration: buildInputDecoration(
                                    labelText: "Event Start Date",
                                    prefixIcon: null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Description
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: AppColors.textBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Add more details like schedule, sponsors, or guests.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                              const SizedBox(height: 16),

                              SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: TextFormField(
                                  initialValue: isEdit ? _description : null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  keyboardType: TextInputType.multiline,
                                  autocorrect: false,
                                  maxLines: 7,
                                  minLines: 7,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? "Enter Event Description"
                                          : null,
                                  onSaved: (v) =>
                                      _description = (v ?? '').trim(),
                                  decoration: buildInputDecoration(
                                    labelText: "",
                                    prefixIcon: null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Ticket price
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  initialValue: isEdit ? _ticketPrice : null,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return "Enter Ticket Price";
                                    }
                                    final n = double.tryParse(
                                        v.trim().replaceAll(',', '.'));
                                    if (n == null || n < 0) {
                                      return "Enter valid Ticket Price";
                                    }
                                    return null;
                                  },
                                  onSaved: (v) =>
                                      _ticketPrice = (v ?? '').trim(),
                                  decoration: buildInputDecoration(
                                    labelText: "Ticket Price $currency",
                                    prefixIcon: null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ---------------- FORM END ----------------

                        const SizedBox(height: 32),
                        SafeArea(
                          top: false,
                          child: CustomButton(
                            text: isEdit ? 'Save Changes' : 'Add Event',
                            onPressed: _submit,
                            backgroundColor: AppColors.textBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Center(child: ProgressHud(message: _loadingMessage)),
          ],
        ),
      ),
    );
  }
}
