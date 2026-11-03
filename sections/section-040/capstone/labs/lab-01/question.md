# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout`, `probe`, `shuttle` and `caller` on Istio. `caller` runs as the `probe` service account. `scout` serves its application on port 9898 (Service port 80) and its metrics on port 9797. The namespace `outpost` runs `drifter`, a client without a sidecar. Today the mesh accepts plain text and every pod can call every workload. Secure `starfleet` with Istio resources, without changing the workloads or `outpost`.

1. `starfleet` must accept only mutual TLS traffic. A request from `drifter` to the application port of `scout`, or to `probe`, must get no HTTP answer.

2. A metrics collector outside the mesh must still read `http://scout.starfleet:9797/metrics` in plain text. Only that port of `scout` may accept plain text.

3. The application port of `scout` must answer only `GET` requests from the `shuttle` service account. A `POST` from `shuttle` and a `GET` from `caller` must get `403`. The metrics port must keep answering `GET` requests from `drifter` with `200`.

4. Create a ConfigMap `mesh-identities` in `starfleet` with the keys `scout` and `probe`. Each value is the identity that is written in the workload certificate of the `istio-proxy` sidecar of that workload.

Do not use `PERMISSIVE` or `DISABLE` for the namespace-wide policy, do not remove the sidecars and do not delete a policy to make a request work. The sidecars need a few seconds to receive a new policy, so run a check again if it still shows the old result.

`kubectl` already points at the cluster. Send test requests with `kubectl exec`, for example `kubectl -n outpost exec deploy/drifter -c drifter -- curl ...`.
