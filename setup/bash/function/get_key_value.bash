#!/bin/bash

get_key_value() {
    local key="$1"
    local default_value="$2" 
    local value 

    local file="${BASH_FUNCTION_KEY_VALUE_FILE:-"/usr/local/bin/bash/.cache/function/key_value"}"
    mkdir -p "$(dirname "$file")"
    
    if grep -q "^${key}=" "$file" 2>/dev/null; then
        value=$(grep "^${key}=" "$file" | cut -d '=' -f 2-)
    else
        value="$default_value"
    fi
    echo "$value"
}