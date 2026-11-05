FROM python:3.12-slim@sha256:b18b261e1b4974b4f321451ad5251ded85abb22c2b8b262da527dda1d031ab30

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /home/jovyan/work
COPY requirements.txt /tmp/requirements.txt
RUN python -m pip install --no-cache-dir -r /tmp/requirements.txt \
    && useradd --create-home --shell /bin/bash jovyan \
    && mkdir -p /home/jovyan/work \
    && chown -R jovyan:jovyan /home/jovyan

COPY --chown=jovyan:jovyan . /home/jovyan/work
USER jovyan
EXPOSE 8888

# Tanpa token hanya untuk container lokal yang dipublish ke 127.0.0.1.
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--IdentityProvider.token=", "--ServerApp.password="]
