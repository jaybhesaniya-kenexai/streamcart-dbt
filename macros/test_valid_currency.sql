{% test valid_currency(model, column_name) %} 
  select 
    {{column_name}}
  from {{model}}
  where   {{column_name}} not in ('INR','USD','GBP','AED','EUR')

{% endtest %}