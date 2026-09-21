FROM mcr.microsoft.com/playwright:v1.46.0

ARG BUILD_VERSION
ARG BUILD_ARCH

LABEL io.hass.version="$BUILD_VERSION" \
      io.hass.type="addon" \
      io.hass.arch="$BUILD_ARCH"

ENV PYTHONUNBUFFERED=1
ENV TZ=Europe/Moscow

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/mbplugin \
    && curl -fsSL https://github.com/artyl/mbplugin/archive/refs/tags/v1.00.92.tar.gz \
       | tar -xz --strip-components=1 -C /opt/mbplugin \
    && python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir -r /opt/mbplugin/docker/requirements.txt

COPY run.sh /run.sh
RUN chmod 0755 /run.sh

WORKDIR /data

CMD ["/run.sh"]
