#!/usr/bin/env python3
"""
Velocity - Pixel Art Asset Generator
Generates all game sprites, tilesets, UI elements, and effects
Style: Neon cyberpunk with Katana Zero inspiration
"""

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import random

# Ensure output directories exist
BASE_PATH = "/home/user/Velocity/assets/sprites"
DIRS = [
    "player", "player/skins/default", "player/skins/ninja", "player/skins/cyber",
    "player/skins/ghost", "player/skins/neon", "player/skins/glitch",
    "tiles", "tiles/platforms", "tiles/hazards", "tiles/decoration",
    "enemies", "ui", "ui/icons", "ui/buttons", "ui/panels",
    "fx", "fx/particles", "fx/trails", "backgrounds"
]

for d in DIRS:
    os.makedirs(os.path.join(BASE_PATH, d), exist_ok=True)

# Color palette - Neon Cyberpunk
COLORS = {
    'black': (5, 5, 15, 255),
    'dark': (15, 10, 30, 255),
    'dark_purple': (30, 20, 50, 255),
    'purple': (80, 40, 120, 255),
    'violet': (150, 50, 255, 255),
    'cyan': (0, 255, 255, 255),
    'cyan_dark': (0, 150, 180, 255),
    'magenta': (255, 0, 255, 255),
    'pink': (255, 100, 180, 255),
    'blue': (50, 100, 255, 255),
    'green': (50, 255, 150, 255),
    'yellow': (255, 255, 50, 255),
    'orange': (255, 150, 50, 255),
    'red': (255, 50, 80, 255),
    'white': (255, 255, 255, 255),
    'gray': (100, 100, 120, 255),
    'light_gray': (180, 180, 200, 255),
    'transparent': (0, 0, 0, 0),
    'glow_cyan': (100, 255, 255, 200),
    'glow_magenta': (255, 100, 255, 200),
}

def create_glow(img, color, radius=2):
    """Add glow effect to an image"""
    glow = img.copy()
    glow = glow.filter(ImageFilter.GaussianBlur(radius))
    result = Image.new('RGBA', img.size, (0, 0, 0, 0))
    result.paste(glow, (0, 0))
    result = Image.alpha_composite(result, img)
    return result

def draw_pixel(draw, x, y, color, scale=1):
    """Draw a scaled pixel"""
    if scale == 1:
        draw.point((x, y), fill=color)
    else:
        draw.rectangle([x*scale, y*scale, (x+1)*scale-1, (y+1)*scale-1], fill=color)

# ============================================
# PLAYER SPRITES
# ============================================

