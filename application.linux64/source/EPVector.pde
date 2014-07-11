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
    
    void rotateX(float angle) {
        temp.x = super.y;
        temp.y = super.z;
        temp.rotate(angle);
        super.y = temp.x;
        super.z = temp.y;
    }
    
    void rotateY(float angle) {
        temp.x = super.x;
        temp.y = super.z;
        temp.rotate(angle);
        super.x = temp.x;
        super.z = temp.y;
    }
    
    void rotateZ(float angle) {
        temp.x = super.x;
        temp.y = super.y;
        temp.rotate(angle);
        super.x = temp.x;
        super.y = temp.y;
    }
    
    void set(int x, int y, int z){
        super.x = x;
        super.y = y;
        super.z = z;
    }
}
