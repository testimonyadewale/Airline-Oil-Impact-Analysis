--Q1: Total Revenue, Fuel Cost and Average Profit Margin
SELECT
      SUM(revenue_usd_m) AS total_revenue_usd_m,
      SUM(fuel_cost_usd_m) AS total_fuel_cost_usd_m,
      AVG(profit_margin_pct) AS avg_profit_margin_pct
FROM
    [dbo].[airline_financial_impact$]

--Q2: Average Jet Fuel Price by Conflict Phase
SELECT
      conflict_phase,
      ROUND(AVG(jet_fuel_usd_barrel),2) AS avg_jet_fuel_usd_barrel
FROM
    [dbo].[oil_jet_fuel_prices$]
GROUP BY
        conflict_phase
ORDER BY
        AVG(jet_fuel_usd_barrel) DESC

--Q3: Airline with Highest Fuel Cost % of Revenue in Each Quarter
SELECT 
      TOP 10
      airline,
      conflict_phase,
      quarter,
      MAX(fuel_cost_pct_revenue) AS max_fuel_cost_pct_revenue
FROM
    [dbo].[airline_financial_impact$]
GROUP BY
        airline,
        conflict_phase,
        quarter
ORDER BY
        MAX(fuel_cost_pct_revenue) DESC

--Q4: Average Ticket Fare by Route Class & Conflict Phase
SELECT
      route_class,
      conflict_phase,
      ROUND(AVG(total_fare_usd),2) AS avg_total_fare_usd
FROM 
    [dbo].[airline_ticket_prices$]
GROUP BY
        route_class,
        conflict_phase
ORDER BY
        route_class,
        conflict_phase,
        AVG(total_fare_usd) DESC

--Q5: Cancellations & Closures by Event Type
SELECT
      event_type,
      SUM(flight_cancellations_est) AS total_flight_cancellations_est,
      SUM(airspace_closures_countries) AS total_airspace_closures_countries
FROM
    [dbo].[conflict_oil_events$]
GROUP BY
        event_type
ORDER BY
        total_flight_cancellations_est DESC,
        total_airspace_closures_countries DESC

--Q6: Airlines with Highest Fuel Hedging & Savings
SELECT
      airline,
      conflict_phase,
      fuel_hedging_pct,
      hedge_savings_usd_m
FROM
    [dbo].[airline_financial_impact$]
WHERE
      fuel_hedging_pct IS NOT NULL
GROUP BY
        airline,
        conflict_phase,
        fuel_hedging_pct,
        hedge_savings_usd_m
HAVING
        hedge_savings_usd_m > 0

--Q7: Average Fuel Surcharge by Distance Band Over Time
SELECT
      
      km_range,
      conflict_phase,
      ROUND(AVG(fuel_surcharge_usd),2) AS avg_fuel_surcharge_usd
FROM
    [dbo].[fuel_surcharges$]
GROUP BY
        km_range,
        conflict_phase
ORDER BY
        AVG(fuel_surcharge_usd) DESC,
        km_range,
        conflict_phase

--Q8: Calculate Rerouted Routes, Average Extra Distance & Cost
SELECT
      origin_city,
      destination_city,
      airline,
      extra_distance_km,
      extra_fuel_cost_usd,
      COUNT(*) AS rerouted_flights_count,
      AVG(extra_distance_km) AS avg_extra_distance_km,
      AVG(extra_fuel_cost_usd) AS avg_extra_fuel_cost_usd
FROM 
    [dbo].[route_cost_impact$]
WHERE
      rerouted = 'Yes'
GROUP BY
        origin_city,
        destination_city,
        airline,
        extra_distance_km,
        extra_fuel_cost_usd
ORDER BY
        extra_fuel_cost_usd DESC,
        extra_distance_km DESC

--Q9: Calculate Revenue vs Fuel Cost per Airline
SELECT
     airline,
     SUM(revenue_usd_m) AS total_route_revenue_usd,
     SUM(fuel_cost_usd_m) AS total_fuel_cost_usd,
     (SUM(revenue_usd_m) - SUM(fuel_cost_usd_m)) AS profit_after_fuel_usd
FROM 
    [dbo].[airline_financial_impact$]
GROUP BY
        airline,
        revenue_usd_m,
        fuel_cost_usd_m
ORDER BY
        total_route_revenue_usd DESC,
        total_fuel_cost_usd DESC

--Q10: How did Brent crude oil prices correlate with average total ticket fares month by month?
SELECT
      o.month,
      ROUND(AVG(t.total_fare_usd),2) AS avg_ticket_fare,
      ROUND(AVG(o.brent_crude_usd_barrel),2) AS avg_brent_oil
FROM
    [dbo].[airline_ticket_prices$] t
JOIN
    [dbo].[oil_jet_fuel_prices$] o ON o.month = t.month
GROUP BY
        o.month
ORDER BY
        o.month

--Q11: Which conflict events caused the largest percentage increase in oil prices,
--and what was the corresponding airfare impact?
SELECT
      TOP 10
      event_type,
      event_description,
      severity,
      location,
      conflict_phase,
      oil_price_change_pct,
      airfare_impact_pct
FROM
    [dbo].[conflict_oil_events$]
ORDER BY
        oil_price_change_pct DESC
        
--Q12: Load Factor by Airline Type & Conflict Phase
SELECT
      airline_type,
      conflict_phase,
      ROUND(AVG(load_factor_pct),2) AS avg_load_factor_pct
FROM
    [dbo].[airline_ticket_prices$]
