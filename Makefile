SDK_HOME := $(HOME)/Library/Application Support/Garmin/ConnectIQ
SDK_BIN  := $(shell cat "$(SDK_HOME)/current-sdk.cfg")/bin
DEV_KEY  := $(HOME)/Library/ConnectIQ/developer_key.der
DEVICE   := edge540

MONKEYC := "$(SDK_BIN)/monkeyc"
DIST    := dist

.PHONY: build build-power build-heart build-time build-speed package package-power package-heart package-time package-speed dev dev-power dev-heart dev-time dev-speed sim clean help

help:
	@echo "make build           Build all .prg (debug, for simulator)"
	@echo "make build-power     Build FoxPower .prg only"
	@echo "make build-heart     Build FoxHeart .prg only"
	@echo "make build-time      Build FoxTime .prg only"
	@echo "make build-speed     Build FoxSpeed .prg only"
	@echo "make package         Build all .iq (release, for store upload)"
	@echo "make package-power   Build FoxPower .iq only"
	@echo "make package-heart   Build FoxHeart .iq only"
	@echo "make package-time    Build FoxTime .iq only"
	@echo "make package-speed   Build FoxSpeed .iq only"
	@echo ""
	@echo "Package output goes to $(DIST)/"
	@echo "make dev             Build + run FoxPower in simulator"
	@echo "make dev-power       Build + run FoxPower in simulator"
	@echo "make dev-heart       Build + run FoxHeart in simulator"
	@echo "make dev-time        Build + run FoxTime in simulator"
	@echo "make dev-speed       Build + run FoxSpeed in simulator"
	@echo "make sim             Open the Connect IQ Simulator"
	@echo "make clean           Remove build artifacts"

build: build-power build-heart build-time build-speed

build-power: FoxPower/bin/FoxPower.prg
build-heart: FoxHeart/bin/FoxHeart.prg
build-time: FoxTime/bin/FoxTime.prg
build-speed: FoxSpeed/bin/FoxSpeed.prg

FoxPower/bin/FoxPower.prg: $(wildcard FoxPower/source/*.mc) $(wildcard FoxPower/resources/**/*) FoxPower/manifest.xml
	@mkdir -p FoxPower/bin
	$(MONKEYC) -d $(DEVICE) -f FoxPower/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

FoxHeart/bin/FoxHeart.prg: $(wildcard FoxHeart/source/*.mc) $(wildcard FoxHeart/resources/**/*) FoxHeart/manifest.xml
	@mkdir -p FoxHeart/bin
	$(MONKEYC) -d $(DEVICE) -f FoxHeart/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

FoxTime/bin/FoxTime.prg: $(wildcard FoxTime/source/*.mc) $(wildcard FoxTime/resources/**/*) FoxTime/manifest.xml
	@mkdir -p FoxTime/bin
	$(MONKEYC) -d $(DEVICE) -f FoxTime/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

FoxSpeed/bin/FoxSpeed.prg: $(wildcard FoxSpeed/source/*.mc) $(wildcard FoxSpeed/resources/**/*) FoxSpeed/manifest.xml
	@mkdir -p FoxSpeed/bin
	$(MONKEYC) -d $(DEVICE) -f FoxSpeed/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

package: package-power package-heart package-time package-speed

package-power: $(DIST)/FoxPower.iq
package-heart: $(DIST)/FoxHeart.iq
package-time: $(DIST)/FoxTime.iq
package-speed: $(DIST)/FoxSpeed.iq

$(DIST)/FoxPower.iq: $(wildcard FoxPower/source/*.mc) $(wildcard FoxPower/resources/**/*) FoxPower/manifest.xml
	@mkdir -p $(DIST)
	$(MONKEYC) -e -r -O 3z -f FoxPower/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

$(DIST)/FoxHeart.iq: $(wildcard FoxHeart/source/*.mc) $(wildcard FoxHeart/resources/**/*) FoxHeart/manifest.xml
	@mkdir -p $(DIST)
	$(MONKEYC) -e -r -O 3z -f FoxHeart/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

$(DIST)/FoxTime.iq: $(wildcard FoxTime/source/*.mc) $(wildcard FoxTime/resources/**/*) FoxTime/manifest.xml
	@mkdir -p $(DIST)
	$(MONKEYC) -e -r -O 3z -f FoxTime/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

$(DIST)/FoxSpeed.iq: $(wildcard FoxSpeed/source/*.mc) $(wildcard FoxSpeed/resources/**/*) FoxSpeed/manifest.xml
	@mkdir -p $(DIST)
	$(MONKEYC) -e -r -O 3z -f FoxSpeed/monkey.jungle -o $@ -y "$(DEV_KEY)" -w

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

dev-speed: build-speed
	@pgrep -xq simulator || (open "$(SDK_BIN)/ConnectIQ.app" && sleep 3)
	"$(SDK_BIN)/monkeydo" FoxSpeed/bin/FoxSpeed.prg $(DEVICE)

sim:
	open "$(SDK_BIN)/ConnectIQ.app"

clean:
	rm -rf FoxPower/bin FoxHeart/bin FoxTime/bin FoxSpeed/bin $(DIST)
