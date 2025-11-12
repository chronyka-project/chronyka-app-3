// IMPORTANTE: AGORA QUE O FRONTEND E O BACKEND ESTÃO NA MESMA PORTA (80 DO HOST),
// USAMOS UMA ROTA RELATIVA PARA EVITAR ERROS DE CORS E SIMPLIFICAR.
const API_URL = '/itens'; 

const itemListContainer = document.getElementById('item-list');
const form = document.getElementById('add-item-form');
const tituloInput = document.getElementById('item-titulo');
const descricaoInput = document.getElementById('item-descricao');

// Elementos do Modal de Edição
const editModal = document.getElementById('edit-modal');
const editForm = document.getElementById('edit-item-form');
const editIdInput = document.getElementById('edit-item-id');
const editTituloInput = document.getElementById('edit-titulo');
const editDescricaoInput = document.getElementById('edit-descricao');
const closeModalBtn = document.getElementById('close-modal-btn');


// --- FUNÇÕES DE CONTROLE DO MODAL ---
/**
 * Exibe o modal de edição com os dados da tarefa preenchidos.
 * @param {Object} item - O objeto de item da API.
 */
function openEditModal(item) {
    // Preenche o formulário do modal com os dados atuais
    editIdInput.value = item.id;
    editTituloInput.value = item.titulo;
    editDescricaoInput.value = item.descricao || '';
    
    // Mostra o modal
    editModal.classList.add('active');
}

/**
 * Fecha o modal de edição.
 */
function closeEditModal() {
    editModal.classList.remove('active');
}

// Listener para fechar o modal
closeModalBtn.addEventListener('click', closeEditModal);
// Listener para fechar o modal clicando fora
editModal.addEventListener('click', (e) => {
    if (e.target === editModal) {
        closeEditModal();
    }
});


// --- FUNÇÕES DE INTERAÇÃO COM A API ---

/**
 * Faz a chamada GET para a API e renderiza os itens.
 */
async function fetchAndRenderItems() {
    try {
        itemListContainer.innerHTML = '<p class="loading-message">Carregando itens...</p>';
        const response = await fetch(API_URL);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const items = await response.json();
        
        // --- CORREÇÃO: INVERTE A ORDEM PARA MOSTRAR MAIS NOVOS NO TOPO ---
        // Cria uma cópia da array e a inverte para que os itens mais recentes (IDs maiores) apareçam primeiro.
        const reversedItems = [...items].reverse();

        renderItems(reversedItems); // Usa a lista invertida
        
    } catch (error) {
        console.error("Erro ao buscar itens:", error);
        itemListContainer.innerHTML = `<p class="error-message">Falha ao carregar tarefas: ${error.message}</p>`;
    }
}

/**
 * Renderiza a lista de itens no HTML.
 * @param {Array<Object>} items - A lista de tarefas.
 */
function renderItems(items) {
    itemListContainer.innerHTML = '';
    
    if (items.length === 0) {
        itemListContainer.innerHTML = '<p class="loading-message">Nenhuma tarefa encontrada. Adicione uma nova!</p>';
        return;
    }
    
    items.forEach(item => {
        const card = document.createElement('div');
        card.className = `item-card ${item.concluido ? 'completed' : ''}`;
        card.dataset.itemId = item.id;
        
        const badgeClass = item.concluido ? 'concluido' : 'pendente';
        const badgeText = item.concluido ? 'Concluído' : 'Pendente';
        
        // Elementos internos do Card
        card.innerHTML = `
            <div class="item-header">
                <input type="checkbox" class="completion-checkbox" ${item.concluido ? 'checked' : ''} id="checkbox-${item.id}">
                <h3 class="item-title">${item.titulo}</h3>
                <span class="badge ${badgeClass}">${badgeText}</span>
            </div>
            <p class="item-description">${item.descricao || 'Sem descrição.'}</p>
            <div class="item-actions">
                <button class="btn-icon btn-edit" data-item-id="${item.id}">
                    <i class="fas fa-edit"></i> Editar
                </button>
                <button class="btn-icon btn-delete" data-item-id="${item.id}">
                    <i class="fas fa-trash-alt"></i> Remover
                </button>
            </div>
        `;
        
        // Adiciona Listeners no Card Renderizado
        
        // 1. Listener do Checkbox (PATCH)
        const checkbox = card.querySelector('.completion-checkbox');
        checkbox.addEventListener('change', (e) => {
            const isCompleted = e.target.checked;
            updateItemStatus(item.id, isCompleted, card);
        });

        // 2. Listener do Botão de Edição (PUT)
        const editBtn = card.querySelector('.btn-edit');
        editBtn.addEventListener('click', () => {
            // Busca o item completo antes de abrir o modal (para ter certeza dos dados)
            openEditModal({
                id: item.id,
                titulo: item.titulo,
                descricao: item.descricao,
                concluido: item.concluido
            });
        });

        // 3. Listener do Botão de Remoção (DELETE)
        const deleteBtn = card.querySelector('.btn-delete');
        deleteBtn.addEventListener('click', () => {
             // Usamos um modal customizado ou confirmação em tela em vez de alert/confirm.
             // Por simplificação aqui, vamos direto.
             deleteItem(item.id, card);
        });

        itemListContainer.appendChild(card);
    });
}

