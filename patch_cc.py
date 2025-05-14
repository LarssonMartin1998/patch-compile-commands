#!/usr/bin/env python3
import json, os, shlex, sys, pathlib

extra = os.environ["NIX_CFLAGS_COMPILE"].split()

# Read first argument and use that as path, if none was provided, use build_compile_commands.json as fallback
fallback = pathlib.Path("build/compile_commands.json")
arg_path = sys.argv[1] if len(sys.argv) > 1 else None
path = pathlib.Path(arg_path) if arg_path else fallback

if not path.exists():
    sys.exit(1)

db   = json.loads(path.read_text())

def add_missing(existing: list[str]) -> list[str]:
    present = set(existing)
    return [f for f in extra if f not in present]

for entry in db:
    if "arguments" in entry:
        entry["arguments"][1:1] = add_missing(entry["arguments"])
    else:
        args = shlex.split(entry["command"])
        args[1:1] = add_missing(args)
        entry["command"] = " ".join(map(shlex.quote, args))

path.write_text(json.dumps(db, indent=2))
