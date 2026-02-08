#!/usr/bin/env python3
"""Generate Vault app logo with modern V design - clean version."""

from PIL import Image, ImageDraw, ImageFilter
import math
import os

def draw_rounded_rect(img, x, y, w, h, radius, color):
    """Draw a proper rounded rectangle with antialiasing."""
    # Create at 4x size for antialiasing
    scale = 4
    temp = Image.new('RGBA', (w * scale, h * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(temp)
    
    r = radius * scale
    draw.rounded_rectangle([0, 0, w * scale - 1, h * scale - 1], r, fill=color)
    
    # Scale down with antialiasing
    temp = temp.resize((w, h), Image.Resampling.LANCZOS)
    img.paste(temp, (x, y), temp)

def draw_v(img, center_x, center_y, width, height, thickness, color, glow_color=None, glow_radius=0):
    """Draw a V shape with optional glow."""
    # Create at 4x size for antialiasing
    scale = 4
    size = max(width, height) * 2
    temp = Image.new('RGBA', (size * scale, size * scale), (0, 0, 0, 0))
    draw = ImageDraw.Draw(temp)
    
    cx = size * scale // 2
    cy = size * scale // 2
    w = width * scale
    h = height * scale
    t = thickness * scale
    
    # V shape polygon points
    points = [
        (cx - w // 2, cy - h // 2),  # top left outer
        (cx - w // 2 + t, cy - h // 2),  # top left inner
        (cx, cy + h // 2 - t // 3),  # bottom inner
        (cx + w // 2 - t, cy - h // 2),  # top right inner
        (cx + w // 2, cy - h // 2),  # top right outer
        (cx, cy + h // 2),  # bottom outer
    ]
    
    draw.polygon(points, fill=color)
    
    # Scale down
    temp = temp.resize((size, size), Image.Resampling.LANCZOS)
    
    # Add glow if requested
    if glow_color and glow_radius > 0:
        glow = temp.copy()
        glow = glow.filter(ImageFilter.GaussianBlur(radius=glow_radius))
        # Tint the glow
        glow_data = glow.load()
        for y in range(glow.height):
            for x in range(glow.width):
                r, g, b, a = glow_data[x, y]
                if a > 0:
                    glow_data[x, y] = (*glow_color[:3], min(255, a))
        
        # Composite glow then V
        paste_x = center_x - size // 2
        paste_y = center_y - size // 2
        img.paste(glow, (paste_x, paste_y), glow)
    
    paste_x = center_x - size // 2
    paste_y = center_y - size // 2
    img.paste(temp, (paste_x, paste_y), temp)

def create_logo(size):
    """Create the logo at specified size."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Colors
    bg_outer = (15, 15, 26, 255)
    bg_inner = (22, 22, 40, 255)
    v_color = (102, 126, 234, 255)  # #667eea
    v_glow = (102, 126, 234, 180)
    dot_color = (102, 126, 234, 80)
    
    # Background rounded rectangle
    radius = int(size * 0.22)
    draw_rounded_rect(img, 0, 0, size, size, radius, bg_outer)
    
    # Inner background
    margin = int(size * 0.035)
    draw_rounded_rect(img, margin, margin, size - margin * 2, size - margin * 2, 
                      int(radius * 0.85), bg_inner)
    
    # V shape
    center_x = size // 2
    center_y = int(size * 0.52)
    v_width = int(size * 0.50)
    v_height = int(size * 0.46)
    v_thickness = int(size * 0.095)
    glow_radius = max(5, size // 20)
    
    draw_v(img, center_x, center_y, v_width, v_height, v_thickness, v_color, v_glow, glow_radius)
    
    # Add subtle dots in corners (larger sizes only)
    if size >= 128:
        draw = ImageDraw.Draw(img)
        dot_r = max(2, int(size * 0.012))
        dot_y = int(size * 0.14)
        dot_x1 = int(size * 0.14)
        dot_x2 = int(size * 0.86)
        
        draw.ellipse([dot_x1 - dot_r, dot_y - dot_r, dot_x1 + dot_r, dot_y + dot_r], fill=dot_color)
        draw.ellipse([dot_x2 - dot_r, dot_y - dot_r, dot_x2 + dot_r, dot_y + dot_r], fill=dot_color)
    
    # Add subtle highlight on top of V
    if size >= 128:
        highlight = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        h_draw = ImageDraw.Draw(highlight)
        
        # Small gradient highlight area
        h_center_y = center_y - v_height // 3
        h_width = v_width // 4
        h_height = v_height // 4
        
        for i in range(h_height):
            alpha = int(30 * (1 - i / h_height))
            h_draw.line([(center_x - v_width // 2 + i, h_center_y + i), 
                         (center_x - v_width // 2 + h_width + i, h_center_y + i)],
                        fill=(255, 255, 255, alpha), width=1)
        
        highlight = highlight.filter(ImageFilter.GaussianBlur(radius=2))
        img = Image.alpha_composite(img, highlight)
    
    return img

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    sizes = {
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-192.png': 192,
        'web/favicon.png': 32,
        'assets/icon.png': 512,
    }
    
    print("🎨 Generating Vault logos...")
    
    for path, size in sizes.items():
        full_path = os.path.join(script_dir, path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
        logo = create_logo(size)
        logo.save(full_path, 'PNG', optimize=True)
        print(f"  ✓ {path} ({size}x{size})")
    
    print("\n✅ All logos generated!")

if __name__ == '__main__':
    main()
