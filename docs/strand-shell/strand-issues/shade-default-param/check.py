import sys
work = sys.argv[1]
d = open(work + "/shot.ppm", "rb").read()
parts, at = [], 0
while len(parts) < 4:
    e = d.index(b"\n", at)
    for w in d[at:e].split():
        parts.append(w)
    at = e + 1
w, h = int(parts[1]), int(parts[2])
px = lambda x, y: tuple(d[at + (y * w + x) * 3 : at + (y * w + x) * 3 + 3])
ROWS = [
    ("group a, default parameter first (the reported case)", ["ADefault", "ADirect", "ACond", "ABase"], True),
    ("group b, direct shade mounted first", ["BDirect", "BDefault"], True),
    ("group c, default parameter never mounted", ["CDirect"], True),
    ("group d, control: no default parameter", ["DOne", "DTwo"], False),
    ("group e, control: shades written out", ["EDefault", "EDirect"], False),
    ("group f, control: one shade", ["FDefault"], False),
    ("group g, lighten and darken, not alpha", ["GDirect"], True),
    ("group h, a constant base, not a service", ["HDirect"], True),
]
if px(2, 2) != (0, 0, 0):
    print("the panel is not where it should be:", px(2, 2)); sys.exit(2)
bugs, broken = [], []
for r, (name, cells, may_fail) in enumerate(ROWS):
    print(name)
    for i, cell in enumerate(cells):
        rgb = px(8 + 12 + 32 * i, 8 + 12 + 32 * r)
        drawn = rgb != (0, 0, 0)
        print(f"  {cell:9} {'drawn' if drawn else 'BLANK'} {rgb}")
        if not drawn:
            (bugs if may_fail else broken).append(cell)
if broken:
    print("control failed, so this check cannot be trusted:", broken); sys.exit(2)
print("BUG PRESENT: " + ", ".join(bugs) if bugs else "FIXED: every square drew")
sys.exit(1 if bugs else 0)
