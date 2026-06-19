/*
  QUESTION 3: Recruitment Targets for the Southeastern Louisiana Lions
  
  Based on Question 2, we know which positions the Lions are weakest at,
  this query goes out into the wider NCAA pool and finds players
  who could genuinely upgrade those positions.
*/


# Step 1: Getting every player's season stats and scoring rate for 2017

WITH player_season_stats AS (
  SELECT
    primary_position,
    player_id,
    full_name,
    team_market,
    SUM(points)        AS total_points,
    SUM(minutes_int64) AS total_minutes,
    SAFE_DIVIDE(SUM(points), SUM(minutes_int64)) AS points_per_minute  
  FROM `bigquery-public-data.ncaa_basketball.mbb_players_games_sr`
  WHERE season = 2017          
    AND tournament IS NULL    
    AND played = TRUE          
    AND minutes_int64 > 0      
  GROUP BY primary_position, player_id, full_name, team_market 
),


# Step 2: Setting the recruitment bar at 75th percentile for each position

benchmarks AS (
  SELECT
    primary_position,
  
    PERCENTILE_CONT(points_per_minute, 0.75)
      OVER (PARTITION BY primary_position) AS benchmark_p75
  FROM player_season_stats

  QUALIFY ROW_NUMBER()
    OVER (PARTITION BY primary_position ORDER BY player_id) = 1
),


# Step 3: Identifying which positions the Lions actually need help at

lions_weak_positions AS (
  SELECT DISTINCT primary_position
  FROM (
    SELECT
      l.primary_position,

      SAFE_DIVIDE(
        SAFE_DIVIDE(SUM(l.total_points), SUM(l.total_minutes)),
        b.benchmark_p75
      ) AS compa_ratio

    FROM player_season_stats l
    JOIN benchmarks b
      USING (primary_position)
    WHERE l.team_market = 'Southeastern Louisiana' 
    GROUP BY l.primary_position, b.benchmark_p75
    HAVING compa_ratio < 1.0
  )
)


# Step 4: Finding external players who meet the 75th percentile bar

SELECT
  p.full_name,
  p.primary_position                              AS position,
  p.team_market                                   AS current_team,      
  ROUND(p.points_per_minute, 4)                   AS points_per_minute, 
  ROUND(b.benchmark_p75, 4)                       AS benchmark_p75,     

  ROUND(SAFE_DIVIDE(p.points_per_minute, b.benchmark_p75), 4) AS compa_ratio,

  p.total_minutes  AS season_minutes  

FROM player_season_stats p
JOIN benchmarks b
  USING (primary_position)


JOIN lions_weak_positions lw
  USING (primary_position)

WHERE p.team_market != 'Southeastern Louisiana'  
  AND p.points_per_minute >= b.benchmark_p75     
  AND p.total_minutes >= 200                     

ORDER BY p.primary_position, compa_ratio DESC

LIMIT 30 
