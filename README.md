# NCAA Scoring Analysis — SE Louisiana Lions

## Overview
End-to-end analytical project benchmarking player scoring efficiency across the 2016/17 NCAA regular season, identifying underperforming players using a compa ratio framework, and surfacing data-driven recruitment targets.

Built using BigQuery SQL, visualised in Looker Studio.

## Business Context
The SE Louisiana Lions scored the lowest points in the 2017 NCAA season. This analysis benchmarks each player's scoring efficiency against NCAA peers and identifies recruitment targets that could improve team performance.

## Analytical Approach
The methodology mirrors compensation analytics:
- Build a benchmark (PPM percentiles by position)
- Review who falls below it (compa ratio analysis)
- Identify where to recruit to close the gap (P75 targets)

## Questions Answered

### Q1 — Points Per Minute Benchmark
Built a PPM benchmark (total points ÷ total minutes) for each position across 2016 & 2017 regular season data. Computed P25, P50 and P75 percentiles across 13,374 players.

### Q2 — Squad Compa Ratio Analysis
Reviewed all 11 SE Louisiana Lions players against the P50 benchmark using a compa ratio (player PPM ÷ benchmark P50).
Mapped findings to pay compensation implications:
- Above 1.0 = high performer, retention priority
- 0.80–0.99 = slightly below, development plan
- Below 0.80 = significantly underperforming, urgent review

### Q3 — Recruitment Target Identification
Identified external players who:
- Play positions where Lions underperform P75
- Score at or above P75 benchmark
- Have played minimum 200 minutes (statistical credibility)

## Tech Stack
- **SQL** — BigQuery (Google Cloud)
- **BI & Visualisation** — Looker Studio
- **Dataset** — bigquery-public-data.ncaa_basketball.mbb_players_games_sr

## Key SQL Concepts Used
- CTEs (Common Table Expressions)
- Window functions (PERCENTILE_CONT, ROW_NUMBER)
- QUALIFY clause (BigQuery-specific)
- SAFE_DIVIDE for defensive coding
- CASE statements for performance banding
