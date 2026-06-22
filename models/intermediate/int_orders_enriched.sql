with source as 
(
select o.*,
       product_name,
       category,
       sub_category,
       brand,
       margin_pct , 
       is_low_stock
from {{ref('stg_orders')}} o
    join {{ref('stg_products')}} p 
 on o.product_id=p.product_id

),
filtered as(
 select * ,
     case 
       when discount_pct>0
         then true
        else 
           false
     end as is_discounted        
 from source
  where event_type='order_placed'
)
select *
from filtered