#!/bin/bash
# Create upload keystore for BundleSnap (signed release bundle).
# Run from project root: ./android/create_keystore.sh
# Then: flutter build appbundle --release

set -e
cd "$(dirname "$0")"

KEYSTORE="upload-keystore.jks"
ALIAS="upload"

if [ -f "$KEYSTORE" ]; then
  echo "Keystore $KEYSTORE already exists. Remove it first to create a new one."
  exit 1
fi

echo "Creating keystore: $KEYSTORE (alias: $ALIAS)"
keytool -genkey -v -keystore "$KEYSTORE" -keyalg RSA -keysize 2048 -validity 10000 -alias "$ALIAS" \
  -dname "CN=Applooms, OU=BundleSnap, O=Applooms, L=City, S=State, C=US"

if [ ! -f key.properties ]; then
  echo ""
  echo "Creating key.properties. You must set the passwords:"
  echo "  storePassword=<password you entered>"
  echo "  keyPassword=<password you entered>"
  echo ""
  printf "storePassword=REPLACE_WITH_YOUR_STORE_PASSWORD\nkeyPassword=REPLACE_WITH_YOUR_KEY_PASSWORD\nkeyAlias=upload\nstoreFile=../upload-keystore.jks\n" > key.properties
  echo "Edit android/key.properties and replace REPLACE_WITH_* with your keystore passwords."
else
  echo "key.properties already exists. Ensure storeFile=upload-keystore.jks and passwords are correct."
fi

echo ""
echo "Done. Next: flutter build appbundle --release"
