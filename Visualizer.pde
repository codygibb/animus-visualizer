import ddf.minim.analysis.*;
import java.util.*;
import java.io.*;
// some random change

// more random changes!
abstract class Visualizer {
    AudioInput input;
    AudioSource src;
    FFT fft;
    BeatDetect beat;
    Camera camera; 
//    HighPassSP hpf;
    boolean darkMode = true;
    boolean showInterface = true;
    int contrast = 0;
    String name;
    boolean flashingMode = false;
    float volumeScale = 0.0;
    final int TEXT_OFFSET = displayWidth - 200;

    boolean highlight, expand, revolve, blur, showParticles;
    
    abstract int getOptimalFrameRate();
    abstract void draw();

    abstract void highlight();
    abstract void expand();
    abstract void revolve();
    abstract void blur();
    abstract void showParticles();

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

    void displayHelpMenu() {
        textSize(14);
        textAlign(LEFT, TOP);
        toggleTextColor(!showInterface);
        text("[h] hide interface", TEXT_OFFSET, 15);
        toggleTextColor(contrast == 0);
        text("[d] dark mode", TEXT_OFFSET, 30);
        toggleTextColor(frontalView);
        text("[f] frontal camera view", TEXT_OFFSET, 45);
        toggleTextColor(rearView);
        text("[r] rear camera view", TEXT_OFFSET, 60);
        toggleTextColor(dropLevel1);
        text("[1] drop level 1", TEXT_OFFSET, 75);
        toggleTextColor(dropLevel2);
        text("[2] drop level 2", TEXT_OFFSET, 90);
        toggleTextColor(dropLevel3);
        text("[3] drop level 3", TEXT_OFFSET, 105);
        toggleTextColor(frontalView);
        
    }

    void toggleTextColor(boolean toggled) {
        if (toggled) {
            fill(255, 100, 100);
        } else {
            fill(abs(150-contrast), abs(150-contrast), abs(150-contrast));
        }
    }


    void keyPressed() {
        switch (key) {
            case '1':
                highlight();
                break;
            case '2':
                expand();
                break;
            case '3':
                revolve();
                break;
            case 'b':
                blur();
                break;
            case 'p':
                showParticles();
                break;

        }
    }
}
