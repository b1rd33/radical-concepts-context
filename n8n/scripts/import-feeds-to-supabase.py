#!/usr/bin/env python3
"""
Import RSS feeds from JSON into Supabase feeds table.

Reads from n8n/context/rss-feeds-full.json (if it exists) or rss-feeds-mvp.json,
connects to Supabase using env vars, and inserts all feeds with round-robin
batch_number assignment (0-23).

Usage:
    pip install -r requirements.txt
    cp .env.example .env  # fill in SUPABASE_URL and SUPABASE_KEY
    python import-feeds-to-supabase.py

Environment variables (from .env at repo root):
    SUPABASE_URL  — Project URL (https://xxxxx.supabase.co)
    SUPABASE_KEY  — service_role key (bypasses RLS)
"""

import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client, Client


# Resolve paths relative to repo root
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent
CONTEXT_DIR = REPO_ROOT / "n8n" / "context"

FEEDS_FULL = CONTEXT_DIR / "rss-feeds-full.json"
FEEDS_MVP = CONTEXT_DIR / "rss-feeds-mvp.json"

NUM_BATCHES = 24  # one batch per hour


def load_feeds() -> list[dict]:
    """Load feeds JSON, preferring full over MVP."""
    feeds_path = FEEDS_FULL if FEEDS_FULL.exists() else FEEDS_MVP

    if not feeds_path.exists():
        print(f"ERROR: No feeds file found. Expected one of:")
        print(f"  {FEEDS_FULL}")
        print(f"  {FEEDS_MVP}")
        sys.exit(1)

    print(f"Reading feeds from: {feeds_path.name}")
    with open(feeds_path) as f:
        return json.load(f)


def build_rows(feeds: list[dict]) -> list[dict]:
    """Convert feed entries to Supabase row format with round-robin batch assignment."""
    rows = []
    for i, feed in enumerate(feeds):
        rows.append({
            "url": feed["url"],
            "name": feed["name"],
            "category": feed.get("category", "general"),
            "batch_number": i % NUM_BATCHES,
            "is_active": True,
        })
    return rows


def main():
    # Load .env from repo root
    env_path = REPO_ROOT / ".env"
    if env_path.exists():
        load_dotenv(env_path)
    else:
        print(f"WARNING: No .env found at {env_path}")

    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_KEY")

    if not url or not key:
        print("ERROR: Missing environment variables.")
        print("Set SUPABASE_URL and SUPABASE_KEY in .env or your environment.")
        print()
        print("  SUPABASE_URL=https://xxxxx.supabase.co")
        print("  SUPABASE_KEY=eyJ...  (service_role key)")
        sys.exit(1)

    # Load and prepare feeds
    feeds = load_feeds()
    rows = build_rows(feeds)

    print(f"Loaded {len(rows)} feeds across {NUM_BATCHES} batches")
    print(f"  Batch sizes: {len(rows) // NUM_BATCHES} per batch"
          f" (+1 for first {len(rows) % NUM_BATCHES} batches)" if len(rows) % NUM_BATCHES else "")

    # Connect to Supabase
    print(f"\nConnecting to Supabase: {url}")
    supabase: Client = create_client(url, key)

    # Insert in batches to avoid payload limits
    BATCH_SIZE = 50
    inserted = 0
    skipped = 0
    errors = 0

    for start in range(0, len(rows), BATCH_SIZE):
        chunk = rows[start : start + BATCH_SIZE]
        try:
            # upsert on url to avoid duplicates on re-run
            result = supabase.table("feeds").upsert(
                chunk,
                on_conflict="url",
            ).execute()
            inserted += len(result.data)
        except Exception as e:
            error_msg = str(e)
            if "duplicate" in error_msg.lower():
                skipped += len(chunk)
                print(f"  Skipped {len(chunk)} duplicate feeds")
            else:
                errors += len(chunk)
                print(f"  ERROR inserting batch: {error_msg}")

    # Summary
    print(f"\n{'='*50}")
    print(f"Import complete!")
    print(f"  Inserted/updated: {inserted}")
    if skipped:
        print(f"  Skipped (duplicates): {skipped}")
    if errors:
        print(f"  Errors: {errors}")
    print(f"  Total feeds in file: {len(rows)}")
    print(f"{'='*50}")

    # Verify count in database
    try:
        count_result = supabase.table("feeds").select("id", count="exact").execute()
        print(f"\nTotal feeds now in database: {count_result.count}")
    except Exception:
        pass  # non-critical


if __name__ == "__main__":
    main()
