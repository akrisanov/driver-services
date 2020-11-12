.PHONY: all test

all:
	docker build . -t zombie_driver:0.1.0

test:
	mix deps.get
	mix test
