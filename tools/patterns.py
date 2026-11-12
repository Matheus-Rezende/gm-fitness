"""Poses-chave de cada padrão de movimento do GM Fitness.

Referências de técnica usadas nas posições (paráfrase, conferidas em
NASM, NFPT, Barbell Logic, Powerlifting Technique, Gravitus e Physitrack):
- Agachamento: pés na largura dos ombros, joelhos acompanham a ponta dos pés,
  calcanhar no chão, coluna neutra, coxa perto da paralela.
- Stiff/terra romeno: joelhos levemente flexionados e fixos, quadril vai para
  trás, coluna neutra, barra desce rente às pernas até o meio da canela.
- Elevação pélvica: costas altas no banco, pés na largura do quadril, no topo
  ombro-quadril-joelho em linha, canela vertical, queixo recolhido.
- Puxada frontal: pegada pronada um pouco mais larga que os ombros, barra até
  a parte alta do peito, cotovelos descem para baixo e para os lados.
- Supino: barra desce em diagonal até o meio do peito e volta sobre os ombros,
  cotovelos de 15 a 45 graus do tronco, antebraço vertical embaixo.
- Elevação lateral: leve flexão de cotovelo constante, sobe até a altura dos
  ombros, conduz pelos cotovelos, sem encolher os ombros.
"""
import math
from motion_core import (P, FA, IA, FL, IL, Pattern, L, ANK, GROUND, add, d, sub,
                         front_of, neck_of, dist, ang, lerpp)

X0 = 78.0
HIP_Y = ANK - 50.8          # quadril em pé (joelho quase estendido)
LIE_Y = GROUND - 8.0        # centro do tronco deitado no chão
BENCH_TOP = 94.0            # altura do banco padrão


def legs_stand(x, xf=None, foot=90):
    xf = x if xf is None else xf
    return IL((x + 0.3, ANK), 1, foot), IL((xf + 0.3, ANK), 1, foot)


def standing(x=X0, torso=0.0, arm=None, arm2=None, **kw):
    lg, lg2 = legs_stand(x)
    return P((x, HIP_Y), torso, arm=arm, arm2=arm2, leg=lg, leg2=lg2, **kw)


def hip_from_neck(neck, torso):
    return add(neck, d(torso), -L['torso'])


def chest_point(p, down=8.0, out=9.0):
    """Ponto na frente do peito (relativo à pose)."""
    n = neck_of(p)
    return add(add(n, d(p['torso']), -down), front_of(p['torso']), out)


def back_bar_point(p):
    """Barra apoiada no trapézio, atrás do pescoço."""
    n = neck_of(p)
    return add(add(n, d(p['torso']), -2.0), front_of(p['torso']), -5.5)


def hipbar_point(J):
    return add(J['hip'], front_of(J['_torso']), 10.0)


def mid(a, b):
    return ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)


def S(a, b, dur, label):
    return (a, b, dur, label)


def rep_seq(down=1.3, up=1.1, top=0.5, bottom=0.35, l0='Posição inicial', l1='Desça controlando',
            l2='Segure', l3='Suba'):
    return [S(0, 0, top, l0), S(0, 1, down, l1), S(1, 1, bottom, l2), S(1, 0, up, l3)]


def J_(name):
    f = lambda J: J[name]  # noqa: E731
    f.joint = name
    return f


# Equipamentos móveis
def plate(joint='handN'):
    return dict(type='plate', track=[J_(joint)])


def db_end(joint='handN'):
    return dict(type='db_end', track=[J_(joint)])


def db_side(joint='handN', angle=0.0):
    return dict(type='db_side', angle=angle, track=[J_(joint)])


def cable(x, y, joint='handN'):
    return dict(type='cable', x=x, y=y, track=[J_(joint)])


def bench(x, y, w, h=5.0):
    return dict(type='bench', x=x, y=y, w=w, h=h)


PATTERNS = []


def add_pattern(p):
    PATTERNS.append(p)
    return p


def variant(base, pid, name, props, keys=None):
    return add_pattern(Pattern(pid, name, base.view, keys or base.keys, base.seq, props, base.vp, base.fps,
                               base.linear, plane=base.plane))


# =========================================================== MEMBROS INFERIORES

def squat_keys(arms_top, arms_bot, hold_fn=None, bottom_torso=38.0):
    k0 = standing(X0, 0, arm=arms_top)
    k1 = P((X0 - 16, 92), bottom_torso, arm=arms_bot, leg=IL((X0 + 0.3, ANK), 1, 90),
           leg2=IL((X0 + 0.3, ANK), 1, 90))
    if hold_fn:
        for k in (k0, k1):
            k['arm'] = hold_fn(k)
            k['arm2'] = None
    return [k0, k1]


squat_bw = add_pattern(Pattern('squat_bw', 'Agachamento livre', 'side',
                               squat_keys(FA(180, 180), FA(90, 90)), rep_seq()))

squat_goblet = add_pattern(Pattern(
    'squat_goblet', 'Agachamento goblet', 'side',
    squat_keys(None, None, hold_fn=lambda k: IA(chest_point(k, 9, 10), -1), bottom_torso=32),
    rep_seq(), props=[dict(type='db_side', angle=0.0, track=[lambda J: add(J['handN'], (0, 1.5))])]))


def _bb_keys(bottom_torso=40.0):
    k0 = standing(X0, 3)
    k1 = P((X0 - 15, 91), bottom_torso, leg=IL((X0 + 0.3, ANK), 1, 90), leg2=IL((X0 + 0.3, ANK), 1, 90))
    for k in (k0, k1):
        k['arm'] = IA(add(back_bar_point(k), front_of(k['torso']), 1.5), 1)
    return [k0, k1]


squat_bb = add_pattern(Pattern('squat_bb', 'Agachamento com barra', 'side', _bb_keys(), rep_seq(),
                               props=[dict(type='plate', track=[lambda J: add(add(J['neck'], d(J['_torso']), -2.0),
                                                                                front_of(J['_torso']), -5.5)])]))
squat_smith = variant(squat_bb, 'squat_smith', 'Agachamento no Smith',
                      [dict(type='rail', x=71.5, y1=8, y2=GROUND)] + squat_bb.props)

# Agachamento sumô (vista de frente)
def _sumo_keys():
    k0 = P((80, 68.5), 0, arm=IA((83, 75), 1), leg=IL((96, ANK), 1, 125))
    k1 = P((80, 92), 0, arm=IA((83, 99), 1), leg=IL((96, ANK), 1, 125), lt=0.66)
    return [k0, k1]


sumo = add_pattern(Pattern('sumo_squat', 'Agachamento sumô', 'front', _sumo_keys(), rep_seq(),
                           props=[dict(type='db_side', angle=0.0,
                                       track=[lambda J: add(mid(J['handN'], J['handF']), (0, 5))])]))

# Afundo (passo para trás)
def _lunge_keys(arm=None):
    k0 = standing(X0, 0, arm=arm)
    k_mid = P((X0 - 8, 74), 2, arm=arm, leg=IL((X0 + 0.3, ANK), 1, 90), leg2=IL((X0 - 22, 108), 1, 130))
    k1 = P((56, 91), 5, arm=arm, leg=IL((X0 + 2, ANK), 1, 90), leg2=IL((32, 111), 1, 150))
    return [k0, k_mid, k1]


LUNGE_SEQ = [S(0, 0, 0.4, 'Posição inicial'), S(0, 1, 0.45, 'Passo para trás'), S(1, 2, 0.75, 'Desça'),
             S(2, 2, 0.35, 'Segure'), S(2, 1, 0.75, 'Suba'), S(1, 0, 0.45, 'Volte o pé')]
lunge_bw = add_pattern(Pattern('lunge', 'Afundo', 'side', _lunge_keys(), LUNGE_SEQ))
lunge_db = add_pattern(Pattern('lunge_db', 'Afundo com halteres', 'side', _lunge_keys(FA(180, 180)), LUNGE_SEQ,
                               props=[db_end('handN')]))

# Agachamento búlgaro
def _bulgarian_keys():
    k0 = P((72, 70), 6, leg=IL((86, ANK), 1, 90), leg2=IL((40, 89.5), 1, 270))
    k1 = P((64, 92), 15, leg=IL((86, ANK), 1, 90), leg2=IL((40, 89.5), 1, 270))
    return [k0, k1]


