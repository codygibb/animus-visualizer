import ddf.minim.*;
import controlP5.*;
import java.util.*;

final float PHI = (1.0 + sqrt(5.0)) / 2.0;

Minim minim;
AudioInput input;
Visualizer[] visualizers;
int select;
float lastMouseX;
float lastMouseY;
float lastMillis;
//Gui
ControlP5 cp5;
CheckBox[] buttons;
CheckBox highlight, expand, revolve, particles, front, rear, top, autoPan, viewing, blur;
Textlabel interfaceLabel;
Slider volSlider;
float sliderVal;

PFont font;
PageDot[] dots;
boolean showInterface;
boolean debugMode;
int contrast;

void setup() {
    size(displayWidth, displayHeight, P3D);
    minim = new Minim(this); 
    font = loadFont("AndaleMono-14.vlw");
    PFont pfont = createFont("AndaleMono-14.vlw",14,true);
    ControlFont cFont = new ControlFont(pfont,14);
    textFont(font);
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
    float dist = 15;
    for (int i = 0; i < dots.length; i++) {
        float w = (dots.length) * dist - (dist / 2);
        float dx = (width / 2 - w) + (2 * dist * i + (dist / 2));
        dots[i] = new PageDot(dx, height - dist * 2, dist / 2, visualizers[i].name);
    }
    buttons = new CheckBox[10];
    cp5 = new ControlP5(this);
    guiSetup(cFont);
    visualizers[select].setup();
}

void draw() {
    smooth(8);
    pushStyle();
    pushMatrix();
    
    visualizers[select].retrieveSound();
    visualizers[select].draw();
    updateGui();
    blendMode(BLEND);
        
    popMatrix();
    popStyle();
    
    noLights();

    contrast = visualizers[select].contrast;
    checkMouse();
    if (showInterface) {
        volSlider.setVisible(true);
        interfaceLabel.setVisible(true);
        for(int i = 0; i< buttons.length; i++){
            buttons[i].setVisible(true);
        }
        for (int i = 0; i < dots.length; i++) {
            if (i == select) {
                fill(255 - contrast);
            } else {
                fill(contrast);
            }
            if (dots[i].overDot) {
                textSize(14);
                textAlign(CENTER, TOP);
                fill(255 - contrast);
                text(dots[i].name, dots[i].x, dots[i].y - 30);
            }
            dots[i].update();
        }
        if(debugMode){
            visualizers[select].displayDebugText();
        }
    } else {
        volSlider.setVisible(false);
        for(int i = 0; i< buttons.length; i++) {
            buttons[i].setVisible(false);
        }
        volSlider.setVisible(false);
        interfaceLabel.setVisible(false);
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

void updateGui() {
    // visualizers[select].expand ? new int{1}: new int{0}
    float[] on = new float[]{1};
    float[] off = new float[]{0};
    buttons[0].setArrayValue(visualizers[select].highlight? on: off);
    buttons[1].setArrayValue(visualizers[select].expand? on: off);
    buttons[2].setArrayValue(visualizers[select].revolve? on: off);
    buttons[3].setArrayValue(visualizers[select].particles? on: off);
    buttons[4].setArrayValue(visualizers[select].frontView? on: off);
    buttons[5].setArrayValue(visualizers[select].rearView? on: off);
    buttons[6].setArrayValue(visualizers[select].topView? on: off);
    buttons[7].setArrayValue(visualizers[select].camera.autoPanningMode? on: off);
    buttons[8].setArrayValue(visualizers[select].camera.viewingMode? on: off);
    buttons[9].setArrayValue(visualizers[select].blur? on: off);
}

void guiSetup(ControlFont font){
    volSlider = cp5.addSlider("sliderVal")
           .setLabel("Input Volume")
           .setRange(-2.0,2.0)
           .setValue(0)
           .setPosition(20,20)
           .setSize(300,17);
    interfaceLabel = cp5.addTextlabel("label")
            .setText("PRESS [h] TO HIDE INTERFACE")
            .setFont(font)
            .setPosition(width-214, 10);
    interfaceLabel.getCaptionLabel().setSize(14);
            
    volSlider.captionLabel().setFont(font).setSize(14);
     buttons[0] = highlight = cp5.addCheckBox("highlight").addItem("Highlight [1]", 0);
     buttons[1] = expand = cp5.addCheckBox("expand").addItem("Expand [2]", 0);
     buttons[2] = revolve = cp5.addCheckBox("revolve").addItem("Revolve [3]", 0);
     buttons[3] = particles = cp5.addCheckBox("particles").addItem("Particles [p]", 0);
     buttons[4] = front = cp5.addCheckBox("front").addItem("Front View [f]", 0);
     buttons[5] = rear = cp5.addCheckBox("rear").addItem("Rear View [r]", 0);
     buttons[6] = top = cp5.addCheckBox("top").addItem("Top View [t]" , 0);
     buttons[7] = autoPan = cp5.addCheckBox("autoPan").addItem("Autopan Camera [a]", 0);
     buttons[8] = viewing = cp5.addCheckBox("viewing").addItem("Follow Mouse [m]", 0);
     buttons[9] = blur = cp5.addCheckBox("blur").addItem("Blur [b]", 0);
     float startHeight = 10;
     for(int i = 0; i < buttons.length; i++){
        if(i == 4){
            startHeight = 30;
        } else if(i == 9) {
            startHeight = 50;
        }
            buttons[i].setPosition(width-210, startHeight+(1+i)*30)
                   .setColorForeground(color(120))
                   .setColorActive(color(255))
                   .setColorLabel(color(255))
                   .setSize(25, 25);
            buttons[i].getItem(0).captionLabel().setFont(font).setSize(14);
     }
}

void controlEvent(ControlEvent theEvent) {
    if (theEvent.isFrom(highlight)) {
        visualizers[select].highlight();
    } else if(theEvent.isFrom(expand)){
        visualizers[select].expand();
    } else if(theEvent.isFrom(revolve)){
        visualizers[select].revolve();
    } else if(theEvent.isFrom(particles)){
        visualizers[select].particles();
    } else if(theEvent.isFrom(front)){
        visualizers[select].fPressed();
    } else if(theEvent.isFrom(rear)){
        visualizers[select].rPressed();
    } else if(theEvent.isFrom(top)){
        visualizers[select].tPressed();
    } else if(theEvent.isFrom(autoPan)){
        visualizers[select].aPressed();
    } else if(theEvent.isFrom(viewing)){
        visualizers[select].mPressed();
    } else if(theEvent.isFrom(blur)){
        visualizers[select].blur = !visualizers[select].blur;
    }
}

void keyPressed() {
    switch (key) {
        case 'D':
            debugMode = !debugMode;
            break;
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
