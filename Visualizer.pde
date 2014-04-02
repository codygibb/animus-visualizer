import ddf.minim.*;
import java.util.*;
import java.io.*;
import ddf.minim.analysis.*;
// some random change

// more random changes!
public abstract class Visualizer {
    final int TEXT_OFFSET = displayWidth - 200;
    final int TEXT_SEPARATION = 15;
    final int TEXT_SIZE = 14;

    AudioInput input;
    AudioSource src;
    FFT fft;
    BeatDetect beat;
    Camera camera;
    int contrast = 0;
    String name;
    boolean flashingMode = false;
    float volumeScale = 0.0;

    boolean showInterface = true;
    boolean highlight, expand, revolve, blur, particles;
    
    abstract int getOptimalFrameRate();
    abstract void draw();

    abstract void highlight();
    abstract void expand();
    abstract void revolve();
    abstract void blur();
    abstract void particles();

    void setup() {}
    
    Visualizer(AudioInput input, String name) {
        this.input = input;
        src = (AudioSource)input;
        fft = new FFT(input.bufferSize(), input.sampleRate());
        int sensitivity = 300;
        beat = new BeatDetect(input.bufferSize(), input.sampleRate());
        beat.setSensitivity(sensitivity);    
        camera = new Camera();
        this.name = name;
    }
    
    //Call at the beginning of draw
    void retrieveSound() {
        beat.detect(input.mix);
        fft.forward(input.mix);
        volumeScale = pow(10, volSlider.getValueF());
    }
    
    void initFlashingMode() {
        flashingMode = !flashingMode;    
    }

    //Call at the beginning of draw to setup background
    //backgroundColor is on gray scale from 0 to 255
    void setBackground(int backgroundColor, int opacity) {
        hint(DISABLE_DEPTH_TEST);
        noStroke();
        if (flashingMode && beat.isKick()) {
            contrast = 255 - contrast;
            backgroundColor = contrast;    
        } 
        fill(backgroundColor, opacity);
        rect(0, 0, width, height);
        hint(ENABLE_DEPTH_TEST);
        fill(255);
        if (backgroundColor == 0) {
            blendMode(SCREEN);
        } else {
            blendMode(DIFFERENCE);
        }
    }

    void displayDebugText() {
        fill(255 - contrast);
        stroke(255 - contrast);
        textSize(14);
        text("current frame rate: " + round(frameRate), 5, height - 25);    
        text(camera.pos.x + ", " + camera.pos.y + ", " + camera.pos.z, 5, height - 10);
    }

    void displayHelpMenu() {
        textSize(TEXT_SIZE);
        textAlign(LEFT, TOP);

        Map<String, Boolean> menuMap = new LinkedHashMap<String, Boolean>();
        menuMap.put("[h] hide interface", !showInterface);
        menuMap.put("[d] dark mode", contrast == 0);
        menuMap.put("[b] blur", blur);
        menuMap.put("[p] particle mode", particles);
        menuMap.put("[1] highlight", highlight);
        menuMap.put("[2] expand", expand);
        menuMap.put("[3] revolve", revolve);

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
        return abs(fft.getBand(index) * 0.8 * volumeScale);
    }

    void keyPressed() {
        switch (key) {
            case 'h':
                showInterface = !showInterface;
                break;
            case 'd':
                contrast = 255 - contrast;
                break;
            case 'b':
                blur();
                break;
            case 'p':
                particles();
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
