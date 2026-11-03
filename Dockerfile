FROM python:3.12-slim

# xgboost's wheel needs libgomp (OpenMP) at runtime; not present by default
# on the slim base image.
RUN apt-get update && apt-get install -y --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PORT=5000
# Without this, Python buffers stdout when it isn't a TTY (always true
# inside a container), so none of this app's startup print()s -- including
# the new-herb broadcast log lines -- ever reach `docker logs` until the
# process exits.
ENV PYTHONUNBUFFERED=1
EXPOSE 5000

CMD ["sh", "-c", "gunicorn api_server:app --bind 0.0.0.0:${PORT}"]
