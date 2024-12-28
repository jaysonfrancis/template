# Copyright (c) All Inc. and affiliates.
# All rights reserved.

import yaml
import typer
from pathlib import Path

app = typer.Typer()

@app.command()
def main(configpath: str) -> None:
    if configpath and Path(configpath).is_file():
        print(yaml_reader(configpath))
    else:
        print(f"`configpath` must be valid. Provided: `{configpath}` does not exist.")

def yaml_reader(path: str) -> None:
    try:
        with open(path, 'r') as f:
            data = yaml.load(f, Loader=yaml.FullLoader)
            return data
    except Exception as e:
        print(f"Error reading file: '{e}'")

if __name__ == "__main__":
    app()
