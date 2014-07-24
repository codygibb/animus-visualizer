import ddf.minim.*;
import java.util.*;
import java.io.*;
import ddf.minim.analysis.*;

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
    abstract int getOptimalFrameRate();
    
    // basic processing draw function, called every frame
    abstract void draw();

    // the following 3 methods must implement 3 different views of the visualizer
    // by manually moving the camera (see Camera's initMoveCamera method).
    // these methods will be called with key presses 'f', 'r', and 't' respectively
    // NOTE: the logical handling of switching different views is handled in the
    // keyPressed() method of Visualizer, all these methods should ONLY implement the physical
    // moving of the camera.
    boolean frontView, rearView, topView;
    abstract void frontView();
    abstract void rearView();
    abstract void topView();
    abstract void autoPan();

    
    // implements particle mode (should just be switching boolean particles on/off)
    boolean particles;
    abstract void particles();

    // particle mode can be a little too intense for some computers, so the first time
    // particle mode is called for each visualizer, Animus will sample 1000ms of 
    // the framerate (at the max particle num), then call adjustDetail, passing in the
    // average framerate. You can then use that info, in adjustDetail, to lower the number
    // of particles in a specific visualizers implementation of particle-mode
    boolean sampleParticleMode;
    abstract void adjustDetail(float avgFr);

    // the following 3 methods must implement the 3 basic "drop levels" of a visualizer.
    // usually this is just switching the booleans highlight, expand, and revolve on/off,
    // then using these booleans in the code that draws the Visualizer to determine what
    // should be drawn every frame
    boolean highlight, expand, revolve, pause, followMouse;
    abstract void highlight();
    abstract void expand();
    abstract void revolve();
    abstract void pause();

    void setup() {}
    
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
    
    void retrieveSound() {
        beat.detect(input.mix);
        fft.forward(input.mix);
        volumeScale = pow(10, sliderVal);
    }

    // calculates avg frame rate over TOTAL_SAMPLE_TIME. returns avg frame rate when done
    // sampling. returns 0 if still sampling. returns -1 if has already sampled.
    float sampleFrameRate() {
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
            // println("avg particle framerate: " + totalFrameRate / frameRateSampleNum + " (" + name + ")");
            return totalFrameRate / frameRateSampleNum;
        }
    }

    // Call at the beginning of draw to setup background
    // backgroundColor is on gray scale from 0 to 255
    // opacity is on a scale from 0 to 255, where 0 is the max amt of blur, and
    // 255 is no blur at all
    void setBackground(int backgroundColor, int opacity) {
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
        opacityFade = lerp(opacityFade, opacity, .05);
        fill(backgroundColor, (int)opacityFade);
        rect(0, 0, width, height);
        hint(ENABLE_DEPTH_TEST);
        fill(255);
        if (backgroundColor == 0) {
            blendMode(SCREEN);
        } else {
            blendMode(DIFFERENCE);
        }
        hint(DISABLE_DEPTH_MASK);
    }
    
    // given an intensity, a peak (max intensity), and two ColorTrackers, calculates and returns an
    // array of colors, {red, green, blue, alpha} that represents the shift from the colors of the
    // baseTracker to the colors of the peakTracker. the alpha value is based on the instensity 
    // so that the baseTracker's colors will appear darker/fainter. ignore it as needed
    float[] getColor(float intensity, int peak, ColorTracker baseTracker, ColorTracker peakTracker) {
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

    float bindRange(float k, float min, float max) {
        if (k < min) {
            return min;
        } else if (k > max) {
            return max;
        } else {
            return k;
        }
    }

    void displayDebugText() {
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
    void displayHelpMenu(boolean showInterface) {
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

    void toggleTextColor(boolean toggled) {
        if (toggled) {
            fill(255, 100, 100);
        } else {
            fill(abs(150-contrast), abs(150-contrast), abs(150-contrast));
        }
    }

    // returns intensity of a certain index within the bandsize, and scales it with volumeScale
    float getIntensity(int index) {
        return abs(fft.getBand(index) * volumeScale * (PHI-1));
    }

    float getGreatestMag(int maxFreq) {
        float greatestMag = 0;
        for (int i = 0; i < maxFreq; i++) {
            float tempMag = getIntensity(i);
            if (tempMag > greatestMag) {
                greatestMag = tempMag;    
            }    
        }
        return greatestMag;
    }

    void fPressed(){
        if (frontView) return;
        camera.disableAllModes();
        frontView = !frontView;
        frontView();
        rearView = false;
        topView = false;
        followMouse = false;
    }

    void aPressed(){
        camera.autoPanSwitch();
        camera.dirSwitch();
        autoPan();
        rearView = false;
        topView = false;
        frontView = false; 
        followMouse = false;       
    }
    void rPressed(){
        if (rearView) return;
        camera.disableAllModes();
        rearView = !rearView;
        rearView();
        topView = false;
        frontView = false;
        followMouse = false;
    }

    void tPressed(){
        if (topView) return;
        camera.disableAllModes();
        topView = !topView;
        topView();
        rearView = false;
        frontView = false;    
        followMouse = false;    
    }

    void mPressed(){
        followMouse = !followMouse;
        // camera.viewSwitch();
        camera.disableAllModes();
        rearView = false;
        topView = false;
        frontView = false;
        if (!followMouse) {
            if (this instanceof Droplet) {
                aPressed();
            } else {
                fPressed();
            }
        }
    }

    void keyPressed() {
        switch (key) {
            // showInterface toggle handled in Animus due to not being able to
            // use static variables (processing fucking sucks!)
            case ' ':
                pause();
                followMouse = pause;
                mouseX = width/2;
                mouseY = height/2;
                break;
            // invert toggle handled in Animus
            case 'm':
                mPressed();
                break;
            case 's':
                aPressed();
                break;
            case 'a':
                fPressed();
                break;
            case 'd':
                rPressed();
                break;
            case 'w':
                tPressed();
                break;
            case 'b':
                blur = !blur;
                break;
            case 'M':
                mPressed();
                break;
            case 'S':
                aPressed();
                break;
            case 'A':
                fPressed();
                break;
            case 'D':
                rPressed();
                break;
            case 'W':
                tPressed();
                break;
            case 'B':
                blur = !blur;
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
            case '4':
                particles();
                if (!sampleParticleMode) {
                    sampleParticleMode = true;
                }
                break;
            default:
                break;
        }
    }
}
