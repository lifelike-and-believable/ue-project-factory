# Stub parser that turns requirements into a spec.json-like output.
import os, json, re
req = os.environ.get('REQ','')
name = os.environ.get('PLUGIN_NAME', '').strip()
ue_version = '5.6'  # Default version

# Extract plugin name
if not name:
    # Try to extract from requirements
    m = re.search(r'plugin\s+called\s+([A-Za-z0-9_]+)', req, re.I)
    if m: 
        name = m.group(1)
    else:
        name = 'TBD'

# Extract UE version if mentioned (e.g., "UE 5.5", "UE5.4", "Unreal Engine 5.3", etc.)
ue_match = re.search(r'(?:UE|Unreal\s+Engine)\s*(\d+\.\d+)', req, re.I)
if ue_match:
    ue_version = ue_match.group(1)

spec = {'plugin_name': name, 'description': 'Generated from requirements', 'ue_version': ue_version, 'targets': ['Win64'], 'include_gauntlet': True}
print(json.dumps(spec))