def generate_player_spritesheet(skin_name="default", primary_color=COLORS['cyan'], secondary_color=COLORS['magenta']):
    """Generate complete player animation spritesheet"""

    # Frame size and layout
    frame_w, frame_h = 32, 32
    frames_per_row = 8
    animations = {
        'idle': 4,
        'run': 8,
        'jump': 2,
        'fall': 2,
        'dash': 3,
        'wall_slide': 2,
        'death': 6,
        'spawn': 4
    }

    total_frames = sum(animations.values())
    rows = (total_frames + frames_per_row - 1) // frames_per_row

    sheet = Image.new('RGBA', (frame_w * frames_per_row, frame_h * rows), COLORS['transparent'])
    draw = ImageDraw.Draw(sheet)

    frame_idx = 0

    # Player base design - sleek runner silhouette
    def draw_player(draw, ox, oy, pose='idle', frame=0):
        """Draw player in various poses"""

        # Base colors based on skin
        body_color = COLORS['dark']
        outline_color = primary_color
        accent_color = secondary_color
        eye_color = primary_color

        if skin_name == "ghost":
            body_color = (*primary_color[:3], 150)
            outline_color = (*COLORS['white'][:3], 200)
        elif skin_name == "neon":
            body_color = primary_color
            outline_color = COLORS['white']
        elif skin_name == "glitch":
            if frame % 2 == 0:
                body_color = primary_color
            else:
                body_color = secondary_color

        # Center position
        cx, cy = ox + 16, oy + 16

        if pose == 'idle':
            # Breathing animation
            bob = [0, -1, -1, 0][frame % 4]

            # Body - sleek rectangular shape
            draw.rectangle([cx-4, cy-8+bob, cx+3, cy+6], fill=body_color)
            # Outline glow
            draw.rectangle([cx-5, cy-9+bob, cx+4, cy-8+bob], fill=outline_color)
            draw.rectangle([cx-5, cy+6, cx+4, cy+7], fill=outline_color)
            draw.rectangle([cx-5, cy-8+bob, cx-4, cy+6], fill=outline_color)
            draw.rectangle([cx+3, cy-8+bob, cx+4, cy+6], fill=outline_color)

            # Head
            draw.rectangle([cx-3, cy-12+bob, cx+2, cy-8+bob], fill=body_color)
            draw.rectangle([cx-4, cy-13+bob, cx+3, cy-12+bob], fill=outline_color)
            draw.rectangle([cx-4, cy-12+bob, cx-3, cy-8+bob], fill=outline_color)
            draw.rectangle([cx+2, cy-12+bob, cx+3, cy-8+bob], fill=outline_color)

            # Eye visor
            draw.rectangle([cx-2, cy-11+bob, cx+1, cy-10+bob], fill=eye_color)

            # Legs
            draw.rectangle([cx-3, cy+7, cx-1, cy+11], fill=body_color)
            draw.rectangle([cx+0, cy+7, cx+2, cy+11], fill=body_color)
            draw.line([cx-3, cy+11, cx-1, cy+11], fill=outline_color)
            draw.line([cx+0, cy+11, cx+2, cy+11], fill=outline_color)

        elif pose == 'run':
            # Running animation with leg movement
            leg_frames = [
                [(0, 0), (2, 3)],   # 0
                [(1, 2), (1, 4)],   # 1
                [(2, 3), (0, 2)],   # 2
                [(2, 4), (-1, 1)],  # 3
                [(1, 3), (-2, 0)],  # 4
                [(0, 2), (-1, 2)],  # 5
                [(-1, 1), (1, 3)],  # 6
                [(-2, 0), (2, 4)],  # 7
            ]

            bob = [-1, 0, -1, -2, -1, 0, -1, -2][frame % 8]
            lean = 2  # Forward lean

            legs = leg_frames[frame % 8]

            # Body - leaning forward
            draw.rectangle([cx-3+lean, cy-8+bob, cx+4+lean, cy+5], fill=body_color)
            draw.rectangle([cx-4+lean, cy-9+bob, cx+5+lean, cy-8+bob], fill=outline_color)
            draw.rectangle([cx-4+lean, cy+5, cx+5+lean, cy+6], fill=outline_color)

            # Head
            draw.rectangle([cx-2+lean, cy-12+bob, cx+3+lean, cy-8+bob], fill=body_color)
            draw.rectangle([cx-3+lean, cy-13+bob, cx+4+lean, cy-12+bob], fill=outline_color)

            # Eye
            draw.rectangle([cx+lean, cy-11+bob, cx+2+lean, cy-10+bob], fill=eye_color)

            # Legs with animation
            l1, l2 = legs
            draw.rectangle([cx-2+l1[0], cy+6, cx+l1[0], cy+10+l1[1]], fill=body_color)
            draw.rectangle([cx+1+l2[0], cy+6, cx+3+l2[0], cy+10+l2[1]], fill=body_color)

            # Speed lines (accent)
            if frame % 2 == 0:
                draw.line([cx-8, cy-4+bob, cx-5, cy-4+bob], fill=accent_color)
                draw.line([cx-7, cy+bob, cx-4, cy+bob], fill=accent_color)

        elif pose == 'jump':
            # Jumping - arms up, legs tucked
            stretch = [2, 0][frame % 2]

            # Body - stretched
            draw.rectangle([cx-3, cy-9-stretch, cx+2, cy+4], fill=body_color)
            draw.rectangle([cx-4, cy-10-stretch, cx+3, cy-9-stretch], fill=outline_color)
            draw.rectangle([cx-4, cy+4, cx+3, cy+5], fill=outline_color)
            draw.rectangle([cx-4, cy-9-stretch, cx-3, cy+4], fill=outline_color)
            draw.rectangle([cx+2, cy-9-stretch, cx+3, cy+4], fill=outline_color)

            # Head
            draw.rectangle([cx-2, cy-13-stretch, cx+1, cy-9-stretch], fill=body_color)
            draw.rectangle([cx-3, cy-14-stretch, cx+2, cy-13-stretch], fill=outline_color)

            # Eye
            draw.rectangle([cx-1, cy-12-stretch, cx, cy-11-stretch], fill=eye_color)

            # Tucked legs
            draw.rectangle([cx-3, cy+5, cx+2, cy+8], fill=body_color)
            draw.line([cx-3, cy+8, cx+2, cy+8], fill=outline_color)

        elif pose == 'fall':
            # Falling - spread out
            spread = [0, 1][frame % 2]

            # Body
            draw.rectangle([cx-4, cy-7, cx+3, cy+5], fill=body_color)
            draw.rectangle([cx-5, cy-8, cx+4, cy-7], fill=outline_color)
            draw.rectangle([cx-5, cy+5, cx+4, cy+6], fill=outline_color)

            # Head
            draw.rectangle([cx-2, cy-11, cx+1, cy-7], fill=body_color)
            draw.rectangle([cx-3, cy-12, cx+2, cy-11], fill=outline_color)

            # Eye - looking down
            draw.rectangle([cx-1, cy-9, cx, cy-8], fill=eye_color)

            # Legs spread
            draw.rectangle([cx-5-spread, cy+6, cx-2-spread, cy+11], fill=body_color)
            draw.rectangle([cx+1+spread, cy+6, cx+4+spread, cy+11], fill=body_color)

        elif pose == 'dash':
            # Dashing - horizontal stretch with motion blur effect
            stretch = [4, 3, 2][frame % 3]

            # Motion blur trail
            for i in range(3):
                alpha = 100 - i * 30
                trail_color = (*primary_color[:3], alpha)
                draw.rectangle([cx-10-i*4, cy-6, cx-6-i*4, cy+4], fill=trail_color)

            # Body - horizontal
            draw.rectangle([cx-4, cy-5, cx+6+stretch, cy+3], fill=body_color)
            draw.rectangle([cx-5, cy-6, cx+7+stretch, cy-5], fill=outline_color)
            draw.rectangle([cx-5, cy+3, cx+7+stretch, cy+4], fill=outline_color)

            # Head merged with body for speed
            draw.rectangle([cx+5+stretch, cy-4, cx+9+stretch, cy+2], fill=body_color)
            draw.rectangle([cx+9+stretch, cy-3, cx+10+stretch, cy+1], fill=outline_color)

            # Eye - determined
            draw.rectangle([cx+7+stretch, cy-2, cx+8+stretch, cy-1], fill=eye_color)

            # Legs trailing
            draw.rectangle([cx-6, cy+4, cx-3, cy+7], fill=body_color)
            draw.rectangle([cx-8, cy+5, cx-5, cy+8], fill=body_color)

        elif pose == 'wall_slide':
            # Wall sliding - against wall
            slide = [0, 1][frame % 2]

            # Body against wall
            draw.rectangle([cx-2, cy-8, cx+4, cy+6], fill=body_color)
            draw.rectangle([cx-3, cy-9, cx+5, cy-8], fill=outline_color)
            draw.rectangle([cx-3, cy+6, cx+5, cy+7], fill=outline_color)
            draw.rectangle([cx+4, cy-8, cx+5, cy+6], fill=outline_color)

            # Head
            draw.rectangle([cx-1, cy-12, cx+3, cy-8], fill=body_color)
            draw.rectangle([cx-2, cy-13, cx+4, cy-12], fill=outline_color)

            # Eye looking away from wall
            draw.rectangle([cx-1, cy-11, cx, cy-10], fill=eye_color)

            # Legs bent
            draw.rectangle([cx-3, cy+7, cx, cy+10+slide], fill=body_color)
            draw.rectangle([cx+1, cy+7, cx+4, cy+9+slide], fill=body_color)

            # Friction particles
            if frame % 2 == 0:
                draw.point((cx+6, cy+slide), fill=accent_color)
                draw.point((cx+7, cy+3+slide), fill=accent_color)

        elif pose == 'death':
            # Death animation - dissolve/shatter
            progress = frame / 5.0

            if frame < 3:
                # Initial impact
                draw.rectangle([cx-4, cy-8, cx+3, cy+6], fill=body_color)
                draw.rectangle([cx-3, cy-12, cx+2, cy-8], fill=body_color)

                # Glitch/impact lines
                for i in range(frame + 1):
                    gx = cx + random.randint(-8, 8)
                    gy = cy + random.randint(-12, 8)
                    draw.line([gx, gy, gx + random.randint(2, 6), gy], fill=accent_color)
            else:
                # Particle dissolution
                particles = 20 - (frame - 3) * 5
                for i in range(max(0, particles)):
                    px = cx + random.randint(-10, 10) + int((frame-3) * random.randint(-2, 2))
                    py = cy + random.randint(-12, 10) - int((frame-3) * 3)
                    size = random.randint(1, 3)
                    pcolor = primary_color if random.random() > 0.5 else accent_color
                    draw.rectangle([px, py, px+size, py+size], fill=pcolor)

        elif pose == 'spawn':
            # Spawn animation - materialize
            progress = frame / 3.0

            if frame == 0:
                # Initial flash
                draw.ellipse([cx-8, cy-8, cx+8, cy+8], fill=(*primary_color[:3], 150))
            elif frame == 1:
                # Forming
                draw.rectangle([cx-3, cy-6, cx+2, cy+4], fill=(*body_color[:3], 150))
                draw.rectangle([cx-2, cy-10, cx+1, cy-6], fill=(*body_color[:3], 150))
                # Glitch lines
                for i in range(5):
                    draw.line([cx-6+i*2, cy-12+i*2, cx-6+i*2+4, cy-12+i*2], fill=primary_color)
            elif frame == 2:
                # Almost formed
                draw.rectangle([cx-4, cy-8, cx+3, cy+6], fill=(*body_color[:3], 200))
                draw.rectangle([cx-3, cy-12, cx+2, cy-8], fill=(*body_color[:3], 200))
                draw.rectangle([cx-2, cy-11, cx+1, cy-10], fill=eye_color)
            else:
                # Fully formed with flash
                draw_player(draw, ox, oy, 'idle', 0)
                # Spawn ring
                draw.ellipse([cx-12, cy-12, cx+12, cy+12], outline=(*primary_color[:3], 100))

    # Generate all animation frames
    row = 0
    col = 0

    for anim_name, frame_count in animations.items():
        for f in range(frame_count):
            ox = col * frame_w
            oy = row * frame_h
            draw_player(draw, ox, oy, anim_name, f)

            col += 1
            if col >= frames_per_row:
                col = 0
                row += 1

    return sheet

