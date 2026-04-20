#!/usr/bin/env bash
# Wrapper for nwg-displays that saves to monitors-local.conf
# This ensures your monitor settings survive updates

exec nwg-displays -m ~/.config/hypr/monitors-local.conf "$@"
