SDK_HOME := $(HOME)/Library/Application Support/Garmin/ConnectIQ
SDK_BIN  := $(shell cat "$(SDK_HOME)/current-sdk.cfg")/bin
DEV_KEY  := $(HOME)/Library/ConnectIQ/developer_key.der
DEVICE   := edge540

.PHONY: build build-power build-heart build-time dev dev-power dev-heart dev-time sim clean help

help:
	@echo "make build        Build all (FoxPower, FoxHeart, FoxTime)"
	@echo "make build-power  Build FoxPower only"
	@echo "make build-heart  Build FoxHeart only"
	@echo "make build-time   Build FoxTime only"
	@echo "make dev          Build + run FoxPower in simulator"
	@echo "make dev-power    Build + run FoxPower in simulator"
	@echo "make dev-heart    Build + run FoxHeart in simulator"
	@echo "make dev-time     Build + run FoxTime in simulator"
	@echo "make sim          Open the Connect IQ Simulator"
	@echo "make clean        Remove build artifacts"

build: build-power build-heart build-time

build-power: FoxPower/bin/FoxPower.prg
build-heart: FoxHeart/bin/FoxHeart.prg
build-time: FoxTime/bin/FoxTime.prg

FoxPower/bin/FoxPower.prg: $(wildcard FoxPower/source/*.mc) $(wildcard FoxPower/resources/**/*) FoxPower/manifest.xml
	@mkdir -p FoxPower/bin
	"$(SDK_BIN)/monkeyc" -d $(DEVICE) -f FoxPower/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

FoxHeart/bin/FoxHeart.prg: $(wildcard FoxHeart/source/*.mc) $(wildcard FoxHeart/resources/**/*) FoxHeart/manifest.xml
	@mkdir -p FoxHeart/bin
	"$(SDK_BIN)/monkeyc" -d $(DEVICE) -f FoxHeart/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

FoxTime/bin/FoxTime.prg: $(wildcard FoxTime/source/*.mc) $(wildcard FoxTime/resources/**/*) FoxTime/manifest.xml
	@mkdir -p FoxTime/bin
	"$(SDK_BIN)/monkeyc" -d $(DEVICE) -f FoxTime/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

dev: dev-power

dev-power: build-power
	@pgrep -xq simulator || (open "$(SDK_BIN)/ConnectIQ.app" && sleep 3)
	"$(SDK_BIN)/monkeydo" FoxPower/bin/FoxPower.prg $(DEVICE)

dev-heart: build-heart
	@pgrep -xq simulator || (open "$(SDK_BIN)/ConnectIQ.app" && sleep 3)
	"$(SDK_BIN)/monkeydo" FoxHeart/bin/FoxHeart.prg $(DEVICE)

dev-time: build-time
	@pgrep -xq simulator || (open "$(SDK_BIN)/ConnectIQ.app" && sleep 3)
	"$(SDK_BIN)/monkeydo" FoxTime/bin/FoxTime.prg $(DEVICE)

sim:
	open "$(SDK_BIN)/ConnectIQ.app"

clean:
	rm -rf FoxPower/bin FoxHeart/bin FoxTime/bin
