with base as (

    select
        order_date,
        channel,
        net_amount
    from {{ ref('fct_orders') }}

    where payment_status = 'success'

)

select

    order_date,

    {{ dbt_utils.pivot(
        'channel',
        ['mobile_app','web','partner_api'],
        agg='sum',
        then_value='net_amount',
        else_value='0',
        suffix='_revenue'
    ) }}

from base

group by order_date