bulgarian = add_pattern(Pattern('bulgarian', 'Agachamento búlgaro', 'side', _bulgarian_keys(), rep_seq(),
                                props=[bench(10, BENCH_TOP, 34), db_end('handN')]))

# Subida no banco (step-up)
BOX = dict(type='box', x=84, y=106, w=32, h=GROUND - 106)


def _stepup_keys():
    k0 = P((78, 72), 4, leg=IL((94, 102), 1, 90), leg2=IL((74, ANK), 1, 90))
    k1 = P((88, 62), 16, leg=IL((94, 102), 1, 90), leg2=IL((80, 110), 1, 120))
    k2 = P((94.5, 51.5), 0, leg=IL((95, 102), 1, 90), leg2=IL((91, 102), 1, 90))
    return [k0, k1, k2]


stepup = add_pattern(Pattern('step_up', 'Subida no banco', 'side', _stepup_keys(),
                             [S(0, 0, 0.4, 'Pé inteiro no banco'), S(0, 1, 0.6, 'Empurre pelo calcanhar'),
                              S(1, 2, 0.6, 'Suba'), S(2, 2, 0.35, 'Fique em pé'), S(2, 1, 0.7, 'Desça controlando'),
                              S(1, 0, 0.6, 'Desça controlando')], props=[BOX], vp=(0, -6, 160, 136)))

# Leg press 45
LP_HIP = (52.0, 98.0)


def _legpress_keys():
    k0 = P(LP_HIP, 318, head=0, arm=IA((60, 101), -1), leg=IL(add(LP_HIP, d(45), 47.5), 1, 315))
    k1 = P(LP_HIP, 318, head=0, arm=IA((60, 101), -1), leg=IL(add(LP_HIP, d(45), 23), 1, 315))
    return [k0, k1]


legpress = add_pattern(Pattern(
    'leg_press', 'Leg press 45°', 'side', _legpress_keys(), rep_seq(l1='Flexione os joelhos', l3='Empurre'),
    props=[dict(type='line', x1=44, y1=118, x2=150, y2=12, w=3),
           dict(type='poly', pts=[(30, 92), (52, 106), (60, 106), (38, 90)]),
           dict(type='poly', pts=[(20, 80), (24, 74), (46, 94), (42, 100)]),
           dict(type='line', x1=50, y1=106, x2=50, y2=GROUND, w=3),
           dict(type='sled', angle=45.0, len=30.0,
                track=[lambda J: add(mid(J['ankN'], J['toeN']), d(45), 3.5)])]))

# Cadeira extensora
def _legext_keys():
    base = dict(arm=IA((60, 100), -1))
    k0 = P((56, 95), 352, leg=FL(90, 180, 90), **base)
    k1 = P((56, 95), 352, leg=FL(90, 86, -4), **base)
    return [k0, k1]


def _shin_pad(J, side_sign):
    shin = sub(J['ankN'], J['kneeN'])
    s = d(ang(shin))
    front = (s[1], -s[0]) if side_sign > 0 else (-s[1], s[0])
    return add(add(J['ankN'], s, -3.0), front, 5.0)


legext = add_pattern(Pattern(
    'leg_extension', 'Cadeira extensora', 'side', _legext_keys(), rep_seq(l1='Estenda os joelhos', l3='Volte devagar',
                                                                        top=0.4, bottom=0.4),
    props=[dict(type='rect', x=40, y=101, w=44, h=6), dict(type='poly', pts=[(38, 101), (44, 101), (40, 58), (34, 58)]),
           dict(type='line', x1=62, y1=107, x2=62, y2=GROUND, w=3),
           dict(type='lever', x=82.5, y=95.5, track=[lambda J: _shin_pad(J, 1)]),
           dict(type='pad', r=4.5, track=[lambda J: _shin_pad(J, 1)])]))

# Mesa flexora (deitado)
def _legcurl_keys():
    base = dict(arm=IA((112, 99), -1), head=8)
    k0 = P((72, 87), 90, leg=FL(270, 270, 180), **base)
    k1 = P((72, 87), 90, leg=FL(272, 355, 265), **base)
    return [k0, k1]


legcurl = add_pattern(Pattern(
    'leg_curl_lying', 'Mesa flexora', 'side', _legcurl_keys(), rep_seq(l1='Flexione os joelhos', l3='Volte devagar',
                                                                     top=0.4, bottom=0.4),
    props=[bench(48, BENCH_TOP, 82), dict(type='lever', x=46.5, y=89,
                                          track=[lambda J: _shin_pad(J, -1)]),
           dict(type='pad', r=4.5, track=[lambda J: _shin_pad(J, -1)])]))

# Cadeira flexora (sentado)
def _legcurl_seated_keys():
    base = dict(arm=IA((60, 96), -1))
    k0 = P((56, 92), 352, leg=FL(90, 92, 2), **base)
    k1 = P((56, 92), 352, leg=FL(90, 198, 108), **base)
    return [k0, k1]


legcurl_seated = add_pattern(Pattern(
    'leg_curl_seated', 'Cadeira flexora', 'side', _legcurl_seated_keys(),
    rep_seq(l1='Puxe os calcanhares para baixo', l3='Volte devagar', top=0.4, bottom=0.4),
    props=[dict(type='rect', x=40, y=98, w=44, h=6), dict(type='poly', pts=[(38, 98), (44, 98), (40, 56), (34, 56)]),
           dict(type='line', x1=62, y1=104, x2=62, y2=GROUND, w=3),
           dict(type='rect', x=66, y=78.5, w=16, h=5),
           dict(type='lever', x=82, y=92, track=[lambda J: _shin_pad(J, -1)]),
           dict(type='pad', r=4.5, track=[lambda J: _shin_pad(J, -1)])]))

# Stiff / terra romeno
def _rdl_keys(arm_top=FA(180, 180), arm_bot=FA(195, 195), hold_back=False):
    k0 = P((79, 68), 0, arm=arm_top, leg=IL((80, ANK), 1, 90))
    k1 = P((64, 74), 70, arm=arm_bot, leg=IL((80, ANK), 1, 90))
    if hold_back:
        for k in (k0, k1):
            k['arm'] = IA(add(back_bar_point(k), front_of(k['torso']), 1.5), 1)
    return [k0, k1]


RDL_SEQ = rep_seq(l1='Quadril para trás', l3='Suba contraindo os glúteos', bottom=0.3)
rdl_db = add_pattern(Pattern('rdl_db', 'Stiff com halteres', 'side', _rdl_keys(), RDL_SEQ, props=[db_end()]))
rdl_bb = add_pattern(Pattern('rdl_bb', 'Stiff com barra', 'side', _rdl_keys(), RDL_SEQ, props=[plate()]))
good_morning = add_pattern(Pattern('good_morning', 'Bom dia', 'side', _rdl_keys(hold_back=True), RDL_SEQ,
                                   props=[dict(type='plate', track=[lambda J: add(add(J['neck'], d(J['_torso']), -2.0),
                                                                                  front_of(J['_torso']), -5.5)])]))
pull_through = add_pattern(Pattern('pull_through', 'Pull through no cabo', 'side',
                                   _rdl_keys(FA(178, 178), FA(205, 205)), RDL_SEQ,
                                   props=[dict(type='pulley', x=12, y=114), cable(12, 114)]))

# Levantamento terra
def _deadlift_keys():
    bar_x = 84.0
    def k(sh_y, torso, arm_tilt=180):
        neck = (bar_x + 2, sh_y)
        hip = hip_from_neck(neck, torso)
        return P(hip, torso, arm=FA(arm_tilt, arm_tilt), leg=IL((81, ANK), 1, 90))
    # saída do chão: quadril acima dos joelhos, ombros sobre a barra (o tronco
    # em 52 graus deixava o quadril baixo demais, parecendo um agachamento)
    k0 = k(74.5, 63, 182)
    k1 = k(54.5, 48, 181)
    k2 = P((79, 68), 0, arm=FA(180, 180), leg=IL((81, ANK), 1, 90))
    return [k0, k1, k2]


