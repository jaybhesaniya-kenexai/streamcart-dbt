-- select

--     p.product_id,
--     p.product_name,
--     p.category,
--     p.sub_category,
--     p.brand,
--     p.margin_pct,
--     p.is_low_stock,

--     sum(f.quantity) as total_units_sold,

--     sum(f.net_amount)
--         as total_net_revenue,

--     avg(f.discount_pct)
--         as avg_discount_pct,

--     rank() over (
--         partition by p.category
--         order by sum(f.net_amount) desc
--     ) as revenue_rank,

--     p.qty_on_hand,
--     p.reorder_level,
--     p.warehouse_code

-- from {{ ref('fct_orders') }} f

-- join {{ ref('stg_products') }} p
--     on f.product_id = p.product_id

-- where f.payment_status='success'

-- group by
--     p.product_id,
--     p.product_name,
--     p.category,
--     p.sub_category,
--     p.brand,
--     p.margin_pct,
--     p.is_low_stock,
--     p.qty_on_hand,
--     p.reorder_level,
--     p.warehouse_code



with product_sales as (

    select
        product_id,
        product_name,
        category,
        sub_category,
        brand,
        margin_pct,
        is_low_stock,

        sum(
            case
                when payment_status = 'success'
                then quantity
                else 0
            end
        ) as total_units_sold,

        sum(
            case
                when payment_status = 'success'
                then net_amount
                else 0
            end
        ) as total_net_revenue,

        avg(discount_pct) as avg_discount_pct

    from {{ ref('fct_orders') }}

    group by
        product_id,
        product_name,
        category,
        sub_category,
        brand,
        margin_pct,
        is_low_stock

),

ranked as (

    select
        *,
        RANK() over (
            partition by category
            order by total_net_revenue desc
        ) as revenue_rank

    from product_sales

),

final as (

    select
        r.product_id,
        r.product_name,
        r.category,
        r.sub_category,
        r.brand,
        r.margin_pct,
        r.is_low_stock,
        r.total_units_sold,
        r.total_net_revenue,
        r.avg_discount_pct,
        r.revenue_rank,
        p.qty_on_hand,
        p.reorder_level,
        p.warehouse_code

    from ranked r
    left join {{ ref('stg_products') }} p
        on r.product_id = p.product_id

)

select *
from final