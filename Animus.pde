// ozio mofo

import ddf.minim.*;
import g4p_controls.*;
import java.util.*;

Minim minim;
AudioInput input;
Visualizer[] visualizers;
int select;
float lastMouseX;
float lastMouseY;
float lastMillis;

GCustomSlider volSlider;
PImage sprite;
PFont font;

PageDot[] dots;

int contrast = 0;
boolean showInterface = true;

void setup() {
    size(displayWidth, displayHeight, P3D);
    minim = new Minim(this); 
    font = loadFont("AndaleMono-14.vlw");
    textFont(font);
    
    Visualizer ring, fluid, droplet, swarm, gravity, globe;
    
    ring = new Ring(minim.getLineIn(Minim.STEREO, 256));
    fluid = new Fluid(minim.getLineIn(Minim.STEREO, 512));
    droplet = new Droplet(minim.getLineIn(Minim.STEREO, 512));
//    swarm = new Swarm(minim.getLineIn(Minim.STEREO, 256));
////    gravity = new Gravity(minim.getLineIn(Minim.STEREO, 512));
//    globe = new Globe(minim.getLineIn(Minim.STEREO, 512));
    
    
    
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
//    print(fluid.testMethod());
}

void draw() {
    contrast = visualizers[select].contrast;
    pushStyle();
    if (visualizers[select].showInterface) {
        volSlider.setVisible(true);
        for (int i = 0; i < dots.length; i++) {
            if (i == select) {
                fill(255);
            } else {
                fill(0);
            }
            dots[i].update();
        }
    } else {
        volSlider.setVisible(false);
    }

    popStyle();
    
    pushStyle();
    pushMatrix();
        
        visualizers[select].draw();
        blendMode(BLEND);
        
    popMatrix();
    popStyle();
    
    noLights();
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
    visualizers[select].showInterface = this.showInterface;
}

void keyPressed() {
    switch (key) {
        case 'x':
            for (int i = 0; i < visualizers.length; i++) {
                visualizers[i].initFlashingMode();    
            }
            break;
        default: break;
    }
    switch (keyCode) {
        case 37:
            select--;
            if (select < 0) {
                select = visualizers.length - 1;
            }
            switchVisualizer();
            frameRate(visualizers[select].getOptimalFrameRate());
            break;
        case 39:
            select++;
            select %= visualizers.length;
            switchVisualizer();
            frameRate(visualizers[select].getOptimalFrameRate());
            break;
        default: break;
    }
    visualizers[select].keyPressed();
}

void stop() {
    input.close();
    minim.stop();
    super.stop();
}
