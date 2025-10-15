# Project Factory (UE Plugin)

Creates a new Unreal Engine plugin project from a template, driven by a freeform prompt.

## Setup
1. Put your UE template at `your-org/ue-plugin-template` (or pass a different template_repo input).
2. Add a secret `FACTORY_ADMIN_TOKEN` (PAT with repo admin in your org).
3. Run the workflow: Actions -> New UE Plugin Project.

## What it does
- Creates repo from the template
- Parses your requirements to extract/derive plugin name and UE version
- **Renames the plugin immediately on main** (from SamplePlugin to your plugin name)
- Applies branch protection rules to main
- Creates an issue with a structured problem statement
- Assigns the issue to GitHub Copilot Coding Agent
- Copilot Agent implements the plugin functionality and opens a PR
- CI in the new repo runs automatically on the PR

## How it works
The workflow:
1. Creates a new repository from the UE plugin template
2. Derives a deterministic plugin name from your requirements (if not explicitly provided)
3. Clones the new repo and runs the rename script directly on main
4. Commits and pushes the rename changes
5. Applies branch protection (requiring PR reviews for future changes)
6. Creates an issue for the GitHub Copilot Coding Agent

The agent then:
1. Implements the plugin functionality based on requirements
2. Updates tests and documentation
3. Opens a PR for review (CI runs automatically)

## Using Requirements Files

For complex plugin specifications, you can store your requirements in markdown files in the `specs/` directory.

### Creating a Requirements File

1. Create a new markdown file in the `specs/` directory (e.g., `specs/my-plugin.md`)
2. Document your plugin requirements (see `specs/example-plugin.md` for a template)
3. Commit and push the file to the factory repo
4. When running the "New UE Plugin Project" workflow:
   - Set `requirements_file` to `specs/my-plugin.md`
   - Leave `requirements` blank (the file takes precedence)

### Inline Requirements (Alternative)

You can still provide requirements directly in the workflow dispatch UI by:
- Leaving `requirements_file` blank
- Filling in the `requirements` field with your specification

The workflow will use `requirements_file` if provided, otherwise it will fall back to the inline `requirements` field.

## Plugin Naming
You can specify the plugin name in three ways:
1. **Explicit input**: Provide a plugin name in the `plugin_name` field (optional)
2. **Pattern in requirements**: Include "plugin called YourName" in your requirements
3. **Auto-derive**: Leave plugin name blank - the factory will derive a PascalCase name from your requirements

The parser will:
- Use the explicit `plugin_name` input if provided
- Extract from "plugin called X" pattern in requirements
- Derive a deterministic name from the requirements title/content (converted to PascalCase alphanumeric)
- Validate the name matches `^[A-Z][A-Za-z0-9]*$`
- Fall back to "NewPlugin" if derivation fails

The plugin is renamed on main immediately after repo creation, so your baseline is clean before any agent work begins.

## Notes
- The parser extracts plugin name and UE version from your requirements
- GitHub Copilot Coding Agent requires appropriate subscription (Pro, Pro+, Business, or Enterprise)
- The agent will create a PR that triggers the template's CI workflow
