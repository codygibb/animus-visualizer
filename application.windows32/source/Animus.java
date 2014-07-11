import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import ddf.minim.*; 
import controlP5.*; 
import java.util.*; 
import ddf.minim.*; 
import ddf.minim.*; 
import ddf.minim.*; 
import ddf.minim.*; 
import java.util.*; 
import java.io.*; 
import ddf.minim.analysis.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Animus extends PApplet {





final float PHI = (1.0f + sqrt(5.0f)) / 2.0f;
final int FONT_SIZE = 14;
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
Textlabel[] buttonLabels;
CheckBox highlight, expand, revolve, particles, front, rear, top, autoPan, viewing, blur, invert;
Textlabel interfaceLabel;
Slider volSlider;
boolean load;
float sliderVal;
PImage logo;
PFont font;
PageDot[] dots;
boolean showInterface;
boolean debugMode;
float showIntro = 255;
float interfaceT;
int contrast;
PImage cam;

public void setup() {
    size(displayWidth, displayHeight, P3D);
    minim = new Minim(this); 
    PFont pfont = createFont("Courier", FONT_SIZE, true);
    ControlFont cFont = new ControlFont(pfont, FONT_SIZE);
    textFont(pfont);
    showInterface = true;
    Visualizer ring, fluid, droplet;
    logo = loadImage("Logo.png");
    AudioInput input = minim.getLineIn(Minim.STEREO, 512);
    cam = loadImage("Camera.png");
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
    buttonLabels = new Textlabel[11];
    cp5 = new ControlP5(this);
    guiSetup(cFont);

    visualizers[select].setup();
    background(0);
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
    
    public void update() {
        float dx = x - mouseX;
        float dy = y - mouseY;
        stroke(255 - visualizers[select].contrast);
        if (sqrt(sq(dx) + sq(dy)) < (radius + 2)) {
            overDot = true;
            strokeWeight(3);
        } else {
            overDot = false;
            strokeWeight(1.2f);
        }
        ellipse(x, y, radius, radius);
    }
}

public void draw() {
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
    if(showIntro == 0) {
        image(cam, width - 171, 208);
    }
    
    if (showInterface) {
        interfaceT = lerp(interfaceT, 255, .01f);
        tint(255, (int)interfaceT);
     
        boolean handOn = false;
        if (cp5.isMouseOver()) {
            handOn = true;
        }
        volSlider.setVisible(true);
        interfaceLabel.setVisible(true);
        for (int i = 0; i < buttons.length; i++) {
            buttons[i].setVisible(true);
        }
        for(int i = 0; i < buttonLabels.length; i++){
            buttonLabels[i].setVisible(true);

        }

        for (int i = 0; i < dots.length; i++) {
            if (i == select) {
                fill(255 - visualizers[select].contrast);
            } else {
                fill(visualizers[select].contrast);
            }
            dots[i].update();
            if (dots[i].overDot) {
                handOn = true;
                textAlign(CENTER, TOP);
                fill(255 - visualizers[select].contrast);
                text(dots[i].name, dots[i].x, dots[i].y - TEXT_OFFSET - dots[i].radius);
            }
        }
        textAlign(CENTER, TOP);
        fill(255 - visualizers[select].contrast);
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
        interfaceT = lerp(interfaceT, 0, .05f);
        tint(255, (int)interfaceT);
        volSlider.setVisible(false);
        volSlider.setVisible(false);
        for(int i = 0; i < buttonLabels.length; i++){
            buttonLabels[i].setVisible(false);
        }
        interfaceLabel.setVisible(false);
    }
    if(showIntro != 0){
        for(int i = 0; i < buttons.length; i++) {
            buttons[i].setVisible(false);
        }
        showIntro = (int)abs(showIntro - showIntro*.001f);
        showInterface = false; 
        fill(0, (int)showIntro);
        rect(0, 0, width, height);
        tint(255, (int)showIntro);
        // logo.resize(int(logo.width * (255/showIntro)), int(logo.height * (255/showIntro)));
        image(logo, width / 2 - logo.width / 2, height / 2-logo.height / 2);
        if(showIntro == 0) {
            showInterface = true;
        }
    }
    if (visualizers[select].sampleParticleMode) {
        float avgFr = visualizers[select].sampleFrameRate();
        if (avgFr > 0) {
            visualizers[select].adjustDetail(avgFr);
        }
    }
}

public void mousePressed() {
    for (int i = 0; i < dots.length; i++) {
        if (dots[i].overDot) {
            select = i;
            switchVisualizer();
            break;
        }
    }        
}

public void checkMouse() {
    if (mouseX != lastMouseX && mouseY != lastMouseY) {
        lastMouseX = mouseX;
        lastMouseY = mouseY;
        lastMillis = millis();
        cursor(ARROW);
    } else if (millis() - lastMillis > 1500) {
        noCursor();
    } 
}

public void switchVisualizer() {
    visualizers[select].setup();
    frameRate(visualizers[select].getOptimalFrameRate());
    setGuiColors();
}

public void updateGui() {
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
    // image(loadImage("Button.png"), mouseX, mouseY);
    // if(mousePressed){
    //     println(mouseX + " " + mouseY);
    // }
}

public void guiSetup(ControlFont font){
    volSlider = cp5.addSlider("sliderVal")
           .setLabel("Input Volume")
           .setRange(-2.0f, 2.0f)
           .setValue(0)
           .setPosition(TEXT_OFFSET, TEXT_OFFSET)
           .setSize(250, FONT_SIZE);
    interfaceLabel = cp5.addTextlabel("label")
            .setText("PRESS [H] TO HIDE INTERFACE")
            .setFont(font)
            .setPosition(width - 230, TEXT_OFFSET);
    interfaceLabel.getCaptionLabel().setSize(FONT_SIZE);

    volSlider.captionLabel().setFont(font).setSize(FONT_SIZE);
    buttons[0] = highlight = cp5.addCheckBox("highlight").addItem("highlight [1]", 0).setCaptionLabel("highlight [1]");
    buttonLabels[0] = cp5.addTextlabel("highlightT").setText("HIGHLIGHT [1]");
    buttons[1] = expand = cp5.addCheckBox("expand").addItem("expand [2]", 0);
    buttonLabels[1] = cp5.addTextlabel("expandT").setText("EXPAND [2]");
    buttons[2] = revolve = cp5.addCheckBox("revolve").addItem("revolve [3]", 0);
    buttonLabels[2] = cp5.addTextlabel("revolveT").setText("REVOLVE [3]");
    buttons[3] = particles = cp5.addCheckBox("particles").addItem("particles [p]", 0);
    buttonLabels[3] = cp5.addTextlabel("particlesT").setText("PARTICLES [p]");
    buttons[4] = front = cp5.addCheckBox("front").addItem("front view [f]", 0);
    // buttonLabels[4] = cp5.addTextlabel("frontT").setText("FRONT VIEW [f]");
    buttonLabels[4] = cp5.addTextlabel("frontT").setText("");
    buttons[5] = rear = cp5.addCheckBox("rear").addItem("rear view [r]", 0);
    // buttonLabels[5] = cp5.addTextlabel("rearT").setText("REAR VIEW [r]");
    buttonLabels[5] = cp5.addTextlabel("rearT").setText("");
    buttons[6] = top = cp5.addCheckBox("top").addItem("top view [t]" , 0);
    // buttonLabels[6] = cp5.addTextlabel("topT").setText("TOP VIEW [t]");
    buttonLabels[6] = cp5.addTextlabel("topT").setText("");
    buttons[7] = autoPan = cp5.addCheckBox("autoPan").addItem("autopan camera [a]", 0);
    buttonLabels[7] = cp5.addTextlabel("autoPanT").setText("");
    // buttonLabels[7] = cp5.addTextlabel("autoPanT").setText("AUTOPAN CAMERA [a]");
    buttons[8] = viewing = cp5.addCheckBox("viewing").addItem("follow mouse [m]", 0);
    buttonLabels[8] = cp5.addTextlabel("viewingT").setText("FOLLOW MOUSE [m]");
    buttons[9] = blur = cp5.addCheckBox("blur").addItem("blur [b]", 0);
    buttonLabels[9] = cp5.addTextlabel("blurT").setText("BLUR [b]");
    buttons[10] = invert = cp5.addCheckBox("invert").addItem("invert [i]", 0);
    buttonLabels[10] = cp5.addTextlabel("inbertT").setText("INVERT [i]");
    

    float startHeight = TEXT_OFFSET;
    PImage normal = loadImage("Button.png");
    PImage hover = loadImage("Button.png");
    PImage click = loadImage("ButtonPressed.png");
    for (int i = 0; i < buttons.length; i++) {
        if (i == 4) {
            startHeight = TEXT_OFFSET + 10;
        } else if (i == 9) {
            startHeight = TEXT_OFFSET + 20;
        }
        buttonLabels[i].setPosition(width - (212 - 30), PApplet.parseInt(startHeight + 5 + (1 + i) * 28))
            .setFont(font);
        buttons[i].setPosition(width - 212, startHeight + (1 + i) * 28)
            .setImages(normal, hover, click)
            .setSize(23, 23)
            .captionLabel().setFont(font).setSize(FONT_SIZE);
            // .updateSize()
            buttons[i].getItem(0).captionLabel().setFont(font).setSize(FONT_SIZE);
    }
    buttons[4].setPosition(width - 212, startHeight + (1 + 5) * 28); //front
    buttons[5].setPosition(width - 126, startHeight + (1 + 5) * 28); //rear
    buttons[6].setPosition(width - 172, startHeight + (1 + 3) * 28+20); //top
    buttons[7].setPosition(width - 172, startHeight + (1 + 7) * 28-20); //autoPan
    setGuiColors();
}

public void setGuiColors() {
    for (CheckBox button : buttons) {
        button.setColorLabel(color(255 - visualizers[select].contrast));
    }
    for (Textlabel label : buttonLabels) {  
        label.setColorLabel(color(255 - contrast));
    }
    volSlider.setColorLabel(color(255 - contrast));
    interfaceLabel.setColor(color(255 - contrast));
}

public void controlEvent(ControlEvent theEvent) {
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
        visualizers[select].contrast = 255 - visualizers[select].contrast;
        setGuiColors();
    }
}

