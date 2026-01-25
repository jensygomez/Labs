#!/bin/bash
#===============================================================================
# EL MANIFIESTO DEL ADMINISTRADOR: EL ESQUELETO DE LA RED (FASE LÓGICA)
#===============================================================================
#
# "En el principio, el kernel creó el espacio de usuario, y todo estaba vacío."
#
# TU TAREA: Debes materializar la topología siguiendo estos principios:
#
# 1. EL AISLAMIENTO (Namespaces):
#    Linux permite que un proceso crea que es el único dueño del stack de red.
#    FILOSOFÍA: Crea tres universos paralelos (Namespaces). 
#    - Uno será el ORIGEN (Client).
#    - Uno será el TRÁNSITO (Edge).
#    - Uno será el DESTINO (Services).
#    REGLA: Cada universo debe ser independiente; lo que pase en uno no afecta al host.
#
# 2. EL DUALISMO (VETH Pairs):
#    En Linux, un cable virtual no es un objeto, es una "tubería" con dos extremos.
#    FILOSOFÍA: Crea dos pares de entidades "Ying-Yang". 
#    - El primer par unirá la periferia con el centro (Client <-> Edge).
#    - El segundo par unirá el centro con el núcleo (Edge <-> Services).
#    REGLA: Recuerda que al crear un par veth, ambos extremos nacen en el "Limbo" 
#    (el espacio de nombres global) hasta que decidas su destino.
#
# 3. LA PERTENENCIA (Asignación de Interfaces):
#    Un recurso solo puede existir en un universo a la vez.
#    FILOSOFÍA: Toma los extremos de tus cables y "empújalos" dentro de sus 
#    respectivos Namespaces.
#    - El Edge debe tener dos manos: una para recibir al Cliente y otra para el Servidor.
#    - El Cliente y el Servidor solo necesitan una mano para alcanzar al Edge.
#
# 4. EL ESTADO DE INERCIA (Interfaces en DOWN):
#    Tener el hardware no implica tener energía. 
#    FILOSOFÍA: Por ahora, deja que el sistema repose. Las interfaces deben 
#    existir dentro de sus universos, pero en estado "Silencioso" (ADMIN DOWN).
#    REGLA: No les des voz (IP) ni aliento (UP) todavía. Solo verifica que 
#    "están ahí" mediante la observación del sistema.
#
# 5. LA MEDITACIÓN (Verificación):
#    Un SysAdmin no asume, comprueba.
#    FILOSOFÍA: Entra en cada universo y pregunta al Kernel qué dispositivos ve.
#    Si el esqueleto es correcto, el Edge debería sentirse como un puente 
#    esperando ser cruzado.
#
#===============================================================================
# "La carretera está trazada en el papel, los postes están puestos, 
#  pero el asfalto aún no ha sido vertido."
#===============================================================================
