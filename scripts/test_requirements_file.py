#!/usr/bin/env python3
"""
Test suite for requirements file handling with special characters.

This validates the parser's ability to:
- Handle multiline requirements
- Handle requirements with quote marks
- Handle requirements with special characters
"""

import subprocess
import json
import sys
import os
import tempfile

def test_parser_with_file(test_name, requirements_content, env, expected):
    """Run parser test using requirements file and check results"""
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
        f.write(requirements_content)
        req_file = f.name
    
    try:
        test_env = os.environ.copy()
        test_env.update(env)
        test_env['REQUIREMENTS_FILE'] = req_file
        
        result = subprocess.run([sys.executable, 'scripts/parser.py'], 
                               env=test_env,
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
    finally:
        os.unlink(req_file)

# Test suite
tests = [
    # Test with quotes
    ('Quotes: Single quotes in content', 
     "Create a 'special' plugin with 'features'",
     {},
     {'plugin_name': 'Special'}),
    
    ('Quotes: Double quotes in content', 
     'Create a "special" plugin with "features"',
     {},
     {'plugin_name': 'Special'}),
    
    ('Quotes: Mixed quotes', 
     '''Create a "special" plugin with 'advanced' features''',
     {},
     {'plugin_name': 'Special'}),
    
    # Test with multiline
    ('Multiline: Basic multiline requirements', 
     '''# Audio System
Create an audio engine plugin
With multiple features
- Feature 1
- Feature 2''',
     {},
     {'plugin_name': 'AudioEngine'}),  # Parser extracts from "audio engine plugin" pattern
    
    ('Multiline: Complex multiline with quotes', 
     '''# "Advanced" AI Plugin
Create a plugin with "neural" networks
Supporting "multiple" models:
- Model A
- Model B''',
     {},
     {'plugin_name': 'AdvancedAi'}),  # Parser derives from heading, removes non-alphanumeric
    
    # Test with special characters
    ('Special chars: Semicolons', 
     'Create a plugin; with semicolons; for testing',
     {},
     {'plugin_name': 'CreateA'}),  # Parser derives from first extractable pattern
    
    ('Special chars: Ampersands', 
     'Create a data & analytics plugin',
     {},
     {'plugin_name': 'DataAnalytics'}),
    
    ('Special chars: Pipes', 
     'Create a networking | communication plugin',
     {},
     {'plugin_name': 'NetworkingCommunication'}),  # Parser keeps both words after removing special chars
    
    # Test backward compatibility with explicit names
    ('Backward compat: Explicit name with quotes in requirements', 
     'Create a "special" plugin',
     {'PLUGIN_NAME': 'MyPlugin'},
     {'plugin_name': 'MyPlugin'}),
    
    ('Backward compat: Multiline with explicit UE version', 
     '''Create a plugin
For UE 5.4
With multiple features''',
     {'UE_VERSION': '5.5'},
     {'ue_version': '5.5'}),
    
    # Test extraction patterns still work
    ('Pattern: plugin called X with quotes', 
     'Create a "special" plugin called TestPlugin',
     {},
     {'plugin_name': 'TestPlugin'}),
    
    ('Pattern: multiline with plugin called X', 
     '''Create a plugin called AudioEngine
With multiple features:
- Feature 1
- Feature 2''',
     {},
     {'plugin_name': 'AudioEngine'}),
]

def main():
    print('\n=== Requirements File Handling Test Suite ===\n')
    passed = 0
    failed = 0

    for test_name, requirements_content, env, expected in tests:
        if test_parser_with_file(test_name, requirements_content, env, expected):
            passed += 1
        else:
            failed += 1

    print(f'\n=== Test Results ===')
    print(f'Passed: {passed}/{len(tests)}')
    print(f'Failed: {failed}/{len(tests)}')

    if failed > 0:
        sys.exit(1)
    else:
        print('\n✓ All requirements file tests passed!')
        sys.exit(0)

if __name__ == '__main__':
    main()
