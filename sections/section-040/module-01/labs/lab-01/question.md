# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout`, `probe`, `shuttle` and a meshed client `caller`, all with Istio sidecars. `scout` serves its application on port 9898 (Service port 80) and its metrics on port 9797. The namespace `outpost` runs `drifter`, which has no sidecar and sends plain text. Today the mesh accepts plain text for every workload. Change that with Istio resources in `starfleet`. Do not change the workloads and do not touch `outpost`.

1. Require mutual TLS for the whole `starfleet` namespace with a `PeerAuthentication`. A request from `drifter` to the application port of `scout`, or to `probe`, must get no HTTP answer. `shuttle` must still reach `probe`.

2. A metrics collector outside the mesh must still read `http://scout.starfleet:9797/metrics` in plain text. Allow plain text on port 9797 of `scout` only. Port 80 of `scout` and all ports of `probe` stay strict.

3. Create a ConfigMap named `mesh-identities` in `starfleet` with the key `scout`. Its value is the identity that is written in the workload certificate of the `istio-proxy` sidecar of `scout`, in the form `spiffe://...`.

Do not switch the namespace policy to `PERMISSIVE` or `DISABLE`, and do not remove the sidecars. The sidecars need a few seconds to receive a new policy, so run a check again if it still shows the old result.

`kubectl` already points at the cluster. Send test requests with `kubectl exec`, for example `kubectl -n outpost exec deploy/drifter -c drifter -- curl ...`. The `istio-proxy` containers have `curl`.
