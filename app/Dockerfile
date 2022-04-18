FROM python:3.9-alpine
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
EXPOSE 80
ENTRYPOINT [ "python" ]
CMD ["app.py"]