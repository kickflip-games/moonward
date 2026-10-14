#!/usr/bin/env python3
"""Author the 30 reference rooms as ordinary, editable Godot scenes.

Coordinates are pixels, with y=0 at the entrance floor and negative y upward.
The main route is recorded independently as markers for traversal checks.
Run from any directory; no third-party dependencies are needed.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "World/Tower"
WIDTH = 1280


def room(number, name, route, *, masses=(), recovery=(), traps=(), springs=(), wind=(), hint="Keep climbing"):
    return dict(id=number, name=name, route=route, masses=masses, recovery=recovery,
                traps=traps, springs=springs, wind=wind, hint=hint)


def trap(kind, x, y, w=64, h=32, dx=0, dy=0, phase=0, period=4.8):
    return dict(kind=kind, x=x, y=y, w=w, h=h, dx=dx, dy=dy, phase=phase, period=period)


# (x, floor y, optional platform type, optional width). The varied paths are
# authored from the boards, rather than a random room or repeated stair pattern.
ROOMS = [
    room(1, "Switchback Ascent", [(128,0),(272,-96),(416,-224),(288,-352),(448,-448),(608,-544),(800,-448),(976,-480),(1152,-576)],
         masses=[(544,-512,128,544)], recovery=[(800,-224,160,32),(1056,-320,96,160)],
         traps=[trap("spikes",960,20,192,24)], springs=[(256,0,1900)], hint="Climb around the buttress · spring shortcut"),
    room(2, "Double Chimney", [(128,0),(224,-128, "stone",96),(352,-256,"stone",96),(224,-384,"stone",96),(352,-512,"stone",96),(544,-512),(672,-352),(832,-352),(944,-448,"stone",96),(1056,-544,"stone",96),(1152,-640)],
         masses=[(416,-480,64,512),(864,-320,48,352)], recovery=[(608,-192,192,32)],
         traps=[trap("spikes",640,20,192,24)], hint="Two wall-jump shafts · recover on the middle shelf"),
    room(3, "The Crossing", [(128,0),(272,-128),(448,-128,"moving_x"),(640,-224,"moving_x"),(832,-320,"moving_x"),(1008,-416),(1152,-544)],
         recovery=[(448,-64,160,24)], traps=[trap("spikes",656,20,624,24)],
         springs=[(256,0,1950)], hint="Ride the crossing · spring to the fragile upper route"),
    room(4, "Spiral Exterior", [(128,0),(320,-128),(448,-224),(320,-352),(496,-480),(640,-576),(816,-480),(1008,-480),(1152,-608)],
         masses=[(592,-512,64,544)], recovery=[(864,-224,160,32)],
         traps=[trap("spikes",1024,20,144,24)], hint="Alternate sides of the tower spine"),
    room(5, "Broken Bridge", [(128,0),(304,-64,"fragile"),(480,-96),(656,-128,"fragile"),(832,-160),(1008,-256,"fragile"),(1152,-384)],
         recovery=[(256,96,144,24),(448,96,144,24),(640,64,144,24),(832,32,144,24),(1024,-64,144,24)],
         springs=[(1088,-256,1500)], hint="Keep moving on cracked planks · lower recovery lane"),
    room(6, "S-Curve Gauntlet", [(128,0),(304,-128),(512,-224),(304,-352),(512,-448),(720,-544),(928,-448),(1152,-576)],
         masses=[(576,-448,64,160),(192,-96,48,128)], recovery=[(640,-256,160,24)],
         traps=[trap("spikes",400,20,96,24),trap("spikes",240,-164,48,24)], hint="Read the alternating ledges · pause at the crossover"),
    room(7, "Counterweight Lift", [(128,0),(304,-96),(496,-192,"moving_y"),(688,-288),(496,-416,"moving_y"),(688,-512),(896,-512),(1152,-640)],
         recovery=[(832,-256,192,32),(256,-384,160,32)],
         springs=[(256,-384,1400)], hint="Ride the counterweights · step off onto safe shelves"),
    room(8, "Collapsing Stair", [(128,0),(288,-96,"fragile"),(448,-192),(608,-288,"fragile"),(768,-384,"fragile"),(960,-480,"fragile"),(1152,-576)],
         recovery=[(224,96,192,24),(448,96,192,24),(672,64,192,24),(896,0,192,24),(1088,-128,128,24)],
         hint="Sprint up the crumbling stair · climb back from below"),
    room(9, "Crank Yard", [(128,0),(304,-128,"moving_x"),(512,-224,"moving_x"),(720,-320,"moving_x"),(912,-416,"moving_x"),(1152,-544)],
         traps=[trap("spikes",688,20,672,24)], springs=[(256,0,1800),(720,-320,1500)],
         recovery=[(1056,-256,128,32)], hint="Chain moving transfers · spring shortcut"),
    room(10, "Outer Face Traverse", [(128,0),(320,-96),(496,-64),(688,-160),(864,-256),(1008,-384),(1152,-512)],
         recovery=[(288,96,144,32),(496,96,144,32),(704,64,144,32),(912,-64,144,32)],
         masses=[(192,-64,48,96)], hint="Follow the outer scaffolds · a lower line rejoins"),
    room(11, "Hanging Garden", [(128,0),(256,-128),(448,-224,"moving_y"),(320,-352),(512,-448),(704,-544),(896,-448),(1152,-576)],
         masses=[(608,-448,64,224)], recovery=[(800,-256,192,32)],
         traps=[trap("spikes",912,20,144,24)], hint="Hanging platforms · choose the interior shortcut"),
    room(12, "Split Wall", [(128,0),(256,-128),(384,-256),(256,-384),(448,-512),(640,-512),(832,-512),(1024,-512),(1152,-640)],
         masses=[(512,-480,64,512),(864,-384,64,320)], recovery=[(576,-288,224,32),(976,-256,160,32)],
         traps=[trap("spikes",992,20,96,24)], hint="Safer left climb · faster right shaft"),
    room(13, "Broken Aqueduct", [(128,0),(304,-64,"fragile"),(480,-96),(656,-192,"fragile"),(832,-256),(1008,-352,"fragile"),(1152,-480)],
         recovery=[(256,96,144,32),(448,96,144,32),(640,64,144,32),(832,-32,144,32),(1024,-160,144,32)],
         traps=[trap("spikes",576,84,48,24),trap("spikes",864,20,48,24)], hint="Fractured aqueduct · drop through to recover"),
    room(14, "Needle Threader", [(128,0),(272,-128,"stone",112),(432,-224,"stone",112),(592,-352,"stone",112),(784,-448,"stone",112),(960,-384,"stone",112),(1152,-512)],
         masses=[(480,-160,48,192),(864,-320,48,192)], recovery=[(352,64,192,32),(992,-192,224,32)],
         traps=[trap("spikes",656,20,96,24),trap("spikes",880,-326,48,24)], hint="Thread the openings · waiting pockets below"),
    room(15, "Relay Lifts", [(128,0),(304,-128,"moving_y"),(496,-192),(672,-288,"moving_y"),(864,-384),(1008,-480,"moving_y"),(1152,-608)],
         traps=[trap("spikes",560,20,384,24)], springs=[(1008,-480,1450)],
         hint="Transfer between lifts · rest on the fixed ledges"),
    room(16, "Echo Chamber", [(128,0),(256,-128),(384,-256),(272,-384),(448,-512),(640,-608),(832,-512),(960,-384),(1104,-512),(1152,-640)],
         masses=[(544,-416,48,288),(800,-416,48,288),(544,-448,304,32)],
         recovery=[(608,-64,256,32),(944,-224,160,32)], hint="Loop around the chamber · drop into the central recovery shelf"),
    room(17, "Frost Shelf", [(128,0),(288,-128,"ice"),(464,-96,"moving_x"),(640,-224,"ice",192),(832,-352,"ice"),(1008,-416),(1152,-544)],
         traps=[trap("spikes",512,20,144,24)], recovery=[(704,-64,160,32)],
         hint="Carry momentum across the frost shelves"),
    room(18, "Crown Approach", [(128,0),(288,-128,"stone",112),(448,-224,"stone",112),(608,-352,"stone",112),(784,-448,"stone",112),(960,-544,"stone",112),(1152,-640)],
         masses=[(352,-128,64,160),(704,-256,64,288),(1056,-416,64,448)],
         traps=[trap("spikes",752,20,144,24)], hint="Climb the battlements in short bursts"),
    room(19, "Moon Gate", [(128,0),(288,-128),(464,-224),(640,-352),(800,-448),(992,-352),(1152,-480)],
         masses=[(576,-320,64,352),(864,-320,64,352)], recovery=[(960,-128,160,32)],
         traps=[trap("spikes",752,20,144,24)], hint="Circle the moon gate · checkpoint before the leap"),
    room(20, "Summit Walk", [(128,0),(304,-64,"stone",192),(512,-128,"stone",192),(720,-192,"stone",192),(928,-288,"stone",192),(1152,-384,"stone",192)],
         hint="Take a breath · the moon is waiting"),
    room(21, "Crusher Ladder", [(128,0),(272,-128),(432,-224),(624,-352),(800,-448),(976,-544),(1152,-640)],
         recovery=[(128,-256,160,32),(560,-128,160,32),(1056,-320,160,32)],
         traps=[trap("crusher",352,-416,80,48,dy=240),trap("crusher",720,-640,80,48,dy=240,phase=1.6),trap("crusher",1072,-800,80,48,dy=240,phase=3.0)],
         hint="Watch the amber tell · wait in the side alcoves"),
    room(22, "Dart Gallery", [(128,0),(288,-128),(464,-224),(640,-128),(816,-256),(992,-384),(1152,-512)],
         recovery=[(256,96,160,32),(480,96,160,32),(704,64,160,32),(928,-64,160,32)],
         traps=[trap("dart",48,-176,32,12,dx=1184,phase=0),trap("dart",1232,-304,32,12,dx=-1184,phase=2.4)],
         hint="Wall slots flash before firing · lower recovery route"),
    room(23, "Flame Pipe", [(128,0),(288,-128),(464,-192),(640,-128),(816,-256),(992,-384),(1152,-512)],
         recovery=[(384,64,128,32),(736,-32,128,32),(1088,-256,128,32)],
         traps=[trap("flame",384,-220,64,160,phase=0),trap("flame",736,-252,64,160,phase=2),trap("flame",1088,-480,64,160,phase=1)],
         hint="Flames pulse on and off · wait on stone pockets"),
    room(24, "Pendulum Court", [(128,0),(288,-128),(464,-224),(640,-128),(816,-256),(992,-384),(1152,-512)],
         traps=[trap("pendulum",384,-312,56,56,dx=90,dy=80,period=4),trap("pendulum",736,-344,56,56,dx=90,dy=80,phase=2,period=4),trap("pendulum",1072,-572,56,56,dx=72,dy=80,period=4)],
         recovery=[(576,32,192,32)], springs=[(832,-256,1600)], hint="Let the pendulums pass · choose your transfer"),
    room(25, "Twin Press", [(128,0),(288,-96),(464,-128),(640,-96),(816,-224),(992,-352),(1152,-480)],
         traps=[trap("crusher",384,-336,80,48,dy=176,phase=0),trap("crusher",736,-400,80,48,dy=176,phase=2.4),trap("crusher",1088,-596,80,48,dy=160,phase=1.2)],
         recovery=[(448,64,160,32),(832,-64,160,32)], springs=[(992,-352,1600)], hint="Alternating presses · spring to the final perch"),
    room(26, "Sawblade Chimney", [(128,0),(256,-128,"stone",112),(384,-256,"stone",112),(256,-384,"stone",112),(448,-512),(640,-512),(832,-512),(1024,-512),(1152,-640)],
         masses=[(160,-576,32,384),(480,-448,32,480)], recovery=[(672,-288,192,32)],
         traps=[trap("saw",352,-190,48,48,dx=64,period=4),trap("saw",320,-450,48,48,dx=64,phase=2,period=4)],
         hint="Wall-jump past the saw tracks · stop at safe ledges"),
    room(27, "Switchback Killbox", [(128,0),(288,-128),(496,-224),(320,-352),(528,-448),(720,-544),(928,-448),(1152,-576)],
         traps=[trap("spikes",592,20,144,24),trap("dart",48,-288,32,12,dx=720),trap("dart",1232,-496,32,12,dx=-720,phase=2.4)],
         recovery=[(960,-224,192,32)], hint="Weave between spikes and darts · recovery pocket to the side"),
    room(28, "Gale Pass", [(128,0),(304,-96,"fragile"),(480,-192),(656,-128,"fragile"),(832,-256),(1008,-352,"fragile"),(1152,-480)],
         wind=[(368,-192,144,288,3400),(736,-256,144,288,-3400),(1088,-352,96,256,3400)],
         recovery=[(256,96,160,32),(576,64,160,32),(896,-64,160,32)],
         springs=[(1088,-352,1450)], hint="Read the gusts · commit between resting shelves"),
    room(29, "Trap Weave", [(128,0),(304,-128),(480,-224),(656,-128),(832,-256),(1008,-384,"moving_x"),(1152,-512)],
         traps=[trap("flame",208,-124,48,120),trap("crusher",568,-420,64,48,dy=224,phase=1.6),trap("spikes",672,20,144,24)],
         recovery=[(416,64,160,32),(864,-64,160,32)], hint="Flame, press, transfer · one trap at a time"),
    room(30, "Ascent of Bells", [(128,0),(288,-128),(464,-224),(640,-128),(816,-256),(992,-384),(1152,-512)],
         traps=[trap("pendulum",384,-320,56,56,dx=80,dy=90,period=4.6),trap("pendulum",736,-352,56,56,dx=80,dy=90,phase=2.3,period=4.6),trap("pendulum",1088,-580,56,56,dx=64,dy=90,period=4.6)],
         recovery=[(512,64,160,32)], springs=[(992,-384,1550)], hint="The last gauntlet · one final climb toward the moon"),
]

# Individual traps first, then combinations, then battlements and the quiet end.
ORDER = list(range(1, 16)) + [21,22,23,24,25,26,27,28,29,30,16,17,18,19,20]


def v(x, y):
    return f"Vector2({x:g}, {y:g})"


def quote(value):
    return json.dumps(value, ensure_ascii=False)


class Scene:
    def __init__(self):
        self.ext = []
        self.sub = []
        self.nodes = []

    def resource(self, kind, path):
        ref = str(len(self.ext) + 1)
        self.ext.append(f'[ext_resource type="{kind}" path="res://{path}" id="{ref}"]')
        return f'ExtResource("{ref}")'

    def shape(self, w, h, circle=False):
        ref = f"Shape{len(self.sub)}"
        self.sub.append(f'[sub_resource type="{"CircleShape2D" if circle else "RectangleShape2D"}" id="{ref}"]\n' +
                        (f"radius = {w / 2:g}" if circle else f"size = {v(w,h)}"))
        return f'SubResource("{ref}")'

    def node(self, name, node_type=None, parent=None, instance=None, **props):
        fields = f'name="{name}"'
        if node_type:
            fields += f' type="{node_type}"'
        if parent is not None:
            fields += f' parent="{parent}"'
        if instance:
            fields += f' instance={instance}'
        self.nodes.append(f"[node {fields}]\n" + "\n".join(f"{key} = {value}" for key,value in props.items()))

    def save(self, path):
        text = f'[gd_scene load_steps={1+len(self.ext)+len(self.sub)} format=3]\n\n'
        path.write_text(text + "\n\n".join(self.ext+self.sub+self.nodes) + "\n")


def build_room(spec, index, checkpoint_index):
    scene = Scene()
    script = scene.resource("Script", "World/Tower/room.gd")
    block = scene.resource("Script", "World/Tower/stone_block.gd")
    trap_script = scene.resource("Script", "World/Tower/trap.gd")
    mount_script = scene.resource("Script", "World/Tower/trap_mount.gd")
    wind_script = scene.resource("Script", "World/Tower/wind.gd")
    moving = scene.resource("PackedScene", "Platforms/MovingPlatform.tscn")
    fragile = scene.resource("PackedScene", "Platforms/breakable/BreakablePlatform.tscn")
    spring = scene.resource("PackedScene", "Platforms/bouncy/bouncy_platform.tscn")
    checkpoint = scene.resource("PackedScene", "Checkpoint/Checkpoint.tscn")
    mirror = index % 2 == 1
    reflect = lambda x: WIDTH-x if mirror else x
    last_y = spec['route'][-1][1]
    # A full jump must fit above the last route ledge without touching the next
    # room's recovery floor. Two connector shelves fill the 384px transition.
    rise = -last_y + (384 if index < 29 else 128)
    scene.node(f"Room{spec['id']:02d}", "Node2D", script=script, room_id=spec['id'], room_name=quote(spec['name']), rise=rise,
               **{"metadata/reference_sheet":quote(f"rooms-{((spec['id']-1)//5)*5+1:02d}-{((spec['id']-1)//5+1)*5:02d}.png")})
    for name in ["Geometry", "Mechanisms", "Checkpoints", "Route", "Decorations"]:
        scene.node(name, "Node2D", ".")
    count = 0

    def stone(x, y, w, h, *, one_way=True, ice=False):
        nonlocal count
        count += 1
        if mirror:
            x = WIDTH-x-w
        name = f"Stone{count:02d}"
        scene.node(name,"StaticBody2D","Geometry",position=v(x,y),collision_layer=2,collision_mask=0,script=block,size=v(w,h),frost=str(ice).lower())
        scene.node("CollisionShape2D","CollisionShape2D",f"Geometry/{name}",position=v(w/2,h/2),shape=scene.shape(w,h),one_way_collision=str(one_way).lower(),one_way_collision_margin=8.0)

    # Side walls and recovery floor. The entrance floor is one-way so the
    # previous room can join it from below without a loading screen or portal.
    stone(0,-rise+32,32,rise+160,one_way=False)
    stone(1248,-rise+32,32,rise+160,one_way=False)
    stone(32,128,1216,32)
    for mass in spec['masses']:
        stone(*mass,one_way=False)
    for shelf in spec['recovery']:
        stone(*shelf)

    recovery_route = list(spec['recovery']) if spec['id'] in [5,8,10,13,22,28] else []
    if recovery_route:
        x,y,w,h = recovery_route[-1]
        x += w/2
        goal_x,goal_y = spec['route'][-1][:2]
        rung_count = max(0, int((y-goal_y-1)//128))
        for j in range(1,rung_count+1):
            rx=x+(goal_x-x)*j/(rung_count+1)
            ry=y-128*j
            stone(rx-64,ry,128,32)
            recovery_route.append((rx-64,ry,128,32))
        scene.node("RecoveryRoute","Node2D",".")
        for i,(rx,ry,rw,rh) in enumerate(recovery_route):
            scene.node(f"Step{i:02d}","Marker2D","RecoveryRoute",position=v(reflect(rx+rw/2),ry-24),**{"metadata/width":rw})
        scene.node(f"Step{len(recovery_route):02d}","Marker2D","RecoveryRoute",position=v(reflect(goal_x),goal_y-24),**{"metadata/width":224})

    surfaces = []
    for i, step in enumerate(spec['route']):
        x,y = step[:2]
        kind = step[2] if len(step)>2 else "stone"
        w = step[3] if len(step)>3 else (224 if i in [0,len(spec['route'])-1] else 144)
        x = reflect(x)
        if kind.startswith("moving"):
            # Centre is the neutral point; the small range preserves readable
            # transfers while retaining real AnimatableBody2D carrying physics.
            move = (32,0) if kind=="moving_x" else (0,40)
            node = f"Lift{i:02d}"
            scene.node(node,parent="Mechanisms",instance=moving,position=v(x,y+16),move_to=v(*move),speed=55.0,delay=0.7,show_path="false")
            surface = f"Mechanisms/{node}/ActualPlatform"
            scene.node(f"Track{i:02d}","Line2D","Decorations",points=f"PackedVector2Array({x-move[0]}, {y-80-move[1]}, {x+move[0]}, {y+16+move[1]})",width=2.0,default_color="Color(0.38, 0.35, 0.48, 0.6)")
        elif kind=="fragile":
            node = f"Fragile{i:02d}"
            scene.node(node,parent="Mechanisms",instance=fragile,position=v(x,y+10),break_delay=0.85,respawn_delay=2.0)
            surface = f"Mechanisms/{node}"
        else:
            stone(reflect(x)-w/2,y,w,32,ice=kind=="ice")
            surface = f"Geometry/Stone{count:02d}"
        surfaces.append(surface)
        scene.node(f"Step{i:02d}","Marker2D","Route",position=v(x,y-24),**{"metadata/surface":quote(surface),"metadata/width":w})
        if spec['id']==11 and i not in [0,len(spec['route'])-1] and kind not in ['moving_x','moving_y']:
            for side in [-1,1]:
                cx=x+side*w*.3
                scene.node(f"GardenChain{i}_{side+1}","Line2D","Decorations",points=f"PackedVector2Array({cx}, {y-176}, {cx}, {y})",width=2.0,default_color="Color(0.42, 0.4, 0.5, 0.65)",z_index=-2)

    if index < 29:
        goal_x = spec['route'][-1][0]
        for j in [1,2]:
            x = goal_x - (64 if j == 1 else 0)
            y = last_y - j * 128
            stone(x-80,y,160,32)
            scene.node(f"Step{len(spec['route'])+j-1:02d}","Marker2D","Route",position=v(reflect(x),y-24),**{"metadata/surface":quote(f"Geometry/Stone{count:02d}"),"metadata/width":160})

    # Longer rooms receive a second shrine on a fixed, known-safe route ledge.
    checkpoint_steps = [0]
    if spec['id'] >= 14 or spec['id'] in [2,5,7,11,12,13]:
        candidates = [i for i in range(2,len(spec['route'])-1) if len(spec['route'][i])<3 or spec['route'][i][2] in ["stone","ice"]]
        if candidates:
            checkpoint_steps.append(min(candidates,key=lambda i:abs(i-len(spec['route'])//2)))
    for i, step_index in enumerate(checkpoint_steps):
        x,y = spec['route'][step_index][:2]
        scene.node(f"Shrine{i}",parent="Checkpoints",instance=checkpoint,position=v(reflect(x),y-24),progression_index=checkpoint_index)
        checkpoint_index += 1

    for i,t in enumerate(spec['traps']):
        name = f"{t['kind'].title()}{i:02d}"
        tx,ty = reflect(t['x']), t['y']
        dx = -t['dx'] if mirror else t['dx']
        scene.node(name,"Area2D","Mechanisms",position=v(tx,ty),collision_layer=4 if t['kind'] in ['spikes','saw','pendulum'] else 0,collision_mask=1,script=trap_script,kind=quote(t['kind']),size=v(t['w'],t['h']),travel=v(dx,t['dy']),phase=t['phase'],period=t['period'])
        if t['kind']=="spikes":
            for tooth in range(max(1,int(t['w']/24))):
                left = -t['w']/2+tooth*24
                scene.node(f"Tooth{tooth}","CollisionPolygon2D",f"Mechanisms/{name}",polygon=f"PackedVector2Array({left+2}, {t['h']/2}, {left+12}, {-t['h']/2+2}, {left+22}, {t['h']/2})")
        else:
            circular = t['kind'] in ['saw','pendulum']
            scene.node("CollisionShape2D","CollisionShape2D",f"Mechanisms/{name}",shape=scene.shape(t['w']*.82 if circular else t['w'],t['h'],circle=circular))
        if t['kind'] != 'spikes':
            scene.node(f"Mount{i}","Node2D","Decorations",position=v(tx,ty),script=mount_script,trap_path=quote(f"../../Mechanisms/{name}"))

    for i,(x,y,force) in enumerate(spec['springs']):
        scene.node(f"Spring{i}",parent="Mechanisms",instance=spring,position=v(reflect(x),y-17),bounce_force=force)
    # Upper shortcuts are deliberately separate from the moving-platform route.
    if spec['id']==3:
        scene.node("Shortcut",parent="Mechanisms",instance=fragile,position=v(reflect(640),-416),break_delay=0.85)
        stone(400,-448,144,32)
    for i,(x,y,w,h,force) in enumerate(spec['wind']):
        name=f"Gust{i}"
        scene.node(name,"Area2D","Mechanisms",position=v(reflect(x),y),collision_layer=0,collision_mask=1,script=wind_script,size=v(w,h),force=-force if mirror else force,process_physics_priority=100)
        scene.node("CollisionShape2D","CollisionShape2D",f"Mechanisms/{name}",shape=scene.shape(w,h))

    scene.node("Name","Label","Decorations",position=v(48,-rise+48),text=quote(spec['name']),modulate="Color(0.58, 0.63, 0.77, 0.8)",**{"theme_override_font_sizes/font_size":20})
    scene.node("Hint","Label","Decorations",position=v(48,-rise+80),text=quote(spec['hint']),modulate="Color(0.46, 0.52, 0.65, 0.8)",**{"theme_override_font_sizes/font_size":14})
    if spec['id']==19:
        arch=scene.resource("Texture2D","Art/BlackSpire/Props/regions/arch.tres")
        scene.node("MoonGateArch","Sprite2D","Decorations",position=v(reflect(752),-160),texture=arch,scale=v(4,4),modulate="Color(0.65, 0.64, 0.8, 1)",z_index=-2)
    path=OUT / "Rooms" / f"{spec['id']:02d}_{spec['name'].lower().replace(' ','_').replace('-','_')}.tscn"
    scene.save(path)
    return dict(id=spec['id'],name=spec['name'],path="res://"+str(path.relative_to(ROOT)),rise=rise,mirror=mirror,
                route=[[reflect(p[0]),p[1]-24] for p in spec['route']],surfaces=surfaces,checkpoint_steps=checkpoint_steps),checkpoint_index


def build_tower():
    (OUT/"Rooms").mkdir(parents=True,exist_ok=True)
    records=[]
    checkpoint_index=0
    y=768
    for index,number in enumerate(ORDER):
        record,checkpoint_index=build_room(ROOMS[number-1],index,checkpoint_index)
        record['origin']=[-1504,y]
        records.append(record)
        y-=record['rise']
    manifest=dict(width=WIDTH,order=ORDER,checkpoints=checkpoint_index,rooms=records)
    (OUT/"room_manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
    scene=Scene()
    tower_script=scene.resource("Script","World/Tower/tower.gd")
    background=scene.resource("Script","Art/BlackSpire/background.gd")
    particle=scene.resource("Texture2D","Art/particle.png")
    moon=scene.resource("Texture2D","Art/moon.png")
    win=scene.resource("PackedScene","WinZone/WinZone.tscn")
    camera=scene.resource("Script","addons/phantom_camera/scripts/phantom_camera/phantom_camera_2d.gd")
    framing=scene.resource("Script","World/CameraFramingZone.gd")
    room_resources=[scene.resource("PackedScene",record['path'][6:]) for record in records]
    scene.node("ReferenceTower","Node2D",script=tower_script)
    scene.node("Background","ColorRect",".",visible="false",color="Color(0.035, 0.035, 0.065, 1)")
    scene.node("Platforms","Node2D",".")
    scene.node("Rooms","Node2D",".")
    for i,record in enumerate(records):
        scene.node(f"Room{record['id']:02d}",parent="Rooms",instance=room_resources[i],position=v(*record['origin']))
        scene.node(f"Frame{i:02d}","Node2D",".",position=v(-864,record['origin'][1]-record['rise']/2),script=framing,size=v(1408,record['rise']),zoom=0.85)
    scene.node("TowerDepth","Node2D",".",script=background,centre_x=-864.0,opening_height=abs(records[20]['origin'][1]),height_span=abs(records[-1]['origin'][1]-records[20]['origin'][1]))
    scene.node("SnowParticles","CPUParticles2D",".",texture=particle,amount=40,lifetime=3.0,emission_shape=3,emission_rect_extents=v(960,540),gravity=v(0,50),initial_velocity_min=30.0,initial_velocity_max=30.0,scale_amount_min=0.1,scale_amount_max=0.1,modulate="Color(0.4, 0.44, 0.65, 0.18)")
    summit=records[-1]
    summit_x=summit['origin'][0]+summit['route'][-1][0]
    summit_y=summit['origin'][1]+summit['route'][-1][1]
    scene.node("CameraManager","Node2D",".")
    scene.node("EndgameCamera","Node2D","CameraManager",position=v(summit_x-200,summit_y-180),script=camera,zoom=v(.85,.85),tween_on_load="false")
    # Keep the zone small enough that the last landing triggers the reward,
    # rather than the penultimate jump passing into a large old trigger.
    scene.node("WinZone",parent=".",instance=win,position=v(summit_x,summit_y-16),auto_transition_delay=0.0)
    scene.node("CollisionShape2D",parent="WinZone",shape=scene.shape(100,80))
    scene.node("Moon","Sprite2D",".",position=v(summit_x-180,summit_y-330),scale=v(.28,.28),texture=moon,modulate="Color(0.7, 0.78, 0.92, 1)",z_index=-2)
    scene.node("SummitTitle","Label",".",position=v(summit_x-430,summit_y-100),text=quote("THE MOONWARD SUMMIT"),modulate="Color(0.65, 0.7, 0.85, 1)",**{"theme_override_font_sizes/font_size":24})
    scene.node("GameTitle","Label",".",position=v(-1456,480),text=quote("MOONWARD"),modulate="Color(0.65, 0.7, 0.85, 1)",**{"theme_override_font_sizes/font_size":28})
    scene.node("Instructions","Label",".",position=v(-1456,516),text=quote("Move: A / D or arrows    Jump: Space    Wall-jump to climb"),modulate="Color(0.58, 0.63, 0.77, 1)",**{"theme_override_font_sizes/font_size":14})
    scene.save(OUT/"ReferenceTower.tscn")
    print(f"Built {len(records)} rooms, {checkpoint_index} checkpoints; tower rise {-y+768}px")


if __name__=="__main__":
    build_tower()
