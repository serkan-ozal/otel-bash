#!/bin/bash

# Copyright 2023 Serkan Ozal

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Log levels:
# - 1: DEBUG
# - 2: INFO
# - 3: WARN
# - 4: ERROR
declare -r _OTEL_BASH_LOG_LEVEL_DEBUG=1
declare -r _OTEL_BASH_LOG_LEVEL_INFO=2
declare -r _OTEL_BASH_LOG_LEVEL_WARN=3
declare -r _OTEL_BASH_LOG_LEVEL_ERROR=4
declare -r _DEFAULT_OTEL_CLI_SERVER_PORT=7777

################################## UTILITIES ###################################
################################################################################

function _otel_bash_print() {
    echo "[OTEL-BASH]" ${@}
}

function _otel_bash_log() {
    _otel_bash_print "$1" "-" "$2" ${@:3}
}

function _otel_bash_log_debug() {
    if [ $_OTEL_BASH_LOG_LEVEL_DEBUG -ge $_otel_bash_log_level ]; then
        _otel_bash_log "DEBUG" "$1" "$2"
    fi    
}

function _otel_bash_log_info() {
    if [ $_OTEL_BASH_LOG_LEVEL_INFO -ge $_otel_bash_log_level ] ; then
        _otel_bash_log "INFO" "$1" "$2"
    fi    
}

function _otel_bash_log_warn() {
    if [ $_OTEL_BASH_LOG_LEVEL_WARN -ge $_otel_bash_log_level ]; then
        _otel_bash_log "WARN" "$1" "$2"
    fi    
}

function _otel_bash_log_error() {
    if [ $_OTEL_BASH_LOG_LEVEL_ERROR -ge $_otel_bash_log_level ]; then
        _otel_bash_log "ERROR" "$1" "$2"
    fi    
}

function _otel_bash_map_hash_key() {
    # replace non-alphanumeric characters with underscore to make keys valid BASH identifiers
    echo "$1_$2" | sed -E "s/[^a-zA-Z0-9]+/_/g" | sed -E "s/^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+\$//g"
}

function _otel_bash_quote() {
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "$quoted"
}

function _otel_bash_map_get() {
    local KEY=$(_otel_bash_quote "$2");
    local HASHED_KEY=`_otel_bash_map_hash_key $1 "$KEY"`
    echo "${!HASHED_KEY}"
}

function _otel_bash_map_has_key() {
    local value=$(_otel_bash_map_get $1 "$2")
    if [ -z "${value}" ]; then
        return 0
    else
        return 1
    fi
}

function _otel_bash_map_put() {
    local KEY=$(_otel_bash_quote "$2");
    local VALUE=$(_otel_bash_quote "$3");
    local HASHED_KEY=`_otel_bash_map_hash_key $1 "$KEY"`
    eval "$HASHED_KEY"="$VALUE"
}

function _otel_bash_map_remove() {
    local KEY=$(_otel_bash_quote "$2");
    local HASHED_KEY=`_otel_bash_map_hash_key $1 "$KEY"`
    eval "unset $HASHED_KEY"
}

################################################################################

##################################### IMPL #####################################
################################################################################

function _otel_bash_get_scope() {
    _otel_bash_map_get _otel_bash_scopes "$1"
}

function _otel_bash_has_scope() {
    _otel_bash_map_has_key _otel_bash_scopes "$1"
    return $?
}

function _otel_bash_put_scope() {
    _otel_bash_map_put _otel_bash_scopes "$1" "$2"
}

function _otel_bash_remove_scope() {
    _otel_bash_map_remove _otel_bash_scopes "$1"
}

function _otel_bash_get_parent_scope() {
    _otel_bash_map_get _otel_bash_parent_scopes "$1"
}

function _otel_bash_put_parent_scope() {
    _otel_bash_map_put _otel_bash_parent_scopes "$1" "$2"
}

function _otel_bash_remove_parent_scope() {
    _otel_bash_map_remove _otel_bash_parent_scopes "$1"
}