deadlift = add_pattern(Pattern('deadlift', 'Levantamento terra', 'side', _deadlift_keys(),
                               [S(0, 0, 0.5, 'Barra sobre o meio do pé'), S(0, 1, 0.7, 'Empurre o chão'),
                                S(1, 2, 0.6, 'Estenda o quadril'), S(2, 2, 0.4, 'Fique ereto'),
                                S(2, 1, 0.7, 'Quadril para trás'), S(1, 0, 0.7, 'Apoie a barra')],
                               props=[plate()]))

# Elevação pélvica (hip thrust)
HT_SH = (37.0, 88.0)


def _ht_keys(pivot=HT_SH, ank_x=92.5, bottom=305, top=272, bar=True):
    def k(t, headtilt):
        hip = add(pivot, d(t), -L['torso'])
        kk = P(hip, t, head=headtilt, leg=IL((ank_x, ANK), 1, 90))
        if bar:
            kk['arm'] = IA(add(hip, front_of(t), 10.0), -1)
        else:
            kk['arm'] = FA(t + 180 - 8, t + 180 - 4)
        return kk
    return [k(bottom, 10), k(top, 26)]


hip_thrust = add_pattern(Pattern('hip_thrust', 'Elevação pélvica', 'side', _ht_keys(),
                                 rep_seq(l1='Desça o quadril', l3='Suba e contraia o glúteo', top=0.2, bottom=0.2)
                                 [1:] + [S(0, 0, 0.5, 'Segure no topo')],
                                 props=[bench(14, BENCH_TOP, 26), dict(type='plate', track=[hipbar_point])]))
# sequência começando embaixo: reorganiza
hip_thrust.seq = [S(0, 0, 0.35, 'Posição inicial'), S(0, 1, 1.0, 'Suba e contraia o glúteo'),
                  S(1, 1, 0.6, 'Segure no topo'), S(1, 0, 1.2, 'Desça controlando')]

GB_SH = (36.0, LIE_Y - 1)


def _bridge_keys():
    def k(t):
        hip = add(GB_SH, d(t), -L['torso'])
        # braços apoiados no chão ao lado do corpo, palmas para baixo
        return P(hip, t, head=6, arm=FA(90, 91), leg=IL((84, ANK), 1, 90))
    return [k(268), k(240)]


glute_bridge = add_pattern(Pattern('glute_bridge', 'Ponte de glúteo', 'side', _bridge_keys(),
                                   [S(0, 0, 0.35, 'Posição inicial'), S(0, 1, 1.0, 'Suba o quadril'),
                                    S(1, 1, 0.6, 'Contraia o glúteo'), S(1, 0, 1.2, 'Desça devagar')]))

# Quatro apoios (coice e perdigueiro)
QH = (55.0, 92.0)
Q_T = 68.5


def quad_base(**over):
    kw = dict(arm=FA(180, 180), arm2=FA(180, 180), leg=FL(180, 270, 270), leg2=FL(180, 270, 270), head=12)
    kw.update(over)
    return P(QH, Q_T, **kw)


donkey = add_pattern(Pattern('donkey_kick', 'Coice em quatro apoios', 'side',
                             [quad_base(leg=FL(178, 272, 272)), quad_base(leg=FL(262, 355, 265))],
                             rep_seq(l1='Leve o pé em direção ao teto', l3='Volte sem encostar o joelho',
                                     down=0.9, up=0.9, top=0.35, bottom=0.45)))
bird_dog = add_pattern(Pattern('bird_dog', 'Perdigueiro', 'side',
                               [quad_base(), quad_base(arm=FA(84, 86), leg2=FL(262, 266, 180))],
                               rep_seq(l1='Estenda braço e perna opostos', l2='Segure', l3='Volte ao centro',
                                       down=1.0, up=1.0, bottom=0.8)))

# Coice na polia (em pé)
def _kickback_keys():
    base = dict(arm=IA((104, 62), -1), leg2=IL((76, ANK), 1, 90))
    k0 = P((74, 67.5), 14, leg=FL(184, 184, 90), **base)
    k1 = P((74, 67.5), 18, leg=FL(212, 212, 120), **base)
    return [k0, k1]


cable_kickback = add_pattern(Pattern(
    'cable_kickback', 'Coice na polia', 'side', _kickback_keys(),
    rep_seq(l1='Leve a perna para trás', l3='Volte controlando', down=0.9, up=1.0),
    props=[dict(type='tower', x=110), dict(type='pulley', x=108, y=114), cable(108, 114, 'ankN')]))

# Abdução em pé (vista de frente)
def _abd_standing_keys():
    base = dict(arm=IA((88, 72), 1))
    k0 = P((80, HIP_Y - 0.4), 0, leg=FL(181, 181, 125), leg2=IL((74.3, ANK), -1, 235), **base)
    k1 = P((79, HIP_Y - 0.4), -4, leg=FL(146, 148, 120), leg2=IL((74.3, ANK), -1, 235), **base)
    return [k0, k1]


abd_standing = add_pattern(Pattern(
    'hip_abduction_standing', 'Abdução de quadril em pé', 'front', _abd_standing_keys(),
    rep_seq(l1='Afaste a perna para o lado', l3='Volte devagar', down=0.9, up=1.0),
    props=[dict(type='band', track=[J_('kneeN'), J_('kneeF')])]))
abd_cable = variant(abd_standing, 'hip_abduction_cable', 'Abdução na polia',
                    [dict(type='pulley', x=10, y=116), cable(10, 116, 'ankN')])

# Cadeira abdutora / adutora (vista de frente, sentado)
def _abd_machine_keys(open_first):
    closed = P((80, 85), 0, arm=IA((97, 88), 1), leg=FL(172, 182, 125), lt=0.75, ls=0.92)
    opened = P((80, 85), 0, arm=IA((97, 88), 1), leg=FL(122, 172, 125), lt=0.75, ls=0.92)
    return [opened, closed] if open_first else [closed, opened]


SEAT_FRONT = [dict(type='rect', x=56, y=88, w=48, h=7), dict(type='rect', x=60, y=40, w=40, h=48, op=0.35),
              dict(type='line', x1=80, y1=95, x2=80, y2=GROUND, w=4)]
abd_machine = add_pattern(Pattern('abductor_machine', 'Cadeira abdutora', 'front', _abd_machine_keys(False),
                                  rep_seq(l1='Abra as pernas', l3='Feche devagar', down=1.0, up=1.2),
                                  props=SEAT_FRONT + [dict(type='pad', r=4, track=[lambda J: add(J['kneeN'], (5, 0))]),
                                                      dict(type='pad', r=4, track=[lambda J: add(J['kneeF'], (-5, 0))])]))
add_machine = add_pattern(Pattern('adductor_machine', 'Cadeira adutora', 'front', _abd_machine_keys(True),
                                  rep_seq(l1='Feche as pernas', l3='Abra devagar', down=1.0, up=1.2),
                                  props=SEAT_FRONT + [dict(type='pad', r=4, track=[lambda J: add(J['kneeN'], (-4.5, 0))]),
                                                      dict(type='pad', r=4, track=[lambda J: add(J['kneeF'], (4.5, 0))])]))

# Abdução deitada de lado (vista de frente, deitado)
def _side_lying_keys():
    base = dict(arm=FA(100, 100), arm2=FA(270, 270), leg2=FL(90, 90, 0))
    k0 = P((90, 104), 270, leg=FL(90, 90, 0), **base)
    k1 = P((90, 104), 270, leg=FL(58, 58, 328), **base)
    return [k0, k1]


side_lying_abd = add_pattern(Pattern('side_lying_abduction', 'Abdução deitada', 'front', _side_lying_keys(),
                                     rep_seq(l1='Eleve a perna de cima', l3='Desça devagar', down=0.9, up=1.1),
                                     props=[dict(type='mat', x=6, x2=154)]))

# Panturrilha em pé
def _calf_keys():
    toe = (X0 + 10.3, ANK)
    up_ank = add(toe, d(128), -10.0)
    k0 = standing(X0, 0)
    k1 = P((up_ank[0], up_ank[1] - 50.8), 0, leg=IL(up_ank, 1, 128), leg2=IL(up_ank, 1, 128))
    return [k0, k1]


