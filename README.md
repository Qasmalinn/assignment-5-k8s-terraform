# Assignment 5 - Kubernetes & Terraform

Provision a local Kubernetes cluster with Terraform and set up a continuous deployment pipeline using GitHub Actions. By the end of this assignment your code will be automatically built, loaded into a local Kind cluster, and deployed on every push to `main`.

**Group size:** 1 person

---

## Prerequisites

- Complete Week 9 in-class exercise (Kubernetes)
- Complete Week 10 in-class exercise (Terraform)
- [Bun](https://bun.sh/) version 1.3 or later installed
- [Docker](https://docs.docker.com/get-docker/) installed **and running** (verify with `docker info`)
- [Kind](https://kind.sigs.k8s.io/) installed
- [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
- [Terraform](https://developer.hashicorp.com/terraform/install) installed

## Setup

1. Clone your repository and `cd` into it
2. Run `bun install`
3. Run `bun run start` to verify the app runs at http://localhost:3000

## Commands

- `bun run start` - Start the server
- `bun run test` - Run test suite

---

## The Starter Project

This repository contains a simple Bun HTTP server and the infrastructure files needed to run it on a local Kubernetes cluster. Take a moment to read through the code before starting.

| File / Directory | Description |
|---|---|
| `src/index.ts` | HTTP server with `/` and `/health` routes — responds with hostname and timestamp |
| `Dockerfile` | Containerizes the app using `oven/bun:latest` |
| `terraform/` | Terraform config that creates a Kind cluster and registers a GitHub Actions runner |
| `scripts/setup-runner.sh` | Creates the Kind cluster and registers the self-hosted runner |
| `scripts/teardown.sh` | Unregisters the runner and deletes the Kind cluster |
| `k8s/kind-config.yaml` | Kind cluster configuration with port 30080 mapped to host |
| `k8s/deployment.yaml` | Kubernetes Deployment — 2 replicas, `imagePullPolicy: Never` |
| `k8s/service.yaml` | Kubernetes Service — NodePort on port 30080 |
| `.github/workflows/deploy.yml` | CI/CD workflow — builds, loads into Kind, deploys |

---

## The Assignment

### Task 1: Generate a Runner Token (Commit 1)

Before Terraform can register your machine as a GitHub Actions runner, you need a registration token.

**1a. Generate a runner registration token**

1. Go to your repository on GitHub
2. Navigate to **Settings > Actions > Runners**
3. Click **"New self-hosted runner"**
4. Copy the **token** shown in the configuration section (it starts with `A` and is valid for 1 hour)

> **Important:** The token expires in **1 hour**. Do **not** generate it now if you plan to take a break before Task 2. Generate it immediately before running `terraform apply` in the next task. If your token expires, simply generate a new one by repeating step 1a.

**1b. Create your Terraform variables file**

Copy the example file and fill in your values:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

Edit `terraform/terraform.tfvars` with your repository name and the runner token:

```hcl
github_repo  = "your-username/assignment-5-k8s-terraform"
runner_token = "AXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

> **Note:** `terraform.tfvars` is gitignored — it contains a sensitive token and should never be committed.

**Commit your changes with a descriptive message.**

---

### Task 2: Provision the Cluster and Runner with Terraform (Commit 2)

Use Terraform to create a Kind cluster and register your machine as a self-hosted runner.

> **Before you begin:** Make sure Docker is running. Run `docker info` and verify you see server information (not a connection error). If Docker is not running, start Docker Desktop / Rancher Desktop and wait until `docker info` succeeds.

**2a. Initialize Terraform**

```bash
cd terraform
terraform init
```

This downloads the `hashicorp/null` and `hashicorp/local` providers.

**2b. Review the plan**

```bash
terraform plan
```

Read the output. The plan should show a single `null_resource.cluster_and_runner` that will execute `scripts/setup-runner.sh`.

**2c. Apply**

```bash
terraform apply
```

Type `yes` to confirm. This will:

1. Create a Kind cluster called `assignment-5` using the config in `k8s/kind-config.yaml`
2. Download the GitHub Actions runner for your OS and architecture
3. Register the runner with labels `self-hosted, local, kind`
4. Start the runner as a system service (or as a background process if `sudo` is unavailable)

**2d. Verify**

Run the following commands to confirm the cluster is working:

```bash
kubectl get nodes
```

You should see a single node with status `Ready`.

Then go to your repository on GitHub: **Settings > Actions > Runners**. You should see a runner named `kind-runner` with status **Idle**.

> **Runner showing Offline?** The runner process may not have started successfully. You can start it manually:
>
> ```bash
> cd ~/actions-runner && ./run.sh
> ```
>
> Leave this terminal open — the runner must stay running for CI/CD to work. Once it connects, you should see `Listening for Jobs` in the output and the status on GitHub should change to **Idle**.

**Commit your changes with a descriptive message.**

---

### Task 3: Deploy Manually to Verify the Setup (Commit 3)

Before relying on CI/CD, verify the full pipeline works by running the steps manually.

**3a. Build the Docker image**

```bash
docker build -t app:test .
```

**3b. Load the image into Kind**

Kind runs Kubernetes inside Docker containers, so your local images are not automatically available to the cluster. You need to load them explicitly:

```bash
kind load docker-image app:test --name assignment-5
```

**3c. Deploy to the cluster**

Replace the `IMAGE_TAG` placeholder in the deployment manifest and apply:

```bash
sed 's|IMAGE_TAG|test|g' k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
```

**3d. Verify the deployment**

```bash
kubectl rollout status deployment/app --timeout=60s
kubectl get pods -l app=app
```

You should see 2 pods running. Visit http://localhost:30080 to confirm the app responds with the hostname and timestamp.

**Commit your changes with a descriptive message.**

---

### Task 4: Push to Main and Trigger the CI/CD Pipeline (Commit 4)

Now test the automated deployment. The workflow at `.github/workflows/deploy.yml` is already configured to build, load, and deploy on every push to `main`.

**4a. Make a visible change**

Open `src/index.ts` and change the greeting text (e.g., change `"Hello from Assignment 5!"` to something else).

**4b. Push to main**

```bash
git add -A
git commit -m "Update greeting"
git push origin main
```

**4c. Watch the workflow**

Go to the **Actions** tab in your repository. You should see the **Deploy** workflow running on your self-hosted runner. It will:

1. Check out the code
2. Build a Docker image tagged with the short commit SHA
3. Load the image into the Kind cluster
4. Update the deployment manifest with the new tag via `sed`
5. Run `kubectl apply` and wait for the rollout to complete

**4d. Verify the new deployment**

Once the workflow finishes (green checkmark), visit http://localhost:30080. You should see your updated greeting.

Run `kubectl get pods -l app=app` to confirm the pods restarted with the new image.

**Commit your changes with a descriptive message.**

---

### Task 5: Explore and Document (Commit 5)

Answer the following questions by adding a `ANSWERS.md` file to the root of your repository.

1. What is the difference between `docker` and `containerd`? Why does Kind use containerd under the hood?
2. Why does the deployment use `imagePullPolicy: Never`?
3. What would need to change if you wanted to deploy to a remote Kubernetes cluster instead of a local one?
4. What are the advantages and disadvantages of using a self-hosted runner compared to GitHub-hosted runners?

**Commit your answers with a descriptive message.**

---

## Cleaning Up

When you are done with the assignment, run the teardown script to unregister the runner and delete the cluster:

```bash
GITHUB_REPO=owner/repo RUNNER_TOKEN=<new-token> bash scripts/teardown.sh
```

> **Note:** You will need to generate a new runner token since the original one has expired. `teardown.sh` is not run by `terraform destroy` — it must be run manually.

---

## Handin

1. Ensure you have at least **5 commits** (one per task)
2. Verify the following before submitting:
   - The self-hosted runner is visible and online in **Settings > Actions > Runners**
   - The Deploy workflow has at least one successful run (green checkmark) in the **Actions** tab
   - The app is accessible at http://localhost:30080
3. Submit the GitHub repository link to Canvas

## Tips & Troubleshooting

- **Token expired?** If `terraform apply` fails during runner registration, your token likely expired. Generate a new one from **Settings > Actions > Runners > New self-hosted runner** and update `terraform/terraform.tfvars`
- **Docker not running?** Both Kind and the CI/CD pipeline need Docker. Run `docker info` to check. If you see a connection error, start Docker Desktop / Rancher Desktop and wait for it to be ready
- **Runner showing Offline?** The runner process must be running on your machine for GitHub Actions to pick up jobs. Start it manually with `cd ~/actions-runner && ./run.sh` and keep the terminal open
- **Runner not picking up jobs?** If the workflow is stuck on "Queued", make sure the runner is connected (`Listening for Jobs` in the terminal). Also verify the runner labels match the workflow (`self-hosted, local, kind`)
- **`ImagePullBackOff` error?** The image was not loaded into Kind. Rerun `kind load docker-image app:<tag> --name assignment-5`
- **Debugging application issues:** Use `kubectl logs deployment/app` to see application logs
- **Debugging pod issues:** Use `kubectl describe pod <pod-name>` to see detailed pod events and error messages
- **Terraform state issues?** If you need to re-run the setup script, use `terraform taint null_resource.cluster_and_runner` then `terraform apply`
- Remember what you learned in Week 9 and Week 10 in-class exercises
