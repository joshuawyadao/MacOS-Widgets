#!/bin/bash
# Parse the structured result returned by notarytool --output-format json.
desktop_widgets_require_accepted_notarization() {
    local response_path="$1" item_name="$2" status
    status="$(/usr/bin/plutil -extract status raw -o - "$response_path" 2>/dev/null)" || status=""
    if [[ "$status" != Accepted ]]; then
        echo "$item_name notarization was not accepted (status: ${status:-unreadable})" >&2
        return 1
    fi
}
