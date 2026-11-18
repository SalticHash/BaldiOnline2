fc = '[gd_resource type="SpriteFrames" format=3 uid="uid://bw1vctqndifwh"]\n'
ext_resources = ""
sub_resources = ""
animations = []


import random
import string

def gen_id():
    characters = string.ascii_lowercase + string.digits
    return ''.join(random.choices(characters, k=5))


def add_atlas(parent_oid, region):
    global sub_resources
    oid = "AtlasTexture_" + gen_id()
    sub_resources += f'[sub_resource type="AtlasTexture" id="{oid}"]\n'
    sub_resources += f'atlas = ExtResource("{parent_oid}")\n'
    sub_resources += f'region = Rect2({", ".join(map(str, region))})\n\n'
    return oid


def add_image(fp, id, anim_name):
    global ext_resources

    path = f"res://characters/student/textures/{fp}"
    root_path = f"/home/ignacioc/Projects/Godot/BaldiOnline2/characters/student/textures/{fp}"
    imp = f"{root_path}.import"

    with open(imp, "r") as imp_f:
        uid = imp_f.readlines()[4].replace('uid="', "").replace('"\n', "")

    oid = f"{id}_{gen_id()}"
    ext_resources += f'[ext_resource type="Texture2D" uid="{uid}" path="{path}" id="{oid}"]\n'


    regions = [
        [0, 0, 256, 256],
        [256, 0, 256, 256],
        [0, 256, 256, 256],
        [256, 256, 256, 256],
        [0, 512, 256, 256],
        [256, 512, 256, 256],
        [0, 768, 256, 256],
        [256, 768, 256, 256]
    ]
    atlas_oids = [add_atlas(oid, region) for region in regions]

    frames = [f'{{"duration": 1.0, "texture": SubResource("{oid}")}}' for oid in atlas_oids]
    anim = f'{{"frames": [{", ".join(frames)}], "loop": 1, "name": &"{anim_name}", "speed": 20.0}}'
    animations.append(anim)

def add_yay(fp, id, anim_name):
    global ext_resources

    path = f"res://characters/student/textures/{fp}"
    root_path = f"/home/ignacioc/Projects/Godot/BaldiOnline2/characters/student/textures/{fp}"
    imp = f"{root_path}.import"

    with open(imp, "r") as imp_f:
        uid = imp_f.readlines()[4].replace("uid=", "").replace('"', "")

    oid = f"{id}_{gen_id()}"
    ext_resources += f'[ext_resource type="Texture2D" uid="{uid}" path="{path}" id="{oid}"]\n'


    anim = f'{{"frames": [{{"duration": 1.0, "texture": ExtResource("{oid}")}}], "loop": 0, "name": &"{anim_name}", "speed": 1.0}}'
    animations.append(anim)  
        

for i in range(12):
    for angle in [0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330]:
        add_image(f"{i}/Student_{i}_{angle}_Sheet.png", i, f"{i}_{angle}")
    add_yay(f"{i}/Student_{i}_Yay.png", i + 12, f"{i}_yay")

fc += f"\n{ext_resources}\n"
fc += f"\n{sub_resources}\n"
fc += "[resource]\n"
fc += f"animations = [\n{",\n".join([f"    {a}" for a in animations])}\n]"

with open("/home/ignacioc/Projects/Godot/BaldiOnline2/characters/student/textures/test.txt", "w") as fpp:
    fpp.write(fc)