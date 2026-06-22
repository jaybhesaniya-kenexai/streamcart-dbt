{% macro safe_net_amount(gross, disc) %}

(
    {{ gross }}
    *
    (
        1 - coalesce({{ disc }},0)/100
    )
)

{% endmacro %}