{{ config(
    materialized='incremental',
    unique_key='order_line_key',
    incremental_strategy='merge',
    on_schema_change='sync_all_columns',
    cluster_by=['order_date'] ,

    post_hook=[
            "{% if target.name == 'prod' %}
            grant select on {{ this }} to role prod_reader
         {% endif %}"
    ]
) }}

with source as (

    select *
    from {{ ref('int_orders_enriched') }}

    {% if is_incremental() %}
        where order_date >
            (
                select max(order_date)
                from {{ this }}
            )
    {% endif %}

),

channel_mapping as (

    select *
    from {{ ref('channel_mapping') }}

)

select

    {{ dbt_utils.generate_surrogate_key(
        ['order_id', 'product_id']
    ) }} as order_line_key,

    s.*,

    cm.channel_label,

    {% if var('show_margin', false) %}
        margin_pct * (1 - discount_pct)
            as effective_margin_pct
    {% endif %}

from source s

left join channel_mapping cm
    on s.channel = cm.channel_code