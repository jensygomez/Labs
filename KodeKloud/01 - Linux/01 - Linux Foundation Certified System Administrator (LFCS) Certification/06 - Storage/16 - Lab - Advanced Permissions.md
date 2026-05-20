---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Advanced Permissions
Fecha de Inicio: 2026-05-09
Dificultad: Intermedio-Medio
Tareas del Lab: "8"
---
## 📊 Bitácora de Intentos
|    Fecha     | Tiempo | Éxito | Task |
| :----------: | :----: | :---: | :--: |
| `09/05/2026` | 15 min | 50 %  |  8   |
| `20/05/2026` | 25 min | 75 %  |  8   |

[[Laboratorios del LFCS]]

**Here’s how it would sound in English, first person singular (B2 level):**

---

In Linux, I really like the philosophy of building robust and reliable systems. One good example is using mirrored arrays, also known as RAID 1. This technique copies the same data on two or more disks so that if one disk fails, the information is still safe and the system can continue working. Understanding how to create and check these RAID arrays helps me prepare for real production environments where data availability is very important.

Another important concept I learned is the use of ACLs, which are Access Control Lists. While traditional Linux permissions are simple and effective, ACLs give me more precise control. They allow me to give specific permissions to certain users or groups without changing the main owner or group permissions. This is very useful in multi-user servers when I need to share files safely and flexibly.

Mastering RAID and ACLs shows that I understand the Linux way of thinking: keeping systems secure, manageable, and reliable. In a technical interview, I can explain that these tools help balance data protection, security, and simplicity. This knowledge not only helps me pass the certification exam but also prepares me to solve real problems that companies face every day.

---

**Key commands to remember:**

- `mdadm --detail --scan`
- `getfacl filename`
- `setfacl -m u:john:rw file`
- `setfacl -R -m u:john:rwx directory`

---

Would you like me to make it a bit shorter, longer, or change anything?