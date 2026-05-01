#!/bin/bash

set -euo pipefail

ROOT_DIR="${SRCROOT:-$(pwd)}"
PROJECT_FILE="$ROOT_DIR/SkyPresenterPro.xcodeproj/project.pbxproj"

critical_count=0
warning_count=0

declare -a critical_messages=()
declare -a warning_messages=()

emit_warning() {
    local path="$1"
    local line="$2"
    local message="$3"
    printf '%s:%s: warning: %s\n' "$path" "$line" "$message"
    warning_count=$((warning_count + 1))
    warning_messages+=("$path:$line: $message")
}

emit_error() {
    local path="$1"
    local line="$2"
    local message="$3"
    printf '%s:%s: error: %s\n' "$path" "$line" "$message"
    critical_count=$((critical_count + 1))
    critical_messages+=("$path:$line: $message")
}

info() {
    printf 'audit_project: %s\n' "$1"
}

safe_find_swift_files() {
    find "$ROOT_DIR" \
        \( -path "$ROOT_DIR/.git" -o \
           -path "$ROOT_DIR/.build" -o \
           -path "$ROOT_DIR/DerivedData" -o \
           -path "$ROOT_DIR/build" -o \
           -path "$ROOT_DIR/SkyPresenterPro.app" -o \
           -path "$ROOT_DIR/HTTPPortBridgeHelper" -o \
           -path "$ROOT_DIR/SkyPresenterProTests.xctest" -o \
           -path "$ROOT_DIR/SkyPresenterPro.xcodeproj" \) -prune \
        -o -type f -name '*.swift' -print
}

safe_find_all_files() {
    find "$ROOT_DIR" \
        \( -path "$ROOT_DIR/.git" -o \
           -path "$ROOT_DIR/.build" -o \
           -path "$ROOT_DIR/DerivedData" -o \
           -path "$ROOT_DIR/build" -o \
           -path "$ROOT_DIR/SkyPresenterPro.app" -o \
           -path "$ROOT_DIR/SkyPresenterProTests.xctest" \) -prune \
        -o -type f -print
}

grep_with_line_numbers() {
    local pattern="$1"
    local path="$2"
    grep -nE "$pattern" "$path" || true
}

check_required_project_file() {
    if [[ ! -f "$PROJECT_FILE" ]]; then
        emit_error "$ROOT_DIR" "1" "No se encontró project.pbxproj en la ruta esperada: $PROJECT_FILE"
    fi
}

check_swift_copy_suffixes() {
    while IFS= read -r file; do
        emit_error "$file" "1" "Archivo Swift duplicado con sufijo (1). Renómbralo o elimínalo."
    done < <(find "$ROOT_DIR" -type f -name '*(1).swift' -print)
}

