# Use uma imagem base oficial do Nginx
FROM nginx:alpine

# Remove a página de boas-vindas padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia seus arquivos estáticos (index.html, style.css, script.js)
# O caminho é relativo ao CONTEXTO (a pasta raiz do projeto)
COPY index.html /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/
COPY script.js /usr/share/nginx/html/

# Por padrão, o Nginx roda na porta 80
EXPOSE 80