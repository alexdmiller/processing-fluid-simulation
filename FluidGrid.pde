class FluidGrid {
  private float[] densities;
  private float[] lastDensities;
  
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
    
    this.sources = new float[(width + 2) * (height + 2)];
    this.diffusion = diffusion;
    
    for (int i = 0; i < this.densities.length; i++) {
      this.densities[i] = 0;
    }
  }
  
  public void setSource(int col, int row, float density) {
    this.sources[(row + 1) * this.width + (col + 1)] = density; //<>//
  }
  
  public float getDensity(int col, int row) {
    return this.densities[(row + 1) * this.width + (col + 1)];
  }
  
  public void render() {
    for (int col = 0; col < this.width; col++) {
      for (int row = 0; row < this.height; row++) {
        fill(getDensity(col, row) * 255.0);
        rect(col * this.cellSize, row * this.cellSize, this.cellSize, this.cellSize); 
      }
    }
  }
  
  public void step(float dt) {
    this.lastDensities = densities;
    this.densities = new float[(width + 2) * (height + 2)];
    
    addSources(dt);
    diffuse(dt);
  }
  
  private void addSources(float dt) {
    for (int i = 0; i < this.sources.length; i++) {
      this.lastDensities[i] += (this.sources[i] * dt);
    }
  }
  
  private void diffuse(float dt) {
    float a = dt * width * height * this.diffusion;    
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        densities[index(col, row)] = lastDensities[index(col, row)] + 
            a * (lastDensities[index(col - 1, row)] +
                lastDensities[index(col, row - 1)] +
                lastDensities[index(col + 1, row)] +
                lastDensities[index(col, row + 1)] - 
                4 * lastDensities[index(col, row)]); 
      }
    }
  }
  
  private int index(int col, int row) {
    return (row + 1) * this.width + (col + 1);
  }
  
  public String toString() {
    String result = "";
    for (int row = 0; row < height + 2; row++) {
      for (int col = 0; col < width + 2; col++) {
        result += (Math.round(densities[row * this.width + col] * 100.0) / 100.0) + "\t";
      }
      result += "\n";
    }
    return result;
  }
}