calf = add_pattern(Pattern('calf_raise', 'Panturrilha em pé', 'side', _calf_keys(),
                           rep_seq(l1='Suba na ponta dos pés', l2='Segure no topo', l3='Desça devagar',
                                   down=0.8, up=1.1, bottom=0.6)))


def _calf_seated_keys():
    toe = (96.0, 116.5)
    def k(fa):
        ank = add(toe, d(fa), -10.0)
        return P((60, 90), 2, arm=IA((84, 82), -1), leg=IL(ank, 1, fa))
    return [k(90), k(126)]


calf_seated = add_pattern(Pattern('calf_seated', 'Panturrilha sentado', 'side', _calf_seated_keys(),
                                  rep_seq(l1='Eleve os calcanhares', l2='Segure no topo', l3='Desça devagar',
                                          down=0.8, up=1.1, bottom=0.6),
                                  props=[dict(type='rect', x=40, y=97, w=34, h=6),
                                         dict(type='line', x1=56, y1=103, x2=56, y2=GROUND, w=3),
                                         dict(type='pad', r=4, track=[lambda J: add(J['kneeN'], (0, -6))]),
                                         dict(type='rect', x=88, y=119, w=18, h=3)]))

# Hiperextensão lombar 45°
HX_ANK = (42.0, 110.0)


def _hyper_keys():
    hip = add(HX_ANK, d(225), -50.6)
    def k(t):
        kk = P(hip, t, leg=IL(HX_ANK, 1, 300))
        kk['arm'] = IA(chest_point(kk, 5, 7), 1)
        return kk
    return [k(45), k(148)]


hyper = add_pattern(Pattern('hyperextension', 'Hiperextensão lombar', 'side', _hyper_keys(),
                            [S(0, 0, 0.4, 'Corpo alinhado'), S(0, 1, 1.2, 'Desça o tronco'), S(1, 1, 0.3, 'Segure'),
                             S(1, 0, 1.1, 'Suba até alinhar, sem passar')],
                            props=[dict(type='poly', pts=[(78, 88), (86, 80), (92, 86), (84, 94)]),
                                   dict(type='line', x1=36, y1=116, x2=96, y2=56, w=3),
                                   dict(type='line', x1=60, y1=96, x2=60, y2=GROUND, w=3),
                                   dict(type='rect', x=34, y=112, w=16, h=3)]))

# Agachamento na parede (isometria)
def _wallsit_keys():
    base = dict(arm=FA(150, 100), leg=IL((78, ANK), 1, 90))
    return [P((52, 93), 0, **base), P((52, 92.5), 0, **base)]


wall_sit = add_pattern(Pattern('wall_sit', 'Agachamento isométrico na parede', 'side', _wallsit_keys(),
                               [S(0, 1, 1.5, 'Segure a posição'), S(1, 0, 1.5, 'Respire')],
                               props=[dict(type='wall', x=44)]))

# =========================================================== PEITO

BP_HIP = (80.0, 86.5)


def _press_lying_keys(top_hand=(51.5, 48.5), bot_hand=(57.0, 75.0)):
    base = dict(leg=IL((104, ANK), 1, 90), head=0)
    return [P(BP_HIP, 270, arm=IA(top_hand, -1), **base), P(BP_HIP, 270, arm=IA(bot_hand, -1), **base)]


BENCH_FLAT = bench(26, BENCH_TOP, 86)
bench_bb = add_pattern(Pattern('bench_press', 'Supino reto', 'side', _press_lying_keys(), rep_seq(
    l1='Desça até o meio do peito', l3='Empurre', top=0.4, bottom=0.25), props=[BENCH_FLAT, plate()]))
bench_db = variant(bench_bb, 'bench_press_db', 'Supino com halteres', [BENCH_FLAT, db_end()])

INC_HIP = (66.0, 88.5)
INC_T = 302.0


def _incline_keys():
    neck = add(INC_HIP, d(INC_T), L['torso'])
    top = add(neck, (0.8, -38.4))
    tmp = P(INC_HIP, INC_T, leg=IL((96, ANK), 1, 90))
    bot = chest_point(tmp, 6, 10)
    base = dict(leg=IL((96, ANK), 1, 90))
    return [P(INC_HIP, INC_T, arm=IA(top, -1), **base), P(INC_HIP, INC_T, arm=IA(bot, -1), **base)]


INC_PROPS = [dict(type='poly', pts=[(58, 95), (64, 101), (36, 78), (30, 72)]),
             dict(type='rect', x=56, y=95, w=24, h=5), dict(type='line', x1=66, y1=100, x2=66, y2=GROUND, w=3)]
incline_bb = add_pattern(Pattern('incline_press', 'Supino inclinado', 'side', _incline_keys(),
                                 rep_seq(l1='Desça até a parte alta do peito', l3='Empurre', top=0.4, bottom=0.25),
                                 props=INC_PROPS + [plate()]))
incline_db = variant(incline_bb, 'incline_press_db', 'Supino inclinado com halteres', INC_PROPS + [db_end()])

# Crucifixo (vista de cima, deitado)
def _fly_keys():
    base = dict(leg=FL(90, 90, 0), ls=0.45)
    k0 = P((100, 65), 270, arm=FA(0, 0), au=-0.2, af=-0.2, **base)
    k1 = P((100, 65), 270, arm=FA(0, 12), au=0.95, af=0.95, **base)
    return [k0, k1]


fly_db = add_pattern(Pattern('fly_db', 'Crucifixo com halteres', 'front', _fly_keys(),
                             rep_seq(l1='Abra os braços em arco', l3='Feche em arco', down=1.3, up=1.2),
                             props=[dict(type='rect', x=40, y=56, w=96, h=18, op=0.55), db_end('handN'),
                                    db_end('handF')], plane='top'))

# Voador (peck deck) e voador invertido, sentado de frente
def _pecdeck_keys(open_first=True):
    base = dict(leg=FL(175, 180, 125), lt=0.4)
    opened = P((80, 85), 0, arm=FA(91, 96), **base)
    if open_first:
        # voador: as mãos se encontram à frente do peito
        closed = P((80, 85), 0, arm=FA(91, 91), au=-0.28, af=-0.28, **base)
        return [opened, closed]
    # voador invertido: começa com os braços esticados à frente, cada mão na
    # frente do seu ombro (sem cruzar), e abre até formar um T
    closed = P((80, 85), 0, arm=FA(91, 91), au=-0.12, af=-0.12, **base)
    return [closed, opened]


pec_deck = add_pattern(Pattern('pec_deck', 'Voador', 'front', _pecdeck_keys(True),
                               rep_seq(l1='Feche os braços à frente', l3='Abra devagar', down=1.0, up=1.2),
                               props=SEAT_FRONT[:1] + SEAT_FRONT[2:] + [db_end('handN'), db_end('handF')]))
reverse_fly = add_pattern(Pattern('reverse_fly', 'Voador invertido', 'front', _pecdeck_keys(False),
                                  rep_seq(l1='Abra os braços para trás', l3='Volte devagar', down=1.0, up=1.2),
                                  props=SEAT_FRONT[:1] + SEAT_FRONT[2:] + [db_end('handN'), db_end('handF')]))

# Crossover (vista de frente, em pé)
def _crossover_keys():
    lg = dict(leg=IL((88.3, ANK), 1, 125), arm2=None)
    return [P((80, HIP_Y), 0, arm=FA(48, 58), **lg), P((80, HIP_Y), 0, arm=FA(200, 206), au=0.85, af=0.85, **lg)]


crossover = add_pattern(Pattern('cable_crossover', 'Crossover', 'front', _crossover_keys(),
                                rep_seq(l1='Traga as mãos para baixo e ao centro', l3='Volte em arco', down=1.0, up=1.2),
                                props=[dict(type='pulley', x=152, y=10), dict(type='pulley', x=8, y=10),
                                       cable(152, 10, 'handN'), cable(8, 10, 'handF')]))

# Flexão de braço e variações
PU_ANK = (36.0, 112.0)


def _plank_pose(ankle, t, arm, leg_foot=165, knee=None, **kw):
    if knee is None:
        hip = add(ankle, d(t), 50.7)
        return P(hip, t, arm=arm, leg=IL(ankle, 1, leg_foot), **kw)
    hip = add(knee, d(t), L['th'])
    return P(hip, t, arm=arm, leg=FL(t + 180, 300, 270), **kw)


