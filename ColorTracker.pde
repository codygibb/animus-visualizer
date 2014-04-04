public class ColorTracker {
    float DELTA_MAX = 5;
    float DELTA_MIN = 0.5;
    
    float red, green, blue;
    boolean incrRed, incrGreen, incrBlue;
    float dr, dg, db;

    ColorTracker(float redStart, float greenStart, float blueStart) {
        incrRed = true;
        incrBlue = false;
        incrGreen = false;
        red = redStart;
        green = greenStart;
        blue = blueStart;
        pickRandomDeltas();
    }    
    
    ColorTracker() {
        this(random(125, 255), random(0, 125), random(67, 200));
    }
    
    void pickRandomDeltas() {
        dr = random(DELTA_MIN, DELTA_MAX);
        dg = random(DELTA_MIN, DELTA_MAX);
        db = random(DELTA_MIN, DELTA_MAX);
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
            dr = random(DELTA_MIN, DELTA_MAX);
        }
        if (blue > 255) {
            incrBlue = false;
            db = random(DELTA_MIN, DELTA_MAX);
        }
        if (green > 255) {
            incrGreen = false;
            dg = random(DELTA_MIN, DELTA_MAX);
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
    
    //sets stroke and/or fill to complementary colors of the current rgb values
    void setComplementaryColor(boolean strokeOn, boolean fillOn) {
        if (strokeOn)
            stroke(255 - red, 255 - green, 255 - blue);
        if (fillOn)
            fill(255 - red, 255 - green, 255 - blue);
    }
    
    //sets stroke and/or fill to current rgb values
    //generally should call each frame
    void setColor(boolean strokeOn, boolean fillOn) {
        if (strokeOn)
            stroke(red, green, blue);    
        if (fillOn) 
            fill(red, green, blue);
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
                          
//        pointLight(red, green, blue,
//                   200, -150, 0);
//
//        directionalLight(red / 4, green / 4, blue / 4,
//                         -1, 0, 0);
//                   
//        lightSpecular(0, 1, 2);
//        
//        directionalLight(0, 0, 0, //color
//                         1, 0, 0); //position
////
//        spotLight(255 - red, 255 - green, 255 - blue,
//                  0, 40, 200,
//                  0, -0.5, -0.5,
//                  PI/2, 0.1);

///////////////////
//        emissive(0, 0, blue);
//        specular(0, random(0, 255), random(0, 255));
//        directionalLight(red/10, green/10, blue/10,
//                          0.5, 0, -1);
//                          
//        lightSpecular(0, 0, 0);
//        ambientLight(0, 0, 0);
//        directionalLight(0, 0, 0,
//                         1, 0, 0);
        
    }
}
