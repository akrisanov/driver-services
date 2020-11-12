.PHONY: all test

all:
	docker build . -t gateway:0.1.0

test:
	mix deps.get
	mix test
