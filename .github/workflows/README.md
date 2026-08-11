# GitHub Actions workflows

Add reusable plan and apply workflows here. Authenticate exclusively through
GitHub OIDC with exact FICs for the normal deployment path. Use protected GitHub
environments for privileged applies and bind FIC subjects to those environments.

Required stages: formatting, validation, linting, policy/security tests, plan,
artifact attestation, approval, apply of the saved plan, and post-apply checks.
Never run privileged applies for workflows originating from forks.

