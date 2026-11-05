import re, sys
work = sys.argv[1]
d = open(work + "/shot.ppm", "rb").read()
parts, at = [], 0
while len(parts) < 4:
    e = d.index(b"\n", at)
    parts += d[at:e].split()
    at = e + 1
w = int(parts[1])
px = lambda x, y: tuple(d[at + (y * w + x) * 3 : at + (y * w + x) * 3 + 3])
log = open(work + "/strand.log").read()
errs = [l.strip() for l in log.splitlines() if "use palette" in l]
check = open(work + "/check.log").read().strip().splitlines()[-1]
rgb = px(20, 20)
print("strand check:", check)
print("at runtime:", errs[0] if errs else "no palette error")
print("square:", rgb, "(the file's text colour is (205, 214, 244))")
if px(2, 2) != (0, 0, 0):
    print("the panel did not draw:", px(2, 2)); sys.exit(2)
if rgb == (205, 214, 244) and not errs:
    print("FIXED: the file works as a palette"); sys.exit(0)
print("GAP PRESENT: the file cannot be used as a palette"); sys.exit(1)
