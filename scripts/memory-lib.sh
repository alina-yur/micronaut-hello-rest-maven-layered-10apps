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

smaps_file_for_pid() {
    local pid="$1"
    local smaps_rollup="/proc/$pid/smaps_rollup"
    local smaps="/proc/$pid/smaps"

    if [[ -r "$smaps_rollup" ]]; then
        echo "$smaps_rollup"
    else
        echo "$smaps"
    fi
}

rss_kb_for_pid() {
    local pid="$1"
    local rss

    read -r rss _ _ < <(memory_kb_for_pid "$pid")
    echo "${rss:-0}"
}

uss_kb_for_pid() {
    local pid="$1"
    local uss

    read -r _ uss _ < <(memory_kb_for_pid "$pid")
    echo "${uss:-0}"
}

pss_kb_for_pid() {
    local pid="$1"
    local pss

    read -r _ _ pss < <(memory_kb_for_pid "$pid")
    echo "${pss:-0}"
}

memory_kb_for_pid() {
    local pid="$1"
    local smaps_file

    smaps_file="$(smaps_file_for_pid "$pid")"
    if [[ -r "$smaps_file" ]]; then
        awk '
            /^Rss:/ { rss += $2 }
            /^Private_(Clean|Dirty|Hugetlb):/ { uss += $2 }
            /^Pss:/ { pss += $2 }
            END { printf "%d %d %d\n", rss + 0, uss + 0, pss + 0 }
        ' "$smaps_file" 2>/dev/null || echo "0 0 0"
    else
        local rss
        rss="$(ps -o rss= -p "$pid" 2>/dev/null | awk '{sum += $1} END {print sum + 0}')"
        printf "%d %d %d\n" "${rss:-0}" 0 0
    fi
}

tree_memory_kb() {
    local root_pid="$1"
    local total_rss=0
    local total_uss=0
    local total_pss=0

    while IFS= read -r pid; do
        local rss
        local uss
        local pss

        read -r rss uss pss < <(memory_kb_for_pid "$pid")
        total_rss=$((total_rss + ${rss:-0}))
        total_uss=$((total_uss + ${uss:-0}))
        total_pss=$((total_pss + ${pss:-0}))
    done < <(process_tree_pids "$root_pid")

    printf "%d %d %d\n" "$total_rss" "$total_uss" "$total_pss"
}

tree_rss_kb() {
    local root_pid="$1"
    local rss

    read -r rss _ _ < <(tree_memory_kb "$root_pid")
    echo "${rss:-0}"
}

tree_uss_kb() {
    local root_pid="$1"
    local uss

    read -r _ uss _ < <(tree_memory_kb "$root_pid")
    echo "${uss:-0}"
}

tree_pss_kb() {
    local root_pid="$1"
    local pss

    read -r _ _ pss < <(tree_memory_kb "$root_pid")
    echo "${pss:-0}"
}

print_memory_header() {
    printf "  %-18s %10s %10s %10s %s\n" "LABEL" "RSS" "USS" "PSS" "PID/TREE"
}

print_memory_sample() {
    local label="$1"
    local root_pid="$2"
    local rss
    local uss
    local pss

    read -r rss uss pss < <(tree_memory_kb "$root_pid")

    printf "  %-18s %7s KB %7s KB %7s KB  %s\n" "$label" "$rss" "$uss" "$pss" "$root_pid"
}

monitor_process_tree() {
    local label="$1"
    local root_pid="$2"
    local interval="${3:-10}"
    local peak_rss=0
    local peak_uss=0
    local peak_pss=0

    print_memory_header
    while kill -0 "$root_pid" 2>/dev/null; do
        local rss
        local uss
        local pss

        read -r rss uss pss < <(tree_memory_kb "$root_pid")

        if (( rss > peak_rss )); then
            peak_rss="$rss"
        fi
        if (( uss > peak_uss )); then
            peak_uss="$uss"
        fi
        if (( pss > peak_pss )); then
            peak_pss="$pss"
        fi

        printf "  %-18s %7s KB %7s KB %7s KB  %s\n" "$label" "$rss" "$uss" "$pss" "$root_pid"
        sleep "$interval"
    done

    printf "  %-18s %7s KB %7s KB %7s KB  %s\n" "${label}-peak" "$peak_rss" "$peak_uss" "$peak_pss" "$root_pid"
}
