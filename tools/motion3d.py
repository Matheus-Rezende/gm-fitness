"""Converte os quadros 2D do estúdio em 3D e descreve os equipamentos em 3D.

Coordenadas 3D (mão direita):
  X = para a frente da pessoa (no desenho de lado, para a direita da tela)
  Y = para cima (o chão fica em Y = -122)
  Z = lateral. Na vista de lado, a câmera fica em +Z; o lado "N" (perto) é +Z.

Cada plano de desenho vira 3D assim:
  side : tela (x, y)  -> (x - cx, -y, Z lateral fixo por lado)
  front: tela (x, y)  -> (profundidade, -y, -(x - cx)); profundidade = para a frente
  top  : tela (x, y)  -> (x - cx, base + profundidade, -(y - cy)); profundidade = para cima

Segmentos encurtados no desenho (escala < 1) ganham o comprimento que falta
na direção fora do plano, então nada fica "achatado" quando a câmera gira.
"""
import math

from motion_core import L, JOINTS, GROUND, d, cw, front_of

SH_Z = 11.0     # meia largura dos ombros
HIP_Z = 6.0     # meia largura do quadril
TOP_BASE = -87.0  # altura do tronco deitado no banco (vista de cima)

LIMBS = {
    # articulação: (pai, comprimento, chave de escala)
    'elbN': ('shN', L['ua'], 'au'), 'handN': ('elbN', L['fa'], 'af'),
    'elbF': ('shF', L['ua'], 'au2'), 'handF': ('elbF', L['fa'], 'af2'),
    'kneeN': ('hipN', L['th'], 'lt'), 'ankN': ('kneeN', L['sh'], 'ls'),
    'kneeF': ('hipF', L['th'], 'lt2'), 'ankF': ('kneeF', L['sh'], 'ls2'),
}
CHAIN_ORDER = ['elbN', 'handN', 'elbF', 'handF', 'kneeN', 'ankN', 'kneeF', 'ankF']


def _out_of_plane(J, joint):
    parent, length, key = LIMBS[joint]
    s = J['_sc'][key]
    return math.sqrt(max(0.0, 1.0 - s * s)) * length


class Frame3D:
    def __init__(self, pts, torso_f, head_up, head_face):
        self.pts = pts
        self.torso_f = torso_f
        self.head_up = head_up
        self.head_face = head_face


def convert(J, plane, cx, cy):
    """Converte um quadro resolvido em 2D para 3D."""
    out_extra = {}
    if plane == 'side':
        def P(pt, z):
            return (pt[0] - cx, -pt[1], z)
        pts = {}
        pts['hip'] = P(J['hip'], 0.0)
        pts['neck'] = P(J['neck'], 0.0)
        pts['head'] = P(J['head'], 0.0)
        for side, sgn in (('N', 1.0), ('F', -1.0)):
            pts['sh' + side] = P(J['sh' + side], SH_Z * sgn)
            pts['hip' + side] = P(J['hip' + side], HIP_Z * sgn)
        z = {'shN': SH_Z, 'shF': -SH_Z, 'hipN': HIP_Z, 'hipF': -HIP_Z}
        for j in CHAIN_ORDER:
            parent = LIMBS[j][0]
            sgn = 1.0 if j.endswith('N') else -1.0
            z[j] = z[parent] + sgn * _out_of_plane(J, j)
            pts[j] = P(J[j], z[j])
        pts['toeN'] = P(J['toeN'], z['ankN'])
        pts['toeF'] = P(J['toeF'], z['ankF'])
        tf = front_of(J['_torso'])
        torso_f = (tf[0], -tf[1], 0.0)
        hu = d(J['_head'])
        hf = cw(hu)
        head_up = (hu[0], -hu[1], 0.0)
        head_face = (hf[0], -hf[1], 0.0)
    elif plane == 'front':
        def P(pt, dep):
            return (dep, -pt[1], -(pt[0] - cx))
        pts = {k: P(J[k], 0.0) for k in ('hip', 'neck', 'head', 'shN', 'shF', 'hipN', 'hipF')}
        dep = {'shN': 0.0, 'shF': 0.0, 'hipN': 0.0, 'hipF': 0.0}
        for j in CHAIN_ORDER:
            parent = LIMBS[j][0]
            dep[j] = dep[parent] + _out_of_plane(J, j)
            pts[j] = P(J[j], dep[j])
        pts['toeN'] = P(J['toeN'], dep['ankN'] + 4.0)
        pts['toeF'] = P(J['toeF'], dep['ankF'] + 4.0)
        torso_f = (1.0, 0.0, 0.0)
        hu = d(J['_head'])
        head_up = (0.0, -hu[1], -hu[0])
        head_face = (1.0, 0.0, 0.0)
    else:  # top
        def P(pt, dep):
            return (pt[0] - cx, TOP_BASE + dep, -(pt[1] - cy))
        pts = {k: P(J[k], 0.0) for k in ('hip', 'neck', 'head', 'shN', 'shF', 'hipN', 'hipF')}
        dep = {'shN': 0.0, 'shF': 0.0, 'hipN': 0.0, 'hipF': 0.0}
        for j in CHAIN_ORDER:
            parent = LIMBS[j][0]
            sgn = 1.0 if j.startswith(('elb', 'hand')) else -1.0
            dep[j] = dep[parent] + sgn * _out_of_plane(J, j)
            pts[j] = P(J[j], dep[j])
        pts['toeN'] = P(J['toeN'], dep['ankN'])
        pts['toeF'] = P(J['toeF'], dep['ankF'])
        torso_f = (0.0, 1.0, 0.0)
        hu = d(J['_head'])
        head_up = (hu[0], 0.0, hu[1])
        head_face = (0.0, 1.0, 0.0)
    return Frame3D(pts, torso_f, head_up, head_face)


