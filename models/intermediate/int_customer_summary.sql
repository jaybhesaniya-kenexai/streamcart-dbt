with source as 
(
    select * 
    from {{ref("int_orders_enriched")}}
),
customer_summary as (
    select customer_id,
           customer_name,
           email, 
           phone,
           customer_tier, 
           city,
           country_code,
       count(*) as total_orders,
       sum(gross_amount) as total_gross_revenue,
       sum(net_amount) as total_net_revenue,
       avg(net_amount) as avg_order_value,
       datediff(day,max(order_date),current_date) as days_since_last_order ,
       
from source
where payment_status='success'      
group by 1,2,3,4,5,6,7
)
select * ,
    case when total_orders >=10
          then 'Platinum'
         when total_orders>=5
          then 'Gold'
         when total_orders>=2
          then 'Silver'
         else 
            'Bronze'
    end as customer_segment          
from customer_summary
