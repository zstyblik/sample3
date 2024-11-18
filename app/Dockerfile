FROM python:3.11.10-slim-bookworm


ENV WORKING_DIR /opt/weather
RUN mkdir -p "${WORKING_DIR}"
WORKDIR "${WORKING_DIR}"
COPY . "${WORKING_DIR}"

RUN \
    groupadd \
        --gid 2000 \
        webgroup \
    && useradd \
        --gid 2000 \
        --home-dir /no/home \
        --no-create-home \
        --no-user-group \
        --shell /no/shell \
        webuser \
    && chown \
        --recursive \
        webuser:webgroup \
        "${WORKING_DIR}"

USER webuser

RUN \
    mkdir -p "${WORKING_DIR}/venv" \
    && python -m venv "${WORKING_DIR}/venv" \
    && "${WORKING_DIR}"/venv/bin/python \
        -m pip \
        install \
        -U \
        pip \
    && "${WORKING_DIR}"/venv/bin/python \
        -m pip \
        install \
        --no-cache-dir \
        -r requirements/requirements.txt

CMD ${WORKING_DIR}/venv/bin/python ./weather.py
