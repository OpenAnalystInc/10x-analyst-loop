#!/usr/bin/env bash
# skill-statusline v2 — JSON parser (no jq, single awk pass)
# Extracts ALL needed fields in one pass for speed on Windows/Git Bash

# ── Bulk parser: extract all fields at once ──
# Sets SL_J_* variables for all known fields
# This avoids spawning 100+ subshells (grep|sed|head per field)
sl_parse_json() {
  eval "$(echo "$input" | awk '
  BEGIN { FS="" }
  {
    s = s $0
  }
  END {
    # Helper: extract "key":value from a string
    # For strings: "key":"value"
    # For numbers: "key":number

    # Top-level strings
    extract_str(s, "cwd")
    extract_str(s, "version")
    extract_str(s, "session_id")

    # model object
    extract_nested_str(s, "model", "id")
    extract_nested_str(s, "model", "display_name")

    # workspace object
    extract_nested_str(s, "workspace", "current_dir")
    extract_nested_str(s, "workspace", "project_dir")

    # cost object
    extract_nested_num(s, "cost", "total_cost_usd")
    extract_nested_num(s, "cost", "total_duration_ms")
    extract_nested_num(s, "cost", "total_api_duration_ms")
    extract_nested_num(s, "cost", "total_lines_added")
    extract_nested_num(s, "cost", "total_lines_removed")

    # context_window object
    extract_nested_num(s, "context_window", "context_window_size")
    extract_nested_num(s, "context_window", "used_percentage")
    extract_nested_num(s, "context_window", "remaining_percentage")
    extract_nested_num(s, "context_window", "total_input_tokens")
    extract_nested_num(s, "context_window", "total_output_tokens")

    # context_window.current_usage (double-nested)
    extract_deep_num(s, "context_window", "current_usage", "input_tokens")
    extract_deep_num(s, "context_window", "current_usage", "output_tokens")
    extract_deep_num(s, "context_window", "current_usage", "cache_creation_input_tokens")
    extract_deep_num(s, "context_window", "current_usage", "cache_read_input_tokens")

    # vim object
    extract_nested_str(s, "vim", "mode")

    # agent object
    extract_nested_str(s, "agent", "name")

    # boolean
    if (match(s, /"exceeds_200k_tokens"[ \t]*:[ \t]*true/)) {
      print "SL_J_exceeds_200k_tokens=true"
    }
  }

  function varname(parts,    r, i) {
    r = "SL_J"
    for (i = 1; i <= length(parts); i++) {
      r = r "_" parts[i]
    }
    return r
  }

  function extract_str(json, key,    pat, val, pos, rest) {
    pat = "\"" key "\"[ \t]*:[ \t]*\""
    if (match(json, pat)) {
      rest = substr(json, RSTART + RLENGTH)
      if (match(rest, /^[^"]*/)) {
        val = substr(rest, 1, RLENGTH)
        gsub(/'\''/, "'\''\\'\'''\''", val)
        print "SL_J_" key "='\''" val "'\''"
      }
    }
  }

  function extract_nested_str(json, parent, key,    pat, block, rest) {
    pat = "\"" parent "\"[ \t]*:[ \t]*\\{"
    if (match(json, pat)) {
      rest = substr(json, RSTART + RLENGTH)
      # Find matching brace (simple: first })
      if (match(rest, /[^}]*/)) {
        block = substr(rest, 1, RLENGTH)
        pat = "\"" key "\"[ \t]*:[ \t]*\""
        if (match(block, pat)) {
          rest = substr(block, RSTART + RLENGTH)
          if (match(rest, /^[^"]*/)) {
            val = substr(rest, 1, RLENGTH)
            gsub(/'\''/, "'\''\\'\'''\''", val)
            print "SL_J_" parent "_" key "='\''" val "'\''"
          }
        }
      }
    }
  }

  function extract_nested_num(json, parent, key,    pat, block, rest, val) {
    pat = "\"" parent "\"[ \t]*:[ \t]*\\{"
    if (match(json, pat)) {
      rest = substr(json, RSTART + RLENGTH)
      # For nested nums, search the full remainder (handles double-nested too)
      block = rest
      pat = "\"" key "\"[ \t]*:[ \t]*"
      if (match(block, pat)) {
        rest = substr(block, RSTART + RLENGTH)
        if (match(rest, /^[0-9.]+/)) {
          val = substr(rest, 1, RLENGTH)
          print "SL_J_" parent "_" key "=" val
        }
      }
    }
  }

  function extract_deep_num(json, p1, p2, key,    pat, outer, inner, rest, val) {
    pat = "\"" p1 "\"[ \t]*:[ \t]*\\{"
    if (match(json, pat)) {
      outer = substr(json, RSTART + RLENGTH)
      pat = "\"" p2 "\"[ \t]*:[ \t]*\\{"
      if (match(outer, pat)) {
        inner = substr(outer, RSTART + RLENGTH)
        pat = "\"" key "\"[ \t]*:[ \t]*"
        if (match(inner, pat)) {
          rest = substr(inner, RSTART + RLENGTH)
          if (match(rest, /^[0-9.]+/)) {
            val = substr(rest, 1, RLENGTH)
            print "SL_J_" p1 "_" p2 "_" key "=" val
          }
        }
      }
    }
  }
  ')"
}

# ── Legacy single-field parsers (for v1 fallback only) ──

json_val() {
  echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 | sed 's/.*:.*"\(.*\)"/\1/'
}

json_num() {
  echo "$input" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*[0-9.]*" | head -1 | sed 's/.*:[[:space:]]*//'
}
