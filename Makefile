# Makefile for an Erlang project using rebar3

# Variables
REBAR = REBAR_GLOBAL_CONFIG_DIR=${HOME} REBAR_CACHE_DIR=${HOME}/.cache/rebar3 rebar3
APPS := $(shell \
  for d in apps/*; do \
    if [ -d "$$d/test" ] && find "$$d/test" -type f -name "*test*.erl" -print -quit | grep -q .; then \
      basename $$d; \
    fi; \
  done \
)


# Default target
all: compile

# Compile the project
compile:
	$(REBAR) compile

compile_test:
	$(REBAR) as test compile

# Clean build artifacts
clean:
	$(REBAR) clean

# Run tests
test: compile_test
	KAZOO_CONFIG=./config/config-test.ini ERL_LIBS=./_build/test/lib/ ./scripts/eunit_run.escript $(APPS)

ct:
	KAZOO_CONFIG=./config/config-test.ini $(REBAR) ct

# Run the project in an Erlang shell
shell:
	$(REBAR) shell

# Run dialyzer for static analysis
dialyzer:
	$(REBAR) dialyzer

# Format the code (if you use the rebar3_format plugin)
format:
	$(REBAR) fmt

tree:
	$(REBAR) tree

# Clean, compile, and run tests in one command
rebuild: clean compile test

# Phony targets to avoid filename conflicts
.PHONY: all compile compile_test clean test shell dialyzer format release run_release stop_release rebuild

