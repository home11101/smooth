#!/bin/bash

# Script to export iOS certificates for GitHub Actions
# Make sure you have your distribution certificate and provisioning profile ready

echo "=== iOS Certificate Export Script ==="
echo "This script will help you export your iOS certificates for GitHub Actions"
echo ""

# Check if Keychain Access is available
if ! command -v security &> /dev/null; then
    echo "Error: security command not found. This script must be run on macOS."
    exit 1
fi

echo "Step 1: Export Distribution Certificate"
echo "----------------------------------------"
echo "1. Open Keychain Access"
echo "2. Find your 'iPhone Distribution' certificate"
echo "3. Right-click and select 'Export'"
echo "4. Choose 'Personal Information Exchange (.p12)' format"
echo "5. Set a password (you'll need this for GitHub secrets)"
echo "6. Save it as 'distribution_certificate.p12' in this directory"
echo ""

read -p "Have you exported the certificate? (y/n): " cert_exported

if [ "$cert_exported" != "y" ]; then
    echo "Please export the certificate first and run this script again."
    exit 1
fi

# Check if certificate file exists
if [ ! -f "distribution_certificate.p12" ]; then
    echo "Error: distribution_certificate.p12 not found in current directory"
    exit 1
fi

echo ""
echo "Step 2: Export Provisioning Profile"
echo "-----------------------------------"
echo "1. Open Xcode"
echo "2. Go to Xcode > Preferences > Accounts"
echo "3. Select your Apple ID and click 'Manage Certificates'"
echo "4. Find your 'Smooth_AI_App_Store-2' provisioning profile"
echo "5. Download it and save as 'Smooth_AI_App_Store-2.mobileprovision' in this directory"
echo ""

read -p "Have you exported the provisioning profile? (y/n): " profile_exported

if [ "$profile_exported" != "y" ]; then
    echo "Please export the provisioning profile first and run this script again."
    exit 1
fi

# Check if provisioning profile file exists
if [ ! -f "Smooth_AI_App_Store-2.mobileprovision" ]; then
    echo "Error: Smooth_AI_App_Store-2.mobileprovision not found in current directory"
    exit 1
fi

echo ""
echo "Step 3: Generate Base64 Encoded Values"
echo "--------------------------------------"

# Generate base64 for certificate
echo "DISTRIBUTION_CERTIFICATE (add this to GitHub secrets):"
echo "========================================================"
base64 -i distribution_certificate.p12
echo ""
echo "========================================================"

# Generate base64 for provisioning profile
echo ""
echo "PROVISIONING_PROFILE (add this to GitHub secrets):"
echo "========================================================"
base64 -i Smooth_AI_App_Store-2.mobileprovision
echo ""
echo "========================================================"

echo ""
echo "Step 4: GitHub Secrets Setup"
echo "----------------------------"
echo "Go to your GitHub repository:"
echo "1. Settings > Secrets and variables > Actions"
echo "2. Add the following secrets:"
echo "   - DISTRIBUTION_CERTIFICATE: (paste the first base64 output above)"
echo "   - PROVISIONING_PROFILE: (paste the second base64 output above)"
echo "   - CERTIFICATE_PASSWORD: (the password you set when exporting the .p12)"
echo "   - APPLE_ID: (your Apple Developer account email)"
echo "   - APP_SPECIFIC_PASSWORD: (generate this in Apple ID settings)"
echo ""

echo "Step 5: Cleanup"
echo "---------------"
echo "After adding the secrets to GitHub, you can safely delete the certificate files:"
echo "- distribution_certificate.p12"
echo "- Smooth_AI_App_Store-2.mobileprovision"
echo ""

echo "Script completed successfully!" 