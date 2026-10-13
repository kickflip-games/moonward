#!/usr/bin/env python3
"""Deterministic crop/patch atlas builder. Requires Pillow, no generated brickwork."""
import argparse
import hashlib
import json
import math
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
SOURCE = ROOT / "Art/StoneSheet/stone_sheet.png"
TILE = 72
PAD = TILE // 2
COLS = 8
EXPECTED = "582f7d7c201dc8d1164e114c71f3a90ab266ec9eae0e54f6df1684474edb0b8a"
# Clockwise neighbours: N NE E SE S SW W NW.
SIDES = [0, 2, 4, 6]
CORNERS = [(1, 0, 2), (3, 2, 4), (5, 4, 6), (7, 6, 0)]
BASE_RECTS = [(1136, 122, 72, 72), (201, 286, 72, 72), (286, 286, 72, 72)]
SLOPES = {
    "up_45": (72, 0), "down_45": (0, 72),
    "up_gentle_low": (72, 36), "up_gentle_high": (36, 0),
    "down_gentle_high": (0, 36), "down_gentle_low": (36, 72),
    "ceiling_up_45": (72, 0), "ceiling_down_45": (0, 72),
}
def crop(src, rect):
    x, y, w, h = rect
    return src.crop((x, y, x+w, y+h))

def mix(a, b, weight):
    return tuple(round(a[i] * (1-weight) + b[i] * weight) for i in range(4))

def patch(dst, donor, point, feather=3):
    """Copy original pixels with a narrow seam; retain donor colour/detail."""
    x0, y0 = point
    p, q = dst.load(), donor.load()
    for y in range(donor.height):
        for x in range(donor.width):
            edge = min(x+1, y+1, donor.width-x, donor.height-y)
            p[x+x0,y+y0] = mix(p[x+x0,y+y0], q[x,y], min(1, edge/feather))

def periodic(im, axes="xy", band=4):
    """Only boundary bands change; interiors remain original raster masonry."""
    im = im.copy()
    p = im.load()
    if "x" in axes:
        for y in range(im.height):
            for k in range(band):
                value = mix(p[k,y],p[im.width-1-k,y],.5)
                strength = (band-k)/band
                p[k,y] = mix(p[k,y],value,strength)
                p[im.width-1-k,y] = mix(p[im.width-1-k,y],value,strength)
    if "y" in axes:
        for x in range(im.width):
            for k in range(band):
                value = mix(p[x,k],p[x,im.height-1-k],.5)
                strength = (band-k)/band
                p[x,k] = mix(p[x,k],value,strength)
                p[x,im.height-1-k] = mix(p[x,im.height-1-k],value,strength)
    return im

def interiors(src):
    a = crop(src, BASE_RECTS[0]).convert("RGBA")
    # Snow is confined to this corner. The donor is unmarked source masonry.
    patch(a, crop(src,(1140,140,24,32)), (48,0))
    # The first stone row carried an exposed-edge highlight. Use an interior row.
    a.paste(a.crop((0,18,72,34)),(0,0))
    # Remove the former block's bottom rim with an original interior stone row.
    a.paste(a.crop((0,47,72,51)),(0,68))
    a = periodic(a)
    a.putalpha(255)
    results = [a]
    for rect, point, donor_rect in [
        (BASE_RECTS[1],(0,24),(1136,146,34,48)),
        (BASE_RECTS[2],(44,32),(1180,146,28,40)),
    ]:
        b=crop(src,rect).convert("RGBA")
        patch(b,crop(src,donor_rect),point)
        # Every variant has the same boundary pixels, independent of random choice.
        bp, ap=b.load(),a.load()
        for y in range(TILE):
            for x in range(TILE):
                distance=min(x,y,TILE-1-x,TILE-1-y)
                if distance < 8:
                    bp[x,y]=mix(bp[x,y],ap[x,y], min(1,max(0,(8-distance)/4)))
        b.putalpha(255)
        results.append(b)
    return results

def normalize(mask):
    for corner,a,b in CORNERS:
        if not (mask & (1<<a) and mask & (1<<b)):
            mask &= ~(1<<corner)
    return mask

