FROM python:3.11-slim-bookworm

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL io.hass.version="$BUILD_VERSION" \
      io.hass.type="app" \
      io.hass.arch="$BUILD_ARCH"

ENV PYTHONUNBUFFERED=1
ENV TZ=Europe/Moscow

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

WORKDIR /data
CMD ["/run.sh"]
