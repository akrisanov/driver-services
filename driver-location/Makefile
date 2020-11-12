.PHONY: all test

all:
	docker build . -t driver_location:0.1.0

test:
	mix deps.get
	mix test
