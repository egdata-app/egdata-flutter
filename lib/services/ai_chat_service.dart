import 'dart:async';
import 'dart:convert';
import 'package:langchain/langchain.dart';
import 'package:langchain_firebase/langchain_firebase.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for managing AI chat conversations using LangChain with Gemini
/// with tool calling for EGData API integration
class AIChatService {
  final ApiService _apiService;
  final String _country;
  ChatFirebaseVertexAI? _chatModel;
  SystemChatMessage? _systemMessage;
  List<Tool> _tools = [];
  List<ChatMessage> _chatHistory = [];

  AIChatService({required ApiService apiService, required String country})
    : _apiService = apiService,
      _country = country;

  /// Initialize the chat model with EGData tools
  void initialize() {
    if (_chatModel != null) return;

    debugPrint('🔧 Initializing AIChatService...');

    debugPrint('📱 Creating ChatFirebaseVertexAI...');
    _chatModel = ChatFirebaseVertexAI(
      defaultOptions: const ChatFirebaseVertexAIOptions(
        model: 'gemini-2.5-pro',
        temperature: 0.7,
      ),
    );
    debugPrint('✅ Model created');

    debugPrint('📝 Creating system message...');
    final systemInstructionText =
        'You are EGData AI, an Epic Games Store assistant. '
        'User\'s default country: $_country\n\n'
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
        '- **Prices**: **\$40.19** ~~\$59.99~~ (-33%) — discount first, original with strikethrough, percentage in parentheses\n'
        '- **Dates**: Clear format (e.g., "January 8, 2026")\n'
        '- **Lists**: Bullet points (•) for games, features\n'
        '- **Structure**: Short paragraphs, scannable\n\n'
        '## Tool Usage\n'
        '- **search_offers**: Find games with filters (offerType, tags, onSale, price range, seller). Uses user\'s country ($_country) for pricing.\n'
        '- **get_offer_price**: Get pricing for ANY country. Pass country code (e.g., "ES" for Spain, "US" for United States) or omit for user\'s default ($_country).\n'
        '- **get_offer_details**: Description, release date, requirements\n'
        '- **get_free_games**: Active giveaways with end dates\n'
        '- **get_top_sellers / get_top_wishlisted**: Popular games\n\n'
        '## Pricing & Countries\n'
        '- You CAN provide prices for ANY country when asked (use get_offer_price with country parameter)\n'
        '- Common country codes: US, UK, ES (Spain), DE (Germany), FR (France), IT (Italy), CA (Canada), AU (Australia), JP (Japan)\n'
        '- When user asks "in [country]", use the appropriate country code\n'
        '- Default to user\'s country ($_country) only when no specific country is mentioned\n\n'
        '## Rules\n'
        '1. For riddles/recommendations: Use knowledge first, optionally search to verify availability\n'
        '2. For prices: Use get_offer_price with appropriate country code (default to "$_country" if not specified)\n'
        '3. Show 5-7 results unless asked for more\n'
        '4. Keep responses focused and scannable';

    _systemMessage = SystemChatMessage(content: systemInstructionText);
    debugPrint('✅ System message created');

    debugPrint('🔨 Creating tools...');
    try {
      debugPrint('  Creating search_offers tool...');
      final tool1 = _createSearchOffersTool();
      debugPrint('  ✅ search_offers created');

      debugPrint('  Creating get_offer_details tool...');
      final tool2 = _createGetOfferDetailsTool();
      debugPrint('  ✅ get_offer_details created');

      debugPrint('  Creating get_offer_price tool...');
      final tool3 = _createGetOfferPriceTool();
      debugPrint('  ✅ get_offer_price created');

      debugPrint('  Creating get_free_games tool...');
      final tool4 = _createGetFreeGamesTool();
      debugPrint('  ✅ get_free_games created');

      debugPrint('  Creating get_top_sellers tool...');
      final tool5 = _createGetTopSellersTool();
      debugPrint('  ✅ get_top_sellers created');

      debugPrint('  Creating get_top_wishlisted tool...');
      final tool6 = _createGetTopWishlistedTool();
      debugPrint('  ✅ get_top_wishlisted created');

      debugPrint('  Creating get_upcoming_games tool...');
      final tool7 = _createGetUpcomingGamesTool();
      debugPrint('  ✅ get_upcoming_games created');

      debugPrint('  Creating get_latest_releases tool...');
      final tool8 = _createGetLatestReleasesTool();
      debugPrint('  ✅ get_latest_releases created');

      debugPrint('  Creating search_sellers tool...');
      final tool9 = _createSearchSellersTool();
      debugPrint('  ✅ search_sellers created');

      _tools = [tool1, tool2, tool3, tool4, tool5, tool6, tool7, tool8, tool9];
      debugPrint('✅ All tools created and added to list');
    } catch (e) {
      debugPrint('❌ Error creating tools: $e');
      rethrow;
    }

    _chatHistory = [];
    debugPrint('✅ AIChatService initialization complete');
  }

