FROM stefanprodan/alpine-base:latest

COPY entrypoint.sh /entrypoint.sh
COPY envsubst /envsubst
RUN chmod +x /entrypoint.sh
USER 1001
ENTRYPOINT ["/entrypoint.sh"]
