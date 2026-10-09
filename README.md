# status-relay

Polls competitor status pages (Baseten, Fireworks, Lambda, Modal, Together, RunPod)
every 15 minutes via GitHub Actions and writes the combined result to `status.json`.
Consumed by a Claude cloud routine that alerts fal sales on competitor infra incidents
(#serverless-competitor-infra-signals). Contact: alex@fal.ai
