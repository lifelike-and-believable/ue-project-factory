# Project Factory (UE Plugin)

Creates a new Unreal Engine plugin project from a template, driven by a freeform prompt.

## Setup
1. Put your UE template at `your-org/ue-plugin-template` (or pass a different template_repo input).
2. Add a secret `FACTORY_ADMIN_TOKEN` (PAT with repo admin in your org).
3. Run the workflow: Actions -> New UE Plugin Project.

## What it does
- Creates repo from the template
- Renames SamplePlugin to your plugin name
- Opens a PR with the scaffold
- CI in the new repo runs automatically

## Notes
- The parser is a stub; replace `scripts/parser.py` with an LLM-backed parser that outputs the same JSON keys.
