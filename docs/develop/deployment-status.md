# Deployment status

What the apps can reach in the cloud today, checked on 2026-11-15 with the AWS
CLI (`--profile mano`, `us-east-1`). Re-run the checks below before trusting it.

## What is live

The single-instance shape from `mano-infra/infra/` (k3s on one EC2 instance and
a single-AZ RDS) is up:

| Resource | Name | State |
|---|---|---|
| EC2 | `mano-k3s`, public IP `34.200.229.11` | running |
| RDS | `mano-postgres` (Postgres) | available |
| ECR | `mano-gateway`, `manotaskmanager`, `manochatservice`, `mano-scheduler`, `manoprojects`, `manoprofiles`, `manobilling` | all tagged `09d21ba` (2026-11-12) |

There is no EKS, ECS, App Runner, Lambda, API Gateway, load balancer or Route 53
zone. Traefik (k3s's ingress) serves everything on port 80:

| Path | What answers |
|---|---|
| `POST http://34.200.229.11/` | the gateway's GraphQL (`{__typename}` returns `Query`) |
| `GET http://34.200.229.11/auth/hello` | `Hello`: the SuperTokens **core**, not mano-auth |

## What is missing

These services are not deployed. None of them has an ECR image, and none is in
`kubernetes-manifest.yaml`:

- **mano-auth**, the SuperTokens API the apps sign in through. Without it there
  is no sign-in in the cloud: no phone OTP, no Google, no Apple.
- **mano-verification** (D10, Didit). The gateway's `startVerification` has
  nothing to call.
- **mano-media** (Garage uploads) and **mano-reviews**.

## Release blockers

1. **No TLS and no domain.** Android blocks cleartext HTTP by default (since
   API 28), and iOS ATS does too, so a store build cannot use the bare IP.
   `api.manoapp.co` behind HTTPS is needed.
2. **mano-auth, mano-verification, mano-media and mano-reviews must be added**
   to the manifest and deployed. Their secrets (Didit, Google, Wompi) go in
   through `bws run`.
3. **The requester is on Play as early access** (`com.manoInc.mano`, since
   2026-11-16) and its Play App Signing SHA-1 is registered with Google (see
   [Auth](auth.md)). That build cannot work yet: it needs blockers 1 and 2.
   The provider's Play id is `com.manoInc.manoprofesional`; its Google Android
   client must be created with that package and the Play App Signing SHA-1.

Until then the apps are developed and tested against the local stack (see
`../mano-gateway/docs/local-stack.md`).

## How to re-check

```bash
aws sts get-caller-identity --profile mano
aws ec2 describe-instances --profile mano --region us-east-1 \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`]|[0].Value,PublicIpAddress]' --output text
aws rds describe-db-instances --profile mano --region us-east-1 \
  --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]' --output text
aws ecr describe-repositories --profile mano --region us-east-1 \
  --query 'repositories[].repositoryName' --output text
curl -s -X POST -H 'content-type: application/json' \
  -d '{"query":"{__typename}"}' http://34.200.229.11/
```

In zsh, pass the `aws` flags literally. A `$P` holding several flags is not
word-split, so the CLI rejects it as one unknown option.
