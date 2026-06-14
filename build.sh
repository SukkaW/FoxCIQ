#!/bin/bash
set -euo pipefail

SDK_HOME="$HOME/Library/Application Support/Garmin/ConnectIQ"
SDK_BIN="$(cat "$SDK_HOME/current-sdk.cfg")/bin"
DEV_KEY="$HOME/Library/ConnectIQ/developer_key.der"
DEVICE="edge540"

if [ ! -f "$DEV_KEY" ]; then
    echo "Error: Developer key not found at $DEV_KEY"
    exit 1
fi

build_project() {
    local project="$1"
    local dir="$(cd "$(dirname "$0")" && pwd)/$project"

    if [ ! -f "$dir/monkey.jungle" ]; then
        echo "Error: $dir/monkey.jungle not found"
        exit 1
    fi

    mkdir -p "$dir/bin"
    echo "Building $project for $DEVICE..."
    "$SDK_BIN/monkeyc" \
        -d "$DEVICE" \
        -f "$dir/monkey.jungle" \
        -o "$dir/bin/$project.prg" \
        -y "$DEV_KEY" \
        -w
    echo "Built: $dir/bin/$project.prg"
}

run_project() {
    local project="$1"
    local dir="$(cd "$(dirname "$0")" && pwd)/$project"
    local prg="$dir/bin/$project.prg"

    if [ ! -f "$prg" ]; then
        echo "Error: $prg not found. Build first."
        exit 1
    fi

    echo "Launching simulator with $project..."
    "$SDK_BIN/monkeydo" "$prg" "$DEVICE"
}

case "${1:-}" in
    power)
        build_project "FoxPower"
        ;;
    heart)
        build_project "FoxHeart"
        ;;
    all)
        build_project "FoxPower"
        build_project "FoxHeart"
        ;;
    run-power)
        build_project "FoxPower"
        run_project "FoxPower"
        ;;
    run-heart)
        build_project "FoxHeart"
        run_project "FoxHeart"
        ;;
    sim)
        echo "Starting Connect IQ Simulator..."
        open "$SDK_BIN/ConnectIQ.app"
        ;;
    *)
        echo "Usage: $0 {power|heart|all|run-power|run-heart|sim}"
        echo ""
        echo "  power      - Build FoxPower"
        echo "  heart      - Build FoxHeart"
        echo "  all        - Build both"
        echo "  run-power  - Build + run FoxPower in simulator"
        echo "  run-heart  - Build + run FoxHeart in simulator"
        echo "  sim        - Open the Connect IQ Simulator"
        exit 1
        ;;
esac
