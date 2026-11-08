# GM Fitness

App Flutter para quem está começando na academia. Funciona **100% offline**: o catálogo, as animações e os seus treinos ficam no aparelho.

## O que tem no app

- **Perfil feminino ou masculino**, escolhido na primeira abertura. Ele muda o boneco das animações, os planos sugeridos e as observações de cada exercício para aquele corpo.
- **Planos por formato de corpo**, 5 dias por semana. Feminino: triângulo invertido, triângulo (pera), ampulheta, retângulo e oval. Masculino: trapézio (V), triângulo invertido, retângulo, triângulo e oval. Além disso, "Primeiros passos" (3 dias, corpo inteiro) para quem nunca treinou.
- **94 exercícios** com passo a passo, dicas, erros comuns e, nos principais, observações para o corpo feminino e masculino.
- **Animações explicadas**: boneco com volume e roupas, músculos trabalhados em destaque, percurso do movimento com seta, posição inicial em transparência, fase atual, modo lento, tela cheia e as poses de início, meio e fim. São 88 movimentos.
- **Treino de hoje**: semana com a quantidade de exercícios por dia, marcação do que já foi feito e barra de progresso.
- **Carga** com números grandes e a cor da anilha correspondente (padrão olímpico), mais o histórico de cada mudança.
- **Exercícios personalizados**, com a animação mais parecida.
- Visual próprio: cores das anilhas, fontes Barlow e Barlow Condensed, ícone do app e tema claro e escuro.

## Como rodar

Requisitos: **Flutter 3.47.9** (stable, com Dart 3.13) ou mais novo. Confira com `flutter --version` e atualize com `flutter upgrade`.

```bash
git clone https://github.com/Matheus-Rezende/gm-fitness.git
cd gm-fitness
flutter pub get
flutter run
```

### Android

Com um emulador aberto ou um celular conectado com a depuração USB ativa, `flutter run` instala o app. Para gerar o APK:

```bash
flutter build apk --release
```

O APK de cada versão também fica disponível na aba **Actions** do GitHub, na execução mais recente, em "gm-fitness-apk".

### iOS

Precisa de um Mac com Xcode. Rode `flutter run` com o simulador aberto, ou abra `ios/Runner.xcworkspace` no Xcode, escolha sua conta em **Signing & Capabilities** e instale num iPhone. O GitHub compila a versão de iOS (sem assinatura) a cada envio para garantir que o projeto continua funcionando.

## Estrutura

```
android/, ios/              projetos nativos (gerados pelo Flutter 3.47.9)
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
  make_icons.py             gera os ícones de Android e iOS
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
