#!/bin/bash
docker exec -it cpu_stress_001 bash -c "stress --cpu 2 --timeout 60"
