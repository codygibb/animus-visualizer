import ddf.minim.*; 

class Fluid extends Visualizer {
    final int OPTIMAL_FRAME_RATE = 40;

    @Override
    int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }

    final int SPEC_SIZE = 30;
    final float SPEC_WIDTH = 5;
    final int HORIZ_SAMPLE_NUM = 80;
    final int VERT_SAMPLE_NUM = 30;
    final int REFRESH = 3;
    final float ANGLE_INC = 0.001;

    // since we need 4 different color trackers -- base and peak colors for both
    // bottom and top halves -- stored all dem in an array
    // colorTrackers[0] -> base tracker for bottom half
    // colorTrackers[1] -> peak tracker for bottom half
    // colorTrackers[2] -> base tracker for top half
    // colorTrackers[3] -> peak tracker for top half
    ColorTracker[] colorTrackers;
    
    HorizSample[] horizSamples;
    VertSample[] vertSamples;
    
    float currRot = 0;
    
    Fluid(AudioInput input) {
        super(input, "Fluid");
        colorTrackers = new ColorTracker[4];
        for (int i = 0; i < colorTrackers.length; i++) {
            colorTrackers[i] = new ColorTracker(0.5, 4);   
        }
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

    class Point {
        float x, y, z;

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
        float intensity;

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
        
        void setColor(float fade, float[] colors) {
            stroke(colors[0] * fade, colors[1] * fade, colors[2] * fade);
        }        

        void update() {
            pos += speed;  
            if (expand) {
                for (int i = 0; i < points.length; i++) {
                    points[i].y += pos / 40;
                }
            }
            if (pos >= stop) {
                for (int i = 0; i < points.length; i++) {
                    int fftIndex = abs(points.length / 2 - i);
                    points[i].y = getIntensity(fftIndex);
                    intensity = getIntensity(fftIndex);

                    // see comment inside Point (above botColors and topColors)
                    // for explanation on wtf is going on here
                    points[i].botColors = getColor(points[i].intensity, 40, colorTrackers[0], colorTrackers[1]);
                    points[i].topColors = getColor(points[i].intensity, 40, colorTrackers[2], colorTrackers[3]);
                }
                pos = 0;
            }
        }

        void drawLines(int ydir, float fade) {
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
                if (particles) {
                    beginShape(POINTS);
                    noFill();
                } else {
                    beginShape(QUAD_STRIP);
                }

                float zEnd = prevSample.pos;
                float zStart = currSample.pos;
                for (int i = 0; i < points.length; i++) {
                    float xStart = currSample.points[i].x;
                    float xEnd = prevSample.points[i].x;
                    float yStart = currSample.points[i].y * ydir;
                    float yEnd = prevSample.points[i].y * ydir;
                    if (particles) {
                        strokeWeight(max(abs(currSample.intensity*2)*volumeScale, 1));
                    }

                    if (ydir > 0) {
                        setColor(fade, points[i].botColors);
                    } else {
                        setColor(fade, points[i].topColors);
                    }

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
                    points[i].y = getIntensity(fftIndex) * 0.6;
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

            if(particles){
                beginShape(POINTS);
            } else {
                beginShape(LINES);
            }

            for (int i = 0; i < points.length - 1; i++) {
                float weight = min((points[i].y + points[i + 1].y) / 20, 6);
                if(particles){
                    weight *= 5;
                }
                strokeWeight(weight);
   
                vertex(points[i].x, points[i].y * ydir);
                vertex(points[i + 1].x, points[i + 1].y * ydir);
            }

            float weight = min((points[points.length - 2].y + points[points.length - 1].y) / 20, 6);
            strokeWeight(weight);
            vertex(points[points.length - 2].x, points[points.length - 2].y * ydir);
            vertex(points[points.length - 1].x, points[points.length - 1].y * ydir);
            endShape();

            popMatrix();
        }
    }

    @Override
    void draw() {
        if(blur) {
            setBackground(contrast, 60);
        } else {
            setBackground(contrast, 150);
        }
        
        camera.update();
        for (ColorTracker ct : colorTrackers) {
            ct.incrementColor();
        }
        noFill();
        pushMatrix();
    
        // makes sure vertical samples appear at the front of the figure
        if (revolve) {
            translate(0, 0, 170);
        }

        if (revolve) {
            currRot += ANGLE_INC;
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
                fade = 1 - s.pos / (HORIZ_SAMPLE_NUM * REFRESH) / 2;
            } else {
                fade = 1 - s.pos / (HORIZ_SAMPLE_NUM * REFRESH);
            }
            s.drawLines(1, fade);
            s.drawLines(-1, fade);  

            if (revolve) {
               rotateZ(-currRot * relativeIndex);
            }
        }

        popMatrix();
    }
    
    void setComplementaryColor(float fade, ColorTracker tracker) {
        stroke((255 - tracker.red) * fade, (255 - tracker.green) * fade, (255 - tracker.blue) * fade);
    }

    @Override
    void particles() {
        particles = !particles;
    }

    @Override
    void highlight() {
        highlight = !highlight;
    }

    @Override
    void expand() {
        expand = !expand;
    }

    @Override
    void revolve() { 
        revolve = !revolve;
        currRot = 0;
        frontView = true;
        rearView = false;
        topView = false;
        frontView();
    }

    @Override
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
    
    @Override
    void rearView() {
        float camX = SPEC_SIZE * SPEC_WIDTH;
        if (revolve) {
            camera.initMoveCenter(0, 0, 0, (int)frameRate);
            camX = 0;
        }
        camera.initMoveCamera(new PVector(camX, 0, 300), (int)frameRate);
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
    
    @Override
    void topView() { 
        float camZ = HORIZ_SAMPLE_NUM*REFRESH/1.99;
        float camY = -150;
        if(frontView){
            camZ = HORIZ_SAMPLE_NUM*REFRESH/2.1;
            camY = 150;
        }
        camera.initMoveCamera(new PVector(150, camY, camZ), (int) frameRate * 2);
        
        if(revolve){
            camera.initMoveCenter(0, 0, HORIZ_SAMPLE_NUM*REFRESH/2, (int)frameRate/2);
        } else{
            camera.initMoveCenter(SPEC_SIZE * SPEC_WIDTH, 0, HORIZ_SAMPLE_NUM*REFRESH/2, (int)frameRate);
        }
        camera.initMoveDir(new PVector(0, 1, 0), (int) frameRate);
    }
}
