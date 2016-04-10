class FluidGrid {
  private float[] density;
  private float[] fu;
  private float[] fv;
  private float[] u;
  private float[] v;
  
  private float[] sources;
  
  private int width;
  private int height;
  private int cellSize;
  private float diffusion;
  private float visc;
  
  public FluidGrid(
      int width,
      int height,
      int cellSize,
      float diffusion,
      float visc) {
    this.width = width;
    this.height = height;
    this.cellSize = cellSize;
    this.diffusion = diffusion;
    this.visc = visc;
    
    density = new float[(width + 2) * (height + 2)];
    u = new float[(width + 2) * (height + 2)];
    v = new float[(width + 2) * (height + 2)];
    fu = new float[(width + 2) * (height + 2)];
    fv = new float[(width + 2) * (height + 2)];
    
    for (int i = 0; i < u.length; i++) {
      //fv[i] = 0.0000 1;
    }
    
    sources = new float[(width + 2) * (height + 2)];
  }
  
  public void addDensity(int col, int row, float d) {
    density[(row + 1) * (this.width + 2) + (col + 1)] += d;
  }
  
  public void setSource(int col, int row, float density) {
    sources[(row + 1) * (this.width + 2) + (col + 1)] = density; //<>//
  }
  
  public void setVelocity(int col, int row, float x, float y) {
    u[(row + 1) * (this.width + 2) + (col + 1)] = x;
    v[(row + 1) * (this.width + 2) + (col + 1)] = y;
  }
  
  public void render() {
    for (int col = 0; col < this.width + 2; col++) {
      for (int row = 0; row < this.height + 2; row++) {
        noStroke();
        fill(this.density[row * (this.width + 2) + col] * 10.0);
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
    density = addSources(density, sources, dt);
    density = diffuse(density, diffusion, dt);  
    density = advect(density, u, v, dt);
    
    u = addSources(u, fu, dt);
    v = addSources(v, fv, dt);
    u = diffuse(u, visc, dt);
    v = diffuse(v, visc, dt);
    
    project(u, v);
    
    u = advect(u, u, v, dt);
    v = advect(v, u, v, dt);
    
    project(u, v);
  }
  
  private float[] addSources(float[] prev, float[] sources, float dt) {
    float[] next = new float[(width + 2) * (height + 2)];
    for (int i = 0; i < sources.length; i++) {
       next[i] = prev[i] + (sources[i] * dt);
    }
    return next;
  }
  
  private float[] diffuse(float[] prev, float diff, float dt) {
    float[] next = new float[(width + 2) * (height + 2)];
    
    float a = dt * (width + 2) * (height + 2) * diff;
    
    for (int k = 0; k < 20; k++) {
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          next[index(col, row)] = (prev[index(col, row)] + 
              a * (next[index(col - 1, row)] +
                  next[index(col, row - 1)] +
                  next[index(col + 1, row)] +
                  next[index(col, row + 1)])) / (1 + 4 * a); 
        }
      }
    }
    
    return next;
  }
  
  private float[] advect(float[] prev, float[] u, float[] v, float dt) {
    float[] next = new float[(width + 2) * (height + 2)];
    
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
        
        next[index(col, row)] =
            s0 * (t0 * prev[index(i0, j0)] + t1 * prev[index(i0, j1)]) +
            s1 * (t0 * prev[index(i1, j0)] + t1 * prev[index(i1, j1)]);
      }
    }
    
    return next;
  }
  
  void project(float[] u, float[] v) {
    float[] p = new float[(width + 2) * (height + 2)];
    float[] div = new float[(width + 2) * (height + 2)];
    
    float h = 1.0 / (this.width * this.height);
    
    for (int row = 0; row < this.height; row++) {
      for (int col = 0; col < this.width; col++) {
        div[index(col, row)] = -0.5 * h * (
            u[index(col + 1, row)] - u[index(col - 1, row)] +
            v[index(col, row + 1)] - v[index(col - 1, row - 1)]);
      }
    }
    
    for (int k = 0; k < 20; k++) {
      for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
          p[index(col, row)] = (div[index(col, row)] + 
              p[index(col - 1, row)] +
              p[index(col, row - 1)] +
              p[index(col + 1, row)] +
              p[index(col, row + 1)]) / 4; 
        }
      }
    }
    
    
    for (int row = 0; row < this.height; row++) {
      for (int col = 0; col < this.width; col++) {
        u[index(col, row)] -= 0.5 * (p[index(col + 1, row)] - p[index(col - 1, row)]) / h;
        v[index(col, row)] -= 0.5 * (p[index(col, row + 1)] - p[index(col, row - 1)]) / h;
      }
    }
  }
  
  private int index(int col, int row) {
    return (row + 1) * (this.width + 2) + (col + 1);
  }
}