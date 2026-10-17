---
slug: kb.journey.fixture
last_verified: 2026-10-17
---

# Planted journey steps (GATE 16 self-test, behavior 114) — never compiled into the artifact

## Rules

```jsonc
{
  "layout": {
    "phases": [
      {
        "phase": "fixture",
        "actions": [
          { "id": "no_rule",      "order": 1 },
          { "id": "unsourced",    "order": 2, "rule": [{ "kb": "kb.fixture.unsourced", "source": 0 }] },
          { "id": "out_of_range", "order": 3, "rule": [{ "kb": "kb.fixture.journey-rule", "source": { "NSW": 9 } }] },
          { "id": "not_gov",      "order": 4, "rule": [{ "kb": "kb.fixture.journey-rule", "source": 0 }] },
          { "id": "fine",         "order": 5, "rule": [{ "kb": "kb.fixture.journey-rule", "source": 1 }] },
          { "id": "habit",        "order": 6, "practice": true }
        ]
      }
    ]
  }
}
```
