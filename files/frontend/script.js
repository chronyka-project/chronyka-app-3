// IMPORTANTE: AGORA VOCÊ ESTÁ USANDO O LOCALHOST (SUA MÁQUINA)
// O Flask está rodando na porta 5000.
const API_URL = 'http://127.0.0.1:5000/itens'; 

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

// Listeners para fechar o modal
closeModalBtn.addEventListener('click', closeEditModal);
editModal.addEventListener('click', (e) => {
    // Fecha se clicar no overlay (fundo escuro), mas não no conteúdo do modal
    if (e.target.id === 'edit-modal') {
        closeEditModal();
    }
});


// --- RENDERIZAÇÃO E GET DE ITENS ---

/**
 * Cria o elemento HTML para um único item da lista, incluindo o checkbox e o botão editar.
 * @param {Object} item - O objeto de item da API.
 */
function createCard(item) {
    const card = document.createElement('div');
    card.className = `item-card ${item.concluido ? 'completed' : ''}`;
    card.setAttribute('data-id', item.id);

    const statusClass = item.concluido ? 'concluido' : 'pendente';
    const statusText = item.concluido ? 'Concluído' : 'Pendente';

    card.innerHTML = `
        <div class="item-status-wrapper">
            <!-- CHECKBOX DE CONCLUSÃO -->
            <input type="checkbox" class="completion-checkbox" data-id="${item.id}" ${item.concluido ? 'checked' : ''}>

            <div class="item-details">
                <h3>${item.titulo}</h3>
                <p>${item.descricao || 'Nenhuma descrição fornecida.'}</p>
                <span class="badge ${statusClass}">${statusText}</span>
            </div>
        </div>
        
        <div class="item-actions">
            <!-- NOVO BOTÃO DE EDIÇÃO -->
            <button class="btn-edit" data-id="${item.id}" data-titulo="${item.titulo}" data-descricao="${item.descricao || ''}">
                <i class="fas fa-edit"></i> Editar
            </button>
            <button class="btn-delete" data-id="${item.id}">
                <i class="fas fa-trash-alt"></i> Remover
            </button>
        </div>
    `;
    
    // 1. Listener de remoção ao botão DELETE
    card.querySelector('.btn-delete').addEventListener('click', (e) => {
        e.stopPropagation(); 
        deleteItem(item.id);
    });

    // 2. Listener de clique ao CHECKBOX para conclusão/pendente
    const checkbox = card.querySelector('.completion-checkbox');
    checkbox.addEventListener('change', () => {
        toggleCompletion(item.id, checkbox.checked, card);
    });
    
    // 3. NOVO: Listener de clique ao botão EDITAR para abrir o modal
    card.querySelector('.btn-edit').addEventListener('click', (e) => {
        e.stopPropagation();
        openEditModal(item);
    });


    return card;
}

/**
 * Busca todos os itens da API e renderiza-os na tela.
 */
async function fetchAndRenderItems() {
    itemListContainer.innerHTML = '<p class="loading-message">Carregando itens...</p>';

    try {
        const response = await fetch(API_URL);
        
        if (!response.ok) {
            throw new Error(`Erro de rede: ${response.status} ${response.statusText}`);
        }

        const itens = await response.json();

        itemListContainer.innerHTML = '';
        if (itens.length === 0) {
            itemListContainer.innerHTML = '<p class="empty-message">Nenhuma tarefa encontrada. Adicione uma nova!</p>';
        } else {
            // Renderiza os itens do mais novo para o mais antigo (id decrescente)
            itens.reverse().forEach(item => {
                itemListContainer.appendChild(createCard(item));
            });
        }

    } catch (error) {
        console.error("Erro ao buscar dados:", error);
        itemListContainer.innerHTML = `<p class="error-message">
            Erro ao carregar dados: ${error.message}. 
            Verifique se o **servidor Flask** está rodando na porta 5000.
        </p>`;
    }
}

// --- ADIÇÃO DE ITEM (POST) ---

/**
 * Envia um novo item para a API via POST.
 */
async function addItem(e) {
    e.preventDefault(); 

    const titulo = tituloInput.value.trim();
    const descricao = descricaoInput.value.trim();

    if (!titulo) return;

    try {
        const response = await fetch(API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                titulo: titulo,
                descricao: descricao,
                concluido: false 
            })
        });

        if (!response.ok) {
            throw new Error(`Falha ao adicionar: ${response.statusText}`);
        }

        // Limpa o formulário e recarrega a lista para mostrar o novo item
        tituloInput.value = '';
        descricaoInput.value = '';
        await fetchAndRenderItems(); 

    } catch (error) {
        console.error("Erro ao adicionar item:", error);
        alert(`Erro ao adicionar item: ${error.message}`);
    }
}


// --- EDIÇÃO DE ITEM (PATCH) ---

/**
 * Envia alterações de um item para a API via PATCH.
 */
async function editItem(e) {
    e.preventDefault(); 
    
    const id = editIdInput.value;
    const titulo = editTituloInput.value.trim();
    const descricao = editDescricaoInput.value.trim();

    if (!titulo || !id) return;

    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                titulo: titulo,
                descricao: descricao
                // Note: Não enviamos 'concluido' aqui, pois ele é tratado pelo checkbox
            })
        });

        if (!response.ok) {
            throw new Error(`Falha ao editar: ${response.statusText}`);
        }

        // Fecha o modal e recarrega a lista para mostrar as alterações
        closeEditModal();
        await fetchAndRenderItems(); 

    } catch (error) {
        console.error("Erro ao editar item:", error);
        alert(`Erro ao editar item: ${error.message}`);
    }
}


// --- REMOÇÃO DE ITEM (DELETE) ---

/**
 * Remove um item da API via DELETE.
 * @param {number} id - ID do item a ser removido.
 */
async function deleteItem(id) {
    if (!window.confirm(`Tem certeza que deseja remover a tarefa com ID ${id}?`)) {
        return;
    }

    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'DELETE'
        });

        if (!response.ok) {
            throw new Error(`Falha ao remover: ${response.statusText}`);
        }

        const cardToRemove = itemListContainer.querySelector(`[data-id="${id}"]`);
        if (cardToRemove) {
            cardToRemove.remove();
        }
        
        if (itemListContainer.children.length === 0) {
            itemListContainer.innerHTML = '<p class="empty-message">Nenhuma tarefa encontrada. Adicione uma nova!</p>';
        }

    } catch (error) {
        console.error("Erro ao remover item:", error);
        alert(`Erro ao remover item: ${error.message}`);
    }
}


// --- TOGGLE CONCLUSÃO (PATCH) ---

/**
 * Alterna o status de conclusão de um item (PATCH).
 * @param {number} id - ID do item a ser atualizado.
 * @param {boolean} newStatus - O novo status (true para concluído, false para pendente).
 * @param {HTMLElement} cardElement - O elemento HTML do cartão para atualização visual.
 */
async function toggleCompletion(id, newStatus, cardElement) {
    try {
        const response = await fetch(`${API_URL}/${id}`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ concluido: newStatus })
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