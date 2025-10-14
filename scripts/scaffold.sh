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

mv Plugins/SamplePlugin "Plugins/$PLUGIN"
mv "Plugins/$PLUGIN/Source/SamplePlugin" "Plugins/$PLUGIN/Source/$PLUGIN"
mv "Plugins/$PLUGIN/Source/SamplePluginEditor" "Plugins/$PLUGIN/Source/${PLUGIN}Editor"
mv "Plugins/$PLUGIN/Source/SamplePluginTests" "Plugins/$PLUGIN/Source/${PLUGIN}Tests"
mv "Plugins/$PLUGIN/SamplePlugin.uplugin" "Plugins/$PLUGIN/${PLUGIN}.uplugin"

git grep -l "SamplePlugin" | xargs sed -i "s/SamplePlugin/$PLUGIN/g"
sed -i "s/\"EngineAssociation\": \"5.6\"/\"EngineAssociation\": \"$UEVER\"/g" ProjectSandbox/ProjectSandbox.uproject

git checkout -b init/scaffold
git add -A
git commit -m "Scaffold $PLUGIN ($UEVER)"
git push -u origin init/scaffold
gh pr create --title "Initialize $PLUGIN" --body "Scaffolded from template via Project Factory." --base main