def to_3d_point(pt, plane, cx, cy, depth=0.0):
    if plane == 'side':
        return (pt[0] - cx, -pt[1], depth)
    if plane == 'front':
        return (depth, -pt[1], -(pt[0] - cx))
    return (pt[0] - cx, TOP_BASE + depth, -(pt[1] - cy))


def in_plane_dir(v, plane):
    """Converte uma direção da tela (x, y para baixo) em direção 3D no plano do desenho."""
    if plane == 'side':
        return (v[0], -v[1], 0.0)
    if plane == 'front':
        return (0.0, -v[1], -v[0])
    return (v[0], 0.0, -v[1])


def out_dir(plane):
    """Direção perpendicular ao plano do desenho (lateral, frente ou cima)."""
    return {'side': (0.0, 0.0, 1.0), 'front': (1.0, 0.0, 0.0), 'top': (0.0, 1.0, 0.0)}[plane]


def add3(a, b, s=1.0):
    return (a[0] + b[0] * s, a[1] + b[1] * s, a[2] + b[2] * s)


def mid3(a, b):
    return ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2)


def norm3(v):
    n = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2) or 1.0
    return (v[0] / n, v[1] / n, v[2] / n)


# ------------------------------------------------------------------ equipamentos

def static_prims(prop, plane, cx, cy):
    """Equipamento parado -> lista de primitivas 3D."""
    t = prop['type']
    ground_y = -GROUND
    od = out_dir(plane)
    prims = []

    def box2d(pts2d, d0, d1, color, op=1.0):
        face = [add3(to_3d_point(p, plane, cx, cy), od, d0) for p in pts2d]
        prims.append(dict(k='box', face=face, ext=[od[0] * (d1 - d0), od[1] * (d1 - d0), od[2] * (d1 - d0)],
                          c=color, op=op))

    def cyl(a2d, b2d, r, color, da=0.0, db=None):
        db = da if db is None else db
        prims.append(dict(k='cyl', a=add3(to_3d_point(a2d, plane, cx, cy), od, da),
                          b=add3(to_3d_point(b2d, plane, cx, cy), od, db), r=r, c=color))

    def rect_pts(x, y, w, h):
        return [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]

    if plane == 'top':
        # banco do crucifixo: deitado ao longo do corpo
        if t == 'rect':
            x0, x1 = prop['x'] - cx, prop['x'] + prop['w'] - cx
            top = TOP_BASE - 7
            face = [(x0, top, -10), (x1, top, -10), (x1, top - 5, -10), (x0, top - 5, -10)]
            prims.append(dict(k='box', face=face, ext=[0, 0, 20], c='pad', op=1.0))
            for x in (x0 + 4, x1 - 6):
                prims.append(dict(k='cyl', a=(x, top - 5, 0), b=(x, ground_y, 0), r=1.2, c='eqDark'))
        return prims

    W = 12.0  # meia largura padrão dos aparelhos
    if t == 'bench':
        x, y, w, h = prop['x'], prop['y'], prop['w'], prop.get('h', 5)
        box2d(rect_pts(x, y, w, h), -W, W, 'pad')
        for lx in (x + 4, x + w - 4):
            for z in (-W + 3, W - 3):
                cyl((lx, y + h), (lx, GROUND), 1.1, 'eqDark', z, z)
    elif t == 'box':
        box2d(rect_pts(prop['x'], prop['y'], prop['w'], prop['h']), -16, 16, 'wood')
    elif t == 'rect':
        op = prop.get('op', 1.0)
        if plane == 'front' and op < 1:
            box2d(rect_pts(prop['x'], prop['y'], prop['w'], prop['h']), -16, -11, 'pad', 1.0)
        elif plane == 'front':
            box2d(rect_pts(prop['x'], prop['y'], prop['w'], prop['h']), -12, 12, 'pad')
        else:
            box2d(rect_pts(prop['x'], prop['y'], prop['w'], prop['h']), -W, W, 'pad', op)
    elif t == 'poly':
        box2d(prop['pts'], -W, W, 'pad')
    elif t == 'line':
        cyl((prop['x1'], prop['y1']), (prop['x2'], prop['y2']), prop.get('w', 2) / 2, 'eqDark')
    elif t == 'rail':
        for z in (-26, 26):
            cyl((prop['x'], prop['y1']), (prop['x'], prop['y2']), 0.9, 'eq', z, z)
    elif t == 'tower':
        x = prop['x']
        box2d(rect_pts(x, -40, 6, GROUND + 40), -4, 4, 'eqDark')
    elif t == 'pulley':
        prims.append(dict(k='disc', c=to_3d_point((prop['x'], prop['y']), plane, cx, cy), n=od, r=3.0, col='eq'))
    elif t == 'bars':
        x1, x2, y = prop['x1'], prop['x2'], prop['y']
        for z in (-15, 15):
            cyl((x1, y), (x2, y), 1.5, 'eq', z, z)
            for px in (x1 + 4, x2 - 4):
                cyl((px, y), (px, GROUND), 1.1, 'eqDark', z, z)
    elif t == 'pullbar':
        x1, x2, y = prop['x1'], prop['x2'], prop['y']
        if plane == 'side':
            xm = (x1 + x2) / 2
            cyl((xm, y), (xm, y), 1.3, 'eq', -32, 32)
            for z in (-32, 32):
                cyl((xm, y - 40), (xm, GROUND), 1.4, 'eqDark', z, z)
        else:
            cyl((x1, y), (x2, y), 1.3, 'eq')
            for px in (x1, x2):
                cyl((px, y - 40), (px, GROUND), 1.4, 'eqDark')
    elif t == 'mat':
        box2d(rect_pts(prop['x'], GROUND - 1.6, prop['x2'] - prop['x'], 1.6), -14, 14, 'mat')
    elif t == 'wall':
        box2d(rect_pts(prop['x'] - 6, -40, 6, GROUND + 40), -40, 40, 'wall')
    elif t == 'treadmill':
        x1, x2 = prop['x1'], prop['x2']
        box2d(rect_pts(x1, GROUND - 4.5, x2 - x1, 4.5), -13, 13, 'belt')
        for z in (-13, 13):
            cyl((x2 - 3, GROUND - 4), (x2 + 6, 62), 1.2, 'eqDark', z, z)
        box2d(rect_pts(x2 + 1, 56, 12, 6), -13, 13, 'pad')
    elif t == 'circle':
        prims.append(dict(k='disc', c=to_3d_point((prop['x'], prop['y']), plane, cx, cy), n=od, r=prop['r'],
                          col='pad'))
    elif t == 'bike':
        crank = (prop['x'], prop['y'])
        seat = (prop['sx'], prop['sy'])
        bar = (prop['hx'], prop['hy'])
        cyl((crank[0] - 34, GROUND - 1), (crank[0] + 30, GROUND - 1), 1.4, 'eqDark')
        cyl(crank, (crank[0] - 20, GROUND - 1), 1.3, 'eqDark')
        cyl(crank, seat, 1.3, 'eqDark')
        cyl(crank, (bar[0] - 2, bar[1] + 6), 1.3, 'eqDark')
        cyl((crank[0] + 18, GROUND - 1), (bar[0] - 2, bar[1] + 6), 1.3, 'eqDark')
        cyl((bar[0] - 2, bar[1] + 6), bar, 1.2, 'eqDark')
        cyl(bar, bar, 1.0, 'eqDark', -12, 12)
        box2d(rect_pts(seat[0] - 7, seat[1] - 1.7, 14, 3.4), -6, 6, 'pad')
        prims.append(dict(k='disc', c=to_3d_point(crank, plane, cx, cy), n=od, r=5.0, col='eq'))
    return prims


