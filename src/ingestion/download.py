"""
Generic download utility.

Downloads a file from a URL and saves it to a local path.
Used by all ingestion scripts (USGS, IEA, Comtrade, etc.).
"""

import hashlib
from pathlib import Path

import requests

from src.db import PROJECT_ROOT


def download_file(url: str, dest_path: Path, force: bool = False) -> Path:
    """
    Download a file from `url` to `dest_path`.

    If the file already exists and `force=False`, skip the download.
    Returns the path to the downloaded file.
    """
    dest_path = Path(dest_path)
    dest_path.parent.mkdir(parents=True, exist_ok=True)

    if dest_path.exists() and not force:
        print(f"[skip] Already exists: {dest_path}")
        return dest_path

    print(f"[download] {url}")
    response = requests.get(url, timeout=60)
    response.raise_for_status()

    dest_path.write_bytes(response.content)
    size_kb = len(response.content) / 1024
    sha = hashlib.sha256(response.content).hexdigest()[:12]
    print(f"[ok] Saved to {dest_path} ({size_kb:.1f} KB, sha256:{sha})")
    return dest_path