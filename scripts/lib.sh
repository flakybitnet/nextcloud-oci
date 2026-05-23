#!/bin/sh
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p "$user" -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

# Execute all executable files in a given directory in alphanumeric order
run_path() {
    local hook_folder_path="/docker-entrypoint-hooks.d/$1"
    local found=0

    echo "=> Searching for hook scripts (*.sh) to run, located in the folder \"${hook_folder_path}\""

    if ! [ -d "${hook_folder_path}" ] || directory_empty "${hook_folder_path}"; then
        echo "==> Skipped: the \"$1\" folder is empty (or does not exist)"
        return 0
    fi

    find "${hook_folder_path}" -maxdepth 1 -iname '*.sh' '(' -type f -o -type l ')' -print | sort | (
        while read -r script_file_path; do
            if ! [ -x "${script_file_path}" ]; then
                echo "==> The script \"${script_file_path}\" was skipped, because it lacks the executable flag"
                continue
            fi

            echo "==> Running the script (cwd: $(pwd)): \"${script_file_path}\""
            found=$((found+1))
            run_as "${script_file_path}" || {
                return_code="$?"
                echo "==> Failed at executing script \"${script_file_path}\". Exit code: ${return_code}"
                exit 1
            }

            echo "==> Finished executing the script: \"${script_file_path}\""
        done
        if [ "$found" -gt "0" ]; then
		    echo "=> Completed executing scripts in the \"$1\" folder"
        else
		    echo "==> Skipped: the \"$1\" folder does not contain any valid scripts"
        fi
    )
}

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

get_enabled_apps() {
    run_as 'php /var/www/html/occ app:list' \
        | sed -n '/^Enabled:$/,/^Disabled:$/p' \
        | sed '1d;$d' \
        | sed -n 's/^  - \([^:]*\):.*/\1/p' \
        | sort
}