def generate_all_player_skins():
    """Generate spritesheets for all player skins"""

    skins = {
        'default': (COLORS['cyan'], COLORS['magenta']),
        'ninja': (COLORS['dark_purple'], COLORS['violet']),
        'cyber': (COLORS['blue'], COLORS['green']),
        'ghost': (COLORS['white'], COLORS['cyan']),
        'neon': (COLORS['magenta'], COLORS['cyan']),
        'glitch': (COLORS['red'], COLORS['green']),
    }

    for skin_name, (primary, secondary) in skins.items():
        sheet = generate_player_spritesheet(skin_name, primary, secondary)
        sheet.save(os.path.join(BASE_PATH, f"player/skins/{skin_name}/spritesheet.png"))
        print(f"Generated player skin: {skin_name}")

# ============================================
# TILESET GENERATION
# ============================================

def generate_tileset():
    """Generate complete tileset for level building"""

    tile_size = 32
    cols = 16
    rows = 16

    tileset = Image.new('RGBA', (tile_size * cols, tile_size * rows), COLORS['transparent'])
    draw = ImageDraw.Draw(tileset)

    def draw_tile(tx, ty, tile_type):
        """Draw a single tile at grid position"""
        x = tx * tile_size
        y = ty * tile_size

        if tile_type == 'solid':
            # Basic solid platform
            draw.rectangle([x, y, x+tile_size-1, y+tile_size-1], fill=COLORS['dark'])
            # Top edge glow
            draw.rectangle([x, y, x+tile_size-1, y+2], fill=COLORS['cyan'])
            # Grid pattern
            for i in range(0, tile_size, 8):
                draw.line([x+i, y+3, x+i, y+tile_size-1], fill=COLORS['dark_purple'])
                draw.line([x, y+i, x+tile_size-1, y+i], fill=COLORS['dark_purple'])

        elif tile_type == 'solid_corner_tl':
            draw.rectangle([x, y, x+tile_size-1, y+tile_size-1], fill=COLORS['dark'])
            draw.rectangle([x, y, x+tile_size-1, y+2], fill=COLORS['cyan'])
            draw.rectangle([x, y, x+2, y+tile_size-1], fill=COLORS['cyan'])

        elif tile_type == 'solid_corner_tr':
            draw.rectangle([x, y, x+tile_size-1, y+tile_size-1], fill=COLORS['dark'])
            draw.rectangle([x, y, x+tile_size-1, y+2], fill=COLORS['cyan'])
            draw.rectangle([x+tile_size-3, y, x+tile_size-1, y+tile_size-1], fill=COLORS['cyan'])

        elif tile_type == 'solid_corner_bl':
            draw.rectangle([x, y, x+tile_size-1, y+tile_size-1], fill=COLORS['dark'])
            draw.rectangle([x, y+tile_size-3, x+tile_size-1, y+tile_size-1], fill=COLORS['cyan'])
            draw.rectangle([x, y, x+2, y+tile_size-1], fill=COLORS['cyan'])

        elif tile_type == 'solid_corner_br':
            draw.rectangle([x, y, x+tile_size-1, y+tile_size-1], fill=COLORS['dark'])
            draw.rectangle([x, y+tile_size-3, x+tile_size-1, y+tile_size-1], fill=COLORS['cyan'])
            draw.rectangle([x+tile_size-3, y, x+tile_size-1, y+tile_size-1], fill=COLORS['cyan'])

        elif tile_type == 'platform':
            # One-way platform
            draw.rectangle([x, y, x+tile_size-1, y+6], fill=COLORS['dark'])
            draw.rectangle([x, y, x+tile_size-1, y+2], fill=COLORS['violet'])
            # Dashed line pattern
            for i in range(0, tile_size, 8):
                draw.rectangle([x+i, y+3, x+i+4, y+5], fill=COLORS['purple'])

        elif tile_type == 'spike_up':
            # Deadly spike pointing up
            for i in range(4):
                sx = x + i * 8
                # Triangle spike
                draw.polygon([
                    (sx+4, y+2),
                    (sx, y+tile_size-1),
                    (sx+8, y+tile_size-1)
                ], fill=COLORS['red'])
                # Glow tip
                draw.line([sx+4, y+2, sx+4, y+6], fill=COLORS['orange'])

        elif tile_type == 'spike_down':
            for i in range(4):
                sx = x + i * 8
                draw.polygon([
                    (sx+4, y+tile_size-3),
                    (sx, y),
                    (sx+8, y)
                ], fill=COLORS['red'])
                draw.line([sx+4, y+tile_size-3, sx+4, y+tile_size-7], fill=COLORS['orange'])

        elif tile_type == 'spike_left':
            for i in range(4):
                sy = y + i * 8
                draw.polygon([
                    (x+2, sy+4),
                    (x+tile_size-1, sy),
                    (x+tile_size-1, sy+8)
                ], fill=COLORS['red'])
                draw.line([x+2, sy+4, x+6, sy+4], fill=COLORS['orange'])

        elif tile_type == 'spike_right':
            for i in range(4):
                sy = y + i * 8
                draw.polygon([
                    (x+tile_size-3, sy+4),
                    (x, sy),
                    (x, sy+8)
                ], fill=COLORS['red'])
                draw.line([x+tile_size-3, sy+4, x+tile_size-7, sy+4], fill=COLORS['orange'])

        elif tile_type == 'checkpoint':
            # Checkpoint flag/beacon
            draw.rectangle([x+14, y+4, x+17, y+tile_size-1], fill=COLORS['gray'])
            # Flag
            draw.polygon([
                (x+17, y+4),
                (x+28, y+10),
                (x+17, y+16)
            ], fill=COLORS['green'])
            # Glow base
            draw.ellipse([x+10, y+tile_size-6, x+22, y+tile_size-1], fill=COLORS['green'])

        elif tile_type == 'checkpoint_active':
            draw.rectangle([x+14, y+4, x+17, y+tile_size-1], fill=COLORS['light_gray'])
            draw.polygon([
                (x+17, y+4),
                (x+28, y+10),
                (x+17, y+16)
            ], fill=COLORS['cyan'])
            draw.ellipse([x+8, y+tile_size-8, x+24, y+tile_size-1], fill=(*COLORS['cyan'][:3], 150))

        elif tile_type == 'goal':
            # Level end goal
            draw.rectangle([x+2, y+2, x+tile_size-3, y+tile_size-3], fill=COLORS['dark'])
            draw.rectangle([x+2, y+2, x+tile_size-3, y+4], fill=COLORS['magenta'])
            draw.rectangle([x+2, y+tile_size-5, x+tile_size-3, y+tile_size-3], fill=COLORS['magenta'])
            draw.rectangle([x+2, y+2, x+4, y+tile_size-3], fill=COLORS['magenta'])
            draw.rectangle([x+tile_size-5, y+2, x+tile_size-3, y+tile_size-3], fill=COLORS['magenta'])
            # Inner glow
            draw.rectangle([x+8, y+8, x+tile_size-9, y+tile_size-9], fill=(*COLORS['magenta'][:3], 100))

        elif tile_type == 'star':
            # Collectible star
            cx, cy = x + tile_size//2, y + tile_size//2
            # Star shape
            points = []
            for i in range(10):
                angle = i * math.pi / 5 - math.pi / 2
                r = 12 if i % 2 == 0 else 6
                points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
            draw.polygon(points, fill=COLORS['yellow'])
            # Inner highlight
            for i in range(10):
                angle = i * math.pi / 5 - math.pi / 2
                r = 8 if i % 2 == 0 else 4
                points[i] = (cx + r * math.cos(angle), cy + r * math.sin(angle))
            draw.polygon(points, fill=COLORS['white'])

        elif tile_type == 'moving_platform':
            draw.rectangle([x, y+8, x+tile_size-1, y+24], fill=COLORS['dark'])
            draw.rectangle([x, y+8, x+tile_size-1, y+11], fill=COLORS['violet'])
            # Movement indicator arrows
            draw.polygon([(x+4, y+16), (x+10, y+13), (x+10, y+19)], fill=COLORS['violet'])
            draw.polygon([(x+tile_size-5, y+16), (x+tile_size-11, y+13), (x+tile_size-11, y+19)], fill=COLORS['violet'])

        elif tile_type == 'bounce_pad':
            # Spring/bounce platform
            draw.rectangle([x+4, y+16, x+tile_size-5, y+tile_size-1], fill=COLORS['dark'])
            # Spring coil
            draw.rectangle([x+8, y+8, x+tile_size-9, y+16], fill=COLORS['green'])
            draw.rectangle([x+6, y+4, x+tile_size-7, y+8], fill=COLORS['green'])
            # Top plate
            draw.rectangle([x+2, y, x+tile_size-3, y+4], fill=COLORS['cyan'])

        elif tile_type == 'wall':
            # Climbable wall
            draw.rectangle([x, y, x+tile_size-1, y+tile_size-1], fill=COLORS['dark'])
            # Grip texture
            for i in range(4):
                for j in range(4):
                    if (i + j) % 2 == 0:
                        gx = x + i * 8 + 2
                        gy = y + j * 8 + 2
                        draw.rectangle([gx, gy, gx+4, gy+4], fill=COLORS['dark_purple'])
            # Edge highlight
            draw.rectangle([x, y, x+2, y+tile_size-1], fill=COLORS['purple'])

        elif tile_type == 'laser_emitter':
            # Laser beam emitter
            draw.rectangle([x+8, y, x+24, y+tile_size-1], fill=COLORS['dark'])
            draw.rectangle([x+10, y+8, x+22, y+24], fill=COLORS['gray'])
            # Lens
            draw.ellipse([x+12, y+12, x+20, y+20], fill=COLORS['red'])
            draw.ellipse([x+14, y+14, x+18, y+18], fill=COLORS['orange'])

        elif tile_type == 'laser_beam':
            # Laser beam segment
            draw.rectangle([x, y+12, x+tile_size-1, y+20], fill=(*COLORS['red'][:3], 180))
            draw.rectangle([x, y+14, x+tile_size-1, y+18], fill=COLORS['orange'])
            draw.rectangle([x, y+15, x+tile_size-1, y+17], fill=COLORS['yellow'])

        elif tile_type == 'decoration_pipe_h':
            # Horizontal pipe decoration
            draw.rectangle([x, y+10, x+tile_size-1, y+22], fill=COLORS['gray'])
            draw.rectangle([x, y+10, x+tile_size-1, y+12], fill=COLORS['light_gray'])
            draw.rectangle([x, y+20, x+tile_size-1, y+22], fill=COLORS['dark_purple'])

        elif tile_type == 'decoration_pipe_v':
            # Vertical pipe
            draw.rectangle([x+10, y, x+22, y+tile_size-1], fill=COLORS['gray'])
            draw.rectangle([x+10, y, x+12, y+tile_size-1], fill=COLORS['light_gray'])
            draw.rectangle([x+20, y, x+22, y+tile_size-1], fill=COLORS['dark_purple'])

        elif tile_type == 'decoration_vent':
            # Vent/grate
            draw.rectangle([x+2, y+2, x+tile_size-3, y+tile_size-3], fill=COLORS['dark'])
            for i in range(4):
                draw.rectangle([x+4, y+4+i*7, x+tile_size-5, y+6+i*7], fill=COLORS['black'])
            draw.rectangle([x+2, y+2, x+tile_size-3, y+4], fill=COLORS['gray'])
            draw.rectangle([x+2, y+tile_size-5, x+tile_size-3, y+tile_size-3], fill=COLORS['gray'])

        elif tile_type == 'decoration_screen':
            # Monitor/screen
            draw.rectangle([x+2, y+2, x+tile_size-3, y+tile_size-3], fill=COLORS['dark'])
            draw.rectangle([x+4, y+4, x+tile_size-5, y+tile_size-8], fill=COLORS['dark_purple'])
            # Screen content - random data
            for i in range(3):
                sw = random.randint(8, 20)
                draw.rectangle([x+6, y+6+i*6, x+6+sw, y+8+i*6], fill=COLORS['cyan'])
            # Stand
            draw.rectangle([x+12, y+tile_size-8, x+20, y+tile_size-3], fill=COLORS['gray'])

        elif tile_type == 'neon_sign_1':
            # Neon decoration
            draw.rectangle([x+4, y+8, x+tile_size-5, y+24], fill=COLORS['transparent'])
            # Glowing text effect
            draw.rectangle([x+6, y+10, x+14, y+14], fill=COLORS['magenta'])
            draw.rectangle([x+18, y+10, x+26, y+22], fill=COLORS['magenta'])
            draw.rectangle([x+6, y+14, x+10, y+22], fill=COLORS['magenta'])
            draw.rectangle([x+6, y+18, x+14, y+22], fill=COLORS['magenta'])

    # Layout tiles in tileset grid
    tile_layout = [
        # Row 0: Basic solids
        ['solid', 'solid_corner_tl', 'solid_corner_tr', 'solid_corner_bl', 'solid_corner_br', 'wall', 'platform', 'moving_platform',
         None, None, None, None, None, None, None, None],
        # Row 1: Hazards
        ['spike_up', 'spike_down', 'spike_left', 'spike_right', 'laser_emitter', 'laser_beam', None, None,
         None, None, None, None, None, None, None, None],
        # Row 2: Interactables
        ['checkpoint', 'checkpoint_active', 'goal', 'star', 'bounce_pad', None, None, None,
         None, None, None, None, None, None, None, None],
        # Row 3: Decorations
        ['decoration_pipe_h', 'decoration_pipe_v', 'decoration_vent', 'decoration_screen', 'neon_sign_1', None, None, None,
         None, None, None, None, None, None, None, None],
    ]

    for ty, row in enumerate(tile_layout):
        for tx, tile_type in enumerate(row):
            if tile_type:
                draw_tile(tx, ty, tile_type)

    tileset.save(os.path.join(BASE_PATH, "tiles/tileset.png"))
    print("Generated tileset")

    return tileset

