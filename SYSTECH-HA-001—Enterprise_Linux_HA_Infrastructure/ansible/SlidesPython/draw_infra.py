from diagrams import Cluster, Diagram
from diagrams.onprem.compute import Server
from diagrams.onprem.network import HAProxy, Internet
from diagrams.onprem.database import PostgreSQL
from diagrams.generic.storage import Storage
from diagrams.onprem.monitoring import Zabbix

# Usamos Server o una figura de red estándar para el DNS
with Diagram("SYSTECH-HA-001 Architecture", show=False, filename="systech_infra", direction="TB"):
    with Cluster("Proxmox VE Subnet (10.10.10.0/24)"):

        # Cliente y DNS
        client = Server("client\n10.10.10.11")
        dns = Server("dns01 (dnsmasq)\n10.10.10.20\nLocal Storage")

        # Capa de Balanceo
        with Cluster("Load Balancing Layer (HA)"):
            lb_cluster = [HAProxy("lb01\n10.10.10.21"),
                          HAProxy("lb02\n10.10.10.22")]

        # Capa de Aplicación
        with Cluster("Application Cluster"):
            apps = [Server("app01\n10.10.10.31"),
                    Server("app02\n10.10.10.32"),
                    Server("app03\n10.10.10.33")]

        # Almacenamiento, BD y Monitoreo
        storage = Storage("storage01\n10.10.10.50")
        db = PostgreSQL("db01\n10.10.10.40")
        zabbix = Zabbix("zabbix-lxc\n10.10.10.90")

        # Flujo de conexiones
        client >> lb_cluster
        for lb in lb_cluster:
            lb >> apps

        for app in apps:
            app >> storage
            app >> db

        # Conexiones del DNS a la red interna
        client >> dns

        # Monitoreo
        zabbix - [apps[0], db, storage, dns]
