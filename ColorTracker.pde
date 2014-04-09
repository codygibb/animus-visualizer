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
    
    void pickRandomDeltas() {
        dr = random(deltaMin, deltaMax);
        dg = random(deltaMin, deltaMax);
        db = random(deltaMin, deltaMax);
    }
    
    //call each frame to slowly change colors over time
    void incrementColor() {
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
    
    void pickRandomColor() {
        red = random(0, 255);
        green = random(0, 255);
        blue = random(0, 255);    
    }
    
    void defineLights() {
        lightSpecular(red / 15, red / 15, red / 15);

        directionalLight(0, green / 8, blue / 4, 
                1, 0, 0);
        pointLight(min(red*2, 255), green / 4, blue / 4,
                200, -150, 0);

        pointLight(0, 0, blue,
                0, 150, 200);

        spotLight(255 - red, 255 - (green / 4), 255 - (blue / 4),
                0, 40, 200,
                0, -0.5, -0.5,
                PI/2, 1);

        directionalLight(0, 0, 0,
                -1, 0, 0);

    }
}
