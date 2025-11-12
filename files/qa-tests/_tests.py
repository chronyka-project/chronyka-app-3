import requests
import pytest
import time

# --- URLs CORRIGIDAS para a Arquitetura Unificada ---
# Agora, o Frontend (HTML/JS) e o Backend (Flask API) estão unificados
# no mesmo contêiner e expostos na porta 5000.
UNIFIED_APP_URL = "http://127.0.0.1:5000"
API_BASE_URL = f"{UNIFIED_APP_URL}/itens" # A API continua em /itens

# Variável global para armazenar o ID do item criado para testes
TEST_ITEM_ID = None

# --- 1. Testes de API (Backend - Flask na porta 5000) ---

@pytest.fixture(scope="module", autouse=True)
def check_api_health():
    """Verifica a saúde da API antes de rodar qualquer teste funcional."""
    try:
        # Verifica a rota principal de listagem (GET /itens)
        response = requests.get(API_BASE_URL)
        assert response.status_code == 200
        assert isinstance(response.json(), list)
        
        # Pequena pausa para garantir que o Flask/Gunicorn subiu completamente
        time.sleep(2) 
    except requests.exceptions.ConnectionError:
        pytest.fail(f"Falha ao conectar à Aplicação Unificada em {UNIFIED_APP_URL}. O serviço está rodando na porta 5000?")

def test_1_get_itens_initial():
    """Testa se a lista de itens inicial retorna 200 e é uma lista."""
    response = requests.get(API_BASE_URL)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2 # Deve ter pelo menos os itens de mock do app.py

def test_2_post_new_item():
    """Testa a criação de um novo item (POST /itens)."""
    global TEST_ITEM_ID
    
    new_item = {
        "titulo": "Tarefa de Teste Ansible",
        "descricao": "Criado via teste Pytest para validação de CI/CD",
        "concluido": False
    }
    
    response = requests.post(API_BASE_URL, json=new_item)
    
    assert response.status_code == 201, f"Esperado 201, mas obteve {response.status_code}. Resposta: {response.text}"
    data = response.json()
    
    # Armazena o ID para os testes subsequentes
    TEST_ITEM_ID = data.get("id")
    
    assert TEST_ITEM_ID is not None
    assert data["titulo"] == new_item["titulo"]
    assert data["concluido"] == new_item["concluido"]

def test_3_put_update_item():
    """Testa a atualização completa do item (PUT /itens/<id>)."""
    if not TEST_ITEM_ID:
        pytest.skip("Pula o teste de PUT: o item não foi criado no POST.")

    updated_data = {
        "titulo": "Tarefa de Teste ATUALIZADA",
        "descricao": "Descrição nova via PUT",
        "concluido": True
    }

    response = requests.put(f"{API_BASE_URL}/{TEST_ITEM_ID}", json=updated_data)
    
    assert response.status_code == 200, f"Esperado 200, mas obteve {response.status_code}"
    data = response.json()
    
    assert data["titulo"] == updated_data["titulo"]
    assert data["descricao"] == updated_data["descricao"]
    assert data["concluido"] == updated_data["concluido"]

def test_4_patch_complete_item():
    """Testa a atualização parcial para marcar como Pendente (PATCH /itens/<id>)."""
    if not TEST_ITEM_ID:
        pytest.skip("Pula o teste de PATCH: o item não foi criado.")
        
    patch_data = {
        "concluido": False # Mudando o status de volta
    }
    
    response = requests.patch(f"{API_BASE_URL}/{TEST_ITEM_ID}", json=patch_data)
    
    assert response.status_code == 200, f"Esperado 200, mas obteve {response.status_code}"
    data = response.json()
    
    assert data["concluido"] == False

def test_5_delete_item():
    """Testa a exclusão do item (DELETE /itens/<id>)."""
    if not TEST_ITEM_ID:
        pytest.skip("Pula o teste de exclusão: o item não foi criado.")
        
    response = requests.delete(f"{API_BASE_URL}/{TEST_ITEM_ID}")
    
    assert response.status_code == 200, f"Esperado 200, mas obteve {response.status_code}"
    
    # Verifica se o item realmente foi removido
    check_response = requests.get(f"{API_BASE_URL}/{TEST_ITEM_ID}")
    assert check_response.status_code == 404

# --- 2. Testes de Frontend (na porta 5000) ---

def test_index_page_status_code():
    """Testa se a rota principal (index) retorna 200."""
    response = requests.get(f"{UNIFIED_APP_URL}/")
    # CORREÇÃO: Usando UNIFIED_APP_URL
    assert response.status_code == 200, f"Esperado 200, mas obteve {response.status_code} na rota /"
    assert "<title>tarefas chronyka</title>" in response.text.lower(), "Página inicial não contém o título esperado."

def test_frontend_assets_exist():
    """Testa se os assets do frontend (CSS e JS) estão sendo servidos."""
    # CORREÇÃO: Usando UNIFIED_APP_URL
    
    # Testa o script.js
    response_js = requests.get(f"{UNIFIED_APP_URL}/script.js")
    assert response_js.status_code == 200
    assert "application/javascript" in response_js.headers.get("Content-Type", "")
    
    # Testa o style.css
    response_css = requests.get(f"{UNIFIED_APP_URL}/style.css")
    assert response_css.status_code == 200
    assert "text/css" in response_css.headers.get("Content-Type", "")