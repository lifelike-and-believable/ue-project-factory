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
gh repo create "$ORG/$REPO_NAME" --$VISIBILITY --template "$TEMPLATE"
git clone "https://$GH_TOKEN@github.com/$ORG/$REPO_NAME.git"
cd "$REPO_NAME"

# Replace all occurrences of SamplePlugin with the new plugin name in files first
# (before renaming, so git grep can find tracked files)
if git grep -l "SamplePlugin" > /dev/null; then
  git grep -l "SamplePlugin" | xargs sed -i "s/SamplePlugin/$PLUGIN/g"
fi

# Rename plugin folder
mv Plugins/SamplePlugin "Plugins/$PLUGIN"

# Rename module source files in each directory before renaming the directories
# This ensures files like SamplePlugin.cpp become PluginName.cpp
for module_dir in "Plugins/$PLUGIN/Source/SamplePlugin" "Plugins/$PLUGIN/Source/SamplePluginEditor" "Plugins/$PLUGIN/Source/SamplePluginTests"; do
  if [ -d "$module_dir" ]; then
    module_basename=$(basename "$module_dir")
    # Rename .cpp, .h, and .Build.cs files that match the module name
    for ext in cpp h Build.cs; do
      if [ -f "$module_dir/$module_basename.$ext" ]; then
        new_module_name=$(echo "$module_basename" | sed "s/SamplePlugin/$PLUGIN/g")
        mv "$module_dir/$module_basename.$ext" "$module_dir/$new_module_name.$ext"
      fi
    done
  fi
done

# Rename source folders
mv "Plugins/$PLUGIN/Source/SamplePlugin" "Plugins/$PLUGIN/Source/$PLUGIN"
mv "Plugins/$PLUGIN/Source/SamplePluginEditor" "Plugins/$PLUGIN/Source/${PLUGIN}Editor"
mv "Plugins/$PLUGIN/Source/SamplePluginTests" "Plugins/$PLUGIN/Source/${PLUGIN}Tests"

# Rename .uplugin file
mv "Plugins/$PLUGIN/SamplePlugin.uplugin" "Plugins/$PLUGIN/${PLUGIN}.uplugin"
sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UEVER\"/g" ProjectSandbox/ProjectSandbox.uproject

git checkout -b init/scaffold
git add -A
git commit -m "Scaffold $PLUGIN ($UEVER)"
git push -u origin init/scaffold
gh pr create --title "Initialize $PLUGIN" --body "Scaffolded from template via Project Factory." --base main
