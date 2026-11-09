# GM Fitness

App Flutter para quem está começando na academia. Funciona **offline**: o catálogo, as animações e os seus treinos ficam no aparelho. A internet só é usada para procurar atualizações do app.

## O que tem no app

- **Sobre você**: a introdução pergunta idade, altura, peso, cintura (opcional), objetivo (emagrecer, definir, ganhar massa ou saúde) e nível de atividade. Tudo pode ser mudado no perfil.
- **Aba Evolução**: IMC (OMS), faixa de peso saudável, calorias e proteína do dia (Mifflin-St Jeor), água, relação cintura/altura, gráfico do peso, previsão realista para chegar à meta, treinos das últimas 4 semanas e um plano de ação para o objetivo. Metas abaixo do peso saudável não são aceitas, e para menores de 18 anos o app não calcula calorias.
- **Atualização dentro do app** (Android): ao abrir o app, ele procura uma versão nova na página de Releases, mostra as novidades e atualiza com um toque, sem perder os dados.
- **Configurações** (engrenagem no perfil): tema automático, claro ou escuro, cor de destaque, tamanho do texto, som e vibração no fim do descanso, atualizações, novidades de cada versão, privacidade e licenças.
- **Perfil feminino ou masculino**, escolhido na primeira abertura. Ele muda o boneco das animações, os planos sugeridos e as observações de cada exercício para aquele corpo.
- **Planos por formato de corpo**, 5 dias por semana. Feminino: triângulo invertido, triângulo (pera), ampulheta, retângulo e oval. Masculino: trapézio (V), triângulo invertido, retângulo, triângulo e oval. Para quem nunca treinou ou não sabe o formato do corpo, "Primeiros passos" em 5 dias (um feminino e um masculino) ou em 3 dias.
- **94 exercícios** com passo a passo, dicas, erros comuns e, nos principais, observações para o corpo feminino e masculino.
- **Animações em 3D com troca de perspectiva**: veja o exercício de lado, em ¾, de frente ou de costas, ou arraste o boneco para girá-lo. O boneco e os aparelhos são malhas 3D com luz e sombra (desenhadas com `Canvas.drawVertices`), então não deformam ao girar. Corpo com músculos, roupas, rosto e tênis, músculos trabalhados em destaque, percurso do movimento com seta, posição inicial em transparência, fase atual, modo lento, tela cheia e as poses de início, meio e fim. São 88 movimentos.
- **Treino de hoje**: semana com a quantidade de exercícios por dia, marcação do que já foi feito e barra de progresso.
- **Treino cronometrado**: "Iniciar treino" liga o cronômetro do dia, marca cada série, conta o descanso e, ao finalizar, pede o esforço percebido (0 a 10). O resumo mostra tempo, séries, volume levantado, a intensidade (leve, moderada, alta ou muito alta), a carga da sessão comparada com a sua média e sugestões de carga para o próximo treino. Tudo fica no histórico.
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

Para instalar sem computador, abra a página de **Releases** do repositório no navegador do celular e baixe o APK da versão mais recente.

Para publicar uma versão nova:

1. Aumente `version:` no `pubspec.yaml` (por exemplo, de `0.5.0+5` para `0.6.0+6`) e `kAppVersion` em `lib/version.dart` (um teste confere se os dois batem).
2. Escreva as novidades em uma seção `## 0.6.0` no `CHANGELOG.md`. Esse texto aparece na Release e no aviso de atualização do app.
3. Envie para a `main`. O GitHub gera o APK assinado e cria a Release `v0.6.0`; os celulares com o app recebem o aviso na próxima vez que abrirem.

Também dá para disparar à mão em **Actions → Publicar versão → Run workflow**.

### Assinatura do APK

O Android só instala uma atualização por cima se as duas versões tiverem a mesma assinatura. Por isso a Release usa uma chave fixa, guardada em dois segredos do repositório (**Settings → Secrets and variables → Actions**):

- `ANDROID_KEYSTORE_BASE64`: o arquivo `.jks` em base64 (`base64 -w0 gm-fitness-release.jks`).
- `ANDROID_KEYSTORE_PASSWORD`: a senha da chave (alias `gmfitness`).

Sem eles, a publicação para com um aviso. Guarde uma cópia da chave fora do GitHub: se ela se perder, as próximas versões não instalam por cima e quem usa o app precisa desinstalar e instalar de novo.

Para gerar um APK assinado na sua máquina, crie `android/key.properties` (ele não vai para o GitHub):

```properties
storeFile=/caminho/para/gm-fitness-release.jks
storePassword=SUA_SENHA
keyAlias=gmfitness
```

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