check_duplicate_swift_basenames() {
    local duplicate_report
    duplicate_report="$(
        safe_find_swift_files \
        | awk '
            {
                n = split($0, parts, "/")
                name = parts[n]
                count[name]++
                paths[name] = paths[name] ORS $0
            }
            END {
                for (name in count) {
                    if (count[name] > 1) {
                        printf "%s", name
                        printf "%s", paths[name]
                        printf "\n--\n"
                    }
                }
            }
        '
    )"

    [[ -z "$duplicate_report" ]] && return

    local current_name=""
    local current_paths=()
    while IFS= read -r line; do
        if [[ "$line" == "--" ]]; then
            if [[ -n "$current_name" && ${#current_paths[@]} -gt 0 ]]; then
                emit_error "${current_paths[0]}" "1" "Basename Swift duplicado detectado: $current_name"
                for path in "${current_paths[@]:1}"; do
                    emit_error "$path" "1" "Basename Swift duplicado detectado: $current_name"
                done
            fi
            current_name=""
            current_paths=()
        elif [[ -z "$current_name" ]]; then
            current_name="$line"
        elif [[ -n "$line" ]]; then
            current_paths+=("$line")
        fi
    done <<< "$duplicate_report"
}

check_pbxproj_critical_references() {
    [[ -f "$PROJECT_FILE" ]] || return

    local agents_refs
    agents_refs="$(grep_with_line_numbers 'AGENTS\.md in Resources|path = AGENTS\.md;' "$PROJECT_FILE")"
    if [[ -n "$agents_refs" ]]; then
        while IFS=: read -r line_no _; do
            emit_error "$PROJECT_FILE" "$line_no" "AGENTS.md aparece referenciado en el proyecto; no debe entrar al bundle ni a Resources."
        done <<< "$agents_refs"
    fi

    local backup_refs
    backup_refs="$(grep_with_line_numbers '\.(bak|save)' "$PROJECT_FILE")"
    if [[ -n "$backup_refs" ]]; then
        while IFS=: read -r line_no _; do
            emit_error "$PROJECT_FILE" "$line_no" "Se encontró una referencia .bak o .save dentro de project.pbxproj."
        done <<< "$backup_refs"
    fi
}

check_temp_artifacts() {
    while IFS= read -r file; do
        emit_warning "$file" "1" "Archivo temporal detectado en el repositorio."
    done < <(safe_find_all_files | grep -E '/\.DS_Store$|\.bak$|\.save$' || true)
}

check_slide_state_warnings() {
    local file
    while IFS= read -r file; do
        [[ "$file" == *"/LivePresentationEngine.swift" ]] && continue

        local matches
        matches="$(grep_with_line_numbers '\b(currentSlide|nextSlide)\b' "$file")"
        [[ -z "$matches" ]] && continue

        while IFS=: read -r line_no _; do
            emit_warning "$file" "$line_no" "Estado slide detectado fuera de LivePresentationEngine. Revisar si duplica runtime."
        done <<< "$matches"
    done < <(safe_find_swift_files)
}

check_projection_command_warnings() {
    local file
    while IFS= read -r file; do
        local current_matches
        current_matches="$(grep_with_line_numbers '\bprojectCurrent\b' "$file")"
        if [[ -n "$current_matches" ]]; then
            while IFS=: read -r line_no _; do
                emit_warning "$file" "$line_no" "Uso de projectCurrent detectado. Confirmar que pasa por LivePresentationEngine."
            done <<< "$current_matches"
        fi

        local prepared_matches
        prepared_matches="$(grep_with_line_numbers '\bprojectPrepared[a-zA-Z]*\b' "$file")"
        if [[ -n "$prepared_matches" ]]; then
            while IFS=: read -r line_no _; do
                emit_warning "$file" "$line_no" "Uso de projectPrepared detectado. Confirmar que no bypassa el engine."
            done <<< "$prepared_matches"
        fi
    done < <(safe_find_swift_files)
}

check_render_text_warnings() {
    local file
    while IFS= read -r file; do
        local matches
        matches="$(grep_with_line_numbers 'Text\(' "$file")"
        [[ -z "$matches" ]] && continue

        while IFS=: read -r line_no _; do
            emit_warning "$file" "$line_no" "Uso directo de Text() en render crítico. Validar consistencia con TextRenderEngine."
        done <<< "$matches"
    done < <(find "$ROOT_DIR/SkyPresenterPro/Core/Projection" -type f -name '*.swift' -print 2>/dev/null || true)
}

check_secret_warnings() {
    local file
    while IFS= read -r file; do
        local matches
        matches="$(grep_with_line_numbers '(api[_-]?key|secret|token|password)[[:space:]]*[:=]' "$file")"
        [[ -z "$matches" ]] && continue

        while IFS=: read -r line_no _; do
            emit_warning "$file" "$line_no" "Posible secret o credencial en texto plano. Revisar este archivo."
        done <<< "$matches"
    done < <(safe_find_all_files | grep -Ev '/AGENTS\.md$|/project\.pbxproj$|/Scripts/' || true)
}

print_summary() {
    info "Resumen: $critical_count error(es) crítico(s), $warning_count warning(s)."

    if (( critical_count > 0 )); then
        info "Errores críticos detectados:"
        for message in "${critical_messages[@]}"; do
            printf '  - %s\n' "$message"
        done
    fi

    if (( warning_count > 0 )); then
        info "Warnings detectados:"
        for message in "${warning_messages[@]}"; do
            printf '  - %s\n' "$message"
        done
    fi
}

main() {
    info "Iniciando auditoría local en: $ROOT_DIR"
    check_required_project_file
    check_swift_copy_suffixes
    check_duplicate_swift_basenames
    check_pbxproj_critical_references
    check_temp_artifacts
    check_slide_state_warnings
    check_projection_command_warnings
    check_render_text_warnings
    check_secret_warnings
    print_summary

    if (( critical_count > 0 )); then
        exit 1
    fi
}

main "$@"
