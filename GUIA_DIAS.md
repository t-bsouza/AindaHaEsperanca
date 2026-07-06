# Ainda Há Esperança — Guia de Fluxo Diário

## Mecânicas Essenciais

| Ação | Custo de tempo |
|---|---|
| Coletar ervas | 3h |
| Aplicar mistura | 3h |
| Descansar | 1h |
| Recusar paciente | 1h |

**Locais de coleta:**
- Porto → +2 Artemísia, +1 Sálvia
- Floresta → +2 Valeriana, +1 Sálvia
- Campo → +2 Sálvia, +1 Artemísia

**Hora de início:** 7h | **Noite (fim do dia):** 21h → 14 horas úteis

**Progressão de saúde:** ESTÁVEL → DEBILITADO → CRÍTICO → TERMINAL → MORTO  
`progress_disease()` é chamado para cada personagem vivo ao fim de cada dia (exceto RECUPERADO).

---

## Misturas da Praga

| Mistura | Fase | Efeito |
|---|---|---|
| A → V → S (cinza, branca, amarga) | Dias 1–5 | **Adiamento** — pula 1 ciclo de progressão |
| V → S → A (branca, amarga, cinza) | Qualquer fase | **Cura verdadeira** — remove a praga; com `auto_heals_after_cure`: RECUPERADO |
| A → V → S | Dia 6+ (praga mutada) | **DANO** — piora o paciente! |

**A ordem importa.** A→V→S ≠ V→S→A.

**Regra de Nara:** `resource_multiplier: 2` — cada erva custa o dobro (A|A|A = 6 Artemísia).

---

## Personagens e Doenças

| Personagem | Dia | Severidade inicial | Praga | Auto-cura |
|---|---|---|---|---|
| Nara Machado | 1, 2 | ESTÁVEL (35) | Não | Não |
| Tomás | 2 | CRÍTICO (65) | Sim | Sim |
| Seu Antônio | 3 | DEBILITADO (55) | Sim | Sim |
| Clara Mendes | 4 | DEBILITADO (45) | Sim | Sim |
| Dona Perpétua | 5 | CRÍTICO (65) | Sim | Sim |
| Padre Alves | 6 | TERMINAL (75) | Sim | Sim |

`auto_heals_after_cure: true` — ao curar a praga com V→S→A, o personagem vai direto para RECUPERADO.

---

## Fluxo Diário — Caminho Ótimo (todos sobrevivem)

**Recursos iniciais:** A:3 V:3 S:3

---

### Dia 1 — Segunda-feira

**Eventos fixos:**
- 7h: Tutorial de coleta (narrativa, sem custo)
- 13h: Tutorial de mistura (narrativa, sem custo) + Nara chega (expira às 16h)
- 16h: Garoto Mudo — avisa sobre a praga; dica: *cinza=A, branca=V, amarga=S → A→V→S adia*

**Ações:**
1. 7h→10h: **Porto** (+2A +1S) → A:5 V:3 S:4
2. 10h→13h: **Porto** (+2A +1S) → A:7 V:3 S:5
3. 13h: **Tratar Nara** com A→A→A (custo ×2 = −6A) → A:1 V:3 S:5 → Nara **RECUPERADA**
4. 16h: Narrativa do Garoto Mudo (sem custo)
5. 16h→19h: **Floresta** (+2V +1S) → A:1 V:5 S:6

**Fim do Dia 1:** A:1 V:5 S:6 | Nara: RECUPERADA

---

### Dia 2 — Terça-feira

**Eventos fixos:**
- 14h: Nara retorna (RECUPERADA — não precisa de tratamento; expira às 16h sem piorar)
- 16h: Garoto Mudo — revela a **cura verdadeira**: *branca primeiro, amarga depois, cinza por último → V→S→A*
- 19h: **Tomás** chega (praga ativa, CRÍTICO; expira às 21h; `dies_if_untreated: true`)

**Ações:**
1. 7h→10h: **Porto** (+2A +1S) → A:3 V:5 S:7
2. 10h→13h: **Porto** (+2A +1S) → A:5 V:5 S:8
3. 13h→14h: **Descansar** (aguardar Nara)
4. 14h–16h: Nara presente — RECUPERADA, deixar expirar naturalmente
5. 16h: Narrativa do Garoto Mudo → anotar **V→S→A**!
6. 16h→19h: **Porto** (+2A +1S) → A:7 V:5 S:9
7. 19h: **Tratar Tomás** com V→S→A (−1A −1V −1S) → A:6 V:4 S:8 → Tomás **RECUPERADO**

**Fim do Dia 2:** A:6 V:4 S:8 | Tomás: RECUPERADO

> **Chave do final perfeito:** a dica do Garoto Mudo no Dia 2 revela V→S→A antes que Tomás expire.
> Use V→S→A em Tomás às 19h — não espere o Dia 4 para descobrir a cura.
   
---

### Dia 3 — Quarta-feira

**Eventos fixos:**
- 8h: Narrativa de reflexão — *"a praga bloqueia tratamentos comuns; curar a praga primeiro"*
- 11h: **Seu Antônio** chega (praga ativa, DEBILITADO; expira às 14h)

**Ações:**
1. 7h→10h: **Porto** (+2A +1S) → A:8 V:4 S:9
2. 10h→11h: Descansar / esperar
3. 11h: **Tratar Antônio** com V→S→A (−1A −1V −1S) → A:7 V:3 S:8 → Antônio **RECUPERADO** (termina às 14h)
4. 14h→17h: **Floresta** (+2V +1S) → A:7 V:5 S:9
5. 17h→20h: **Floresta** (+2V +1S) → A:7 V:7 S:10