function _otel_bash_now_nanos() {
    local epoch=""

    if [ -n "${EPOCHREALTIME-}" ]; then
        epoch=$(( ${EPOCHREALTIME/./} * 1000 ))
    elif hash python 2>/dev/null; then
        epoch=$(python -c 'from time import time; print(int(round(time() * 1000000000)))')
    elif hash python3 2>/dev/null; then
        epoch=$(python3 -c 'from time import time; print(int(round(time() * 1000000000)))')
    elif hash node 2>/dev/null; then
        epoch=$(node -e 'console.log(Date.now() * 1000000)')
    elif hash gdate 2>/dev/null; then
        epoch="$(gdate +%s%9N)"
    else
        if [[ "$OSTYPE" == "linux"* ]]; then
            epoch=$(date +%s%9N)
        else
            epoch=$(date +%s000000000)
        fi
    fi

    echo ${epoch}
}

function _otel_bash_validate_traceparent {
    local traceparent=$1
    if [[ "$traceparent" =~ ^00-[0-9a-z]{32}-[0-9a-z]{16}-[0-9a-z]{2}$ ]]; then
        return 1
    else
        return 0
    fi
}

function _otel_bash_extract_trace_id_from_traceparent {
    local traceparent=$1
    _otel_bash_traceparent $traceparent
    local is_valid=$?
    if [ $is_valid == 1 ]; then
        echo ${traceparent:3:32}
    fi
}

function _otel_bash_extract_parent_span_id_from_traceparent {
    local traceparent=$1
    _otel_bash_traceparent $traceparent
    local is_valid=$?
    if [ $is_valid == 1 ]; then
        echo ${traceparent:36:16}
    fi
}

function _otel_bash_generate_trace_id() {
    # Generate 64 bit (8 byte) random number
    local i1=$(($RANDOM<<48 | $RANDOM<<32 | $RANDOM<<16 | $RANDOM))
    # Generate another 64 bit (8 byte) random number
    local i2=$(($RANDOM<<48 | $RANDOM<<32 | $RANDOM<<16 | $RANDOM))
    # Combine two 64 bit (16 hex character) numbers to produce 128 bit (16 hex character) random number
    printf '%016x%016x\n' $i1 $i2
}

function _otel_bash_generate_span_id() {
    # Generate 64 bit (8 byte) random number
    local i=$(($RANDOM<<48 | $RANDOM<<32 | $RANDOM<<16 | $RANDOM))
    printf '%016x\n' $i
}

function _otel_bash_report_span() {
    local source_file_name="$1"
    local func_name="$2"
    local line_no=$3
    local command="$4"
    local parent_span_id="$5"
    local span_id="$6"
    local start_time=$7
    local end_time=$8
    local return_code=$9
    local status_code="OK"
    local duration_ms=$(((end_time-start_time)/1000000))

    local span_name="${source_file_name}:${func_name}@${line_no}"
    if [ $line_no == 0 ]; then
        span_name="${source_file_name}"
    fi
    if [ $return_code != 0 ]; then
        status_code="ERROR"
    fi

    _otel_bash_log_info "<report_span>" \
        "Reporting span:" \
            "name=${span_name}," "command=${command}," \
            "trace id=${_otel_bash_trace_id}," "parent span id=${parent_span_id}," "span id=${span_id}," \
            "duration(ms)=${duration_ms}," "return code=${return_code} ..."

    if [ $_otel_bash_otel_cli_exist == 1 ]; then
        otel-cli export \
            --name "${span_name}" --service-name "${source_file_name}" \
            --trace-id "${_otel_bash_trace_id}" --span-id "${span_id}" --parent-span-id "${parent_span_id}" \
            --traceparent-disable --start-time-nanos ${start_time} --end-time-nanos ${end_time} \
            --kind INTERNAL --status-code ${status_code} \
            --attributes \
                "source.file.name=${source_file_name}" "function.name=${func_name}" \
                line.no=${line_no} "command=${command}" return.code=${return_code}
    else
        _otel_bash_print "Span:" \
            "name='${span_name}'," "service name='${source_file_name}'," \
            "trace id='${_otel_bash_trace_id}'," "parent span id='${parent_span_id}'," "span id='${span_id}'," \
            "start time nanos=${start_time}," "end time nanos=${end_time}, ", \
            "kind='INTERNAL'," "status='${status_code}' ..."
    fi
}

