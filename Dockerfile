FROM python:3.12-slim

EXPOSE 8080

WORKDIR /app

COPY requirements.txt /requirements.txt

RUN pip install --no-cache-dir --upgrade -r /requirements.txt

COPY . /app

CMD python3 app.py
