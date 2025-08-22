#!/bin/bash

set_key_value() {
    local key="$1"
    local value="$2"
    
    local file="${BASH_FUNCTION_KEY_VALUE_FILE:-"/usr/local/bin/bash/.cache/function/key_value"}"
    mkdir -p "$(dirname "$file")"

    if grep -q "^${key}=" "$file" 2>/dev/null; then
        sed -i "s/^${key}=.*/${key}=${value}/" "$file"
    else
        echo "${key}=${value}" >> "$file"
    fi
}