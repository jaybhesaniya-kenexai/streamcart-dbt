{% snapshot customer_tier_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='_loaded_at'
    )
}}

with latest_customer as (

    select
        trim(data:customer.id::string) as customer_id,

        coalesce(
            initcap(lower(data:customer.tier::string)),
            'Standard'
        ) as customer_tier,

        initcap(
            lower(data:customer.address.city::string)
        ) as city,

        _loaded_at,

        row_number() over (
            partition by trim(data:customer.id::string)
            order by _loaded_at desc
        ) as rn

    from {{ source('raw_streamcart', 'raw_orders') }}

)

select
    customer_id,
    customer_tier,
    city,
    _loaded_at

from latest_customer

where rn = 1

{% endsnapshot %}