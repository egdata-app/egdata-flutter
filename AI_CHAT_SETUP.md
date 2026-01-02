# AI Chat Setup Guide

The AI chat feature uses Google's Gemini 2.0 Flash model via LangChain.dart for intelligent game assistance.

## Quick Setup

1. **Get your Gemini API key:**
   - Visit https://aistudio.google.com/app/apikey
   - Click "Create API key"
   - Copy the generated key

2. **Configure the app:**
   - Open the `.env` file in the project root
   - Add your API key:
     ```
     GEMINI_API_KEY=your_api_key_here
     ```
   - Save the file

3. **Run the app:**
   ```bash
   flutter run
   ```

## Features

The AI assistant can help you with:
- **Game Search** - Find games by title, genre, or tags
- **Price Checking** - Get current prices and discounts
- **Free Games** - See active Epic Games Store giveaways
- **Game Details** - Get descriptions, release dates, and requirements
- **Top Games** - Browse best sellers and most wishlisted
- **Upcoming Releases** - See what's coming soon
- **Publisher Search** - Find games by developer or publisher

## Tool Call Indicators

When the AI uses tools to fetch data, you'll see real-time indicators:
- **🔍 Search Offers** - Searching for games
- **💰 Get Pricing** - Fetching price information
- **🎮 Free Games** - Checking free game offers
- **📋 Game Details** - Getting detailed information
- **⭐ Top Sellers / Most Wishlisted** - Finding popular games
- **🗓️ Upcoming Games** - Checking upcoming releases
- **🆕 Latest Releases** - Finding new releases
- **🏢 Search Publishers** - Looking up developers/publishers

Each indicator shows:
- Tool icon and name
- Loading spinner while executing
- Result count when complete (e.g., "✓ Found 5 results")

## Security Notes

- ⚠️ **Never commit your API key to version control**
- The `.env` file is already in `.gitignore`
- See `.env.example` for the template
- For production, consider using Firebase Remote Config or encrypted storage

## Troubleshooting

### "GEMINI_API_KEY not configured" error
- Make sure you created a `.env` file (not just `.env.example`)
- Verify the API key is on the line `GEMINI_API_KEY=your_key`
- Restart the app after adding the key

### API quota exceeded
- Free tier has usage limits
- Check your quota at https://aistudio.google.com/app/apikey
- Consider upgrading for higher limits

### Chat not working
- Check your internet connection
- Verify the API key is valid
- Check console logs for detailed error messages
