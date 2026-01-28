#!/bin/bash

# Railway Environment Variables Setup Script
# Run this after: railway init

echo "Setting up Railway environment variables..."

railway variables set TELEGRAM_BOT_TOKEN="8456270009:AAF-55STf9EofZVIewNYTrIRf6jYXhsuP9Y"
railway variables set TELEGRAM_BOT_USERNAME="ClawdBumpbot"
railway variables set FARBUMP_API_URL="https://farbump.vercel.app"
railway variables set FARBUMP_WEB_URL="https://farbump.vercel.app"
railway variables set NODE_ENV="production"
railway variables set PORT="18789"

echo ""
echo "⚠️  IMPORTANT: Set your Gemini API key manually!"
echo ""
echo "Run this command with YOUR actual API key:"
echo ""
echo "railway variables set GOOGLE_GENERATIVE_AI_API_KEY=\"your_gemini_key_here\""
echo ""
echo "Get free API key at: https://aistudio.google.com/apikey"
echo ""
echo "Other options:"
echo "  Anthropic: railway variables set ANTHROPIC_API_KEY=\"your_key\""
echo "  OpenAI: railway variables set OPENAI_API_KEY=\"sk-your_key\""
echo ""

# Verify
echo "Current variables:"
railway variables
