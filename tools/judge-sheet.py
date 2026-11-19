"""Builds the one image a make.fun judge is shown for an entry, to review our own screenshots the
way the judge sees them: the cover scaled to fit 768x480 on top, the other screenshots in a row
beneath it, each scaled to fit 382x238 (3 screenshots) or 253x158 (4).

    python tools/judge-sheet.py <screenshots dir or list of images> <out.png>
"""

import sys
from pathlib import Path

from PIL import Image


def fit(image: Image.Image, width: int, height: int) -> Image.Image:
    scale = min(width / image.width, height / image.height, 1.0)
    return image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.LANCZOS)


def build_sheet(paths: list[Path]) -> Image.Image:
    images = [Image.open(path).convert("RGB") for path in paths]
    cover = fit(images[0], 768, 480)
    rest_box = (382, 238) if len(images) == 3 else (253, 158)
    rest = [fit(image, *rest_box) for image in images[1:]]
    gap = 4
    row_width = sum(image.width for image in rest) + gap * (len(rest) - 1)
    row_height = max(image.height for image in rest)
    sheet = Image.new("RGB", (max(cover.width, row_width), cover.height + gap + row_height), (0, 0, 0))
    sheet.paste(cover, ((sheet.width - cover.width) // 2, 0))
    x = (sheet.width - row_width) // 2
    for image in rest:
        sheet.paste(image, (x, cover.height + gap))
        x += image.width + gap
    return sheet


def main() -> None:
    *sources, out = sys.argv[1:]
    paths: list[Path] = []
    for source in sources:
        path = Path(source)
        if path.is_dir():
            paths += sorted(p for p in path.iterdir() if p.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp"))
        else:
            paths.append(path)
    if not 3 <= len(paths) <= 4:
        raise SystemExit(f"need 3 or 4 screenshots, got {len(paths)}")
    build_sheet(paths).save(out)
    print(f"wrote {out} from {[p.name for p in paths]}")


if __name__ == "__main__":
    main()
