import 'dart:async';
import 'dart:convert';
import 'package:langchain/langchain.dart';
import 'package:langchain_firebase/langchain_firebase.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'ai_tools/search_offers_tool.dart';
import 'ai_tools/get_offer_details_tool.dart';
import 'ai_tools/get_offer_price_tool.dart';
import 'ai_tools/get_free_games_tool.dart';
import 'ai_tools/get_top_sellers_tool.dart';
import 'ai_tools/get_top_wishlisted_tool.dart';
import 'ai_tools/get_upcoming_games_tool.dart';
import 'ai_tools/get_latest_releases_tool.dart';
import 'ai_tools/search_sellers_tool.dart';
import 'ai_tools/get_tags_tool.dart';

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
        model: 'gemini-2.5-flash',
        temperature: 0.5,
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
        '• Specific offer details (get_offer_details)\n'
        '• **IMPORTANT**: When user asks about specific genres/themes/features (e.g., "steampunk", "roguelike", "split-screen"), ALWAYS use get_tags FIRST to find the correct tag name, then search with that tag\n\n'
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
        '- **get_tags**: Get all available tags/labels (genres, features, events). **Use this FIRST** when user mentions specific genres/themes/features to find the exact tag ID. Returns tags grouped by category with popularity counts. Supports searchTerm parameter for finding tags (e.g., searchTerm: "city" finds "City Builder" tag). Each tag has "id" and "name" fields.\n'
        '- **search_offers**: Find games with filters (offerType, tags, onSale, price range, seller). Uses user\'s country ($_country) for pricing. **CRITICAL**: Use tag IDs (the "id" field from get_tags), NOT tag names. Example: tags: [9204] for City Builder.\n'
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
        '1. **Tag Workflow Example**:\n'
        '   User: "City builder games on sale?"\n'
        '   Step 1: get_tags(searchTerm: "city builder") → returns [{id: 9204, name: "City Builder", ...}]\n'
        '   Step 2: search_offers(tags: [9204], onSale: true)\n'
        '   CRITICAL: Extract the numeric "id" field from get_tags, pass it as a number in the tags array.\n'
        '2. For riddles/recommendations: Use knowledge first, optionally search to verify availability\n'
        '3. For prices: Use get_offer_price with appropriate country code (default to "$_country" if not specified)\n'
        '4. Show 5-7 results unless asked for more\n'
        '5. Keep responses focused and scannable';

    _systemMessage = SystemChatMessage(content: systemInstructionText);
    debugPrint('✅ System message created');

    debugPrint('🔨 Creating tools...');
    try {
      debugPrint('  Creating search_offers tool...');
      final tool1 = createSearchOffersTool(_apiService, _country);
      debugPrint('  ✅ search_offers created');

      debugPrint('  Creating get_offer_details tool...');
      final tool2 = createGetOfferDetailsTool(_apiService);
      debugPrint('  ✅ get_offer_details created');

      debugPrint('  Creating get_offer_price tool...');
      final tool3 = createGetOfferPriceTool(_apiService, _country);
      debugPrint('  ✅ get_offer_price created');

      debugPrint('  Creating get_free_games tool...');
      final tool4 = createGetFreeGamesTool(_apiService);
      debugPrint('  ✅ get_free_games created');

      debugPrint('  Creating get_top_sellers tool...');
      final tool5 = createGetTopSellersTool(_apiService, _country);
      debugPrint('  ✅ get_top_sellers created');

      debugPrint('  Creating get_top_wishlisted tool...');
      final tool6 = createGetTopWishlistedTool(_apiService, _country);
      debugPrint('  ✅ get_top_wishlisted created');

      debugPrint('  Creating get_upcoming_games tool...');
      final tool7 = createGetUpcomingGamesTool(_apiService, _country);
      debugPrint('  ✅ get_upcoming_games created');

      debugPrint('  Creating get_latest_releases tool...');
      final tool8 = createGetLatestReleasesTool(_apiService, _country);
      debugPrint('  ✅ get_latest_releases created');

      debugPrint('  Creating search_sellers tool...');
      final tool9 = createSearchSellersTool(_apiService, _country);
      debugPrint('  ✅ search_sellers created');

      debugPrint('  Creating get_tags tool...');
      final tool10 = createGetTagsTool(_apiService);
      debugPrint('  ✅ get_tags created');

      _tools = [tool1, tool2, tool3, tool4, tool5, tool6, tool7, tool8, tool9, tool10];
      debugPrint('✅ All tools created and added to list');
    } catch (e) {
      debugPrint('❌ Error creating tools: $e');
      rethrow;
    }

    _chatHistory = [];
    debugPrint('✅ AIChatService initialization complete');
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

      // Create options with tools
      final options = ChatFirebaseVertexAIOptions(tools: _tools);

      // Agentic loop - keep calling until we get a final answer
      int loopCount = 0;
      const maxLoops = 5; // Prevent infinite loops

      while (loopCount < maxLoops) {
        loopCount++;
        debugPrint('🔄 Agentic loop iteration $loopCount');

        // Build prompt with current history
        final prompt = PromptValue.chat([_systemMessage!, ..._chatHistory]);

        debugPrint('🌊 Calling stream with ${_tools.length} tools...');
        final stream = _chatModel!.stream(prompt, options: options);

        bool hasToolCalls = false;
        final toolCallsToExecute = <AIChatMessageToolCall>[];
        final contentBuffer = StringBuffer();

        // Process stream chunks
        await for (final chunk in stream) {
          final aiMessage = chunk.output;

          // Check for tool calls
          if (aiMessage.toolCalls.isNotEmpty) {
            hasToolCalls = true;
            debugPrint('🔧 Found ${aiMessage.toolCalls.length} tool calls');

            for (final toolCall in aiMessage.toolCalls) {
              debugPrint('  Tool: ${toolCall.name}');
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
          }
        }

        // If tools were called, execute them and continue loop
        if (hasToolCalls) {
          debugPrint('🛠️  Executing ${toolCallsToExecute.length} tools...');

          // Add AI message with tool calls to history
          _chatHistory.add(
            AIChatMessage(
              content: contentBuffer.toString(),
              toolCalls: toolCallsToExecute,
            ),
          );

          // Execute all tools
          for (final toolCall in toolCallsToExecute) {
            try {
              debugPrint('  Executing: ${toolCall.name}');
              final result = await _executeTool(
                toolCall.name,
                _convertToStringMap(toolCall.arguments),
              );

              final resultCount = _extractResultCount(toolCall.name, result);
              debugPrint(
                '  ✅ Tool ${toolCall.name} completed (count: $resultCount)',
              );

              // Yield completion indicator
              final paramsJson = _convertToStringMap(toolCall.arguments);
              final paramsEncoded = Uri.encodeComponent(jsonEncode(paramsJson));
              yield '<tool:${toolCall.name}:complete:$resultCount:$paramsEncoded>';

              // Add tool result to history
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

              _chatHistory.add(
                ToolChatMessage(
                  toolCallId: toolCall.id,
                  content: 'Error: ${e.toString()}',
                ),
              );
            }
          }

          // Continue loop to get next response
          continue;
        }

        // No tool calls - we have final answer, break loop
        if (contentBuffer.isNotEmpty) {
          _chatHistory.add(AIChatMessage(content: contentBuffer.toString()));
        }
        debugPrint('✅ Final answer received, ending loop');
        break;
      }

      if (loopCount >= maxLoops) {
        debugPrint('⚠️  Max loops reached, ending conversation');
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
      case 'get_tags':
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
        return await searchOffers(_apiService, _country, args);
      case 'get_offer_details':
        return await getOfferDetails(_apiService, args);
      case 'get_offer_price':
        return await getOfferPrice(_apiService, _country, args);
      case 'get_free_games':
        return await getFreeGames(_apiService);
      case 'get_top_sellers':
        return await getTopSellers(_apiService, _country, args);
      case 'get_top_wishlisted':
        return await getTopWishlisted(_apiService, _country, args);
      case 'get_upcoming_games':
        return await getUpcomingGames(_apiService, _country, args);
      case 'get_latest_releases':
        return await getLatestReleases(_apiService, _country, args);
      case 'search_sellers':
        return await searchSellers(_apiService, _country, args);
      case 'get_tags':
        return await getTags(_apiService, args);
      default:
        return {'error': 'Unknown tool: $toolName'};
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
