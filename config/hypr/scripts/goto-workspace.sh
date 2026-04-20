#!/usr/bin/env bash
# Switch to workspace and reset submap
hyprctl dispatch workspace "$1"
hyprctl dispatch submap reset
