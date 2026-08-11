# Azure platform Terraform roots

Each child directory is an independently planned and applied Terraform root with
its own Azure Storage state key and pipeline identity. Cross-stack relationships
must use stable outputs or explicit configuration, not filesystem-relative state.

Numeric prefixes describe dependency order, not permission inheritance.

Workload landing zones are kept in `../applications/` so tenant control-plane
ownership remains distinct from application deployment ownership.

Shared platform services include the Azure DNS zone in `20-shared-services/public-dns`.
Registrar delegation is isolated in `20-shared-services/domain-registration`
because it uses an external control plane and a nameserver change has a much
larger blast radius than an ordinary DNS record change.
