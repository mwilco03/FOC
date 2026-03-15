# Hints System

This directory contains hint files for each hop in JSON format.

## Structure

Each hop has a JSON file with three tiers of hints:

1. **Nudge** (10% cost) - General direction
2. **Guide** (25% cost) - Specific technique
3. **Walkthrough** (50% cost) - Step-by-step commands (minus flag location)

## Format

```json
{
  "hop": 1,
  "container": "GATE",
  "hints": [
    {
      "tier": "nudge",
      "cost_percent": 10,
      "text": "General hint text..."
    },
    {
      "tier": "guide",
      "cost_percent": 25,
      "text": "More specific hint..."
    },
    {
      "tier": "walkthrough",
      "cost_percent": 50,
      "text": "Step-by-step walkthrough..."
    }
  ]
}
```

## Sequential Gating

Hints for Hop N are only available after Hop N-1 flag is submitted.
Exception: Hop 1 hints are always available.
