{\rtf1\ansi\ansicpg1252\cocoartf2870
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;\f1\fnil\fcharset0 LucidaGrande;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 -- first lets just take a look at the data\
SELECT * FROM flights LIMIT 10;\
\
-- how many rows do we have?\
SELECT COUNT(*) FROM flights;\
\
-- checking for any missing values before i start\
SELECT \
  COUNT(*) - COUNT(Airline) AS missing_airline,\
  COUNT(*) - COUNT(AirportFrom) AS missing_from,\
  COUNT(*) - COUNT(AirportTo) AS missing_to,\
  COUNT(*) - COUNT(Class) AS missing_class\
FROM flights;\
\
-- looks clean, no nulls - good to go\
\
\
-- ============================================================\
-- Flight Delay Analysis\
-- Author: Akshar Mehta\
-- Dataset: US Airline Delay Data (~539k flights, 18 airlines)\
-- Goal: Find patterns in flight delays to help travelers\
--       make smarter booking decisions\
-- ============================================================\
\
\
-- ------------------------------------------------------------\
-- Q1: which airlines have the worst delay rates?\
-- i want to see total flights, delayed flights, and the rate\
-- ------------------------------------------------------------\
SELECT \
  Airline,\
  COUNT(*) AS total_flights,\
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS total_delayed,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
GROUP BY Airline\
ORDER BY delay_rate_pct DESC;\
\
-- WN (Southwest) at 69.8% is shockingly high - way above everyone else\
-- YV (Mesa Airlines) at 24.3% is the best - interesting, smaller carrier\
-- going to keep this in mind when i look at airports later\
\
\
-- ------------------------------------------------------------\
-- Q2: does the day of the week matter?\
-- adding labels so its easier to read\
-- ------------------------------------------------------------\
SELECT \
  CASE DayOfWeek\
    WHEN 1 THEN 'Monday'\
    WHEN 2 THEN 'Tuesday'\
    WHEN 3 THEN 'Wednesday'\
    WHEN 4 THEN 'Thursday'\
    WHEN 5 THEN 'Friday'\
    WHEN 6 THEN 'Saturday'\
    WHEN 7 THEN 'Sunday'\
  END AS day_name,\
  COUNT(*) AS total_flights,\
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS total_delayed,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
GROUP BY DayOfWeek\
ORDER BY DayOfWeek;\
\
-- Monday is the worst day - makes sense, lots of business travel\
-- and weekend maintenance delays probably carry over\
-- saturday looks pretty good which is useful to know\
\
\
-- ------------------------------------------------------------\
-- Q3: what are the busiest routes?\
-- concatenating from and to airports to make it readable\
-- ------------------------------------------------------------\
SELECT \
  AirportFrom || ' 
\f1 \uc0\u8594 
\f0  ' || AirportTo AS route,\
  COUNT(*) AS total_flights,\
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS total_delayed,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
GROUP BY AirportFrom, AirportTo\
ORDER BY total_flights DESC\
LIMIT 10;\
\
-- LAX-SFO and SFO-LAX are by far the busiest, makes total sense\
-- OGG-HNL is interesting - that's the hawaii island hopper route\
-- high volume doesnt always mean high delays though\
\
\
-- ------------------------------------------------------------\
-- Q4: which airports have the worst delays?\
-- filtering to airports with over 1000 flights so small airports\
-- dont skew the results\
-- ------------------------------------------------------------\
SELECT \
  AirportFrom AS airport,\
  COUNT(*) AS total_flights,\
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS total_delayed,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
GROUP BY AirportFrom\
HAVING total_flights > 1000\
ORDER BY delay_rate_pct DESC\
LIMIT 10;\
\
-- MDW (Chicago Midway) is #1 worst - this actually makes sense now\
-- Southwest uses Midway as a major hub and they had a 69.8% delay rate\
-- so the airport delay rate is probably being dragged up by Southwest\
-- would be interesting to check MDW without Southwest flights someday\
\
\
-- ------------------------------------------------------------\
-- Q5: do longer flights get delayed more than shorter ones?\
-- bucketing flight lengths into categories\
-- ------------------------------------------------------------\
SELECT \
  CASE \
    WHEN Length < 60 THEN '1. Short (under 1hr)'\
    WHEN Length BETWEEN 60 AND 180 THEN '2. Medium (1-3hrs)'\
    WHEN Length BETWEEN 180 AND 360 THEN '3. Long (3-6hrs)'\
    ELSE '4. Very Long (6hr+)'\
  END AS flight_category,\
  COUNT(*) AS total_flights,\
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS total_delayed,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
GROUP BY flight_category\
ORDER BY flight_category;\
\
-- longer flights are delayed more - i actually expected the opposite\
-- thought short flights would have more delays due to quick turnarounds\
-- maybe longer routes have more variables - weather, air traffic etc\
\
\
-- ------------------------------------------------------------\
-- Q6: best and worst time of day to fly?\
-- Time column appears to be in minutes from midnight\
-- ------------------------------------------------------------\
\
-- quick check on the Time column range first\
SELECT MIN(Time), MAX(Time) FROM flights;\
\
-- ok confirmed, it goes from 0 to 1439 (minutes in a day)\
SELECT \
  CASE \
    WHEN Time < 360 THEN '1. Early Morning (12am-6am)'\
    WHEN Time BETWEEN 360 AND 719 THEN '2. Morning (6am-12pm)'\
    WHEN Time BETWEEN 720 AND 1079 THEN '3. Afternoon (12pm-6pm)'\
    ELSE '4. Evening (6pm-12am)'\
  END AS time_of_day,\
  COUNT(*) AS total_flights,\
  SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS total_delayed,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
GROUP BY time_of_day\
ORDER BY time_of_day;\
\
-- evening flights are actually the best which is surprising\
-- early morning is worst - probably overnight maintenance issues\
-- cascading into the first flights of the day\
-- practical takeaway: book evening flights if you can\
\
\
-- ------------------------------------------------------------\
-- Q7: on the busiest routes, which airline should you pick?\
-- focusing on LAX-SFO, SFO-LAX, and OGG-HNL\
-- only including airlines with over 50 flights on that route\
-- so we have a decent sample size\
-- ------------------------------------------------------------\
SELECT \
  AirportFrom || ' 
\f1 \uc0\u8594 
\f0  ' || AirportTo AS route,\
  Airline,\
  COUNT(*) AS total_flights,\
  ROUND(SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS delay_rate_pct\
FROM flights\
WHERE (AirportFrom = 'LAX' AND AirportTo = 'SFO')\
   OR (AirportFrom = 'SFO' AND AirportTo = 'LAX')\
   OR (AirportFrom = 'OGG' AND AirportTo = 'HNL')\
GROUP BY route, Airline\
HAVING total_flights > 50\
ORDER BY route, delay_rate_pct ASC;\
\
-- AA (American) has the best delay rate on LAX-SFO\
-- good practical finding - if youre flying that route pick AA\
-- will visualize this in tableau as a route comparison chart\
\
\
-- ------------------------------------------------------------\
-- summary of key findings:\
-- 1. Southwest (WN) has nearly 70% delay rate - avoid if possible\
-- 2. Monday is worst day to fly, Saturday is better\
-- 3. LAX-SFO is busiest route in the dataset\
-- 4. MDW (Chicago Midway) is most delayed airport - Southwest hub connection\
-- 5. Longer flights get delayed more than shorter ones\
-- 6. Evening flights are least delayed, early morning worst\
-- 7. On LAX-SFO route, AA is your best bet\
-- next step: build tableau dashboard to visualize all of this\
-- ------------------------------------------------------------}