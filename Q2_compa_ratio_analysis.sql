/*
  QUESTION 2: Southeastern Louisiana Lions 2017 (Player Performance vs Benchmark)
  
  Now that we have our benchmarks from Question 1, we want to hold each
  Lions player up against them. The key metric here is the compa ratio.
  
  A compa ratio of 1.0 means a player is scoring at exactly the
  median rate for their position. Below 1.0 means they're underperforming
  their peers. This tells us not just who is struggling, but by how much.
*/


# Step 1: Building the benchmark 

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
  WHERE season IN (2016, 2017)    
    AND tournament IS NULL        
    AND played = TRUE            
    AND minutes_int64 > 0         
  GROUP BY primary_position, player_id, full_name, team_market  
),


# Step 2: Computing the P50 benchmark for each position

benchmarks AS (
  SELECT
    primary_position,
    
    PERCENTILE_CONT(points_per_minute, 0.50)
      OVER (PARTITION BY primary_position) AS benchmark_p50
  FROM player_season_stats

  QUALIFY ROW_NUMBER()
    OVER (PARTITION BY primary_position ORDER BY player_id) = 1
),


# Step 3: Isolating just the Lions players from the 2017 season

lions_2017 AS (
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
    AND team_market = 'Southeastern Louisiana'    
  GROUP BY primary_position, player_id, full_name, team_market
)


# Step 4: Joining each Lions player to their position benchmark and calculating the compa ratio

SELECT
  l.full_name,
  l.primary_position                            AS position,
  l.total_points,
  l.total_minutes,

  ROUND(l.points_per_minute, 4)                 AS points_per_minute,    
  ROUND(b.benchmark_p50, 4)                     AS benchmark_p50,        

  # The compa ratio: player PPM divided by the benchmark PPM
  # 1.0 = exactly at benchmark
  # 0.85 = 15% below benchmark
  # 1.20 = 20% above benchmark

  ROUND(SAFE_DIVIDE(l.points_per_minute, b.benchmark_p50), 4) AS compa_ratio,

  CASE
    WHEN SAFE_DIVIDE(l.points_per_minute, b.benchmark_p50) >= 1.0
      THEN 'At or above benchmark'
    WHEN SAFE_DIVIDE(l.points_per_minute, b.benchmark_p50) >= 0.8
      THEN 'Slightly below benchmark'
    ELSE
      'Significantly below benchmark'
  END AS performance_band

FROM lions_2017 l

LEFT JOIN benchmarks b
  USING (primary_position)

ORDER BY compa_ratio ASC 
