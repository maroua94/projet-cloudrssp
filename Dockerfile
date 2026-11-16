FROM python:3.12-slim AS base
RUN apt-get update && apt-get install -y --only-upgrade zlib1g \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .

FROM base AS test
RUN pip install --no-cache-dir pytest==8.3.3
COPY test_app.py .
RUN pytest -v

FROM base AS final
RUN useradd --create-home --uid 10001 appuser
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/healthz')" || exit 1
CMD ["python", "app.py"]
