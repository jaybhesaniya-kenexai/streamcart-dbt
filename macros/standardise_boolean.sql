{% macro standardise_boolean(col) %}

case
    when upper(trim({{ col }}))
         in ('TRUE','1','YES','Y')
    then true
    else false
end

{% endmacro %}