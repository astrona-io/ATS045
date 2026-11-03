---
draft: true
exam_objectives:
  - Image Repository
---
# Summary

An image reference has a registry host, a repository path, a tag and optionally a digest. Only the digest is fixed. A registry stores manifests, configuration blobs and layers, all addressed by digest, and a tag is a movable pointer to a manifest. Anyone who can pull an image can download every layer, so a secret in any layer is exposed to everyone with read access. Anyone who can push can move a tag, so write access decides what the cluster will run.

A repository needs authentication, authorization and a plan for retention. Push, pull and delete are separate rights that belong to different identities: the build pipeline pushes, the nodes pull, and a controlled process deletes. A pull credential that can also push is a way to replace an image. Deleting a tag leaves the blobs until garbage collection, tag immutability stops overwrites, and registry traffic across a network needs TLS.

A node pulls images for a pod, so Kubernetes passes it a pull Secret of type `kubernetes.io/dockerconfigjson`. The Secret is namespaced, and its registry host must match the host in the image reference. Attaching it to a ServiceAccount covers every pod that uses the account, and the credential reaches a pod only when the pod is created. `imagePullPolicy: IfNotPresent` lets any pod on a node use a cached private image without a credential check, and `Always` or the `AlwaysPullImages` admission controller removes that gap. Rotation is complete when the old credential is revoked at the registry.

Key facts:

- `ImagePullBackOff` with an authorization failure means the pod has no valid pull credential.
- The `Docker-Content-Digest` response header carries a manifest digest.
- The Secret type for pull credentials is `kubernetes.io/dockerconfigjson`.

<!-- astrona:playground:destroy -->
