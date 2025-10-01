#!/bin/bash

echo "🚀 Setting up iOS dependencies for Stela Network..."

# Navigate to iOS directory
cd ios

echo "📦 Installing CocoaPods dependencies..."
pod install

echo "✅ iOS setup complete!"
echo "📱 You can now build the iOS app with:"
echo "   flutter build ios --debug"
echo "   flutter build ios --release"
