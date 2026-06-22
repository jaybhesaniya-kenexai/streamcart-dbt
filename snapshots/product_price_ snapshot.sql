{% snapshot product_price_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='check',
        check_cols=['list_price', 'is_available']
    )
}}

with latest_product as (

    select

        trim(data:product_id::string) as product_id,

        data:pricing.list_price::float as list_price,

        coalesce(
            try_to_boolean(data:is_available::string),
            false
        ) as is_available,

        row_number() over (
            partition by trim(data:product_id::string)
            order by _loaded_at desc
        ) as rn

    from {{ source('raw_streamcart', 'raw_products') }}

)

select
    product_id,
    list_price,
    is_available

from latest_product

where rn = 1

{% endsnapshot %}