GROUP BY
        airline_type,
        conflict_phase
ORDER BY
        avg_load_factor_pct DESC,
        airline_type,
        conflict_phase

--Q13: Calculate routes cancelled vs rerouted per conflict phase and year?
 SELECT
        LEFT(month,4),
        conflict_phase,
       COUNT(CASE WHEN flight_cancelled = 'Yes' THEN 1 END) AS total_flights_cancelled,
       COUNT(CASE WHEN rerouted = 'Yes' THEN 1 END) AS total_flights_rerouted
FROM
    [dbo].[route_cost_impact$]
GROUP BY
         LEFT(month,4),
         conflict_phase
ORDER BY
         LEFT(month,4),
         conflict_phase

--Q14: Year-on-Year Ticket price change across all airlines
-- I have to change the data type of yoy_price_change_pct to float because it was stored as nvarchar
--and i wanted to calculate the average
ALTER TABLE [dbo].[airline_ticket_prices$]
ALTER COLUMN yoy_price_change_pct FLOAT

SELECT
      LEFT(month,4) AS year,
      ROUND(AVG(yoy_price_change_pct),2) AS avg_yoy_price_change
FROM
    [dbo].[airline_ticket_prices$]
WHERE
     yoy_price_change_pct IS NOT NULL
GROUP BY
       LEFT(month,4)
ORDER BY
       LEFT(month,4)

--Q15: Which region (Middle East, Asia, Europe, etc.) had the highest average net profit per quarter?
SELECT
      region,
      quarter,
      ROUND(AVG(net_profit_usd_m),2) AS avg_net_profit_usd_m
FROM
    [dbo].[airline_financial_impact$]
GROUP BY
        region,
        quarter
ORDER BY
        avg_net_profit_usd_m DESC,
        region,
        quarter

--Q16: Fare Breakdown: Base vs Surcharge vs Taxes by Conflict Phase
SELECT
      conflict_phase,
      ROUND(AVG(base_fare_usd),2) AS avg_base_fare_usd,
      ROUND(AVG(fuel_surcharge_usd),2) AS avg_fuel_surcharge_usd,
      ROUND(AVG(taxes_fees_usd),2) AS avg_taxes_fees_usd,
      ROUND(AVG(total_fare_usd),2) AS avg_total_fare_usd
FROM
    [dbo].[airline_ticket_prices$]
GROUP BY
        conflict_phase
ORDER BY
        avg_total_fare_usd DESC

--Q17: Fuel Efficiency by Aircraft Type
SELECT
      aircraft_type,
      ROUND(AVG(fuel_consumption_bbl / actual_distance_km), 2) AS avg_fuel_efficiency_bbl_per_km,
      ROUND(AVG(fuel_consumption_bbl), 2) AS avg_fuel_consumption_bbl,
      ROUND(AVG(actual_distance_km),2) AS avg_actual_distance_km
FROM
    [dbo].[route_cost_impact$]
WHERE
      actual_distance_km > 0
GROUP BY
        aircraft_type
ORDER BY
        avg_fuel_efficiency_bbl_per_km ASC,
        aircraft_type

--Q18: Surcharge as % of Base Fare by Region Year-on-Year
SELECT
      region,
      LEFT(month,4) AS year,
      ROUND(AVG(surcharge_as_pct_base), 2) AS avg_surcharge_as_pct_base
FROM
    [dbo].[fuel_surcharges$]
WHERE
      surcharge_as_pct_base IS NOT NULL
GROUP BY
        region,
        LEFT(month,4)
ORDER BY
        avg_surcharge_as_pct_base DESC,
        region,
     
--Q19: Which airlines carried the most passengers during high-severity conflict events,
--and what was their profit margin during those periods?
SELECT
      airline,
      ROUND(SUM(passengers_carried_m), 2) AS total_passengers_carried_m,
      ROUND(AVG(profit_margin_pct), 2) AS avg_profit_margin_pct
FROM
    [dbo].[airline_financial_impact$]
WHERE 
     conflict_phase IN (SELECT DISTINCT conflict_phase
                 FROM [dbo].[conflict_oil_events$]
                WHERE severity = 'High')
GROUP BY
        airline
ORDER BY
        total_passengers_carried_m DESC

--Q20: Financial Loss from Rerouting & Cancellations
SELECT
      airline,
      conflict_phase,
      SUM(CASE WHEN flight_cancelled = 'Yes' THEN route_revenue_usd ELSE 0 END) AS total_loss_from_cancellations_usd,
      SUM(CASE WHEN rerouted = 'Yes' THEN extra_fuel_cost_usd ELSE 0 END) AS total_loss_from_rerouting_usd,
      (SUM(CASE WHEN flight_cancelled = 'Yes' THEN route_revenue_usd ELSE 0 END) + 
       SUM(CASE WHEN rerouted = 'Yes' THEN extra_fuel_cost_usd ELSE 0 END)) AS total_financial_loss_usd
FROM
    [dbo].[route_cost_impact$] r
GROUP BY
        airline,
        conflict_phase
ORDER BY
        total_financial_loss_usd DESC,
        airline,
        conflict_phase

--EXTRAS:Top 5 Routes with Highest Fuel Cost as % of Total Ticket Price***
SELECT 
      TOP 5
      origin_city,
      destination_city,
      airline,
      fuel_pct_of_cost
FROM 
    [dbo].[route_cost_impact$]
GROUP BY
        origin_city,
        destination_city,
        airline,
        fuel_pct_of_cost
ORDER BY
        fuel_pct_of_cost DESC