#!/usr/bin/python3
"""Flattens om_list.py's Alfred JSON into "title<TAB>arg" lines for the native picker."""
import json, os, subprocess
out = subprocess.run(["/usr/bin/python3", os.path.join(os.path.dirname(__file__), "om_list.py")], capture_output=True, text=True, timeout=10).stdout
for i in json.loads(out).get("items", []):
    print(i["title"] + "\t" + i["arg"])