# ============================================
# BACKGROUNDS
# ============================================

def generate_backgrounds():
    """Generate parallax background layers"""

    bg_width = 1920
    bg_height = 1080

    # Layer 1: Far background - city skyline
    bg1 = Image.new('RGBA', (bg_width, bg_height), COLORS['black'])
    draw1 = ImageDraw.Draw(bg1)

    # Gradient sky
    for y in range(bg_height):
        progress = y / bg_height
        r = int(5 + progress * 20)
        g = int(2 + progress * 15)
        b = int(15 + progress * 35)
        draw1.line([(0, y), (bg_width, y)], fill=(r, g, b, 255))

    # Distant buildings
    for i in range(30):
        bx = i * 70 + random.randint(-20, 20)
        bh = random.randint(200, 500)
        bw = random.randint(40, 80)
        by = bg_height - bh

        # Building silhouette
        draw1.rectangle([bx, by, bx+bw, bg_height], fill=COLORS['dark'])

        # Windows
        for wx in range(bx+4, bx+bw-4, 8):
            for wy in range(by+8, bg_height-20, 12):
                if random.random() > 0.3:
                    wcolor = random.choice([COLORS['cyan'], COLORS['magenta'], COLORS['yellow'], COLORS['dark_purple']])
                    wcolor = (*wcolor[:3], random.randint(100, 200))
                    draw1.rectangle([wx, wy, wx+4, wy+6], fill=wcolor)

    bg1.save(os.path.join(BASE_PATH, "backgrounds/city_far.png"))

    # Layer 2: Mid background - closer buildings with more detail
    bg2 = Image.new('RGBA', (bg_width, bg_height), COLORS['transparent'])
    draw2 = ImageDraw.Draw(bg2)

    for i in range(15):
        bx = i * 140 + random.randint(-30, 30)
        bh = random.randint(400, 700)
        bw = random.randint(80, 150)
        by = bg_height - bh

        draw2.rectangle([bx, by, bx+bw, bg_height], fill=COLORS['dark'])
        draw2.rectangle([bx, by, bx+bw, by+4], fill=COLORS['purple'])

        # Neon signs
        if random.random() > 0.5:
            sign_color = random.choice([COLORS['cyan'], COLORS['magenta'], COLORS['pink']])
            sy = by + random.randint(20, 100)
            draw2.rectangle([bx+10, sy, bx+bw-10, sy+20], fill=sign_color)

        # Windows
        for wx in range(bx+8, bx+bw-8, 12):
            for wy in range(by+30, bg_height-30, 16):
                if random.random() > 0.4:
                    draw2.rectangle([wx, wy, wx+6, wy+10], fill=COLORS['dark_purple'])

    bg2.save(os.path.join(BASE_PATH, "backgrounds/city_mid.png"))

    # Layer 3: Near background - platforms and structures
    bg3 = Image.new('RGBA', (bg_width, bg_height), COLORS['transparent'])
    draw3 = ImageDraw.Draw(bg3)

    # Pipes and infrastructure
    for i in range(10):
        py = random.randint(100, bg_height-200)
        draw3.rectangle([0, py, bg_width, py+20], fill=COLORS['dark'])
        draw3.rectangle([0, py, bg_width, py+3], fill=COLORS['gray'])

        # Pipe joints
        for jx in range(0, bg_width, 200):
            draw3.rectangle([jx, py-5, jx+30, py+25], fill=COLORS['dark'])
            draw3.ellipse([jx+5, py, jx+25, py+20], fill=COLORS['gray'])

    bg3.save(os.path.join(BASE_PATH, "backgrounds/city_near.png"))

    print("Generated backgrounds")

