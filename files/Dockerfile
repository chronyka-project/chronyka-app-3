# Usa uma imagem Python leve como base
FROM python:3.11-slim

# Define a porta interna do container onde o Gunicorn será executado
ENV PORT 5000
EXPOSE $PORT

# Define o diretório de trabalho dentro do container
WORKDIR /usr/src/app

# Copia os requisitos de dependência e os instala primeiro para aproveitar o cache do Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o resto do código (app.py, index.html, style.css, script.js)
COPY . .

# Comando para iniciar o servidor web Gunicorn
# bind 0.0.0.0 garante que o container escute em todas as interfaces de rede
# app:app refere-se ao objeto Flask 'app' dentro do arquivo 'app.py'
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]