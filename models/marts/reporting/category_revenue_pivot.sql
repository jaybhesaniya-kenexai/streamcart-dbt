{% set categories = [
    'ELECTRONICS',
    'HOME_APPLIANCES',
    'COMPUTERS'
] %}

select
    customer_id,

    {% for cat in categories %}
    sum(
        case
            when upper(category) = '{{ cat }}'
            then net_amount
            else 0
        end
    ) as {{ cat | lower }}_revenue
    {% if not loop.last %},{% endif %}
    {% endfor %}

from {{ ref('fct_orders') }}

group by customer_id