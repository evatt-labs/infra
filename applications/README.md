# Application landing zones

Application roots deploy workloads into subscriptions vended and governed by the
Azure platform. Each application owns its own state, deployment identity,
environment promotion, and operational lifecycle.

Applications consume platform outputs and inherited controls; they must not
create management groups, modify tenant policy, vend subscriptions, or grant
themselves additional access.

Public web hosting and its custom-domain binding belong here rather than in the
authoritative DNS root. This keeps application lifecycle changes from owning the
`evattlabs.com` zone or registrar delegation.
