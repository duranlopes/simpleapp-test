FROM python:3.9-slim
LABEL maintainer='Duran Lopes'
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 5000
CMD ["uvicorn", "api.get_ec2:app", "--host", "0.0.0.0", "--port", "5000"]