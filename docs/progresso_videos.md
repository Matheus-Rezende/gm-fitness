# Progresso dos vídeos dos exercícios (Google Flow)

Arquivo de controle para retomar a geração dos vídeos quando os créditos do Flow renovarem
(50 créditos grátis por dia; créditos mensais do plano renovam todo dia 10).

## Como gerar (padrão que funcionou)

- Projeto no Flow: https://flow.google.com/project/5f33965a-3b4c-41e6-975d-81d0919ea3bf
- Referências: imagens "Man standing in gym" e "Woman standing in gym" (camiseta azul, short/legging preta, tênis branco).
- Para cada exercício: pesquisar a execução correta na internet, gerar a imagem da posição inicial
  (homem e mulher, Nano Banana, 0 crédito), conferir, e gerar o vídeo de 8 s com Omni 1.2 Flash a 360p
  usando a imagem como primeiro e último quadro (8 créditos cada), com o tempo de cada fase descrito.
- Movimentos que trocam o apoio (subir em caixote) funcionaram melhor com Veo 3.1 Lite (10 créditos).
- Movimentos de membros alternados (dead bug): imagem inicial + imagem da posição final, vídeo de 4 s
  com Omni entre as duas, e montagem de ida + pausa + volta (trecho ao contrário) no app.
- Conferir os quadros de cada vídeo antes de aceitar. Uma tentativa por vídeo; erro é anotado e avisado.
- Vídeos prontos vão para coleções no Flow; o usuário baixa em .zip e envia para entrar no app
  (`assets/videos/<id>_m.mp4` e `<id>_f.mp4`, lista em `lib/widgets/exercise_video.dart`).

## Ordem combinada

1. Exercícios com máquina (aparelho, polia, Smith, esteira, remo).
2. Por último, exercícios sem máquina (barra, halter, kettlebell, peso corporal).

## Status (atualizado em 12/11/2026, saldo ~5 créditos; 50 grátis amanhã)

Legenda: [x] pronto no Flow · [~] gerado, com ressalva · [ ] falta

### Correções
- [x] dead_bug (homem e mulher) — vídeos de 4 s na coleção "GM Fitness - videos corrigidos"; montar 8 s no app (ida + pausa + volta).

### Máquinas
- [x] remo_ergometro — coleção "GM Fitness - novos exercicios"
- [x] mesa_flexora — novos exercicios
- [x] coice_polia — novos exercicios
- [x] pulldown_bracos_estendidos — novos exercicios
- [~] voador_invertido — HOMEM ok (vídeo de 4 s, vista de trás, montar ida+volta). MULHER falhou 3x (a 3ª com Veo 3.1 Fast em 12/11: braços quase não abrem) — decidir com o usuário
- [x] barra_fixa_assistida — novos exercicios
- [x] cadeira_adutora — mulher ok (novos exercicios); homem refeito em 12/11 (vídeo de 4 s, montar ida+volta)
- [x] abducao_polia — homem em novos exercicios; MULHER caiu na coleção "videos corrigidos"
- [x] crossover — refeito com Veo 3.1 Fast em 12/11 (homem e mulher, mãos se encontram à frente; mulher faz 2 repetições)
- [~] panturrilha_sentado — gerado 12/11 (movimento sutil, conferir no celular)
- [x] hiperextensao_lombar — 12/11
- [x] voador — 12/11 (vídeos de 4 s, montar ida+volta)
- [x] agachamento_smith — 12/11
- [x] pull_through — 12/11
- [x] rosca_polia — 12/11
- [~] corrida_esteira — 12/11 (parece trote leve; mulher perto do painel)
- [x] corrida_intervalada — 12/11 (sprint)

### Sem máquina
Gerados em 12/11 (Omni 1.2 Flash, 8 s, soltos na aba Vídeos):
- [x] elevacao_pelvica — homem e mulher
- [~] agachamento_barra — homem ok (agacha fundo); mulher desce pouco e o rack tapa parte
- [~] stiff_barra — mulher ok; homem desce só até o joelho
- [x] agachamento_bulgaro — homem e mulher
- [x] abdominal_bicicleta — homem e mulher
- [x] rosca_direta_barra — homem e mulher
- [~] caminhada_fazendeiro — homem e mulher dão poucos passos quase no lugar e param
- [x] remada_curvada_barra — homem e mulher
- [x] remada_curvada_halteres — homem e mulher

Faltam (próximo: agachamento_sumo):
agachamento_sumo, crucifixo_halteres, afundo_halteres, elevacao_pernas, marcha_estacionaria,
agachamento_livre, agachamento_goblet_kettlebell, agachamento_sumo_kettlebell, afundo,
levantamento_terra, bom_dia, abducao_deitada, agachamento_isometrico, swing_kettlebell,
supino_reto_barra, supino_inclinado_barra, flexao_braco, flexao_joelhos, paralelas, barra_fixa,
desenvolvimento_barra, elevacao_frontal, encolhimento, rosca_scott, triceps_frances, triceps_testa,
triceps_coice, triceps_banco, escalador, giro_russo, elevacao_pernas_barra, super_homem,
polichinelo, pular_corda, burpee


Obs. 12/11: os vídeos gerados em 12/11 ainda NÃO foram movidos para a coleção "GM Fitness - novos exercicios" (arrastar no Flow está falhando); estão soltos no topo da aba Vídeos do projeto.
