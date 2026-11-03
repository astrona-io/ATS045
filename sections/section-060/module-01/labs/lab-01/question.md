# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout` (application port 9898, Service port 80), `probe` (port 8080, Service port 80) and a client `shuttle`. The `outpost` namespace runs a client `drifter` and a server `beacon` that stands for a system outside the application. Every pod can reach every other pod today. Restrict the network with `NetworkPolicy` resources in `starfleet`. Do not change the workloads.

1. Isolate every pod in `starfleet` for incoming traffic. After the change, `drifter` must not reach `scout` or `probe`, and `shuttle` must not reach `probe`.

2. Allow `shuttle`, and only `shuttle`, to reach `scout` on its application port. A request from `shuttle` to `http://scout.starfleet/` must return `200`.

3. Restrict the outgoing traffic of `shuttle`. It may resolve names and reach `scout`. It must not reach `probe` or `beacon`.

Do not delete the default-deny policy. Do not allow all sources or all destinations, and do not use the host network. The network plug-in needs a few seconds to apply a policy, so repeat a check that still shows the old result.

`kubectl` already points at the cluster. Test a path from the affected pod, for example `kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' --max-time 4 http://scout.starfleet/`. A request that gets no answer prints `000`.