def _pushup_keys(ankle=PU_ANK, hand_y=119.5, top_t=None, bot_t=86.0, knee=None):
    length = 80.7 if knee is None else (L['th'] + L['torso'])
    base = knee if knee is not None else ankle
    if top_t is None:
        sh_y = hand_y - 38.7
        top_t = math.degrees(math.acos((base[1] - sh_y) / length))
    sh_top = add(base, d(top_t), length)
    hand = (sh_top[0] + 1.0, hand_y)
    k0 = _plank_pose(ankle, top_t, IA(hand, -1), knee=knee, head=4)
    k1 = _plank_pose(ankle, bot_t, IA(hand, -1), knee=knee, head=4)
    return [k0, k1]


pushup = add_pattern(Pattern('push_up', 'Flexão de braço', 'side', _pushup_keys(),
                             rep_seq(l1='Desça o peito', l3='Empurre o chão', top=0.35, bottom=0.2)))
pushup_knee = add_pattern(Pattern('push_up_knee', 'Flexão com joelhos', 'side',
                                  _pushup_keys(knee=(58.0, 117.5), bot_t=78.0),
                                  rep_seq(l1='Desça o peito', l3='Empurre o chão', top=0.35, bottom=0.2),
                                  props=[dict(type='mat', x=30, x2=140)]))
pushup_incline = add_pattern(Pattern('push_up_incline', 'Flexão inclinada', 'side',
                                     _pushup_keys(hand_y=92.0, bot_t=58.0),
                                     rep_seq(l1='Leve o peito ao banco', l3='Empurre', top=0.35, bottom=0.2),
                                     props=[bench(102, 94.5, 40, 5)]))

# Paralelas
def _dips_keys():
    hand = (88.0, 66.0)
    def k(neck, t, sh):
        hip = hip_from_neck(neck, t)
        return P(hip, t, arm=IA(hand, -1), leg=FL(175, sh, 150), head=6)
    return [k((88.5, 27.2), 10, 215), k((91.0, 42.0), 22, 230)]


dips = add_pattern(Pattern('dips', 'Paralelas', 'side', _dips_keys(),
                           rep_seq(l1='Desça dobrando os cotovelos', l3='Empurre para cima', top=0.35, bottom=0.2),
                           props=[dict(type='bars', x1=66, x2=112, y=66)]))


def _bench_dip_keys():
    hand = (42.0, 92.0)
    def k(neck):
        hip = hip_from_neck(neck, 350)
        return P(hip, 350, arm=IA(hand, -1), leg=IL((90, ANK), 1, 90))
    return [k((49.0, 55.0)), k((46.0, 66.0))]


bench_dip = add_pattern(Pattern('bench_dip', 'Tríceps no banco', 'side', _bench_dip_keys(),
                                rep_seq(l1='Desça dobrando os cotovelos', l3='Estenda os braços', top=0.35, bottom=0.2),
                                props=[bench(12, BENCH_TOP, 32)]))

# =========================================================== OMBROS

def _ohp_keys(seated=False):
    if seated:
        hip = (76.0, 93.0)
        legs = dict(leg=IL((102, ANK), 1, 90))
    else:
        hip = (X0, HIP_Y)
        legs = dict(leg=IL((X0 + 0.3, ANK), 1, 90))
    neck = add(hip, (0, -L['torso']))
    k0 = P(hip, 0, arm=IA(add(neck, (8, -1)), -1), **legs)
    k1 = P(hip, 0, head=-10, arm=IA(add(neck, (10, -18)), -1), **legs)
    k2 = P(hip, 0, arm=IA(add(neck, (-0.5, -38.6)), -1), **legs)
    return [k0, k1, k2]


OHP_SEQ = [S(0, 0, 0.45, 'Barra na altura dos ombros'), S(0, 1, 0.45, 'Empurre para cima'),
           S(1, 2, 0.55, 'Estenda os braços'), S(2, 2, 0.35, 'Segure'), S(2, 1, 0.6, 'Desça controlando'),
           S(1, 0, 0.5, 'Desça controlando')]
ohp = add_pattern(Pattern('overhead_press', 'Desenvolvimento em pé', 'side', _ohp_keys(), OHP_SEQ,
                          props=[plate()], vp=(0, -14, 160, 144)))
ohp_seated = add_pattern(Pattern('overhead_press_db', 'Desenvolvimento sentado', 'side', _ohp_keys(True), OHP_SEQ,
                                 props=[dict(type='rect', x=58, y=100, w=30, h=6),
                                        dict(type='rect', x=62, y=48, w=6, h=52),
                                        dict(type='line', x1=73, y1=106, x2=73, y2=GROUND, w=3), db_end()],
                                 vp=(0, -14, 160, 144)))


def _lateral_keys():
    lg = dict(leg=IL((88.3, ANK), 1, 125))
    return [P((80, HIP_Y), 0, arm=FA(172, 168), **lg), P((80, HIP_Y), 0, arm=FA(91, 97), **lg)]


lateral = add_pattern(Pattern('lateral_raise', 'Elevação lateral', 'front', _lateral_keys(),
                              rep_seq(l1='Suba até a altura dos ombros', l3='Desça em 2 a 3 segundos',
                                      down=1.0, up=1.4, top=0.35, bottom=0.25),
                              props=[db_end('handN'), db_end('handF')]))


def _front_raise_keys():
    return [standing(X0, 0, arm=FA(178, 176)), standing(X0, 0, arm=FA(92, 96))]


front_raise = add_pattern(Pattern('front_raise', 'Elevação frontal', 'side', _front_raise_keys(),
                                  rep_seq(l1='Suba até a altura dos ombros', l3='Desça devagar', down=1.0, up=1.3),
                                  props=[db_end()]))


def _shrug_keys():
    lg = dict(leg=IL((88.3, ANK), 1, 125), arm=FA(176, 178))
    return [P((80, HIP_Y), 0, **lg), P((80, HIP_Y), 0, shrug=5.5, **lg)]


shrug = add_pattern(Pattern('shrug', 'Encolhimento', 'front', _shrug_keys(),
                            rep_seq(l1='Eleve os ombros', l2='Segure', l3='Desça devagar', down=0.7, up=0.9,
                                    bottom=0.6), props=[db_end('handN'), db_end('handF')]))


def _facepull_keys():
    k0 = standing(72, 0, arm=FA(84, 86))
    k1 = standing(72, 0, arm=FA(84, 14), au=-0.45)
    return [k0, k1]


face_pull = add_pattern(Pattern('face_pull', 'Face pull', 'side', _facepull_keys(),
                                rep_seq(l1='Puxe a corda em direção ao rosto', l2='Abra os cotovelos',
                                        l3='Volte devagar', down=1.0, up=1.2),
                                props=[dict(type='tower', x=128), dict(type='pulley', x=124, y=30),
                                       cable(124, 30, 'handN')]))

# =========================================================== BRAÇOS

def _curl_keys(top_fore=30.0):
    return [standing(X0, 0, arm=FA(180, 178)), standing(X0, 0, arm=FA(176, top_fore))]


CURL_SEQ = rep_seq(l1='Flexione os cotovelos', l3='Desça devagar', down=1.0, up=1.4, top=0.35, bottom=0.3)
curl_db = add_pattern(Pattern('curl', 'Rosca direta', 'side', _curl_keys(), CURL_SEQ, props=[db_end()]))
curl_bb = variant(curl_db, 'curl_bb', 'Rosca direta com barra', [plate()])
hammer = variant(curl_db, 'hammer_curl', 'Rosca martelo',
                 [dict(type='db_side', angle=0.0, along=True, track=[J_('handN'), J_('elbN')])])
curl_cable = variant(curl_db, 'curl_cable', 'Rosca na polia', [dict(type='pulley', x=112, y=116),
                                                                cable(112, 116, 'handN')])


def _preacher_keys():
    hip = (66.0, 94.0)
    base = dict(leg=IL((96, ANK), 1, 90))
    return [P(hip, 15, arm=FA(140, 140), **base), P(hip, 15, arm=FA(140, 28), **base)]