class ScrollBar {
    int x;
    int y;
    float value;
    PImage backgroundImg;
    PImage midSection;
    PImage end;
    
    ScrollBar(int x, int y, String backgroundImg, String midSection, String end) {
        this.x = x;
        this.y = y; 
        this.backgroundImg = loadImage(backgroundImg);
        this.midSection = loadImage(midSection);
        this.end = loadImage(end);
        value = 0.5f;
    }
    
    public void update() {
        image(backgroundImg, x, y);
        
        float size = backgroundImg.width - value * backgroundImg.width;
        for(int i = 0; i < PApplet.parseInt(size-end.width/2); i++) {
            image(midSection, PApplet.parseInt(this.x+3 + i), this.y);
        }
        image(end, this.x+size, this.y);
    }
    
    public void mousePressed() {
        if(mouseX >= this.x && mouseX < this.x + this.backgroundImg.width &&
           mouseY >= this.y && mouseY < this.y + this.backgroundImg.height) {
               value = (this.x + this.backgroundImg.width - mouseX) / (1.0f *(this.x + this.backgroundImg.width));
           }
    }
}

public void keyPressed() {
    switch (key) {
        case 'D':
            debugMode = !debugMode;
            break;
        case 'h':
            showInterface = !showInterface;
            break;
        case 'i':
            visualizers[select].contrast = 255 - visualizers[select].contrast;
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

public void stop() {
    input.close();
    minim.stop();
    super.stop();
}
public class Camera {
    PVector pos; //current position of camera
    PVector center; //center view for camera
    PVector dir; //"up" of camera;
    
    PVector moveStart; //saves the initial panning coordinates
    PVector moveEnd; //ending panning coordinates
    boolean movingCamera; //boolean storing whether camera is panning
    int moveTime; //total time to move from moveStart to moveEnd
    int currentTime; //current time while panning
    
    PVector dirStart;
    PVector dirEnd;
    boolean movingDir;
    int mDirTime;
    int mDirCurrTime;
    
    PVector mCenterStart;
    PVector mCenterEnd;
    boolean movingCenter;
    int mCenterTime;
    int mCenterCurrTime;
    
    boolean viewingMode; //true: free panning on
    boolean autoPanningMode; //true: auto panning on
    boolean autoDirChangeMode;
    
    PVector leftOuterBounds; //leftmost x, y, z auto panning bounds (generally negative)
    PVector rightOuterBounds; //rightmost x, y, z auto panning bounds (generally positive)
    PVector leftInnerBounds;
    PVector rightInnerBounds;
    
    Camera(float initX, float initY, float initZ) {
        pos = new PVector(initX, initY, initZ);
        dir = new PVector(0, 1, 0);
        center = new PVector(0, 0, 0);
        moveStart = new PVector(width/2, height/2, height/2);
        moveEnd = new PVector(width/2, height/2, height/2);
        movingCamera = false;
        autoPanningMode = false;
        leftOuterBounds = new PVector(-2000, -2000, -2000);
        rightOuterBounds = new PVector(2000, 2000, 2000);
        leftInnerBounds = new PVector(0, 0, 0);
        rightInnerBounds = new PVector(0, 0, 0);
        viewingMode = true;
        mCenterStart = new PVector(0, 0, 0);
        mCenterEnd = new PVector(0, 0, 0);
        dirStart = new PVector(0, 0, 0);
        dirEnd = new PVector(0, 0, 0);
        movingCenter = false;
        autoDirChangeMode = false;
    }
    
    Camera() {
        this(width/2, height/2, height/2);
    }
    
    public void setCenter(float cx, float cy, float cz) {
        center = new PVector(cx, cy, cz);  
    }
    
    public void setOuterBounds(float lx, float ly, float lz, float rx, float ry, float rz) {
        leftOuterBounds = new PVector(lx, ly, lz);
        rightOuterBounds = new PVector(rx, ry, rz);
    }
    
    public void setInnerBounds(float lx, float ly, float lz, float rx, float ry, float rz) {
        leftInnerBounds = new PVector(lx, ly, lz);
        rightInnerBounds = new PVector(rx, ry, rz);
    }
    
    //switches autoPanningMode on/off, also turns viewingMode off
    public void autoPanSwitch() {
        autoPanningMode = !autoPanningMode;
        viewingMode = false;
    }
    
    //switches dir on/off, also turns viewingMode off
    public void dirSwitch() {
        autoDirChangeMode = !autoDirChangeMode;
        viewingMode = false;
    }
    
    //switches viewingMode on/off, also turns autoPanningMode off
    public void viewSwitch() {
        viewingMode = !viewingMode;
        if (viewingMode) {  
            disableAllModes();
            viewingMode = true;
        } else {
            disableAllModes();
        }
    }
    
    // disables and mode that is affecting camera movement / orientation
    public void disableAllModes() {
        viewingMode = false;
        autoPanningMode = false;
        autoDirChangeMode = false;
        movingCamera = false;
        movingDir = false;
        movingCenter = false;    
    }
    
    //pans camera to set destination at set time (100 apprx. equals 2 seconds)
    public void initMoveCamera(PVector destination, int time) {
        moveStart.x = pos.x;
        moveStart.y = pos.y;
        moveStart.z = pos.z;
        moveEnd = destination;
        moveTime = time;
        currentTime = 0;
        
        movingCamera = true;    
    }
    
    
    public void initMoveDir(PVector destination, int time) {
        dirStart.x = dir.x;
        dirStart.y = dir.y;
        dirStart.z = dir.z;
        dirEnd = destination;
        mDirTime = time;
        mDirCurrTime = 0;
        
        movingDir = true; 
    }
    
    public void initMoveCenter(float dx, float dy, float dz, int time) {
        mCenterStart.x = center.x;
        mCenterStart.y = center.y;
        mCenterStart.z = center.z;
        mCenterEnd = new PVector(dx, dy, dz);
        mCenterTime = time;
        mCenterCurrTime = 0;
  
        movingCenter = true;      
    }
    
    public void rotateCamera(float angleInc) {
        dir.rotate(angleInc);
    }
    
    public PVector pickRandomPoint() {
        float xf, yf, zf;
        float x1 = random(leftOuterBounds.x, leftInnerBounds.x);
        float x2 = random(rightInnerBounds.x, rightOuterBounds.x);
        if (random(1) > 0.5f)
            xf = x1;
        else
            xf = x2;
//            
//        float y1 = random(leftOuterBounds.y, leftInnerBounds.y);
//        float y2 = random(rightInnerBounds.y, rightOuterBounds.y);
//        if (random(1) > 0.5)
//            yf = y1;
//        else
//            yf = y2;
        yf = random(leftOuterBounds.y, rightOuterBounds.y);
            
        float z1 = random(leftOuterBounds.z, leftInnerBounds.z);
        float z2 = random(rightInnerBounds.z, rightOuterBounds.z);
        if (random(1) > 0.5f)
            zf = z1;
        else
            zf = z2;
//        xf = random(leftOuterBounds.x, rightOuterBounds.x);
//        yf = random(leftOuterBounds.y, rightOuterBounds.y);
//        zf = random(leftOuterBounds.z, rightOuterBounds.z);

        return new PVector(xf, yf, zf);           
    }
    
    public void integrate(int currentTime, int maxTime, PVector v, PVector start, PVector end) {
        float angle = (currentTime*1.0f / maxTime) * PI;

        float xAmp = ((end.x - start.x) * PI) / (2 * maxTime);
        float dx = xAmp*sin(angle);
        v.x += dx;
        
        float yAmp = ((end.y - start.y) * PI) / (2 * maxTime);
        float dy = yAmp*sin(angle);
        v.y += dy;
        
        float zAmp = ((end.z - start.z) * PI) / (2 * maxTime);
        float dz = zAmp*sin(angle);
        v.z += dz;
    }

    //must be called every frame
    public void update() {        
        if (viewingMode) {
            pos.x = map(mouseX, 0, width, leftOuterBounds.x, rightOuterBounds.x);
            pos.y = map(mouseY, 0, height, leftOuterBounds.y, rightOuterBounds.y);
        }
        
        if (autoPanningMode && !movingCamera) {
            int time = (int)random(frameRate*8, frameRate*12);
            PVector nextPos = pickRandomPoint();
            initMoveCamera(nextPos, time);
        }
        
        if (autoDirChangeMode && !movingDir) {
            int time;
            if (!autoPanningMode) {
                time = (int)random(frameRate*8, frameRate*12);    
            } else {
                time = moveTime;
            }
            float x = random(-1, 1);
            float y = random(-1, 1);
            float z = random(-1, 1);
            initMoveDir(new PVector(x, y, z), time);
        }
        
        if (movingCamera) {
            integrate(currentTime, moveTime, pos, moveStart, moveEnd);
            currentTime++;
            if (currentTime == moveTime) {
                movingCamera = false;    
            } 
        }
        
        if (movingDir) {
            integrate(mDirCurrTime, mDirTime, dir, dirStart, dirEnd);
            mDirCurrTime++;
            if (mDirCurrTime == mDirTime) {
                movingDir = false;
            } 
        }
        
        if (movingCenter) {
            integrate(mCenterCurrTime, mCenterTime, center, mCenterStart, mCenterEnd);
            mCenterCurrTime++;
            if (mCenterCurrTime == mCenterTime) {
                movingCenter = false;    
            } 
        }
        
        camera(pos.x, pos.y, pos.z, center.x, center.y, center.z, dir.x, dir.y, dir.z);
    }
    
}
public class ColorTracker {
    float deltaMax;
    float deltaMin;
    
    float red, green, blue;
    boolean incrRed, incrGreen, incrBlue;
    float dr, dg, db;

    ColorTracker(float redStart, float greenStart, float blueStart, float deltaMin, float deltaMax) {
        this.deltaMin = deltaMin;
        this.deltaMax = deltaMax;
        incrRed = true;
        incrBlue = false;
        incrGreen = false;
        red = redStart;
        green = greenStart;
        blue = blueStart;
        pickRandomDeltas();
    }    
    
    ColorTracker(float deltaMin, float deltaMax) {
        this(random(125, 255), random(0, 125), random(67, 200), deltaMin, deltaMax);
    }
    
    public void pickRandomDeltas() {
        dr = random(deltaMin, deltaMax);
        dg = random(deltaMin, deltaMax);
        db = random(deltaMin, deltaMax);
    }
    
    //call each frame to slowly change colors over time
    public void incrementColor() {
        if (red + blue + green < 255) {
            incrRed = true;
            incrBlue = true;
            incrGreen = true;
            pickRandomDeltas();
            
        } else if (red + blue + green > (255 * 2)) {
            incrRed = false;
            incrBlue = false;
            incrGreen = false; 
            pickRandomDeltas();
        }
        
        if (red > 255) {
            incrRed = false;
            dr = random(deltaMin, deltaMax);
        }
        if (blue > 255) {
            incrBlue = false;
            db = random(deltaMin, deltaMax);
        }
        if (green > 255) {
            incrGreen = false;
            dg = random(deltaMin, deltaMax);
        }
        if (red < 0) incrRed = true;
        if (blue < 0) incrBlue = true;
        if (green < 0) incrGreen = true;    
        
        if (incrRed) red += dr;
            else red -= dr;
        if (incrBlue) blue += db;
            else blue -= db;
        if (incrGreen) green += dg;
            else green -= dg;
    }
    
    public void pickRandomColor() {
        red = random(0, 255);
        green = random(0, 255);
        blue = random(0, 255);    
    }
    
    public void defineLights() {
        lightSpecular(red / 15, red / 15, red / 15);

        directionalLight(0, green / 8, blue / 4, 
                1, 0, 0);
        pointLight(min(red*2, 255), green / 4, blue / 4,
                200, -150, 0);

        pointLight(0, 0, blue,
                0, 150, 200);

        spotLight(255 - red, 255 - (green / 4), 255 - (blue / 4),
                0, 40, 200,
                0, -0.5f, -0.5f,
                PI/2, 1);

        directionalLight(0, 0, 0,
                -1, 0, 0);

    }
}


class Droplet extends Visualizer {
    public @Override
    int getOptimalFrameRate() {
        return 35;
    }
 
    final int SPEC_SIZE = 50;
    final int SPEC_WIDTH = 7;
    final int DETAIL = 6;
    final int PART_DETAIL = 12;
    final float DECAY = 0.25f; // DECAY = -y per frame
    final int MAX_DECAY = 100;
    final int PEAK = 40;
    final float EXPAND_RATE = 0.02f;
    final float HIGHLIGHT_POINT_STOP = 80;
    final float MIN_PART_SIZE = 2;
    final float MAX_PART_SIZE = 20;
    final float PART_SCALE = 0.5f;
    int dropletSize = 4;
    
    float currExpand = 0;

    // since we need 4 different color trackers -- base and peak colors for both
    // bottom and top halves -- stored all dem in an array
    // colorTrackers[0] -> base tracker for bottom half
    // colorTrackers[1] -> peak tracker for bottom half
    // colorTrackers[2] -> base tracker for top half
    // colorTrackers[3] -> peak tracker for top half
    ColorTracker[] colorTrackers;
    
    Ring[] rings;
    RotationTracker rotater;

    Droplet(AudioInput input) {
        super(input, "DROPLET");
        camera.pos = new PVector(0, 0, 400);
        float n = SPEC_SIZE * SPEC_WIDTH;
        camera.setOuterBounds(-n, -n * 1.2f, -n, n, n * 1.2f, n);
        camera.setInnerBounds(-n / 4, 0, - n / 4, n / 4, 0, n / 4);
        camera.viewSwitch();
        colorTrackers = new ColorTracker[4];
        for (int i = 0; i < colorTrackers.length; i++) {
            colorTrackers[i] = new ColorTracker(0.5f, 4);
        }
        rotater = new RotationTracker();
        rings = new Ring[SPEC_SIZE];
        setupDroplet();
    }
    
    public void setupDroplet() {
        // int detail = (particles) ? PART_DETAIL : DETAIL;

        for (int i = 0; i < rings.length; i++) {
            int radius = SPEC_WIDTH * (i + 1);
            // int pointNum = (particles) ?  detail : detail * (i + 1);
            int pointNum = dropletSize * (i + 1);
            int hpointNum = dropletSize * (i + 1) / 10;

            rings[i] = new Ring(radius, i, pointNum, hpointNum);
        }
        for (int i = rings.length - 1; i >= 0; i--) {
            for (int j = 0; j < rings[i].points.length; j++) {
                if (i != 0) {
                    rings[i].points[j].oneDeeper = rings[i].points[j].findNearestOneDeeper(i);
                }
            }
        }
    }
    
    class Ring {
        int index, expandTick;
        Point[] points;
        HighlightPoint[] hpoints;
        
        // allow HighlightPoints to access the same base fade that each ring has
        // (they will be doing some additional fading on top of that as well)
        float baseFade;
        
        // 0 index Ring has a boost in detail
        Ring(int radius, int index, int pointNum, int hpointNum) {
            this.index = index;
            expandTick = index;

            points = new Point[pointNum];
            for (int i = 0; i < points.length; i++) {
                float angle = TWO_PI * i / points.length;
                EPVector pos = new EPVector(radius, 0, 0);
                pos.rotateY(angle);
                points[i] = new Point(pos, index);
            }

            hpoints = new HighlightPoint[hpointNum];
            for (int i = 0; i < hpoints.length; i++) {
                float angle = random(0, TWO_PI);
                EPVector pos = new EPVector(radius, 0, 0);
                pos.rotateY(angle);
                float size = random(1, 3);
                float speed = random(0.8f, 1.1f);
                hpoints[i] = new HighlightPoint(pos, speed, size);
            }
        }

        //converts alpha value to a ratio and multplies every color by that ratio (lets us use blend modes)
        public void setColor(float[] colors) {
            float fade = max(colors[3], 30) / 255.0f;
            fade += currExpand;
            fade = min(fade, 1);

            // slightly fades the outer edges of the plane
            fade *= pow((SPEC_SIZE - index) * 1.0f / SPEC_SIZE, 5.0f / 6.0f);

            // set baseFade so that the HighlightPoints can access this fading when they have to set their
            // color
            baseFade = fade;
            
            stroke(colors[0] * fade, colors[1] * fade, colors[2] * fade); 
        }
        
        public void update() {
            expandTick--;
            // expandTick %= SPEC_SIZE;
            for (int i = 0; i < points.length; i++) {
                points[i].update(index, expandTick);
                points[i].botColors = getColor(-points[i].naturalY, PEAK, colorTrackers[0], colorTrackers[1]);
                points[i].topColors = getColor(-points[i].naturalY, PEAK, colorTrackers[2], colorTrackers[3]);
            }

            float incomingSignal = getIntensity(index) / 2;
            // float incomingSignal = getGreatestMag(SPEC_SIZE) / 3;
            for (HighlightPoint hp : hpoints) {
                hp.update(incomingSignal);
            }
        }
        
        // ydir is -1 or 1: determines whether the figure is draw top up or top down
        public void drawRing(int ydir) {
            noFill();

            float strokeFactor = (expand) ? 4 : 2;
            strokeWeight(1 + ((float) index) / SPEC_SIZE * strokeFactor);
            // strokeWeight(1.5);

            if (!particles) {
                beginShape(LINES);
            }

            for (int i = 0; i < points.length; i++) {
                Point curr = points[i % points.length];
                Point next = points[(i + 1) % points.length]; // last index -> zero index
                if (ydir > 0) {
                    setColor(curr.botColors);
                } else {
                    setColor(curr.topColors);
                }

                if (particles) {
                    drawParticle(curr, ydir);
                    drawParticle(next, ydir);
                } else {
                    vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    vertex(next.pos.x, next.pos.y * ydir, next.pos.z);
                }

                Point oneDeeper = points[i % points.length].oneDeeper;
                if (this.index != 0) {
                    if (particles) {
                        drawParticle(curr, ydir);
                    } else {
                        vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                    }
                    if (ydir > 0) {
                        setColor(oneDeeper.botColors);
                    } else {
                        setColor(oneDeeper.topColors);
                    }
                    if (particles) {
                        drawParticle(oneDeeper, ydir);
                    } else {
                        vertex(oneDeeper.pos.x, oneDeeper.pos.y * ydir, oneDeeper.pos.z);
                    }
                }
            }
            
            // if auto rotating, then draws an extra smaller ring before rotating again
            // (this makes sure that we don't have unconnected lines showing)
            if (this.index != 0) {
                for (int i = 0; i < rings[index - 1].points.length + 1; i++) {
                    Point curr = rings[index - 1].points[i % rings[index - 1].points.length];

                    // last index -> zero index
                    Point next = rings[index - 1].points[(i + 1) % rings[index - 1].points.length];
                    
                    if (ydir > 0) {
                        setColor(curr.botColors);
                    } else {
                        setColor(curr.topColors);
                    }
                    if (particles) {
                        drawParticle(curr, ydir);
                        drawParticle(next, ydir);
                    } else {
                        vertex(curr.pos.x, curr.pos.y * ydir, curr.pos.z);
                        vertex(next.pos.x, next.pos.y * ydir, next.pos.z);
                    } 
                }
            }

            if (!particles) {
                endShape();
            }

            float baseY = points[0].pos.y;
            float[] c = (ydir > 0) ? points[0].botColors : points[0].topColors;
            for (HighlightPoint hp : hpoints) {
                hp.drawHighlightPoint(baseY, ydir, c, baseFade);
            }
        }

        public void drawParticle(Point p, int ydir) {
            float weight = abs(p.naturalY) + abs(p.pos.y) * currExpand * 0.25f;
            strokeWeight(bindRange(weight * PART_SCALE, MIN_PART_SIZE, MAX_PART_SIZE));
            point(p.pos.x, p.pos.y * ydir, p.pos.z);
        }
    }
    
    class Point {
        EPVector pos;

        // always use point.expandedY , the expandedY will
        // store the natural y position of the point + whatever expansion amt we need.
        // obviously the expansion amt is zero when not expanding, so during those times
        // expandedY will just hold the natural y position
        float naturalY;

        // we are re-using the same samples to draw both bottom and top - but bottom and top need
        // different NON-COMPLEMENTARY colors. so each point keeps track of the two set of colors
        // it will display as
        float[] botColors;
        float[] topColors;

        Point oneDeeper;
        int index;
 
        Point(EPVector pos, int index) {
            this.pos = pos;
            naturalY = pos.y;
            this.index = index;
            oneDeeper = null; 
            botColors = new float[4];
            topColors = new float[4];   
        }
        
        public void update(int index, int expandTick) {
            if (naturalY < 0) {
                naturalY += DECAY + abs(naturalY / 20);
                naturalY = min(0, naturalY);
            }
            float incomingSignal = -1.5f * getIntensity(index);
            if (naturalY > incomingSignal) {
                naturalY = incomingSignal;    
            }
            pos.y = getExpandedY(expandTick);
        }
        
        // finds the equivalent Point to this Point that is located on a ring
        // one deeper than this Point's current ring
        // ringIndex must not equal zero
        public Point findNearestOneDeeper(int ringIndex) {
            int nearestIndex = 0;
            float closestDist = PVector.dist(pos, rings[ringIndex - 1].points[nearestIndex].pos);
            for (int i = 1; i < rings[ringIndex - 1].points.length; i++) {
                float currentDist = PVector.dist(pos, rings[ringIndex - 1].points[i].pos);
                if (currentDist < closestDist) {
                    nearestIndex = i;
                    closestDist = currentDist;
                }
            }
            return rings[ringIndex - 1].points[nearestIndex];
        }

        public float getExpandedY(int expandTick) {
            if (currExpand > 0) {
                // expandTick is decremented in update. keeps the sin wave moving forward.
                // "- currExpand * amp" shifts the planes vertically apart so the waves don't 
                // overlap
                float time = TWO_PI * expandTick / SPEC_SIZE * 1.3f;
                float amp = 40 * sqrt(index * 1.0f / SPEC_SIZE);
                return naturalY - currExpand * amp * sin(time) - currExpand * amp;
            } else {
                return naturalY;
            }
        }
    }

    class HighlightPoint {
        float speed, size;
        EPVector pos;
        boolean continueHighlighting;

        HighlightPoint(EPVector pos, float speed, float size) {
            this.speed = speed;
            this.size = size;
            this.pos = pos;
        }

        public void update(float intensity) {
            if (continueHighlighting) {
                pos.y -= intensity;
                pos.y -= speed;
            }
            if (abs(pos.y) >= HIGHLIGHT_POINT_STOP) {
                if (!highlight) {
                    continueHighlighting = false;
                }
                pos.y = 0;
                float angle = random(0, TWO_PI);
                pos.rotateY(angle);
            }
        }

        public void drawHighlightPoint(float baseY, float ydir, float[] colors, float baseFade) {
            if (continueHighlighting) {
                float fade = 1 - abs(pos.y) / HIGHLIGHT_POINT_STOP;
                fade *= baseFade;
                stroke((255 - colors[0]) * fade, (255 - colors[1]) * fade, (255 - colors[2]) * fade);

                strokeWeight(size * 4);
                point(pos.x, (baseY + pos.y) * ydir, pos.z);
            }
        }
    }
    
    public @Override
    void draw() {
        if (blur) {
            setBackground(contrast, 50);
        } else {
            setBackground(contrast, 150);
        }

        if (expand && currExpand < 1) {
            currExpand += EXPAND_RATE;
        } else if (!expand && currExpand > 0) {
            currExpand -= EXPAND_RATE;    
        }

        if (!expand && currExpand < 0) {
            currExpand = 0;
        }

        if (expand && currExpand > 1) {
            currExpand = 1;
        }

        pushMatrix();
        
            rotater.update();
            camera.update();

            for (ColorTracker ct : colorTrackers) {
                ct.incrementColor();
            }
        if (!pause) {
            for (int i = 0; i < rings.length; i++) {
                rings[i].update();
            }
        }
        
        // if the camera is above the figure, the bottom rings are drawn last. If the camera is below the figure,
        // the top rings are drawn last.
        if (camera.pos.y > 0) { 
            drawInOrder(1, -1);
        } else {
            drawInOrder(-1, 1);
        } 

        popMatrix();
    }
    
    public void drawInOrder(int front, int behind) {
        int mult;
        int order;
        for (int i = (rings.length - 1) * 2; i >= 0; i--) {
            if (i > rings.length - 1) {
                order = front;    
            } else {
                order = behind;    
            }

            // the first 5 rings are rotated together
            if (i % (rings.length - 1) > 5) {
                mult = i;
            } else {
                mult = 5;
            }
//            rotateZ(PI/2);
            rotateX(rotater.xRot * mult);
            rotateY(rotater.yRot * mult);
            rings[i % (rings.length - 1)].drawRing(order);
            rotateY(-rotater.yRot * mult);
            rotateX(-rotater.xRot * mult);
        }
    }

    public @Override
    void adjustDetail(float avgFr) {
        // TODO
    }

    public @Override
    void particles() {
        particles = !particles;
        blur = particles;
        setupDroplet();
        if (highlight) {
            for (Ring r : rings) {
                for (HighlightPoint hp : r.hpoints) {
                    hp.continueHighlighting = true;
                }
            }
        }
    }

    public @Override
    void highlight() {
        for (Ring r : rings) {
            for (HighlightPoint hp : r.hpoints) {
                hp.continueHighlighting = true;
            }
        }
        highlight = !highlight;
    }

    public @Override
    void expand() {
        expand = !expand;
    }

    public @Override
    void revolve() { 
        revolve = !revolve;
        rotater.autoSwitch();
        if (!revolve) {
            rotater.initRotate(0, 0, (int) frameRate * 10);    
        }
    }
    
    public @Override
    void frontView() {
        // camera.initMoveCamera(new PVector(0, 0, 400), (int) frameRate * 2);
        camera.initMoveCamera(new PVector(-350, 0, .0001f), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }
    
    public @Override
    void rearView() {
        camera.initMoveCamera(new PVector(10, 180, 0.001f), (int) frameRate * 2);
        // camera.initMoveCamera(new PVector(400, -300, 0), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }
    
    public @Override
    void topView() { 
        camera.initMoveCamera(new PVector(.001f, -400, 0), (int) frameRate * 2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate * 2);
    }

    public @Override
    void pause() {
        pause = !pause;
    }
    
    public @Override
    void keyPressed() {
        super.keyPressed();
        switch (keyCode) {
             case 38:
                 dropletSize++;;
                 setupDroplet();
                 break;
             case 40:
                 if (dropletSize > 1) {
                     dropletSize--;
                     setupDroplet();
                 }
                 break;
            default:
                break;
        }
    }
}
class EPVector extends PVector {
    PVector temp;
    EPVector(float x, float y, float z) {
        super(x, y, z);  
        temp = new PVector();     
    }
    
    EPVector() {
        super(0, 0, 0);   
        temp = new PVector();    
    }
    
    public void rotateX(float angle) {
        temp.x = super.y;
        temp.y = super.z;
        temp.rotate(angle);
        super.y = temp.x;
        super.z = temp.y;
    }
    
    public void rotateY(float angle) {
        temp.x = super.x;
        temp.y = super.z;
        temp.rotate(angle);
        super.x = temp.x;
        super.z = temp.y;
    }
    
    public void rotateZ(float angle) {
        temp.x = super.x;
        temp.y = super.y;
        temp.rotate(angle);
        super.x = temp.x;
        super.y = temp.y;
    }
    
    public void set(int x, int y, int z){
        super.x = x;
        super.y = y;
        super.z = z;
    }
}
 

class Fluid extends Visualizer {
    public @Override
    int getOptimalFrameRate() {
        return 40;
    }

    final int SPEC_SIZE = 30;
    final float SPEC_WIDTH = 5;
    final int HORIZ_SAMPLE_NUM = 80;
    final int VERT_SAMPLE_NUM = 30;
    final int REFRESH = 3;
    final float ANGLE_INC = 0.001f;
    final float MIN_PARTICLE_SIZE = 2;
    final float MAX_PARTICLE_SIZE = 20;

    // since we need 4 different color trackers -- base and peak colors for both
    // bottom and top halves -- stored all dem in an array
    // colorTrackers[0] -> base tracker for bottom half
    // colorTrackers[1] -> peak tracker for bottom half
    // colorTrackers[2] -> base tracker for top half
    // colorTrackers[3] -> peak tracker for top half
    ColorTracker[] colorTrackers;
    
    HorizSample[] horizSamples;
    VertSample[] vertSamples;
    boolean pause;
    float fluidXRot, fluidYRot;
    
    float currRot = 0;

    int particleDetailLoss = 1;
    
    Fluid(AudioInput input) {
        super(input, "FLUID");
        colorTrackers = new ColorTracker[4];
        for (int i = 0; i < colorTrackers.length; i++) {
            colorTrackers[i] = new ColorTracker(0.5f, 4);   
        }
        camera.setCenter(SPEC_SIZE * SPEC_WIDTH, 0, 0);
        horizSamples = new HorizSample[HORIZ_SAMPLE_NUM];
        vertSamples = new VertSample[VERT_SAMPLE_NUM];
        for (int i = 0; i < horizSamples.length; i++) {
            horizSamples[i] = new HorizSample(i * REFRESH, REFRESH, HORIZ_SAMPLE_NUM * REFRESH);
        }
        for (int i = 0; i < vertSamples.length; i++) {
            vertSamples[i] = new VertSample(i * REFRESH, REFRESH, VERT_SAMPLE_NUM * REFRESH);
        }
        camera.viewingMode = false;
        camera.pos = new PVector(SPEC_SIZE * SPEC_WIDTH, 0, -130);
        camera.setOuterBounds(0, -200, -200, SPEC_SIZE * SPEC_WIDTH * 2, 200, REFRESH * HORIZ_SAMPLE_NUM);
        noFill();
    }

    class Point {
        float x, y, z, intensity;

        // we are re-using the same samples to draw both bottom and top - but bottom and top need
        // different NON-COMPLEMENTARY colors. so each point keeps track of the two set of colors
        // it will display as
        float[] topColors;
        float[] botColors;

        public Point(float x, float y, float z) {
            this.x = x;
            this.y = y;
            this.z = z;
            topColors = new float[4];
            botColors = new float[4];
        }
    }

    class HorizSample {
        float pos, speed, stop;
        int index;
        Point[] points;

        HorizSample(float initPos, float speed, float stop) {
            this.speed = speed;
            this.stop = stop;
            index = (int) (initPos / speed);
            pos = initPos;
            points = new Point[SPEC_SIZE * 2];
            for (int i = 0; i < points.length; i++) {
                points[i] = new Point(i * SPEC_WIDTH, 0, 0);
            }
        }
        
        public void setColor(float fade, float[] colors) {
            stroke(colors[0] * fade, colors[1] * fade, colors[2] * fade);
            // fill(colors[0] * fade*.1, colors[1] * fade*.1, colors[2] * fade*.1);
        }        

        public void update() {

            pos += speed;  
            if (expand) {
                for (int i = 0; i < points.length; i++) {
                    points[i].y += pos / 40;
                }
            }
            if (pos >= stop) {
                for (int i = 0; i < points.length; i++) {
                    int fftIndex = (int)round(abs(points.length / 2.0f - i));
                    points[i].y = getIntensity(fftIndex);
                    points[i].intensity = getIntensity(fftIndex);

                    // see comment inside Point (above botColors and topColors)
                    // for explanation on wtf is going on here
                    points[i].botColors = getColor(points[i].intensity, 40, colorTrackers[0], colorTrackers[1]);
                    points[i].topColors = getColor(points[i].intensity, 40, colorTrackers[2], colorTrackers[3]);
                }
                pos = 0;
            }
        }

        public void drawLines(int ydir, float fade) {
            pushMatrix();

            if (pos > 0) {

                HorizSample currSample = this;
                int prevIndex;
                if (index == 0) {
                    prevIndex = horizSamples.length - 1;
                } else {
                    prevIndex = index - 1;
                }

                HorizSample prevSample = horizSamples[prevIndex];

                // strokeWeight cannot being changed while inside beginShape/endShape,
                // so we must use point() instead of vertex() when drawing particles
                if (!particles) {
                    beginShape(QUAD_STRIP);
                }

                float zEnd = prevSample.pos;
                float zStart = currSample.pos;
                float tempFade = fade;
                for (int i = 0; i < points.length; i++) {
                    float xStart = currSample.points[i].x;
                    float xEnd = prevSample.points[i].x;
                    float yStart = currSample.points[i].y * ydir;
                    float yEnd = prevSample.points[i].y * ydir;
                    if(!expand) { 
                        if (abs(yEnd - yStart) <= 1)
                            tempFade = .03f;
                        else
                            tempFade = fade * abs(1-(yEnd / volumeScale / (PHI-1) - yStart / volumeScale / (PHI-1))/5.0f);
                    }
                    if (ydir > 0) {
                        setColor(tempFade, points[i].botColors);
                    } else {
                        setColor(tempFade, points[i].topColors);
                    }

                    if (!particles) {
                        vertex(xStart, yStart, zStart);
                        vertex(xEnd, yEnd, zEnd);
                    } else if (i % particleDetailLoss == 0) {
                        if(!expand) {
                            strokeWeight(bindRange(currSample.points[i].intensity, MIN_PARTICLE_SIZE, MAX_PARTICLE_SIZE));
                        }
                        point(xStart, yStart, zStart);

                        strokeWeight(bindRange(prevSample.points[i].intensity, MIN_PARTICLE_SIZE, MAX_PARTICLE_SIZE));
                        point(xEnd, yEnd, zEnd);
                    // } else if (i % particleDetailLoss == 0) {
                    //     strokeWeight(bindRange(currSample.points[i].intensity, MIN_PARTICLE_SIZE, MAX_PARTICLE_SIZE));
                    //     point(xStart, yStart, zStart);
                    }
                }  

                if (!particles) {
                    endShape();
                }
            } 
            popMatrix();
        }
    }

    class VertSample {
        float pos, stop, speed;
        PVector[] points;
        boolean continueSampling;

        VertSample(float initPos, float speed, float stop) {
            pos = initPos;
            this.speed = speed;
            this.stop = stop;
            points = new PVector[SPEC_SIZE * 2];
            for (int i = 0; i < points.length; i++) {
                points[i] = new PVector(i * SPEC_WIDTH, 0);
            }
            continueSampling = false;
        }

        public void update() {
            pos += speed;
            if (pos >= stop) {
                for (int i = 0; i < points.length; i++) {
                    int fftIndex = abs(points.length / 2 - i);
                    points[i].y = getIntensity(fftIndex);
                }
                pos = 0;
                if (highlight) {
                    continueSampling = true;
                } else {
                    continueSampling = false;
                }
            }
        }

        public void drawLines(int ydir) {
            pushMatrix();

            translate(0, pos * ydir, 0);

            if (!particles) {
                beginShape(LINES);
            }

            for (int i = 0; i < points.length - 1; i++) {
                float weight = (!particles)
                    ? bindRange((points[i].y + points[i + 1].y) / 20, 1, 6)
                    : bindRange(points[i].y / 2, 1, MAX_PARTICLE_SIZE);

                strokeWeight(weight);
                if (!particles) {
                    vertex(points[i].x, points[i].y * ydir);
                    vertex(points[i + 1].x, points[i + 1].y * ydir);
                } else {
                    point(points[i].x, points[i].y * ydir);
                }
            }

            float weight = min((points[points.length - 2].y + points[points.length - 1].y) / 20, 6);
            strokeWeight(weight);
            if (!particles) {
                vertex(points[points.length - 2].x, points[points.length - 2].y * ydir);
                vertex(points[points.length - 1].x, points[points.length - 1].y * ydir);
            } else {
                point(points[points.length - 2].x, points[points.length - 2].y * ydir);
            }

            if (!particles) {
                endShape();
            }

            popMatrix();
        }
    }

    public @Override
    void draw() {
        if (blur) {
            setBackground(contrast, 80);
        } else {
            setBackground(contrast, 255);
        }
        
        camera.update();
    
        // --------------------------------------------------- Rotate Fluid
        if(revolve) {
            translate(0, 0, HORIZ_SAMPLE_NUM * REFRESH/2);
        } else {
            translate(SPEC_SIZE*SPEC_WIDTH, 0, HORIZ_SAMPLE_NUM * REFRESH/2);
        }
        if (pause) {
            fluidXRot = lerp(fluidXRot, map(mouseY/2, 0, height/2, -PI, PI), .05f);
            fluidYRot = lerp(fluidYRot, map(mouseX/2, 0, width/2, -PI, PI), .05f);
        } else {
            fluidXRot = lerp(fluidXRot, 0, .05f);
            fluidYRot = lerp(fluidYRot, 0, .05f);
        }
        rotateX(fluidXRot);
        rotateY(fluidYRot);
        if(revolve) {
            translate(0, 0, -HORIZ_SAMPLE_NUM * REFRESH/2);
        } else {
            translate(-SPEC_SIZE*SPEC_WIDTH, 0, -HORIZ_SAMPLE_NUM * REFRESH/2);
        }


        for (ColorTracker ct : colorTrackers) {
            ct.incrementColor();
        }
        noFill();
        pushMatrix();
    
        // makes sure vertical samples appear at the front of the figure
        if (revolve) {
            translate(0, 0, 170);
        }
        if (!pause) {
            if (revolve) {
                currRot += ANGLE_INC;
            } else {
                currRot = lerp(currRot, 0, PHI * 40 * ANGLE_INC);
            }

            for (int i = 0; i < VERT_SAMPLE_NUM; i++) {
                vertSamples[i].update();
            }
        }
        for (int i = 0; i < VERT_SAMPLE_NUM; i++) {
            VertSample s = vertSamples[i];
            if (s.continueSampling) {
                    rotateZ(currRot);
                float fade = 1 - s.pos / (VERT_SAMPLE_NUM * REFRESH);
                setComplementaryColor(fade, colorTrackers[0]);
                s.drawLines(1);
                setComplementaryColor(fade, colorTrackers[2]);
                s.drawLines(-1);
            }
        } 

        popMatrix();

        pushMatrix();

        strokeWeight(1);
        if (!pause){
            for (int i = 0; i < HORIZ_SAMPLE_NUM; i++) {
                horizSamples[i].update();
            }
        }
        for (int i = 0; i < HORIZ_SAMPLE_NUM; i++) {
            HorizSample s = horizSamples[i];
            int relativeIndex = (int) (s.pos / REFRESH);
            rotateZ(currRot * relativeIndex);

                
            if (expand) {
                float weight = map(s.pos, 0, s.stop, 0.8f, 5);
                strokeWeight(weight);
            }
            
            
            float fade;
            if (expand) {
                fade = 1 - s.pos / (HORIZ_SAMPLE_NUM * REFRESH) / 2;
            } else {
                fade = min(1 - s.pos / (HORIZ_SAMPLE_NUM * REFRESH), .3f);
                // if(1-s.pos == 1 || s.pos < 5) //sets only the front to full color
                //     fade = 1;
            }
            
            // for (int j = 0; j < s.points.length; j++) {
            //     if(s.points[j].y >= mag)
            //         fade = 1;
            // }
            s.drawLines(1, fade);
            s.drawLines(-1, fade);  
            rotateZ(-currRot * relativeIndex);
            
        }

        popMatrix();
    }
    
    public void setComplementaryColor(float fade, ColorTracker tracker) {
        stroke((255 - tracker.red) * fade, (255 - tracker.green) * fade, (255 - tracker.blue) * fade);
    }

    public @Override
    void adjustDetail(float avgFr) {
        if (avgFr < 25) {
            particleDetailLoss = 5;
        } else if (avgFr < 30) {
            particleDetailLoss = 4;
        } else if (avgFr < 35) {
            particleDetailLoss = 3;
        } else if (avgFr < 38) {
            particleDetailLoss = 2;
        }
        println(particleDetailLoss);
    }

    public @Override
    void particles() {
        particles = !particles;
        blur = particles;
    }

    public @Override
    void highlight() {
        highlight = !highlight;
    }

    public @Override
    void expand() {
        expand = !expand;
    }

    public @Override
    void revolve() { 
        revolve = !revolve;
        if (!revolve && currRot >= .082f) {
            currRot = .082f; //sets revolve to 1 full rotation
        }
        if(revolve) {
            camera.setOuterBounds(-SPEC_SIZE * SPEC_WIDTH, -200, -200, SPEC_SIZE * SPEC_WIDTH, 200, REFRESH * HORIZ_SAMPLE_NUM);
        } else {
            camera.setOuterBounds(0, -200, -200, SPEC_SIZE * SPEC_WIDTH * 2, 200, REFRESH * HORIZ_SAMPLE_NUM);
        }
        fPressed();
        frontView();
    }

    public @Override
    void pause() {
        pause = !pause;
    }

    public @Override
    void frontView() {
        float camX = SPEC_SIZE * SPEC_WIDTH;
        if (revolve) {
            camera.initMoveCenter(0, 0, 0, (int)frameRate);
            camX = 0;
        } else {
            camera.initMoveCenter(SPEC_SIZE * SPEC_WIDTH, 0, 0, (int)frameRate);
        }
        camera.initMoveCamera(new PVector(camX, 0, -130), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    public @Override
    void rearView() {
        float camX = SPEC_SIZE * SPEC_WIDTH;
        if (revolve) {
            camera.initMoveCenter(0, 0, 0, (int)frameRate);
            camX = 0;
        }
        camera.initMoveCamera(new PVector(camX, 0, 300), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    
    public @Override
    void topView() { 
        float camZ = HORIZ_SAMPLE_NUM * REFRESH/ 1.99f;
        float camY = -150;
        if (frontView) {
            camZ = HORIZ_SAMPLE_NUM * REFRESH / 2.1f;
            camY = 160;
        }
        
        if (revolve) {
            camera.initMoveCamera(new PVector(-150, camY, camZ), (int) frameRate * 2);
            camera.initMoveCenter(0, 0, HORIZ_SAMPLE_NUM * REFRESH / 2, (int) frameRate / 2);
        } else {
            camera.initMoveCamera(new PVector(150, camY, camZ), (int) frameRate * 2);
            camera.initMoveCenter(SPEC_SIZE * SPEC_WIDTH, 0, HORIZ_SAMPLE_NUM * REFRESH / 2, (int) frameRate);
        }
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }

}
 

class Ring extends Visualizer {
    public @Override
    int getOptimalFrameRate() {
        return 40;
    }
    
    final int SAMPLE_NUM = 180;
    final int SPEC_SIZE = 50;
    final float REFRESH = 2;
    final float ROT_SPEED = PI / 2800;
    final float DIST = PHI * 2; //PHI
    final float ADD_DIST = -10; //-10
    final float INIT_DIST = 20; // 10
    final float MAX_TIME = 2000; //in milliseconds
    final float MAX_SPEED = 0.2f;
    final float MIN_PART_SIZE = 2;
    final float MAX_PART_SIZE = 20;

    EPVector rotationVector; //handles rotating the verticies when revolve is turned on
    float xRot;
    float zRot;
    float explodeVal;

    // we will sample the framerate and adjust this as needed when particle mode is
    // initiated
    float particleDetailLoss = 0;
    
    float deltaRotation = PI / 2000;
    
    ColorTracker tracker;
    ColorTracker tracker2;
    Sample[] samples;
    
    float start = 0;
    float stop = 0;
    float averageSpeed = 0;
    boolean throttlingOn = false;
    
    public Ring(AudioInput input) {
        super(input, "RING");
        tracker = new ColorTracker(0.1f, 0.8f);
        tracker2 = new ColorTracker(0.1f, 0.8f);
        camera.viewingMode = false;
        camera.pos = new PVector(0, 0, -800);
        camera.setOuterBounds(-1000, -1000, -1000, 1000, 1000, 1000);
        rotationVector = new EPVector();
        setupRing();
        start = millis();
    }    

    public void setupRing(){
        samples = new Sample[SAMPLE_NUM];
        for (int i = 0; i < samples.length; i++) {
            samples[i] = new Sample(i * REFRESH, SAMPLE_NUM * REFRESH, SPEC_SIZE, i);
        }
    }
    
    // Samples are slices of the sound
    class Sample {
        Point[] points;
        float pos, stop, rot, rotSpeed;
        int index;
        
        Sample(float pos, float stop, int pointNum, int index) {
            this.pos = pos;
            this.stop = stop;
            this.index = index;
            
            points = new Point[pointNum];
            for (int i = 0; i < points.length; i++) {
                float angle = i * (TWO_PI / points.length);
                
                PVector p = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                int rotDir;
                if (i % 2 == 0) {
                    rotDir = 1;
                } else {
                    rotDir = -1;
                }
                
                points[i] = new Point(i, p, pow(points.length - i, 1.168f) * ROT_SPEED, rotDir);
            }
        }
        
        public void update() {
            pos += REFRESH;      
            
            boolean isNewPoint = false;
            float greatestMag = 0.0f;
            if (pos >= stop) {
                pos = 0;
                isNewPoint = true;
                if (highlight) {
                    greatestMag = getGreatestMag(100);
                }
            }
            
            for (int i = 0; i < points.length; i++) {
                Point p = points[i];
                p.updateRot();
                p.pos.z = pos;
                if (isNewPoint) {
                    float angle = i * (TWO_PI / points.length);
                    PVector temp2d = new PVector(0, INIT_DIST + DIST * pow((float)Math.E, angle));
                    temp2d.rotate(p.rot);
                    p.pos = new PVector(temp2d.x, temp2d.y, 0);
                    p.updateSnd(greatestMag);
                    if (highlight) {
                        p.strokeWeight = min(0.3f + p.size, 8);
                    } else {
                        p.strokeWeight = min(0.3f + p.size * 3, 30);
                    }   
                }
            } 
        }
        
        public void drawSample() {
            if (pos > 0 && pos < stop - REFRESH) {
                int prevIndex;
                if (index == 0) {
                    prevIndex = samples.length - 1;
                } else {
                    prevIndex = index - 1;
                }
                
                Sample prevSample = samples[prevIndex];
                
                if (revolve) {
                    xRot += .000001f;
                    zRot += .00001f;
                } else {
                    xRot = 0;
                    zRot = 0;
                }                    
                
                if (!particles) {
                    beginShape(LINES);
                }
                for (int i = 0; i < points.length; i++) {
                    points[i].drawPoint(pos, stop, prevSample.points[i], index);
                }
                if (!particles) {
                    endShape();
                } 
            } 
        }
    }
    
    class Point {
        int index, rotDir;
        PVector pos;
        float size, rotSpeed, rot, origMag, greatestMag, strokeWeight;
        float[] colors;
        
        Point(int index, PVector pos, float rotSpeed, int rotDir) {
            this.index = index;
            this.pos = pos;
            this.rotSpeed = rotSpeed;
            origMag = INIT_DIST + (new PVector(pos.x, pos.y)).mag();
            this.rotDir = rotDir;
            colors = new float[4];
        }
        
        public void updateRot() {
            rot += rotSpeed * rotDir;
        }
        
        public void updateSnd(float greatestMag) {
            this.greatestMag = greatestMag;
            size = getIntensity(index) * 0.9f;
            colors = getColor(pos.mag(), 200, tracker, tracker2);
        }
        
        public void drawPoint(float zpos, float stop, Point prevPoint, int sampleIndex) {
            float fade = pow((stop - zpos) / stop, 5.0f / 6.0f);

            stroke(colors[0] * fade, colors[1] * fade, colors[2] * fade);

            float magnitude = zpos * (ADD_DIST / stop);
            if (!pause) {
                if (prevPoint.pos.z == 0) {
                    PVector p = new PVector(pos.x, pos.y);             
                    if (highlight) {
                        float mag = origMag + abs(greatestMag);
                        p.setMag(mag);
                    }
                    pos.x = p.x;
                    pos.y = p.y;    
                } else {
                    pos.setMag(pos.mag() + magnitude);
                }
            }

            strokeWeight(strokeWeight);
            PVector prevPos = prevPoint.pos;
            float theta = TWO_PI * index / SPEC_SIZE;
            if (expand) {
                pos.y -= index / 3.0f;
            }
            rotationVector.set(pos.x, pos.y, pos.z);
            rotationVector.rotateX(theta * xRot);
            rotationVector.rotateZ(theta * zRot);

            if (!particles) {
                vertex(rotationVector.x, rotationVector.y, rotationVector.z);
            } else if (sampleIndex % particleDetailLoss == 0) {
                strokeWeight(bindRange(size * 10, MIN_PART_SIZE, MAX_PART_SIZE));
                point(rotationVector.x, rotationVector.y, rotationVector.z);
            }

            rotationVector.set(prevPos.x, prevPos.y, prevPos.z);
            rotationVector.rotateX(theta * xRot);
            rotationVector.rotateZ(theta * zRot);

            if (!particles) {
                vertex(rotationVector.x, rotationVector.y, rotationVector.z);
// <<<<<<< HEAD
//             } else if (sampleIndex % particleDetailLoss == 0) {
//                 strokeWeight(bindRange(size * 10, MIN_PART_SIZE, MAX_PART_SIZE));
//                 point(rotationVector.x, rotationVector.y, rotationVector.z);
// =======
// >>>>>>> FETCH_HEAD
            }
        }
    }

    public synchronized void draw() {
        if (blur) {
            setBackground(contrast, 40);
        } else { 
            setBackground(contrast, 150);
        }
       if (sampleParticleMode) {
           float avgFr = sampleFrameRate();
           if (avgFr > 0) {
               adjustDetail(avgFr);
           }
       }
        hint(ENABLE_DEPTH_MASK);
        tracker.incrementColor();
        tracker2.incrementColor();
        pushMatrix();

        camera.update();
        if (!pause) {
            if (millis() - start < stop) {
                averageSpeed = incrRot(deltaRotation);
                if (averageSpeed > MAX_SPEED || averageSpeed < -MAX_SPEED) {
                    throttlingOn = true;
                    deltaRotation = -deltaRotation;
                } else if (((averageSpeed < 0.015f && averageSpeed > 0) || (averageSpeed > -0.015f && averageSpeed < 0))
                        && throttlingOn) {
                    throttlingOn = false;   
                }
            } else {
                start = millis();
                stop = random(0, MAX_TIME);
                if (!throttlingOn) {
                    deltaRotation = -deltaRotation;
                }
            }
            
            for (int i = 0; i < samples.length; i++) {
                samples[i].update();
            }
        }

        hint(DISABLE_DEPTH_MASK);
        for (int i = 0; i < samples.length; i++) {
            samples[i].drawSample();
        }

        popMatrix();
    }

    // returns avg rotation of all points
    public float incrRot(float increment) {
        float total = 0;
        float count = 0;
        for (Sample sample : samples) {
            for (Point point : sample.points) {
                point.rotSpeed += increment;
                total += point.rotSpeed;   
                count++;     
            }
        }
        return total / count;
    }

    public @Override
    void adjustDetail(float avgFr) {
        if (avgFr < 30) {
            particleDetailLoss = 8;
        } else if (avgFr < 40) {
            particleDetailLoss = 6;
        } else if (avgFr < 45) {
            particleDetailLoss = 3;
        }
    }

    public @Override
    void particles() {
        particles = !particles;
        blur = particles;
    }

    public @Override
    void highlight() {
        highlight = !highlight;
        // if (!highlight) {
        //     REFRESH = 35;
        //     SAMPLE_NUM = height / 4;
        // } else {
        //     REFRESH = 2;
        //     SAMPLE_NUM = 180;
        // }
        // for (int i = 0; i < samples.length; i++) {
        //      samples[i].stop = SAMPLE_NUM * REFRESH;
        //      samples[i].pos *= REFRESH;
        // }
        setupRing();     
    }
 
    public @Override
    void expand() {
        expand = !expand;

    }
    
    public @Override
    void revolve(){
        revolve = !revolve;
            // camera.initMoveCamera(new PVector(0, 1300, 0), (int)frameRate*2);
        blur = revolve;
        if (topView) {
            camera.initMoveCamera(new PVector(0, -REFRESH * SAMPLE_NUM - 600, 0), (int)frameRate * 2);
        }
    }
    
    public @Override
    void frontView() {
        camera.initMoveCamera(new PVector(0, 0, -800), (int)frameRate*2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    public @Override
    void rearView() {
        camera.initMoveCamera(new PVector(0, 0, REFRESH * SAMPLE_NUM), (int)frameRate*2);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    public @Override
    void topView() {
        if(revolve) {
            camera.initMoveCamera(new PVector(0, 1300, 0), (int)frameRate*2);
            camera.initMoveCenter(0, 0, 0, (int)frameRate);
        } else {
            camera.initMoveCenter(0, 0, (REFRESH * SAMPLE_NUM), (int)frameRate);
            camera.initMoveCamera(new PVector(0, -285 , -5 ), (int)frameRate*2);
        }
    }

    public @Override
    void pause() {
        pause = !pause;
    }
    
    public void leftView(){
        camera.initMoveCamera(new PVector(-176, -121, 0), (int)frameRate*2);
        camera.initMoveCenter(0, 0, width/4, (int)frameRate);
    }
    
    public @Override
    void keyPressed() {
        super.keyPressed();
        if(key == 'l')
            leftView();
    }
}
class RotationTracker {
    float xRot, yRot, zRot, xStart, yStart,zStart, xEnd, yEnd, zEnd;
    boolean manualRotate, autoRotate, rotating;
    int currentTime, moveTime;
    
    RotationTracker() {
        xRot = 0;
        yRot = 0;
        zRot = 0;
        manualRotate = false;
        autoRotate = false;
        rotating = false;    
    }
    
    public void autoSwitch() {
        autoRotate = !autoRotate;
        manualRotate = false; 
    }
    
    public void manualSwitch() {
        manualRotate = !manualRotate;
        autoRotate = false;
        rotating = false;  
    }
    
    public void initRotate(float xDestination, float yDestination, int time) {
        initRotate(xDestination, xDestination, 0, time);
    }
    
    public void initRotate(float xDestination, float yDestination, float zDestination, int time) {
        xStart = xRot;
        yStart = yRot;
        zStart = zRot;
        xEnd = xDestination;
        yEnd = yDestination;
        zEnd = zDestination;
        moveTime = time; 
        currentTime = 0;
        rotating = true; 
    }
    
    public void update() {
        if (manualRotate) {
            xRot = map(mouseX, 0, width, 0, PI);    
            yRot = map(mouseY, 0, height, 0, PI); 
        }   
        
        if (autoRotate && !rotating) {
            float x = random(0, PI);
            float y = random(0, PI);
            float z = random(0, PI);
            float dist = sqrt(sq(x) + sq(y)+sq(z));
            int baseLine = (int) random(5 * frameRate, 10 * frameRate);
            int time = baseLine + (int)(75 * frameRate * (dist / PI));
            initRotate(x, y, z, time);
        }
        
        if (rotating) {
            float angle = (currentTime*1.0f / moveTime) * PI;

            float xAmp = ((xEnd - xStart) * PI) / (2 * moveTime);
            float dx = xAmp * sin(angle);
            xRot += dx;
            
            float yAmp = ((yEnd - yStart) * PI) / (2 * moveTime);
            float dy = yAmp * sin(angle);
            yRot += dy;
            
            float zAmp = ((zEnd - zStart) * PI) / (2 * moveTime);
            float dz = zAmp * sin(angle);
            zRot += dz;
            
            currentTime++;
            if (currentTime == moveTime) {
                rotating = false;    
            }
        }
    } 
}





public abstract class Visualizer {
    final int TEXT_OFFSET = displayWidth - 200;
    final int TEXT_SEPARATION = 15;
    final int TEXT_SIZE = 14;
    final float TOTAL_SAMPLE_TIME = 1000;

    AudioInput input;
    AudioSource src;
    FFT fft;
    BeatDetect beat;
    Camera camera;
    int contrast;
    String name;
    boolean flashingMode;
    float volumeScale;
    boolean blur;
    float opacityFade;
    float samplerStartTime;
    float totalFrameRate;
    int frameRateSampleNum;
    
    // visualizers must return what their optimal frame rate is. this is so that
    // faster computers will not go crazy and update the visualizer way too fast
    public abstract int getOptimalFrameRate();
    
    // basic processing draw function, called every frame
    public abstract void draw();

    // the following 3 methods must implement 3 different views of the visualizer
    // by manually moving the camera (see Camera's initMoveCamera method).
    // these methods will be called with key presses 'f', 'r', and 't' respectively
    // NOTE: the logical handling of switching different views is handled in the
    // keyPressed() method of Visualizer, all these methods should ONLY implement the physical
    // moving of the camera.
    boolean frontView, rearView, topView;
    public abstract void frontView();
    public abstract void rearView();
    public abstract void topView();

    
    // implements particle mode (should just be switching boolean particles on/off)
    boolean particles;
    public abstract void particles();

    // particle mode can be a little too intense for some computers, so the first time
    // particle mode is called for each visualizer, Animus will sample 1000ms of 
    // the framerate (at the max particle num), then call adjustDetail, passing in the
    // average framerate. You can then use that info, in adjustDetail, to lower the number
    // of particles in a specific visualizers implementation of particle-mode
    boolean sampleParticleMode;
    public abstract void adjustDetail(float avgFr);

    // the following 3 methods must implement the 3 basic "drop levels" of a visualizer.
    // usually this is just switching the booleans highlight, expand, and revolve on/off,
    // then using these booleans in the code that draws the Visualizer to determine what
    // should be drawn every frame
    boolean highlight, expand, revolve, pause;
    public abstract void highlight();
    public abstract void expand();
    public abstract void revolve();
    public abstract void pause();

    public void setup() {}
    
    Visualizer(AudioInput input, String name) {
        frontView = true;
        this.input = input;
        src = (AudioSource)input;
        fft = new FFT(input.bufferSize(), input.sampleRate());
        int sensitivity = 300;
        beat = new BeatDetect(input.bufferSize(), input.sampleRate());
        beat.setSensitivity(sensitivity);    
        camera = new Camera();
        this.name = name;
    }
    
    public void retrieveSound() {
        beat.detect(input.mix);
        fft.forward(input.mix);
        volumeScale = pow(10, sliderVal);
    }

    // calculates avg frame rate over TOTAL_SAMPLE_TIME. returns avg frame rate when done
    // sampling. returns 0 if still sampling. returns -1 if has already sampled.
    public float sampleFrameRate() {
        if (samplerStartTime == -1) {
            return -1;
        }

        if (samplerStartTime == 0) {
            samplerStartTime = millis();
        }

        if (samplerStartTime + TOTAL_SAMPLE_TIME >= millis()) {
            frameRateSampleNum++;
            totalFrameRate += frameRate;
            return -1;
        } else {
            samplerStartTime = -1;
            println("avg particle framerate: " + totalFrameRate / frameRateSampleNum + " (" + name + ")");
            return totalFrameRate / frameRateSampleNum;
        }
    }

    // Call at the beginning of draw to setup background
    // backgroundColor is on gray scale from 0 to 255
    // opacity is on a scale from 0 to 255, where 0 is the max amt of blur, and
    // 255 is no blur at all
    public void setBackground(int backgroundColor, int opacity) {
        hint(DISABLE_DEPTH_TEST);
        noStroke();
        if (flashingMode && beat.isKick()) {
            contrast = 255 - contrast;
            backgroundColor = contrast;    
        }

        // flashingMode overrides opacity in order to create more blur
        if (flashingMode) {
            opacity = 10;
        }
        opacityFade = lerp(opacityFade, opacity, .05f);
        fill(backgroundColor, (int)opacityFade);
        rect(0, 0, width, height);
        hint(ENABLE_DEPTH_TEST);
        fill(255);
        if (backgroundColor == 0) {
            blendMode(SCREEN);
        } else {
            blendMode(DIFFERENCE);
        }
    }
    
    // given an intensity, a peak (max intensity), and two ColorTrackers, calculates and returns an
    // array of colors, {red, green, blue, alpha} that represents the shift from the colors of the
    // baseTracker to the colors of the peakTracker. the alpha value is based on the instensity 
    // so that the baseTracker's colors will appear darker/fainter. ignore it as needed
    public float[] getColor(float intensity, int peak, ColorTracker baseTracker, ColorTracker peakTracker) {
        float red1 = baseTracker.red;
        float green1 = baseTracker.green;
        float blue1 = baseTracker.blue;
        float red2 = 255 - peakTracker.red;
        float green2 = 255 - peakTracker.green;
        float blue2 = 255 - peakTracker.blue;
        
        float shift2 = intensity / peak;
        float shift1 = 1 - shift2;
        
        float r = red1 * shift1 + red2 * shift2;
        float g = green1 * shift1 + green2 * shift2;
        float b = blue1 * shift1 + blue2 * shift2;
        float alpha = min(255 * shift2, 255);

        float[] result = {r, g, b, alpha};
        return result;
    }    

    public float bindRange(float k, float min, float max) {
        if (k < min) {
            return min;
        } else if (k > max) {
            return max;
        } else {
            return k;
        }
    }

    public void displayDebugText() {
        textSize(TEXT_SIZE);
        textAlign(LEFT, TOP);
        fill(255 - contrast);
        text("current frame rate: " + round(frameRate), 5, height - 25);    
        text(camera.pos.x + ", " + camera.pos.y + ", " + camera.pos.z, 5, height - 10);
    }

    // called by Animus (essentially main). since the displaying the help menu is global
    // to all visualizers, Animus handles that functionality and lets each Visualizer
    // know whether to display a help menu or not. we had to do it this way because
    // processing doesn't allow for static variables :(
    public void displayHelpMenu(boolean showInterface) {
        textSize(TEXT_SIZE);
        textAlign(LEFT, TOP);

        Map<String, Boolean> menuMap = new LinkedHashMap<String, Boolean>();
        menuMap.put("[h] hide interface", !showInterface);
        menuMap.put(" ", false);
        menuMap.put("Camera options:", false);
        menuMap.put("[a] auto panning mode", camera.autoPanningMode);
        menuMap.put("[v] free view mode", camera.viewingMode);
        menuMap.put("[f] front angle view", frontView);
        menuMap.put("[r] rear angle view", rearView);
        menuMap.put("[t] top-down view", topView);
        menuMap.put("  ", false);
        menuMap.put("Morph options:", false);
        menuMap.put("[1] highlight", highlight);
        menuMap.put("[2] expand", expand);
        menuMap.put("[3] revolve", revolve);
        menuMap.put("   ", false);
        menuMap.put("Screen options:", false);
        menuMap.put("[d] dark mode", contrast == 0);
        menuMap.put("[b] blur mode", blur);
        menuMap.put("[p] particle mode", particles);
        menuMap.put("[x] flashing mode", flashingMode);

        int i = 1;
        for (String textKey : menuMap.keySet()) {
            toggleTextColor(menuMap.get(textKey));
            text(textKey, TEXT_OFFSET, i * TEXT_SEPARATION);
            i++;
        }
    }

    public void toggleTextColor(boolean toggled) {
        if (toggled) {
            fill(255, 100, 100);
        } else {
            fill(abs(150-contrast), abs(150-contrast), abs(150-contrast));
        }
    }

    // returns intensity of a certain index within the bandsize, and scales it with volumeScale
    public float getIntensity(int index) {
        return abs(fft.getBand(index) * volumeScale * (PHI-1));
    }

    public float getGreatestMag(int maxFreq) {
        float greatestMag = 0;
        for (int i = 0; i < maxFreq; i++) {
            float tempMag = getIntensity(i);
            if (tempMag > greatestMag) {
                greatestMag = tempMag;    
            }    
        }
        return greatestMag;
    }

    public void fPressed(){
        if (frontView) return;
        camera.disableAllModes();
        frontView = !frontView;
        frontView();
        rearView = false;
        topView = false;
    }

    public void aPressed(){
        camera.autoPanSwitch();
        camera.dirSwitch();
        rearView = false;
        topView = false;
        frontView = false;        
    }
    public void rPressed(){
        if (rearView) return;
        camera.disableAllModes();
        rearView = !rearView;
        rearView();
        topView = false;
        frontView = false;
    }

    public void tPressed(){
        if (topView) return;
        camera.disableAllModes();
        topView = !topView;
        topView();
        rearView = false;
        frontView = false;        
    }

    public void mPressed(){
        camera.viewSwitch();
        
        rearView = false;
        topView = false;
        frontView = false;
    }

    public void keyPressed() {
        switch (key) {
            // showInterface toggle handled in Animus due to not being able to
            // use static variables (processing fucking sucks!)
            case ' ':
                pause();
                mouseX = width/2;
                mouseY = height/2;
                break;
            // invert toggle handled in Animus
            case 'm':
                mPressed();
                break;
            case 'a':
                aPressed();
                break;
            case 'f':
                fPressed();
                break;
            case 'r':
                rPressed();
                break;
            case 't':
                tPressed();
                break;
            case 'b':
                blur = !blur;
                break;
            case 'p':
                particles();
                if (!sampleParticleMode) {
                    sampleParticleMode = true;
                }
                break;
            case '1':
                highlight();
                break;
            case '2':
                expand();
                break;
            case '3':
                revolve(); 
                break;
            default:
                break;
        }
    }
}
    static public void main(String[] passedArgs) {
        String[] appletArgs = new String[] { "--full-screen", "--bgcolor=#0A0A0A", "--hide-stop", "Animus" };
        if (passedArgs != null) {
          PApplet.main(concat(appletArgs, passedArgs));
        } else {
          PApplet.main(appletArgs);
        }
    }
}
