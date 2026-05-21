#!/usr/bin/env bash

set -u

children_pids() {
    local parent_pid="$1"
    ps -o pid= --ppid "$parent_pid" 2>/dev/null | awk '{print $1}'
}

process_tree_pids() {
    local root_pid="$1"
    local -a queue=("$root_pid")
    local index=0

    while (( index < ${#queue[@]} )); do
        local pid="${queue[$index]}"
        index=$((index + 1))

        [[ -n "$pid" ]] || continue
        kill -0 "$pid" 2>/dev/null || continue
        printf '%s\n' "$pid"

        while IFS= read -r child_pid; do
            [[ -n "$child_pid" ]] || continue
            queue+=("$child_pid")
        done < <(children_pids "$pid")
    done
}

rss_kb_for_pid() {
    local pid="$1"
    ps -o rss= -p "$pid" 2>/dev/null | awk '{sum += $1} END {print sum + 0}'
}

pss_kb_for_pid() {
    local pid="$1"
    awk '/^Pss:/{sum += $2} END {print sum + 0}' "/proc/$pid/smaps" 2>/dev/null
}

tree_rss_kb() {
    local root_pid="$1"
    local total=0

    while IFS= read -r pid; do
        local rss
        rss="$(rss_kb_for_pid "$pid")"
        total=$((total + rss))
    done < <(process_tree_pids "$root_pid")

    echo "$total"
}

tree_pss_kb() {
    local root_pid="$1"
    local total=0

    while IFS= read -r pid; do
        local pss
        pss="$(pss_kb_for_pid "$pid")"
        total=$((total + pss))
    done < <(process_tree_pids "$root_pid")

    echo "$total"
}

print_memory_header() {
    printf "  %-18s %10s %10s %s\n" "LABEL" "RSS" "PSS" "PID/TREE"
}

print_memory_sample() {
    local label="$1"
    local root_pid="$2"
    local rss
    local pss

    rss="$(tree_rss_kb "$root_pid")"
    pss="$(tree_pss_kb "$root_pid")"

    printf "  %-18s %7s KB %7s KB  %s\n" "$label" "$rss" "$pss" "$root_pid"
}

monitor_process_tree() {
    local label="$1"
    local root_pid="$2"
    local interval="${3:-10}"
    local peak_rss=0
    local peak_pss=0

    print_memory_header
    while kill -0 "$root_pid" 2>/dev/null; do
        local rss
        local pss

        rss="$(tree_rss_kb "$root_pid")"
        pss="$(tree_pss_kb "$root_pid")"

        if (( rss > peak_rss )); then
            peak_rss="$rss"
        fi
        if (( pss > peak_pss )); then
            peak_pss="$pss"
        fi

        printf "  %-18s %7s KB %7s KB  %s\n" "$label" "$rss" "$pss" "$root_pid"
        sleep "$interval"
    done

    printf "  %-18s %7s KB %7s KB  %s\n" "${label}-peak" "$peak_rss" "$peak_pss" "$root_pid"
}

