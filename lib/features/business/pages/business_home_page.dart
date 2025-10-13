import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';
import 'package:mymink/core/constants/colors.dart';
import 'package:mymink/core/services/firebase_service.dart';
import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';
import 'package:mymink/features/business/data/models/business_model.dart';
import 'package:mymink/features/business/data/services/business_service.dart';
import 'package:mymink/features/business/widgets/business_item.dart';

class BusinessHomePage extends ConsumerStatefulWidget {
  const BusinessHomePage({Key? key}) : super(key: key);

  @override
  _BusinessHomePageState createState() => _BusinessHomePageState();
}

class _BusinessHomePageState extends ConsumerState<BusinessHomePage>
    with AutomaticKeepAliveClientMixin<BusinessHomePage> {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;

  List<BusinessModel> _businesses = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  BusinessModel? _businessModel;
  final TextEditingController _searchController = TextEditingController();
  String _error = "No businesses available";

  // NEW: Track search mode + current query
  bool _isSearchMode = false;
  String _currentSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchTextChanged);
    _loadInitialBusinesses(true);
    _loadMyBusinessModel();
  }

  void _loadMyBusinessModel() async {
    final result = await BusinessService.getBusinessByUid(
        FirebaseService().auth.currentUser!.uid);
    if (result.hasData) {
      _businessModel = result.data!;
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore &&
        _lastDocument != null) {
      _loadMoreBusinesses();
    }
  }

  void _onSearchTextChanged() {
    final t = _searchController.text.trim();
    if (t.isEmpty && _isSearchMode && !_isLoading) {
      // Reset to normal (non-search) list
      setState(() {
        _isSearchMode = false;
        _currentSearchTerm = '';
        _businesses = [];
        _lastDocument = null;
        _hasMore = true;
      });
      // Reload original list from Firestore
      _loadInitialBusinesses(true);
    }
  }

  Future<void> _refreshBusinesses() async {
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });

    if (_isSearchMode) {
      await _applySearch(); // refresh current search
    } else {
      await _loadInitialBusinesses(false);
    }
  }

  Future<void> _loadInitialBusinesses(bool shouldShowLoader) async {
    if (shouldShowLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    final result = await BusinessService.getBusinessesPaginated(
      pageSize: _pageSize,
    );

    if (shouldShowLoader) {
      setState(() {
        _isLoading = false;
      });
    }

    if (result.hasData) {
      _businesses = result.data!.businesses;
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.businesses.length == _pageSize;
      setState(() {});
    } else {
      setState(() {
        _error = result.error ?? 'No businesses available';
      });
    }
  }

  /// 2) Called when user taps the search button or picks a letter
  Future<void> _applySearch() async {
    final term = _searchController.text.trim();

    // Hide keyboard
    FocusScope.of(context).unfocus();

    // Reset paging state
    setState(() {
      _isLoading = true;
      _businesses = [];
      _lastDocument = null;
      _hasMore = true;
      _error = 'No businesses available';
    });

    if (term.isEmpty) {
      _isSearchMode = false;
      _currentSearchTerm = '';
      await _loadInitialBusinesses(false);
      setState(() => _isLoading = false);
      return;
    }

    _isSearchMode = true;
    _currentSearchTerm = term;

    final result = await BusinessService.searchBusinessesByTextPaginated(
      term: term,
      pageSize: _pageSize,
    );

    if (result.hasData) {
      _businesses = result.data!.businesses;
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.businesses.length == _pageSize;
      if (_businesses.isEmpty) _error = 'No results found for "$term".';
    } else {
      _error = result.error ?? 'No results found for "$term".';
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreBusinesses() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final result = _isSearchMode
        ? await BusinessService.searchBusinessesByTextPaginated(
            term: _currentSearchTerm,
            pageSize: _pageSize,
            lastDoc: _lastDocument,
          )
        : await BusinessService.getBusinessesPaginated(
            pageSize: _pageSize,
            lastDoc: _lastDocument,
          );

    if (result.hasData) {
      _businesses.addAll(result.data!.businesses);
      _lastDocument = result.data!.lastDocument;
      if (result.data!.businesses.length < _pageSize) _hasMore = false;
      setState(() {});
    }

    setState(() {
      _isLoading = false;
    });
  }

  void businessAddedCallback() {
    _refreshBusinesses();
    _loadMyBusinessModel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              CustomAppBar(
                title: 'Businesses',
                width: 90,
                gestureDetector: GestureDetector(
                  onTap: () async {
                    if (_businessModel != null) {
                      await context.push(AppRoutes.businessDetailsPage,
                          extra: {'businessModel': _businessModel});
                      _loadMyBusinessModel();
                    } else {
                      context.push(AppRoutes.businessAddPage, extra: {
                        'callback': businessAddedCallback,
                      });
                    }
                  },
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'My Business',
                        style: TextStyle(color: AppColors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SearchBarWithButton(
                  controller: _searchController,
                  hintText: 'Search',
                  onPressed: _applySearch,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshBusinesses,
                  child: _businesses.isEmpty && !_isLoading
                      ? Center(
                          child: Text(
                            _isSearchMode ? 'No results found' : _error,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          itemCount: _businesses.length +
                              (_hasMore && !_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _businesses.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final b = _businesses[index];
                            return BusinessItem(
                              business: b,
                              onShareTap: () {},
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Center(
              child: ProgressHud(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _scrollController.dispose();

    super.dispose();
  }
}
