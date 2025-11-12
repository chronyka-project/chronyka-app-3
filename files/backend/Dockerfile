# Use uma imagem base oficial do Python para o seu backend Flask
FROM python:3.11-slim

# Define o diretório de trabalho dentro do container
WORKDIR /usr/src/app

# Copia o arquivo de dependências e instala as dependências
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o restante do código da aplicação
COPY app.py .

# O Gunicorn será o servidor de produção
EXPOSE 5000

# Comando para rodar a aplicação usando Gunicorn.
ENV FLASK_APP=app.py
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]