def strips(src,style):
    if style=="moss":
        top=crop(src,(201,20,72,46))
        # Preserve grass and the first stone ridge, leave deeper masonry to fill.
        p=top.load()
        for y in range(top.height):
            for x in range(top.width):
                r,g,b,a=p[x,y]
                if y>26 and not (g>r*1.18 and g>b*.9):
                    p[x,y]=(r,g,b,0)
        left=crop(src,(29,202,10,72))
        right=crop(src,(435,202,8,72))
        bottom=crop(src,(201,350,72,8))
    else:
        top=crop(src,(964,16,72,58))
        p=top.load()
        for y in range(top.height):
            for x in range(top.width):
                r,g,b,a=p[x,y]
                if y>25 and not (b>110 and g>100 and b>r*1.1):
                    p[x,y]=(r,g,b,0)
        # Use bare masonry boundaries, never a vertical snow stripe.
        left=crop(src,(1136,144,4,72))
        right=crop(src,(1204,144,4,72))
        bottom=crop(src,(1136,185,72,5))
    return dict(top=periodic(top,"x"),left=periodic(left,"y"),
                right=periodic(right,"y"),bottom=periodic(bottom,"x"))

def terrain_tile(fill,edge,mask):
    canvas=Image.new("RGBA",(TILE,TILE*2))
    canvas.paste(fill,(0,PAD))
    # A boundary is drawn only where its side is exposed.
    if not mask&1: canvas.alpha_composite(edge["top"],(0,PAD-24))
    if not mask&4: canvas.alpha_composite(edge["right"],(TILE-edge["right"].width,PAD))
    if not mask&16: canvas.alpha_composite(edge["bottom"],(0,PAD+TILE-edge["bottom"].height))
    if not mask&64: canvas.alpha_composite(edge["left"],(0,PAD))
    # A missing diagonal between connected sides needs a local concave rim.
    # Copy a small original edge fragment; do not frame the rest of the cell.
    for bit,a,b in CORNERS:
        if mask&(1<<a) and mask&(1<<b) and not mask&(1<<bit):
            frag=edge["bottom"].crop((0,0,9,min(5,edge["bottom"].height)))
            if bit==1: pos=(TILE-9,PAD)
            elif bit==3: pos=(TILE-9,PAD+TILE-5)
            elif bit==5: pos=(0,PAD+TILE-5)
            else: pos=(0,PAD)
            canvas.alpha_composite(frag,pos)
    return canvas

def slope_tile(fill,edge,name,style,src):
    left,right=SLOPES[name]
    ceiling=name.startswith("ceiling")
    pts = [(0,left),(TILE,right),(TILE,TILE),(0,TILE)] if not ceiling else [(0,0),(TILE,0),(TILE,right),(0,left)]
    # Native sprite slopes remain manual, geometry is aligned to exact endpoints.
    canvas=Image.new("RGBA",(TILE,TILE*2))
    body=Image.new("RGBA",(TILE,TILE))
    mask=Image.new("L",body.size)
    ImageDraw.Draw(mask).polygon(pts,fill=255)
    body.paste(fill,(0,0));body.putalpha(mask)
    canvas.alpha_composite(body,(0,PAD))
    if not ceiling:
        # Original diagonal slope crops, no rectangular-tile rotation or stretching.
        rect = ((539,34,72,72) if name.startswith("up") else (455,34,72,72)) if style=="moss" else ((1294,34,72,72) if name.startswith("up") else (1220,34,72,72))
        original=crop(src,rect)
        op=original.load()
        cp=canvas.load()
        for x in range(TILE):
            boundary=left+(right-left)*x/TILE
            source_y=72-x if name.startswith("up") else x
            for delta in range(-18,8):
                yy=round(boundary+delta)
                sy=max(0,min(71,round(source_y+delta)))
                if -PAD<=yy<TILE:
                    px=op[x,sy]
                    foliage = (px[1]>px[0]*1.18 and px[1]>px[2]*.9) if style=="moss" else (px[2]>110 and px[1]>100)
                    if px[3] and (delta>=0 or foliage):
                        old=cp[x,PAD+yy]
                        cp[x,PAD+yy]=mix(old,px,px[3]/255)[:3]+(255,) if old[3]==255 else px
    else:
        # No snow collision: the intact source ceiling counterpart supplies trim.
        original=crop(src,(539,202,72,72) if style=="moss" else (1294,202,72,72))
        if name=="ceiling_down_45": original=original.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        p=canvas.load()
        for x in range(TILE):
            boundary=left+(right-left)*x/TILE
            for delta in range(-5,1):
                yy=round(boundary+delta)
                if 0<=yy<TILE: p[x,PAD+yy]=original.getpixel((x,yy))
    # Collider matches the underlying polygon, foliage may overhang it.
    polygon=[]
    for x,y in pts:
        point=[x-TILE/2,y-TILE/2]
        if point not in polygon: polygon.append(point)
    return canvas,polygon

