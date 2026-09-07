FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN useradd --create-home --uid 10001 appuser

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY api ./api

USER 10001
EXPOSE 5000

CMD ["uvicorn", "api.get_ec2:app", "--host", "0.0.0.0", "--port", "5000"]
