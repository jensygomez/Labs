FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

CMD ["/bin/bash", "-c", "/setup.sh && /bin/bash"]