# ============================================
# UI ELEMENTS
# ============================================

def generate_ui_elements():
    """Generate UI sprites and icons"""

    # Game icon
    icon = Image.new('RGBA', (256, 256), COLORS['dark'])
    draw = ImageDraw.Draw(icon)

    # V shape for Velocity
    draw.polygon([
        (40, 40),
        (128, 200),
        (216, 40),
        (180, 40),
        (128, 160),
        (76, 40)
    ], fill=COLORS['cyan'])

    # Speed lines
    draw.line([(20, 80), (60, 80)], fill=COLORS['magenta'], width=4)
    draw.line([(196, 80), (236, 80)], fill=COLORS['magenta'], width=4)
    draw.line([(30, 120), (50, 120)], fill=COLORS['magenta'], width=3)
    draw.line([(206, 120), (226, 120)], fill=COLORS['magenta'], width=3)

    icon.save(os.path.join(BASE_PATH, "ui/icon.png"))

    # Button backgrounds
    button_sizes = [(200, 50), (150, 40), (100, 35)]
    button_states = ['normal', 'hover', 'pressed']

    for size in button_sizes:
        for state in button_states:
            btn = Image.new('RGBA', size, COLORS['transparent'])
            draw = ImageDraw.Draw(btn)

            if state == 'normal':
                fill_color = COLORS['dark']
                border_color = COLORS['cyan']
            elif state == 'hover':
                fill_color = COLORS['dark_purple']
                border_color = COLORS['magenta']
            else:  # pressed
                fill_color = COLORS['purple']
                border_color = COLORS['white']

            # Rounded rectangle effect
            draw.rectangle([2, 2, size[0]-3, size[1]-3], fill=fill_color)
            draw.rectangle([0, 0, size[0]-1, 2], fill=border_color)
            draw.rectangle([0, size[1]-3, size[0]-1, size[1]-1], fill=border_color)
            draw.rectangle([0, 0, 2, size[1]-1], fill=border_color)
            draw.rectangle([size[0]-3, 0, size[0]-1, size[1]-1], fill=border_color)

            btn.save(os.path.join(BASE_PATH, f"ui/buttons/button_{size[0]}x{size[1]}_{state}.png"))

    # Panel background
    panel = Image.new('RGBA', (400, 300), COLORS['transparent'])
    draw = ImageDraw.Draw(panel)

    draw.rectangle([4, 4, 395, 295], fill=(*COLORS['dark'][:3], 230))
    draw.rectangle([0, 0, 399, 4], fill=COLORS['cyan'])
    draw.rectangle([0, 295, 399, 299], fill=COLORS['cyan'])
    draw.rectangle([0, 0, 4, 299], fill=COLORS['cyan'])
    draw.rectangle([395, 0, 399, 299], fill=COLORS['cyan'])

    # Corner accents
    draw.rectangle([0, 0, 20, 4], fill=COLORS['magenta'])
    draw.rectangle([0, 0, 4, 20], fill=COLORS['magenta'])
    draw.rectangle([379, 0, 399, 4], fill=COLORS['magenta'])
    draw.rectangle([395, 0, 399, 20], fill=COLORS['magenta'])

    panel.save(os.path.join(BASE_PATH, "ui/panels/panel_medium.png"))

    # Icons
    icon_size = 32
    icons_data = {
        'play': lambda d: d.polygon([(8, 6), (26, 16), (8, 26)], fill=COLORS['green']),
        'pause': lambda d: [d.rectangle([8, 6, 13, 26], fill=COLORS['yellow']), d.rectangle([19, 6, 24, 26], fill=COLORS['yellow'])],
        'restart': lambda d: d.arc([6, 6, 26, 26], 45, 315, fill=COLORS['cyan'], width=3),
        'settings': lambda d: d.ellipse([8, 8, 24, 24], outline=COLORS['gray'], width=2),
        'back': lambda d: d.polygon([(22, 6), (10, 16), (22, 26)], fill=COLORS['cyan']),
        'forward': lambda d: d.polygon([(10, 6), (22, 16), (10, 26)], fill=COLORS['cyan']),
        'star': lambda d: d.polygon([(16, 4), (19, 12), (28, 12), (21, 18), (24, 27), (16, 22), (8, 27), (11, 18), (4, 12), (13, 12)], fill=COLORS['yellow']),
        'medal_bronze': lambda d: d.ellipse([6, 6, 26, 26], fill=(205, 127, 50, 255)),
        'medal_silver': lambda d: d.ellipse([6, 6, 26, 26], fill=(192, 192, 192, 255)),
        'medal_gold': lambda d: d.ellipse([6, 6, 26, 26], fill=(255, 215, 0, 255)),
        'medal_platinum': lambda d: d.ellipse([6, 6, 26, 26], fill=(229, 228, 226, 255)),
        'lock': lambda d: [d.rectangle([10, 14, 22, 26], fill=COLORS['gray']), d.arc([10, 6, 22, 18], 0, 180, fill=COLORS['gray'], width=2)],
        'check': lambda d: d.line([(8, 16), (14, 22), (26, 8)], fill=COLORS['green'], width=3),
        'cross': lambda d: [d.line([(8, 8), (24, 24)], fill=COLORS['red'], width=3), d.line([(24, 8), (8, 24)], fill=COLORS['red'], width=3)],
    }

    for icon_name, draw_func in icons_data.items():
        img = Image.new('RGBA', (icon_size, icon_size), COLORS['transparent'])
        draw = ImageDraw.Draw(img)
        draw_func(draw)
        img.save(os.path.join(BASE_PATH, f"ui/icons/{icon_name}.png"))

    print("Generated UI elements")

