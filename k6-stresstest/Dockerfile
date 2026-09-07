FROM grafana/k6:0.54.0

WORKDIR /app
COPY script.js .

ENTRYPOINT ["k6"]
CMD ["run", "/app/script.js"]
