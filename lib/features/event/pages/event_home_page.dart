import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:mymink/core/constants/app_routes.dart';

import 'package:mymink/core/constants/colors.dart';

import 'package:mymink/core/widgets/custom_app_bar.dart';
import 'package:mymink/core/widgets/progress_hud.dart';
import 'package:mymink/core/widgets/search_bar_with_button.dart';

import 'package:mymink/features/event/data/models/event.dart';
import 'package:mymink/features/event/data/services/event_service.dart';
import 'package:mymink/features/event/widgets/event_item.dart';

class EventHomePage extends ConsumerStatefulWidget {
  const EventHomePage({Key? key}) : super(key: key);

  @override
  _EventHomePageState createState() => _EventHomePageState();
}

class _EventHomePageState extends ConsumerState<EventHomePage>
    with AutomaticKeepAliveClientMixin<EventHomePage> {
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 10;

  List<EventModel> _events = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  final TextEditingController _searchController = TextEditingController();
  String _error = "No events available";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialEvents(true);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore &&
        _lastDocument != null) {
      _loadMoreEvents();
    }
  }

  Future<void> _refreshEvent() async {
    setState(() {
      _lastDocument = null;
      _hasMore = true;
    });
    await _loadInitialEvents(false);
  }

  Future<void> _loadInitialEvents(bool shouldShowLoader) async {
    if (shouldShowLoader)
      setState(() {
        _isLoading = true;
      });

    final countryCode = await _userCoutryCode();

    final result = await EventService.getEventsPaginated(
        countryCode: countryCode ?? 'AU', pageSize: _pageSize);

    if (shouldShowLoader)
      setState(() {
        _isLoading = false;
      });

    if (result.hasData) {
      _events = result.data!.events;
      _lastDocument = result.data!.lastDocument;
      _hasMore = result.data!.events.length == _pageSize;
      setState(() {});
    } else {
      setState(() {
        print(result.error);
        _error = result.error!;
      });
    }
  }

  /// 2) Called when user taps the search button or picks a letter
  Future<void> _applySearch() async {}

  Future<void> _loadMoreEvents() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final countryCode = await _userCoutryCode();

    final result = await EventService.getEventsPaginated(
        countryCode: countryCode ?? 'AU', pageSize: _pageSize);

    if (result.hasData) {
      _events.addAll(result.data!.events);
      _lastDocument = result.data!.lastDocument;
      if (result.data!.events.length < _pageSize) _hasMore = false;
      setState(() {});
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String?> _userCoutryCode() async {
    final localeString =
        await Devicelocale.currentLocale; // e.g. "en-US" or "en_US"
    if (localeString != null) {
      final parts = localeString.contains('-')
          ? localeString.split('-')
          : localeString.split('_');
      if (parts.length >= 2) {
        final countryCode = parts[1].toUpperCase();
        return countryCode;
      }
    }
    return null;
  }

  void businessAddedCallback() {
    _refreshEvent();
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
                title: 'Events',
                width: 90,
                gestureDetector: GestureDetector(
                  onTap: () {
                    context.push(AppRoutes.eventOrganizationPage);
                  },
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'My Events',
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
                  onRefresh: _refreshEvent,
                  child: _events.isEmpty && !_isLoading
                      ? Center(
                          child: Text(
                            _error,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          itemCount: _events.length +
                              (_hasMore && !_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _events.length) {
                              // show loading indicator at bottom only if there are items
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final event = _events[index];
                            return EventItem(event: event);
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
    _scrollController.dispose();
    super.dispose();
  }
}
