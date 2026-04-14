FROM python:3.12.11-slim
LABEL org.opencontainers.image.authors="Hystax"

WORKDIR /usr/src/app/
ENV PYTHONPATH /usr/src/app/

COPY optscale_client/config_client optscale_client/config_client
COPY tools/render_local_config.py tools/render_local_config.py
COPY docker/local/config.yaml.tpl docker/local/config.yaml.tpl

COPY docker_images/configurator/requirements.txt docker_images/configurator/
RUN pip install --no-cache-dir -r docker_images/configurator/requirements.txt

COPY docker_images/configurator/configurator.py docker_images/configurator/

CMD ["sh", "-c", "python tools/render_local_config.py docker/local/config.yaml.tpl /config/config && python docker_images/configurator/configurator.py /config/config"]
