"""Motor de movimento do GM Fitness (lado da autoria).

Cada exercício é descrito por poses-chave (ângulos e alvos de cinemática
inversa). Este módulo resolve as poses, interpola no tempo e gera os quadros
que o app desenha. O app só lê as posições prontas, então tudo o que é
calculado aqui é exatamente o que aparece na tela.

Convenções:
- Mundo de 160 x 130 unidades, y para baixo, chão em y = 122.
- Ângulos em graus: 0 = para cima, 90 = para a direita (frente da pessoa),
  180 = para baixo, 270 = para trás.
- Vista "side": a pessoa olha para a direita.
- Vista "front": a pessoa olha para quem está vendo; o lado "N" (perto)
  fica à direita da tela.
"""
import math

L = dict(torso=30.0, neckhead=10.5, ua=19.0, fa=20.0, th=25.5, sh=25.5, foot=10.0)
GROUND = 122.0
ANK = 118.0
SH_HALF = 11.0
HIP_HALF = 6.0
FRONT_FOOT = 5.0

JOINTS = ['hip', 'neck', 'head', 'shN', 'elbN', 'handN', 'shF', 'elbF', 'handF',
          'hipN', 'kneeN', 'ankN', 'toeN', 'hipF', 'kneeF', 'ankF', 'toeF']


def d(a):
    r = math.radians(a)
    return (math.sin(r), -math.cos(r))


def add(p, v, s=1.0):
    return (p[0] + v[0] * s, p[1] + v[1] * s)


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def ang(v):
    return math.degrees(math.atan2(v[0], -v[1])) % 360


def cw(v):
    return (-v[1], v[0])


def dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def lerp(a, b, t):
    return a + (b - a) * t


def lerpp(a, b, t):
    return (lerp(a[0], b[0], t), lerp(a[1], b[1], t))


def angdiff(a, b):
    return (b - a + 540) % 360 - 180