def tracked_specs(prop, plane, symmetric):
    """Equipamento que se move -> (tipo 3D, parâmetros, lista de funções que dão pontos 3D).

    Cada função recebe (J2d, F3d) e devolve um ponto 3D.
    """
    t = prop['type']
    fns = prop.get('track', [])
    od = out_dir(plane)

    def lift(fn, depth=0.0):
        def g(J, F, cx, cy):
            return to_3d_point(fn(J), plane, cx, cy, depth)
        return g

    def joint3(name):
        return lambda J, F, cx, cy: F.pts[name]

    specs = []
    if t == 'plate':
        specs.append(('barbell', {}, [lift(fns[0])]))
    elif t in ('db_end', 'db_side'):
        def axis_for(J):
            if t == 'db_end':
                return {'side': (0.0, 0.0, 1.0), 'front': (1.0, 0.0, 0.0), 'top': (1.0, 0.0, 0.0)}[plane]
            if prop.get('along') and len(fns) > 1:
                hand, elb = fns[0](J), fns[1](J)
                v = (hand[0] - elb[0], hand[1] - elb[1])
                n = math.hypot(*v) or 1.0
                p = cw((v[0] / n, v[1] / n))
                return in_plane_dir(p, plane)
            return in_plane_dir(d(prop.get('angle', 0.0)), plane)

        src = fns[0]
        jn = getattr(src, 'joint', None)
        hand_name = jn if jn in ('handN', 'handF') else None
        if plane == 'side' and t == 'db_end' and hand_name:
            # halter preso à mão: usa a posição 3D da mão (com o lado certo)
            names = [hand_name] + (['handF'] if symmetric and hand_name == 'handN' else [])
            for nm in names:
                specs.append(('dumbbell', {}, [joint3(nm),
                                               (lambda nm_: lambda J, F, cx, cy: add3(F.pts[nm_], axis_for(J), 5.0))(nm)]))
        else:
            base = lift(src)
            specs.append(('dumbbell', {}, [base,
                                           lambda J, F, cx, cy, b=base: add3(b(J, F, cx, cy), axis_for(J), 5.0)]))
    elif t == 'kb':
        specs.append(('kettlebell', {}, [lambda J, F, cx, cy: mid3(F.pts['handN'], F.pts['handF']),
                                         lambda J, F, cx, cy: mid3(F.pts['elbN'], F.pts['elbF'])]))
    elif t == 'pad':
        r = prop.get('r', 4)
        if plane == 'side':
            specs.append(('padcyl', {'r': r}, [lift(fns[0], -10.0), lift(fns[0], 10.0)]))
        else:
            specs.append(('padcyl', {'r': r}, [lift(fns[0], -4.0), lift(fns[0], 6.0)]))
    elif t == 'lever':
        piv = (prop['x'], prop['y'])
        specs.append(('lever', {}, [lambda J, F, cx, cy: to_3d_point(piv, plane, cx, cy, 12.0), lift(fns[0], 12.0)]))
    elif t == 'sled':
        a = d(prop['angle'] + 90)
        half = prop['len'] / 2

        def corner(sa, sz):
            return lambda J, F, cx, cy: to_3d_point((fns[0](J)[0] + a[0] * half * sa, fns[0](J)[1] + a[1] * half * sa),
                                                    plane, cx, cy, 14.0 * sz)
        specs.append(('quad', {}, [corner(-1, -1), corner(1, -1), corner(1, 1), corner(-1, 1)]))
    elif t == 'cable':
        start = (prop['x'], prop['y'])
        src = fns[0]
        is_hand = getattr(src, 'joint', None) == 'handN'
        if plane == 'side' and is_hand and symmetric:
            end = lambda J, F, cx, cy: mid3(F.pts['handN'], F.pts['handF'])
            specs.append(('cable', {}, [lambda J, F, cx, cy: to_3d_point(start, plane, cx, cy), end]))
            specs.append(('grip', {}, [joint3('handN'), joint3('handF')]))
        elif plane == 'side' and is_hand:
            specs.append(('cable', {}, [lambda J, F, cx, cy: to_3d_point(start, plane, cx, cy, SH_Z),
                                        joint3('handN')]))
        elif plane == 'side':
            specs.append(('cable', {}, [lambda J, F, cx, cy: to_3d_point(start, plane, cx, cy, HIP_Z),
                                        joint3('ankN')]))
        else:
            specs.append(('cable', {}, [lambda J, F, cx, cy: to_3d_point(start, plane, cx, cy), lift(src)]))
    elif t == 'cablev':
        top_y = prop['y']
        specs.append(('cable', {}, [lambda J, F, cx, cy: to_3d_point((fns[0](J)[0], top_y), plane, cx, cy),
                                    lift(fns[0])]))
    elif t == 'seg':
        specs.append(('grip', {'r': prop.get('w', 2) / 2}, [lift(fns[0]), lift(fns[1])]))
    elif t == 'band':
        specs.append(('band', {}, [joint3('kneeN'), joint3('kneeF')]))
    elif t == 'rope':
        specs.append(('rope', {}, [joint3('handN'), joint3('handF'), lift(fns[2], 8.0)]))
    return specs


def head_frame(F):
    return F.head_up, F.head_face
