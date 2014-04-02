class Globe extends Visualizer {
    int OPTIMAL_FRAME_RATE = 40;
    public int getOptimalFrameRate() {
        return OPTIMAL_FRAME_RATE;
    }
    
    final int SPEC_SIZE = 100;
    final int DENSITY = 10; // points per frequency
    final int RADIUS = 500;
    final float DECAY = 0.3;
    final int MAX_RADIUS = 2000;
    final int CONNECTIONS = 4; //max number of connections a particle will make
    
    Particle[] particles;
    HashMap<Particle, Particle[]> particleMap;
    boolean dropLevel1 = false;
    ColorTracker tracker;

    Globe(AudioInput input) {
        super(input, "Globe");    
        tracker = new ColorTracker();
        stroke(255);
        particles = new Particle[SPEC_SIZE * DENSITY];
        for (int i = 0; i < particles.length; i++) {
            PVector pos = PVector.random3D();
            pos.setMag(RADIUS);
            particles[i] = new Particle(pos, i / DENSITY);
        }
        particleMap = new HashMap<Particle, Particle[]>();
        for (int i = 0; i < particles.length; i++) {
            Particle[] children = particles[i].findChildren(i);
        }
    }

    class Particle {
        EPVector pos;
        int index;
        float weight;
        
        Particle(PVector pos, int index) {
            this.pos = new EPVector(pos.x, pos.y, pos.z);
            this.index = index;
        }
        
        void update() {
            weight = fft.getBand(index) * volumeScale;
            if (dropLevel1) {
                pos.setMag(pos.mag() + weight * 10);
                if (pos.mag() > MAX_RADIUS) {
                    pos.setMag(RADIUS);    
                }
            } else {
                weight += RADIUS;
                if (pos.mag() > RADIUS) {
                    float dm = DECAY + pos.mag() / 50;
                    float mag = pos.mag() - dm;
                    mag = max(mag, RADIUS);
                    pos.setMag(mag);
                }
                if (pos.mag() < weight) {
                    pos.setMag(weight);
                }
            }
        }
        
        void drawParticle() {
            strokeWeight(2.5);
            stroke(255);
            beginShape(LINES);
            PVector origin = new PVector(pos.x, pos.y, pos.z);
            origin.setMag(RADIUS);
            stroke(0);
            vertex(origin.x, origin.y, origin.z);
            stroke(255);
            vertex(pos.x, pos.y, pos.z);
            endShape();
        }
        
        // pick particle
        // grab 
        
        Particle[] findChildren(int myIndex) {
            int size = ceil(random(0, CONNECTIONS));
            Particle[] children = new Particle[size];
            for (int i = 0; i < particles.length; i++) {
                if (i != myIndex) {
                    updateChildren(particles[i], children);
                }    
            }
            return children;
        }
        
        void updateChildren(Particle p, Particle[] children) {
            float[] dists = new float[children.length];
            for (int i = 0; i < children.length; i++) {
//                dists[i] = dist(p, children[i]);
            }        
            dists = sort(dists);
        }
    }

    synchronized void draw() {
        retrieveSound();
        setBackground(contrast, 255);
        pushMatrix();
        camera.update();

        for (Particle p : particles) {
            p.update();
            p.drawParticle();    
        }

        popMatrix();
    }

    void keyPressed() {
        switch (key) {
            case '1':
                dropLevel1 = !dropLevel1;
                break;
            default:
                break;    
        }
    }
}

