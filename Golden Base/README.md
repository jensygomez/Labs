network-engine/
├── engine.sh                # Orquestador (único entrypoint)
│
├── lib/
│   ├── log.sh               # logging, colors, timestamps
│   ├── guard.sh             # validaciones (root, deps, kernel)
│   ├── idempotency.sh       # ensure_* helpers
│   ├── netns.sh             # namespaces
│   ├── links.sh             # veth, bridges, trunks
│   ├── addressing.sh        # IPs
│   ├── forwarding.sh        # sysctl, rp_filter
│   ├── routing.sh           # rutas por rol
│   ├── nat.sh               # NAT / egress
│   ├── firewall.sh          # policies
│   └── tests.sh             # validaciones automáticas
│
├── roles/
│   ├── edge.conf
│   ├── core-edge.conf
│   ├── core-svc.conf
│   └── core-mgmt.conf
│
├── topology/
│   └── lab.conf             # definición declarativa
│
├── phases/
│   ├── 01-netns.sh
│   ├── 02-links.sh
│   ├── 03-addressing.sh
│   ├── 04-forwarding.sh
│   ├── 05-routing.sh
│   ├── 06-nat.sh
│   ├── 07-firewall.sh
│   └── 08-tests.sh
│
└── README.md
