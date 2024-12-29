.ONESHELL:

# standardize on bash
SHELL:=/bin/bash
VENV=.venv
VENV_BIN=$(VENV)/bin

# Detect CPU architecture.
ifeq ($(OS),Windows_NT)
    ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		ARCH := amd64
	else ifeq ($(PROCESSOR_ARCHITECTURE),x86)
		ARCH := x86
	else ifeq ($(PROCESSOR_ARCHITECTURE),ARM64)
		ARCH := arm64
	else
		ARCH := unknown
    endif
else
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
		ARCH := amd64
	else ifneq ($(filter %86,$(UNAME_P)),)
		ARCH := x86
	else ifneq ($(filter arm%,$(UNAME_P)),)
		ARCH := arm64
	else
		ARCH := unknown
    endif
endif

# NOTE: maybe we default to pip installl uv in a python3 -m venv?
UV_INSTALL_CMD:=curl -LsSf https://astral.sh/uv/install.sh | sh

# --- Define patterns to clean here ---
CLEAN_DIRS := __pycache__ *.egg-info dist build .pytest_cache .ipynb_checkpoints .ruff_cache
CLEAN_FILES := .DS_Store

.PHONY: install
install: ## Install the virtual environment and install the pre-commit hooks
	@echo "🚀 Creating virtual environment using uv"
	@uv sync
	@uv run pre-commit install

.PHONY: install-uv
install-uv: ## Install uv if it's not already installed
	@echo "🔍 Checking if uv is installed..."
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "🚀 uv not found. Installing uv..."; \
		$(UV_INSTALL_CMD) || { echo "❌ uv installation failed."; exit 1; }; \
		echo "✅ uv installation completed."; \
	else \
		echo "✅ uv is already installed."; \
	fi

.PHONY: check
check: ## Run code quality tools.
	@echo "🚀 Checking lock file consistency with 'pyproject.toml'"
	@uv lock --locked
	@echo "🚀 Linting code: Running pre-commit"
	@uv run pre-commit run -a

.PHONY: test
test: ## Test the code with pytest
	@echo "🚀 Testing code: Running pytest"
	@uv run python -m pytest

.PHONY: build
build: clean-build ## Build wheel file
	@echo "🚀 Creating wheel file"
	@uvx --from build pyproject-build --installer uv

.PHONY: clean-build
clean-build: ## Clean build artifacts
	@echo "🚀 Removing build artifacts"
	@uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

.PHONY: docs-test
docs-test: ## Test if documentation can be built without warnings or errors
	@uv run mkdocs build -s

.PHONY: docs
docs: ## Build and serve the documentation
	@uv run mkdocs serve

.PHONY: clean
clean: ## Remove standard metadata and build artifacts
	@echo "🚀 Cleaning directories..."
	for dir in $(CLEAN_DIRS); do \
		find . -type d -name "$$dir" -exec rm -rf {} +; \
	done
	@echo "🚀 Cleaning files..."
	for file in $(CLEAN_FILES); do \
		find . -type f -name "$$file" -exec rm -rf {} +; \
	done
	@echo "✅ Clean completed."

.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