def ik(a, b, l1, l2, bend, warn, tag):
    """Dois segmentos da raiz a até o alvo b. bend=+1 dobra para o lado
    anti-horário da linha a->b, bend=-1 para o lado horário."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    D = math.hypot(dx, dy)
    if D < 1e-6:
        dx, dy, D = 0.0, 1e-6, 1e-6
    ux, uy = dx / D, dy / D
    if l1 < 0 or l2 < 0:
        raise ValueError('escala negativa não suportada em IK')
    maxr = l1 + l2 - 0.01
    minr = abs(l1 - l2) + 0.01
    if D > maxr + 0.8:
        warn.append(f'{tag}: alvo fora de alcance por {D - maxr:.1f}')
    Dc = min(max(D, minr), maxr)
    x = (l1 * l1 - l2 * l2 + Dc * Dc) / (2 * Dc)
    h = math.sqrt(max(l1 * l1 - x * x, 0.0))
    px, py = (uy, -ux) if bend > 0 else (-uy, ux)
    mid = (a[0] + ux * x + px * h, a[1] + uy * x + py * h)
    end = (a[0] + ux * Dc, a[1] + uy * Dc)
    return mid, end


# ---------------------------------------------------------------- especificações

def FA(upper, fore):
    """Braço por ângulos (forward kinematics)."""
    return ('fk', float(upper), float(fore))


def IA(target, bend):
    """Braço por alvo da mão (inverse kinematics)."""
    return ('ik', (float(target[0]), float(target[1])), bend)


def FL(thigh, shin, foot):
    return ('fk', float(thigh), float(shin), float(foot))


def IL(target, bend, foot):
    return ('ik', (float(target[0]), float(target[1])), bend, float(foot))


SCALE_KEYS = ['au', 'af', 'au2', 'af2', 'lt', 'ls', 'lt2', 'ls2']


def P(hip, torso, arm=None, arm2=None, leg=None, leg2=None, head=0.0, shrug=0.0, **sc):
    p = dict(hip=(float(hip[0]), float(hip[1])), torso=float(torso), head=float(head),
             shrug=float(shrug), arm=arm or FA(180, 180), arm2=arm2, leg=leg, leg2=leg2)
    for k in SCALE_KEYS:
        if k in sc:
            p[k] = float(sc[k])
        elif k.endswith('2') and k[:-1] in sc:
            p[k] = float(sc[k[:-1]])
        else:
            p[k] = 1.0
    for k in sc:
        if k not in SCALE_KEYS:
            raise KeyError(k)
    return p


def neck_of(p):
    return add(p['hip'], d(p['torso']), L['torso'])


def front_of(torso):
    return cw(d(torso))


def reflect_point(pt, origin, axis):
    vx, vy = pt[0] - origin[0], pt[1] - origin[1]
    dot = vx * axis[0] + vy * axis[1]
    px, py = axis[0] * dot, axis[1] * dot
    return (origin[0] + 2 * px - vx, origin[1] + 2 * py - vy)


def mirror_spec(spec, p, is_leg):
    ta = p['torso']
    if spec[0] == 'fk':
        if is_leg:
            return ('fk', (2 * ta - spec[1]) % 360, (2 * ta - spec[2]) % 360, (2 * ta - spec[3]) % 360)
        return ('fk', (2 * ta - spec[1]) % 360, (2 * ta - spec[2]) % 360)
    tgt = reflect_point(spec[1], p['hip'], d(ta))
    if is_leg:
        return ('ik', tgt, -spec[2], (2 * ta - spec[3]) % 360)
    return ('ik', tgt, -spec[2])


def normalize(p, view):
    """Preenche o lado F (longe) quando ele não foi informado."""
    q = dict(p)
    if q['leg'] is None:
        raise ValueError('perna N sem especificação')
    for k, kn, is_leg in (('arm2', 'arm', False), ('leg2', 'leg', True)):
        if q[k] is None:
            q[k] = mirror_spec(q[kn], q, is_leg) if view == 'front' else q[kn]
    return q


def attach_points(p, view):
    hip = p['hip']
    td = d(p['torso'])
    neck = add(hip, td, L['torso'])
    if view == 'front':
        perp = cw(td)
        shN, shF = add(neck, perp, SH_HALF), add(neck, perp, -SH_HALF)
        hipN, hipF = add(hip, perp, HIP_HALF), add(hip, perp, -HIP_HALF)
    else:
        shN = shF = neck
        hipN = hipF = hip
    if p['shrug']:
        shN, shF = add(shN, td, p['shrug']), add(shF, td, p['shrug'])
    return neck, shN, shF, hipN, hipF


def solve_arm(sh, spec, us, fs, warn, tag):
    if spec[0] == 'fk':
        el = add(sh, d(spec[1]), L['ua'] * us)
        ha = add(el, d(spec[2]), L['fa'] * fs)
        return el, ha
    return ik(sh, spec[1], L['ua'] * us, L['fa'] * fs, spec[2], warn, tag)


def solve_leg(hp, spec, ts, ss, foot_len, warn, tag):
    if spec[0] == 'fk':
        kn = add(hp, d(spec[1]), L['th'] * ts)
        an = add(kn, d(spec[2]), L['sh'] * ss)
        fa = spec[3]
    else:
        kn, an = ik(hp, spec[1], L['th'] * ts, L['sh'] * ss, spec[2], warn, tag)
        fa = spec[3]
    toe = add(an, d(fa), foot_len)
    return kn, an, toe


def solve(p, view, warn):
    p = normalize(p, view)
    neck, shN, shF, hipN, hipF = attach_points(p, view)
    hd = p['torso'] + p['head']
    head = add(neck, d(hd), L['neckhead'])
    foot_len = FRONT_FOOT if view == 'front' else L['foot']
    elbN, handN = solve_arm(shN, p['arm'], p['au'], p['af'], warn, 'braço N')
    elbF, handF = solve_arm(shF, p['arm2'], p['au2'], p['af2'], warn, 'braço F')
    kneeN, ankN, toeN = solve_leg(hipN, p['leg'], p['lt'], p['ls'], foot_len, warn, 'perna N')
    kneeF, ankF, toeF = solve_leg(hipF, p['leg2'], p['lt2'], p['ls2'], foot_len, warn, 'perna F')
    J = dict(hip=p['hip'], neck=neck, head=head, shN=shN, elbN=elbN, handN=handN,
             shF=shF, elbF=elbF, handF=handF, hipN=hipN, kneeN=kneeN, ankN=ankN, toeN=toeN,
             hipF=hipF, kneeF=kneeF, ankF=ankF, toeF=toeF)
    J['_torso'] = p['torso'] % 360
    J['_head'] = hd % 360
    return J


def limb_angles(J, limb):
    if limb == 'arm':
        return (ang(sub(J['elbN'], J['shN'])), ang(sub(J['handN'], J['elbN'])))
    if limb == 'arm2':
        return (ang(sub(J['elbF'], J['shF'])), ang(sub(J['handF'], J['elbF'])))
    if limb == 'leg':
        return (ang(sub(J['kneeN'], J['hipN'])), ang(sub(J['ankN'], J['kneeN'])), ang(sub(J['toeN'], J['ankN'])))
    return (ang(sub(J['kneeF'], J['hipF'])), ang(sub(J['ankF'], J['kneeF'])), ang(sub(J['toeF'], J['ankF'])))


def interp(p0, p1, t, view):
    n0, n1 = normalize(p0, view), normalize(p1, view)
    out = dict(hip=lerpp(n0['hip'], n1['hip'], t), torso=lerp(n0['torso'], n1['torso'], t),
               head=lerp(n0['head'], n1['head'], t), shrug=lerp(n0['shrug'], n1['shrug'], t))
    for k in SCALE_KEYS:
        out[k] = lerp(n0[k], n1[k], t)
    J0 = J1 = None
    for limb in ('arm', 'arm2', 'leg', 'leg2'):
        s0, s1 = n0[limb], n1[limb]
        is_leg = limb.startswith('leg')
        if s0[0] == s1[0] == 'fk':
            out[limb] = tuple([s0[0]] + [lerp(a, b, t) for a, b in zip(s0[1:], s1[1:])])
        elif s0[0] == s1[0] == 'ik':
            if is_leg:
                out[limb] = ('ik', lerpp(s0[1], s1[1], t), s0[2] if t < 0.5 else s1[2], lerp(s0[3], s1[3], t))
            else:
                out[limb] = ('ik', lerpp(s0[1], s1[1], t), s0[2] if t < 0.5 else s1[2])
        else:
            if J0 is None:
                J0 = solve(p0, view, [])
                J1 = solve(p1, view, [])
            a0, a1 = limb_angles(J0, limb), limb_angles(J1, limb)
            vals = [a + angdiff(a, b) * t for a, b in zip(a0, a1)]
            if is_leg:
                out[limb] = ('fk', vals[0], vals[1], vals[2])
            else:
                out[limb] = ('fk', vals[0], vals[1])
    return out


def ease(u):
    return 0.5 - 0.5 * math.cos(math.pi * u)


class Pattern:
    def __init__(self, pid, name, view, keys, seq, props=None, vp=(0, 0, 160, 130), fps=20, linear=False):
        self.id = pid
        self.name = name
        self.view = view
        self.keys = keys
        self.seq = seq
        self.props = props or []
        self.vp = vp
        self.fps = fps
        self.linear = linear

    def duration(self):
        return sum(s[2] for s in self.seq)

    def pose_at(self, time):
        t = 0.0
        for (i, j, dur, _label) in self.seq:
            if time <= t + dur + 1e-9:
                u = 0.0 if dur <= 0 else (time - t) / dur
                u = max(0.0, min(1.0, u))
                if i == j:
                    return self.keys[i]
                return interp(self.keys[i], self.keys[j], u if self.linear else ease(u), self.view)
            t += dur
        return self.keys[self.seq[-1][1]]

    def frames(self, warn):
        T = self.duration()
        n = max(2, int(round(T * self.fps)))
        out = []
        for f in range(n):
            time = T * f / n
            J = solve(self.pose_at(time), self.view, warn)
            J['_t'] = f / n
            out.append(J)
        return out

    def phases(self):
        n = max(2, int(round(self.duration() * self.fps)))
        T = self.duration()
        res = []
        t = 0.0
        for (_i, _j, dur, label) in self.seq:
            a = int(round(t / T * n))
            t += dur
            b = int(round(t / T * n))
            if res and res[-1][2] == label and res[-1][1] == a:
                res[-1][1] = b
            else:
                res.append([a, b, label])
        return res
