import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for managing AI chat conversations using Firebase Vertex AI (Gemini)
/// with function calling for EGData API integration
class AIChatService {
  final ApiService _apiService;
  final String _country;
  GenerativeModel? _model;
  ChatSession? _chatSession;

  AIChatService({required ApiService apiService, required String country})
    : _apiService = apiService,
      _country = country;

  /// Initialize the generative model with EGData tools
  void initialize() {
    if (_model != null) return;

    // Define the tools following the Discord bot pattern
    final tools = [
      Tool.functionDeclarations([
        _createSearchOffersTool(),
        _createGetOfferDetailsTool(),
        _createGetOfferPriceTool(),
        _createGetFreeGamesTool(),
        _createGetTopSellersTool(),
        _createGetTopWishlistedTool(),
        _createGetUpcomingGamesTool(),
        _createGetLatestReleasesTool(),
        _createSearchSellersTool(),
      ]),
    ];

    // Configure thinking to enhance reasoning capabilities
    final thinkingConfig = ThinkingConfig(
      thinkingBudget: -1, // Dynamic thinking - model determines optimal allocation
      includeThoughts: true, // Include thought summaries in responses
    );

    final generationConfig = GenerationConfig(
      thinkingConfig: thinkingConfig,
    );

    // Create the generative model with tools
    // Using Gemini 2.5 Flash because Gemini 3 requires thought_signature support
    // which is not yet fully implemented in firebase_ai SDK for streaming function calls
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      tools: tools,
      generationConfig: generationConfig,
      systemInstruction: Content.text(
        'You are EGData AI, an Epic Games Store assistant. '
        'Current user country: $_country\n\n'

        '## Core Behavior\n'
        '- **Helpful & Smart**: Use reasoning and knowledge to answer questions. You know about games, developers, genres, and gaming history.\n'
        '- **Tools for Live Data**: Use tools ONLY for current prices, availability, and store data. Your knowledge covers game info, recommendations, and riddles.\n'
        '- **Be Concise**: Direct answers. No narration ("Let me search..."). Just answer.\n\n'

        '## When to Use Tools vs Knowledge\n\n'
        '**Use Tools For:**\n'
        '• Current prices, sales, discounts (get_offer_price, search_offers with onSale)\n'
        '• What\'s available NOW on Epic Store (search_offers)\n'
        '• Active free games (get_free_games)\n'
        '• Specific offer details (get_offer_details)\n\n'

        '**Use Your Knowledge For:**\n'
        '• Game recommendations by genre, theme, developer\n'
        '• Riddles, clues, trivia about games\n'
        '• Developer/publisher info (country of origin, history)\n'
        '• Game mechanics, story summaries, comparisons\n'
        '• "Games like X" suggestions\n\n'

        '## Output Format\n'
        '- **Game titles**: **Bold**\n'
        '- **Prices**: **\$14.99** ~~\$59.99~~ (-75%) — discount first, original with strikethrough\n'
        '- **Dates**: Clear format (e.g., "January 8, 2026")\n'
        '- **Lists**: Bullet points (•) for games, features\n'
        '- **Structure**: Short paragraphs, scannable\n\n'

        '## Tool Usage\n'
        '- **search_offers**: Find games with filters (offerType, tags, onSale, price range, seller)\n'
        '- **get_offer_price**: Current pricing (always pass country "$_country")\n'
        '- **get_offer_details**: Description, release date, requirements\n'
        '- **get_free_games**: Active giveaways with end dates\n'
        '- **get_top_sellers / get_top_wishlisted**: Popular games\n\n'

        '## Rules\n'
        '1. For riddles/recommendations: Use knowledge first, optionally search to verify availability\n'
        '2. For prices/sales: ALWAYS use tools with country "$_country"\n'
        '3. Show 5-7 results unless asked for more\n'
        '4. Keep responses focused and scannable',
      ),
    );

