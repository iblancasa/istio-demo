FROM python:3.12.0-slim-bullseye
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
EXPOSE 9080
ENTRYPOINT ["flask"]
CMD ["run", "-p", "9080", "-h", "0.0.0.0"]