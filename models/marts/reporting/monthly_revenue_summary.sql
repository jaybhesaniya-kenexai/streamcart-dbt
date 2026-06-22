-- with base as (

--     select *
--     from {{ ref('fct_orders') }}
--     where payment_status='success'

-- ),

-- category_rank as (

--     select
--         year(order_date) as order_year,
--         month(order_date) as order_month,
--         category,
--         sum(net_amount) as revenue,

--         row_number() over (
--             partition by
--                 year(order_date),
--                 month(order_date)
--             order by sum(net_amount) desc
--         ) as rn

--     from base
--     group by 1,2,3

-- ),

-- channel_rank as (

--     select
--         year(order_date) as order_year,
--         month(order_date) as order_month,
--         channel,
--         count(distinct order_id) as orders_cnt,

--         row_number() over (
--             partition by
--                 year(order_date),
--                 month(order_date)
--             order by count(distinct order_id) desc
--         ) as rn

--     from base
--     group by 1,2,3

-- )

-- select

--     year(b.order_date) as order_year,
--     month(b.order_date) as order_month,

--     count(distinct b.order_id) as total_orders,

--     sum(b.gross_amount) as total_gross_revenue,

--     sum(b.net_amount) as total_net_revenue,

--     sum(
--         b.gross_amount - b.net_amount
--     ) as total_discount_given,

--     avg(b.discount_pct) as avg_discount_pct,

--     max(
--         case when cr.rn=1
--         then cr.category end
--     ) as top_category,

--     max(
--         case when chr.rn=1
--         then chr.channel end
--     ) as top_channel

-- from base b

-- left join category_rank cr
--     on year(b.order_date)=cr.order_year
--    and month(b.order_date)=cr.order_month

-- left join channel_rank chr
--     on year(b.order_date)=chr.order_year
--    and month(b.order_date)=chr.order_month

-- group by 1,2





with orders as (

    select
        f.*,
        d.year as order_year,
        d.month as order_month

    from {{ ref('fct_orders') }} f
    inner join {{ ref('dim_date') }} d
        on f.order_date = d.date

    where f.payment_status = 'success'

),

monthly_metrics as (

    select
        order_year,
        order_month,

        count(distinct order_id) as total_orders,

        sum(gross_amount) as total_gross_revenue,

        sum(net_amount) as total_net_revenue,

        sum(gross_amount - net_amount) as total_discount_given,

        avg(discount_pct) as avg_discount_pct

    from orders

    group by
        order_year,
        order_month

),

category_revenue as (

    select
        order_year,
        order_month,
        category,

        sum(net_amount) as category_net_revenue

    from orders

    group by
        order_year,
        order_month,
        category

),

top_category as (

    select distinct
        order_year,
        order_month,

        first_value(category) over (
            partition by order_year, order_month
            order by category_net_revenue desc
        ) as top_category

    from category_revenue

),

channel_orders as (

    select
        order_year,
        order_month,
        channel,

        count(distinct order_id) as channel_order_count

    from orders

    group by
        order_year,
        order_month,
        channel

),

top_channel as (

    select distinct
        order_year,
        order_month,

        first_value(channel) over (
            partition by order_year, order_month
            order by channel_order_count desc
        ) as top_channel

    from channel_orders

),

final as (

    select
        m.order_year,
        m.order_month,
        m.total_orders,
        m.total_gross_revenue,
        m.total_net_revenue,
        m.total_discount_given,
        m.avg_discount_pct,
        tc.top_category,
        tch.top_channel

    from monthly_metrics m

    left join top_category tc
        on m.order_year = tc.order_year
       and m.order_month = tc.order_month

    left join top_channel tch
        on m.order_year = tch.order_year
       and m.order_month = tch.order_month

)

select *
from final