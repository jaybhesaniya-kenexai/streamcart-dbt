with source as (

    select {{ dbt_utils.star(
         from=source('raw_streamcart', 'raw_products') ,
         except=['_source']
         ) }}
    from {{ source('raw_streamcart','raw_products') }}

),

dedup as (

    select *
    from source

    qualify row_number() over (
        partition by trim(data:product_id::string)
        order by _loaded_at desc
    ) = 1

)

select

    trim(data:product_id::string)
        as product_id,

    trim(data:name::string)
        as product_name,

    initcap(lower(data:category::string))
        as category,

    lower(trim(data:sub_category::string))
        as sub_category,

    initcap(lower(data:brand::string))
        as brand,

        {{ standardise_boolean(
            "data:is_available::string"
        ) }}
        as is_available ,

    array_to_string(data:tags, ',')
        as tags,

    try_to_double(
        data:specs.weight_kg::string
    ) as weight_kg,

    try_to_number(
        data:specs.warranty_yr::string
    ) as warranty_years,

    data:pricing.cost_price::float
        as cost_price,

    data:pricing.list_price::float
        as list_price,

    try_to_number(
        data:stock.qty_on_hand::string
    ) as qty_on_hand,

    try_to_number(
        data:stock.reorder_lvl::string
    ) as reorder_level,

    upper(trim(data:stock.warehouse::string))
        as warehouse_code,

    round(
        (
            list_price - cost_price
        )*100
        /
        nullif(list_price,0),
        2
    ) as margin_pct,

    case
        when qty_on_hand <= reorder_level
        then true
        else false
    end as is_low_stock

from dedup