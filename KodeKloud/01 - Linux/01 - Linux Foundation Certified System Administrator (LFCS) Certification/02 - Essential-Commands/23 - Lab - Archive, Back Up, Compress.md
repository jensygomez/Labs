---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Archive, Back Up, Compress, IO Redirection
Fecha de Inicio: 2026-05-12
Dificultad: Basico-Medio
Tareas Totales: "15"
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas                     |
| :------------- | :----- | :---- | :-------------------------------- |
| 12 - 05 - 2026 | 45 min | 16%   | Problemas con redirección stderr. |
| 14 - 05 - 2026 | 45 min | 26%   | Seguieremos practicando           |
| 15 - 05 - 2026 | 35 min | 60%   | Evolución clara y constante.      |
| `20/05/2026`   | 60 min | 66%   |                                   |
[[Laboratorios del LFCS]]


---
# Lab Summary: Archiving, Compression, and Stream Redirection

During this lab, I worked with the three foundational pillars of Unix philosophy: doing one thing well and composing it with other tools. I learned how to package entire directories using tar, which is really the backbone of any serious backup strategy or configuration distribution in Linux. It's not just about squeezing files together; it's about understanding how a systems administrator handles critical information, moves it across servers, and preserves it reliably. Once I understood tar properly, I realized why legacy systems still depend on it after decades—because it works, it's predictable, and it doesn't rely on anything unnecessarily complex.

Compression was the natural next step. I moved beyond tar, which merely groups files, into actual compressed formats like gzip, bzip2, and xz. The philosophy is straightforward: optimize your resources. In a real company, sending a 50GB backup uncompressed is irresponsible; compressing it down to 15GB is professional. I learned to choose the right compression tool depending on the situation: gzip is fast and everywhere, bzip2 squeezes more but takes longer, xz is the future but demands more processing power. A sysadmin who hasn't mastered this is a sysadmin wasting company bandwidth and slowing down disaster recovery times when things go wrong.

Redirection is where Unix really shows its power, and honestly, where most beginners get confused. I worked with the three data streams: standard input, standard output, and standard error. This is the nervous system of automation. When you redirect stdout to one file, stderr to another, and accidentally forget one, your script fails silently in production and nobody knows why until it's too late. I learned to separate what matters from what doesn't, to capture errors for auditing, to process data reliably. This isn't cosmetic; it's the difference between an administrator who knows exactly what happened when systems broke at 3 AM and one who's just guessing.

---

**Key commands to remember:**

```bash
tar -cvf archive.tar directory/
tar -xvf archive.tar -C /destination/path/
gzip -k file.txt
cat file.txt >> destination.txt 2>&1
sort file.conf | uniq -i
```