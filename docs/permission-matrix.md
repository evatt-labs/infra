# Permission matrix

Complete this table before implementing role assignments. Include important
operations each identity must be unable to perform.

| Principal | Plane | Scope | Allowed | Explicitly excluded | Auth method |
|---|---|---|---|---|---|
| `spn-mghierarchy-prod-001` | Azure | Tenant root MG | MG topology | Subscriptions, policy, RBAC | GitHub FIC |
| `spn-subvending-prod-001` | Billing + Azure | Invoice section + approved MGs | Create/place subscriptions | MG creation, workloads | GitHub FIC |
| `spn-policy-prod-001` | Azure | Evatt Labs MG | Policy definitions/assignments | General resources, RBAC | GitHub FIC |
| `spn-rbac-platform-prod-001` | Azure | Platform MG | Role assignments | Resource deployment | GitHub FIC |
| `spn-rbac-landingzones-prod-001` | Azure | Landing Zones MG | Role assignments | Resource deployment | GitHub FIC |
| `spn-entragroups-prod-001` | Graph | Tenant directory | User lookup/group membership | User mutation, app consent | GitHub FIC |

