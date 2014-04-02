import ddf.minim.*; 

public class Fluid extends Visualizer {
    int OPTIMAL_FRAME_RATE = 40;
    int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }

    FluidColorTracker tracker1, tracker2;

    HorizSample[] horizSamples;
    VertSample[] vertSamples;
    final int SPEC_SIZE = 30;
    final float SPEC_WIDTH = 5;
    final int HORIZ_SAMPLE_NUM = 80;
    final int VERT_SAMPLE_NUM = 30;
    final int REFRESH = 3; 

    boolean expand = false;
    boolean revolve = false;
    boolean frontalView = true;
    boolean rearView = false;
    float currRot = 0;
    float angleInc = 0.001;

    Fluid(AudioInput input) {
        super(input, "Fluid");
        tracker1 = new FluidColorTracker(50, 100, 150, true, true, false);
        tracker2 = new FluidColorTracker(255, 100, 150, false, true, true);
        //        camera.setCenter(SPEC_SIZE * SPEC_WIDTH, 0, HORIZ_SAMPLE_NUM * REFRESH);
        camera.setCenter(SPEC_SIZE * SPEC_WIDTH, 0, 0);
        horizSamples = new HorizSample[HORIZ_SAMPLE_NUM];
        for (int i = 0; i < HORIZ_SAMPLE_NUM; i++) {
            horizSamples[i] = new HorizSample(i * REFRESH, REFRESH, HORIZ_SAMPLE_NUM * REFRESH);
        }
        vertSamples = new VertSample[VERT_SAMPLE_NUM];
        for (int i = 0; i < VERT_SAMPLE_NUM; i++) {
            vertSamples[i] = new VertSample(i * REFRESH, REFRESH, VERT_SAMPLE_NUM * REFRESH);
        }
        camera.viewingMode = false;
        camera.pos = new PVector(SPEC_SIZE * SPEC_WIDTH, 0, -130);
        camera.setOuterBounds(0, -200, -200, SPEC_SIZE * SPEC_WIDTH, 200, REFRESH * HORIZ_SAMPLE_NUM);
    }

    class HorizSample {
        float pos, speed, stop;
        int index;
        PVector[] points;

        HorizSample(float initPos, float speed, float stop) {
            this.speed = speed;
            this.stop = stop;
            index = (int) (initPos / speed);
            pos = initPos;
            points = new PVector[SPEC_SIZE * 2];
            for (int i = 0; i < points.length; i++) {
                points[i] = new PVector(i * SPEC_WIDTH, 0);
            }
        }    

        void update() {
            pos += speed;  
            if (expand) {
                for (int i = 0; i < points.length; i++) {
                    points[i].y -= pos / 40;
                }
            }
            if (pos >= stop) {
                for (int i = 0; i < points.length; i++) {
                    int fftIndex = abs(points.length / 2 - i);
                    points[i].y = -fft.getBand(fftIndex) * volumeScale;
                    //                    int srcIndex = abs(points.length / 2 - i);
                    //                    points[i].y = src.left.get(srcIndex)*200;
                }
                pos = 0;
            }
        }

        void drawLines(int ydir) {
            pushMatrix();

            if (pos > 0) {

                HorizSample currSample = this;
                int prevIndex;
                if (index == 0) {
                    prevIndex = horizSamples.length - 1;
                } 
                else {
                    prevIndex = index - 1;
                }

                HorizSample prevSample = horizSamples[prevIndex];
                if (!revolve) {
//                    fill(0);
                }
                beginShape(QUAD_STRIP);

                float zEnd = prevSample.pos;
                float zStart = currSample.pos;
                //                if (revolve) {
                //                    rotateZ(pos * (TWO_PI / HORIZ_SAMPLE_NUM) * currRot);    
                //                }
                for (int i = 0; i < points.length; i++) {
                    float xStart = currSample.points[i].x;
                    float xEnd = prevSample.points[i].x;
                    float yStart = currSample.points[i].y * ydir;
                    float yEnd = prevSample.points[i].y * ydir;
                    vertex(xStart, yStart, zStart);
                    vertex(xEnd, yEnd, zEnd);
                }  
                endShape();
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

        void update() {
            pos += speed;
            if (pos >= stop) {
                for (int i = 0; i < points.length; i++) {
                    int fftIndex = abs(points.length / 2 - i);
                    points[i].y = fft.getBand(fftIndex) * 0.5 * volumeScale;
                }
                pos = 0;
                if (highlight) {
                    continueSampling = true;
                } else {
                    continueSampling = false;
                }
            }
        }

        void drawLines(int ydir) {
            pushMatrix();

            translate(0, pos * ydir, 0);
            beginShape(LINES);
            for (int i = 0; i < points.length - 1; i++) {
                float weight = min((points[i].y + points[i+1].y) / 20, 6);
                strokeWeight(weight);
                //                line(points[i].x, points[i].y*ydir, points[i+1].x, points[i+1].y*ydir);    
                vertex(points[i].x, points[i].y * ydir);
                vertex(points[i+1].x, points[i+1].y * ydir);
            }
            float weight = min((points[points.length-2].y + points[points.length-1].y) / 20, 6);
            strokeWeight(weight);
            //            line(points[points.length-2].x, points[points.length-2].y*ydir,
            //                 points[points.length-1].x, points[points.length-1].y*ydir);
            vertex(points[points.length-2].x, points[points.length-2].y * ydir);
            vertex(points[points.length-1].x, points[points.length-1].y * ydir);
            endShape();

            popMatrix();
        }
    }
    
    void collapseLines() {
        for (int i = 0; i < horizSamples.length; i++) {
            
        }    
    }

    synchronized void draw() {

        if (revolve) {
            currRot += angleInc;
        }

        retrieveSound();
        setBackground(contrast, 150);
        pushMatrix();
        camera.update();
        fill(255);
        tracker1.incrementColor();
        tracker2.incrementColor();  
        noFill();
        pushMatrix();
        if (revolve) {
            translate(0, 0, -130 + 300);
        }

        for (int i = 0; i < VERT_SAMPLE_NUM; i++) {
            vertSamples[i].update();
        }
        for (int i = 0; i < VERT_SAMPLE_NUM; i++) {
            VertSample s = vertSamples[i];
            if (s.continueSampling) {
                if (revolve) {
                    rotateZ(currRot);
                }
                float fade = s.pos / (VERT_SAMPLE_NUM * REFRESH);
                tracker2.setComplementaryColor(1 - fade);
                s.drawLines(1);
                tracker1.setComplementaryColor(1 - fade);
                s.drawLines(-1);
            }
        } 
        popMatrix();
        strokeWeight(0.8);
        for (int i = 0; i < HORIZ_SAMPLE_NUM; i++) {
            horizSamples[i].update();
        }
        for (int i = 0; i < HORIZ_SAMPLE_NUM; i++) {
            HorizSample s = horizSamples[i];

            int relativeIndex = (int) (s.pos / REFRESH);

            if (revolve) {
                rotateZ(currRot * relativeIndex);
            }

            if (expand) {
                float weight = map(s.pos, 0, s.stop, 0.8, 5);
                strokeWeight(weight);
            }
            float fade;
            if (expand) {
                fade = s.pos / (HORIZ_SAMPLE_NUM * REFRESH) / 2;
            } 
            else {
                fade = s.pos / (HORIZ_SAMPLE_NUM * REFRESH);
            }
            tracker1.setColor(1 - fade);
            s.drawLines(1);
            tracker2.setColor(1 - fade);
            s.drawLines(-1);  

            if (revolve) {
                rotateZ(-currRot * relativeIndex);
            }
        }

        popMatrix();

        if (showInterface) {
            displayHelpMenu();    
            displayDebugText();
        }
    }

    void blur() {
        // TODO
    }

    void particles() {
        // TODO
    }
    
    void highlight() {
        highlight = !highlight;
    }

    void expand() {
        expand = !expand;
    }

    void revolve() {
        revolve = !revolve; 
        currRot = 0;
        if (revolve) {
            camera.initMoveCenter(0, 0, 0, (int)frameRate);
            camera.initMoveCamera(new PVector(0, 0, -160), (int)frameRate);
        } else {
            collapseLines();
            camera.initMoveCenter(SPEC_SIZE * SPEC_WIDTH, 0, 0, (int)frameRate);
            camera.initMoveCamera(new PVector(1.0 * SPEC_SIZE * SPEC_WIDTH, 0, -130), (int) frameRate);
        }
    }

// case 'f':
//     frontalView = true;
//     rearView = false;
//     camera.disableAllModes();
//     float camX = SPEC_SIZE * SPEC_WIDTH;
//     if (revolve) {
//         camera.initMoveCenter(0, 0, 0, (int)frameRate);
//         camX = 0;
//     }
//     camera.initMoveCamera(new PVector(camX, 0, -130), (int)frameRate);
//     break;
// case 'r':
//     rearView = true;
//     frontalView = false;
//     camera.disableAllModes();
//     camX = SPEC_SIZE * SPEC_WIDTH;
//     if (revolve) {
//         camera.initMoveCenter(0, 0, 0, (int)frameRate);
//         camX = 0;
//     }
//     camera.initMoveCamera(new PVector(camX, 0, 300), (int)frameRate);
//     break;



    class FluidColorTracker extends ColorTracker {

        FluidColorTracker(float red, float green, float blue, boolean incrRed, boolean incrGreen, boolean incrBlue) {
            super(red, green, blue);    
            this.incrRed = incrRed;
            this.incrGreen = incrGreen;
            this.incrBlue = incrBlue;
        }

        void setColor(float fade) {
            stroke(red * fade, green * fade, blue * fade);
        }  

        void setComplementaryColor(float fade) {
            stroke((255 - red) * fade, (255 - green) * fade, (255 - blue) * fade);
        }
    }
}

