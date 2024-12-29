.ONESHELL:

# standardize on bash
SHELL := /bin/bash

UV_INSTALL_CMD := curl -LsSf https://astral.sh/uv/install.sh | sh

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
	@echo "🚀 Static type checking: Running mypy"
	@uv run mypy
	@echo "🚀 Checking for obsolete dependencies: Running deptry"
	@uv run deptry .

.PHONY: test
test: ## Test the code with pytest
	@echo "🚀 Testing code: Running pytest"
	@uv run python -m pytest --cov --cov-config=pyproject.toml --cov-report=xml

.PHONY: build
build: clean-build ## Build wheel file
	@echo "🚀 Creating wheel file"
	@uvx --from build pyproject-build --installer uv

.PHONY: clean-build
clean-build: ## Clean build artifacts
	@echo "🚀 Removing build artifacts"
	@uv run python -c "import shutil; import os; shutil.rmtree('dist') if os.path.exists('dist') else None"

.PHONY: publish
publish: ## Publish a release to PyPI.
	@echo "🚀 Publishing."
	@uvx twine upload --repository-url https://upload.pypi.org/legacy/ dist/*

.PHONY: build-and-publish
build-and-publish: build publish ## Build and publish.

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

.PHONY: dry-clean
dry-clean: ## Show what would be cleaned without actually removing files
	@echo "🔍 Dry run: Listing directories to be cleaned..."
	for dir in $(CLEAN_DIRS); do \
		find . -type d -name "$$dir"; \
	done
	@echo "🔍 Dry run: Listing files to be cleaned..."
	for file in $(CLEAN_FILES); do \
		find . -type f -name "$$file"; \
	done

.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
