"""Gera assets/motions.json e prévias para conferência visual.

Uso:
  python3 tools/motion_studio.py export            # grava o JSON usado pelo app
  python3 tools/motion_studio.py preview [ids...]  # folhas de contato em tools/preview/
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
from motion_core import JOINTS, GROUND, d, add  # noqa: E402
from patterns import PATTERNS  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def build(pattern, warn):
    frames = pattern.frames(warn)
    tracked = []  # (prop_index, n)
    props_out = []
    for prop in pattern.props:
        q = {k: v for k, v in prop.items() if k != 'track'}
        if 'track' in prop:
            q['track'] = []
            for fn in prop['track']:
                q['track'].append(len(tracked))
                tracked.append(fn)
        if 'pts' in q:
            q['pts'] = [[round(x, 2), round(y, 2)] for x, y in q['pts']]
        props_out.append(q)
    data = []
    for J in frames:
        row = []
        for name in JOINTS:
            row += [round(J[name][0], 1), round(J[name][1], 1)]
        row += [round(J["_torso"], 1), round(J["_head"], 1)]
        for fn in tracked:
            pt = fn(J)
            row += [round(pt[0], 1), round(pt[1], 1)]
        data.append(row)
    return dict(name=pattern.name, view=pattern.view, fps=pattern.fps, vp=list(pattern.vp),
                phases=pattern.phases(), props=props_out, frames=data), frames, tracked


# ------------------------------------------------------------------ prévia

def draw_frame(img, row, pdef, view, ox, oy, s):
    dr = ImageDraw.Draw(img)
    pts = {name: (row[2 * i], row[2 * i + 1]) for i, name in enumerate(JOINTS)}
    base = 2 * len(JOINTS) + 2
    torso_a = row[2 * len(JOINTS)]

    def T(p):
        return (ox + p[0] * s, oy + p[1] * s)

    def tp(i):
        return (row[base + 2 * i], row[base + 2 * i + 1])

    def cap(a, b, r, col):
        A, B = T(a), T(b)
        dr.line([A, B], fill=col, width=max(1, int(2 * r * s)))
        for P in (A, B):
            dr.ellipse([P[0] - r * s, P[1] - r * s, P[0] + r * s, P[1] + r * s], fill=col)

    dr.line([T((-20, GROUND)), T((200, GROUND))], fill=(150, 150, 150), width=2)
    for pr in pdef['props']:
        t = pr['type']
        if t in ('bench',):
            x, y, w, h = pr['x'], pr['y'], pr['w'], pr.get('h', 5)
            dr.rectangle([T((x, y)), T((x + w, y + h))], fill=(90, 90, 100))
            for lx in (x + 3, x + w - 5):
                dr.rectangle([T((lx, y + h)), T((lx + 2, GROUND))], fill=(120, 120, 130))
        elif t == 'box':
            dr.rectangle([T((pr['x'], pr['y'])), T((pr['x'] + pr['w'], pr['y'] + pr['h']))], fill=(120, 100, 80))
        elif t == 'rect':
            dr.rectangle([T((pr['x'], pr['y'])), T((pr['x'] + pr['w'], pr['y'] + pr['h']))], fill=(100, 100, 115))
        elif t == 'poly':
            dr.polygon([T(p) for p in pr['pts']], fill=(100, 100, 115))
        elif t == 'line':
            dr.line([T((pr['x1'], pr['y1'])), T((pr['x2'], pr['y2']))], fill=(110, 110, 120), width=int(pr['w'] * s))
        elif t == 'rail':
            dr.line([T((pr['x'], pr['y1'])), T((pr['x'], pr['y2']))], fill=(110, 110, 120), width=int(2 * s))
        elif t == 'tower':
            dr.rectangle([T((pr['x'], 0)), T((pr['x'] + 6, GROUND))], fill=(110, 110, 125))
        elif t == 'pulley':
            x, y = T((pr['x'], pr['y']))
            dr.ellipse([x - 3 * s, y - 3 * s, x + 3 * s, y + 3 * s], outline=(60, 60, 60), width=2)
        elif t == 'bars':
            dr.line([T((pr['x1'], pr['y'])), T((pr['x2'], pr['y']))], fill=(80, 80, 90), width=int(3 * s))
            dr.line([T((pr['x2'] - 4, pr['y'])), T((pr['x2'] - 4, GROUND))], fill=(80, 80, 90), width=int(3 * s))
        elif t == 'pullbar':
            dr.line([T((pr['x1'], pr['y'])), T((pr['x2'], pr['y']))], fill=(80, 80, 90), width=int(3 * s))
        elif t == 'mat':
            dr.rectangle([T((pr['x'], GROUND - 1.5)), T((pr['x2'], GROUND))], fill=(80, 140, 160))
        elif t == 'wall':
            dr.rectangle([T((pr['x'] - 6, 0)), T((pr['x'], GROUND))], fill=(170, 170, 170))
        elif t == 'treadmill':
            dr.rectangle([T((pr['x1'], GROUND - 4)), T((pr['x2'], GROUND))], fill=(60, 60, 60))
        elif t == 'circle':
            x, y = T((pr['x'], pr['y']))
            r = pr['r'] * s
            dr.ellipse([x - r, y - r, x + r, y + r], outline=(80, 80, 90), width=3)
    # figura
    farc, nearc, skin, skinf = (150, 60, 90), (210, 80, 120), (225, 170, 130), (190, 140, 105)
    leggf, leggn = (40, 40, 60), (60, 60, 90)
    if view == 'side':
        cap(pts['shF'], pts['elbF'], 3, skinf)
        cap(pts['elbF'], pts['handF'], 2.5, skinf)
        cap(pts['hipF'], pts['kneeF'], 5, leggf)
        cap(pts['kneeF'], pts['ankF'], 3.5, leggf)
        cap(pts['ankF'], pts['toeF'], 2.4, (230, 230, 230))
    else:
        cap(pts['hipF'], pts['kneeF'], 5, leggn)
        cap(pts['kneeF'], pts['ankF'], 3.5, leggn)
        cap(pts['ankF'], pts['toeF'], 2.4, (230, 230, 230))
    cap(pts['hip'], pts['neck'], 8 if view == 'side' else 10, nearc)
    if view == 'front':
        cap(pts['shN'], pts['shF'], 4, nearc)
        cap(pts['hipN'], pts['hipF'], 6, leggn)
    cap(pts['hipN'], pts['kneeN'], 5, leggn)
    cap(pts['kneeN'], pts['ankN'], 3.5, leggn)
    cap(pts['ankN'], pts['toeN'], 2.4, (250, 250, 250))
    hx, hy = T(pts['head'])
    dr.ellipse([hx - 7 * s, hy - 7 * s, hx + 7 * s, hy + 7 * s], fill=skin)
    if view == 'side':
        fd = d(row[2 * len(JOINTS) + 1] + 90)
        ex, ey = T(add(pts['head'], fd, 4.5))
        dr.ellipse([ex - 2, ey - 2, ex + 2, ey + 2], fill=(20, 20, 20))
    else:
        cap(pts['shF'], pts['elbF'], 3, skin)
        cap(pts['elbF'], pts['handF'], 2.5, skin)
    cap(pts['shN'], pts['elbN'], 3, skin)
    cap(pts['elbN'], pts['handN'], 2.5, skin)
    for pr in pdef['props']:
        t = pr['type']
        tr = pr.get('track')
        if not tr:
            continue
        p0 = tp(tr[0])
        if t == 'plate':
            x, y = T(p0)
            dr.ellipse([x - 9 * s, y - 9 * s, x + 9 * s, y + 9 * s], outline=(30, 30, 30), width=4)
        elif t in ('db_end', 'kb', 'pad'):
            x, y = T(p0)
            r = (pr.get('r', 4)) * s
            dr.ellipse([x - r, y - r, x + r, y + r], fill=(40, 40, 40))
        elif t == 'db_side':
            x, y = T(p0)
            dr.rectangle([x - 2 * s, y - 6 * s, x + 2 * s, y + 6 * s], fill=(40, 40, 40))
        elif t == 'cable':
            dr.line([T((pr['x'], pr['y'])), T(p0)], fill=(20, 20, 20), width=1)
        elif t == 'cablev':
            dr.line([T((p0[0], pr['y'])), T(p0)], fill=(20, 20, 20), width=1)
        elif t in ('seg', 'band'):
            dr.line([T(p0), T(tp(tr[1]))], fill=(20, 20, 20), width=3)
        elif t == 'lever':
            dr.line([T((pr['x'], pr['y'])), T(p0)], fill=(70, 70, 70), width=int(2 * s))
        elif t == 'sled':
            a = pr['angle']
            ux, uy = d(a + 90)
            L2 = pr['len'] / 2
            dr.line([T((p0[0] - ux * L2, p0[1] - uy * L2)), T((p0[0] + ux * L2, p0[1] + uy * L2))], fill=(50, 50, 50),
                    width=int(3 * s))
        elif t == 'rope':
            a, b, c = p0, tp(tr[1]), tp(tr[2])
            pts_ = []
            for i in range(21):
                u = i / 20
                x = (1 - u) ** 2 * a[0] + 2 * (1 - u) * u * c[0] + u * u * b[0]
                y = (1 - u) ** 2 * a[1] + 2 * (1 - u) * u * c[1] + u * u * b[1]
                pts_.append(T((x, y)))
            dr.line(pts_, fill=(30, 30, 30), width=2)


def preview(ids):
    out_dir = os.path.join(ROOT, 'tools', 'preview')
    os.makedirs(out_dir, exist_ok=True)
    s = 2.2
    cols = 6
    for pat in PATTERNS:
        if ids and pat.id not in ids:
            continue
        warn = []
        pdef, frames, _ = build(pat, warn)
        n = len(pdef['frames'])
        idx = [int(i * n / cols) for i in range(cols)]
        vx, vy, vw, vh = pdef['vp']
        W, H = int(vw * s), int(vh * s)
        img = Image.new('RGB', (W * cols, H + 18), (245, 242, 235))
        for c, fi in enumerate(idx):
            draw_frame(img, pdef['frames'][fi], pdef, pdef['view'], c * W - vx * s, -vy * s, s)
            ImageDraw.Draw(img).rectangle([c * W, 0, c * W + W - 1, H - 1], outline=(200, 200, 200))
        lab = f"{pat.id}  {pat.name}  {pat.duration():.2f}s  " + ('AVISOS: ' + '; '.join(sorted(set(warn))) if warn else '')
        ImageDraw.Draw(img).text((4, H + 3), lab, fill=(0, 0, 0))
        img.save(os.path.join(out_dir, pat.id + '.png'))
        if warn:
            print(pat.id, sorted(set(warn)))


def sheet(ids, name):
    """Junta várias prévias numa imagem só para conferência rápida."""
    out_dir = os.path.join(ROOT, 'tools', 'preview')
    ims = [Image.open(os.path.join(out_dir, i + '.png')) for i in ids]
    W = max(im.width for im in ims)
    H = sum(im.height for im in ims)
    big = Image.new('RGB', (W, H), (255, 255, 255))
    y = 0
    for im in ims:
        big.paste(im, (0, y))
        y += im.height
    big.save(os.path.join(out_dir, name))


def export():
    out = dict(version=1, joints=JOINTS, patterns={})
    total_warn = 0
    for pat in PATTERNS:
        warn = []
        pdef, _, _ = build(pat, warn)
        if pat.id in out['patterns']:
            raise SystemExit('id duplicado: ' + pat.id)
        out['patterns'][pat.id] = pdef
        if warn:
            total_warn += 1
            print('AVISO', pat.id, sorted(set(warn)))
    path = os.path.join(ROOT, 'assets', 'motions.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    print(f'{len(out["patterns"])} padrões, {os.path.getsize(path) / 1024:.0f} KB, padrões com aviso: {total_warn}')


# ------------------------------------------------------------------ 3D

def build3d(pattern, warn):
    import motion3d as m3
    frames = pattern.frames(warn)
    plane = pattern.plane
    cx, cy = frames[0]['hip']
    symmetric = all(abs(J['handN'][0] - J['handF'][0]) < 0.01 and abs(J['handN'][1] - J['handF'][1]) < 0.01
                    for J in frames)
    prims = []
    tracked = []
    props_out = []
    for prop in pattern.props:
        if 'track' not in prop:
            prims += m3.static_prims(prop, plane, cx, cy)
            continue
        for kind, params, fns in m3.tracked_specs(prop, plane, symmetric):
            idx = []
            for fn in fns:
                idx.append(len(tracked))
                tracked.append(fn)
            q = dict(type=kind, track=idx)
            q.update(params)
            props_out.append(q)
    rows = []
    for J in frames:
        F = m3.convert(J, plane, cx, cy)
        row = []
        for name in JOINTS:
            row += [round(v, 1) for v in F.pts[name]]
        for vec in (F.torso_f, F.head_up, F.head_face):
            row += [round(v, 3) for v in vec]
        for fn in tracked:
            row += [round(v, 1) for v in fn(J, F, cx, cy)]
        rows.append(row)

    def r3(p):
        return [round(v, 2) for v in p]

    prims_out = []
    for pr in prims:
        q = dict(pr)
        for k in ('a', 'b', 'c', 'n', 'ext'):
            if k in q and isinstance(q[k], (list, tuple)):
                q[k] = r3(q[k])
        if 'face' in q:
            q['face'] = [r3(p) for p in q['face']]
        prims_out.append(q)
    yaw = 0 if plane == 'side' else 90
    return dict(name=pattern.name, plane=plane, yaw=yaw, fps=pattern.fps, phases=pattern.phases(),
                prims=prims_out, props=props_out, frames=rows)


def export3d():
    out = dict(version=2, joints=JOINTS, patterns={})
    for pat in PATTERNS:
        warn = []
        out['patterns'][pat.id] = build3d(pat, warn)
    path = os.path.join(ROOT, 'assets', 'motions.json')
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, separators=(',', ':'))
    print(f'3D: {len(out["patterns"])} padrões, {os.path.getsize(path) / 1024:.0f} KB')


def preview3d(ids, yaws=(0, 45, 90, 180)):
    """Prévia simples em 3D (cápsulas ordenadas por profundidade) em vários ângulos."""
    import motion3d as m3  # noqa: F401
    out_dir = os.path.join(ROOT, 'tools', 'preview3d')
    os.makedirs(out_dir, exist_ok=True)
    for pat in PATTERNS:
        if ids and pat.id not in ids:
            continue
        data = build3d(pat, [])
        rows = data['frames']
        n = len(rows)
        fr = [rows[0], rows[n // 3]]
        S = 2.0
        W, H = 220, 200
        img = Image.new('RGB', (W * len(yaws) * len(fr), H), (240, 242, 245))
        dr = ImageDraw.Draw(img)
        col = 0
        for f in fr:
            for yaw in yaws:
                th = math.radians(yaw)
                ph = math.radians(10)
                t = (math.sin(th) * math.cos(ph), math.sin(ph), math.cos(th) * math.cos(ph))
                r = (math.cos(th), 0.0, -math.sin(th))
                up = (t[1] * r[2] - t[2] * r[1], t[2] * r[0] - t[0] * r[2], t[0] * r[1] - t[1] * r[0])

                def proj(p):
                    sx = p[0] * r[0] + p[1] * r[1] + p[2] * r[2]
                    sy = p[0] * up[0] + p[1] * up[1] + p[2] * up[2]
                    dz = p[0] * t[0] + p[1] * t[1] + p[2] * t[2]
                    return (col * W + W / 2 + sx * S * 0.8, H * 0.55 - sy * S * 0.8 - 40), dz

                pts = {name: tuple(f[3 * i:3 * i + 3]) for i, name in enumerate(JOINTS)}
                segs = [('hip', 'neck', 9, (210, 80, 120)), ('neck', 'head', 4, (225, 170, 130)),
                        ('shN', 'elbN', 3, (225, 170, 130)), ('elbN', 'handN', 2.5, (225, 170, 130)),
                        ('shF', 'elbF', 3, (190, 140, 105)), ('elbF', 'handF', 2.5, (190, 140, 105)),
                        ('hipN', 'kneeN', 5, (70, 70, 110)), ('kneeN', 'ankN', 3.5, (70, 70, 110)),
                        ('hipF', 'kneeF', 5, (45, 45, 70)), ('kneeF', 'ankF', 3.5, (45, 45, 70)),
                        ('shN', 'shF', 3, (225, 170, 130)), ('hipN', 'hipF', 5, (70, 70, 110))]
                items = []
                for a, b, rad, c in segs:
                    (pa, da), (pb, db) = proj(pts[a]), proj(pts[b])
                    items.append(((da + db) / 2, pa, pb, rad, c))
                ground = [proj((x, -122, z))[0] for x, z in ((-80, -40), (80, -40), (80, 40), (-80, 40))]
                dr.polygon(ground, fill=(215, 220, 228))
                for _, pa, pb, rad, c in sorted(items, key=lambda x: x[0]):
                    dr.line([pa, pb], fill=c, width=int(rad * S * 0.8 * 2))
                hp, _ = proj(pts['head'])
                dr.ellipse([hp[0] - 11, hp[1] - 11, hp[0] + 11, hp[1] + 11], fill=(225, 170, 130))
                dr.text((col * W + 4, 4), f'{yaw}°', fill=(0, 0, 0))
                col += 1
        dr.text((4, H - 14), pat.id, fill=(0, 0, 0))
        img.save(os.path.join(out_dir, pat.id + '.png'))


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'export'
    if cmd in ('export', 'export3d'):
        export3d()
    elif cmd == 'export2d':
        export()
    elif cmd == 'preview':
        preview(set(sys.argv[2:]))
    elif cmd == 'preview3d':
        preview3d(set(sys.argv[2:]))
    elif cmd == 'sheet':
        sheet(sys.argv[3:], sys.argv[2])
