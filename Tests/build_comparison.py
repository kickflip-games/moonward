"""Package rendered frames using an installed ffmpeg; no Python dependencies."""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1] / "artifacts" / "gameplay_polish"
FONT = Path("/System/Library/Fonts/Supplemental/Arial.ttf")


def run(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *map(str, args)], check=True)


def main():
    filters_available = subprocess.check_output(["ffmpeg", "-hide_banner", "-filters"], text=True, stderr=subprocess.DEVNULL)
    labels = ["01_jump", "02_alternating_walls", "03_narrow_shaft", "04_moving_platform",
              "05_spring", "06_spikes_retry", "07_turret"]
    for label in labels:
        filters = "[0:v][1:v]hstack=inputs=2,pad=iw:ih+36:0:36:color=0x171c29"
        if FONT.exists() and "drawtext" in filters_available:
            filters += (f",drawtext=fontfile={FONT}:text='ORIGINAL':x=24:y=6:fontsize=22:fontcolor=white"
                        f",drawtext=fontfile={FONT}:text='POLISHED':x=w/2+24:y=6:fontsize=22:fontcolor=white")
        run("-framerate", "10", "-pattern_type", "glob", "-i", ROOT / "before" / f"{label}_*.png",
            "-framerate", "10", "-pattern_type", "glob", "-i", ROOT / "after" / f"{label}_*.png",
            "-filter_complex", filters, "-c:v", "libx264", "-crf", "20", "-pix_fmt", "yuv420p",
            "-movflags", "+faststart", ROOT / f"{label}_comparison.mp4")
    for label in ["08_tower_start", "09_tower_moving_shaft", "10_tower_moving_hazards", "11_tower_turrets"]:
        run("-i", ROOT / "before" / f"{label}.png", "-i", ROOT / "after" / f"{label}.png",
            "-filter_complex", "hstack=inputs=2", "-frames:v", "1", ROOT / f"{label}_comparison.png")
    summary = {variant: json.loads((ROOT / variant / "benchmark.json").read_text())
               for variant in ["before", "after"]}
    (ROOT / "metrics.json").write_text(json.dumps(summary, indent=2) + "\n")


if __name__ == "__main__":
    main()
