# k6 load test

The test uses the pinned official `grafana/k6` image and defaults to a small local smoke load. It is not a production stress test.

```bash
docker build -t simpleapp-k6:local .
docker run --rm \
  --network host \
  -e BASE_URL=http://127.0.0.1:8008 \
  -e VUS=5 \
  -e DURATION=30s \
  simpleapp-k6:local
```

Increase `VUS` and `DURATION` only against an explicitly authorized test environment. The run fails when more than 1% of requests fail or p95 latency exceeds 500 ms.
