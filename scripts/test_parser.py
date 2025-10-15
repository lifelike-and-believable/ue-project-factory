#!/usr/bin/env python3
"""
Test suite for the parser script.

This validates the parser's ability to:
- Extract explicit plugin names
- Parse "plugin called X" patterns
- Derive plugin names from requirements text
- Validate plugin names against UE conventions
- Handle UE version inputs and extraction
"""

import subprocess
import json
import sys

def test_parser(test_name, env, expected):
    """Run parser test and check results"""
    result = subprocess.run([sys.executable, 'scripts/parser.py'], 
                           env=env,
                           capture_output=True, text=True)
    if result.returncode != 0:
        print(f'✗ {test_name}: Parser failed with error: {result.stderr}')
        return False
    
    try:
        spec = json.loads(result.stdout.strip())
    except json.JSONDecodeError as e:
        print(f'✗ {test_name}: Invalid JSON output: {e}')
        return False
    
    # Check expectations
    passed = True
    for key, value in expected.items():
        if spec.get(key) != value:
            print(f'✗ {test_name}: Expected {key}={value}, got {spec.get(key)}')
            passed = False
    
    if passed:
        print(f'✓ {test_name}')
    return passed

# Test suite
tests = [
    # Explicit plugin name tests
    ('Explicit plugin name', 
     {'REQ': 'Create a plugin', 'PLUGIN_NAME': 'MyPlugin'}, 
     {'plugin_name': 'MyPlugin', 'ue_version': '5.6'}),
    
    # Pattern extraction tests
    ('Pattern: plugin called X (PascalCase)', 
     {'REQ': 'Create a plugin called TestPlugin'}, 
     {'plugin_name': 'TestPlugin'}),
    
    ('Pattern: plugin called X (with hyphens)', 
     {'REQ': 'plugin called Test-Plugin'}, 
     {'plugin_name': 'TestPlugin'}),
    
    ('Pattern: plugin called X (with underscores)', 
     {'REQ': 'plugin called my_cool_plugin'}, 
     {'plugin_name': 'MyCoolPlugin'}),
    
    ('Pattern: plugin called X (mixed case)', 
     {'REQ': 'plugin called AUDIO_MIXER'}, 
     {'plugin_name': 'AudioMixer'}),
    
    # Derivation tests
    ('Derive: markdown heading', 
     {'REQ': '# Audio Engine\nCreate an audio engine'}, 
     {'plugin_name': 'AudioEngine'}),
    
    ('Derive: create pattern', 
     {'REQ': 'create a physics simulation plugin'}, 
     {'plugin_name': 'PhysicsSimulation'}),
    
    ('Derive: build pattern', 
     {'REQ': 'build an advanced AI plugin'}, 
     {'plugin_name': 'AdvancedAi'}),
    
    ('Derive: implement pattern', 
     {'REQ': 'implement a networking layer plugin'}, 
     {'plugin_name': 'NetworkingLayer'}),
    
    ('Derive: from first line', 
     {'REQ': 'Some Clear Title\nWith details below'}, 
     {'plugin_name': 'SomeClearTitle'}),
    
    ('Derive: complex pattern', 
     {'REQ': 'Create an ai-powered plugin for games'}, 
     {'plugin_name': 'AiPowered'}),
    
    # Fallback tests
    ('Fallback: empty requirements', 
     {'REQ': ''}, 
     {'plugin_name': 'NewPlugin'}),
    
    ('Fallback: no extractable name', 
     {'REQ': 'Just some random text'}, 
     {'plugin_name': 'JustSomeRandomText'}),
    
    # UE version tests
    ('UE version: from requirements (format: UE 5.4)', 
     {'REQ': 'Create a plugin for UE 5.4'}, 
     {'ue_version': '5.4'}),
    
    ('UE version: from requirements (format: Unreal Engine 5.3)', 
     {'REQ': 'Create a plugin for Unreal Engine 5.3'}, 
     {'ue_version': '5.3'}),
    
    ('UE version: explicit input overrides requirements', 
     {'REQ': 'Create a plugin for UE 5.4', 'UE_VERSION': '5.5'}, 
     {'ue_version': '5.5'}),
    
    ('UE version: explicit input with no mention in requirements', 
     {'REQ': 'Create a plugin', 'UE_VERSION': '5.3'}, 
     {'ue_version': '5.3'}),
    
    ('UE version: default when not specified', 
     {'REQ': 'Create a plugin'}, 
     {'ue_version': '5.6'}),
]

def main():
    print('\n=== Running Parser Test Suite ===\n')
    passed = 0
    failed = 0

    for test_name, env, expected in tests:
        if test_parser(test_name, env, expected):
            passed += 1
        else:
            failed += 1

    print(f'\n=== Test Results ===')
    print(f'Passed: {passed}/{len(tests)}')
    print(f'Failed: {failed}/{len(tests)}')

    if failed > 0:
        sys.exit(1)
    else:
        print('\n✓ All tests passed!')
        sys.exit(0)

if __name__ == '__main__':
    main()
