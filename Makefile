LIBS         ?= -lib datetime -lib version
HMAIN        ?= suncalc.SunCalc
HFLAGS       ?= -cp src
HFLAGS_BUILD ?= $(HMAIN) $(HFLAGS) -D normal_build $(LIBS)

SRC          ?= $(wildcard src/suncalc/*.hx)
TEST_SRC     ?= $(wildcard test/*)
TEMPLATE_SRC ?= $(wildcard templates/*.j2)

TARGET_SUPPORT_LIBS ?= hxcpp hxjava hxnodejs
DEV_LIBS ?= dox

MAKE_OPTIONS ?= --no-print-directory


.PHONY: default
default: docs

README.md: metainfo.json $(TEMPLATE_SRC) build/doc.xml scripts/template
	scripts/template -i "$<" -t templates/README.md.j2 -d build/doc.xml > "$@"

.PHONY: check
check: test check-diff

## Fix branches of submodules after cloning.
.PHONY: fix-sub-branches
fix-sub-branches:
	cd docs && git checkout gh-pages

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
	for lib in $(TARGET_SUPPORT_LIBS) $(DEV_LIBS); do yes | haxelib install "$$lib"; done

link-hooks: .git/hooks/pre-commit

haxelib.json: metainfo.json scripts/print_haxelib_json_file
	./scripts/print_haxelib_json_file "$<" > "$@"

## Test and build for all supported targets.
.PHONY: all
all: test build dist

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


## haxe {{{
.PHONY: haxe
haxe: build/suncalc_js/suncalc.js

.PHONY: build/suncalc_haxe
build/suncalc_haxe: src/suncalc/SunCalc.hx includes/pre.all README.md haxelib.json
	mkdir --parents "$@/suncalc"
	cat includes/pre.all "$<" > "$@/suncalc/SunCalc.hx"
	cp haxelib.json README.md CONTRIBUTING.md LICENSE.md "$@"

haxe-dist: build/suncalc_haxe
	haxelib submit "$<"

## }}}

## js {{{
.PHONY: js
js: build/suncalc_js/suncalc.js

.PHONY: node
node: js

build/test_suncalc.js: language/js.hxml $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -lib hxnodejs -cp test -main Test -js "$@"
	node "$@"

build/suncalc_js/suncalc.js: language/js.hxml $(SRC) $(TEST_SRC) includes/pre.all includes/js_pre.js includes/js_post.js
	mkdir --parents $(shell dirname $@)
	haxe "$<" $(HFLAGS_BUILD) -js build/suncalc.haxe.js
	cat includes/pre.all includes/js_pre.js build/suncalc.haxe.js includes/js_post.js > "$@"
	@echo 'Run native JS tests from mourner to ensure API compatibility.'
	node test/test.js >/dev/zero

.PHONY: min
min: build/suncalc_js/suncalc.min.js
build/suncalc_js/suncalc.min.js: build/suncalc_js/suncalc.js
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
	@cat includes/pre.all "$@/src/suncalc/SunCalc.java" > "$@/src/suncalc/SunCalc.java.tmp"
	@mv "$@/src/suncalc/SunCalc.java.tmp" "$@/src/suncalc/SunCalc.java"
## }}}

## php {{{
.PHONY: php
php: ports/suncalc-php

build/test_suncalc_php: $(SRC) $(TEST_SRC)
	haxe $(HFLAGS) $(LIBS) -cp test -main Test -php "$@"
	php "$@/index.php"

ports/suncalc-php: $(SRC) includes/pre.all .FORCE
	haxe $(HFLAGS_BUILD) -php "$@"
	@echo '<?php' | cat - includes/pre.all > "$@/lib/suncalc/SunCalc.class.php.tmp"
	@grep --invert-match --fixed-strings '<?php' "$@/lib/suncalc/SunCalc.class.php" >> "$@/lib/suncalc/SunCalc.class.php.tmp"
	@mv "$@/lib/suncalc/SunCalc.class.php.tmp" "$@/lib/suncalc/SunCalc.class.php"
	cp CONTRIBUTING.md LICENSE.md "$@"

ports/suncalc-php/composer.json: metainfo.json scripts/print_composer_json_file
	./scripts/print_composer_json_file "$<" > "$@"

ports/suncalc-php/README.md: metainfo.json $(TEMPLATE_SRC) build/doc.xml scripts/template
	scripts/template -i "$<" -t templates/ports_README.md.j2 -d build/doc.xml --key-value target=php > "$@"

.PHONY: php-dist
php-dist: ports/suncalc-php ports/suncalc-php/composer.json ports/suncalc-php/README.md

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
	@cat includes/pre.all "$@/src/suncalc/SunCalc.cpp" > "$@/src/suncalc/SunCalc.cpp.tmp"
	@mv "$@/src/suncalc/SunCalc.cpp.tmp" "$@/src/suncalc/SunCalc.cpp"
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

.PHONY: docs
docs: build/doc.xml includes/css_post.css README.md
	haxelib run dox -i "$<" -o "$@"
	cat includes/css_post.css >> "$@/styles.css"

.PHONY: test
test: docs
	@echo
	@echo --------Testing JavaScript target.
	@$(MAKE) $(MAKE_OPTIONS) --always-make build/test_suncalc.js build/suncalc_js/suncalc.js
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

.PHONY: dist
dist: php-dist

## All files should be properly rebuild, nothing should be changed.
.PHONY: check-diff
check-diff:
	git submodule foreach "find . -type f -not -iregex '\(.*suncalc.*\|\./\.git.*\)' -print0 | xargs -0 git diff --exit-code"
	git diff --exit-code --ignore-submodules=dirty

.PHONY: push
push: check-diff
	git submodule foreach git push
	git push

.PHONY: .FORCE
.FORCE:

.git/hooks/%: scripts/%-hook
	ln --symbolic --force "../../$<" "$@"
