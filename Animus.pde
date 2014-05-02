import ddf.minim.*;
import controlP5.*;
import java.util.*;

final float PHI = (1.0 + sqrt(5.0)) / 2.0;
final int FONT_SIZE = 12;
final int TEXT_OFFSET = 20;

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
CheckBox highlight, expand, revolve, particles, front, rear, top, autoPan, viewing, blur, invert;
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
    PFont pfont = createFont("whitrabt.ttf", FONT_SIZE, true);
    ControlFont cFont = new ControlFont(pfont, FONT_SIZE);
    textFont(pfont);
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
    float dist = 13;
    for (int i = 0; i < dots.length; i++) {
        float w = (dots.length) * dist - (dist / 2);
        float dx = (width / 2 - w) + (2 * dist * i + (dist / 2));
        dots[i] = new PageDot(dx, height - dist * 2, dist / 2, visualizers[i].name);
    }
    buttons = new CheckBox[11];
    cp5 = new ControlP5(this);
    guiSetup(cFont);
    visualizers[select].setup();
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
            strokeWeight(1.2);
        }
        ellipse(x, y, radius, radius);
    }
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
    
    if (showInterface) {
        boolean handOn = false;
        if (cp5.isMouseOver()) {
            handOn = true;
        }
        volSlider.setVisible(true);
        interfaceLabel.setVisible(true);
        for (int i = 0; i < buttons.length; i++) {
            buttons[i].setVisible(true);
        }
        for (int i = 0; i < dots.length; i++) {
            if (i == select) {
                fill(255 - contrast);
            } else {
                fill(contrast);
            }
            dots[i].update();
            if (dots[i].overDot) {
                // textSize(FONT_SIZE);
                handOn = true;
                textAlign(CENTER, TOP);
                fill(255 - contrast);
                text(dots[i].name, dots[i].x, dots[i].y - TEXT_OFFSET - dots[i].radius);
            }
        }
        textAlign(CENTER, TOP);
        fill(255 - contrast);
        text(visualizers[select].name, displayWidth / 2, TEXT_OFFSET);
        if (debugMode) {
            visualizers[select].displayDebugText();
        }
        if (handOn) {
            cursor(HAND);
        } else {
            cursor(ARROW);
        }
    } else {
        checkMouse();
        volSlider.setVisible(false);
        for(int i = 0; i < buttons.length; i++) {
            buttons[i].setVisible(false);
        }
        volSlider.setVisible(false);
        interfaceLabel.setVisible(false);
    }
    if (visualizers[select].sampleParticleMode) {
        float avgFr = visualizers[select].sampleFrameRate();
        if (avgFr > 0) {
            visualizers[select].adjustDetail(avgFr);
        }
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
        cursor(ARROW);
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
    buttons[0].setArrayValue(visualizers[select].highlight ? on : off);
    buttons[1].setArrayValue(visualizers[select].expand ? on : off);
    buttons[2].setArrayValue(visualizers[select].revolve ? on : off);
    buttons[3].setArrayValue(visualizers[select].particles ? on : off);
    buttons[4].setArrayValue(visualizers[select].frontView ? on : off);
    buttons[5].setArrayValue(visualizers[select].rearView ? on : off);
    buttons[6].setArrayValue(visualizers[select].topView ? on : off);
    buttons[7].setArrayValue(visualizers[select].camera.autoPanningMode ? on : off);
    buttons[8].setArrayValue(visualizers[select].camera.viewingMode ? on : off);
    buttons[9].setArrayValue(visualizers[select].blur ? on : off);
}

void guiSetup(ControlFont font){
    volSlider = cp5.addSlider("sliderVal")
           .setLabel("Input Volume")
           .setRange(-2.0, 2.0)
           .setValue(0)
           .setPosition(TEXT_OFFSET, TEXT_OFFSET)
           .setSize(250, FONT_SIZE);
    interfaceLabel = cp5.addTextlabel("label")
            .setText("PRESS [H] TO HIDE INTERFACE")
            .setFont(font)
            .setPosition(width - 216, TEXT_OFFSET);
    interfaceLabel.getCaptionLabel().setSize(FONT_SIZE);
            
    volSlider.captionLabel().setFont(font).setSize(FONT_SIZE);
    buttons[0] = highlight = cp5.addCheckBox("highlight").addItem("highlight [1]", 0);
    buttons[1] = expand = cp5.addCheckBox("expand").addItem("expand [2]", 0);
    buttons[2] = revolve = cp5.addCheckBox("revolve").addItem("revolve [3]", 0);
    buttons[3] = particles = cp5.addCheckBox("particles").addItem("particles [p]", 0);
    buttons[4] = front = cp5.addCheckBox("front").addItem("front view [f]", 0);
    buttons[5] = rear = cp5.addCheckBox("rear").addItem("rear view [r]", 0);
    buttons[6] = top = cp5.addCheckBox("top").addItem("top view [t]" , 0);
    buttons[7] = autoPan = cp5.addCheckBox("autoPan").addItem("autopan camera [a]", 0);
    buttons[8] = viewing = cp5.addCheckBox("viewing").addItem("follow mouse [m]", 0);
    buttons[9] = blur = cp5.addCheckBox("blur").addItem("blur [b]", 0);
    buttons[10] = invert = cp5.addCheckBox("invert").addItem("invert [i]", 0);
    float startHeight = TEXT_OFFSET;
    for (int i = 0; i < buttons.length; i++) {
        if (i == 4) {
            startHeight = TEXT_OFFSET + 10;
        } else if (i == 9) {
            startHeight = TEXT_OFFSET + 20;
        }
        buttons[i].setPosition(width - 212, startHeight + (1 + i) * 17)
                .setSize(15, 15);
        buttons[i].getItem(0).captionLabel().setFont(font).setSize(FONT_SIZE);
    }
    setGuiColors();
}

void setGuiColors() {
    for (CheckBox button : buttons) {
        button.setColorLabel(color(255 - contrast));
    }
    volSlider.setColorLabel(color(255 - contrast));
    interfaceLabel.setColor(color(255 - contrast));
}

void controlEvent(ControlEvent theEvent) {
    if (theEvent.isFrom(highlight)) {
        visualizers[select].highlight();
    } else if (theEvent.isFrom(expand)) {
        visualizers[select].expand();
    } else if (theEvent.isFrom(revolve)) {
        visualizers[select].revolve();
    } else if (theEvent.isFrom(particles)) {
        visualizers[select].particles();
    } else if (theEvent.isFrom(front)) {
        visualizers[select].fPressed();
    } else if (theEvent.isFrom(rear)) {
        visualizers[select].rPressed();
    } else if (theEvent.isFrom(top)) {
        visualizers[select].tPressed();
    } else if (theEvent.isFrom(autoPan)) {
        visualizers[select].aPressed();
    } else if (theEvent.isFrom(viewing)) {
        visualizers[select].mPressed();
    } else if (theEvent.isFrom(blur)) {
        visualizers[select].blur = !visualizers[select].blur;
    } else if (theEvent.isFrom(invert)) {
        visualizers[select].contrast = 255 - contrast;
        contrast = 255 - contrast;
        setGuiColors();
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
        case 'i':
            contrast = 255 - contrast;
            setGuiColors();
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
