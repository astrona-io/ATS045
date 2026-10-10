---
draft: true
exam_objectives:
  - Connectivity
---
# Designing Allowed Paths Without Implicit Trust

Connectivity determines which components can attempt communication. A platform security design should identify application entry paths, service-to-service paths and management paths separately. Private addressing can reduce exposure, but it does not make every reachable caller legitimate.

## Ingress And Application Requests

An external client can reach a load balancer, gateway or other entry implementation. That component routes toward an application backend. Each hop needs an identified listener and route, while transport protection and application permissions provide separate security decisions.

Transport Layer Security (TLS) may terminate at the entry component. If the next hop is plaintext, the encrypted boundary does not automatically extend to the application. Protect another hop when required and state where data can be observed. A secure browser address alone is not evidence about every internal connection.

Forwarding client information through proxies needs a defined trust rule. An application should not accept arbitrary caller-supplied identity or source metadata as authoritative merely because it has a familiar header name. Trusted intermediaries and application verification determine what can be relied upon.

## East-West Communication

Service-to-service traffic can use stable discovery while individual Pods change. NetworkPolicy can restrict supported connections under an enforcing implementation. A service mesh can add peer identity and selected application-level policy. These mechanisms can complement one another but should not be treated as identical controls.

Egress restrictions need to account for Domain Name System (DNS), data stores, registries and other legitimate dependencies. A blanket restriction without the required exceptions can prevent startup or ordinary requests. An overly broad exception can reopen the path the policy intended to narrow. Map destination, protocol and identity requirements explicitly.

Encryption protects bytes on configured paths, while authorization decides permitted operations. A compromised application allowed to call its database can still misuse the granted data role. Segmentation reduces routes; it does not automatically fix business access decisions within a permitted route.

## Management Traffic

application programming interface (API) server, kubelet, datastore and runtime control interfaces carry administrative authority. They should not share the same exposure assumptions as a public web endpoint. Limit reachability to intended components and operators, then enforce trusted identities and appropriate permissions at the interface.

Administrative workstations and automated jobs are part of those paths. A credential stored in a widely accessible build environment can bypass the intent of a narrow external firewall when the job itself has legitimate access. Model the whole caller-to-interface relationship.

## Verifying A Path And Its Limits

A resource declaring routing or policy is only intent until the implementation realizes it. Gateway acceptance, endpoint eligibility and network-policy enforcement provide different observations. A successful connection proves reachability but not every application operation or encryption property.

For a failed dependency, distinguish DNS, route, listener, transport verification and permission. Correct the relevant stage without broadening unrelated access. Verification should use the affected caller and intended operation, because another test location can bypass the actual policy boundary.

A clear connectivity policy states who may reach what, through which implementation and with which identity and protected hops. This gives both students and operators a reviewable contract instead of assuming “internal” means universally trusted.

## Common pitfalls

> [!WARNING]
> Private reachability does not establish authorized identity. Declared routes and policies need implementations, and transport protection must be evaluated for each relevant hop.
