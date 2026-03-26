#!/usr/bin/env fish

set CLASS "quake"
# Get client info from hyprctl's JSON output
set CLIENT (hyprctl -j clients | jq ".[] | select(.class==\"$CLASS\")")

# Check if the client exists
if test -z "$CLIENT"
    # If not running, launch it.
    # Your hyprland config should handle the initial launch with exec-once,
    # but this makes the script more robust if the window is closed.
    foot -a "$CLASS" &
else
    set WORKSPACE_ID (echo "$CLIENT" | jq ".workspace.id")
    set ACTIVE_WORKSPACE_ID (hyprctl -j activeworkspace | jq ".id")

    # If the window is on the active workspace, move it to special.
    # Otherwise, bring it to the active workspace and focus it.
    if test "$WORKSPACE_ID" = "$ACTIVE_WORKSPACE_ID"
        hyprctl dispatch movetoworkspacesilent special,\"class:^$CLASS$\""
    else
        hyprctl dispatch movetoworkspace "$ACTIVE_WORKSPACE_ID","class:^$CLASS$"
        hyprctl dispatch focuswindow "class:^$CLASS$"
    end
end
