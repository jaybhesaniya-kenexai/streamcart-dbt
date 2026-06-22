with source as(
  select *
   from {{ref('int_customer_summary')}} --succcess paymrnts order summary per customer
)
select 
           customer_id,
           customer_name,
           email, 
           phone,
           customer_tier, 
           city,
           s.country_code,
           dc.region ,           
       total_orders,
        total_gross_revenue,
        total_net_revenue,
        {{ dbt_utils.safe_divide('total_net_revenue','total_orders') }} as avg_order_value,
        days_since_last_order ,
       case when total_orders >=10
          then 'Platinum'
         when total_orders>=5
          then 'Gold'
         when total_orders>=2
          then 'Silver'
         else 
            'Bronze'
    end as customer_segment 
from source s 
   join {{ ref('country_config')}} dc 
  on s.country_code=dc.country_code 