{{ config(
    materialized='incremental',
    unique_key=['event_id', 'product_id'],
    incremental_strategy='merge',
    on_schema_change='sync_all_columns'
) }}

with source as (

    select
        *
    from {{ source('raw_streamcart','raw_orders') }} s

    {% if is_incremental() %}
        where s._loaded_at >
            (
                select coalesce(
                    max(_loaded_at),
                    '1900-01-01'::timestamp
                )
                from {{ this }} t
            )
    {% endif %}

),

filtered as (

    select *
    from source

    {% if var('lookback_days', none) is not none %}

    where _loaded_at >=
        dateadd(
            day,
            -{{ var('lookback_days') }},
            current_timestamp
        )

    {% endif %}

),

dedup as (

    select *
    from filtered

    qualify row_number() over (
        partition by trim(data:event_id::string)
        order by _loaded_at desc
    ) = 1

),

flattened as (

    select
        d.*,
        f.value as item
    from dedup d,
    lateral flatten(input => d.data:order.items) f

)

select

    trim(data:event_id::string) as event_id,

    lower(trim(data:event_type::string)) as event_type,

    to_timestamp(
        data:occurred_at::string,
        'DD/MM/YYYY HH24:MI:SS'
    ) as occurred_at,

    trim(data:customer.id::string) as customer_id,

    {% if target.name == 'prod' %}

        initcap(trim(data:customer.name::string))
            as customer_name,

        lower(trim(data:customer.email::string))
            as email,

    {% else %}

        'Customer_' || trim(data:customer.id::string)
            as customer_name,

        md5(lower(trim(data:customer.email::string)))
            as email,

    {% endif %}

    {{ clean_phone("data:customer.phone::string") }} as phone,

    coalesce(
        initcap(lower(data:customer.tier::string)),
        'Standard'
    ) as customer_tier,

    initcap(lower(data:customer.address.city::string))
        as city,

    upper(trim(data:customer.address.country::string))
        as country_code,

    trim(data:order.order_id::string)
        as order_id,

    lower(
        replace(
            trim(data:order.channel::string),
            ' ',
            '_'
        )
    ) as channel,

    {{ parse_date_flexible(
        "data:order.placed_at::string",
        "DD/MM/YYYY",
        "YYYY-MM-DD"
    ) }}
    as order_date,

    upper(trim(data:order.currency::string))
        as currency_code,

    {{ clean_amount("data:order.total_amount::string") }}
        as order_total,

    item:product_id::string as product_id,

    coalesce(
    try_to_number(nullif(trim(item:qty::string), '')),
    0
    ) as quantity,

    {{ clean_amount("item:unit_price::string") }}
        as unit_price,

    case
        when try_to_number(item:discount_pct::string) > 60
            then null
        else try_to_number(item:discount_pct::string)
    end as discount_pct,

    lower(
        replace(
            trim(data:order.payment.method::string),
            ' ',
            '_'
        )
    ) as payment_method,

    lower(trim(data:order.payment.status::string))
        as payment_status,

    quantity * unit_price
        as gross_amount,

    {{ safe_net_amount(
        'quantity * unit_price',
        'discount_pct'
    ) }}
        as net_amount,

        _loaded_at

from flattened

where lower(data:metadata.is_test_event::string) <> 'true'