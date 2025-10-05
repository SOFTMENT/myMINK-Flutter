import 'dart:io';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/collections.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/constants/contries_list.dart';
import 'package:mymink/core/constants/product_categories.dart';
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
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/features/marketplace/data/models/marketplace_model.dart';
import 'package:mymink/core/widgets/images_picker.dart';

class EditOrAddProductPage extends StatefulWidget {
  const EditOrAddProductPage({super.key, this.product});
  final MarketplaceModel? product; // ← null = Add, non-null = Edit

  @override
  State<EditOrAddProductPage> createState() => _EditOrAddProductPageState();
}

class _EditOrAddProductPageState extends State<EditOrAddProductPage> {
  // Local image files chosen in this session (aligned by index with preview URLs)
  final List<File?> _images = [null];

  // Existing image URLs for edit mode (shown when file is null)
  final List<String> _existingImageUrls = [];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _category = "";
  String _title = "";
  String _price = "";
  String _description = "";
  String? _loadingMessage;
  final _categoryCtrl = TextEditingController();
  String currency = 'AUD';

  bool get isEdit => widget.product != null;
  String countryCode = '';
  @override
  void initState() {
    super.initState();
    if (isEdit) _hydrateFromProduct(widget.product!);
    _detectUserCountryIfNeeded();
  }

