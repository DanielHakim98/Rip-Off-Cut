PHONY: build, clean

PROJECT_NAME := cut

build: $(shell find src -type f)
	gleam run -m gleescript
	@chmod +x ./$(PROJECT_NAME)
	@mkdir -p bin/
	@mv ./$(PROJECT_NAME) ./bin/

clean:
	@rm -r bin/