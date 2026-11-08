"""Catálogo de exercícios e pré-definições por formato de corpo.

Gera assets/exercises.json e assets/presets.json e valida as referências
(animações existentes, ids únicos, exercícios usados nos planos).
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from patterns import PATTERNS  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GROUPS = {
    'peito': 'Peito', 'costas': 'Costas', 'ombros': 'Ombros', 'biceps': 'Bíceps', 'triceps': 'Tríceps',
    'trapezio': 'Trapézio', 'antebraco': 'Antebraço', 'abdomen': 'Abdômen', 'lombar': 'Lombar',
    'gluteos': 'Glúteos', 'quadriceps': 'Quadríceps', 'posterior': 'Posterior de coxa', 'adutores': 'Adutores',
    'abdutores': 'Abdutores', 'panturrilha': 'Panturrilha', 'cardio': 'Cardio', 'corpo_inteiro': 'Corpo inteiro',
}
EQUIP = {
    'peso_corporal': 'Peso corporal', 'halter': 'Halteres', 'barra': 'Barra', 'maquina': 'Máquina',
    'polia': 'Polia / cabo', 'kettlebell': 'Kettlebell', 'elastico': 'Elástico', 'smith': 'Smith',
    'barra_fixa': 'Barra fixa / paralelas', 'cardio': 'Aparelho de cardio',
}
LEVELS = {'iniciante': 'Iniciante', 'intermediario': 'Intermediário', 'avancado': 'Avançado'}

EX = []


def E(id, name, group, secondary, equipment, level, anim, steps, tips, mistakes):
    EX.append(dict(id=id, name=name, group=group, secondary=secondary, equipment=equipment, level=level,
                   anim=anim, steps=steps, tips=tips, mistakes=mistakes))


# ------------------------------------------------------------------ PERNAS E GLÚTEOS
E('agachamento_livre', 'Agachamento livre', 'quadriceps', ['gluteos', 'posterior', 'abdomen'], 'peso_corporal',
  'iniciante', 'squat_bw',
  ['Fique em pé com os pés entre a largura do quadril e dos ombros, pontas levemente para fora.',
   'Contraia o abdômen e leve o quadril para trás e para baixo, como quem vai sentar.',
   'Desça mantendo o calcanhar no chão e os joelhos apontando na mesma direção dos pés.',
   'Vá até as coxas ficarem perto da paralela ao chão, ou até onde mantiver a coluna neutra.',
   'Empurre o chão com o pé inteiro para subir, contraindo os glúteos no final.'],
  ['Estenda os braços à frente para ajudar no equilíbrio.',
   'Se o calcanhar sair do chão, diminua a profundidade e trabalhe a mobilidade do tornozelo.'],
  ['Deixar os joelhos caírem para dentro.', 'Tirar o calcanhar do chão.', 'Arredondar a lombar no fundo.'])

E('agachamento_goblet', 'Agachamento goblet com halter', 'quadriceps', ['gluteos', 'abdomen'], 'halter',
  'iniciante', 'squat_goblet',
  ['Segure um halter na vertical junto ao peito, com as duas mãos sob a cabeça do halter.',
   'Pés na largura dos ombros, pontas levemente para fora.',
   'Desça com o tronco firme, cotovelos indo para dentro dos joelhos.',
   'Mantenha o peito aberto e o halter colado ao corpo durante toda a descida.',
   'Suba empurrando o chão e estendendo quadril e joelhos juntos.'],
  ['É uma ótima forma de aprender o agachamento: o peso à frente ajuda a manter o tronco ereto.'],
  ['Afastar o halter do peito.', 'Inclinar demais o tronco à frente.'])

E('agachamento_goblet_kettlebell', 'Agachamento goblet com kettlebell', 'quadriceps', ['gluteos', 'abdomen'],
  'kettlebell', 'iniciante', 'squat_goblet',
  ['Segure o kettlebell pelas laterais da alça, junto ao peito.',
   'Pés na largura dos ombros e abdômen contraído.',
   'Desça levando o quadril para trás e para baixo, joelhos acompanhando os pés.',
   'Pare quando as coxas chegarem perto da paralela, sem perder a coluna neutra.',
   'Suba empurrando o chão com o pé inteiro.'],
  ['Mantenha os cotovelos apontando para baixo.'],
  ['Deixar o kettlebell puxar o tronco para frente.', 'Joelhos caindo para dentro.'])

E('agachamento_barra', 'Agachamento com barra', 'quadriceps', ['gluteos', 'posterior', 'lombar', 'abdomen'], 'barra',
  'intermediario', 'squat_bb',
  ['Apoie a barra no trapézio, atrás do pescoço, com as mãos firmes um pouco além dos ombros.',
   'Tire a barra do suporte, dê dois passos para trás e posicione os pés na largura dos ombros.',
   'Inspire, contraia o abdômen e desça levando o quadril para trás e para baixo.',
   'Mantenha joelhos alinhados com os pés e a barra sobre o meio do pé.',
   'Suba empurrando o chão e soltando o ar no final.'],
  ['Use os pinos de segurança do rack.', 'Comece com a barra vazia para aprender o movimento.'],
  ['Apoiar a barra no pescoço.', 'Deixar os joelhos caírem para dentro.', 'Arredondar a lombar.'])

E('agachamento_smith', 'Agachamento no Smith', 'quadriceps', ['gluteos', 'posterior'], 'smith', 'iniciante',
  'squat_smith',
  ['Apoie a barra do Smith no trapézio e destrave girando os punhos.',
   'Posicione os pés levemente à frente da linha da barra, na largura dos ombros.',
   'Desça controlando, com o tronco firme e os joelhos acompanhando os pés.',
   'Suba empurrando o chão até estender quase totalmente os joelhos.',
   'Ao terminar, trave a barra girando os punhos de volta.'],
  ['O trilho guia a barra, o que dá segurança para quem está começando.'],
  ['Pés muito à frente, que sobrecarregam a lombar.', 'Esquecer de travar a barra no final.'])

E('agachamento_sumo', 'Agachamento sumô com halter', 'gluteos', ['adutores', 'quadriceps'], 'halter', 'iniciante',
  'sumo_squat',
  ['Afaste bem os pés, mais que a largura dos ombros, com as pontas abertas.',
   'Segure um halter na vertical com as duas mãos, braços estendidos entre as pernas.',
   'Desça mantendo o tronco ereto e empurrando os joelhos para fora, na direção dos pés.',
   'Vá até as coxas ficarem perto da paralela ao chão.',
   'Suba apertando os glúteos e a parte interna das coxas.'],
  ['Quanto mais afastados os pés, mais trabalho para glúteos e adutores.'],
  ['Joelhos indo para dentro.', 'Inclinar o tronco à frente.'])

E('agachamento_sumo_kettlebell', 'Agachamento sumô com kettlebell', 'gluteos', ['adutores', 'quadriceps'],
  'kettlebell', 'iniciante', 'sumo_squat',
  ['Pés bem afastados e pontas abertas, kettlebell seguro pela alça entre as pernas.',
   'Tronco ereto e abdômen contraído.',
   'Desça empurrando os joelhos para fora, alinhados aos pés.',
   'Suba apertando glúteos e adutores, sem balançar o kettlebell.'],
  ['Mantenha os braços relaxados; quem trabalha são as pernas.'],
  ['Arredondar as costas para alcançar o chão.'])

E('afundo', 'Afundo (passo para trás)', 'quadriceps', ['gluteos', 'posterior'], 'peso_corporal', 'iniciante',
  'lunge',
  ['Em pé, pés na largura do quadril, mãos na cintura ou ao lado do corpo.',
   'Dê um passo largo para trás, apoiando a ponta do pé de trás.',
   'Desça até o joelho de trás quase tocar o chão, com a canela da frente na vertical.',
   'Empurre pelo calcanhar da perna da frente para voltar à posição inicial.',
   'Alterne as pernas ou complete as repetições de um lado.'],
  ['O passo para trás protege mais o joelho que o passo à frente.', 'Use uma parede para apoio no início.'],
  ['Joelho da frente caindo para dentro.', 'Passo curto demais, que joga o joelho muito à frente.'])

E('afundo_halteres', 'Afundo com halteres', 'quadriceps', ['gluteos', 'posterior'], 'halter', 'intermediario',
  'lunge_db',
  ['Segure um halter em cada mão, braços estendidos ao lado do corpo.',
   'Dê um passo largo para trás e apoie a ponta do pé.',
   'Desça com o tronco ereto até o joelho de trás quase tocar o chão.',
   'Empurre pelo calcanhar da frente para voltar.'],
  ['Mantenha os ombros para trás e o olhar à frente.'],
  ['Inclinar o tronco para frente.', 'Bater o joelho de trás no chão.'])

E('agachamento_bulgaro', 'Agachamento búlgaro', 'quadriceps', ['gluteos', 'posterior'], 'halter', 'intermediario',
  'bulgarian',
  ['Apoie o peito do pé de trás em um banco, a cerca de um passo e meio de distância.',
   'Segure halteres ao lado do corpo (ou faça sem peso no começo).',
   'Desça reto, com o tronco levemente inclinado e o joelho da frente alinhado ao pé.',
   'Pare quando a coxa da frente ficar perto da paralela.',
   'Suba empurrando pelo calcanhar da perna da frente. Complete as repetições e troque de perna.'],
  ['Inclinar levemente o tronco aumenta o trabalho de glúteo.', 'Faça perto de uma parede para equilíbrio.'],
  ['Pé da frente perto demais do banco.', 'Empurrar com a perna de trás.'])

E('subida_banco', 'Subida no banco (step-up)', 'gluteos', ['quadriceps', 'posterior'], 'peso_corporal', 'iniciante',
  'step_up',
  ['Fique de frente para um banco ou caixa firme, na altura do joelho ou mais baixo.',
   'Apoie o pé inteiro em cima do banco.',
   'Empurre pelo calcanhar do pé de cima e suba até ficar em pé sobre o banco.',
   'Desça devagar, controlando com a perna de cima.',
   'Complete as repetições e troque de perna.'],
  ['Comece com um banco baixo.', 'Para mais intensidade, segure halteres.'],
  ['Dar impulso com o pé de baixo.', 'Joelho de cima caindo para dentro.'])

E('leg_press_45', 'Leg press 45°', 'quadriceps', ['gluteos', 'posterior'], 'maquina', 'iniciante', 'leg_press',
  ['Sente-se com as costas e o quadril bem apoiados no encosto.',
   'Pés na plataforma na largura do quadril, no meio da placa.',
   'Destrave e flexione os joelhos levando a plataforma em direção ao peito.',
   'Desça até onde o quadril continuar apoiado no banco.',
   'Empurre com o pé inteiro até quase estender os joelhos, sem travar.'],
  ['Pés mais altos trabalham mais glúteo e posterior; mais baixos, mais quadríceps.'],
  ['Travar os joelhos no topo.', 'Tirar o quadril do banco no fundo.', 'Joelhos caindo para dentro.'])

E('cadeira_extensora', 'Cadeira extensora', 'quadriceps', [], 'maquina', 'iniciante', 'leg_extension',
  ['Ajuste o encosto para o joelho ficar alinhado ao eixo da máquina.',
   'Posicione o rolo logo acima do tornozelo e segure as alças laterais.',
   'Estenda os joelhos até as pernas ficarem quase retas.',
   'Segure um instante contraindo a coxa.',
   'Volte devagar, sem deixar o peso bater.'],
  ['Controle a descida em 2 a 3 segundos.'],
  ['Dar tranco para subir.', 'Tirar o quadril do banco.'])

E('mesa_flexora', 'Mesa flexora', 'posterior', ['panturrilha'], 'maquina', 'iniciante', 'leg_curl_lying',
  ['Deite de bruços com os joelhos logo após a borda do banco.',
   'Ajuste o rolo logo acima dos calcanhares e segure as alças.',
   'Flexione os joelhos trazendo os calcanhares em direção ao glúteo.',
   'Mantenha o quadril colado no banco.',
   'Volte devagar até quase estender as pernas.'],
  ['Pense em puxar com a parte de trás da coxa, não com a lombar.'],
  ['Tirar o quadril do banco.', 'Soltar o peso na volta.'])

E('cadeira_flexora', 'Cadeira flexora', 'posterior', [], 'maquina', 'iniciante', 'leg_curl_seated',
  ['Sente-se com o joelho alinhado ao eixo da máquina.',
   'Ajuste o apoio por cima das coxas e o rolo atrás dos tornozelos.',
   'Puxe os calcanhares para baixo e para trás, flexionando os joelhos.',
   'Segure um instante e volte devagar.'],
  ['O apoio firme sobre as coxas evita que o quadril saia do banco.'],
  ['Usar balanço do tronco.', 'Voltar rápido demais.'])

E('stiff_halteres', 'Stiff com halteres', 'posterior', ['gluteos', 'lombar'], 'halter', 'iniciante', 'rdl_db',
  ['Em pé, pés na largura do quadril, halteres à frente das coxas.',
   'Flexione levemente os joelhos e mantenha esse ângulo durante todo o movimento.',
   'Empurre o quadril para trás, descendo os halteres rente às pernas.',
   'Desça até sentir o alongamento atrás da coxa, por volta do meio da canela, com a coluna neutra.',
   'Suba levando o quadril à frente e contraindo os glúteos.'],
  ['O movimento é de quadril: pense em fechar uma porta com o bumbum.'],
  ['Arredondar a lombar.', 'Dobrar demais os joelhos, virando um agachamento.', 'Afastar os halteres das pernas.'])

E('stiff_barra', 'Stiff com barra (terra romeno)', 'posterior', ['gluteos', 'lombar'], 'barra', 'intermediario',
  'rdl_bb',
  ['Segure a barra na altura das coxas, mãos um pouco além da largura dos ombros.',
   'Ombros para trás, coluna neutra e joelhos levemente flexionados.',
   'Leve o quadril para trás deslizando a barra rente às coxas e canelas.',
   'Desça até o meio da canela ou até onde a coluna continuar neutra.',
   'Suba empurrando o quadril à frente, sem jogar o tronco para trás no final.'],
  ['Mantenha a barra perto do corpo o tempo todo.'],
  ['Arredondar as costas.', 'Barra longe das pernas.', 'Hiperestender a lombar no topo.'])

E('levantamento_terra', 'Levantamento terra', 'posterior', ['gluteos', 'lombar', 'costas', 'quadriceps', 'trapezio'],
  'barra', 'avancado', 'deadlift',
  ['Pés na largura do quadril com a barra sobre o meio do pé.',
   'Desça o quadril e segure a barra logo por fora das pernas, canelas encostando na barra.',
   'Peito aberto, coluna neutra e braços estendidos.',
   'Empurre o chão com as pernas e estenda o quadril, mantendo a barra colada ao corpo.',
   'Fique ereto no topo e desça levando o quadril para trás.'],
  ['Aprenda o stiff e a elevação pélvica antes.', 'Comece leve e priorize a técnica.'],
  ['Arredondar a lombar.', 'Puxar a barra com os braços.', 'Afastar a barra das canelas.'])

E('bom_dia', 'Bom dia (good morning)', 'posterior', ['lombar', 'gluteos'], 'barra', 'avancado', 'good_morning',
  ['Apoie a barra no trapézio como no agachamento.',
   'Pés na largura do quadril e joelhos levemente flexionados.',
   'Leve o quadril para trás inclinando o tronco, coluna sempre neutra.',
   'Desça até sentir o alongamento atrás das coxas.',
   'Suba empurrando o quadril à frente.'],
  ['Use carga bem leve; é um exercício de técnica.'],
  ['Arredondar as costas.', 'Descer além da sua mobilidade.'])

E('pull_through', 'Pull through na polia', 'gluteos', ['posterior'], 'polia', 'iniciante', 'pull_through',
  ['De costas para a polia baixa, segure a corda entre as pernas.',
   'Dê alguns passos à frente até o cabo ficar tenso.',
   'Leve o quadril para trás deixando a corda passar entre as pernas, coluna neutra.',
   'Estenda o quadril com força, contraindo os glúteos no final.'],
  ['Os braços só seguram; o movimento vem do quadril.'],
  ['Puxar com os braços.', 'Agachar em vez de levar o quadril para trás.'])

E('elevacao_pelvica', 'Elevação pélvica (hip thrust)', 'gluteos', ['posterior'], 'barra', 'intermediario',
  'hip_thrust',
  ['Apoie a parte alta das costas na borda de um banco, barra sobre o quadril com proteção.',
   'Pés no chão na largura do quadril, joelhos dobrados.',
   'Empurre pelos calcanhares e suba o quadril até ombros, quadril e joelhos ficarem em linha.',
   'No topo, a canela fica vertical, o queixo recolhido e o glúteo contraído por 1 segundo.',
   'Desça o quadril controlando.'],
  ['Pode ser feito com halter ou anilha no lugar da barra.', 'Olhe para frente, não para o teto.'],
  ['Arquear a lombar no topo em vez de contrair o glúteo.', 'Pés longe demais ou perto demais.'])

E('ponte_gluteo', 'Ponte de glúteo', 'gluteos', ['posterior', 'abdomen'], 'peso_corporal', 'iniciante',
  'glute_bridge',
  ['Deite de costas, joelhos dobrados e pés no chão na largura do quadril.',
   'Braços ao lado do corpo e abdômen levemente contraído.',
   'Empurre pelos calcanhares e suba o quadril até formar uma linha dos ombros aos joelhos.',
   'Contraia o glúteo por 1 a 2 segundos e desça devagar.'],
  ['Para dificultar, apoie um halter sobre o quadril ou faça com uma perna só.'],
  ['Arquear a lombar no topo.', 'Empurrar com a ponta dos pés.'])

E('coice_quatro_apoios', 'Coice em quatro apoios', 'gluteos', ['posterior'], 'peso_corporal', 'iniciante',
  'donkey_kick',
  ['Apoie mãos sob os ombros e joelhos sob o quadril.',
   'Contraia o abdômen para manter as costas retas.',
   'Com o joelho dobrado, leve a sola do pé em direção ao teto.',
   'Suba até a coxa ficar alinhada ao tronco, sem arquear a lombar.',
   'Volte sem encostar o joelho no chão e troque de lado no final.'],
  ['Pode usar caneleira para aumentar a carga.'],
  ['Arquear a lombar para subir mais.', 'Girar o quadril.'])

E('coice_polia', 'Coice na polia', 'gluteos', ['posterior'], 'polia', 'iniciante', 'cable_kickback',
  ['Prenda a caneleira da polia baixa no tornozelo.',
   'Segure na máquina e incline levemente o tronco à frente.',
   'Leve a perna para trás estendendo o quadril, joelho quase reto.',
   'Contraia o glúteo no fim e volte controlando.'],
  ['O movimento é curto: pare antes de arquear as costas.'],
  ['Balançar o corpo.', 'Arquear a lombar.'])

E('abducao_em_pe_elastico', 'Abdução de quadril em pé com elástico', 'abdutores', ['gluteos'], 'elastico',
  'iniciante', 'hip_abduction_standing',
  ['Coloque o elástico acima dos joelhos e fique de pé perto de um apoio.',
   'Tronco ereto e abdômen firme, peso na perna de apoio.',
   'Afaste a perna de fora para o lado sem inclinar o tronco.',
   'Volte devagar sem deixar as pernas baterem. Troque de lado.'],
  ['Mantenha a ponta do pé apontando para frente.'],
  ['Inclinar o tronco para o lado.', 'Girar o pé para fora.'])

E('abducao_polia', 'Abdução de quadril na polia', 'abdutores', ['gluteos'], 'polia', 'iniciante',
  'hip_abduction_cable',
  ['Prenda a caneleira da polia baixa no tornozelo da perna de fora.',
   'Fique de lado para a máquina segurando no apoio.',
   'Afaste a perna para o lado, cruzando o cabo à frente da perna de apoio.',
   'Volte devagar e complete as repetições antes de trocar.'],
  ['Movimento controlado vale mais que amplitude grande.'],
  ['Inclinar o tronco.', 'Usar impulso.'])

E('cadeira_abdutora', 'Cadeira abdutora', 'abdutores', ['gluteos'], 'maquina', 'iniciante', 'abductor_machine',
  ['Sente-se com as costas apoiadas e as almofadas por fora dos joelhos.',
   'Segure as alças laterais.',
   'Abra as pernas empurrando as almofadas para fora.',
   'Segure um instante e feche devagar, sem deixar o peso bater.'],
  ['Inclinar levemente o tronco à frente aumenta o trabalho do glúteo.'],
  ['Fechar rápido demais.', 'Tirar o quadril do banco.'])

E('cadeira_adutora', 'Cadeira adutora', 'adutores', [], 'maquina', 'iniciante', 'adductor_machine',
  ['Sente-se com as almofadas por dentro dos joelhos.',
   'Comece com as pernas numa abertura confortável.',
   'Feche as pernas apertando as almofadas.',
   'Volte devagar até a abertura inicial.'],
  ['Não abra além do que for confortável.'],
  ['Abrir demais na volta.', 'Dar tranco.'])

E('abducao_deitada', 'Abdução deitada de lado', 'abdutores', ['gluteos'], 'peso_corporal', 'iniciante',
  'side_lying_abduction',
  ['Deite de lado com as pernas estendidas e a cabeça apoiada no braço de baixo.',
   'Alinhe ombros, quadril e tornozelos.',
   'Eleve a perna de cima mantendo o joelho reto e o pé apontando para frente.',
   'Desça devagar e complete as repetições antes de trocar de lado.'],
  ['Pode usar caneleira ou elástico para progredir.'],
  ['Girar o quadril para trás.', 'Subir a perna com impulso.'])

E('panturrilha_em_pe', 'Panturrilha em pé', 'panturrilha', [], 'peso_corporal', 'iniciante', 'calf_raise',
  ['Fique em pé com os pés na largura do quadril, mão apoiada na parede.',
   'Suba na ponta dos pés o mais alto que conseguir.',
   'Segure 1 segundo no topo.',
   'Desça devagar até o calcanhar voltar ao chão.'],
  ['Na ponta de um degrau, deixe o calcanhar descer abaixo do nível para alongar mais.',
   'Segure halteres para aumentar a carga.'],
  ['Fazer rápido, quicando.', 'Dobrar os joelhos.'])

E('panturrilha_sentado', 'Panturrilha sentado', 'panturrilha', [], 'maquina', 'iniciante', 'calf_seated',
  ['Sente-se com a almofada sobre a parte baixa das coxas.',
   'Apoie a ponta dos pés na plataforma.',
   'Eleve os calcanhares o máximo possível.',
   'Segure 1 segundo e desça devagar alongando.'],
  ['Trabalha mais o sóleo, músculo profundo da panturrilha.'],
  ['Amplitude curta.', 'Movimento rápido.'])

E('agachamento_isometrico', 'Agachamento isométrico na parede', 'quadriceps', ['gluteos'], 'peso_corporal',
  'iniciante', 'wall_sit',
  ['Encoste as costas na parede e afaste os pés cerca de um passo à frente.',
   'Deslize para baixo até os joelhos formarem um ângulo próximo de 90 graus.',
   'Mantenha os joelhos sobre os tornozelos e as costas apoiadas.',
   'Segure o tempo indicado respirando normalmente.'],
  ['Comece com 20 a 30 segundos e aumente aos poucos.'],
  ['Joelhos à frente da ponta dos pés.', 'Prender a respiração.'])

E('hiperextensao_lombar', 'Hiperextensão lombar (banco 45°)', 'lombar', ['gluteos', 'posterior'], 'maquina',
  'iniciante', 'hyperextension',
  ['Ajuste o apoio para ficar logo abaixo do quadril, pés presos no suporte.',
   'Cruze os braços no peito e alinhe o corpo com as pernas.',
   'Desça o tronco dobrando no quadril, mantendo a coluna neutra.',
   'Suba até o corpo ficar alinhado com as pernas, sem passar disso.'],
  ['Contrair os glúteos na subida protege a lombar.'],
  ['Subir além da linha do corpo, arqueando a lombar.', 'Movimentos rápidos.'])

E('swing_kettlebell', 'Swing com kettlebell', 'gluteos', ['posterior', 'lombar', 'corpo_inteiro'], 'kettlebell',
  'intermediario', 'kb_swing',
  ['Pés um pouco além da largura do quadril, kettlebell à frente no chão.',
   'Leve o quadril para trás e passe o kettlebell entre as pernas, como num passe de futebol americano.',
   'Estenda o quadril com força para jogar o kettlebell até a altura do peito.',
   'Os braços só guiam; no topo, glúteos contraídos e corpo reto.',
   'Deixe o kettlebell descer e repita levando o quadril para trás.'],
  ['É um movimento de quadril, não de agachamento.'],
  ['Levantar o peso com os braços.', 'Arredondar a lombar.', 'Agachar em vez de dobrar no quadril.'])

# ------------------------------------------------------------------ PEITO
E('supino_reto_barra', 'Supino reto com barra', 'peito', ['triceps', 'ombros'], 'barra', 'intermediario',
  'bench_press',
  ['Deite no banco com os olhos logo abaixo da barra e os pés firmes no chão.',
   'Junte as escápulas e puxe-as para baixo, criando uma base firme nas costas.',
   'Segure a barra um pouco além da largura dos ombros, punhos retos.',
   'Desça a barra em diagonal até o meio do peito, cotovelos de 45 graus do tronco.',
   'Empurre de volta até os braços estenderem sobre os ombros.'],
  ['Treine com alguém para ajudar ou use os pinos de segurança.'],
  ['Cotovelos totalmente abertos, a 90 graus do tronco.', 'Tirar o quadril do banco.', 'Quicar a barra no peito.'])

E('supino_reto_halteres', 'Supino reto com halteres', 'peito', ['triceps', 'ombros'], 'halter', 'iniciante',
  'bench_press_db',
  ['Deite no banco com um halter em cada mão, apoiados nas coxas.',
   'Leve os halteres para cima do peito com os braços estendidos.',
   'Junte as escápulas e desça os halteres ao lado do peito, cotovelos a 45 graus.',
   'Empurre de volta aproximando levemente os halteres no topo.'],
  ['Os halteres permitem um movimento mais natural para os ombros.'],
  ['Deixar os halteres caírem para os lados.', 'Bater os halteres no topo.'])

E('supino_inclinado_barra', 'Supino inclinado com barra', 'peito', ['ombros', 'triceps'], 'barra', 'intermediario',
  'incline_press',
  ['Ajuste o banco entre 30 e 45 graus.',
   'Deite com as escápulas juntas e pés firmes no chão.',
   'Desça a barra até a parte alta do peito, abaixo da clavícula.',
   'Empurre de volta até estender os braços.'],
  ['Inclinação alta demais transfere o trabalho para os ombros.'],
  ['Descer a barra no pescoço.', 'Perder o apoio das escápulas.'])

E('supino_inclinado_halteres', 'Supino inclinado com halteres', 'peito', ['ombros', 'triceps'], 'halter',
  'iniciante', 'incline_press_db',
  ['Banco entre 30 e 45 graus, um halter em cada mão.',
   'Comece com os braços estendidos sobre a parte alta do peito.',
   'Desça os halteres ao lado do peito com controle.',
   'Empurre de volta até estender os braços.'],
  ['Trabalha principalmente a parte de cima do peito.'],
  ['Arquear demais a lombar.', 'Descer sem controle.'])

E('crucifixo_halteres', 'Crucifixo com halteres', 'peito', ['ombros'], 'halter', 'iniciante', 'fly_db',
  ['Deite no banco com os halteres sobre o peito, palmas viradas uma para a outra.',
   'Mantenha uma leve flexão nos cotovelos durante todo o movimento.',
   'Abra os braços em arco até sentir o peito alongar, sem passar da linha do corpo.',
   'Feche em arco, como se abraçasse uma árvore.'],
  ['Use carga menor que no supino.'],
  ['Dobrar e estender os cotovelos, virando um supino.', 'Descer demais os braços.'])

E('voador', 'Voador (peck deck)', 'peito', ['ombros'], 'maquina', 'iniciante', 'pec_deck',
  ['Ajuste o banco para as alças ficarem na altura do peito.',
   'Costas apoiadas e braços abertos com leve flexão.',
   'Feche os braços à frente contraindo o peito.',
   'Volte devagar até sentir o peito alongar.'],
  ['Mantenha os ombros para trás e para baixo.'],
  ['Projetar os ombros à frente.', 'Abrir demais na volta.'])

E('crossover', 'Crossover na polia', 'peito', ['ombros'], 'polia', 'intermediario', 'cable_crossover',
  ['Segure as alças das polias altas e dê um passo à frente.',
   'Incline levemente o tronco e mantenha uma leve flexão nos cotovelos.',
   'Traga as mãos para baixo e ao centro, à frente do quadril.',
   'Volte em arco controlando até os braços abrirem.'],
  ['Variar a altura das polias muda a região do peito trabalhada.'],
  ['Dobrar e estender os cotovelos.', 'Deixar os cabos puxarem rápido na volta.'])

E('flexao_braco', 'Flexão de braço', 'peito', ['triceps', 'ombros', 'abdomen'], 'peso_corporal', 'intermediario',
  'push_up',
  ['Mãos no chão um pouco além da largura dos ombros, corpo em linha reta da cabeça aos pés.',
   'Contraia abdômen e glúteos.',
   'Desça o peito em direção ao chão com os cotovelos a cerca de 45 graus do tronco.',
   'Empurre o chão até estender os braços, sem deixar o quadril cair.'],
  ['Se ainda não consegue, comece pela flexão inclinada ou com joelhos.'],
  ['Quadril caindo ou empinado.', 'Cotovelos totalmente abertos.', 'Cabeça caindo à frente.'])

E('flexao_joelhos', 'Flexão com joelhos', 'peito', ['triceps', 'ombros'], 'peso_corporal', 'iniciante',
  'push_up_knee',
  ['Apoie as mãos e os joelhos no chão, com os pés elevados.',
   'Mantenha uma linha reta dos joelhos à cabeça.',
   'Desça o peito em direção ao chão.',
   'Empurre até estender os braços.'],
  ['Use um colchonete para proteger os joelhos.'],
  ['Dobrar no quadril em vez de manter a linha reta.'])

E('flexao_inclinada', 'Flexão inclinada no banco', 'peito', ['triceps', 'ombros'], 'peso_corporal', 'iniciante',
  'push_up_incline',
  ['Apoie as mãos num banco firme, na largura dos ombros.',
   'Corpo em linha reta, pés apoiados no chão.',
   'Leve o peito até o banco dobrando os cotovelos.',
   'Empurre o banco até estender os braços.'],
  ['Quanto mais alto o apoio, mais fácil.'],
  ['Quadril caindo.', 'Banco instável.'])

E('paralelas', 'Mergulho nas paralelas', 'triceps', ['peito', 'ombros'], 'barra_fixa', 'avancado', 'dips',
  ['Segure as barras e suba com os braços estendidos.',
   'Incline levemente o tronco à frente e dobre os joelhos.',
   'Desça dobrando os cotovelos até cerca de 90 graus.',
   'Empurre para cima até estender os braços.'],
  ['Use a máquina de paralela assistida para começar.'],
  ['Descer demais forçando os ombros.', 'Balançar o corpo.'])

# ------------------------------------------------------------------ COSTAS
E('puxada_frontal', 'Puxada frontal', 'costas', ['biceps', 'ombros'], 'polia', 'iniciante', 'lat_pulldown',
  ['Ajuste o apoio das coxas e segure a barra com pegada pronada, um pouco além dos ombros.',
   'Incline o tronco levemente para trás, cerca de 15 graus, com o peito aberto.',
   'Puxe a barra até a parte alta do peito, levando os cotovelos para baixo e para os lados.',
   'Suba controlando até estender os braços.'],
  ['Pense em puxar com os cotovelos, não com as mãos.'],
  ['Puxar a barra atrás da nuca.', 'Jogar o corpo para trás.', 'Usar mais os braços que as costas.'])

E('barra_fixa', 'Barra fixa', 'costas', ['biceps', 'abdomen'], 'barra_fixa', 'avancado', 'pull_up',
  ['Segure a barra com pegada pronada, um pouco além da largura dos ombros.',
   'Pendure com os braços estendidos e o abdômen firme.',
   'Puxe levando o peito em direção à barra até o queixo passar dela.',
   'Desça controlando até estender os braços.'],
  ['Comece com a barra assistida ou com elástico.'],
  ['Balançar o corpo.', 'Meia repetição.'])

E('barra_fixa_assistida', 'Barra fixa assistida', 'costas', ['biceps'], 'maquina', 'iniciante', 'pull_up',
  ['Ajuste o contrapeso da máquina (gravitron) ou prenda um elástico na barra.',
   'Apoie os joelhos ou pés na plataforma e segure a barra.',
   'Puxe levando o peito à barra.',
   'Desça devagar até estender os braços.'],
  ['Diminua a assistência aos poucos.'],
  ['Descer rápido.', 'Encolher os ombros.'])

E('remada_sentada', 'Remada sentada na polia', 'costas', ['biceps', 'trapezio'], 'polia', 'iniciante',
  'seated_row',
  ['Sente-se com os pés no apoio e os joelhos levemente dobrados.',
   'Segure o triângulo com os braços estendidos e a coluna ereta.',
   'Puxe levando os cotovelos para trás, rente ao corpo, até as mãos chegarem ao abdômen.',
   'Junte as escápulas e volte estendendo os braços devagar.'],
  ['O tronco fica praticamente parado.'],
  ['Balançar o tronco para frente e para trás.', 'Encolher os ombros.'])

E('remada_curvada_barra', 'Remada curvada com barra', 'costas', ['biceps', 'lombar', 'trapezio'], 'barra',
  'intermediario', 'bent_row',
  ['Segure a barra, flexione os joelhos e incline o tronco à frente com a coluna neutra.',
   'Braços estendidos abaixo dos ombros.',
   'Puxe a barra em direção ao abdômen levando os cotovelos para trás.',
   'Junte as escápulas e desça devagar.'],
  ['Mantenha o tronco parado durante as repetições.'],
  ['Arredondar a lombar.', 'Levantar o tronco para ajudar.'])

E('remada_curvada_halteres', 'Remada curvada com halteres', 'costas', ['biceps', 'trapezio'], 'halter',
  'iniciante', 'bent_row_db',
  ['Halteres nas mãos, joelhos flexionados e tronco inclinado à frente.',
   'Coluna neutra e abdômen firme.',
   'Puxe os halteres em direção ao abdômen.',
   'Desça devagar até estender os braços.'],
  ['Palmas viradas uma para a outra deixam o movimento mais confortável.'],
  ['Arredondar as costas.', 'Puxar com os punhos dobrados.'])

E('remada_unilateral', 'Remada unilateral (serrote)', 'costas', ['biceps'], 'halter', 'iniciante', 'one_arm_row',
  ['Apoie o joelho e a mão do mesmo lado no banco, a outra perna no chão.',
   'Costas retas, paralelas ao chão.',
   'Puxe o halter em direção ao quadril levando o cotovelo para trás.',
   'Desça devagar até estender o braço. Troque de lado.'],
  ['Pense em levar o cotovelo ao bolso de trás.'],
  ['Girar o tronco para subir o peso.', 'Puxar com o bíceps.'])

E('pulldown_bracos_estendidos', 'Pulldown com braços estendidos', 'costas', ['abdomen'], 'polia', 'intermediario',
  'straight_arm_pulldown',
  ['De frente para a polia alta, segure a barra com braços estendidos.',
   'Incline levemente o tronco à frente.',
   'Leve a barra até as coxas em arco, com os cotovelos quase retos.',
   'Suba devagar até a altura dos ombros.'],
  ['Ótimo para sentir o dorsal trabalhando.'],
  ['Dobrar os cotovelos.', 'Balançar o tronco.'])

# ------------------------------------------------------------------ OMBROS
E('desenvolvimento_barra', 'Desenvolvimento em pé com barra', 'ombros', ['triceps', 'abdomen'], 'barra',
  'intermediario', 'overhead_press',
  ['Segure a barra na altura dos ombros, mãos um pouco além da largura deles.',
   'Contraia glúteos e abdômen.',
   'Empurre a barra para cima, afastando levemente a cabeça para ela passar.',
   'Termine com os braços estendidos e a barra sobre o meio do pé.',
   'Desça controlando até os ombros.'],
  ['Não arqueie a lombar: mantenha o abdômen firme.'],
  ['Inclinar o tronco para trás.', 'Empurrar a barra à frente do corpo.'])

E('desenvolvimento_halteres', 'Desenvolvimento com halteres sentado', 'ombros', ['triceps'], 'halter',
  'iniciante', 'overhead_press_db',
  ['Sente-se com as costas apoiadas, halteres na altura dos ombros.',
   'Empurre os halteres para cima até quase estender os braços.',
   'Desça controlando até a altura das orelhas.'],
  ['Encosto vertical ou levemente inclinado dá mais segurança.'],
  ['Arquear a lombar.', 'Bater os halteres no topo.'])

E('elevacao_lateral', 'Elevação lateral', 'ombros', ['trapezio'], 'halter', 'iniciante', 'lateral_raise',
  ['Em pé, halteres ao lado do corpo, cotovelos levemente dobrados.',
   'Eleve os braços para os lados conduzindo pelos cotovelos.',
   'Pare na altura dos ombros, com as palmas viradas para o chão.',
   'Desça em 2 a 3 segundos até os halteres voltarem ao lado do corpo.'],
  ['Use carga leve; é um músculo pequeno.', 'Mantenha a mesma flexão de cotovelo durante toda a série.'],
  ['Encolher os ombros.', 'Balançar o corpo.', 'Subir acima da linha dos ombros.'])

E('elevacao_frontal', 'Elevação frontal', 'ombros', [], 'halter', 'iniciante', 'front_raise',
  ['Em pé, halteres à frente das coxas.',
   'Eleve um ou os dois braços à frente até a altura dos ombros.',
   'Mantenha os cotovelos levemente dobrados.',
   'Desça devagar.'],
  ['Pode alternar os braços.'],
  ['Balançar o tronco.', 'Subir acima da cabeça.'])

E('voador_invertido', 'Voador invertido', 'ombros', ['costas', 'trapezio'], 'maquina', 'iniciante',
  'reverse_fly',
  ['Sente-se de frente para o encosto e segure as alças à frente.',
   'Abra os braços para trás com leve flexão nos cotovelos.',
   'Junte as escápulas no final.',
   'Volte devagar.'],
  ['Trabalha a parte de trás do ombro e melhora a postura.'],
  ['Encolher os ombros.', 'Usar impulso.'])

E('face_pull', 'Face pull', 'ombros', ['trapezio', 'costas'], 'polia', 'intermediario', 'face_pull',
  ['Ajuste a polia na altura do rosto e segure a corda com as palmas para baixo.',
   'Puxe a corda em direção ao rosto, abrindo os cotovelos para os lados e para cima.',
   'Termine com as mãos ao lado das orelhas.',
   'Volte devagar estendendo os braços.'],
  ['Excelente para a saúde dos ombros e a postura.'],
  ['Puxar baixo, em direção ao peito.', 'Jogar o corpo para trás.'])

E('encolhimento', 'Encolhimento com halteres', 'trapezio', [], 'halter', 'iniciante', 'shrug',
  ['Em pé, halteres ao lado do corpo.',
   'Eleve os ombros em direção às orelhas, sem dobrar os cotovelos.',
   'Segure 1 segundo e desça devagar.'],
  ['Não gire os ombros; o movimento é para cima e para baixo.'],
  ['Girar os ombros.', 'Dobrar os cotovelos.'])

# ------------------------------------------------------------------ BRAÇOS
E('rosca_direta_halteres', 'Rosca direta com halteres', 'biceps', ['antebraco'], 'halter', 'iniciante', 'curl',
  ['Em pé, halteres ao lado do corpo com as palmas para frente.',
   'Cotovelos colados ao tronco.',
   'Flexione os cotovelos levando os halteres em direção aos ombros.',
   'Desça devagar até estender os braços.'],
  ['Pode alternar os braços.'],
  ['Balançar o tronco.', 'Levar os cotovelos à frente.'])

E('rosca_direta_barra', 'Rosca direta com barra', 'biceps', ['antebraco'], 'barra', 'iniciante', 'curl_bb',
  ['Segure a barra com as palmas para frente, na largura dos ombros.',
   'Cotovelos junto ao corpo.',
   'Suba a barra flexionando os cotovelos.',
   'Desça devagar.'],
  ['A barra W deixa o punho mais confortável.'],
  ['Jogar o corpo para trás.', 'Descer sem controle.'])

E('rosca_martelo', 'Rosca martelo', 'biceps', ['antebraco'], 'halter', 'iniciante', 'hammer_curl',
  ['Segure os halteres com as palmas viradas para o corpo.',
   'Cotovelos colados ao tronco.',
   'Flexione os cotovelos mantendo a pegada neutra.',
   'Desça devagar.'],
  ['Trabalha também o antebraço.'],
  ['Balançar o tronco.'])

E('rosca_polia', 'Rosca na polia', 'biceps', [], 'polia', 'iniciante', 'curl_cable',
  ['Segure a barra da polia baixa com as palmas para cima.',
   'Cotovelos junto ao corpo.',
   'Flexione os cotovelos até a barra chegar perto dos ombros.',
   'Volte devagar.'],
  ['O cabo mantém tensão durante todo o movimento.'],
  ['Inclinar o tronco para trás.'])

E('rosca_scott', 'Rosca Scott', 'biceps', [], 'barra', 'iniciante', 'preacher_curl',
  ['Sente-se no banco Scott com a parte de trás dos braços apoiada.',
   'Segure a barra com as palmas para cima.',
   'Flexione os cotovelos subindo a barra.',
   'Desça devagar até quase estender os braços.'],
  ['Não estenda os cotovelos completamente com carga alta.'],
  ['Tirar os braços do apoio.', 'Descer de uma vez.'])

E('triceps_polia', 'Tríceps na polia (barra)', 'triceps', [], 'polia', 'iniciante', 'triceps_pushdown',
  ['De frente para a polia alta, segure a barra com as palmas para baixo.',
   'Cotovelos colados ao corpo, a 90 graus.',
   'Estenda os cotovelos levando a barra até as coxas.',
   'Volte devagar até 90 graus.'],
  ['Só o antebraço se move.'],
  ['Abrir os cotovelos.', 'Usar o peso do corpo.'])

E('triceps_corda', 'Tríceps na polia com corda', 'triceps', [], 'polia', 'iniciante', 'triceps_pushdown',
  ['Segure a corda na polia alta com as palmas voltadas uma para a outra.',
   'Cotovelos fixos ao lado do corpo.',
   'Estenda os cotovelos e abra levemente a corda no final.',
   'Volte devagar.'],
  ['Abrir a corda no final aumenta a contração.'],
  ['Mover os ombros.', 'Inclinar demais o tronco.'])

E('triceps_frances', 'Tríceps francês com halter', 'triceps', [], 'halter', 'iniciante', 'overhead_triceps',
  ['Em pé ou sentado, segure um halter com as duas mãos acima da cabeça.',
   'Cotovelos apontando para cima, perto da cabeça.',
   'Desça o halter atrás da cabeça dobrando só os cotovelos.',
   'Estenda os braços de volta.'],
  ['Mantenha o abdômen firme para não arquear a lombar.'],
  ['Abrir muito os cotovelos.', 'Arquear as costas.'])

E('triceps_testa', 'Tríceps testa', 'triceps', [], 'barra', 'intermediario', 'skull_crusher',
  ['Deite no banco com a barra acima do peito, braços estendidos.',
   'Incline levemente os braços em direção à cabeça.',
   'Dobre só os cotovelos levando a barra em direção à testa.',
   'Estenda os braços de volta.'],
  ['A barra W é mais confortável para os punhos.'],
  ['Mover os ombros.', 'Abrir os cotovelos.'])

E('triceps_coice', 'Tríceps coice', 'triceps', [], 'halter', 'iniciante', 'triceps_kickback',
  ['Incline o tronco à frente apoiando uma mão num banco.',
   'Braço de trabalho junto ao corpo, cotovelo dobrado a 90 graus.',
   'Estenda o cotovelo levando o halter para trás.',
   'Volte devagar sem mover o braço.'],
  ['Use carga leve e foque na contração.'],
  ['Balançar o braço.', 'Deixar o cotovelo cair.'])

E('triceps_banco', 'Tríceps no banco', 'triceps', ['peito', 'ombros'], 'peso_corporal', 'iniciante', 'bench_dip',
  ['Apoie as mãos na borda de um banco atrás do corpo, pernas à frente.',
   'Tire o quadril do banco com os braços estendidos.',
   'Dobre os cotovelos para trás até cerca de 90 graus.',
   'Estenda os braços para subir, quadril perto do banco.'],
  ['Joelhos dobrados facilitam; pernas estendidas dificultam.'],
  ['Descer demais, forçando os ombros.', 'Afastar o quadril do banco.'])

# ------------------------------------------------------------------ ABDÔMEN E CORE
E('prancha', 'Prancha', 'abdomen', ['ombros', 'gluteos'], 'peso_corporal', 'iniciante', 'plank',
  ['Apoie os antebraços no chão com os cotovelos sob os ombros.',
   'Estenda as pernas apoiando nas pontas dos pés.',
   'Corpo em linha reta, abdômen e glúteos contraídos.',
   'Respire normalmente e segure o tempo indicado.'],
  ['Melhor 20 segundos bem feitos que 1 minuto com o quadril caindo.'],
  ['Quadril caindo.', 'Quadril empinado.', 'Prender a respiração.'])

E('prancha_joelhos', 'Prancha com joelhos', 'abdomen', [], 'peso_corporal', 'iniciante', 'plank_knee',
  ['Apoie antebraços e joelhos no chão, cotovelos sob os ombros.',
   'Mantenha uma linha reta dos joelhos à cabeça.',
   'Contraia abdômen e glúteos e respire normalmente.'],
  ['Versão de entrada para a prancha.'],
  ['Dobrar o quadril.'])

E('prancha_lateral', 'Prancha lateral', 'abdomen', ['abdutores'], 'peso_corporal', 'intermediario', 'side_plank',
  ['Deite de lado e apoie o antebraço com o cotovelo sob o ombro.',
   'Pernas estendidas, uma sobre a outra.',
   'Eleve o quadril até o corpo formar uma linha reta.',
   'Segure o tempo indicado e troque de lado.'],
  ['Para facilitar, apoie o joelho de baixo no chão.'],
  ['Quadril caindo.', 'Ombro longe do cotovelo.'])

E('abdominal_supra', 'Abdominal supra', 'abdomen', [], 'peso_corporal', 'iniciante', 'crunch',
  ['Deite de costas com os joelhos dobrados e os pés no chão.',
   'Cruze os braços no peito.',
   'Contraia o abdômen e tire as escápulas do chão, sem puxar o pescoço.',
   'Desça devagar.'],
  ['O movimento é curto: a lombar continua no chão.'],
  ['Puxar a cabeça com as mãos.', 'Subir com impulso.'])

E('elevacao_pernas', 'Elevação de pernas deitado', 'abdomen', [], 'peso_corporal', 'iniciante', 'leg_raise',
  ['Deite de costas com as pernas estendidas e as mãos ao lado do corpo.',
   'Pressione a lombar no chão.',
   'Suba as pernas até a vertical.',
   'Desça devagar, parando antes de os pés tocarem o chão.'],
  ['Se a lombar sair do chão, dobre os joelhos.'],
  ['Arquear a lombar.', 'Descer de uma vez.'])

E('abdominal_bicicleta', 'Abdominal bicicleta', 'abdomen', [], 'peso_corporal', 'intermediario', 'bicycle_crunch',
  ['Deite de costas com as mãos atrás da cabeça, sem puxar o pescoço.',
   'Tire os ombros do chão e flexione um joelho em direção ao peito.',
   'Gire o tronco levando o cotovelo ao joelho oposto enquanto estende a outra perna.',
   'Troque de lado de forma controlada.'],
  ['Devagar e controlado funciona melhor que rápido.'],
  ['Puxar o pescoço.', 'Movimento rápido e sem rotação.'])

E('dead_bug', 'Dead bug', 'abdomen', ['lombar'], 'peso_corporal', 'iniciante', 'dead_bug',
  ['Deite de costas com os braços para cima e os joelhos a 90 graus sobre o quadril.',
   'Pressione a lombar no chão.',
   'Estenda um braço para trás e a perna oposta à frente, sem tocar o chão.',
   'Volte ao centro e alterne os lados.'],
  ['Ótimo para quem sente a lombar em outros abdominais.'],
  ['Deixar a lombar sair do chão.', 'Mover braço e perna do mesmo lado.'])

E('escalador', 'Escalador (mountain climber)', 'abdomen', ['cardio', 'ombros'], 'peso_corporal',
  'intermediario', 'mountain_climber',
  ['Posição de prancha alta, mãos sob os ombros.',
   'Corpo reto e abdômen contraído.',
   'Traga um joelho em direção ao peito e volte.',
   'Alterne as pernas em ritmo constante, sem levantar o quadril.'],
  ['Faça devagar para uma versão de baixo impacto.'],
  ['Quadril alto.', 'Ombros à frente das mãos.'])

E('giro_russo', 'Giro russo', 'abdomen', [], 'peso_corporal', 'intermediario', 'russian_twist',
  ['Sente-se com os joelhos dobrados e os calcanhares no chão.',
   'Incline o tronco para trás com a coluna reta.',
   'Junte as mãos à frente e gire o tronco para um lado.',
   'Gire para o outro lado de forma controlada.'],
  ['Segure uma anilha ou halter para aumentar a dificuldade.'],
  ['Arredondar as costas.', 'Girar só os braços.'])

E('elevacao_pernas_barra', 'Elevação de pernas na barra', 'abdomen', ['antebraco'], 'barra_fixa', 'avancado',
  'hanging_leg_raise',
  ['Pendure na barra com os braços estendidos.',
   'Contraia o abdômen para evitar balanço.',
   'Suba as pernas até a altura do quadril.',
   'Desça devagar.'],
  ['Comece com os joelhos dobrados.'],
  ['Balançar o corpo.', 'Descer de uma vez.'])

E('super_homem', 'Super-homem', 'lombar', ['gluteos'], 'peso_corporal', 'iniciante', 'superman',
  ['Deite de bruços com braços e pernas estendidos.',
   'Eleve braços, peito e pernas alguns centímetros do chão.',
   'Segure 2 segundos.',
   'Desça devagar.'],
  ['Olhe para o chão para manter o pescoço neutro.'],
  ['Subir demais, forçando a lombar.', 'Levantar a cabeça.'])

E('perdigueiro', 'Perdigueiro (bird dog)', 'abdomen', ['lombar', 'gluteos'], 'peso_corporal', 'iniciante',
  'bird_dog',
  ['Fique em quatro apoios: mãos sob os ombros e joelhos sob o quadril.',
   'Estenda um braço à frente e a perna oposta para trás.',
   'Mantenha o quadril parado e as costas retas.',
   'Volte e alterne os lados.'],
  ['Imagine um copo de água sobre a lombar.'],
  ['Girar o quadril.', 'Arquear as costas.'])

# ------------------------------------------------------------------ CARDIO E CORPO INTEIRO
E('caminhada_esteira', 'Caminhada na esteira', 'cardio', ['panturrilha', 'gluteos'], 'cardio', 'iniciante', 'walk',
  ['Comece em ritmo leve por 3 a 5 minutos.',
   'Tronco ereto, olhar à frente e braços balançando naturalmente.',
   'Ajuste uma velocidade em que ainda consiga conversar.',
   'Desacelere aos poucos no final.'],
  ['Evite se apoiar nas barras laterais.'],
  ['Olhar para os pés o tempo todo.', 'Segurar nas barras.'])

E('caminhada_inclinada', 'Caminhada inclinada', 'cardio', ['gluteos', 'posterior', 'panturrilha'], 'cardio',
  'iniciante', 'walk',
  ['Ajuste a esteira entre 5% e 12% de inclinação.',
   'Tronco ereto, sem segurar nas barras.',
   'Passos firmes, empurrando o chão com o glúteo.',
   'Velocidade em que ainda seja possível falar frases curtas.'],
  ['Cardio de baixo impacto, ótimo para quem está acima do peso.'],
  ['Inclinar o tronco e segurar no painel.'])

E('corrida_esteira', 'Corrida na esteira', 'cardio', ['quadriceps', 'panturrilha'], 'cardio', 'intermediario',
  'run',
  ['Aqueça caminhando por 5 minutos.',
   'Corra com passos curtos e leves, pisando sob o corpo.',
   'Braços dobrados a 90 graus, balançando para frente e para trás.',
   'Desacelere caminhando no final.'],
  ['Para começar, alterne 1 minuto correndo e 2 caminhando.'],
  ['Passadas longas demais.', 'Correr na ponta dos pés o tempo todo.'])

E('corrida_intervalada', 'Corrida intervalada (HIIT)', 'cardio', ['corpo_inteiro'], 'cardio', 'avancado', 'run',
  ['Aqueça por 5 minutos em ritmo leve.',
   'Corra em ritmo forte por 20 a 30 segundos.',
   'Recupere caminhando ou trotando por 60 a 90 segundos.',
   'Repita de 6 a 10 vezes e desaqueça.'],
  ['Para quem tem excesso de peso, prefira intervalos na bicicleta.'],
  ['Pular o aquecimento.', 'Recuperação curta demais.'])

E('bicicleta_ergometrica', 'Bicicleta ergométrica', 'cardio', ['quadriceps', 'gluteos'], 'cardio', 'iniciante',
  'bike',
  ['Ajuste o banco: com o pedal embaixo, o joelho fica levemente dobrado.',
   'Pedale em ritmo confortável para aquecer.',
   'Ajuste a carga para manter um esforço moderado.',
   'Mantenha o tronco estável e os ombros relaxados.'],
  ['Excelente cardio de baixo impacto para os joelhos.'],
  ['Banco baixo demais.', 'Balançar o quadril.'])

E('remo_ergometro', 'Remo ergômetro', 'cardio', ['costas', 'quadriceps', 'corpo_inteiro'], 'cardio',
  'intermediario', 'rower',
  ['Sente-se com os pés presos e segure o puxador com os braços estendidos.',
   'Empurre com as pernas primeiro.',
   'Depois incline levemente o tronco para trás e puxe o puxador até a parte baixa das costelas.',
   'Volte na ordem inversa: braços, tronco e, por fim, joelhos.'],
  ['A força vem principalmente das pernas.'],
  ['Puxar com os braços antes de empurrar com as pernas.', 'Arredondar as costas.'])

E('marcha_estacionaria', 'Marcha estacionária', 'cardio', ['quadriceps', 'abdomen'], 'peso_corporal', 'iniciante',
  'march',
  ['Em pé, postura ereta e braços dobrados.',
   'Eleve um joelho até a altura do quadril, sem pular.',
   'Troque de perna em ritmo constante, balançando os braços.'],
  ['Cardio de baixo impacto para fazer em qualquer lugar.'],
  ['Inclinar o tronco para trás.'])

E('polichinelo', 'Polichinelo', 'cardio', ['corpo_inteiro'], 'peso_corporal', 'iniciante', 'jumping_jack',
  ['Em pé, pernas juntas e braços ao lado do corpo.',
   'Abra as pernas e leve os braços acima da cabeça.',
   'Volte à posição inicial.',
   'Mantenha um ritmo constante.'],
  ['Versão sem salto: abra uma perna de cada vez.'],
  ['Aterrissar com os joelhos travados.'])

E('pular_corda', 'Pular corda', 'cardio', ['panturrilha'], 'peso_corporal', 'intermediario', 'jump_rope',
  ['Segure as alças com os cotovelos perto do corpo.',
   'Gire a corda com os punhos, não com os braços.',
   'Faça saltos baixos aterrissando na ponta dos pés.',
   'Mantenha o olhar à frente.'],
  ['Comece com séries curtas de 30 segundos.'],
  ['Saltar alto demais.', 'Girar a corda com os ombros.'])

E('burpee', 'Burpee', 'corpo_inteiro', ['cardio', 'peito', 'quadriceps'], 'peso_corporal', 'avancado', 'burpee',
  ['Em pé, agache e apoie as mãos no chão.',
   'Leve os pés para trás até a posição de prancha.',
   'Traga os pés de volta para perto das mãos.',
   'Salte com os braços para cima e aterrisse suave.'],
  ['Sem salto e sem jogar os pés, vira uma versão de baixo impacto.'],
  ['Quadril caindo na prancha.', 'Aterrissar com os joelhos travados.'])

E('caminhada_fazendeiro', 'Caminhada do fazendeiro', 'corpo_inteiro', ['antebraco', 'trapezio', 'abdomen'], 'halter',
  'iniciante', 'farmer_walk',
  ['Segure halteres pesados ao lado do corpo.',
   'Fique bem ereto, ombros para trás e abdômen firme.',
   'Caminhe com passos curtos pelo tempo ou distância indicados.',
   'Apoie os halteres no chão agachando, sem curvar as costas.'],
  ['Ótimo para pegada e postura.'],
  ['Deixar os ombros caírem à frente.', 'Inclinar o corpo para um lado.'])

# ================================================================== PRÉ-DEFINIÇÕES


def it(ex, sets, reps, rest=60, note=''):
    return dict(exercise=ex, sets=sets, reps=reps, rest=rest, note=note)


def day(weekday, title, items):
    return dict(weekday=weekday, title=title, items=items)


PRESETS = [
    dict(
        id='primeiros_passos', name='Primeiros passos', shape='iniciante', sex='both',
        summary='Para quem nunca treinou ou está voltando. Corpo inteiro, 3 vezes por semana.',
        description='Antes de buscar um formato de corpo, o corpo precisa aprender os movimentos básicos. '
                    'Este plano usa máquinas e exercícios simples para criar força, coordenação e o hábito '
                    'de treinar.',
        goals=['Aprender a técnica dos movimentos básicos', 'Criar o hábito de treinar',
               'Preparar articulações e músculos para treinos mais intensos'],
        focus=['Corpo inteiro', 'Técnica', 'Cardio leve'],
        caution=['Use cargas que permitam terminar as repetições com folga de 2 a 3.',
                 'Depois de 4 a 6 semanas, escolha um plano pelo seu formato de corpo.'],
        days=[
            day(0, 'Corpo inteiro A', [it('leg_press_45', 3, '12'), it('puxada_frontal', 3, '12'),
                                       it('supino_reto_halteres', 3, '12'), it('ponte_gluteo', 3, '15'),
                                       it('prancha_joelhos', 3, '20s'), it('caminhada_inclinada', 1, '15 min', 0)]),
            day(2, 'Corpo inteiro B', [it('agachamento_goblet', 3, '12'), it('remada_sentada', 3, '12'),
                                       it('desenvolvimento_halteres', 3, '12'), it('cadeira_flexora', 3, '12'),
                                       it('dead_bug', 3, '10'), it('bicicleta_ergometrica', 1, '15 min', 0)]),
            day(4, 'Corpo inteiro C', [it('subida_banco', 3, '10 cada'), it('remada_unilateral', 3, '12 cada'),
                                       it('flexao_inclinada', 3, '10'), it('cadeira_abdutora', 3, '15'),
                                       it('perdigueiro', 3, '10 cada'), it('caminhada_esteira', 1, '20 min', 0)]),
        ]),
    dict(
        id='triangulo_invertido', sex='F', name='Triângulo invertido', shape='triangulo_invertido',
        summary='Ombros e costas mais largos que o quadril. Foco em glúteos, quadril e pernas.',
        description='No triângulo invertido a parte de cima é mais larga que a de baixo. A largura dos ombros é '
                    'estrutural e não muda; o que muda é a proporção. Ganhar volume e firmeza em glúteos, '
                    'quadril e coxas, e manter a parte de cima com carga leve, deixa a silhueta mais equilibrada.',
        goals=['Dar volume a glúteos e quadril', 'Definir coxas', 'Manter a parte de cima firme, sem alargar'],
        focus=['Glúteos', 'Abdutores', 'Quadríceps', 'Posterior de coxa'],
        caution=['Evite volume alto de desenvolvimento, elevação lateral e puxadas pesadas.',
                 'Acima do peso: prefira cardio de baixo impacto, sem saltos.'],
        days=[
            day(0, 'Glúteos e quadril', [it('agachamento_goblet', 4, '12'), it('elevacao_pelvica', 4, '10', 90),
                                         it('abducao_em_pe_elastico', 3, '15 cada'),
                                         it('coice_quatro_apoios', 3, '12 cada'),
                                         it('caminhada_inclinada', 1, '15 min', 0)]),
            day(1, 'Cardio e abdômen', [it('caminhada_inclinada', 1, '30 min', 0), it('marcha_estacionaria', 4, '1 min', 30),
                                        it('prancha_joelhos', 3, '30s'), it('dead_bug', 3, '10'),
                                        it('elevacao_pernas', 3, '12')]),
            day(2, 'Coxas e posterior', [it('agachamento_sumo', 4, '12'), it('stiff_halteres', 3, '12', 90),
                                         it('mesa_flexora', 3, '12'), it('leg_press_45', 3, '12', 90),
                                         it('panturrilha_em_pe', 3, '20')]),
            day(3, 'Glúteos (volume)', [it('elevacao_pelvica', 4, '10', 90), it('afundo', 3, '10 cada', 90),
                                        it('cadeira_abdutora', 3, '15'), it('coice_polia', 3, '15 cada'),
                                        it('caminhada_inclinada', 1, '15 min', 0)]),
            day(4, 'Corpo inteiro leve', [it('agachamento_goblet', 3, '15'), it('remada_sentada', 2, '15'),
                                          it('flexao_inclinada', 2, '10'), it('prancha', 3, '30s'),
                                          it('bicicleta_ergometrica', 1, '25 min', 0)]),
        ]),
    dict(
        id='triangulo', sex='F', name='Triângulo (pera)', shape='triangulo',
        summary='Quadril mais largo que os ombros. Foco em ombros e costas para equilibrar.',
        description='No triângulo, ou pera, o quadril e as coxas são mais largos que os ombros. Desenvolver '
                    'ombros (especialmente a parte lateral) e costas cria largura em cima, enquanto as pernas '
                    'recebem treino de definição, sem excesso de volume.',
        goals=['Alargar visualmente os ombros', 'Desenvolver costas', 'Definir pernas sem aumentar volume'],
        focus=['Ombros', 'Costas', 'Peito', 'Posterior de coxa'],
        caution=['Pernas continuam sendo treinadas, com foco em resistência e definição.',
                 'Gordura localizada não sai com exercício localizado; o cardio ajuda no todo.'],
        days=[
            day(0, 'Ombros e costas', [it('desenvolvimento_halteres', 4, '10', 90), it('elevacao_lateral', 4, '12'),
                                       it('puxada_frontal', 4, '10', 90), it('remada_sentada', 3, '12'),
                                       it('face_pull', 3, '15')]),
            day(1, 'Pernas (definição)', [it('stiff_halteres', 3, '15'), it('mesa_flexora', 3, '15'),
                                          it('ponte_gluteo', 3, '20'), it('cadeira_adutora', 3, '15'),
                                          it('bicicleta_ergometrica', 1, '20 min', 0)]),
            day(2, 'Peito e ombros', [it('supino_inclinado_halteres', 4, '10', 90), it('crucifixo_halteres', 3, '12'),
                                      it('elevacao_lateral', 4, '12'), it('voador_invertido', 3, '15'),
                                      it('prancha', 3, '30s')]),
            day(3, 'Costas e braços', [it('remada_curvada_halteres', 4, '10', 90), it('barra_fixa_assistida', 3, '8'),
                                       it('pulldown_bracos_estendidos', 3, '12'), it('rosca_direta_halteres', 3, '12'),
                                       it('triceps_corda', 3, '12')]),
            day(4, 'Cardio e core', [it('remo_ergometro', 1, '20 min', 0), it('escalador', 3, '30s', 30),
                                     it('prancha_lateral', 3, '20s cada'), it('abdominal_bicicleta', 3, '12 cada')]),
        ]),
    dict(
        id='ampulheta', sex='F', name='Ampulheta', shape='ampulheta',
        summary='Ombros e quadril alinhados, cintura marcada. Foco em manter o equilíbrio.',
        description='Na ampulheta, ombros e quadril têm larguras parecidas e a cintura é bem definida. O objetivo é '
                    'manter essa proporção: treino equilibrado entre parte de cima e de baixo, core forte e '
                    'cardio para controlar a gordura corporal.',
        goals=['Manter a proporção natural', 'Tonificar o corpo todo', 'Fortalecer o core'],
        focus=['Corpo inteiro', 'Glúteos', 'Costas', 'Core'],
        caution=['Evite exagerar em exercícios de oblíquo com carga, que podem engrossar a cintura.'],
        days=[
            day(0, 'Inferiores', [it('agachamento_goblet', 4, '12', 90), it('stiff_halteres', 3, '12', 90),
                                  it('afundo_halteres', 3, '10 cada'), it('cadeira_abdutora', 3, '15'),
                                  it('panturrilha_em_pe', 3, '20')]),
            day(1, 'Superiores', [it('puxada_frontal', 4, '10', 90), it('supino_reto_halteres', 3, '12'),
                                  it('remada_unilateral', 3, '12 cada'), it('elevacao_lateral', 3, '12'),
                                  it('triceps_corda', 3, '12')]),
            day(2, 'Cardio e core', [it('bicicleta_ergometrica', 1, '30 min', 0), it('prancha', 3, '40s'),
                                     it('dead_bug', 3, '12'), it('perdigueiro', 3, '10 cada')]),
            day(3, 'Glúteos e posterior', [it('elevacao_pelvica', 4, '10', 90), it('agachamento_bulgaro', 3, '10 cada', 90),
                                           it('mesa_flexora', 3, '12'), it('coice_polia', 3, '15 cada')]),
            day(4, 'Corpo inteiro', [it('remada_sentada', 3, '12'), it('desenvolvimento_halteres', 3, '10'),
                                     it('subida_banco', 3, '10 cada'), it('swing_kettlebell', 3, '15'),
                                     it('caminhada_inclinada', 1, '20 min', 0)]),
        ]),
    dict(
        id='retangulo', sex='F', name='Retângulo', shape='retangulo',
        summary='Ombros, cintura e quadril com larguras parecidas. Foco em criar curvas.',
        description='No retângulo, a cintura é pouco marcada. Para criar curvas, o treino aumenta glúteos e a parte '
                    'lateral dos ombros e desenvolve as costas, o que dá a impressão de cintura mais fina.',
        goals=['Aumentar glúteos', 'Desenvolver ombros laterais e costas', 'Marcar a cintura'],
        focus=['Glúteos', 'Abdutores', 'Ombros', 'Costas'],
        caution=['Abdominais com carga pesada nos oblíquos não afinam a cintura.'],
        days=[
            day(0, 'Glúteos', [it('elevacao_pelvica', 4, '10', 90), it('agachamento_sumo', 4, '12', 90),
                               it('cadeira_abdutora', 4, '15'), it('coice_polia', 3, '12 cada')]),
            day(1, 'Ombros e costas', [it('elevacao_lateral', 4, '12'), it('desenvolvimento_halteres', 3, '10', 90),
                                       it('puxada_frontal', 4, '10', 90), it('remada_sentada', 3, '12')]),
            day(2, 'Pernas', [it('agachamento_barra', 4, '10', 120), it('stiff_barra', 3, '10', 90),
                              it('cadeira_extensora', 3, '12'), it('panturrilha_em_pe', 3, '20')]),
            day(3, 'Glúteos e core', [it('agachamento_bulgaro', 3, '10 cada', 90), it('ponte_gluteo', 3, '20'),
                                      it('abducao_polia', 3, '15 cada'), it('prancha', 3, '40s'),
                                      it('dead_bug', 3, '12')]),
            day(4, 'Superiores e cardio', [it('remada_curvada_halteres', 3, '12'), it('elevacao_lateral', 3, '15'),
                                           it('face_pull', 3, '15'), it('caminhada_inclinada', 1, '25 min', 0)]),
        ]),
    dict(
        id='oval', sex='F', name='Oval (maçã)', shape='oval',
        summary='Volume concentrado na região da cintura. Foco em perder gordura com baixo impacto.',
        description='No formato oval, ou maçã, a gordura se concentra no abdômen. O objetivo principal é reduzir a '
                    'gordura corporal total com treino de força para o corpo todo, cardio frequente de baixo impacto '
                    'e fortalecimento do core. Pernas e costas fortes também melhoram a postura.',
        goals=['Reduzir a gordura corporal', 'Ganhar força no corpo todo', 'Melhorar a postura e o core'],
        focus=['Corpo inteiro', 'Cardio de baixo impacto', 'Core'],
        caution=['A perda de gordura depende também da alimentação com leve déficit calórico.',
                 'Evite saltos e corrida no início para proteger as articulações.',
                 'Se tiver pressão alta ou outra condição, converse com seu médico antes.'],
        days=[
            day(0, 'Força A', [it('leg_press_45', 3, '12', 90), it('puxada_frontal', 3, '12', 90),
                               it('supino_reto_halteres', 3, '12'), it('ponte_gluteo', 3, '15'),
                               it('caminhada_inclinada', 1, '20 min', 0)]),
            day(1, 'Cardio', [it('bicicleta_ergometrica', 1, '35 min', 0), it('prancha_joelhos', 3, '30s'),
                              it('perdigueiro', 3, '10 cada')]),
            day(2, 'Força B', [it('agachamento_goblet', 3, '12', 90), it('remada_sentada', 3, '12', 90),
                               it('desenvolvimento_halteres', 3, '12'), it('cadeira_flexora', 3, '12'),
                               it('caminhada_esteira', 1, '20 min', 0)]),
            day(3, 'Cardio e core', [it('remo_ergometro', 1, '15 min', 0), it('marcha_estacionaria', 4, '1 min', 30),
                                     it('dead_bug', 3, '10'), it('prancha_lateral', 3, '15s cada')]),
            day(4, 'Circuito', [it('subida_banco', 3, '10 cada', 30), it('remada_unilateral', 3, '12 cada', 30),
                                it('flexao_inclinada', 3, '10', 30), it('caminhada_fazendeiro', 3, '40s', 30),
                                it('caminhada_inclinada', 1, '20 min', 0)]),
        ]),
]


PRESETS += [
    dict(
        id='m_trapezio', sex='M', name='Trapézio (V)', shape='m_trapezio',
        summary='Ombros largos e cintura mais estreita. Foco em manter o equilíbrio sem esquecer as pernas.',
        description='O trapézio, ou V, é o formato que muitos homens buscam: ombros e costas largos e cintura mais '
                    'estreita. Para manter essa proporção, o treino divide o volume entre parte de cima e pernas, '
                    'e o core fica forte para sustentar as cargas.',
        goals=['Manter a proporção entre tronco e pernas', 'Ganhar força nos exercícios básicos',
               'Manter a cintura definida'],
        focus=['Corpo inteiro', 'Pernas', 'Costas', 'Peito'],
        caution=['Não pule o treino de pernas: é ele que impede o visual de tronco grande e pernas finas.'],
        days=[
            day(0, 'Peito e tríceps', [it('supino_reto_barra', 4, '8', 120), it('supino_inclinado_halteres', 3, '10', 90),
                                       it('crossover', 3, '12'), it('paralelas', 3, '8', 90), it('triceps_corda', 3, '12')]),
            day(1, 'Pernas (quadríceps)', [it('agachamento_barra', 4, '8', 120), it('leg_press_45', 3, '10', 90),
                                           it('cadeira_extensora', 3, '12'), it('panturrilha_em_pe', 4, '15')]),
            day(2, 'Costas e bíceps', [it('barra_fixa', 4, '6 a 8', 120), it('remada_curvada_barra', 4, '8', 90),
                                       it('remada_sentada', 3, '10'), it('rosca_direta_barra', 3, '10'),
                                       it('rosca_martelo', 3, '12')]),
            day(3, 'Ombros e core', [it('desenvolvimento_barra', 4, '8', 120), it('elevacao_lateral', 4, '12'),
                                     it('face_pull', 3, '15'), it('prancha', 3, '45s'), it('elevacao_pernas_barra', 3, '10')]),
            day(4, 'Posteriores e cardio', [it('levantamento_terra', 4, '5', 150), it('mesa_flexora', 3, '10'),
                                            it('elevacao_pelvica', 3, '10', 90), it('remo_ergometro', 1, '15 min', 0)]),
        ]),
    dict(
        id='m_triangulo_invertido', sex='M', name='Triângulo invertido', shape='m_triangulo_invertido',
        summary='Tronco grande e pernas finas. Foco em pernas e glúteos para equilibrar.',
        description='Quando o peito e os ombros crescem muito mais que as pernas, o corpo fica com o tronco '
                    'pesado. O plano coloca três dias de membros inferiores e mantém a parte de cima com volume '
                    'moderado.',
        goals=['Aumentar coxas e glúteos', 'Fortalecer posterior de coxa', 'Manter o tronco sem exagerar no volume'],
        focus=['Quadríceps', 'Posterior de coxa', 'Glúteos', 'Panturrilha'],
        caution=['Pernas respondem bem a cargas altas e amplitude completa: priorize a técnica antes da carga.'],
        days=[
            day(0, 'Pernas pesado', [it('agachamento_barra', 5, '6 a 8', 150), it('leg_press_45', 4, '10', 90),
                                     it('cadeira_extensora', 3, '12'), it('panturrilha_em_pe', 4, '15')]),
            day(1, 'Superiores', [it('supino_inclinado_halteres', 3, '10', 90), it('puxada_frontal', 3, '10', 90),
                                  it('remada_sentada', 3, '12'), it('elevacao_lateral', 3, '15')]),
            day(2, 'Posteriores', [it('stiff_barra', 4, '8', 120), it('elevacao_pelvica', 4, '10', 90),
                                   it('mesa_flexora', 3, '12'), it('panturrilha_sentado', 4, '15')]),
            day(3, 'Core e cardio', [it('bicicleta_ergometrica', 1, '25 min', 0), it('prancha', 3, '45s'),
                                     it('dead_bug', 3, '12'), it('abdominal_bicicleta', 3, '15 cada')]),
            day(4, 'Pernas volume', [it('agachamento_bulgaro', 4, '10 cada', 90), it('afundo_halteres', 3, '12 cada', 90),
                                     it('cadeira_flexora', 3, '12'), it('cadeira_abdutora', 3, '15')]),
        ]),
    dict(
        id='m_retangulo', sex='M', name='Retângulo', shape='m_retangulo',
        summary='Ombros e cintura com larguras parecidas. Foco em costas e ombros para criar o V.',
        description='No retângulo, o tronco desce reto dos ombros à cintura. Dorsais largas e a parte lateral dos '
                    'ombros desenvolvida criam o formato em V; o core forte e a gordura sob controle deixam a cintura '
                    'mais estreita visualmente.',
        goals=['Alargar as costas', 'Desenvolver os ombros laterais', 'Afinar a cintura visualmente'],
        focus=['Costas', 'Ombros', 'Peito', 'Core'],
        caution=['Abdominais com carga pesada nos oblíquos podem engrossar a cintura; prefira core estático.'],
        days=[
            day(0, 'Costas (largura)', [it('barra_fixa_assistida', 4, '8', 90), it('puxada_frontal', 4, '10', 90),
                                        it('pulldown_bracos_estendidos', 3, '12'), it('rosca_direta_halteres', 3, '12')]),
            day(1, 'Peito e ombros', [it('supino_inclinado_barra', 4, '8', 120), it('elevacao_lateral', 4, '12'),
                                      it('desenvolvimento_halteres', 3, '10', 90), it('triceps_polia', 3, '12')]),
            day(2, 'Pernas', [it('agachamento_barra', 4, '8', 120), it('stiff_barra', 3, '10', 90),
                              it('leg_press_45', 3, '12'), it('panturrilha_em_pe', 3, '15')]),
            day(3, 'Costas (espessura)', [it('remada_curvada_barra', 4, '8', 90), it('remada_unilateral', 3, '10 cada'),
                                          it('face_pull', 3, '15'), it('rosca_martelo', 3, '12')]),
            day(4, 'Ombros e core', [it('elevacao_lateral', 4, '15'), it('voador_invertido', 3, '15'),
                                     it('prancha', 3, '45s'), it('caminhada_inclinada', 1, '20 min', 0)]),
        ]),
    dict(
        id='m_triangulo', sex='M', name='Triângulo', shape='m_triangulo',
        summary='Ombros mais estreitos que a cintura e o quadril. Foco em ombros, costas e peito.',
        description='No triângulo, a parte de baixo é mais larga que os ombros. O plano dá prioridade a ombros, '
                    'costas e peito para criar largura em cima, mantém as pernas com treino de força e inclui cardio '
                    'para reduzir a gordura da cintura.',
        goals=['Alargar ombros e costas', 'Desenvolver o peito', 'Reduzir a gordura na cintura'],
        focus=['Ombros', 'Costas', 'Peito', 'Cardio'],
        caution=['Gordura localizada não sai com abdominal; o cardio e a alimentação fazem essa parte.'],
        days=[
            day(0, 'Ombros e peito', [it('desenvolvimento_halteres', 4, '10', 90), it('elevacao_lateral', 4, '12'),
                                      it('supino_reto_halteres', 3, '10', 90), it('crucifixo_halteres', 3, '12')]),
            day(1, 'Costas', [it('puxada_frontal', 4, '10', 90), it('remada_sentada', 4, '10', 90),
                              it('pulldown_bracos_estendidos', 3, '12'), it('encolhimento', 3, '12')]),
            day(2, 'Pernas e cardio', [it('leg_press_45', 3, '12', 90), it('stiff_halteres', 3, '12', 90),
                                       it('cadeira_flexora', 3, '12'), it('bicicleta_ergometrica', 1, '20 min', 0)]),
            day(3, 'Ombros e braços', [it('elevacao_lateral', 4, '15'), it('face_pull', 3, '15'),
                                       it('rosca_direta_barra', 3, '10'), it('triceps_testa', 3, '10')]),
            day(4, 'Corpo inteiro e cardio', [it('supino_inclinado_halteres', 3, '10'), it('remada_unilateral', 3, '10 cada'),
                                              it('agachamento_goblet', 3, '12'), it('remo_ergometro', 1, '15 min', 0)]),
        ]),
    dict(
        id='m_oval', sex='M', name='Oval', shape='m_oval',
        summary='Volume concentrado no abdômen. Foco em perder gordura com treino de força e cardio leve.',
        description='No formato oval, a gordura se acumula na barriga. O caminho é treino de força para o corpo todo, '
                    'cardio frequente de baixo impacto e core forte, que também protege a lombar. A alimentação com '
                    'leve déficit calórico faz parte do resultado.',
        goals=['Reduzir a gordura corporal', 'Ganhar força no corpo todo', 'Proteger a lombar com core forte'],
        focus=['Corpo inteiro', 'Cardio de baixo impacto', 'Core'],
        caution=['Evite corrida e saltos no início para poupar joelhos e tornozelos.',
                 'Se tiver pressão alta ou outra condição, converse com seu médico antes.'],
        days=[
            day(0, 'Força A', [it('leg_press_45', 3, '12', 90), it('supino_reto_halteres', 3, '12', 90),
                               it('puxada_frontal', 3, '12'), it('prancha_joelhos', 3, '30s'),
                               it('caminhada_inclinada', 1, '20 min', 0)]),
            day(1, 'Cardio', [it('bicicleta_ergometrica', 1, '35 min', 0), it('perdigueiro', 3, '10 cada'),
                              it('dead_bug', 3, '10')]),
            day(2, 'Força B', [it('agachamento_goblet', 3, '12', 90), it('remada_sentada', 3, '12', 90),
                               it('desenvolvimento_halteres', 3, '12'), it('ponte_gluteo', 3, '15'),
                               it('caminhada_esteira', 1, '20 min', 0)]),
            day(3, 'Cardio e core', [it('remo_ergometro', 1, '15 min', 0), it('marcha_estacionaria', 4, '1 min', 30),
                                     it('prancha_lateral', 3, '15s cada'), it('super_homem', 3, '10')]),
            day(4, 'Circuito', [it('subida_banco', 3, '10 cada', 30), it('flexao_inclinada', 3, '10', 30),
                                it('remada_unilateral', 3, '12 cada', 30), it('caminhada_fazendeiro', 3, '40s', 30),
                                it('caminhada_inclinada', 1, '20 min', 0)]),
        ]),
]

# Observações por gênero. Diferenças médias entre corpos masculinos e femininos (largura do quadril e ângulo
# do joelho, distribuição de força entre parte de cima e de baixo, flexibilidade, recuperação entre séries).
# A técnica do movimento é a mesma; o que muda é onde prestar atenção e como progredir.
KNEES_F = ('Em média, o quadril feminino é mais largo, o que favorece os joelhos caírem para dentro. '
           'Pense em empurrar os joelhos para fora, na direção dos pés.')
MOB_M = ('Em média, homens têm menos mobilidade de quadril e tornozelo. Se o calcanhar sair do chão ou a lombar '
         'arredondar, abra um pouco mais os pés e diminua a profundidade.')
NOTES = {
    'agachamento_livre': {'F': [KNEES_F], 'M': [MOB_M]},
    'agachamento_goblet': {'F': [KNEES_F], 'M': [MOB_M]},
    'agachamento_goblet_kettlebell': {'F': [KNEES_F], 'M': [MOB_M]},
    'agachamento_barra': {'F': [KNEES_F, 'Mulheres costumam recuperar mais rápido entre séries; 90 segundos de '
                                         'descanso geralmente bastam.'],
                          'M': [MOB_M, 'Suba a carga só quando todas as repetições saírem com a mesma técnica.']},
    'agachamento_smith': {'F': [KNEES_F], 'M': [MOB_M]},
    'agachamento_sumo': {'F': ['A base larga aproveita bem o quadril mais largo e trabalha glúteos e adutores.'],
                         'M': ['Abra os pés só até onde os joelhos conseguem acompanhar a ponta dos pés.']},
    'afundo': {'F': [KNEES_F], 'M': ['Mantenha o tronco ereto; inclinar à frente tira trabalho das pernas.']},
    'afundo_halteres': {'F': [KNEES_F], 'M': ['Mantenha o tronco ereto; inclinar à frente tira trabalho das pernas.']},
    'agachamento_bulgaro': {'F': [KNEES_F], 'M': ['Comece sem carga: o equilíbrio é o primeiro limite.']},
    'subida_banco': {'F': [KNEES_F], 'M': ['Use um banco na altura do joelho e suba sem impulso da perna de baixo.']},
    'leg_press_45': {'F': [KNEES_F], 'M': ['Desça só até onde o quadril continua apoiado; carga demais encurta o '
                                           'movimento.']},
    'elevacao_pelvica': {'F': ['É um dos exercícios que mais ativam o glúteo; dá para progredir a carga com '
                               'frequência.'],
                         'M': ['Também vale para homens: glúteo forte melhora o agachamento e o terra e protege a '
                               'lombar.']},
    'cadeira_abdutora': {'F': ['Fortalece o glúteo médio, que ajuda a manter os joelhos alinhados nos agachamentos.'],
                         'M': ['O glúteo médio estabiliza o joelho no agachamento e na corrida; não é exercício só '
                               'para mulheres.']},
    'stiff_halteres': {'F': ['Em média, mulheres têm mais flexibilidade; pare onde a coluna ainda está neutra, mesmo '
                             'que alcance mais longe.'],
                       'M': ['Se o posterior estiver encurtado, desça só até o joelho no começo.']},
    'stiff_barra': {'F': ['Em média, mulheres têm mais flexibilidade; pare onde a coluna ainda está neutra.'],
                    'M': ['Se o posterior estiver encurtado, desça só até o joelho no começo.']},
    'levantamento_terra': {'F': ['Mulheres costumam ter boa força de quadril em relação ao peso do corpo; progrida '
                                 'devagar e mantenha a técnica.'],
                           'M': ['Não sacrifique a coluna neutra para levantar mais peso.']},
    'flexao_braco': {'F': ['Em média, mulheres têm menos força na parte de cima em relação ao corpo; comece pela '
                           'flexão inclinada ou com joelhos e progrida.'],
                     'M': ['Se já faz 15 boas repetições, eleve os pés ou faça uma pausa embaixo.']},
    'flexao_joelhos': {'F': ['Ótimo ponto de partida; quando fizer 15 boas repetições, passe para a flexão completa.'],
                       'M': ['Use como aquecimento ou para completar séries depois da flexão completa.']},
    'barra_fixa': {'F': ['Comece pela barra assistida; segurar no topo e descer devagar também constroem força.'],
                   'M': ['Dorsais largas são a base do formato em V; priorize amplitude completa.']},
    'barra_fixa_assistida': {'F': ['Diminua a assistência aos poucos, uma vez por semana.'],
                             'M': ['Use até conseguir 6 repetições sem ajuda.']},
    'puxada_frontal': {'F': ['Costas fortes melhoram a postura e afinam visualmente a cintura.'],
                       'M': ['Dorsais largas são a base do formato em V.']},
    'supino_reto_barra': {'F': ['Halteres costumam ser mais confortáveis para começar.'],
                          'M': ['Sem parceiro, use os pinos de segurança e não leve a série até a falha.']},
    'supino_reto_halteres': {'F': ['Bom para começar: o cotovelo encontra o ângulo mais confortável.'],
                             'M': ['Permite mais amplitude que a barra; desça até sentir o peito alongar.']},
    'elevacao_lateral': {'F': ['Ombros laterais desenvolvidos equilibram a silhueta de quem tem quadril mais largo.'],
                         'M': ['O deltoide lateral é o que mais contribui para a largura dos ombros.']},
    'desenvolvimento_halteres': {'F': ['Ótimo para dar contorno aos ombros sem precisar de carga alta.'],
                                 'M': ['Evite arquear a lombar para subir mais peso.']},
    'rosca_direta_halteres': {'F': ['Braços fortes ajudam em todos os exercícios de puxar.'],
                              'M': ['Carga demais vira balanço de tronco; mantenha os cotovelos parados.']},
    'triceps_corda': {'F': ['O tríceps é a maior parte do braço; trabalhá-lo deixa o braço mais firme.'],
                      'M': ['O tríceps responde por boa parte do volume do braço.']},
}


def validate_and_export():
    pats = {p.id for p in PATTERNS}
    ids = set()
    for e in EX:
        assert e['id'] not in ids, 'id repetido ' + e['id']
        ids.add(e['id'])
        assert e['anim'] in pats, (e['id'], e['anim'])
        assert e['group'] in GROUPS, (e['id'], e['group'])
        assert all(g in GROUPS for g in e['secondary']), e['id']
        assert e['equipment'] in EQUIP, (e['id'], e['equipment'])
        assert e['level'] in LEVELS, e['id']
        assert len(e['steps']) >= 3, e['id']
    for k in NOTES:
        assert k in ids, ('nota de exercício inexistente', k)
    for e in EX:
        if e['id'] in NOTES:
            e['notes'] = NOTES[e['id']]
    for pr in PRESETS:
        assert pr['sex'] in ('F', 'M', 'both'), pr['id']
        for dd in pr['days']:
            for i in dd['items']:
                assert i['exercise'] in ids, (pr['id'], i['exercise'])
    meta = dict(groups=GROUPS, equipment=EQUIP, levels=LEVELS)
    with open(os.path.join(ROOT, 'assets', 'exercises.json'), 'w', encoding='utf-8') as f:
        json.dump(dict(meta=meta, exercises=EX), f, ensure_ascii=False, indent=1)
    with open(os.path.join(ROOT, 'assets', 'presets.json'), 'w', encoding='utf-8') as f:
        json.dump(dict(presets=PRESETS), f, ensure_ascii=False, indent=1)
    used = {e['anim'] for e in EX}
    print(f'{len(EX)} exercícios, {len(PRESETS)} pré-definições; animações sem exercício: {sorted(pats - used)}')


if __name__ == '__main__':
    validate_and_export()
