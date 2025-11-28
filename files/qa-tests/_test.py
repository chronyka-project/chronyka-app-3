import os
import requests
import json
from time import sleep

# --- CONFIGURAÇÃO ---
# Lê a variável de ambiente injetada pelo Ansible.
# Se a variável não estiver definida (ex: rodando localmente), usa o padrão.
# A porta 5000 é a porta do host que expõe o Gunicorn (conforme seu docker-compose.yml).
UNIFIED_APP_URL = os.environ.get("UNIFIED_APP_URL", "http://127.0.0.1:5000")
API_ENDPOINT = f"{UNIFIED_APP_URL}/itens" 

def setup_module(module):
    """Garante que a API esteja totalmente online antes de começar os testes."""
    print(f"\n--- Aguardando API em: {UNIFIED_APP_URL} ---")
    retries = 10
    for i in range(retries):
        try:
            # Tenta acessar o endpoint principal (index.html, que é o WhiteNoise)
            response = requests.get(UNIFIED_APP_URL)
            if response.status_code == 200:
                print("API está pronta.")
                return
        except requests.exceptions.ConnectionError:
            pass
        
        print(f"Tentativa {i+1}/{retries}: Falha na conexão. Aguardando 3 segundos...")
        sleep(3)
    
    # Se falhar após todas as tentativas, lança um erro para o pytest
    raise ConnectionError(f"Não foi possível conectar à API em {UNIFIED_APP_URL} após {retries} tentativas.")

# --- TESTES DE FUNCIONALIDADE (CRITICAL) ---

def test_01_get_initial_items():
    """Testa se a rota GET /itens retorna status 200 e itens iniciais."""
    response = requests.get(API_ENDPOINT)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    # Verifica os dois itens iniciais simulados no app.py
    assert len(data) >= 2 

def test_02_post_new_item():
    """Testa se a rota POST /itens cria um novo item."""
    new_item = {
        "titulo": "Tarefa de Teste POST",
        "descricao": "Criada pelo teste automatizado."
    }
    response = requests.post(API_ENDPOINT, json=new_item)
    assert response.status_code == 201
    data = response.json()
    
    # Verifica se o item foi criado com sucesso e tem um ID
    assert "id" in data
    assert data["titulo"] == new_item["titulo"]
    
    # Armazena o ID para o próximo teste (se necessário, mas vamos usar um ID dinâmico)
    global last_created_id 
    last_created_id = data["id"]

def test_03_put_update_item():
    """Testa se a rota PUT /itens/<id> atualiza totalmente um item."""
    # 1. Cria um item temporário
    temp_item_data = {"titulo": "PUT Temp", "descricao": "Antes de atualizar"}
    post_response = requests.post(API_ENDPOINT, json=temp_item_data)
    temp_id = post_response.json()["id"]
    
    # 2. Dados de atualização
    updated_data = {
        "titulo": "PUT Atualizado",
        "descricao": "Descrição nova e completa",
        "concluido": True 
    }
    
    # 3. Executa o PUT
    put_response = requests.put(f"{API_ENDPOINT}/{temp_id}", json=updated_data)
    assert put_response.status_code == 200
    
    # 4. Verifica se os dados foram atualizados
    get_response = requests.get(f"{API_ENDPOINT}/{temp_id}")
    final_item = get_response.json()
    assert final_item["titulo"] == "PUT Atualizado"
    assert final_item["concluido"] == True

def test_04_patch_status_update():
    """Testa se a rota PATCH /itens/<id> atualiza o status de conclusão."""
    # 1. Cria um item temporário NÃO CONCLUÍDO
    temp_item_data = {"titulo": "PATCH Status", "concluido": False}
    post_response = requests.post(API_ENDPOINT, json=temp_item_data)
    temp_id = post_response.json()["id"]

    # 2. Executa o PATCH para concluir
    patch_response = requests.patch(f"{API_ENDPOINT}/{temp_id}", json={"concluido": True})
    assert patch_response.status_code == 200
    
    # 3. Verifica o estado atualizado
    get_response = requests.get(f"{API_ENDPOINT}/{temp_id}")
    final_item = get_response.json()
    assert final_item["concluido"] == True

def test_05_delete_item():
    """Testa se a rota DELETE /itens/<id> remove um item."""
    # 1. Cria um item temporário
    temp_item_data = {"titulo": "Item para deletar"}
    post_response = requests.post(API_ENDPOINT, json=temp_item_data)
    temp_id = post_response.json()["id"]
    
    # 2. Executa o DELETE
    delete_response = requests.delete(f"{API_ENDPOINT}/{temp_id}")
    assert delete_response.status_code == 200
    
    # 3. Tenta dar GET no item removido (espera 404)
    get_response = requests.get(f"{API_ENDPOINT}/{temp_id}")
    assert get_response.status_code == 404

# --- TESTES DE ATIVOS ESTÁTICOS (RESOLVE O ERRO REPORTADO ANTERIORMENTE) ---

def test_06_frontend_html_is_served():
    """Testa se o index.html está sendo servido pelo WhiteNoise."""
    response = requests.get(UNIFIED_APP_URL)
    assert response.status_code == 200
    # Verifica uma string única no seu index.html
    assert "📋 App Tarefas Chronyka" in response.text
    assert response.headers['Content-Type'].startswith('text/html')

def test_07_frontend_assets_exist():
    """Testa se os assets do frontend (CSS e JS) estão sendo servidos."""
    # Testa o style.css
    response_css = requests.get(f"{UNIFIED_APP_URL}/style.css")
    assert response_css.status_code == 200
    assert response_css.headers['Content-Type'].startswith('text/css')
    
    # Testa o script.js
    response_js = requests.get(f"{UNIFIED_APP_URL}/script.js")
    assert response_js.status_code == 200
    assert response_js.headers['Content-Type'].startswith('text/javascript')