# Makefile for keen-auth-permissions

# Detect operating system
ifeq ($(OS),Windows_NT)
	DETECTED_OS := Windows
	DB_GEN_CMD := db-gen-win.exe
else
	DETECTED_OS := $(shell uname -s)
	ifeq ($(DETECTED_OS),Linux)
		DB_GEN_CMD := ./db-gen-linux
	else
		$(error Unsupported operating system: $(DETECTED_OS))
	endif
endif

.PHONY: help setup deps compile test format docs clean generate db-setup db-gen

# Default target
help:
	@echo "Available commands for keen-auth-permissions:"
	@echo ""
	@echo "Setup & Dependencies:"
	@echo "  make setup      - Initial project setup (deps + compile)"
	@echo "  make deps       - Fetch dependencies"
	@echo "  make compile    - Compile the project"
	@echo ""
	@echo "Development:"
	@echo "  make test       - Run tests"
	@echo "  make format     - Format code"
	@echo "  make docs       - Generate documentation"
	@echo "  make clean      - Clean build artifacts"
	@echo ""
	@echo "Database:"
	@echo "  make db-setup   - Set up database (Windows only)"
	@echo "  make db-gen     - Generate Elixir code from PostgreSQL stored procedures"
	@echo "  make generate   - Alias for db-gen (deprecated, use db-gen instead)"
	@echo ""
	@echo "Detected OS: $(DETECTED_OS)"
	@echo "DB Gen Command: $(DB_GEN_CMD)"

# Setup targets
setup: deps compile
	@echo "Project setup completed successfully!"

deps:
	@echo "Fetching dependencies..."
	mix deps.get

compile:
	@echo "Compiling project..."
	mix compile

# Development targets
test:
	@echo "Running tests..."
	mix test

format:
	@echo "Formatting code..."
	mix format

docs:
	@echo "Generating documentation..."
	mix docs

clean:
	@echo "Cleaning build artifacts..."
	mix clean

# Database targets
db-setup:
ifeq ($(DETECTED_OS),Windows)
	@echo "Setting up database..."
	powershell.exe -ExecutionPolicy Bypass -File create-db.ps1
else
	@echo "Database setup script is only available for Windows"
	@echo "Please set up your PostgreSQL database manually"
endif

db-gen:
	@echo "Generating Elixir code from PostgreSQL stored procedures..."
	@echo "Using: $(DB_GEN_CMD)"
ifeq ($(DETECTED_OS),Windows)
	@if exist $(DB_GEN_CMD) ( \
		$(DB_GEN_CMD) generate \
	) else ( \
		echo "Error: $(DB_GEN_CMD) not found. Please ensure the database code generator is available." && exit 1 \
	)
else
	@if [ -f "$(DB_GEN_CMD)" ] && [ -x "$(DB_GEN_CMD)" ]; then \
		$(DB_GEN_CMD) generate; \
	else \
		echo "Error: $(DB_GEN_CMD) not found or not executable. Please ensure the database code generator is available."; \
		exit 1; \
	fi
endif
	@echo "Code generation completed. Don't forget to compile the project:"
	@echo "  make compile"

generate: db-gen
	@echo "Warning: 'make generate' is deprecated. Use 'make db-gen' instead."

# Convenience targets
all: setup test docs
	@echo "Full build completed!"

dev: deps compile
	@echo "Development setup completed!"

# Show current configuration
info:
	@echo "Project: keen-auth-permissions"
	@echo "Operating System: $(DETECTED_OS)"
	@echo "Database Generator: $(DB_GEN_CMD)"
	@echo "Elixir Version: $$(elixir --version | head -n 1)"
	@echo "Mix Version: $$(mix --version)"