{% macro generate_row_key(cols_list) %}

md5(

    concat_ws(
        '|',

        {% for col in cols_list %}
            coalesce(cast({{ col }} as varchar),'')
            {% if not loop.last %},{% endif %}
        {% endfor %}

    )

)

{% endmacro %}