select 
  discount_pct
from {{ ref('stg_orders') }}
where discount_pct is not null 
 and discount_pct>60   