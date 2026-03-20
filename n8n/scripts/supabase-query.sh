#!/bin/bash
# Supabase Query Helper for Radical Concepts
# Usage: ./supabase-query.sh "SELECT * FROM feeds LIMIT 5;"

PROJECT_REF="jqegmsusycnjecqjndgd"

# Extract Supabase access token from macOS Keychain
RAW=$(security find-generic-password -s "Supabase CLI" -a supabase -w 2>/dev/null)
TOKEN=$(echo "$RAW" | sed 's/go-keyring-base64://' | base64 -d)

if [ -z "$TOKEN" ]; then
  echo "Error: No Supabase CLI token found in Keychain."
  echo "Run: supabase login"
  exit 1
fi

# POST the SQL query to Supabase Management API
curl -s -X POST "https://api.supabase.com/v1/projects/${PROJECT_REF}/database/query" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\": \"$1\"}"
