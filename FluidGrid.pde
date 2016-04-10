class FluidGrid { //<>//
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

    sources = new float[(width + 2) * (height + 2)];
  }

  public void addDensity(int col, int row, float d) {
    density[(row + 1) * (this.width + 2) + (col + 1)] += d;
  }

  public void setSource(int col, int row, float density) {
    sources[(row + 1) * (this.width + 2) + (col + 1)] = density;
  }

  public void addVelocity(int col, int row, float x, float y) {
    u[(row + 1) * (this.width + 2) + (col + 1)] += x;
    v[(row + 1) * (this.width + 2) + (col + 1)] += y;
  }

  public void render() {
    for (int col = 0; col < this.width + 2; col++) {
      for (int row = 0; row < this.height + 2; row++) {
        noStroke();
        fill(this.density[row * (this.width + 2) + col] * 10.0);
        rect(
            col * this.cellSize,
            row * this.cellSize,
            this.cellSize,
            this.cellSize);
      }
    }
  }

  public void step(float dt) {    
    density = addSources(density, sources, dt);
    density = diffuse(density, diffusion, dt, Bound.NONE);  
    density = advect(density, u, v, dt, Bound.NONE);

    u = addSources(u, fu, dt);
    v = addSources(v, fv, dt);
    u = diffuse(u, visc, dt, Bound.X);
    v = diffuse(v, visc, dt, Bound.Y);

    project(u, v);

    u = advect(u, u, v, dt, Bound.X);
    v = advect(v, u, v, dt, Bound.Y);

    project(u, v);
  }

  private float[] addSources(float[] prev, float[] sources, float dt) {
    float[] next = new float[(width + 2) * (height + 2)];
    for (int i = 0; i < sources.length; i++) {
      next[i] = prev[i] + (sources[i] * dt);
    }
    return next;
  }

  private float[] diffuse(float[] prev, float diff, float dt, Bound b) {
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
      
      bound(b, next);
    }

    return next;
  }

  private float[] advect(
      float[] prev,
      float[] u,
      float[] v,
      float dt,
      Bound b) {
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

    bound(b, next);

    return next;
  }

  // The velocity field a sum of an incompressible field and a gradient
  // field. To enforce conservation of mass, we compute the gradient field
  // and subtract that from the velocity field -- leaving us with the
  // incompressible field. The incompressible field is "swirly", and swirly
  // is good.
  private void project(float[] u, float[] v) {
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
    
    bound(Bound.NONE, div);
    bound(Bound.NONE, p);

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
      
      bound(Bound.NONE, p);
    }


    for (int row = 0; row < this.height; row++) {
      for (int col = 0; col < this.width; col++) {
        u[index(col, row)] -=
            0.5 * (p[index(col + 1, row)] - p[index(col - 1, row)]) / h;
        v[index(col, row)] -=
            0.5 * (p[index(col, row + 1)] - p[index(col, row - 1)]) / h;
      }
    }
    
    bound(Bound.X, u);
    bound(Bound.Y, v);
  }

  private void bound(Bound b, float[] x) {
    // If bound is set to Bound.X or Bound.Y, then set that boundary so it
    // zeros out the property of the fluid. Used to simulate hard borders.
    if (b == Bound.X) {
      for (int row = 0; row < height; row++) {
        x[index(-1, row)] = -x[index(0, row)];
        x[index(height, row)] = -x[index(height - 1, row)];
      }
    } else if (b == Bound.Y) {
       for (int col = 0; col < width; col++) {
         x[index(col, -1)] = -x[index(col, 0)];
         x[index(col, width)] = -x[index(col, width - 1)];
      }
    }
    
    // Set the corners to be the average of the two adjacent cells.
    x[index(-1, -1)] =
        0.5 * (x[index(0, -1)] + x[index(-1, 0)]);
    x[index(-1, height)] =
        0.5 * (x[index(0, height)] + x[index(-1, height-1)]);
    x[index(width, -1)] =
        0.5 * (x[index(width-1, -1)] + x[index(width, 0)]);
    x[index(width, height)] =
        0.5 * (x[index(width, height-1)] + x[index(width-1, height)]);
  }

  private int index(int col, int row) {
    return (row + 1) * (this.width + 2) + (col + 1);
  }
}

enum Bound {
  NONE, X, Y;
}