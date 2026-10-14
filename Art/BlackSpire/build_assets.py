#!/usr/bin/env python3
"""Crop and assemble BlackSpire originals without resizing their pixels."""
from pathlib import Path
from PIL import Image, ImageDraw
import json,math,hashlib
ROOT=Path(__file__).resolve().parent
tiles=Image.open(ROOT/"Source/Medieval_tiles_free_2.0.png").convert("RGBA")
props=Image.open(ROOT/"Source/Medieval_props_free.png").convert("RGBA")
def crop(im,r):
 x,y,w,h=r;return im.crop((x,y,x+w,y+h))
def fill(w,h):
 # The artist's supplied quiet structural fill; no generated masonry.
 out=Image.new("RGBA",(w,h))
 strip=crop(tiles,(640,400,24,16))
 for y in range(0,h,16):
  for x in range(0,w,24):out.paste(strip,(x,y))
 return out
TOP=(65,100,24,12)
BOTTOM=(41,256,24,12)
LEFT=(53,112,12,24)
RIGHT=(593,112,12,24)
CAP_TOP=(65,101,24,6)
CAP_BOTTOM=(41,260,24,6)
CAP_LEFT=(53,112,6,24)
CAP_RIGHT=(599,112,6,24)
manual=[]
images=[]
for mask in range(16):
 im=fill(24,24)
 if not mask&8:im.alpha_composite(crop(tiles,CAP_TOP),(0,0))
 if not mask&2:im.alpha_composite(crop(tiles,CAP_BOTTOM),(0,18))
 if not mask&4:im.alpha_composite(crop(tiles,CAP_LEFT),(0,0))
 if not mask&1:im.alpha_composite(crop(tiles,CAP_RIGHT),(18,0))
 images.append((im,dict(name=f"sides_{mask:02x}",mask=mask,kind="terrain",collision=[[-12,-12],[12,-12],[12,12],[-12,12]])))
# Exact 45-degree and original 1:3 roof grades. Original slope strokes are crops.
slopes=[("up_45",24,0,(688,40,24,24)),("down_45",0,24,(736,16,24,24)),
 ("up_gentle_low",24,16,(208,80,24,24)),("up_gentle_middle",16,8,(232,80,24,24)),
 ("up_gentle_high",8,0,(256,80,24,24)),
 ("down_gentle_high",0,8,(400,56,24,24)),("down_gentle_middle",8,16,(424,56,24,24)),
 ("down_gentle_low",16,24,(448,56,24,24))]
for name,a,b,r in slopes:
 im=fill(24,24);mask=Image.new("L",(24,24));ImageDraw.Draw(mask).polygon([(0,a),(24,b),(24,24),(0,24)],fill=255)
 im.alpha_composite(crop(tiles,r));im.putalpha(mask)
 pts=[]
 for p in [[-12,a-12],[12,b-12],[12,12],[-12,12]]:
  if p not in pts:pts.append(p)
 images.append((im,dict(name=name,kind="slope",collision=pts,endpoints=[a,b],source_rect=r)))
# Manual corner accents are only selected explicitly, not advertised as 47-tile coverage.
for corner in ["NW","NE","SW","SE"]:
 im=fill(24,24)
 im.alpha_composite(crop(tiles,CAP_TOP if "N" in corner else CAP_BOTTOM),(0,0 if "N" in corner else 18))
 im.alpha_composite(crop(tiles,CAP_LEFT if "W" in corner else CAP_RIGHT),(0 if "W" in corner else 18,0))
 images.append((im,dict(name="inner_"+corner,kind="manual",collision=[[-12,-12],[12,-12],[12,12],[-12,12]])))
# Thin and one-way ledges keep the artist's original cap height.
ledge=crop(tiles,TOP)
for name in ["thin_ledge","one_way_ledge"]:
 im=Image.new("RGBA",(24,24));im.alpha_composite(ledge,(0,0))
 images.append((im,dict(name=name,kind="manual",collision=[[-12,-12],[12,-12],[12,0],[-12,0]],one_way=name=="one_way_ledge")))
