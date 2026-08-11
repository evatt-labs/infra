# Identity architecture

Document every human and workload trust path as issuer, subject, audience,
principal, authorization scope, token lifetime, owner, and revocation procedure.

The production path uses exact GitHub FICs. A flexible-FIC demonstration must be
isolated, labelled preview, and constrained by both repository subject and trusted
reusable-workflow claims.

Human privilege uses PIM. Workload identities retain narrowly scoped standing
access because they cannot activate PIM assignments. Emergency-access accounts
are monitored and excluded from ordinary automation.

