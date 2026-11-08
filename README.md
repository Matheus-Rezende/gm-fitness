# GM Fitness

App Flutter para quem está começando na academia. Funciona **100% offline**: o catálogo, as animações e os seus treinos ficam no aparelho.

## O que tem nesta primeira versão

- **Catálogo com 94 exercícios** (pernas, glúteos, peito, costas, ombros, braços, abdômen e cardio), com busca sem acento, filtro por grupo muscular e por equipamento.
- **Animação de cada exercício**: um boneco desenhado no próprio app executa o movimento em loop, com o nome da fase atual ("Desça controlando", "Suba"...), pausa e velocidade 0,5x. São 88 movimentos diferentes.
- **Passo a passo, dicas e erros comuns** de cada exercício.
- **Planos por formato de corpo** (5 dias por semana): triângulo invertido, triângulo (pera), ampulheta, retângulo e oval (maçã), além de "Primeiros passos" (3 dias, corpo inteiro) para quem nunca treinou.
- **Meus treinos**: lista por dia da semana, com séries, repetições, descanso e **carga** (botões de menos e mais ou toque para digitar). Cada mudança de carga entra no histórico.
- **Exercícios personalizados**: crie os seus, escolha o grupo muscular, o equipamento e a animação mais parecida.
- Tema claro e escuro automáticos.

## Como rodar

Este repositório guarda só o código do app (pasta `lib/`) e os dados (`assets/`). As pastas de plataforma (Android, Linux etc.) são geradas pelo próprio Flutter na primeira vez:

```bash
git clone git@github.com:Matheus-Rezende/gm-fitness.git
cd gm-fitness
flutter create . --project-name gm_fitness --org com.gmfitness --platforms=android,linux
flutter pub get
flutter run
```

O `flutter create .` não sobrescreve os arquivos que já existem, só cria os que faltam.

## Estrutura

```
lib/
  main.dart                 tema e carregamento inicial
  state/app_state.dart      catálogo + dados do usuário (shared_preferences)
  motion/                   leitura e desenho das animações
  screens/                  telas (Meus treinos, Exercícios, Planos, detalhe, criação)
  widgets/                  componentes reutilizados
assets/
  exercises.json            catálogo de exercícios (gerado)
  presets.json              planos por formato de corpo (gerado)
  motions.json              quadros das animações (gerado)
tools/
  motion_core.py            cinemática (ângulos e alvos das articulações)
  patterns.py               poses-chave de cada movimento
  motion_studio.py          gera motions.json e prévias em PNG
  catalog.py                catálogo e planos, com validação
```

### Como as animações funcionam

Cada movimento é descrito em `tools/patterns.py` por poses-chave: ângulo do tronco, posição do quadril e ângulos ou alvos das mãos e dos pés. O script resolve as articulações (com comprimento fixo de cada segmento do corpo, para nada "esticar"), interpola as poses no tempo e grava os quadros em `assets/motions.json`. O app só desenha esses quadros.

Para alterar ou criar um movimento:

```bash
python3 tools/motion_studio.py preview squat_bw    # gera tools/preview/squat_bw.png para conferir
python3 tools/motion_studio.py export              # atualiza assets/motions.json
python3 tools/catalog.py                           # valida e atualiza exercícios e planos
```

(precisa do Python 3 com a biblioteca Pillow para as prévias)

## Aviso

As animações e os planos são uma orientação geral de técnica e não substituem um profissional de educação física. Se tiver alguma condição de saúde, converse com seu médico antes de começar.