    // Start a new chat session
    _chatSession = _model!.startChat();
  }

  /// Create search_offers tool
  FunctionDeclaration _createSearchOffersTool() {
    return FunctionDeclaration(
      'search_offers',
      'Search games with filters (offerType, seller, tags, price range, discounts). Returns game titles and IDs.',
      parameters: {
        'query': Schema.string(
          description: 'Search query for game titles',
        ),
        'offerType': Schema.string(
          description: 'Type: BASE_GAME, DLC, BUNDLE, EDITION, DEMO, etc.',
        ),
        'tags': Schema.array(
          items: Schema.string(),
          description: 'Genre/category tags (e.g., ["RPG", "Action"])',
        ),
        'onSale': Schema.boolean(
          description: 'Filter for games currently on sale',
        ),
        'priceMin': Schema.integer(
          description: 'Minimum price in cents (e.g., 1000 for \$10)',
        ),
        'priceMax': Schema.integer(
          description: 'Maximum price in cents (e.g., 2000 for \$20)',
        ),
        'limit': Schema.integer(
          description: 'Max results (default: 10, max: 10)',
        ),
      },
    );
  }

  /// Create get_offer_details tool
  FunctionDeclaration _createGetOfferDetailsTool() {
    return FunctionDeclaration(
      'get_offer_details',
      'Get full details for a single game including description, release date, seller, tags, and requirements.',
      parameters: {
        'offerId': Schema.string(
          description: 'The offer ID from search results',
        ),
      },
    );
  }

  /// Create get_offer_price tool
  FunctionDeclaration _createGetOfferPriceTool() {
    return FunctionDeclaration(
      'get_offer_price',
      'Get current pricing for a single game with original price, discount price, and discount percentage.',
      parameters: {'offerId': Schema.string(description: 'The offer ID')},
    );
  }

  /// Create get_free_games tool
  FunctionDeclaration _createGetFreeGamesTool() {
    return FunctionDeclaration(
      'get_free_games',
      'Get currently active free game giveaways from Epic Games Store.',
      parameters: {},
    );
  }

  /// Create get_top_sellers tool
  FunctionDeclaration _createGetTopSellersTool() {
    return FunctionDeclaration(
      'get_top_sellers',
      'Get best-selling games (returns titles and IDs only, use get_offer_price for pricing).',
      parameters: {
        'count': Schema.integer(
          description: 'Number of results (max: 50)',
        ),
      },
    );
  }

  /// Create get_top_wishlisted tool
  FunctionDeclaration _createGetTopWishlistedTool() {
    return FunctionDeclaration(
      'get_top_wishlisted',
      'Get most-wishlisted games (returns titles and IDs only, use get_offer_price for pricing).',
      parameters: {
        'count': Schema.integer(
          description: 'Number of results (max: 50)',
        ),
      },
    );
  }

  /// Create get_upcoming_games tool
  FunctionDeclaration _createGetUpcomingGamesTool() {
    return FunctionDeclaration(
      'get_upcoming_games',
      'Get upcoming game releases with release dates.',
      parameters: {
        'limit': Schema.integer(
          description: 'Number of results per page',
        ),
      },
    );
  }

  /// Create get_latest_releases tool
  FunctionDeclaration _createGetLatestReleasesTool() {
    return FunctionDeclaration(
      'get_latest_releases',
      'Get recently released games.',
      parameters: {
        'limit': Schema.integer(
          description: 'Number of results per page',
        ),
      },
    );
  }

  /// Create search_sellers tool
  FunctionDeclaration _createSearchSellersTool() {
    return FunctionDeclaration(
      'search_sellers',
      'Find publishers/developers by name to get seller IDs for filtering.',
      parameters: {
        'query': Schema.string(
          description: 'Publisher or developer name to search for',
        ),
      },
    );
  }

  /// Send a message and get streaming response with function calling and thinking
  Stream<String> sendMessage(String userMessage) async* {
    if (_model == null || _chatSession == null) {
      initialize();
    }

    try {
      final response = _chatSession!.sendMessageStream(
        Content.text(userMessage),
      );

      var hasYieldedThoughts = false;

      await for (final chunk in response) {
        // Stream thought summaries if available
        final thoughtSummary = chunk.thoughtSummary;
        if (thoughtSummary != null && thoughtSummary.isNotEmpty) {
          if (!hasYieldedThoughts) {
            yield '<thinking>\n';
            hasYieldedThoughts = true;
          }
          yield thoughtSummary;
        }

        // Check if Gemini wants to call functions
        final functionCalls = chunk.functionCalls.toList();
        if (functionCalls.isNotEmpty) {
          // Execute each function call and send response back
          for (final functionCall in functionCalls) {
            debugPrint('AI calling function: ${functionCall.name}');

            try {
              final result = await _executeTool(
                functionCall.name,
                functionCall.args,
              );

              // Send function response back to the model
              final followUpResponse = _chatSession!.sendMessageStream(
                Content.functionResponse(functionCall.name, result),
              );

              // Stream the model's response after receiving function result
              await for (final followUpChunk in followUpResponse) {
                // Stream thought summaries from follow-up response
                final followUpThought = followUpChunk.thoughtSummary;
                if (followUpThought != null && followUpThought.isNotEmpty) {
                  if (!hasYieldedThoughts) {
                    yield '<thinking>\n';
                    hasYieldedThoughts = true;
                  }
                  yield followUpThought;
                }

                final text = followUpChunk.text;
                if (text != null && text.isNotEmpty) {
                  // Close thinking tag before answer
                  if (hasYieldedThoughts) {
                    yield '\n</thinking>\n\n';
                    hasYieldedThoughts = false;
                  }
                  yield text;
                }
              }
            } catch (e) {
              debugPrint('Error executing ${functionCall.name}: $e');
              // Send error as function response
              final errorResponse = _chatSession!.sendMessageStream(
                Content.functionResponse(functionCall.name, {
                  'error': 'Failed to execute: ${e.toString()}',
                }),
              );

              await for (final errorChunk in errorResponse) {
                final text = errorChunk.text;
                if (text != null && text.isNotEmpty) {
                  yield text;
                }
              }
            }
          }
        } else {
          // Regular text response
          final text = chunk.text;
          if (text != null && text.isNotEmpty) {
            // Close thinking tag before answer
            if (hasYieldedThoughts) {
              yield '\n</thinking>\n\n';
              hasYieldedThoughts = false;
            }
            yield text;
          }
        }
      }
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      yield 'Sorry, I encountered an error: ${e.toString()}';
    }
  }

  /// Execute a tool function
  Future<Map<String, dynamic>> _executeTool(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    switch (toolName) {
      case 'search_offers':
        return await _searchOffers(args);
      case 'get_offer_details':
        return await _getOfferDetails(args);
      case 'get_offer_price':
        return await _getOfferPrice(args);
      case 'get_free_games':
        return await _getFreeGames();
      case 'get_top_sellers':
        return await _getTopSellers(args);
      case 'get_top_wishlisted':
        return await _getTopWishlisted(args);
      case 'get_upcoming_games':
        return await _getUpcomingGames(args);
      case 'get_latest_releases':
        return await _getLatestReleases(args);
      case 'search_sellers':
        return await _searchSellers(args);
      default:
        return {'error': 'Unknown tool: $toolName'};
    }
  }

  /// Implement search_offers
  Future<Map<String, dynamic>> _searchOffers(Map<String, dynamic> args) async {
    try {
      final query = args['query'] as String?;
      final offerTypeStr = args['offerType'] as String?;
      final onSale = args['onSale'] as bool?;
      final priceMin = args['priceMin'] as num?;
      final priceMax = args['priceMax'] as num?;
      final tagsList = args['tags'] as List?;
      final limit = (args['limit'] as num?)?.toInt() ?? 10;

      SearchOfferType? offerType;
      if (offerTypeStr != null) {
        offerType = SearchOfferType.values.firstWhere(
          (e) => e.value == offerTypeStr,
          orElse: () => SearchOfferType.baseGame,
        );
      }

      List<String>? tags;
      if (tagsList != null && tagsList.isNotEmpty) {
        tags = tagsList.map((e) => e.toString()).toList();
      }

      PriceRange? priceRange;
      if (priceMin != null || priceMax != null) {
        priceRange = PriceRange(min: priceMin?.toInt(), max: priceMax?.toInt());
      }

      final searchRequest = SearchRequest(
        title: query,
        offerType: offerType,
        onSale: onSale,
        price: priceRange,
        tags: tags,
        limit: limit.clamp(1, 10),
        sortBy: onSale == true
            ? SearchSortBy.discountPercent
            : SearchSortBy.lastModifiedDate,
        sortDir: SearchSortDir.desc,
      );

      final searchResponse = await _apiService.search(
        searchRequest,
        country: _country,
      );

      final results = searchResponse.offers.map((offer) {
        final price = offer.price?.totalPrice;
        final originalPrice = price?.originalPrice ?? 0;
        final discountPrice = price?.discountPrice ?? originalPrice;
        final discount = price?.discountPercent ?? 0;

        return {
          'offerId': offer.id,
          'title': offer.title,
          'offerType': offer.offerType,
          'originalPrice': '\$${(originalPrice / 100).toStringAsFixed(2)}',
          'discountPrice': discountPrice != originalPrice
              ? '\$${(discountPrice / 100).toStringAsFixed(2)}'
              : null,
          'discount': discount,
          'releaseDate': offer.releaseDate?.toIso8601String(),
          'developer': offer.seller?.name,
        };
      }).toList();

      return {
        'results': results,
        'total': searchResponse.total,
        'count': results.length,
      };
    } catch (e) {
      return {'error': e.toString(), 'results': []};
    }
  }

  /// Implement get_offer_details
  Future<Map<String, dynamic>> _getOfferDetails(
    Map<String, dynamic> args,
  ) async {
    try {
      final offerId = args['offerId'] as String;
      final offer = await _apiService.getOffer(offerId);

      return {
        'offerId': offer.id,
        'title': offer.title,
        'description': offer.description,
        'releaseDate': offer.releaseDate?.toIso8601String(),
        'developer': offer.seller?.name,
        'tags': offer.tags.map((t) => t.name).toList(),
        'offerType': offer.offerType,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Implement get_offer_price
  Future<Map<String, dynamic>> _getOfferPrice(Map<String, dynamic> args) async {
    try {
      final offerId = args['offerId'] as String;
      final priceData = await _apiService.getOfferPrice(
        offerId,
        country: _country,
      );

      if (priceData == null) {
        return {'error': 'Price not found for this offer'};
      }

      final originalPrice = priceData.originalPrice;
      final discountPrice = priceData.discountPrice;
      final discount = priceData.discountPercent ?? 0;

      return {
        'offerId': offerId,
        'originalPrice': '\$${(originalPrice / 100).toStringAsFixed(2)}',
        'discountPrice': discountPrice != originalPrice
            ? '\$${(discountPrice / 100).toStringAsFixed(2)}'
            : null,
        'discount': discount,
        'onSale': discount > 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Implement get_free_games
  Future<Map<String, dynamic>> _getFreeGames() async {
    try {
      final freeGames = await _apiService.getFreeGames();
      final now = DateTime.now();

      final active = freeGames
          .where((g) {
            if (g.giveaway == null) return false;
            return now.isAfter(g.giveaway!.startDate) &&
                now.isBefore(g.giveaway!.endDate);
          })
          .map((game) {
            return {
              'offerId': game.id,
              'title': game.title,
              'description': game.description,
              'startDate': game.giveaway?.startDate.toIso8601String(),
              'endDate': game.giveaway?.endDate.toIso8601String(),
            };
          })
          .toList();

      return {'games': active, 'count': active.length};
    } catch (e) {
      return {'error': e.toString(), 'games': []};
    }
  }

  /// Implement get_top_sellers
  Future<Map<String, dynamic>> _getTopSellers(Map<String, dynamic> args) async {
    try {
      final count = (args['count'] as num?)?.toInt() ?? 10;

      // Use search API to get recent popular games
      final searchRequest = SearchRequest(
        offerType: SearchOfferType.baseGame,
        sortBy: SearchSortBy.lastModifiedDate,
        sortDir: SearchSortDir.desc,
        limit: count.clamp(1, 50),
      );

      final result = await _apiService.search(searchRequest, country: _country);

      return {
        'games': result.offers
            .map((offer) => {'offerId': offer.id, 'title': offer.title})
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString(), 'games': []};
    }
  }

  /// Implement get_top_wishlisted
  Future<Map<String, dynamic>> _getTopWishlisted(
    Map<String, dynamic> args,
  ) async {
    try {
      final count = (args['count'] as num?)?.toInt() ?? 10;

      // Use search API to get popular games
      final searchRequest = SearchRequest(
        offerType: SearchOfferType.baseGame,
        sortBy: SearchSortBy.lastModifiedDate,
        sortDir: SearchSortDir.desc,
        limit: count.clamp(1, 50),
      );

      final result = await _apiService.search(searchRequest, country: _country);

      return {
        'games': result.offers
            .map((offer) => {'offerId': offer.id, 'title': offer.title})
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString(), 'games': []};
    }
  }

  /// Implement get_upcoming_games
  Future<Map<String, dynamic>> _getUpcomingGames(
    Map<String, dynamic> args,
  ) async {
    try {
      final limit = (args['limit'] as num?)?.toInt() ?? 10;

      // Use search API with upcoming sort
      final searchRequest = SearchRequest(
        offerType: SearchOfferType.baseGame,
        sortBy: SearchSortBy.upcoming,
        sortDir: SearchSortDir.asc,
        limit: limit,
      );

      final result = await _apiService.search(searchRequest, country: _country);

      return {
        'games': result.offers
            .map(
              (offer) => {
                'offerId': offer.id,
                'title': offer.title,
                'releaseDate': offer.releaseDate?.toIso8601String(),
              },
            )
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString(), 'games': []};
    }
  }

  /// Implement get_latest_releases
  Future<Map<String, dynamic>> _getLatestReleases(
    Map<String, dynamic> args,
  ) async {
    try {
      final limit = (args['limit'] as num?)?.toInt() ?? 10;

      // Use search API sorted by release date
      final searchRequest = SearchRequest(
        offerType: SearchOfferType.baseGame,
        sortBy: SearchSortBy.releaseDate,
        sortDir: SearchSortDir.desc,
        limit: limit,
      );

      final result = await _apiService.search(searchRequest, country: _country);

      return {
        'games': result.offers
            .map(
              (offer) => {
                'offerId': offer.id,
                'title': offer.title,
                'releaseDate': offer.releaseDate?.toIso8601String(),
              },
            )
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString(), 'games': []};
    }
  }

  /// Implement search_sellers
  Future<Map<String, dynamic>> _searchSellers(Map<String, dynamic> args) async {
    try {
      final query = args['query'] as String;

      // Search for games by this seller/publisher
      final searchRequest = SearchRequest(title: query, limit: 10);

      final result = await _apiService.search(searchRequest, country: _country);

      // Extract unique sellers from results
      final sellersMap = <String, String>{};
      for (final offer in result.offers) {
        if (offer.seller != null) {
          sellersMap[offer.seller!.id] = offer.seller!.name;
        }
      }

      return {
        'sellers': sellersMap.entries
            .map((entry) => {'sellerId': entry.key, 'name': entry.value})
            .toList(),
      };
    } catch (e) {
      return {'error': e.toString(), 'sellers': []};
    }
  }

  /// Clear chat history and start fresh
  void clearChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Dispose resources
  void dispose() {
    _chatSession = null;
    _model = null;
  }
}
