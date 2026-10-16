"""
Privacy Media Vault Backend Service
Manages sandboxed storage for form-check videos and progress photos.
Ensures media files remain isolated from the system gallery using .nomedia protection.
"""

import os
import sys
import json
import time
import shutil
import base64
from pathlib import Path
from typing import Dict, Any, List, Optional


class MediaVaultManager:
    """Handles sandboxed filesystem operations for privacy-focused media attachments."""

    def __init__(self):
        # Resolve sandboxed storage path according to Ubuntu Touch standards
        xdg_data = os.environ.get("XDG_DATA_HOME")
        if xdg_data:
            base_dir = Path(xdg_data)
        else:
            base_dir = Path.home() / ".local" / "share" / "personalfitnessapp.parvathy"

        self.vault_dir = base_dir / "sandboxed_media"
        self._initialize_vault()

    def _initialize_vault(self):
        """Creates the sandboxed directory and sets up .nomedia protection."""
        try:
            self.vault_dir.mkdir(parents=True, exist_ok=True)
            
            # .nomedia prevents Android/Linux media indexers from scanning this folder
            nomedia_file = self.vault_dir / ".nomedia"
            if not nomedia_file.exists():
                with open(nomedia_file, "w") as f:
                    f.write("# Sandboxed Personal Fitness App Media - Do not index into system gallery\n")

            # .trackerignore for Lomiri/Tracker indexing engines
            tracker_file = self.vault_dir / ".trackerignore"
            if not tracker_file.exists():
                with open(tracker_file, "w") as f:
                    f.write("\n")

        except Exception as e:
            print(f"Error initializing media vault directory: {e}", file=sys.stderr)

    def get_vault_path(self) -> str:
        return str(self.vault_dir)

    def save_media_file(self, filename: str, content_bytes: bytes) -> str:
        """Saves raw media bytes into the sandboxed vault and returns the absolute path."""
        target_path = self.vault_dir / filename
        with open(target_path, "wb") as f:
            f.write(content_bytes)
        return str(target_path)

    def delete_media_file(self, filename: str) -> bool:
        """Deletes a file from the sandboxed vault."""
        target_path = self.vault_dir / filename
        if target_path.exists():
            try:
                target_path.unlink()
                return True
            except Exception:
                return False
        return False

    def list_files(self) -> List[Dict[str, Any]]:
        """Lists all media files currently stored in the sandboxed vault."""
        files = []
        if not self.vault_dir.exists():
            return files

        for p in self.vault_dir.iterdir():
            if p.name.startswith("."):
                continue
            stat = p.stat()
            is_video = p.suffix.lower() in [".mp4", ".mov", ".mkv", ".webm"]
            files.append({
                "filename": p.name,
                "path": str(p),
                "size_bytes": stat.st_size,
                "modified": stat.st_mtime,
                "is_video": is_video
            })
        return sorted(files, key=lambda x: x["modified"], reverse=True)
