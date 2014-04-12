import ddf.minim.*;
import g4p_controls.*;
import java.util.*;

final float PHI = (1.0 + sqrt(5.0)) / 2.0;

Minim minim;
AudioInput input;
Visualizer[] visualizers;
int select;
float lastMouseX;
float lastMouseY;
float lastMillis;
GCustomSlider volSlider;
PFont font;
PageDot[] dots;
boolean showInterface;
int contrast;

void setup() {
    size(displayWidth, displayHeight, P3D);
    minim = new Minim(this); 
    font = loadFont("AndaleMono-14.vlw");
    textFont(font);
    background(0);
    showInterface = true;
    Visualizer ring, fluid, droplet;
    
    AudioInput input = minim.getLineIn(Minim.STEREO, 512);
    
    ring = new Ring(input);
    fluid = new Fluid(input);
    droplet = new Droplet(input);
  
    visualizers = new Visualizer[] {ring, fluid, droplet};
    select = 0;
    frameRate(visualizers[select].getOptimalFrameRate());
    ellipseMode(CENTER);
    ellipseMode(RADIUS);
    dots = new PageDot[visualizers.length];
    float dist = 10;
    for (int i = 0; i < dots.length; i++) {
        float w = (dots.length) * dist - (dist / 2);
        float dx = (width / 2 - w) + (2 * dist * i + (dist / 2));
        dots[i] = new PageDot(dx, height - dist * 2, dist / 2, visualizers[i].name);
    }
    
    volSlider = new GCustomSlider(this, 20, 20, 300, 10, "blue18px");
    volSlider.setLimits(0.0, -2.0, 2.0);
    
    visualizers[select].setup();
}

void draw() {
    pushStyle();
    pushMatrix();
        
    visualizers[select].draw();
    blendMode(BLEND);
        
    popMatrix();
    popStyle();
    
    noLights();

    contrast = visualizers[select].contrast;
    if (showInterface) {
        volSlider.setVisible(true);
        for (int i = 0; i < dots.length; i++) {
            if (i == select) {
                fill(255 - contrast);
            } else {
                fill(contrast);
            }
            if (dots[i].overDot) {
                textSize(12);
                textAlign(CENTER, TOP);
                fill(255 - contrast);
                text(dots[i].name, dots[i].x, dots[i].y - 20);
            }
            dots[i].update();
        }
        visualizers[select].displayHelpMenu(showInterface);
        visualizers[select].displayDebugText();
    } else {
        volSlider.setVisible(false);
    }
}

class PageDot {
    float x, y, radius;
    String name;
    boolean overDot;

    PageDot(float x, float y, float radius, String name) {
        this.x = x;
        this.y = y;
        this.radius = radius;
        this.name = name; 
        overDot = false;
    }    
    
    void update() {
        float dx = x - mouseX;
        float dy = y - mouseY;
        stroke(255 - contrast);
        if (sqrt(sq(dx) + sq(dy)) < (radius + 2)) {
            overDot = true;
            strokeWeight(3);
        } else {
            overDot = false;
            strokeWeight(1);
        }
        ellipse(x, y, radius, radius);
    }
}

void mousePressed() {
    for (int i = 0; i < dots.length; i++) {
        if (dots[i].overDot) {
            select = i;
            break;
        }
    }        
}

void checkMouse() {
    if (mouseX != lastMouseX && mouseY != lastMouseY) {
        lastMouseX = mouseX;
        lastMouseY = mouseY;
        lastMillis = millis();
        cursor();
    } else if (millis() - lastMillis > 1500) {
        noCursor();
    } 
}

void switchVisualizer() {
    visualizers[select].setup();
    frameRate(visualizers[select].getOptimalFrameRate());
}

void keyPressed() {
    switch (key) {
        case 'h':
            showInterface = !showInterface;
            break;
        default:
            break;
    }
    switch (keyCode) {
        case 37: // left arrow key
            select--;
            if (select < 0) {
                select = visualizers.length - 1;
            }
            switchVisualizer();
            break;
        case 39: // right arrow key
            select++;
            select %= visualizers.length;
            switchVisualizer();
            break;
        default:
            break;
    }
    visualizers[select].keyPressed();
}

void stop() {
    input.close();
    minim.stop();
    super.stop();
}
