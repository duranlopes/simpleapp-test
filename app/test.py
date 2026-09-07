"""Finite HTTP smoke test for the deployed application."""

from __future__ import annotations

import os
import sys
import time
import urllib.error
import urllib.request


URL = os.getenv("SMOKE_TEST_URL", "http://127.0.0.1:8008/health")
ATTEMPTS = int(os.getenv("SMOKE_TEST_ATTEMPTS", "10"))
TIMEOUT = float(os.getenv("SMOKE_TEST_TIMEOUT", "3"))
DELAY = float(os.getenv("SMOKE_TEST_DELAY", "2"))


def main() -> int:
    last_error: Exception | None = None
    for attempt in range(1, ATTEMPTS + 1):
        try:
            with urllib.request.urlopen(URL, timeout=TIMEOUT) as response:
                body = response.read().decode("utf-8")
                if response.status == 200:
                    print(f"Smoke test passed: {URL} ({response.status})")
                    return 0
                last_error = RuntimeError(f"unexpected status {response.status}: {body}")
        except (OSError, urllib.error.URLError) as error:
            last_error = error
        if attempt < ATTEMPTS:
            time.sleep(DELAY)

    print(f"Smoke test failed after {ATTEMPTS} attempts: {last_error}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