function _otel_bash_trap_debug() {
    local current_time1=$(_otel_bash_now_nanos)

    local source_file_name="${BASH_SOURCE[1]}"
    local func_name="${FUNCNAME[1]}"
    local command="${BASH_COMMAND}"
    local line_no=${BASH_LINENO}
    local return_code=$?

    if [[ "${FUNCNAME[1]}" == "_otel_bash_"* ]] || [[ "${FUNCNAME[1]}" == "otel_bash_"* ]]; then
        return
    fi

    local delimiter="///"
    local parent_span_id=""
    local span_id=$(_otel_bash_generate_span_id)
    local scope_id="${SHLVL}:${source_file_name}:${func_name}"
    local existing_scope=$(_otel_bash_get_scope "$scope_id")
    local parent_scope=""

    if [ ! -z "$existing_scope" ]
    then
        # Parse and get existing scope elements
        local existing_scope_elements=()
        local s=$existing_scope$delimiter
        while [[ $s ]]; do
            existing_scope_elements+=( "${s%%"$delimiter"*}" );
            s=${s#*"$delimiter"};
        done;

        _otel_bash_report_span \
            "${existing_scope_elements[0]}" \
            "${existing_scope_elements[1]}" \
            ${existing_scope_elements[2]} \
            "${existing_scope_elements[3]}" \
            "${existing_scope_elements[4]}" \
            "${existing_scope_elements[5]}" \
            ${existing_scope_elements[6]} \
            ${current_time1} \
            ${return_code}
    fi

    # Check whether current scope has any span
    _otel_bash_has_scope "$scope_id"
    local has_scope=$?
    if [ $has_scope == 0 ]; then
        parent_scope=$(_otel_bash_get_scope "$_otel_bash_latest_scope_id")
    else
        local parent_scope_id=$(_otel_bash_get_parent_scope "$scope_id")
        parent_scope=$(_otel_bash_get_scope "$parent_scope_id")
    fi

    # Check whether there is parent scope
    if [ ! -z "$parent_scope" ]
    then
        # Parse and get parent scope elements
        local parent_scope_elements=()
        local s=$parent_scope$delimiter
        while [[ $s ]]; do
            parent_scope_elements+=( "${s%%"$delimiter"*}" );
            s=${s#*"$delimiter"};
        done;

        # Set parent span id as the id of the active span in the parent scope
        parent_span_id="${parent_scope_elements[5]}"
    fi

    # Check whether parent span has been able to resolved
    if [ -z "$parent_span_id" ]; then
        # If parent span has not been able to resolved, take root span as parent span
        parent_span_id=${_otel_bash_root_span_id}
    fi

    # Check whether
    # - current span will be root of its scope
    # - latest scope is exist
    # - current scope is different then latest scope
    if [ $has_scope == 0 ] && \
      [ ! -z "$_otel_bash_latest_scope_id" ] && \
      [ "${scope_id}" != "$_otel_bash_latest_scope_id" ]; then
        # Map latest scope as parent of the current span
        _otel_bash_put_parent_scope "$scope_id" "$_otel_bash_latest_scope_id"
    fi

    local current_time2=$(_otel_bash_now_nanos)
    local current_scope=""
    current_scope+="${source_file_name}${delimiter}"
    current_scope+="${func_name}${delimiter}"
    current_scope+="${line_no}${delimiter}"
    current_scope+="${command}${delimiter}"
    current_scope+="${parent_span_id}${delimiter}"
    current_scope+="${span_id}${delimiter}"
    current_scope+="${current_time2}"

    # Save current span as the active span its scope
    _otel_bash_put_scope "$scope_id" "${current_scope}"

    # Set current scope as latest scope
    _otel_bash_latest_scope_id=$scope_id

    # To be able to propagate active span id as parent span id to the new process,
    # set environment variable at every new span start.
    # So it will be picked up by child process.
    export OTEL_BASH_PARENT_SPAN_ID=$span_id

    # Export traceparent header so it can be picked up by child processes trace by OTEL
    export TRACEPARENT="00-${_otel_bash_trace_id}-${span_id}-01"

    _otel_bash_log_debug "<trap_debug>" "============================"
    _otel_bash_log_debug "<trap_debug>" "TRACE ID : ${_otel_bash_trace_id}"
    _otel_bash_log_debug "<trap_debug>" "SOURCE   : ${source_file_name}"
    _otel_bash_log_debug "<trap_debug>" "FUNCTION : ${func_name}"
    _otel_bash_log_debug "<trap_debug>" "LINE     : ${line_no}"
    _otel_bash_log_debug "<trap_debug>" "COMMAND  : ${command}"
    _otel_bash_log_debug "<trap_debug>" "LEVEL    : ${SHLVL}"
    _otel_bash_log_debug "<trap_debug>" "============================"
}

function _otel_bash_trap_return() {
    if [[ "${FUNCNAME[1]}" == "_otel_bash_"* ]] || [[ "${FUNCNAME[1]}" == "otel_bash_"* ]]; then
        return
    fi

    set +T

    local scope_id="${SHLVL}:${BASH_SOURCE[1]}:${FUNCNAME[1]}"
    _otel_bash_remove_scope "$scope_id"
    _otel_bash_remove_parent_scope "$scope_id"

    _otel_bash_log_debug "<trap_return>" "============================"
    _otel_bash_log_debug "<trap_return>" "TRACE ID : ${_otel_bash_trace_id}"
    _otel_bash_log_debug "<trap_return>" "SOURCE   : ${BASH_SOURCE[1]}"
    _otel_bash_log_debug "<trap_return>" "FUNCTION : ${FUNCNAME[1]}"
    _otel_bash_log_debug "<trap_return>" "LINE     : ${BASH_LINENO}"
    _otel_bash_log_debug "<trap_return>" "COMMAND  : ${BASH_COMMAND}"
    _otel_bash_log_debug "<trap_return>" "LEVEL    : ${SHLVL}"
    _otel_bash_log_debug "<trap_return>" "============================"

    set -T
}

function _otel_bash_trap_exit() {
    if [[ "${FUNCNAME[1]}" == "_otel_bash_"* ]] || [[ "${FUNCNAME[1]}" == "otel_bash_"* ]]; then
        return
    fi

    set +T

    local exit_time=$(_otel_bash_now_nanos)
    local scope_id="${SHLVL}:${BASH_SOURCE[1]}:${FUNCNAME[1]}"

    _otel_bash_remove_scope "$scope_id"
    _otel_bash_remove_parent_scope "$scope_id"

    local source_file_name="${BASH_SOURCE[1]}"
    local func_name=""
    local line_no=0
    local command=""
    local parent_span_id="${_otel_bash_parent_span_id}"
    local span_id="${_otel_bash_root_span_id}"
    local start_time=${_otel_bash_root_span_start_time}
    local end_time=${exit_time}
    local return_code=$?

    _otel_bash_report_span \
        "${source_file_name}" \
        "${func_name}" \
        ${line_no} \
        "${command}" \
        "${parent_span_id}" \
        "${span_id}" \
        ${start_time} \
        ${end_time} \
        ${return_code}

    _otel_bash_log_debug "<trap_exit>" "============================="
    _otel_bash_log_debug "<trap_exit>" "TRACE ID : ${_otel_bash_trace_id}"
    _otel_bash_log_debug "<trap_exit>" "SOURCE   : ${BASH_SOURCE[1]}"
    _otel_bash_log_debug "<trap_exit>" "LEVEL    : ${SHLVL}"
    _otel_bash_log_debug "<trap_exit>" "============================="

    set -T
}

################################################################################

##################################### APIS #####################################
################################################################################

function otel_bash_run_script() {
    . "$1" "${@:2}"
}

################################################################################

##################################### INIT #####################################
################################################################################

function _otel_bash_init() {
    set +T

    if [ "$_otel_bash_initialized" = true ]; then
        set -T
        return
    fi

    # By default, log level is "WARN"
    _otel_bash_log_level=$_OTEL_BASH_LOG_LEVEL_WARN

    _otel_bash_trace_id=
    _otel_bash_root_span_id=
    _otel_bash_root_span_start_time=
    _otel_bash_parent_span_id=
    _otel_bash_latest_scope_id=
    _otel_bash_otel_cli_exist=

    # Set log level
    if [ "$OTEL_BASH_LOG_LEVEL" == "DEBUG" ]; then
        _otel_bash_log_level=$_OTEL_BASH_LOG_LEVEL_DEBUG
    elif [ "$OTEL_BASH_LOG_LEVEL" == "INFO" ]; then
        _otel_bash_log_level=$_OTEL_BASH_LOG_LEVEL_INFO
    elif [ "$OTEL_BASH_LOG_LEVEL" == "WARN" ]; then
        _otel_bash_log_level=$_OTEL_BASH_LOG_LEVEL_WARN
    elif [ "$OTEL_BASH_LOG_LEVEL" == "ERROR" ]; then
        _otel_bash_log_level=$_OTEL_BASH_LOG_LEVEL_ERROR
    else
        if [ ! -z "$BASH_LOG_LEVEL" ]; then
            _otel_bash_log "ERROR" "<init>" "Invalid log level: ${BASH_LOG_LEVEL}"
        fi
    fi

    # Set trace id
    if [ -z "$_otel_bash_trace_id" ]; then
        if [ -z "$OTEL_BASH_TRACE_ID" ]; then
            if [ ! -z "$TRACEPARENT" ]; then
                local trace_id=$(_otel_bash_extract_trace_id_from_traceparent "$TRACEPARENT")
                if [ ! -z "$trace_id" ]; then
                    _otel_bash_trace_id=$trace_id
                fi
            fi
        else
            _otel_bash_trace_id=$OTEL_BASH_TRACE_ID
        fi
        if [ -z "$_otel_bash_trace_id" ]; then
            _otel_bash_trace_id=$(_otel_bash_generate_trace_id)
        fi
    fi
    export OTEL_BASH_TRACE_ID="$_otel_bash_trace_id"

    # Set parent span id
    if [ -z "$_otel_bash_parent_span_id" ]; then
        if [ -z "$OTEL_BASH_PARENT_SPAN_ID" ]; then
            if [ ! -z "$TRACEPARENT" ]; then
                local parent_span_id=$(_otel_bash_extract_parent_span_id_from_traceparent "$TRACEPARENT")
                if [ ! -z "$parent_span_id" ]; then
                    _otel_bash_parent_span_id=$parent_span_id
                fi
            fi
        else
            _otel_bash_parent_span_id=$OTEL_BASH_PARENT_SPAN_ID
        fi
        if [ -z "$_otel_bash_parent_span_id" ]; then
            _otel_bash_parent_span_id=""
        fi
    fi

    # Generate root span id
    _otel_bash_root_span_id=$(_otel_bash_generate_span_id)

    # Check whether "otel-cli" is exist to send traces
    if [ -x "$(command -v otel-cli)" ]; then
        _otel_bash_otel_cli_exist=1
        # "_OTEL_BASH" is internal environment variable and 
        # it is set and propagated to child processes/scripts automatically by default.
        # If this environment variable is set, this means that current bash execution is already traced.
        # In this case, no need to start OTEL CLI server again as the server port is already in use. 
        if [ -z "$_OTEL_BASH" ]; then
            local server_port=${OTEL_CLI_SERVER_PORT:-${_DEFAULT_OTEL_CLI_SERVER_PORT}}
            export OTEL_CLI_SERVER_PORT=${server_port}
            # Start OTEL CLI server in background.
            # Note that we don't need to close the server manually 
            # as it shutdowns automatically when this (parent) process exits.
            otel-cli start-server &
        fi    
    else        
        _otel_bash_otel_cli_exist=0
        _otel_bash_log \
            "WARN" "<init>" \
            "'otel-cli' couldn't be found to send traces." \
            "So traces will only be printed to the console."
    fi

    # Init root span start time
    _otel_bash_root_span_start_time=$(_otel_bash_now_nanos)

    export _OTEL_BASH=true

    trap '_otel_bash_trap_debug'   DEBUG
    trap '_otel_bash_trap_return'  RETURN
    trap '_otel_bash_trap_exit'    EXIT

    _otel_bash_initialized=true
    
    set -T
}

################################################################################

_otel_bash_init
