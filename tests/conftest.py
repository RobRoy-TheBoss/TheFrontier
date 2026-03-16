"""
conftest.py — pytest configuration for The Frontier test suite.
Provides shared fixtures and the DATA_DIR / PROJECT_ROOT paths.
"""
import json
import os
import pathlib
import pytest

PROJECT_ROOT = pathlib.Path(__file__).parent.parent
DATA_DIR = PROJECT_ROOT / "data"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
SCENES_DIR = PROJECT_ROOT / "scenes"
DOC_DIR = PROJECT_ROOT / "doc"


def load_json(relative_path: str) -> dict | list:
    """Load a JSON file from the data directory (flat layout per LLR v0.5.1)."""
    full_path = DATA_DIR / relative_path
    with open(full_path, "r", encoding="utf-8") as f:
        return json.load(f)


@pytest.fixture(scope="session")
def project_root():
    return PROJECT_ROOT


@pytest.fixture(scope="session")
def data_dir():
    return DATA_DIR