**Fim do Dia 3:** A:7 V:7 S:10 | Antônio: RECUPERADO

---

### Dia 4 — Quinta-feira

**Eventos fixos:**
- 8h: Garoto Mudo — confirma A→V→S como adiamento; diz para procurar "quem conhece a floresta"
- 13h: **Clara** chega (praga ativa, DEBILITADO; expira às 16h; `auto_heals_after_cure`)

**Ações:**
1. 7h→10h: **Porto** (+2A +1S) → A:9 V:7 S:11
2. 10h→13h: Descansar / esperar Clara
3. 13h: **Tratar Clara** com V→S→A (−1A −1V −1S) → A:8 V:6 S:10 → Clara **RECUPERADA**
   - Clara revela no diálogo: *"Valeriana primeiro, depois Sálvia, depois Artemísia"* — V→S→A confirmado!
4. 16h→19h: **Floresta** (+2V +1S) → A:8 V:8 S:11
5. 19h→22h=noite: **Porto** (+2A +1S) → A:10 V:8 S:12

**Fim do Dia 4:** A:10 V:8 S:12 | Clara: RECUPERADA

> **Fim do Dia 4 → início do Dia 5:** nenhuma progressão de doença (todos RECUPERADOS até agora).

---

### Dia 5 — Sexta-feira

**Eventos fixos:**
- 8h: Narrativa — a praga se espalhou por toda a vila
- 10h: **Dona Perpétua** chega (praga ativa, CRÍTICA; expira às 13h)

**⚠ Fim do Dia 5: a praga MUTA!** A→V→S passa a causar DANO a partir do Dia 6.

**Ações:**
1. 7h→10h: **Porto** (+2A +1S) → A:12 V:8 S:13 (Perpétua chega às 10h logo após)
2. 10h: **Tratar Perpétua** com V→S→A (−1A −1V −1S) → A:11 V:7 S:12 → Perpétua **RECUPERADA** (termina às 13h)
3. 13h→16h: **Floresta** (+2V +1S) → A:11 V:9 S:13
4. 16h→19h: **Floresta** (+2V +1S) → A:11 V:11 S:14

**Fim do Dia 5:** A:11 V:11 S:14 | **Praga mutada a partir de agora!**

---

### Dia 6 — Sábado

**Eventos fixos:**
- 8h: Narrativa — *"A praga mutou. A→V→S agora piora o paciente. Use V→S→A."*
- 11h: **Padre Alves** chega (praga **mutada**, TERMINAL; expira às 14h)

**⚠ NÃO use A→V→S no Dia 6+! Causa DANO.**

**Ações:**
1. 8h→11h: **Porto** (+2A +1S) → A:13 V:11 S:15 (Padre Alves chega ao final)
2. 11h: **Tratar Padre Alves** com V→S→A (−1A −1V −1S) → A:12 V:10 S:14 → Padre Alves **RECUPERADO**
3. 14h→17h: Coletar extra para reserva do Dia 7 (opcional)

**Fim do Dia 6:** A:12 V:10 S:14 | Padre Alves: RECUPERADO

---

### Dia 7 — Domingo (Último Dia)

**Se o caminho ótimo foi seguido:** todos os personagens estão RECUPERADOS.  
A fila do Dia 7 estará **vazia** — nenhum tratamento necessário.

**Se algum personagem não foi curado:** ele retorna no Dia 7 com praga **mutada** (inclusive Nara, se nunca foi tratada). Trate com V→S→A (lembrando que Nara custa ×2 = −2V −2S −2A).

- 8h: Narrativa final

**Condição de vitória:** nenhum personagem morreu.  
**Final perfeito:** todos os personagens vistos estão RECUPERADOS.

---

## Resumo dos Recursos — Caminho Ótimo

| Fim do dia | A | V | S | Situação |
|---|---|---|---|---|
| Início | 3 | 3 | 3 | — |
| Dia 1 | 1 | 5 | 6 | Nara RECUPERADA |
| Dia 2 | 6 | 4 | 8 | Tomás RECUPERADO |
| Dia 3 | 7 | 7 | 10 | Antônio RECUPERADO |
| Dia 4 | 10 | 8 | 12 | Clara RECUPERADA |
| Dia 5 | 11 | 11 | 14 | Perpétua RECUPERADA; praga muta |
| Dia 6 | 12 | 10 | 14 | Padre Alves RECUPERADO |
| Dia 7 | — | — | — | Fila vazia → final perfeito |

---

## Dicas Críticas

1. **Leia o diário a cada dia.** As dicas do Garoto Mudo estão nas anotações.
2. **Cure a praga antes da doença.** Enquanto `has_plague = true`, qualquer mistura de doença do receituário vai para o resultado "praga", não para a doença.
3. **Valeriana é escassa via Porto.** Para acumular V, priorize a Floresta em dias sem paciente urgente.
4. **Nara custa o dobro.** Cada erva da mistura dela custa 2 — A→A→A gasta 6 Artemísia. Colete Porto duas vezes antes de tratá-la no Dia 1.
5. **Personagens RECUPERADOS não pioram** ao serem ignorados ou ao expirar. Nara no Dia 2 pode ser dispensada com segurança.
6. **Tomás é o teste mais difícil.** Ele aparece apenas no Dia 2, às 19h, e morre se não tratado. A dica de V→S→A é dada às 16h do mesmo dia pelo Garoto Mudo — você tem uma janela de 3 horas para agir.
7. **Dia 6: praga mutada.** V→S→A ainda cura. A→V→S agora causa DANO. Padre Alves chega em estado TERMINAL — não perca tempo.
