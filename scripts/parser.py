# Stub parser that turns requirements into a spec.json-like output.
import os, json, re
req = os.environ.get('REQ','')
name = 'AutoPlugin'
m = re.search(r'plugin\s+called\s+([A-Za-z0-9_]+)', req, re.I)
if m: name = m.group(1)
spec = {'plugin_name': name, 'description': 'Generated from requirements', 'ue_version': '5.6', 'targets': ['Win64'], 'include_gauntlet': True}
print(json.dumps(spec))
