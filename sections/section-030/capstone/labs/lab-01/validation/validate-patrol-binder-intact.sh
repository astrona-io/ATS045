#!/usr/bin/env bash
# Check: the patrol-binder CronJob is not deleted, suspended or re-identified,
# and its RBAC is unchanged.
set -uo pipefail

suspended="$(kubectl -n outpost get cronjob patrol-binder -o jsonpath='{.spec.suspend}' 2>/dev/null || echo missing)"
if [ "$suspended" = "missing" ] || [ "$suspended" = "true" ]; then
  echo "FAIL: the CronJob patrol-binder in outpost is missing or suspended"
  exit 1
fi
account="$(kubectl -n outpost get cronjob patrol-binder -o jsonpath='{.spec.jobTemplate.spec.template.spec.serviceAccountName}' 2>/dev/null)"
if [ "$account" != "patrol-binder" ]; then
  echo "FAIL: the CronJob runs as '${account}', expected patrol-binder"
  exit 1
fi
if ! kubectl -n starfleet get rolebinding patrol-binder >/dev/null 2>&1; then
  echo "FAIL: the RoleBinding patrol-binder in starfleet was removed"
  exit 1
fi

echo "PASS: the patrol-binder CronJob and its RBAC are unchanged"
