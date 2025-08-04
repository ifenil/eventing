import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../providers/event_provider.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/event_card.dart';
import 'ticket_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch events when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchEvents();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 36,
        titleSpacing: 0,
      ),
      body: Consumer<EventProvider>(
        builder: (context, eventProvider, child) {
          switch (eventProvider.state) {
            case EventState.initial:
            case EventState.loading:
              return const AppLoadingWidget(
                message: 'Loading events...',
              );
            case EventState.error:
              return AppErrorWidget(
                message: eventProvider.errorMessage ?? AppConstants.unknownError,
                onRetry: () => eventProvider.refreshEvents(),
              );
            case EventState.loaded:
              if (!eventProvider.hasEvents) {
                return AppErrorWidget(
                  message: AppConstants.noEventsFound,
                  icon: Icons.event,
                  onRetry: () => eventProvider.refreshEvents(),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await eventProvider.fetchEvents();
                },
                child: ListView.builder(
                  itemCount: eventProvider.events.length,
                  itemBuilder: (context, index) {
                    final event = eventProvider.events[index];
                    return EventCard(
                      event: event,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketScreen(
                              eventId: event.id.toString(),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}