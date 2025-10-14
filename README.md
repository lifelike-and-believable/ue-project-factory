# Project Factory (UE Plugin)

Creates a new Unreal Engine plugin project from a template, driven by a freeform prompt.

## Setup
1. Put your UE template at `your-org/ue-plugin-template` (or pass a different template_repo input).
2. Add a secret `FACTORY_ADMIN_TOKEN` (PAT with repo admin in your org).
3. Run the workflow: Actions -> New UE Plugin Project.

## What it does
- Creates repo from the template
- Parses your requirements to extract plugin name and UE version
- Creates an issue with a structured problem statement
- Assigns the issue to GitHub Copilot Coding Agent
- Copilot Agent implements the plugin and opens a PR
- CI in the new repo runs automatically on the PR

## How it works
The workflow uses GitHub Copilot Coding Agent to implement the plugin based on your requirements. The agent:
1. Renames `SamplePlugin` to your desired plugin name
2. Updates all file paths and references
3. Implements the plugin functionality
4. Ensures tests pass
5. Opens a PR for review

## Notes
- The parser extracts plugin name and UE version from your requirements
- GitHub Copilot Coding Agent requires appropriate subscription (Pro, Pro+, Business, or Enterprise)
- The agent will create a PR that triggers the template's CI workflow
