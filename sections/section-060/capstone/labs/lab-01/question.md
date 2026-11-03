# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout` (application port 9898, metrics port 9797, Service port 80 for the application), `probe` (port 8080, Service port 80) and a client `shuttle`. The `outpost` namespace runs a client `drifter` and a server `beacon` that stands for a system outside the application. The `ops` namespace runs a client `collector` that stands for an operations tool. No `NetworkPolicy` exists, so every pod can reach every pod.

Segment the `starfleet` network with `NetworkPolicy` resources in `starfleet`. Do not change the workloads.

1. Isolate every pod in `starfleet` for both incoming and outgoing traffic.

2. Allow `shuttle` to reach `scout` on its application port and `probe` on its port, by name (`http://scout.starfleet/` and `http://probe.starfleet/get` must return `200`). Allow nothing else from `shuttle`.

3. Allow only the `collector` pod in the `ops` namespace to read the metrics port 9797 of `scout`. No other client may read it, and the `collector` may not reach the application port.

4. `drifter` must not reach `scout` or `probe`, and `shuttle` must not reach `beacon`.

Do not delete the default-deny policy. Do not allow all sources or all destinations, and do not use the host network. The network plug-in needs a few seconds to apply a policy, so repeat a check that still shows the old result.

`kubectl` already points at the cluster. Test a path from the client pod, for example `kubectl -n ops exec deploy/collector -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://<scout pod IP>:9797/metrics`. A request that gets no answer prints `000`. Read the pod address with `kubectl -n starfleet get pod -l app=scout -o wide`.
