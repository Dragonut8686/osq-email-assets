#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Этап 5 пайплайна: видео -> сжатый mp4 + email-GIF. Полностью без интерактива
(замена ручных батников OSQ video compressor.bat и video2gif_email-new.bat).

Использование:
  python scripts/video2gif.py <video.mp4> [ещё видео...] [опции]

Опции (значения по умолчанию = настройки из проверенных батников):
  --width 500        ширина GIF
  --fps 12           частота кадров GIF
  --colors 128       палитра GIF
  --dither bayer:bayer_scale=3   тип дизеринга (floyd_steinberg | none)
  --crop-21x9        обрезать в 21:9 (по умолчанию НЕ обрезаем)
  --no-compress      пропустить шаг сжатия mp4
  --out <dir>        куда класть результаты (по умолчанию рядом с исходником)

Результаты: <имя>_compressed.mp4 и <имя>.gif
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

FFMPEG = shutil.which("ffmpeg") or "ffmpeg"


def run_ffmpeg(args_list, what):
    res = subprocess.run([FFMPEG, "-y", *args_list], capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[error] ffmpeg ({what}):\n{res.stderr[-1500:]}", file=sys.stderr)
        sys.exit(1)


def process(video, args):
    src = Path(video)
    if not src.exists():
        print(f"[error] Нет файла: {src}", file=sys.stderr)
        sys.exit(1)
    out_dir = Path(args.out) if args.out else src.parent
    out_dir.mkdir(parents=True, exist_ok=True)

    # --- 1. Сжатый mp4 (для архива/пересылки) ---
    if not args.no_compress:
        compressed = out_dir / f"{src.stem}_compressed.mp4"
        run_ffmpeg(
            ["-i", str(src), "-c:v", "libx264", "-preset", "slow", "-crf", "23",
             "-profile:v", "high", "-level", "4.0", "-pix_fmt", "yuv420p",
             "-movflags", "+faststart", "-an", str(compressed)],
            "compress",
        )
        print(f"[ok] {compressed} ({compressed.stat().st_size // 1024} KB)")

    # --- 2. GIF через палитру ---
    filters = [f"fps={args.fps}"]
    if args.crop_21x9:
        filters.append("crop=iw:iw*9/21:0:(ih-oh)/2")
    filters.append(f"scale={args.width}:-1:flags=lanczos")
    chain = ",".join(filters)

    palette = out_dir / f"{src.stem}_palette.png"
    gif = out_dir / f"{src.stem}.gif"
    run_ffmpeg(
        ["-i", str(src), "-vf", f"{chain},palettegen=max_colors={args.colors}:stats_mode=diff", str(palette)],
        "palettegen",
    )
    run_ffmpeg(
        ["-i", str(src), "-i", str(palette), "-filter_complex",
         f"{chain}[x];[x][1:v]paletteuse=dither={args.dither}", "-loop", "0", str(gif)],
        "gif",
    )
    palette.unlink(missing_ok=True)
    size_kb = gif.stat().st_size // 1024
    print(f"[ok] {gif} ({size_kb} KB)")
    if size_kb > 1024:
        print(f"[warn] GIF больше 1 MB ({size_kb} KB) — для письма тяжеловато: "
              f"уменьшите --width/--fps/--colors или длину исходника")
    return gif


def main():
    ap = argparse.ArgumentParser(description="OSQ video -> mp4+gif (без интерактива)")
    ap.add_argument("videos", nargs="+")
    ap.add_argument("--width", type=int, default=500)
    ap.add_argument("--fps", type=int, default=12)
    ap.add_argument("--colors", type=int, default=128)
    ap.add_argument("--dither", default="bayer:bayer_scale=3")
    ap.add_argument("--crop-21x9", action="store_true")
    ap.add_argument("--no-compress", action="store_true")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    for v in args.videos:
        process(v, args)


if __name__ == "__main__":
    main()
