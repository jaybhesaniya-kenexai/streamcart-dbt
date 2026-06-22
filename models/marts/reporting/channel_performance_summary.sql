-- with payment_rank as (

--     select

--         order_date,
--         channel,
--         payment_method,

--         count(*) as cnt,

--         row_number() over (
--             partition by order_date, channel
--             order by count(*) desc
--         ) as rn

--     from {{ ref('fct_orders') }}

--     group by 1,2,3

-- )

-- select

--     f.order_date,
--     f.channel,

--     count(distinct f.order_id)
--         as total_orders,

--     count(distinct case
--         when f.payment_status='success'
--         then f.order_id
--     end) as successful_orders,

--     count(distinct case
--         when f.payment_status='failed'
--         then f.order_id
--     end) as cancelled_orders,

--     round(
--         count(distinct case
--             when f.payment_status='success'
--             then f.order_id
--         end)
--         /
--         nullif(
--             count(distinct f.order_id),
--             0
--         )
--         *100,
--         2
--     ) as success_rate_pct,

--     sum(f.gross_amount)
--         as total_gross_revenue,

--     sum(f.net_amount)
--         as total_net_revenue,

--     round(
--         sum(f.net_amount)
--         /
--         nullif(
--             count(distinct f.order_id),
--             0
--         ),
--         2
--     ) as avg_order_value,

--     max(
--         case
--             when pr.rn = 1
--             then pr.payment_method
--         end
--     ) as most_used_payment_method

-- from {{ ref('fct_orders') }} f

-- left join payment_rank pr
--     on f.order_date = pr.order_date
--    and f.channel = pr.channel

-- group by
--     f.order_date,
--     f.channel


with daily_channel_metrics as (

    select
        order_date,
        channel,

        count(distinct order_id) as total_orders,

        count(
            distinct case
                when payment_status = 'success'
                then order_id
            end
        ) as successful_orders,

        count(
            distinct case
                when payment_status = 'cancelled'
                then order_id
            end
        ) as cancelled_orders,

        sum(gross_amount) as total_gross_revenue,

        sum(net_amount) as total_net_revenue,

        avg(net_amount) as avg_order_value

    from {{ ref('fct_orders') }}

    group by
        order_date,
        channel

),

payment_method_counts as (

    select
        order_date,
        channel,
        payment_method,

        count(*) as payment_method_count

    from {{ ref('fct_orders') }}

    group by
        order_date,
        channel,
        payment_method

),

ranked_payment_methods as (

    select
        *,
        rank() over (
            partition by order_date, channel
            order by payment_method_count desc
        ) as payment_rank

    from payment_method_counts

),

most_used_payment_method as (

    select
        order_date,
        channel,
        payment_method as most_used_payment_method

    from ranked_payment_methods

    where payment_rank = 1

),

final as (

    select
        d.order_date,
        d.channel,
        d.total_orders,
        d.successful_orders,
        d.cancelled_orders,

        d.successful_orders
            / nullif(d.total_orders, 0) * 100
            as success_rate_pct,

        d.total_gross_revenue,
        d.total_net_revenue,
        d.avg_order_value,

        p.most_used_payment_method

    from daily_channel_metrics d
    left join most_used_payment_method p
        on d.order_date = p.order_date
       and d.channel = p.channel

)

select *
from final