  /// Create search_offers tool
  Tool _createSearchOffersTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'search_offers',
      description:
          'Search games with filters (offerType, seller, tags, price range, discounts). Returns game titles and IDs.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'query': <String, dynamic>{
            'type': 'string',
            'description': 'Search query for game titles',
          },
          'offerType': <String, dynamic>{
            'type': 'string',
            'description': 'Type: BASE_GAME, DLC, BUNDLE, EDITION, DEMO, etc.',
          },
          'tags': <String, dynamic>{
            'type': 'array',
            'items': <String, dynamic>{'type': 'string'},
            'description': 'Genre/category tags (e.g., ["RPG", "Action"])',
          },
          'onSale': <String, dynamic>{
            'type': 'boolean',
            'description': 'Filter for games currently on sale',
          },
          'priceMin': <String, dynamic>{
            'type': 'integer',
            'description': 'Minimum price in cents (e.g., 1000 for \$10)',
          },
          'priceMax': <String, dynamic>{
            'type': 'integer',
            'description': 'Maximum price in cents (e.g., 2000 for \$20)',
          },
          'limit': <String, dynamic>{
            'type': 'integer',
            'description': 'Max results (default: 10, max: 10)',
          },
        },
      },
      func: (toolInput) async => await _searchOffers(toolInput),
    );
  }

  /// Create get_offer_details tool
  Tool _createGetOfferDetailsTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_offer_details',
      description:
          'Get full details for a single game including description, release date, seller, tags, and requirements.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'offerId': <String, dynamic>{
            'type': 'string',
            'description': 'The offer ID from search results',
          },
        },
        'required': ['offerId'],
      },
      func: (toolInput) async => await _getOfferDetails(toolInput),
    );
  }

  /// Create get_offer_price tool
  Tool _createGetOfferPriceTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_offer_price',
      description:
          'Get current pricing for a single game with original price, discount price, and discount percentage. Can fetch prices for any country.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'offerId': <String, dynamic>{
            'type': 'string',
            'description': 'The offer ID',
          },
          'country': <String, dynamic>{
            'type': 'string',
            'description':
                'Two-letter country code (e.g., "US", "ES", "UK", "DE"). Defaults to user\'s country ($_country) if not specified.',
          },
        },
        'required': ['offerId'],
      },
      func: (toolInput) async => await _getOfferPrice(toolInput),
    );
  }

  /// Create get_free_games tool
  Tool _createGetFreeGamesTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_free_games',
      description:
          'Get currently active free game giveaways from Epic Games Store.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{},
      },
      func: (toolInput) async => await _getFreeGames(),
    );
  }

  /// Create get_top_sellers tool
  Tool _createGetTopSellersTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_top_sellers',
      description:
          'Get best-selling games (returns titles and IDs only, use get_offer_price for pricing).',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'count': <String, dynamic>{
            'type': 'integer',
            'description': 'Number of results (max: 50)',
          },
        },
      },
      func: (toolInput) async => await _getTopSellers(toolInput),
    );
  }

  /// Create get_top_wishlisted tool
  Tool _createGetTopWishlistedTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_top_wishlisted',
      description:
          'Get most-wishlisted games (returns titles and IDs only, use get_offer_price for pricing).',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'count': <String, dynamic>{
            'type': 'integer',
            'description': 'Number of results (max: 50)',
          },
        },
      },
      func: (toolInput) async => await _getTopWishlisted(toolInput),
    );
  }

  /// Create get_upcoming_games tool
  Tool _createGetUpcomingGamesTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_upcoming_games',
      description: 'Get upcoming game releases with release dates.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'limit': <String, dynamic>{
            'type': 'integer',
            'description': 'Number of results per page',
          },
        },
      },
      func: (toolInput) async => await _getUpcomingGames(toolInput),
    );
  }

  /// Create get_latest_releases tool
  Tool _createGetLatestReleasesTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'get_latest_releases',
      description: 'Get recently released games.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'limit': <String, dynamic>{
            'type': 'integer',
            'description': 'Number of results per page',
          },
        },
      },
      func: (toolInput) async => await _getLatestReleases(toolInput),
    );
  }

  /// Create search_sellers tool
  Tool _createSearchSellersTool() {
    return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
      name: 'search_sellers',
      description:
          'Find publishers/developers by name to get seller IDs for filtering.',
      inputJsonSchema: <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'query': <String, dynamic>{
            'type': 'string',
            'description': 'Publisher or developer name to search for',
          },
        },
        'required': ['query'],
      },
      func: (toolInput) async => await _searchSellers(toolInput),
    );
  }

  /// Send a message and get streaming response with tool calling
  Stream<String> sendMessage(String userMessage) async* {
    if (_chatModel == null || _systemMessage == null) {
      initialize();
    }

    try {
      debugPrint('📤 Sending message: $userMessage');

      // Add user message to history
      final userMsg = HumanChatMessage(
        content: ChatMessageContent.text(userMessage),
      );
      _chatHistory.add(userMsg);
      debugPrint('✅ Added user message to history');

      // Build prompt with system message + history
      debugPrint('🔨 Building prompt with ${_chatHistory.length} messages');
      final prompt = PromptValue.chat([_systemMessage!, ..._chatHistory]);
      debugPrint('✅ Prompt built successfully');

      // FIRST REQUEST: Get model response (may include tool calls)
      debugPrint('🚀 Starting stream with ${_tools.length} tools');

      // Create options with tools
      debugPrint('🔧 Creating ChatFirebaseVertexAIOptions...');
      late final ChatFirebaseVertexAIOptions options;
      try {
        options = ChatFirebaseVertexAIOptions(tools: _tools);
        debugPrint('✅ Options created');
      } catch (e) {
        debugPrint('❌ Error creating options: $e');
        debugPrint('❌ Error stack: ${StackTrace.current}');
        rethrow;
      }

      debugPrint('🌊 Calling stream...');
      final stream = _chatModel!.stream(prompt, options: options);
      debugPrint('✅ Stream created');

      bool hasToolCalls = false;
      final toolCallsToExecute = <AIChatMessageToolCall>[];
      final contentBuffer = StringBuffer();

      debugPrint('📥 Starting to process stream chunks...');
      await for (final chunk in stream) {
        debugPrint('📦 Received chunk');
        try {
          final aiMessage = chunk.output;
          debugPrint('✅ Got aiMessage from chunk');

          // Check for tool calls in this chunk
          if (aiMessage.toolCalls.isNotEmpty) {
            hasToolCalls = true;
            debugPrint('🔧 Found ${aiMessage.toolCalls.length} tool calls');

            for (final toolCall in aiMessage.toolCalls) {
              debugPrint('  Tool: ${toolCall.name}');
              // NEW TOOL CALL - yield executing indicator with params
              final paramsJson = _convertToStringMap(toolCall.arguments);
              final paramsEncoded = Uri.encodeComponent(jsonEncode(paramsJson));
              yield '<tool:${toolCall.name}:executing:$paramsEncoded>';
              toolCallsToExecute.add(toolCall);
            }
          }

          // Stream text content if present
          final content = aiMessage.content;
          String? text;
          if (content is ChatMessageContentText) {
            text = (content as ChatMessageContentText).text;
          } else if (content is String) {
            text = content;
          }

          if (text != null && text.isNotEmpty) {
            debugPrint('📝 Text content: ${text.length} chars');
            contentBuffer.write(text);
            yield text;
          } else {
            debugPrint(
              '⚠️  Content type: ${content.runtimeType}, no text to yield',
            );
          }
        } catch (e) {
          debugPrint('Error processing chunk: $e');
          debugPrint('Chunk type: ${chunk.runtimeType}');
          debugPrint('Output type: ${chunk.output.runtimeType}');
          debugPrint('Content type: ${chunk.output.content.runtimeType}');
          rethrow;
        }
      }

      // EXECUTE TOOLS if any were called
      if (hasToolCalls) {
        debugPrint('🛠️  Executing ${toolCallsToExecute.length} tools...');
        // Execute all tools
        for (final toolCall in toolCallsToExecute) {
          try {
            debugPrint('  Executing: ${toolCall.name}');
            final result = await _executeTool(
              toolCall.name,
              _convertToStringMap(toolCall.arguments),
            );

            // Calculate result count (for "Found X games" display)
            final resultCount = _extractResultCount(toolCall.name, result);
            debugPrint(
              '  ✅ Tool ${toolCall.name} completed (count: $resultCount)',
            );

            // Yield completion indicator with params
            final paramsJson = _convertToStringMap(toolCall.arguments);
            final paramsEncoded = Uri.encodeComponent(jsonEncode(paramsJson));
            yield '<tool:${toolCall.name}:complete:$resultCount:$paramsEncoded>';

            // Add tool result to history immediately
            _chatHistory.add(
              ToolChatMessage(
                toolCallId: toolCall.id,
                content: result.toString(),
              ),
            );
          } catch (e) {
            debugPrint('Error executing ${toolCall.name}: $e');

            final paramsJson = _convertToStringMap(toolCall.arguments);
            final paramsEncoded = Uri.encodeComponent(jsonEncode(paramsJson));
            yield '<tool:${toolCall.name}:error:0:$paramsEncoded>';

            // Add error result to history
            _chatHistory.add(
              ToolChatMessage(
                toolCallId: toolCall.id,
                content: 'Error: ${e.toString()}',
              ),
            );
          }
        }

        // Add AI message with tool calls to history BEFORE tool results
        _chatHistory.insert(
          _chatHistory.length - toolCallsToExecute.length,
          AIChatMessage(
            content: contentBuffer.toString(),
            toolCalls: toolCallsToExecute,
          ),
        );

        // SECOND REQUEST: Get final answer after tools executed
        debugPrint('🔄 Making second request for final answer...');
        final finalPrompt = PromptValue.chat([
          _systemMessage!,
          ..._chatHistory,
        ]);

        final finalStream = _chatModel!.stream(finalPrompt);
        debugPrint('🌊 Processing final stream...');

        await for (final chunk in finalStream) {
          debugPrint('📦 Received final chunk');
          final content = chunk.output.content;

          // Handle both ChatMessageContentText and plain String content
          String? text;
          if (content is ChatMessageContentText) {
            text = (content as ChatMessageContentText).text;
          } else if (content is String) {
            text = content;
          }

          if (text != null && text.isNotEmpty) {
            debugPrint('📝 Final text: ${text.length} chars');
            yield text;
          } else {
            debugPrint(
              '⚠️ No text in chunk, content type: ${content.runtimeType}',
            );
          }
        }
        debugPrint('✅ Final stream complete');
      }

      // Add final AI message to history
      if (!hasToolCalls && contentBuffer.isNotEmpty) {
        _chatHistory.add(AIChatMessage(content: contentBuffer.toString()));
      }
    } catch (e) {
      debugPrint('Error in sendMessage: $e');
      yield 'Sorry, I encountered an error: ${e.toString()}';
    }
  }

  /// Convert dynamic map to properly typed Map with String keys and dynamic values
  Map<String, dynamic> _convertToStringMap(dynamic map) {
    if (map == null) return {};
    if (map is Map<String, dynamic>) return map;

    final result = <String, dynamic>{};
    if (map is Map) {
      map.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = _convertToStringMap(value);
        } else if (value is List) {
          result[key.toString()] = value.map((e) {
            if (e is Map) return _convertToStringMap(e);
            return e;
          }).toList();
        } else {
          result[key.toString()] = value;
        }
      });
    }
    return result;
  }

  /// Extract result count from tool response for display
  int _extractResultCount(String toolName, Map<String, dynamic> result) {
    switch (toolName) {
      case 'search_offers':
      case 'get_free_games':
        return (result['count'] as int?) ?? 0;
      case 'get_top_sellers':
      case 'get_top_wishlisted':
      case 'get_upcoming_games':
      case 'get_latest_releases':
        final games = result['games'] as List?;
        return games?.length ?? 0;
      case 'search_sellers':
        final sellers = result['sellers'] as List?;
        return sellers?.length ?? 0;
      default:
        return 0; // get_offer_details, get_offer_price return single item
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
      final country = (args['country'] as String?) ?? _country;
      final priceData = await _apiService.getOfferPrice(
        offerId,
        country: country,
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
    _chatHistory = [];
  }

  /// Dispose resources
  void dispose() {
    _chatHistory = [];
    _chatModel = null;
    _systemMessage = null;
    _tools = [];
  }
}
