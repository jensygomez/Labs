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
