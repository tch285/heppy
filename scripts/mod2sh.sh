#!/bin/bash

# mod2sh.sh - Converts modulefile to bash script
# Usage: ./mod2sh.sh input_modulefile output_script

if [ $# -lt 2 ]; then
    echo "Usage: $0 <input_modulefile> <output_script>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

cat > "$OUTPUT_FILE" << 'EOL'
#!/bin/bash
# Generated on: $(date)

EOL

chmod +x "$OUTPUT_FILE"

while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^#.*$ ]] || [[ -z "${line// }" ]]; then
        echo "# $line" >> "$OUTPUT_FILE"
        continue
    fi

    # set
    if [[ "$line" =~ ^[[:space:]]*set[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        echo "$var_name=$var_value" >> "$OUTPUT_FILE"
        continue
    fi

    # prepend-path
    if [[ "$line" =~ ^[[:space:]]*prepend-path[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
        path_var="${BASH_REMATCH[1]}"
        path_value="${BASH_REMATCH[2]}"
        echo "export $path_var=$path_value:\$$path_var" >> "$OUTPUT_FILE"
        continue
    fi

    # append-path
    if [[ "$line" =~ ^[[:space:]]*append-path[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
        path_var="${BASH_REMATCH[1]}"
        path_value="${BASH_REMATCH[2]}"
        echo "export $path_var=\$$path_var:$path_value" >> "$OUTPUT_FILE"
        continue
    fi

    # setenv
    if [[ "$line" =~ ^[[:space:]]*setenv[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
        env_var="${BASH_REMATCH[1]}"
        env_value="${BASH_REMATCH[2]}"
        echo "export $env_var=$env_value" >> "$OUTPUT_FILE"
        continue
    fi

    # unsetenv
    if [[ "$line" =~ ^[[:space:]]*unsetenv[[:space:]]+([^[:space:]]+)$ ]]; then
        env_var="${BASH_REMATCH[1]}"
        echo "unset $env_var" >> "$OUTPUT_FILE"
        continue
    fi

    # set-alias
    if [[ "$line" =~ ^[[:space:]]*set-alias[[:space:]]+([^[:space:]]+)[[:space:]]+(.*)$ ]]; then
        alias_name="${BASH_REMATCH[1]}"
        alias_value="${BASH_REMATCH[2]}"
        # Remove quotes if present
        alias_value="${alias_value//\"/}"
        echo "alias $alias_name=\"$alias_value\"" >> "$OUTPUT_FILE"
        continue
    fi

    # module load: added as comment
    if [[ "$line" =~ ^[[:space:]]*module[[:space:]]+load[[:space:]]+(.*)$ ]]; then
        module_name="${BASH_REMATCH[1]}"
        echo "# NOTE: Original had 'module load $module_name' - you need to source that module's script" >> "$OUTPUT_FILE"
        continue
    fi

    # unrecognized: add as comment
    echo "# UNTRANSLATED: $line" >> "$OUTPUT_FILE"

done < "$INPUT_FILE"

echo "Conversion complete; output written to: $OUTPUT_FILE"