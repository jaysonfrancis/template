# Copyright (c) All Inc. and affiliates.
# All rights reserved.

import typer

from . import config_manager

app = typer.Typer()
app.command()(config_manager.main)

if __name__ == "__main__":
    app()