/**
 * Adiciona um novo item (POST).
 */
async function addItem(e) {
    e.preventDefault();
    
    const titulo = tituloInput.value.trim();
    const descricao = descricaoInput.value.trim();
    
    if (!titulo) return;
    
    const payload = {
        titulo: titulo,
        descricao: descricao,
        concluido: false
    };

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            throw new Error(`Falha ao adicionar: ${response.statusText}`);
        }

        // Limpa o formulário e recarrega a lista
        tituloInput.value = '';
        descricaoInput.value = '';
        await fetchAndRenderItems();
        
    } catch (error) {
        console.error("Erro ao adicionar item:", error);
        alert(`Erro ao adicionar item: ${error.message}`);
    }
}

/**
 * Edita um item existente (PUT) via modal.
 */
async function editItem(e) {
    e.preventDefault();
    
    const id = parseInt(editIdInput.value);
    const titulo = editTituloInput.value.trim();
    const descricao = editDescricaoInput.value.trim();
    
    if (!titulo || isNaN(id)) return;

    const currentCard = document.querySelector(`.item-card[data-item-id="${id}"]`);
    const isCompleted = currentCard ? currentCard.classList.contains('completed') : false;

    const payload = {
        titulo: titulo,
        descricao: descricao,
        concluido: isCompleted // Mantém o status de conclusão atual
    };

    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        if (!response.ok) {
            throw new Error(`Falha ao salvar: ${response.statusText}`);
        }

        // Fecha o modal e recarrega a lista para mostrar a alteração
        closeEditModal();
        await fetchAndRenderItems();
        
    } catch (error) {
        console.error("Erro ao salvar edição:", error);
        alert(`Erro ao salvar edição: ${error.message}`);
    }
}


/**
 * Remove um item (DELETE).
 */
async function deleteItem(id, cardElement) {
    
    // Confirmação simples via console, idealmente seria um modal
    console.log(`Tentando deletar item ${id}...`);

    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`Falha ao remover: ${response.statusText}`);
        }

        // Remove o card do DOM sem recarregar toda a lista
        cardElement.remove();
        
        // Verifica se a lista ficou vazia
        if (itemListContainer.children.length === 0) {
            fetchAndRenderItems();
        }
        
    } catch (error) {
        console.error("Erro ao remover item:", error);
        alert(`Erro ao remover item: ${error.message}`);
    }
}


/**
 * Atualiza o status de conclusão de um item (PATCH).
 * @param {number} id - ID do item.
 * @param {boolean} isCompleted - Novo status de conclusão.
 * @param {HTMLElement} cardElement - O elemento DOM do card.
 */
async function updateItemStatus(id, isCompleted, cardElement) {
    
    const payload = {
        concluido: isCompleted
    };

    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!response.ok) {
            throw new Error(`Falha ao atualizar status: ${response.statusText}`);
        }

        const updatedItem = await response.json();
        
        // --- Atualização visual aprimorada ---
        const badge = cardElement.querySelector('.badge');
        const checkbox = cardElement.querySelector('.completion-checkbox');
        
        // Garante que o checkbox (se não foi ele que disparou o evento) reflita o estado
        if (checkbox) {
            checkbox.checked = updatedItem.concluido;
        }

        if (updatedItem.concluido) {
            cardElement.classList.add('completed');
            badge.textContent = 'Concluído';
            badge.className = 'badge concluido';
        } else {
            cardElement.classList.remove('completed');
            badge.textContent = 'Pendente';
            badge.className = 'badge pendente';
        }
        
    } catch (error) {
        console.error("Erro ao atualizar item:", error);
        // Em caso de falha, forçamos o recarregamento para garantir a sincronização com o backend
        alert(`Erro ao atualizar item: ${error.message}. Recarregando a lista.`);
        await fetchAndRenderItems();
    }
}


// --- INICIALIZAÇÃO ---

// Adiciona listener para o formulário de adição
form.addEventListener('submit', addItem);

// Adiciona listener para o formulário de edição (dentro do modal)
editForm.addEventListener('submit', editItem);

// Carrega os itens na inicialização
fetchAndRenderItems();