{{ config(materialized='table') }}

with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2015-01-01' as date)",
        end_date="cast('2035-12-31' as date)"
    ) }}

)

select
    date_day as date,

    extract(day from date_day) as day_of_month,
    extract(month from date_day) as month,
    extract(year from date_day) as year,
    extract(quarter from date_day) as quarter,

    extract(week from date_day) as week_of_year,
    extract(dayofweek from date_day) as day_of_week,

    dayname(date_day) as day_name,
    monthname(date_day) as month_name,

    case
        when extract(dayofweek from date_day) in (0,6)
        then true
        else false
    end as is_weekend

from date_spine