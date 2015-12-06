LIBS         ?= -lib datetime -lib version
HMAIN        ?= -main SunCalc
HFLAGS       ?= -cp src
HFLAGS_BUILD ?= $(HMAIN) $(HFLAGS) -D normal_build $(LIBS)

SRC      ?= $(wildcard src/*.hx)
TEST_SRC ?= $(wildcard test/*)

TARGET_SUPPORT_LIBS ?= hxcpp hxjava hxnodejs

MAKE_OPTIONS ?= --no-print-directory


.PHONY: default
default: docs

.PHONY: dependencies-get
dependencies-get: haxe-dependencies-get haxe-dependencies-target-get node-dependencies-get

.PHONY: node-dependencies-get
node-dependencies-get: package.json
	npm install

.PHONY: haxe-dependencies-get
haxe-dependencies-get: haxelib.json
	jq '.dependencies | keys | join("\n")' "$<" --raw-output | while read lib; do yes | haxelib install "$$lib"; done

.PHONY: haxe-dependencies-target-get
haxe-dependencies-target-get: Makefile
	for lib in $(TARGET_SUPPORT_LIBS); do yes | haxelib install "$$lib"; done

haxelib.json: metainfo.json scripts/print_haxelib_json_file
	./scripts/print_haxelib_json_file "$<" > "$@"

## Test and build for all supported targets.
.PHONY: all
all: dependencies-get test build

## Build for all supported targets.
.PHONY: build
build: js \
		java \
		php \
		python \
		cpp \
		neko \
		swf \
		as3

.PHONY: clean
clean:
	rm -rf build


## js {{{
.PHONY: js
js: build/suncalc.js

.PHONY: node
node: js

build/test_suncalc.js: language/js.hxml $(SRC) $(TEST_SRC)
	haxe "$<" $(HFLAGS) $(LIBS) -lib hxnodejs -cp test -main Test -js "$@"
	node "$@"

build/suncalc.js: language/js.hxml $(SRC) $(TEST_SRC) includes/pre.all includes/js_pre.js includes/js_post.js
	haxe "$<" $(HFLAGS_BUILD) -js build/suncalc.haxe.js
	cat includes/pre.all includes/js_pre.js build/suncalc.haxe.js includes/js_post.js > "$@"
	@echo 'Run native JS tests from mourner to ensure API compatibility.'
	node test/test.js >/dev/zero

.PHONY: min
min: build/suncalc.min.js
build/suncalc.min.js: build/suncalc.js
	uglifyjs "$<" --output "$@" --comments '/github.com/' --lint
## }}}

## java {{{
.PHONY: java
java: build/suncalc_java

build/test_suncalc_java: $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -cp test -main Test -java "$@"
	java -jar "$@/Test.jar"

.PHONY: build/suncalc_java
build/suncalc_java: $(SRC) includes/pre.all
	haxe $(HFLAGS_BUILD) -java "$@"
	@cat includes/pre.all "$@/src/haxe/root/SunCalc.java" > "$@/src/haxe/root/SunCalc.java.tmp"
	@mv "$@/src/haxe/root/SunCalc.java.tmp" "$@/src/haxe/root/SunCalc.java"
## }}}

## php {{{
.PHONY: php
php: build/suncalc_php

build/test_suncalc_php: $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -cp test -main Test -php "$@"
	php "$@/index.php"

.PHONY: build/suncalc_php
build/suncalc_php: $(SRC) includes/pre.all
	haxe $(HFLAGS_BUILD) -php "$@"
	@echo '<?php' | cat - includes/pre.all > "$@/lib/SunCalc.class.php.tmp"
	@grep --invert-match --fixed-strings '<?php' "$@/lib/SunCalc.class.php" >> "$@/lib/SunCalc.class.php.tmp"
	@mv "$@/lib/SunCalc.class.php.tmp" "$@/lib/SunCalc.class.php"
	cp CONTRIBUTING.md LICENSE.md "$@"


build/suncalc_php/composer.json: metainfo.json scripts/print_haxelib_json_file
	./scripts/print_composer_json_file "$<" > "$@"

build/suncalc_php/README.md: metainfo.json scripts/print_readme
	./scripts/print_readme "$<" PHP > "$@"

.PHONY: php_dist
php_dist: build/suncalc_php build/suncalc_php/composer.json build/suncalc_php/README.md

## }}}

## python {{{
.PHONY: python
python: build/suncalc.py

build/test_suncalc.py: $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -cp test -main Test -python "$@"
	python3 "$@"

build/suncalc.py: $(SRC) includes/pre.all
	haxe $(HFLAGS_BUILD) -python "$@"
## }}}

## cpp {{{
.PHONY: cpp
cpp: build/suncalc_cpp

build/test_suncalc_cpp: $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -cp test -main Test -cpp "$@"
	$@/Test

.PHONY: build/suncalc_cpp
build/suncalc_cpp: $(SRC) includes/pre.all
	haxe $(HFLAGS_BUILD) -cpp "$@"
	@cat includes/pre.all "$@/src/SunCalc.cpp" > "$@/src/SunCalc.cpp.tmp"
	@mv "$@/src/SunCalc.cpp.tmp" "$@/src/SunCalc.cpp"
## }}}

## neko {{{
.PHONY: neko
neko: build/suncalc.n

build/test_suncalc.n: $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -cp test -main Test -neko "$@"
	neko "$@"

build/suncalc.n: $(SRC) includes/pre.all
	haxe $(HFLAGS_BUILD) -neko "$@"
## }}}

## swf {{{
.PHONY: swf
swf: build/suncalc.swf

build/suncalc.swf: $(SRC)
	haxe $(HFLAGS_BUILD) -swf "$@"
## }}}

## as3 {{{
.PHONY: as3
as3: build/suncalc_as3

build/suncalc_as3: $(SRC)
	haxe $(HFLAGS_BUILD) -as3 "$@"
## }}}

## cs {{{
.PHONY: cs
cs: build/suncalc_cs

build/suncalc_cs: $(SRC) includes/pre.all
	haxe $(HFLAGS_BUILD) -cs "$@"
## }}}

build/doc.xml: $(SRC)
	haxe $(HMAIN) $(HFLAGS) $(LIBS) -xml "$@"

docs: build/doc.xml includes/css_post.css
	haxelib run dox -i "$<" -o build/dox
	cat includes/css_post.css >> build/dox/styles.css

.PHONY: test
test: docs
	@echo
	@echo --------Testing JavaScript target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc.js build/suncalc.js
	@echo
	@echo -------- Testing Python target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc.py
	@echo
	@echo --------Testing PHP target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc_php
	@echo
	@echo -------- Testing C++ target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc_cpp
	@echo
	@echo -------- Testing Java target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc_java
	@echo
	@echo -------- Testing Neko target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc.n