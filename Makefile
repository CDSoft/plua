# This file is part of plua.
#
# plua is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# plua is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with plua.  If not, see <https://www.gnu.org/licenses/>.
#
# For further information about plua you can visit
# http://cdelord.fr/plua

# Default encryption key for the Lua chunks in compiled applications
BUILD = .build

PREFIX := $(firstword $(wildcard $(PREFIX) $(HOME)/.local $(HOME)))

PLUA_VERSION := $(shell git describe --tags 2>/dev/null || echo "⊥")

# PLua library
PLUA_LIB_ZIP = $(BUILD)/lib/plua.zip
PLUA_LIB_LUA = $(BUILD)/lib/plua.lua
PLUA_LIB_SOURCES += lib/F.lua
PLUA_LIB_SOURCES += lib/L.lua
PLUA_LIB_SOURCES += lib/fs.lua
PLUA_LIB_SOURCES += lib/sys.lua
PLUA_LIB_SOURCES += lib/sh.lua
PLUA_LIB_SOURCES += lib/prompt.lua
PLUA_LIB_SOURCES += lib/crypt.lua
PLUA_LIB_SOURCES += lib/argparse.lua
PLUA_LIB_SOURCES += lib/inspect.lua
PLUA_LIB_SOURCES += lib/serpent.lua
PLUA_LIB_SOURCES += $(BUILD)/plua-version.lua

# PLua Library compiler
PLUASLC = pluaslc.lua

# PLua compiler
PLUAC_BIN = $(BUILD)/bin/pluac

# PLua interpreter (REPL)
PLUA_BIN = $(BUILD)/bin/plua
PLUA_SOURCES = plua.lua

ifneq ($(shell which rlwrap 2>/dev/null),)
RLWRAP_ENABLE ?= -r
endif

ARCH := $(shell uname -m)
OS   := $(shell uname -s | tr A-Z a-z)

## Compile and test plua
all: compile
all: test

## Compile plua
compile: $(PLUA_BIN)

## Install plua in $(PREFIX)/bin
install: $(PLUAC_BIN) $(PLUA_LIB_ZIP) $(PLUA_LIB_LUA) $(PLUA_BIN)
	@test -n "$(PREFIX)" || (echo "No installation path found" && false)
	install $(PLUA_BIN) $(PREFIX)/bin/
	install $(PLUAC_BIN) $(PREFIX)/bin/
	install $(PLUA_LIB_ZIP) $(PREFIX)/lib/
	install $(PLUA_LIB_LUA) $(PREFIX)/lib/

## Clean the build directory
clean:
	rm -rf $(BUILD)

include makex.mk

welcome:
	@echo '${CYAN}P${NORMAL}andoc ${CYAN}Lua${NORMAL} interpreter'

###############################################################################
# Third party modules
###############################################################################

.PHONY: update
.PHONY: update-argparse
.PHONY: update-inspect
.PHONY: update-serpent

## Update the source code of third party packages
update: update-argparse
update: update-inspect
update: update-serpent

ARGPARSE_VERSION = master
ARGPARSE_ARCHIVE = argparse-$(ARGPARSE_VERSION).zip
ARGPARSE_URL = https://github.com/mpeterv/argparse/archive/refs/heads/$(ARGPARSE_VERSION).zip

INSPECT_VERSION = master
INSPECT_ARCHIVE = inspect-$(INSPECT_VERSION).zip
INSPECT_URL = https://github.com/kikito/inspect.lua/archive/refs/heads/$(INSPECT_VERSION).zip

SERPENT_VERSION = master
SERPENT_ARCHIVE = serpent-$(SERPENT_VERSION).zip
SERPENT_URL = https://github.com/pkulchenko/serpent/archive/refs/heads/$(SERPENT_VERSION).zip

## Update argparse sources
update-argparse: $(BUILD)/$(ARGPARSE_ARCHIVE)
	unzip -j -o $< '*/argparse.lua' -d lib

$(BUILD)/$(ARGPARSE_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(ARGPARSE_URL) -O $@

## Update inspect sources
update-inspect: $(BUILD)/$(INSPECT_ARCHIVE)
	unzip -j -o $< '*/inspect.lua' -d lib

$(BUILD)/$(INSPECT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(INSPECT_URL) -O $@

## Update serpent sources
update-serpent: $(BUILD)/$(SERPENT_ARCHIVE)
	unzip -j -o $< '*/serpent.lua' -d lib
	sed -i -e 's/(loadstring or load)/load/g'                   \
	       -e '/^ *if setfenv then setfenv(f, env) end *$$/d'   \
	       lib/serpent.lua

$(BUILD)/$(SERPENT_ARCHIVE):
	@mkdir -p $(dir $@)
	wget $(SERPENT_URL) -O $@

###############################################################################
# Compilation
###############################################################################

$(PLUAC_BIN): pluac.lua
	@mkdir -p $(dir $@)
	cp $< $@

$(PLUA_LIB_ZIP): $(PLUASLC) $(PLUA_LIB_SOURCES) | $(PANDOC)
	@mkdir -p $(dir $@)
	./$(PLUASLC) $(PLUA_LIB_SOURCES) -o $@

$(PLUA_LIB_LUA): $(PLUASLC) $(PLUA_LIB_SOURCES) | $(PANDOC)
	@mkdir -p $(dir $@)
	./$(PLUASLC) $(PLUA_LIB_SOURCES) -o $@

$(PLUA_BIN): $(PLUAC_BIN) $(PLUA_SOURCES) $(PLUA_LIB_ZIP) | $(PANDOC)
	@mkdir -p $(dir $@)
	$(PLUAC_BIN) -v $(RLWRAP_ENABLE) $(PLUA_SOURCES) -o $@

$(BUILD)/plua-version.lua: $(wildcard .git/refs/tags) $(wildcard .git/index)
	@mkdir -p $(dir $@)
	@(	set -eu;                                    \
	    echo "-- @RUN";                             \
	    echo "_PLUA_VERSION = \"$(PLUA_VERSION)\""; \
	    echo "return _PLUA_VERSION";                \
	) > $@.tmp
	@mv $@.tmp $@

###############################################################################
# Tests
###############################################################################

.PHONY: test

TESTS_SOURCES := $(sort $(wildcard tests/*.lua))

## Run plua tests
test: $(BUILD)/test-plua.ok

$(BUILD)/test-plua.ok: $(BUILD)/test-plua
	ARCH=$(ARCH) OS=$(OS) $< Pandoc and Lua are great
	@touch $@

$(BUILD)/test-plua: $(PLUAC_BIN) $(TESTS_SOURCES) $(PLUA_LIB_ZIP)
	$(PLUAC_BIN) -v $(TESTS_SOURCES) -o $@

###############################################################################
# Documentation
###############################################################################

.PHONY: doc

## Generate plua documentation (README.md)
doc: README.md

README.md: plua.md $(PLUA_BIN) $(PLUAC_BIN) Makefile | $(PANDA)
	PANDA_TARGET=$@ PANDA_DEP_FILE=$(BUILD)/$(notdir $@).d $(PANDA) -t gfm --toc --toc-depth 2 -s $< -o $@

-include $(BUILD)/*.d
