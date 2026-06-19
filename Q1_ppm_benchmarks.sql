/*
  QUESTION 1: Points Per Minute Benchmark by Position
  
  The goal here is to build a benchmark that tells us how efficiently
  players at each position score, relative to the time they spend on
  the court. We're using two seasons (2016 & 2017) to make the
  benchmarks as statistically reliable as possible.
*/


# Step 1: Getting each player's season totals

WITH player_season_stats AS (
  SELECT
    primary_position,
    player_id,
    full_name,
    SUM(points)        AS total_points,   
    SUM(minutes_int64) AS total_minutes   
  FROM `bigquery-public-data.ncaa_basketball.mbb_players_games_sr`
  WHERE season IN (2016, 2017)    
    AND tournament IS NULL        
    AND played = TRUE             
    AND minutes_int64 > 0         
  GROUP BY primary_position, player_id, full_name  
),


# Step 2: Calculating each player's scoring efficiency

ppm_calc AS (
  SELECT
    primary_position,
    player_id,
    total_points,
    total_minutes,
    SAFE_DIVIDE(total_points, total_minutes) AS points_per_minute
  FROM player_season_stats
),


# Step 3: Computing the percentile distribution for each position

percentiles AS (
  SELECT
    primary_position,
    player_id,

    
    ROUND(PERCENTILE_CONT(points_per_minute, 0.25)
      OVER (PARTITION BY primary_position), 4) AS ppm_p25,

    
    ROUND(PERCENTILE_CONT(points_per_minute, 0.50)
      OVER (PARTITION BY primary_position), 4) AS ppm_p50,

    ROUND(PERCENTILE_CONT(points_per_minute, 0.75)
      OVER (PARTITION BY primary_position), 4) AS ppm_p75

  FROM ppm_calc
)


# Step 4: Collapsing down to one clean row per position

SELECT
  primary_position                  AS position,
  COUNT(DISTINCT player_id)         AS total_players,  
  ANY_VALUE(ppm_p25)                AS ppm_p25,        
  ANY_VALUE(ppm_p50)                AS ppm_p50,        
  ANY_VALUE(ppm_p75)                AS ppm_p75         
FROM percentiles
GROUP BY primary_position
ORDER BY ppm_p50 DESC  
