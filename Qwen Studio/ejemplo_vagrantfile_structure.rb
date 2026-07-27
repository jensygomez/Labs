ruby
# -- mode: ruby --
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  # Define nodes with their IPs and extra disks if needed.
  nodes = [
    { name: "node01", ip: "192.168.122.11", extra_disks: [] },
    { name: "node02", ip: "192.168.122.12", extra_disks: [] }  # add disks as required (e.g., ['1G'])
  ]
  
  nodes.each do |node|
    config.vm.define node[:name] do |node_config|
      node_config.vm.hostname = node[:name]
      
      # Private network for internal communication
      node_config.vm.network "private_network", 
        ip: node[:ip], 
        libvirt__network_name: "mgmt-net",
        libvirt__dhcp_enabled: false
      
      node_config.vm.provider "libvirt" do |lv|
        lv.memory = 1024
        lv.cpus = 1
        lv.driver = "kvm"
        node[:extra_disks].each do |size|
          lv.storage :file, :size => size, :type => 'qcow2'
        end
      end
      
      # ----- GENERAL PROVISIONING (all nodes) -----
      node_config.vm.provision "shell", inline: <<-SHELL
        echo "🔧 Configuring #{node[:name]}..."
        for host in node01 node02; do
          sed -i "/$host/d" /etc/hosts
        done
        cat << 'HOSTS' >> /etc/hosts
192.168.122.11 node01
192.168.122.12 node02
HOSTS
        useradd -m -s /bin/bash bob 2>/dev/null || true
        echo 'bob:caleston123' | chpasswd
        echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
        chmod 0440 /etc/sudoers.d/bob
        
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq sshpass curl acl
      SHELL
      
      # ----- NODE02: server with 12 incidents -----
      if node[:name] == "node02"
        node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
          echo-SHELL
          echo <<-SHELL
          echo "🖥️ Configuring node "🖥️ Configuring node "🖥️ Configuring node02 with 12 incidents..."
          export02 with 12 incidents..."
          export02 with 12 incidents..."
          export DEBIAN_FRONTEND=noninteractive DEBIAN_FRONTEND=noninteractive
 DEBIAN_FRONTEND=noninteractive

          
          # Prepare the          
          # Prepare the scenario for the          
          # Prepare the scenario for the scenario for the 12 tasks 12 tasks.
          # 12 tasks.
          #.
          # Examples:
          # - Examples:
          # - Create Examples:
          # - Create directories and Create directories and files
          # - Install or remove packages directories and files
          # - Install or remove packages files
          # - Install or remove packages
          # -
          # - Configure services
          # - Configure services Configure services
          # - Create
          # - Create users
          # - Create users users and groups
          # - Set up and groups
          # - Set up log and groups
          # - Set up log log files, configuration files, configuration files, configuration files files, etc.
          
          echo " files, etc.
          
          echo ", etc.
          
          echo "✅ node02 configured with 12 incidents✅ node02 configured with 12 incidents✅ node02 configured with 12 incidents"
        SHELL
      end"
        SHELL
      end"
        SHELL
      end
      
      # ----- NODE01:
      
      # ----- NODE01:
      
      # ----- NODE01: control station with ticket control station with ticket control station with ticket and scripts -----
      if node[:name] == " and scripts -----
      if node[:name] == " and scripts -----
      if node[:name] == "node01"
        node_config.vmnode01"
        node_config.vmnode01"
        node_config.vm.provision "shell", privileged.provision "shell", privileged: false, inline.provision "shell", privileged: false, inline: false, inline: <<-SHELL: <<-SHELL: <<-SHELL
          echo "🎫 Generating Ticket
          echo "🎫 Generating Ticket
          echo "🎫 Generating Ticket, verification, and validator on node, verification, and validator on node01..."
          
          # Create, verification, and validator on node01..."
          
          # Create01..."
          
          # Create TICKET_M TICKET_M TICKET_MOCK-XXX.txt
          #OCK-XXX.txt
          #OCK-XXX.txt
          # Create verify-XXX.sh ( Create verify-XXX.sh ( Create verify-XXX.sh (optional, for scenariooptional, for scenariooptional, for scenario verification)
          # Create validate.sh ( verification)
          # Create validate.sh verification)
          # Create validate.sh (direct SSH validation)
 (direct SSH validation)
          
          echo "✅direct SSH validation)
          
          echo "✅ Ticket + Verification Ticket + Verification + Validator created          
          echo "✅ Ticket + Verification + Validator created."
          echo + Validator created."
         ."
          echo "🚀 vag "🚀 vag echo "🚀 vagrant ssh node01 →rant ssh node01 → automatic verificationrant ssh node01 → automatic verification"
          echo "📝 When done: automatic verification"
          echo "📝 When"
          echo "📝 When done: bash /home/vagrant/validate bash /home/vagrant/validate done: bash /home/v.sh"
        SHELL
      end.sh"
        SHELL
      end
    end
  end
end
    end
  end
end
