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

## Status (atualizado em 11/11/2026, saldo ~323 créditos)

Legenda: [x] pronto no Flow · [~] gerado, com ressalva · [ ] falta

### Correções
- [x] dead_bug (homem e mulher) — vídeos de 4 s na coleção "GM Fitness - videos corrigidos"; montar 8 s no app (ida + pausa + volta).

### Máquinas
- [x] remo_ergometro — coleção "GM Fitness - novos exercicios"
- [x] mesa_flexora — novos exercicios
- [x] coice_polia — novos exercicios
- [x] pulldown_bracos_estendidos — novos exercicios
- [ ] voador_invertido — 1ª tentativa ruim (braços quase não abrem); refazer com vista de trás e Veo
- [x] barra_fixa_assistida — novos exercicios
- [~] cadeira_adutora — mulher ok (novos exercicios); HOMEM refazer (pernas não fecham)
- [x] abducao_polia — homem em novos exercicios; MULHER caiu na coleção "videos corrigidos"
- [ ] crossover
- [ ] panturrilha_sentado
- [ ] hiperextensao_lombar
- [ ] voador
- [ ] agachamento_smith
- [ ] pull_through
- [ ] rosca_polia
- [ ] corrida_esteira
- [ ] corrida_intervalada

### Sem máquina
elevacao_pelvica, agachamento_barra, stiff_barra, agachamento_bulgaro, abdominal_bicicleta,
rosca_direta_barra, caminhada_fazendeiro, remada_curvada_barra, remada_curvada_halteres,
agachamento_sumo, crucifixo_halteres, afundo_halteres, elevacao_pernas, marcha_estacionaria,
agachamento_livre, agachamento_goblet_kettlebell, agachamento_sumo_kettlebell, afundo,
levantamento_terra, bom_dia, abducao_deitada, agachamento_isometrico, swing_kettlebell,
supino_reto_barra, supino_inclinado_barra, flexao_braco, flexao_joelhos, paralelas, barra_fixa,
desenvolvimento_barra, elevacao_frontal, encolhimento, rosca_scott, triceps_frances, triceps_testa,
triceps_coice, triceps_banco, escalador, giro_russo, elevacao_pernas_barra, super_homem,
polichinelo, pular_corda, burpee