preacher = add_pattern(Pattern('preacher_curl', 'Rosca Scott', 'side', _preacher_keys(),
                               rep_seq(l1='Flexione os cotovelos', l3='Desça até quase estender', down=1.0, up=1.4),
                               props=[dict(type='poly', pts=[(78, 78), (84, 72), (102, 92), (96, 98)]),
                                      dict(type='line', x1=94, y1=96, x2=94, y2=GROUND, w=3),
                                      dict(type='rect', x=54, y=101, w=26, h=6),
                                      dict(type='line', x1=66, y1=107, x2=66, y2=GROUND, w=3), plate()]))


def _pushdown_keys():
    lg = dict(leg=IL((76.3, ANK), 1, 90), leg2=IL((76.3, ANK), 1, 90))
    k0 = P((76, HIP_Y), 8, arm=FA(176, 72), **lg)
    k1 = P((76, HIP_Y), 8, arm=FA(178, 176), **lg)
    return [k0, k1]


pushdown = add_pattern(Pattern('triceps_pushdown', 'Tríceps na polia', 'side', _pushdown_keys(),
                               rep_seq(l1='Estenda os cotovelos', l3='Volte até 90 graus', down=0.9, up=1.2),
                               props=[dict(type='tower', x=112), dict(type='pulley', x=106, y=6),
                                      cable(106, 6, 'handN')]))


def _overhead_ext_keys():
    return [standing(X0, 0, arm=FA(357, 200)), standing(X0, 0, arm=FA(358, 356))]


overhead_ext = add_pattern(Pattern('overhead_triceps', 'Tríceps francês', 'side', _overhead_ext_keys(),
                                   [S(0, 0, 0.4, 'Halter atrás da cabeça'), S(0, 1, 1.0, 'Estenda os cotovelos'),
                                    S(1, 1, 0.3, 'Segure'), S(1, 0, 1.3, 'Desça atrás da cabeça')],
                                   props=[db_end()], vp=(0, -14, 160, 144)))


def _skull_keys():
    base = dict(leg=IL((104, ANK), 1, 90))
    return [P(BP_HIP, 270, arm=FA(352, 352), **base), P(BP_HIP, 270, arm=FA(352, 236), **base)]


skull = add_pattern(Pattern('skull_crusher', 'Tríceps testa', 'side', _skull_keys(),
                            rep_seq(l1='Dobre só os cotovelos', l3='Estenda', down=1.2, up=1.0),
                            props=[BENCH_FLAT, plate()]))


def _kickback_tri_keys():
    hip = (64.0, 72.0)
    base = dict(arm2=FA(178, 178), leg=IL((66, ANK), 1, 90), leg2=IL((74, ANK), 1, 90), head=8)
    return [P(hip, 75, arm=FA(262, 180), **base), P(hip, 75, arm=FA(263, 262), **base)]


tri_kickback = add_pattern(Pattern('triceps_kickback', 'Tríceps coice', 'side', _kickback_tri_keys(),
                                   rep_seq(l1='Estenda o cotovelo para trás', l3='Volte devagar', down=0.9, up=1.1),
                                   props=[bench(90, 103, 40), db_end()]))

# =========================================================== COSTAS

def _pulldown_keys():
    base = dict(leg=FL(165, 180, 125), lt=0.35)
    k0 = P((80, 85), 0, arm=IA((106.6, 19.5), -1), **base)
    k1 = P((80, 85), 0, arm=IA((100.0, 52.0), -1), **base)
    return [k0, k1]


pulldown = add_pattern(Pattern(
    'lat_pulldown', 'Puxada frontal', 'front', _pulldown_keys(),
    rep_seq(l1='Leve a barra à parte alta do peito', l3='Suba controlando', down=1.0, up=1.3, top=0.35, bottom=0.3),
    props=[dict(type='rect', x=58, y=88, w=44, h=7), dict(type='line', x1=80, y1=95, x2=80, y2=GROUND, w=4),
           dict(type='rect', x=62, y=80, w=36, h=5),
           dict(type='cablev', track=[lambda J: mid(J['handN'], J['handF'])], y=-14),
           dict(type='seg', w=2.2, track=[lambda J: add(J['handN'], (6, 0)), lambda J: add(J['handF'], (-6, 0))])],
    vp=(0, -14, 160, 144)))


def _pullup_keys():
    def k(neck_y, legs):
        neck = (80.0, neck_y)
        return P(add(neck, (0, L['torso'])), 0, arm=IA((104, -10), -1), leg=legs)
    return [k(26.4, FL(180, 182, 125)), k(-7.5, FL(176, 186, 125))]


pullup = add_pattern(Pattern('pull_up', 'Barra fixa', 'front', _pullup_keys(),
                             [S(0, 0, 0.45, 'Pendure com braços estendidos'), S(0, 1, 1.0, 'Puxe o peito à barra'),
                              S(1, 1, 0.3, 'Queixo acima da barra'), S(1, 0, 1.2, 'Desça controlando')],
                             props=[dict(type='pullbar', x1=40, x2=120, y=-10)], vp=(-20, -32, 200, 162)))


def _row_seated_keys():
    base = dict(leg=IL((98, 106), 1, 0))
    k0 = P((54, 97), 12, arm=IA((97.5, 77), -1), **base)
    k1 = P((54, 97), 0, arm=IA((66, 84), -1), **base)
    return [k0, k1]


row_seated = add_pattern(Pattern('seated_row', 'Remada sentada', 'side', _row_seated_keys(),
                                 rep_seq(l1='Puxe com os cotovelos para trás', l2='Junte as escápulas',
                                         l3='Estenda os braços devagar', down=1.0, up=1.3),
                                 props=[dict(type='rect', x=30, y=104, w=46, h=6),
                                        dict(type='rect', x=101, y=90, w=5, h=26),
                                        dict(type='line', x1=50, y1=110, x2=50, y2=GROUND, w=3),
                                        dict(type='tower', x=118), dict(type='pulley', x=114, y=80),
                                        cable(114, 80, 'handN')]))


def _bentrow_keys():
    hip = (64.0, 76.0)
    t = 65.0
    base = dict(leg=IL((80, ANK), 1, 90), head=6)
    tmp = P(hip, t, **base)
    tgt = add(add(hip, d(t), 12.0), front_of(t), 9.0)
    return [P(hip, t, arm=FA(185, 185), **base), P(hip, t, arm=IA(tgt, -1), **base)]


BR_SEQ = rep_seq(l1='Puxe em direção ao abdômen', l2='Junte as escápulas', l3='Desça devagar', down=0.9, up=1.2)
bent_row = add_pattern(Pattern('bent_row', 'Remada curvada', 'side', _bentrow_keys(), BR_SEQ, props=[plate()]))
bent_row_db = variant(bent_row, 'bent_row_db', 'Remada curvada com halteres', [db_end()])


def _onearm_row_keys():
    hip = (70.0, 72.0)
    t = 82.0
    base = dict(arm2=IA((99.5, 99.5), -1), leg=IL((64, ANK), 1, 90), leg2=FL(180, 270, 270), head=8)
    tgt = add(add(hip, d(t), 8.0), front_of(t), 8.0)
    return [P(hip, t, arm=FA(180, 180), **base), P(hip, t, arm=IA(tgt, -1), **base)]


onearm_row = add_pattern(Pattern('one_arm_row', 'Remada unilateral', 'side', _onearm_row_keys(), BR_SEQ,
                                 props=[bench(40, 101.5, 90), db_end()]))


def _straight_pd_keys():
    lg = dict(leg=IL((70.3, ANK), 1, 90), head=4)
    return [P((66, 68.5), 25, arm=FA(62, 64), **lg), P((66, 68.5), 25, arm=FA(172, 174), **lg)]


straight_pd = add_pattern(Pattern('straight_arm_pulldown', 'Pulldown com braços estendidos', 'side',
                                  _straight_pd_keys(),
                                  rep_seq(l1='Leve a barra até as coxas', l3='Suba devagar', down=1.0, up=1.2),
                                  props=[dict(type='tower', x=126), dict(type='pulley', x=122, y=8),
                                         cable(122, 8, 'handN')]))

# =========================================================== CORE

