from flask import Flask, jsonify, request
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics
# NOVO: Importa WhiteNoise
from whitenoise import WhiteNoise 

app = Flask(__name__)

# --- CONFIGURAÇÃO WHITENOISE (SERVE O FRONTEND) ---
# WhiteNoise configura o servidor Flask/Gunicorn para servir arquivos estáticos.
# root='.' significa que ele vai procurar arquivos estáticos no diretório raiz do projeto (onde app.py está).
# index_file=True garante que, ao acessar '/', ele serve o 'index.html'.
app.wsgi_app = WhiteNoise(app.wsgi_app, root='.', index_file=True, prefix='/')


metrics = PrometheusMetrics(app, in_progress=True)

# Configuração do CORS para ambiente local e de produção
# Permitimos qualquer origem (*) no deploy Docker para simplificar a configuração de rede,
# já que tudo está na mesma máquina/porta (80).
CORS(app, resources={r"/*": {"origins": "*"}})

# Simulação de banco de dados (armazenamento em memória)
itens = [
    {"id": 1, "titulo": "Ajustar CORS no Flask para Localhost", "descricao": "Mudar a configuração do CORS para aceitar o frontend rodando na porta 8080.", "concluido": True},
    {"id": 2, "titulo": "Implementar Edição de Tarefas (PUT)", "descricao": "Adicionar um botão de edição e lógica para atualizar a tarefa no frontend e no backend.", "concluido": False}
]
next_id = 3

# Função auxiliar para encontrar item
def find_item(item_id):
    return next((item for item in itens if item["id"] == item_id), None)

# Rota GET - Listar todos os itens
# Esta é uma rota de API
@app.route('/itens', methods=['GET'])
def get_itens():
    return jsonify(itens)

# Rota GET - Obter um item específico
@app.route('/itens/<int:item_id>', methods=['GET'])
def get_item(item_id):
    item = find_item(item_id)
    if item:
        return jsonify(item)
    return jsonify({"message": "Item not found"}), 404

# Rota POST - Adicionar novo item
@app.route('/itens', methods=['POST'])
def add_item():
    global next_id
    data = request.get_json()
    if not data or 'titulo' not in data:
        return jsonify({"message": "Title is required"}), 400
    
    new_item = {
        "id": next_id,
        "titulo": data['titulo'],
        "descricao": data.get('descricao', ''),
        "concluido": data.get('concluido', False)
    }
    itens.append(new_item)
    next_id += 1
    return jsonify(new_item), 201

# Rota PUT - Atualizar item completamente (PUT)
@app.route('/itens/<int:item_id>', methods=['PUT'])
def update_item(item_id):
    data = request.get_json()
    item = find_item(item_id)
    
    if not item:
        return jsonify({"message": "Item not found"}), 404
        
    if not data or 'titulo' not in data:
        return jsonify({"message": "Title is required"}), 400

    item['titulo'] = data['titulo']
    item['descricao'] = data.get('descricao', item['descricao'])
    # O PUT deve ser usado para atualização completa, incluindo o status
    item['concluido'] = data.get('concluido', item['concluido']) 

    return jsonify(item)

# Rota PATCH - Atualizar item parcialmente (ex: status de conclusão)
@app.route('/itens/<int:item_id>', methods=['PATCH'])
def patch_item(item_id):
    data = request.get_json()
    item = find_item(item_id)
    
    if not item:
        return jsonify({"message": "Item not found"}), 404

    # Aplica atualização apenas se o campo existir no corpo da requisição
    if 'titulo' in data:
        item['titulo'] = data['titulo']
    if 'descricao' in data:
        item['descricao'] = data['descricao']
    if 'concluido' in data:
        item['concluido'] = data['concluido']

    return jsonify(item)

# Rota DELETE - Remover item
@app.route('/itens/<int:item_id>', methods=['DELETE'])
def delete_item(item_id):
    global itens
    original_len = len(itens)
    itens = [item for item in itens if item["id"] != item_id]
    
    if len(itens) == original_len:
        return jsonify({"message": "Item not found"}), 404
        
    return jsonify({"message": "Item deleted"}), 200

# Rota de Health Check para o ALB
@app.route("/health")
def health():
    return "ok", 200


if __name__ == '__main__':
    # Esta parte é para rodar localmente e é ignorada pelo Gunicorn
    app.run(host='127.0.0.1', port=5000, debug=True)