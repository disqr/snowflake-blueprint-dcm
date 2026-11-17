"""Render util/templates/manifest.yaml.jinja to manifest.yml at the repo root.

Usage: python util/generate_manifest.py <account_identifier>
"""
import sys
from pathlib import Path

from jinja2 import Environment, FileSystemLoader, StrictUndefined

setup_dir = Path(__file__).resolve().parent
env = Environment(loader=FileSystemLoader(setup_dir / "templates"), undefined=StrictUndefined)
output = env.get_template("manifest.yaml.jinja").render(account_identifier=sys.argv[1])
(setup_dir.parent / "manifest.yml").write_text(output)
print(f"Wrote {setup_dir.parent / 'manifest.yml'}")
