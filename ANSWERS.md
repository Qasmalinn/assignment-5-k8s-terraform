# Task 5 - Questions and Answers

**1. What is the difference between `docker` and `containerd`? Why does Kind use containerd under the hood?**

Docker is a complete platform for building, running, and managing containers. It includes a CLI, image builder, and a high-level daemon that handles the full developer workflow. Under the hood, Docker itself uses containerd as its container runtime. Containerd is a lower-level daemon that focuses solely on running and managing containers — pulling images, managing storage, and handling the container lifecycle — without the extra tooling that Docker provides.

Kind uses containerd directly because it only needs to run containers inside the cluster nodes, not the full Docker workflow. Using containerd keeps things lightweight and is also the same runtime that production Kubernetes clusters (like those on GKE or EKS) use, making Kind more realistic as a local development environment.

**2. Why does the deployment use `imagePullPolicy: Never`?**

Normally Kubernetes tries to pull images from a remote registry like Docker Hub. In a local Kind cluster, images are not pushed to any registry — they are loaded directly into the cluster using `kind load docker-image`. Setting `imagePullPolicy: Never` tells Kubernetes to never attempt a remote pull and only use the image that is already present on the node. Without this setting the deployment would fail with an `ImagePullBackOff` error because Kubernetes would look for the image in a registry where it does not exist.

**3. What would need to change if you wanted to deploy to a remote Kubernetes cluster instead of a local one?**

Several things would need to change:
- Images would need to be pushed to a remote container registry (e.g. Docker Hub, GitHub Container Registry, or ECR) instead of loaded with `kind load`.
- The `imagePullPolicy` should be changed from `Never` to `IfNotPresent` or `Always` so Kubernetes can pull from the registry.
- The deployment manifest would reference the full registry path for the image (e.g. `ghcr.io/username/app:tag`).
- The CI/CD workflow would need credentials to authenticate with the registry and push the image.
- The kubeconfig used by the runner would need to point to the remote cluster instead of the local Kind cluster.

**4. What are the advantages and disadvantages of using a self-hosted runner compared to GitHub-hosted runners?**

**Advantages:**
- Full access to local resources such as the Kind cluster, which is not possible with GitHub-hosted runners.
- No compute costs since the runner uses your own machine.
- Can be customised with specific software, hardware, or network access that hosted runners do not provide.

**Disadvantages:**
- The runner only works while your machine is on and the runner process is running, making it unreliable for team projects.
- You are responsible for maintaining, updating, and securing the runner yourself.
- Public repositories pose a security risk since forks can submit pull requests that run code on your machine.
- Does not scale automatically — a hosted runner can spin up multiple parallel jobs, while a self-hosted runner is limited to what your machine can handle.
