
---

Sure, I can share a recent technical challenge. 

In my self-study lab work, I built a custom Docker image for a Flask web application. 

I started by writing a Dockerfile based on python:3.14, installing dependencies, copying the application code, and setting up the entry point. 

After building it, I noticed the image was over 420MB, which is quite heavy for a containerized app. 

So I investigated the issue and found that the base image itself, the Debian-based python:3.14, was the main contributor to that size. 

I modified the Dockerfile to use the alpine variant instead, python:3.14-alpine, which is built on a much lighter Linux distribution. After rebuilding, I reduced the image size down to under 24MB, nearly a 95% reduction, while keeping the exact same application functionality. 

I also ran and tested both versions as containers, mapping different host ports to verify everything worked correctly before and after the optimization. 

This experience reinforced for me how important image size optimization is in real-world Docker workflows, especially for faster deployments, reduced storage costs, and quicker CI/CD pipelines.

---

[[Laboratorios del LFCS]]

---



