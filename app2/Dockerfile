FROM python:3.12.0-slim-bullseye
COPY requirements.txt .
RUN pip install -r requirements.txt
RUN pip install waitress
COPY app.py .
EXPOSE 9080
ENTRYPOINT ["waitress-serve"]
CMD ["--port", "9080", "app:app"]