# ============================================
# FX AND PARTICLES
# ============================================

def generate_fx():
    """Generate visual effects and particle textures"""

    # Particle textures
    particles = {
        'circle_soft': (16, 'circle', True),
        'circle_hard': (16, 'circle', False),
        'square': (8, 'square', False),
        'spark': (16, 'spark', True),
        'star': (16, 'star', False),
    }

    for name, (size, shape, soft) in particles.items():
        img = Image.new('RGBA', (size, size), COLORS['transparent'])
        draw = ImageDraw.Draw(img)

        if shape == 'circle':
            if soft:
                # Soft gradient circle
                for r in range(size//2, 0, -1):
                    alpha = int(255 * (r / (size//2)))
                    draw.ellipse([size//2-r, size//2-r, size//2+r, size//2+r], fill=(255, 255, 255, alpha))
            else:
                draw.ellipse([0, 0, size-1, size-1], fill=COLORS['white'])
        elif shape == 'square':
            draw.rectangle([0, 0, size-1, size-1], fill=COLORS['white'])
        elif shape == 'spark':
            cx, cy = size//2, size//2
            draw.line([(cx, 0), (cx, size-1)], fill=COLORS['white'], width=2)
            draw.line([(0, cy), (size-1, cy)], fill=COLORS['white'], width=2)
            draw.line([(2, 2), (size-3, size-3)], fill=(255, 255, 255, 128), width=1)
            draw.line([(size-3, 2), (2, size-3)], fill=(255, 255, 255, 128), width=1)
        elif shape == 'star':
            cx, cy = size//2, size//2
            points = []
            for i in range(10):
                angle = i * math.pi / 5 - math.pi / 2
                r = size//2 - 1 if i % 2 == 0 else size//4
                points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
            draw.polygon(points, fill=COLORS['white'])

        img.save(os.path.join(BASE_PATH, f"fx/particles/{name}.png"))

    # Dash trail effect
    trail = Image.new('RGBA', (64, 32), COLORS['transparent'])
    draw = ImageDraw.Draw(trail)
    for x in range(64):
        alpha = int(255 * (1 - x/64))
        draw.line([(x, 8), (x, 24)], fill=(255, 255, 255, alpha))
    trail.save(os.path.join(BASE_PATH, "fx/trails/dash_trail.png"))

    # Death particles
    death = Image.new('RGBA', (8, 8), COLORS['transparent'])
    draw = ImageDraw.Draw(death)
    draw.rectangle([1, 1, 6, 6], fill=COLORS['white'])
    death.save(os.path.join(BASE_PATH, "fx/particles/death_particle.png"))

    # Glow texture
    glow = Image.new('RGBA', (64, 64), COLORS['transparent'])
    draw = ImageDraw.Draw(glow)
    for r in range(32, 0, -1):
        alpha = int(100 * (r / 32))
        draw.ellipse([32-r, 32-r, 32+r, 32+r], fill=(255, 255, 255, alpha))
    glow.save(os.path.join(BASE_PATH, "fx/glow.png"))

    print("Generated FX and particles")

# ============================================
# MAIN
# ============================================

if __name__ == "__main__":
    print("Generating Velocity game assets...")
    print("=" * 40)

    generate_all_player_skins()
    generate_tileset()
    generate_backgrounds()
    generate_ui_elements()
    generate_fx()

    print("=" * 40)
    print("Asset generation complete!")
