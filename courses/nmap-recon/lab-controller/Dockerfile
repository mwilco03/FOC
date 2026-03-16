FROM python:3.11-alpine

COPY controller.py /app/controller.py
COPY static /app/static

WORKDIR /app

EXPOSE 8080

CMD ["python3", "controller.py"]
