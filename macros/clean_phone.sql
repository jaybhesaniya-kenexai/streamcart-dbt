{% macro clean_phone(column_name) %}
    right(
        regexp_replace({{ column_name }}, '[^0-9]', ''),
        10
    )
{% endmacro %}