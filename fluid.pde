import java.util.Arrays;

FluidGrid grid;
long lastTimeMillis;

float lastMouseX;
float lastMouseY;

int CELL_SIZE = 5;


void setup() {
  size(800, 800);
  grid = new FluidGrid(
    width / CELL_SIZE, 
    height / CELL_SIZE, 
    CELL_SIZE, 
    0.0000001, 
    0.000001);
  lastTimeMillis = System.currentTimeMillis();
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}

void draw() {
  background(0);

  long millis = System.currentTimeMillis();
  long delta = millis - lastTimeMillis;
  float vx = (mouseX - lastMouseX) / 1000.0;
  float vy = (mouseY - lastMouseY) / 1000.0;

  grid.addVelocity(mouseX / CELL_SIZE, mouseY / CELL_SIZE, vx, vy);
  if (mousePressed) {
    grid.addDensity(mouseX / CELL_SIZE, mouseY / CELL_SIZE, 500);
  }

  grid.step(delta);
  grid.render();
  
  lastTimeMillis = millis;
  lastMouseX = mouseX;
  lastMouseY = mouseY;
}