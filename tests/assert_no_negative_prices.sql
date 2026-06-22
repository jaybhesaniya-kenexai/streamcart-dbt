select 
  unit_price
from {{ ref('stg_orders') }}
where unit_price is not null and  unit_price<0  