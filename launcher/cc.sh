#!/bin/zsh
# Command bar "cc": currency conversion, e.g. "cc 100 usd zmw". Ported from the Alfred Currency Converter.
D="${0:A:h}"
export alfred_workflow_cache="$HOME/Library/Caches/command-bar-cc" thousands_group=1
"$D/convert-currency" "$1" 2>/dev/null | /usr/bin/python3 -c '
import json,sys
try: items=json.load(sys.stdin).get("items",[])
except Exception: items=[]
for i in items[:3]: print(i.get("title",""))
'
