# Global Instructions

## Behavior
- Be direct and critical. Don't be sycophantic.
- When you're unsure, say so. Don't guess at APIs or library interfaces.
- If a task is complex, plan before coding. Write the plan as comments or a brief outline first.
- Prefer simple solutions. Don't over-engineer.

## Code Style
- Write clear, readable code. Favor explicitness over cleverness.
- Add comments for non-obvious decisions, not for what the code does.
- Use meaningful variable and function names.
- Handle errors explicitly. No silent failures.

## Git & GitHub
- Use `gh` CLI for all GitHub operations (PRs, issues, etc.), not raw API calls.
- Write conventional commit messages: `type(scope): description`
- Never commit directly to main. Use feature branches.

## GCP / Cloud
- Use `gcloud` CLI for GCP operations.
- Never hardcode project IDs, credentials, or secrets in code.
- Use environment variables or Secret Manager for sensitive values.

## Testing
- When adding new functions, write tests.
- Run existing tests before declaring a task complete.
- If tests fail, fix them before moving on.