atlas=Image.new("RGBA",(8*24,math.ceil(len(images)/8)*24))
for i,(im,data) in enumerate(images):
 at=[i%8,i//8];atlas.alpha_composite(im,(at[0]*24,at[1]*24));data["atlas_coords"]=at
atlas.save(ROOT/"Terrain/terrain_atlas.png")
# Sparse masonry marks come from the artist's roof texture. Remove its flat
# backing, retaining every original mark pixel; these are overlays, not fills.
accent_rects=[(306,593,22,14),(370,600,36,20),(310,624,26,17)]
accents=Image.new("RGBA",(144,24))
for i,r in enumerate(accent_rects):
 im=crop(tiles,r)
 im.putdata([p if p[:3]==(53,53,95) else (0,0,0,0) for p in im.getdata()])
 accents.alpha_composite(im,(i*48+(48-im.width)//2,(24-im.height)//2))
accents.save(ROOT/"Terrain/masonry_accents.png")
# Legacy tower visual body grid is separate from the new 24px design kit.
base=Image.new("RGBA",(16*5,16))
for i in range(5):
 im=fill(16,16)
 if i:
  pts={1:[(0,16),(16,0),(16,16)],2:[(0,0),(0,16),(16,16)],3:[(0,0),(16,0),(16,16)],4:[(0,0),(16,0),(0,16)]}[i]
  m=Image.new("L",(16,16));ImageDraw.Draw(m).polygon(pts,fill=255);im.putalpha(m)
 base.alpha_composite(im,(i*16,0))
base.save(ROOT/"Terrain/quiet_geometry.png")
names={"window":(28,22,30,56),"door_closed":(67,29,51,56),"door_open":(128,29,51,56),
 "gate":(188,29,51,56),"arch":(247,29,51,56),"chest":(303,70,23,15),"chest_open":(330,65,23,20),
 "small_roof":(357,67,28,18),"vase":(392,63,18,22),"crate":(414,67,26,18),"barrel":(444,59,23,26),
 "brazier":(34,96,29,37),"brazier_tilt":(76,104,39,29),"pillar_short":(131,92,19,40),
 "pillar":(161,92,19,54),"ladder":(196,95,24,74),"ladder_cap":(230,89,22,51),
 "left_arch_trim":(310,95,20,63),"right_arch_trim":(345,96,20,62),"shield":(386,106,37,39),
 "torch":(432,113,26,31)}
palette=Image.new("RGBA",(12*24,12*24));x=y=rh=0;entries=[]
(ROOT/"Props/regions").mkdir(exist_ok=True)
for name,r in names.items():
 im=crop(props,r);w=math.ceil(im.width/24);h=math.ceil(im.height/24)
 if x+w>12:x=0;y+=rh;rh=0
 ox=x*24+(w*24-im.width)//2;oy=y*24+(h*24-im.height)//2
 palette.alpha_composite(im,(ox,oy))
 entries.append(dict(name=name,source_rect=list(r),atlas_coords=[x,y],size_in_atlas=[w,h]))
 (ROOT/f"Props/regions/{name}.tres").write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n[ext_resource type="Texture2D" path="res://Art/BlackSpire/Source/Medieval_props_free.png" id="1"]\n\n[resource]\natlas = ExtResource("1")\nregion = Rect2(%d, %d, %d, %d)\nfilter_clip = true\n'%r)
 x+=w;rh=max(rh,h)
palette=palette.crop((0,0,12*24,(y+rh)*24));palette.save(ROOT/"Props/props_atlas.png")
# Repeat chest wood at its original density, rather than stretching a single sprite.
wood=crop(props,names["crate"])
spring=Image.new("RGBA",(61,17))
for x in range(0,61,wood.width):spring.alpha_composite(wood,(x,0))
spring.save(ROOT/"Terrain/spring_deck.png")
stem=Image.new("RGBA",(33,22))
stem.alpha_composite(crop(props,(136,103,8,18)),(3,0));stem.alpha_composite(crop(props,(136,103,8,18)),(22,0))
stem.alpha_composite(crop(props,(131,124,19,8)),(7,14));stem.save(ROOT/"Terrain/spring_stem.png")
meta=dict(logical_tile_size=24,terrain_mode="match_sides",terrain_tiles=[d for im,d in images],
 masonry_accent_source_rects=accent_rects,
 props=entries,edge_regions=dict(top=TOP,bottom=BOTTOM,left=LEFT,right=RIGHT),
 source_sha256={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/"Source").glob("*.png")},
 attribution="BlackSpire Studio — Medieval pixel art asset FREE — CC BY-SA 4.0")
(ROOT/"catalog.json").write_text(json.dumps(meta,indent=2)+"\n")
print("BlackSpire atlases: 16 side configurations, 8 original-gradient slopes, manual corners/ledges, 21 props")