def _plank_keys():
    ank = (34.0, 112.0)
    def k(dt):
        t = 81.8 + dt
        hip = add(ank, d(t), 50.7)
        return P(hip, t, arm=FA(180, 90), leg=IL(ank, 1, 165), head=4)
    return [k(0), k(-0.6)]


plank = add_pattern(Pattern('plank', 'Prancha', 'side', _plank_keys(),
                            [S(0, 1, 1.5, 'Corpo em linha reta'), S(1, 0, 1.5, 'Respire normalmente')],
                            props=[dict(type='mat', x=20, x2=150)]))


def _plank_knee_keys():
    knee = (62.0, 117.5)
    def k(dt):
        t = 74.0 + dt
        hip = add(knee, d(t), L['th'])
        return P(hip, t, arm=FA(180, 90), leg=FL(t + 180, 300, 270), head=4)
    return [k(0), k(-0.6)]


plank_knee = add_pattern(Pattern('plank_knee', 'Prancha com joelhos', 'side', _plank_knee_keys(),
                                 [S(0, 1, 1.5, 'Ombros sobre os cotovelos'), S(1, 0, 1.5, 'Respire')],
                                 props=[dict(type='mat', x=20, x2=150)]))


def _side_plank_keys():
    def k(lift):
        t = 285.0
        perp = front_of(t)
        far_sh_y = 100.5 - lift
        neck_y = far_sh_y + perp[1] * 11.0
        neck = (50.0, neck_y)
        hip = hip_from_neck(neck, t)
        return P(hip, t, arm=FA(105, 105), arm2=FA(180, 270), au2=1.0, af2=0.3,
                 leg=FL(105, 105, 15), leg2=FL(105, 105, 15))
    return [k(0), k(1.2)]


side_plank = add_pattern(Pattern('side_plank', 'Prancha lateral', 'front', _side_plank_keys(),
                                 [S(0, 1, 1.5, 'Quadril alto'), S(1, 0, 1.5, 'Respire')],
                                 props=[dict(type='mat', x=20, x2=150)]))

CR_HIP = (82.0, LIE_Y)


def _crunch_keys():
    def k(t, dx):
        kk = P((CR_HIP[0] - dx, CR_HIP[1]), t, head=8, leg=IL((104, ANK), 1, 90))
        kk['arm'] = IA(chest_point(kk, 7, 9), 1)
        return kk
    return [k(270, 0), k(292, 2.0)]


crunch = add_pattern(Pattern('crunch', 'Abdominal supra', 'side', _crunch_keys(),
                             rep_seq(l1='Tire as escápulas do chão', l2='Contraia', l3='Desça devagar', down=0.8,
                                     up=1.1, bottom=0.4), props=[dict(type='mat', x=20, x2=140)]))


def _legraise_keys():
    base = dict(arm=FA(90, 90))
    return [P(CR_HIP, 270, leg=FL(88, 88, -2), **base), P(CR_HIP, 270, leg=FL(2, 4, -86), **base)]


leg_raise = add_pattern(Pattern('leg_raise', 'Elevação de pernas', 'side', _legraise_keys(),
                                [S(0, 0, 0.35, 'Lombar no chão'), S(0, 1, 1.1, 'Suba as pernas'),
                                 S(1, 1, 0.25, 'Segure'), S(1, 0, 1.5, 'Desça devagar sem tocar o chão')],
                                props=[dict(type='mat', x=20, x2=150)]))


def _bicycle_keys():
    base = dict(head=10)
    def k(near_bent):
        bent, ext = FL(30, 115, 25), FL(76, 80, 350)
        kk = P(CR_HIP, 288, leg=bent if near_bent else ext, leg2=ext if near_bent else bent, **base)
        kk['arm'] = IA(add(neck_of(kk), d(288), 6), 1)
        kk['au'] = kk['au2'] = 0.55
        return kk
    return [k(True), k(False)]


bicycle = add_pattern(Pattern('bicycle_crunch', 'Abdominal bicicleta', 'side', _bicycle_keys(),
                              [S(0, 0, 0.25, 'Cotovelo em direção ao joelho'), S(0, 1, 0.7, 'Troque de lado'),
                               S(1, 1, 0.25, 'Cotovelo em direção ao joelho'), S(1, 0, 0.7, 'Troque de lado')],
                              props=[dict(type='mat', x=20, x2=150)]))


def _deadbug_keys():
    tab = FL(0, 90, 0)
    ext = FL(80, 84, 0)
    up = FA(0, 0)
    over = FA(-80, -80)
    k0 = P(CR_HIP, 270, arm=up, arm2=up, leg=tab, leg2=tab)
    k1 = P(CR_HIP, 270, arm=over, arm2=up, leg=tab, leg2=ext)
    k2 = P(CR_HIP, 270, arm=up, arm2=over, leg=ext, leg2=tab)
    return [k0, k1, k2]


dead_bug = add_pattern(Pattern('dead_bug', 'Dead bug', 'side', _deadbug_keys(),
                               [S(0, 0, 0.4, 'Lombar firme no chão'), S(0, 1, 1.0, 'Estenda braço e perna opostos'),
                                S(1, 0, 0.9, 'Volte ao centro'), S(0, 2, 1.0, 'Troque de lado'),
                                S(2, 0, 0.9, 'Volte ao centro')], props=[dict(type='mat', x=6, x2=154)]))


def _mclimb_keys():
    top = _pushup_keys()[0]
    hip, t = top['hip'], top['torso']
    back = IL(PU_ANK, 1, 165)
    fwd = IL((81, 108), 1, 160)
    return [P(hip, t, arm=top['arm'], leg=fwd, leg2=back, head=4),
            P(hip, t, arm=top['arm'], leg=back, leg2=fwd, head=4)]


mclimber = add_pattern(Pattern('mountain_climber', 'Escalador', 'side', _mclimb_keys(),
                               [S(0, 0, 0.12, 'Joelho ao peito'), S(0, 1, 0.38, 'Troque as pernas'),
                                S(1, 1, 0.12, 'Joelho ao peito'), S(1, 0, 0.38, 'Troque as pernas')]))


def _twist_keys():
    def k(s):
        hip = (80.0, GROUND - 8)
        t = 9.0 * s
        tgt = (80 + 21 * s, 104)
        return P(hip, t, arm=IA(tgt, -1), arm2=IA(tgt, 1), leg=FL(22, 172, 125), lt=0.45, ls=0.55,
                 leg2=FL(338, 188, 235))
    return [k(1), k(-1)]


russian_twist = add_pattern(Pattern('russian_twist', 'Giro russo', 'front', _twist_keys(),
                                    [S(0, 0, 0.25, 'Gire o tronco'), S(0, 1, 0.8, 'Troque de lado'),
                                     S(1, 1, 0.25, 'Gire o tronco'), S(1, 0, 0.8, 'Troque de lado')],
                                    props=[dict(type='mat', x=20, x2=140)]))


def _hanging_lr_keys():
    neck = (80.0, -10.0 + 38.6)
    hip = add(neck, (0, L['torso']))
    return [P(hip, 0, arm=FA(0, 0), leg=FL(180, 182, 150)), P(hip, -8, arm=FA(0, 0), leg=FL(92, 100, 20))]


hanging_lr = add_pattern(Pattern('hanging_leg_raise', 'Elevação de pernas na barra', 'side', _hanging_lr_keys(),
                                 [S(0, 0, 0.4, 'Pendure firme'), S(0, 1, 1.0, 'Suba as pernas'),
                                  S(1, 1, 0.3, 'Segure'), S(1, 0, 1.3, 'Desça sem balançar')],
                                 props=[dict(type='pullbar', x1=60, x2=100, y=-10)], vp=(-20, -32, 200, 162)))


def _superman_keys():
    hip = (60.0, LIE_Y)
    return [P(hip, 90, arm=FA(90, 90), leg=FL(270, 270, 270), head=0),
            P(hip, 80, arm=FA(77, 76), leg=FL(281, 281, 281), head=-4)]


superman = add_pattern(Pattern('superman', 'Super-homem', 'side', _superman_keys(),
                               rep_seq(l1='Eleve braços e pernas', l2='Segure', l3='Desça devagar', down=0.8, up=1.0,
                                       bottom=0.7), props=[dict(type='mat', x=4, x2=156)]))

# =========================================================== CARDIO / CORPO INTEIRO

