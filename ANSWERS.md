# Task 5 - Questions and Answers

**1. What is the difference between `docker` and `containerd`? Why does Kind use containerd under the hood?**

Docker is basically the full package - it gives you the CLI, the build tools, and everything you need to work with containers day to day. Containerd is what actually runs the containers under the hood, it's more low level and just handles things like pulling images and managing the container lifecycle. Docker actually uses containerd internally.

Kind uses containerd directly instead of Docker because it doesn't need all the extra stuff Docker comes with. Containerd is lighter and also happens to be what real production Kubernetes clusters use, so Kind ends up being a more accurate local setup.

**2. Why does the deployment use `imagePullPolicy: Never`?**

Because the image isn't in any registry - it gets loaded directly into the Kind cluster with `kind load docker-image`. If you don't set `imagePullPolicy: Never`, Kubernetes will try to pull it from Docker Hub and fail since the image doesn't exist there. This setting tells it to just use whatever image is already on the node.

**3. What would need to change if you wanted to deploy to a remote Kubernetes cluster instead of a local one?**

A few things would need to change:
- The image would need to be pushed to a real registry like Docker Hub or GitHub Container Registry instead of loaded with `kind load`
- `imagePullPolicy` would need to be updated so Kubernetes actually pulls from the registry
- The image name in the deployment would need the full registry path
- The workflow would need credentials to push to the registry
- The kubeconfig would need to point to the remote cluster

**4. What are the advantages and disadvantages of using a self-hosted runner compared to GitHub-hosted runners?**

The main advantage is that a self-hosted runner has access to your local machine, which is why it works here - it can reach the Kind cluster directly. It also doesn't cost anything extra.

The downsides are that it only works when your machine is on and the runner process is running, so it's not great for anything that needs to be reliable. You also have to maintain it yourself and it's a security risk on public repos since anyone could open a PR and run code on your machine.
