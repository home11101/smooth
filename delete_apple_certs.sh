#!/bin/bash

echo "Suppression des certificats Apple Development..."
security find-certificate -c "Apple Development" -a -Z | grep SHA-1 | awk '{print $3}' | while read sha; do
    echo "Suppression certificat Apple Development SHA1: $sha"
    security delete-certificate -Z $sha
done

echo "Suppression des certificats Apple Distribution..."
security find-certificate -c "Apple Distribution" -a -Z | grep SHA-1 | awk '{print $3}' | while read sha; do
    echo "Suppression certificat Apple Distribution SHA1: $sha"
    security delete-certificate -Z $sha
done

echo "Vérification des identités restantes :"
security find-identity -v -p codesigning
