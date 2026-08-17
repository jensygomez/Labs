# Verificar que Tofu ve la variable
echo $TF_VAR_ssh_public_key
# Verificar que SSH puede leer tu config montada
cat /root/.ssh/config | grep "10.10.10"
# Inicializar Terraform/OpenTofu
tofu init
# Verificar si puedes leerlo como tu usuario mapeado
cat /root/.ssh/config
# Si sigue fallando, copia el config a una ubicación no montada
cp /root/.ssh/config /tmp/ssh_config
export GIT_SSH_COMMAND="ssh -F /tmp/ssh_config"
export ANSIBLE_SSH_ARGS="-F /tmp/ssh_config"
exit
tofu plan
tofu plan -out=tfplan
tofu apply tfplan
ls -lh
vim providers.tf 
vi providers.tf 
tofu init
tofu plan
tofu apply tfplan
tofu plan -out=tfplan
tofu apply "tfplan"
tofu apply tfplan
tofu init
tofu plan -out=tfplan
tofu plan -out=tfplan
exit
tofu init
tofu plan -out=tfplan
tofu apply tfplan
exit
tofu apply tfplan
tofu plan -out=tfplan
tofu apply tfplan
tofu refresh
ssh -o StrictHostKeyChecking=no ansible@10.10.10.21 hostname
ssh -o StrictHostKeyChecking=no ansible@10.10.10.22 hostname
ssh -o StrictHostKeyChecking=no ansible@10.10.10.23 hostname
ssh -o StrictHostKeyChecking=no ansible@10.10.10.21 hostname
ssh -o StrictHostKeyChecking=no server01@10.10.10.21 hostname
exit
ssh 10.10.10.21 hostname
ssh 10.10.10.22 hostname
ssh 10.10.10.23 hostname
exit
echo $HOME
whoami
cat /root/.ssh/config | grep "10.10.10"
sudo cat /root/.ssh/config | grep "10.10.10"
ssh -i ~/.ssh/id_lxd_fleet root@192.168.18.100 << 'EOF'
echo "=== Config VM 201 (verificar cicustom) ==="
qm config 201

echo ""
echo "=== ¿Existe el snippet en disco? ==="
cat /var/lib/vz/snippets/cloud-user-config.yml

echo ""
echo "=== Interfaces de red de la VM (via agent) ==="
qm agent 201 network-get-interfaces 2>&1

echo ""
echo "=== Hostname de la VM ==="
qm agent 201 get-host-name 2>&1
EOF

exit
