# Reusable Terraform modules

Modules in this directory provide small, composable identity-platform building
blocks. A module must not configure a backend, select an environment, or assume a
pipeline identity. Deployable composition and state ownership belong in
`platform/` or `applications/`.

Every module should document its trust boundary, required caller permissions,
created principals, sensitive outputs, import procedure, and destructive effects.