def atlas_pack(tiles,path):
    rows=math.ceil(len(tiles)/COLS)
    atlas=Image.new("RGBA",(COLS*TILE,rows*TILE*2))
    for n,(image,data) in enumerate(tiles):
        x,y=n%COLS,n//COLS*2
        atlas.alpha_composite(image,(x*TILE,y*TILE))
        data.update(atlas_coords=[x,y],size_in_atlas=[1,2],pixel_rect=[x*TILE,y*TILE,TILE,TILE*2])
    atlas.save(path,optimize=False)
    return atlas.size

def build():
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==EXPECTED, "Source changed; review inventory first"
    src=Image.open(SOURCE).convert("RGBA")
    fills=interiors(src)
    masks=sorted({normalize(n) for n in range(256)})
    assert len(masks)==47
    metadata=dict(source=str(SOURCE.relative_to(ROOT)),source_sha256=EXPECTED,
        tile_size=TILE,body_y=PAD,texture_region_size=[TILE,TILE],
        neighbor_order=["N","NE","E","SE","S","SW","W","NW"],styles=[],decorations=[])
    for style_id,style in enumerate(["moss","ice"]):
        edge=strips(src,style)
        tiles=[]
        for mask in masks:
            tiles.append((terrain_tile(fills[0],edge,mask),dict(name=f"mask_{mask:02x}",mask=mask,kind="terrain")))
        for variant in [1,2]:
            tiles.append((terrain_tile(fills[variant],edge,255),dict(name=f"interior_{variant}",mask=255,kind="interior_variant")))
        for name in SLOPES:
            tile,polygon=slope_tile(fills[0],edge,name,style,src)
            tiles.append((tile,dict(name=name,kind="slope",collision=polygon,endpoints=list(SLOPES[name]))))
        for name,mask in [("flat_transition",124),("wall_transition_left",31),("wall_transition_right",241)]:
            tiles.append((terrain_tile(fills[0],edge,mask),dict(name=name,kind="manual_transition",collision=[[-36,-36],[36,-36],[36,36],[-36,36]])))
        bare=Image.new("RGBA",(TILE,TILE*2))
        bare.paste(fills[0],(0,PAD))
        bare.alpha_composite(crop(src,(1136,137,72,4)),(0,PAD))
        tiles.append((bare,dict(name="bare_top",kind="manual_transition",collision=[[-36,-36],[36,-36],[36,36],[-36,36]])))
        size=atlas_pack(tiles,OUT/f"{style}_terrain.png")
        metadata["styles"].append(dict(name=style,source_id=style_id,terrain_set=style_id,terrain_id=0,atlas_size=list(size),tiles=[d for _,d in tiles]))
    # Non-colliding fixed-grid decorative entries, preserving source scale.
    entries=json.loads((ROOT/"Art/StoneSheet/catalog.json").read_text())["entries"]
    names=["wood_moss","wood_ice","lantern_moss","lantern_ice","moon_banner_moss","moon_banner_ice",
           "window_moss","moon_window_ice","pillar_moss","pillar_ice","shrine_moss","shrine_ice"]
    decor=[]
    for entry in entries:
        if entry["name"] in names:
            image=crop(src,entry["region"])
            decor.append((image,dict(name=entry["name"],source_rect=entry["region"])))
    # Isolated foliage masks from the artwork; stone backing is removed, not recoloured.
    for style in ["moss","ice"]:
        top=strips(src,style)["top"]
        p=top.load()
        for y in range(top.height):
            for x in range(top.width):
                r,g,b,a=p[x,y]
                keep=(g>r*1.18 and g>b*.9) if style=="moss" else (b>110 and g>100 and b>r*1.1)
                if not keep:p[x,y]=(r,g,b,0)
        decor.append((top,dict(name=style+"_surface_overhang",source_rect=None)))
    vine=crop(src,(205,49,20,58))
    vp=vine.load()
    for y in range(vine.height):
        for x in range(vine.width):
            r,g,b,a=vp[x,y]
            if not (g>r*1.18 and g>b*.9):vp[x,y]=(r,g,b,0)
    decor.append((vine,dict(name="hanging_vine",source_rect=[205,49,20,58])))
    # Chains are architectural wall art, deliberately non-colliding.
    decor.append((crop(src,(201,456,72,68)),dict(name="wall_chain",source_rect=[201,456,72,68])))
    for name,rect in [("moss_arch_left",(29,118,72,72)),("moss_arch_right",(115,118,72,72)),
                      ("ice_arch_left",(791,118,72,72)),("ice_arch_right",(877,118,72,72))]:
        decor.append((crop(src,rect),dict(name=name,source_rect=list(rect))))
    crack=crop(src,(310,309,18,22))
    cp=crack.load()
    for cy in range(crack.height):
        for cx in range(crack.width):
            r,g,b,a=cp[cx,cy]
            if max(r,g,b)>65:cp[cx,cy]=(r,g,b,0)
    decor.append((crack,dict(name="masonry_crack",source_rect=[310,309,18,22])))
    width=12*TILE
    image=Image.new("RGBA",(width,12*TILE))
    x=y=row_height=0
    for piece,data in decor:
        w=math.ceil(piece.width/TILE);h=math.ceil(piece.height/TILE)
        if x+w>12:x=0;y+=row_height;row_height=0
        px,py=x*TILE,y*TILE
        # Centre artwork in the padded multi-cell region without resizing.
        image.alpha_composite(piece,(px+(w*TILE-piece.width)//2,py+(h*TILE-piece.height)//2))
        data.update(atlas_coords=[x,y],size_in_atlas=[w,h],pixel_rect=[px,py,w*TILE,h*TILE])
        metadata["decorations"].append(data)
        x+=w;row_height=max(row_height,h)
    image=image.crop((0,0,width,(y+row_height)*TILE))
    image.save(OUT/"terrain_overlays.png")
    metadata["decoration_atlas_size"]=list(image.size)
    (OUT/"terrain_atlas.json").write_text(json.dumps(metadata,indent=2)+"\n")
    inventory=[]
    for e in entries:
        name=e["name"]
        if name.startswith(("moss_","ice_")) and name not in ("ice_surface_overhang","moss_surface_overhang"):
            kind="hazard" if "spikes" in name else "slope" if any(k in name for k in ("slope","ceiling")) else "terrain_candidate"
        elif name in names:kind="decoration"
        else:
            x,y,w,h=e["region"]
            if y<365 or y>=952:kind="terrain_candidate_requires_boundary_review"
            elif y<532:kind="architectural_trim_non_colliding"
            elif y<700:kind="wall_or_banner_fragment_review_manually"
            elif y<870:kind="architecture_decoration_non_colliding"
            elif x<190 or 780<=x<950:kind="hazard_art_no_damage_behaviour"
            elif 190<=x<365 or 950<=x<1130:kind="chains_decoration_non_colliding"
            else:kind="terrain_candidate_requires_boundary_review"
        inventory.append(dict(name=name,source_rect=e["region"],classification=kind))
    (OUT/"source_inventory.json").write_text(json.dumps(inventory,indent=2)+"\n")
    return metadata

def validate(meta):
    for style in meta["styles"]:
        im=Image.open(OUT/(style["name"]+"_terrain.png"))
        assert im.mode=="RGBA" and list(im.size)==style["atlas_size"]
        used=set()
        for tile in style["tiles"]:
            x,y,w,h=tile["pixel_rect"]
            assert x>=0 and y>=0 and x+w<=im.width and y+h<=im.height
            for cy in range(y//TILE,(y+h)//TILE):
                for cx in range(x//TILE,(x+w)//TILE):
                    assert (cx,cy) not in used
                    used.add((cx,cy))
            if tile["kind"]=="terrain":assert normalize(tile["mask"])==tile["mask"]
        interior=next(t for t in style["tiles"] if t.get("mask")==255)
        x,y,w,h=interior["pixel_rect"]
        a=im.crop((x,y+PAD,x+TILE,y+PAD+TILE))
        assert a.getextrema()[3]==(255,255)
        assert a.crop((0,0,1,TILE)).tobytes()==a.crop((TILE-1,0,TILE,TILE)).tobytes()
        assert a.crop((0,0,TILE,1)).tobytes()==a.crop((0,TILE-1,TILE,TILE)).tobytes()
    im=Image.open(OUT/"terrain_overlays.png")
    occupied=set()
    assert im.mode=="RGBA" and list(im.size)==meta["decoration_atlas_size"]
    for tile in meta["decorations"]:
        x,y,w,h=tile["pixel_rect"]
        assert x+w<=im.width and y+h<=im.height
        for cy in range(y//TILE,(y+h)//TILE):
            for cx in range(x//TILE,(x+w)//TILE):
                assert (cx,cy) not in occupied
                occupied.add((cx,cy))
    print("Atlas validation passed: 47 canonical masks/style, bounds, occupancy, opaque interiors and periodic seams")

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("--check",action="store_true")
    args=parser.parse_args()
    if args.check:
        validate(json.loads((OUT/"terrain_atlas.json").read_text()))
    else:validate(build())
