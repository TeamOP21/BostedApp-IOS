#!/bin/bash
echo "========================================"
echo "BostedApp iOS Setup"
echo "========================================"
echo ""

echo "Creating directory structure..."
mkdir -p BostedApp/Views/Components
mkdir -p BostedApp/ViewModels
mkdir -p BostedApp/Models
mkdir -p BostedApp/API

echo ""
echo "Copying Swift source files..."
cp ../Swift/Sources/App/BostedApp.swift BostedApp/BostedApp.swift 2>/dev/null
cp ../Swift/Sources/Views/*.swift BostedApp/Views/ 2>/dev/null
cp ../Swift/Sources/Views/Components/*.swift BostedApp/Views/Components/ 2>/dev/null
cp ../Swift/Sources/ViewModels/*.swift BostedApp/ViewModels/ 2>/dev/null
cp ../Swift/Sources/Models/*.swift BostedApp/Models/ 2>/dev/null
cp ../Swift/Sources/API/*.swift BostedApp/API/ 2>/dev/null

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Open BostedApp.xcodeproj in Xcode"
echo "2. Fix the issues listed in README.md"
echo "3. Build and run (Cmd+R)"
echo ""
echo "IMPORTANT: Read README.md for required code fixes!"
echo ""
