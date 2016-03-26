class FluidGrid {
  private float[] densities;
  private float[] lastDensities;
  
  private float[] u;
  private float[] v;
  
  private float[] sources;
  
  private int width;
  private int height;
  private int cellSize;
  private float diffusion;
  
  public FluidGrid(int width, int height, int cellSize, float diffusion) {
    this.width = width;
    this.height = height;
    this.cellSize = cellSize;
    
    this.densities = new float[(width + 2) * (height + 2)];
    this.u = new float[(width + 2) * (height + 2)];
    this.v = new float[(width + 2) * (height + 2)];
    
    for (int i = 0; i < this.u.length; i++) {
      this.v[i] = -0.0001;
    }
    
    this.sources = new float[(width + 2) * (height + 2)];
    this.diffusion = diffusion;
  }
  
  public void setSource(int col, int row, float density) {
    this.sources[(row + 1) * (this.width + 2) + (col + 1)] = density; //<>//
  }
  
  public void setVelocity(int col, int row, float x, float y) {
    this.u[(row + 1) * (this.width + 2) + (col + 1)] = x;
    this.v[(row + 1) * (this.width + 2) + (col + 1)] = y;
  }
  
  public void render() {
    for (int col = 0; col < this.width + 2; col++) {
      for (int row = 0; row < this.height + 2; row++) {
        noStroke();
        fill(this.densities[row * (this.width + 2) + col] * 255.0);
        rect(col * this.cellSize, row * this.cellSize, this.cellSize, this.cellSize);
        
        stroke(255, 0, 0);
        
        //pushMatrix();
        //translate(col * this.cellSize + this.cellSize / 2, row * this.cellSize + this.cellSize / 2);
        //line(0, 0, this.u[row * (this.width + 2) + col] * 10000, this.v[row * (this.width + 2) + col] * 10000);
        //popMatrix();
      }
    }
  }
  
  public void step(float dt) {    
    addSources(this.sources, this.densities, dt);
    
    this.lastDensities = this.densities;
    this.densities = new float[(width + 2) * (height + 2)];
    
    diffuse(this.lastDensities, this.densities, dt);
    
    this.lastDensities = this.densities;
    this.densities = new float[(width + 2) * (height + 2)];
    
    advect(this.lastDensities, this.densities, this.u, this.v, dt);
  }
  
  private void addSources(float[] sources, float[] curr, float dt) {
    for (int i = 0; i < sources.length; i++) {
      curr[i] += (sources[i] * dt);
    }
  }
  
  private void diffuse(float[] last, float[] curr, float dt) {
    float a = dt * (width + 2) * (height + 2) * this.diffusion;
    
    for (int k = 0; k < 20; k++) {
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          curr[index(col, row)] = (last[index(col, row)] + 
              a * (curr[index(col - 1, row)] +
                  curr[index(col, row - 1)] +
                  curr[index(col + 1, row)] +
                  curr[index(col, row + 1)])) / (1 + 4* a); 
        }
      }
    }
  }
  
  private void advect(float[] last, float[] curr, float[] u, float[] v, float dt) {
    float dt0 = dt * this.width;
    
    for (int row = 0; row < this.height; row++) {
      for (int col = 0; col < this.width; col++) {
        // Where was the particle last frame, in terms of rows and cols
        float x = col - dt0 * u[index(col, row)];
        float y = row - dt0 * v[index(col, row)];
        
        // Bound within 0.5 of border
        x = max(x, 0.5);
        x = min(x, this.width - 0.5);
        y = max(y, 0.5);
        y = min(y, this.width - 0.5);
        
        // Convert to box of 4 cells around the particle 
        int i0 = (int) x;
        int j0 = (int) y;
        int i1 = i0 + 1;
        int j1 = j0 + 1;

        // Bilinear interpolation of values
        // Distances
        float s1 = x - i0;
        float s0 = 1 - s1;
        float t1 = y - j0;
        float t0 = 1 - t1;
        
        curr[index(col, row)] =
            s0 * (t0 * last[index(i0, j0)] + t1 * last[index(i0, j1)]) +
            s1 * (t0 * last[index(i1, j0)] + t1 * last[index(i1, j1)]);
      }
    }
  }
  
  private int index(int col, int row) {
    return (row + 1) * (this.width + 2) + (col + 1);
  }
}