def _gait_keys(run=False):
    lean = 8 if run else 2
    bob = 3.0 if run else 1.2
    stride = 15 if run else 12
    a_back, a_fwd = (FA(205, 120), FA(150, 60)) if run else (FA(196, 188), FA(164, 152))
    a_mid = FA(180, 100) if run else FA(180, 178)
    def contact(near):
        lead = IL((80 + stride, 116.5), 1, 75)
        trail = IL((80 - stride - 2, 113), 1, 125)
        return P((80, HIP_Y - 0.5 + (1.5 if run else 0)), lean, arm=a_back if near else a_fwd,
                 arm2=a_fwd if near else a_back, leg=lead if near else trail, leg2=trail if near else lead, head=-lean)
    def midst(near):
        stance = IL((80.5, ANK), 1, 90)
        swing = FL(172, 205, 120) if not run else FL(150, 230, 140)
        return P((80, HIP_Y - bob), lean, arm=a_mid, arm2=a_mid, leg=stance if near else swing,
                 leg2=swing if near else stance, head=-lean)
    return [contact(True), midst(True), contact(False), midst(False)]


def gait_seq(step):
    return [S(0, 1, step, 'Passada'), S(1, 2, step, 'Passada'), S(2, 3, step, 'Passada'), S(3, 0, step, 'Passada')]


TREADMILL = [dict(type='treadmill', x1=30, x2=134)]
walk = add_pattern(Pattern('walk', 'Caminhada', 'side', _gait_keys(), gait_seq(0.28), props=TREADMILL, linear=True))
run = add_pattern(Pattern('run', 'Corrida', 'side', _gait_keys(True), gait_seq(0.19), props=TREADMILL, linear=True))
farmer = add_pattern(Pattern('farmer_walk', 'Caminhada do fazendeiro', 'side',
                             [dict(k, arm=FA(180, 180), arm2=None) for k in _gait_keys()], gait_seq(0.3),
                             props=[db_end()], linear=True))


def _march_keys():
    def k(near_up):
        up, down = FL(98, 182, 120), IL((X0 + 0.3, ANK), 1, 90)
        return P((X0, HIP_Y), 0, arm=FA(200, 120) if near_up else FA(160, 80),
                 arm2=FA(160, 80) if near_up else FA(200, 120), leg=up if near_up else down,
                 leg2=down if near_up else up)
    k0 = standing(X0, 0)
    return [k(True), k0, k(False), k0]


march = add_pattern(Pattern('march', 'Marcha estacionária', 'side', _march_keys(),
                            [S(0, 1, 0.35, 'Joelho na altura do quadril'), S(1, 2, 0.35, 'Troque de perna'),
                             S(2, 3, 0.35, 'Joelho na altura do quadril'), S(3, 0, 0.35, 'Troque de perna')]))


def _bike_keys():
    c, r = (90.0, 103.0), 9.5
    keys = []
    for i in range(8):
        phi = i * 45.0
        a = add(c, d(phi), r)
        b = add(c, d(phi + 180), r)
        keys.append(P((66, 72), 28, arm=IA((106, 60), -1), leg=IL(a, 1, 102), leg2=IL(b, 1, 102), head=-14))
    return keys


bike = add_pattern(Pattern('bike', 'Bicicleta ergométrica', 'side', _bike_keys(),
                           [S(i, (i + 1) % 8, 0.12, 'Pedale') for i in range(8)],
                           props=[dict(type='bike', x=90, y=103, sx=62, sy=78, hx=108, hy=58)], linear=True))


def _rower_keys():
    feet = IL((112, 104), 1, 30)
    catch = P((88, 102), 25, arm=FA(103, 103), leg=feet)
    drive = P((66, 102), 25, arm=FA(103, 103), leg=feet)
    finish = P((64, 102), -20, arm=IA((66, 86), -1), leg=feet)
    arms_out = P((64, 102), -20, arm=FA(104, 104), leg=feet)
    lean = P((66, 102), 25, arm=FA(103, 103), leg=feet)
    return [catch, drive, finish, arms_out, lean]


rower = add_pattern(Pattern('rower', 'Remo ergômetro', 'side', _rower_keys(),
                            [S(0, 1, 0.55, 'Empurre com as pernas'), S(1, 2, 0.45, 'Incline e puxe'),
                             S(2, 2, 0.15, 'Final'), S(2, 3, 0.35, 'Braços à frente'),
                             S(3, 4, 0.35, 'Incline à frente'), S(4, 0, 0.6, 'Dobre os joelhos')],
                            props=[dict(type='line', x1=26, y1=110, x2=120, y2=110, w=3),
                                   dict(type='rect', x=56, y=104, w=16, h=4),
                                   dict(type='rect', x=110, y=96, w=6, h=12),
                                   dict(type='circle', x=140, y=96, r=12),
                                   cable(132, 92, 'handN')]))


def _jack_keys():
    lg_in = IL((86.3, ANK), 1, 125)
    lg_out = IL((101, ANK), 1, 125)
    k0 = P((80, HIP_Y), 0, arm=FA(174, 176), leg=lg_in)
    k1 = P((80, HIP_Y + 2.5), 0, arm=FA(22, 14), leg=lg_out)
    return [k0, k1]


jumping_jack = add_pattern(Pattern('jumping_jack', 'Polichinelo', 'front', _jack_keys(),
                                   [S(0, 1, 0.42, 'Abra braços e pernas'), S(1, 0, 0.42, 'Feche')],
                                   vp=(0, -14, 160, 144)))


def _rope_keys():
    lg = IL((84.3, ANK), 1, 125)
    k0 = P((80, HIP_Y), 0, arm=FA(168, 120), leg=lg)
    k1 = P((80, HIP_Y - 3.5), 0, arm=FA(168, 120), leg=FL(180, 180, 150))
    return [k0, k1]


def _rope_ctrl(J):
    t = J['_t']
    a = math.radians(t * 360.0)
    return (80.0, 72.0 - 70.0 * math.cos(a))


jump_rope = add_pattern(Pattern('jump_rope', 'Pular corda', 'front', _rope_keys(),
                                [S(0, 1, 0.2, 'Salto baixo'), S(1, 0, 0.2, 'Aterrisse na ponta dos pés'),
                                 S(0, 0, 0.2, 'Gire com os punhos')],
                                props=[dict(type='rope', track=[J_('handN'), J_('handF'), _rope_ctrl])],
                                vp=(0, -14, 160, 144)))


def _burpee_keys():
    stand = standing(X0, 0)
    squat = P((66, 98), 60, arm=IA((96.5, 119.5), -1), leg=IL((80.3, ANK), 1, 90), head=8)
    sh = (95.5, 80.8)
    t = 67.2
    ank = add(sh, d(t), -80.7)
    plank_ = P(add(ank, d(t), 50.7), t, arm=IA((96.5, 119.5), -1), leg=IL(ank, 1, 165), head=4)
    jump = P((80, HIP_Y - 8), 0, arm=FA(10, 6), leg=FL(178, 182, 140))
    return [stand, squat, plank_, jump]


burpee = add_pattern(Pattern('burpee', 'Burpee', 'side', _burpee_keys(),
                             [S(0, 1, 0.5, 'Agache e apoie as mãos'), S(1, 2, 0.35, 'Pés para trás'),
                              S(2, 2, 0.3, 'Prancha'), S(2, 1, 0.35, 'Pés de volta'),
                              S(1, 3, 0.4, 'Salte'), S(3, 0, 0.35, 'Aterrisse suave')],
                             vp=(0, -14, 160, 144)))


def _swing_keys():
    bottom = P((62, 76), 70, arm=FA(200, 200), leg=IL((80.3, ANK), 1, 90), head=6)
    top = P((X0, HIP_Y), 0, arm=FA(92, 92), leg=IL((80.3, ANK), 1, 90))
    return [bottom, top]


kb_swing = add_pattern(Pattern('kb_swing', 'Swing com kettlebell', 'side', _swing_keys(),
                               [S(0, 1, 0.55, 'Estenda o quadril com força'), S(1, 1, 0.15, 'Contraia o glúteo'),
                                S(1, 0, 0.55, 'Quadril para trás')],
                               props=[dict(type='kb', track=[J_('handN')])]))
