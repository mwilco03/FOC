FROM python:3.11-alpine

# Multi-purpose distractor: runs fake services that look interesting but have no flags
COPY distractors.py /app/distractors.py

EXPOSE 80 443 8080 9090 161

CMD ["python3", "/app/distractors.py"]
