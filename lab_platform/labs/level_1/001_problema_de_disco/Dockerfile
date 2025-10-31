FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

COPY setup.sh /setup.sh
RUN chmod +x /setup.sh
RUN /setup.sh

CMD ["/bin/bash"]