  // Only detect if we didn't extract currency from existing product
  void _detectUserCountryIfNeeded() async {
    if (isEdit && currency.isNotEmpty) return;
    try {
      final localeString =
          await Devicelocale.currentLocale; // e.g. "en-US" or "en_US"
      if (localeString != null) {
        final parts = localeString.contains('-')
            ? localeString.split('-')
            : localeString.split('_');
        if (parts.length >= 2) {
          countryCode = parts[1].toUpperCase();
          _applyCountryCurrency(countryCode);
        }
      }
    } catch (e) {
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

  void _hydrateFromProduct(MarketplaceModel p) {
    // Title / description / category
    _title = p.title;
    _description = p.about;
    _category = p.categoryName;
    _categoryCtrl.text = _category;

    // Price + Currency parse (handle "50 AUD" or "AUD 50")
    final parsedCurrency = _extractCurrency(p.cost);
    final parsedPrice = _extractPrice(p.cost);
    if (parsedCurrency != null) currency = parsedCurrency;
    if (parsedPrice != null) _price = parsedPrice;

    // Existing image URLs (limit to 4)
    if (p.productImages.isNotEmpty) {
      _existingImageUrls
        ..clear()
        ..addAll(p.productImages.take(4));
      // Align files list to same length with nulls
      _images
        ..clear()
        ..addAll(List<File?>.filled(_existingImageUrls.length, null));
    }
  }

  String? _extractCurrency(String cost) {
    // look for a 3-letter code (USD, AUD, INR, etc.)
    final match = RegExp(r'\b([A-Z]{3})\b').firstMatch(cost.toUpperCase());
    return match?.group(1);
    // If your app stores currency words (e.g., "Rupees"), expand mapping as needed.
  }

  String? _extractPrice(String cost) {
    // numbers with optional decimals; keep it simple
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(cost);
    final raw = match?.group(1);
    return raw?.replaceAll(
        ',', '.'); // normalize 1,234.56 or 1234,56 → "1234.56"
  }

  Future<void> _pickCategory() async {
    final categories = [...productCategories]..removeAt(0);
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ListView.separated(
            physics: const ClampingScrollPhysics(),
            shrinkWrap: true,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final item = categories[i];
              final isSelected = item == _category;
              return ListTile(
                title: Text(item),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(item),
              );
            },
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        _category = selected;
        _categoryCtrl.text = selected;
      });
    }
  }

  Future<void> _btnClicked() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final hasAnyImage =
        _existingImageUrls.isNotEmpty || _images.any((f) => f != null);
    if (!hasAnyImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload at least 1 product image.")),
      );
      return;
    }

    final id = isEdit
        ? widget.product!.id
        : FirebaseService().db.collection(Collections.marketplace).doc().id;

    final uid = FirebaseService().auth.currentUser!.uid;

    final model = MarketplaceModel(
      id: id,
      uid: uid,

      title: _title,
      cost: '$_price $currency',
      about: _description,
      categoryName: _category,
      isActive: isEdit ? (widget.product!.isActive) : true,
      dateCreated: isEdit ? widget.product!.dateCreated : DateTime.now(),
      productUrl: isEdit ? widget.product!.productUrl : '',
      countryCode: countryCode,
      productImages: const [], // temp; we fill after upload/merge
    );

    // Upload new files and merge with existing URLs by slot index
    final mergedUrls = <String>[];
    final slotCount = [_existingImageUrls.length, _images.length, 4]
        .reduce((a, b) => a > b ? a : b); // max, capped by 4

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Images Uploading...';
    });

    for (int i = 0; i < slotCount && i < 4; i++) {
      final file = (i < _images.length) ? _images[i] : null;
      final existingUrl =
          (i < _existingImageUrls.length) ? _existingImageUrls[i] : null;

      if (file != null) {
        final result = await AWSUploader.uploadFile(
          folderName: 'ProductImages',
          postType: PostType.image,
          previousKey: null, // keep null; we’re not replacing on S3 by key here
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

    // If still empty (user removed all), guard
    if (mergedUrls.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload at least 1 product image.")),
      );
      return;
    }

    model.productImages = mergedUrls;

    // Create deep link for new product; keep existing for edits
    if (!isEdit || (model.productUrl.isEmpty)) {
      final dl = await DeepLinkService.createDeepLinkForProduct(model);
      if (dl.hasData) {
        model.productUrl = dl.data ?? '';
      }
    }

    try {
      setState(() => _loadingMessage = 'Saving...');
      await FirebaseService()
          .db
          .collection(Collections.marketplace)
          .doc(model.id)
          .set(model.toJson());

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Product Updated' : 'Product Added')),
      );

      await Future.delayed(const Duration(seconds: 1));
      context.pop(isEdit);
    } catch (e) {
      setState(() => _isLoading = false);
      CustomDialog.show(context, title: 'ERROR', message: e.toString());
    }
  }

  void deleteProduct() async {
    await FirebaseService()
        .db
        .collection(Collections.marketplace)
        .doc(widget.product!.id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: const Text('Product Deleted'),
      ),
    );

    Future.delayed(const Duration(seconds: 1));
    context.pop(true);
  }

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
                    title: isEdit ? 'Edit Product' : 'Add Product',
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
                                      "Are you sure you want to delete this product?"),
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
                                        deleteProduct();
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
                                      Icon(
                                        Icons.delete_outline,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        'Delete',
                                        style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 13),
                                      ),
                                    ]),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Image',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Use a high quality image: (9:5 ratio)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textDarkGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ImagesPicker(
                          images: _images,
                          previewUrls: _existingImageUrls, // ← show existing
                          onTapSlot: (index) async {
                            // Ensure list has this slot
                            while (_images.length <= index) {
                              _images.add(null);
                            }
                            String? source =
                                await ImagePickerDialog.show(context);
                            if (source != null) {
                              File? image = await ImageService().pickImage(
                                  context, source,
                                  ratioX: 9, ratioY: 5);
                              if (image != null) {
                                setState(() {
                                  _images[index] = image; // replace slot
                                });
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: _categoryCtrl,
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  onTap: _pickCategory,
                                  onSaved: (v) => _category = v ?? '',
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? "Select Category"
                                      : null,
                                  decoration: buildInputDecoration(
                                    labelText: "Category",
                                    prefixIcon: null,
                                  ),
                                ),
                              ),
                              const Positioned(
                                right: 10,
                                top: 10,
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: AppColors.textDarkGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              initialValue: isEdit ? _title : null,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.words,
                              onSaved: (v) => _title = v ?? '',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Enter Product Title"
                                  : null,
                              decoration: buildInputDecoration(
                                labelText: "Title",
                                prefixIcon: null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: TextFormField(
                              initialValue: isEdit ? _price : null,
                              keyboardType: TextInputType.number,
                              autocorrect: false,
                              onSaved: (v) => _price = v ?? '',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Enter Product Price"
                                  : null,
                              decoration: buildInputDecoration(
                                labelText: "Price $currency",
                                prefixIcon: null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Product Description",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: TextFormField(
                              initialValue: isEdit ? _description : null,
                              textCapitalization: TextCapitalization.sentences,
                              keyboardType: TextInputType.multiline,
                              autocorrect: false,
                              maxLines: 7,
                              minLines: 7,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? "Enter Product Description"
                                  : null,
                              onSaved: (v) => _description = v ?? '',
                              decoration: buildInputDecoration(
                                labelText: "",
                                prefixIcon: null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            text: isEdit ? "Save Changes" : "Add",
                            onPressed: _btnClicked,
                            backgroundColor: AppColors.textBlack,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Center(
                child: ProgressHud(message: _loadingMessage),
              ),
          ],
        ),
      ),
    );
  }
}
