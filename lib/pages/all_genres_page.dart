import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluquery/fluquery.dart';
import '../main.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../widgets/genre_card.dart';
import 'mobile_browse_page.dart';

class AllGenresPage extends HookWidget {
  final FollowService followService;
  final AppSettings settings;
  final PushService? pushService;

  const AllGenresPage({
    super.key,
    required this.followService,
    required this.settings,
    this.pushService,
  });

  Future<List<GenreWithOffers>> _fetchAllGenres() async {
    final apiService = ApiService();
    return apiService.getGenres();
  }

  void _openBrowseWithGenre(BuildContext context, GenreInfo genre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              genre.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: MobileBrowsePage(
            followService: followService,
            settings: settings,
            pushService: pushService,
            initialGenreId: genre.id,
            initialGenreName: genre.name,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final genresQuery = useQuery<List<GenreWithOffers>, Object>(
      queryKey: ['all-genres'],
      queryFn: (_) => _fetchAllGenres(),
      staleTime: StaleTime(const Duration(minutes: 10)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Genres',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: genresQuery.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : genresQuery.isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load genres',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => genresQuery.refetch(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => genresQuery.refetch(),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: genresQuery.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final genre = genresQuery.data![index];
                      return GenreCard(
                        genreWithOffers: genre,
                        onTap: () => _openBrowseWithGenre(context, genre.genre),
                      );
                    },
                  ),
                ),
    );
  }
}
