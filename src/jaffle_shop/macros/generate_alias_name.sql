{% macro generate_alias_name(custom_alias_name=none, node=none) -%}

    {%- if target.name == "ci" -%}
        {# Prefix GITHUB_RUN_NUMBER to the alias, so CI namespaces are distinct.#}
        {{ env_var("GITHUB_RUN_NUMBER", "") ~ "_" ~ {{ node.name }} }}

    {%- elif custom_alias_name -%}

        {{ custom_alias_name | trim }}

    {%- elif node.version -%}

        {{ return(node.name ~ "_v" ~ (node.version | replace(".", "_"))) }}

    {%- else -%}

        {{ node.name }}

    {%- endif -%}

{%- endmacro %}
