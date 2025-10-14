#!/usr/bin/env bash
set -euxo pipefail
ORG="$1"
TEMPLATE="$2"
VISIBILITY="$3"
REQ="$4"
REPO_NAME="${5:-}"

REQ="$REQ" python3 scripts/parser.py > spec.json
PLUGIN=$(jq -r .plugin_name spec.json)
UEVER=$(jq -r .ue_version spec.json)

if [ -z "$REPO_NAME" ]; then
  SLUG=$(echo "$PLUGIN" | tr "[:upper:]" "[:lower:]")
  REPO_NAME="ue-$SLUG"
fi

# Construct the visibility flag properly
VISIBILITY_FLAG="--${VISIBILITY}"
gh repo create "$ORG/$REPO_NAME" "$VISIBILITY_FLAG" --template "$TEMPLATE"
git clone "https://$GH_TOKEN@github.com/$ORG/$REPO_NAME.git"
cd "$REPO_NAME"

# Verify the template structure exists
echo "Verifying template structure..."
if [ ! -d "Plugins/SamplePlugin" ]; then
  echo "ERROR: Template does not contain expected Plugins/SamplePlugin directory"
  echo "Repository structure:"
  ls -la
  if [ -d "Plugins" ]; then
    echo "Plugins directory contents:"
    ls -la Plugins/
  fi
  exit 1
fi

# Verify source directories exist before attempting to rename them
echo "Checking template source directories..."
for dir in "Plugins/SamplePlugin/Source/SamplePlugin" \
           "Plugins/SamplePlugin/Source/SamplePluginEditor" \
           "Plugins/SamplePlugin/Source/SamplePluginTests"; do
  if [ ! -d "$dir" ]; then
    echo "WARNING: Expected directory $dir does not exist, skipping its rename"
  fi
done

# Verify the .uplugin file exists
if [ ! -f "Plugins/SamplePlugin/SamplePlugin.uplugin" ]; then
  echo "ERROR: Template does not contain expected Plugins/SamplePlugin/SamplePlugin.uplugin file"
  echo "SamplePlugin directory contents:"
  ls -la Plugins/SamplePlugin/
  exit 1
fi

# Rename plugin directory
echo "Renaming plugin from SamplePlugin to $PLUGIN..."
mv Plugins/SamplePlugin "Plugins/$PLUGIN"

# Rename source directories if they exist
if [ -d "Plugins/$PLUGIN/Source/SamplePlugin" ]; then
  mv "Plugins/$PLUGIN/Source/SamplePlugin" "Plugins/$PLUGIN/Source/$PLUGIN"
fi

if [ -d "Plugins/$PLUGIN/Source/SamplePluginEditor" ]; then
  mv "Plugins/$PLUGIN/Source/SamplePluginEditor" "Plugins/$PLUGIN/Source/${PLUGIN}Editor"
fi

if [ -d "Plugins/$PLUGIN/Source/SamplePluginTests" ]; then
  mv "Plugins/$PLUGIN/Source/SamplePluginTests" "Plugins/$PLUGIN/Source/${PLUGIN}Tests"
fi

# Rename .uplugin file
mv "Plugins/$PLUGIN/SamplePlugin.uplugin" "Plugins/$PLUGIN/${PLUGIN}.uplugin"

# Verify renaming was successful
echo "Verifying renaming was successful..."
if [ ! -d "Plugins/$PLUGIN" ]; then
  echo "ERROR: Plugin directory Plugins/$PLUGIN was not created successfully"
  exit 1
fi

if [ ! -f "Plugins/$PLUGIN/${PLUGIN}.uplugin" ]; then
  echo "ERROR: Plugin file Plugins/$PLUGIN/${PLUGIN}.uplugin was not created successfully"
  exit 1
fi

# Replace all text references to SamplePlugin with the new plugin name
echo "Replacing text references to SamplePlugin with $PLUGIN..."
# Use -z and xargs -0 to handle filenames with spaces safely
# The || true prevents errors if no files are found
if git grep -l --untracked -z "SamplePlugin" 2>/dev/null | xargs -0 -r sed -i "s/SamplePlugin/$PLUGIN/g" 2>/dev/null; then
  echo "Text replacement completed successfully"
else
  echo "WARNING: No files found containing 'SamplePlugin' to replace"
fi

# Update UE version if ProjectSandbox exists
if [ -f "ProjectSandbox/ProjectSandbox.uproject" ]; then
  sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UEVER\"/g" ProjectSandbox/ProjectSandbox.uproject
else
  echo "WARNING: ProjectSandbox/ProjectSandbox.uproject not found, skipping UE version update"
fi

echo "Scaffolding complete! Creating PR..."
git checkout -b init/scaffold
git add -A
git commit -m "Scaffold $PLUGIN ($UEVER)"
git push -u origin init/scaffold
gh pr create --title "Initialize $PLUGIN" --body "Scaffolded from template via Project Factory." --base main
