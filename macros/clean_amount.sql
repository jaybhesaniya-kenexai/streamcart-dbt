{% macro clean_amount(col) %}

try_to_decimal(
    replace(
        replace(
            trim({{ col }}),
            '$',
            ''
        ),
        ',',
        ''
    ),
    12,
    2
)
{% endmacro %}