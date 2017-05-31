
target: build
.PHONY: build

build:
	node ./node_modules/.bin/coffee -o dist/ src/
