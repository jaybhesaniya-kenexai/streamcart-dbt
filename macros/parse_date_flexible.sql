{% macro parse_date_flexible(col, fmt1, fmt2) %}

case
    when {{ col }} like '__/__/____%'
    then to_date({{ col }}, '{{ fmt1 }}')
    else to_date({{ col }}, '{{ fmt2 }}')
end

{% endmacro %}