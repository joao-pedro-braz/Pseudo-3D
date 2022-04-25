import java.util.List;
import java.util.Arrays;

final PVector pyramidSize = new PVector(200, 200, 20);
final int slicesAmount = 40;
final int sliceSidesAmount = 40;
final boolean debug = false;
final float lightSourceIntensity = 10.0;
final float ambientLightIntensity = 2.0;
final boolean simulateSelfShading = true;
final color baseColor = color(50, 50, 50);

PVector center = new PVector(width / 2, height / 2);
PVector lightSourcePos = new PVector(1.0, 0.0, -20.0);
PVector lightSourceDir = new PVector(1.0, 0.0, 0.0);
PVector[][][] slices = new PVector[slicesAmount][2][];

void setup() {
  size(800, 600);
  center = new PVector(width / 2, height / 2);

  for (int i = slicesAmount; i >= 1; i--) {
    final PVector sliceSize = pyramidSize.copy().mult((float) i / slicesAmount);

    final PVector[] sliceCoords = getSliceCoords(sliceSize, center);

    final PVector[] sliceNormals = getSliceNormals(sliceCoords);

    slices[slicesAmount - i][0] = sliceCoords;
    slices[slicesAmount - i][1] = sliceNormals;
  }
}

void draw() {
  background(20);

  rectMode(CENTER);
  for (PVector[][] slice : slices) {
    final PVector[] sliceCoords = slice[0];
    final PVector[] sliceNormals = slice[1];

    for (int j = 0; j < sliceCoords.length; j++) {
      drawSliceSide(sliceCoords[j], sliceCoords[(j == sliceCoords.length - 1) ? 0 : (j + 1)], sliceNormals[j]);
    }
  }
}

PVector[] getSliceCoords(PVector sliceSize, PVector center) {
  final PVector sliceSizeHalf = sliceSize.copy().div(2);

  final PVector A = new PVector(center.x - sliceSizeHalf.x, center.y - sliceSizeHalf.y);
  final PVector B = new PVector(center.x + sliceSizeHalf.x, center.y - sliceSizeHalf.y);
  final PVector C = new PVector(center.x + sliceSizeHalf.x, center.y + sliceSizeHalf.y);
  final PVector D = new PVector(center.x - sliceSizeHalf.x, center.y + sliceSizeHalf.y);

  List<PVector> sides = new ArrayList<>();

  sides.add(A);

  for (int i = 1; i < sliceSidesAmount; i++) {
    sides.add(PVector.lerp(A, B, (float) i / sliceSidesAmount));
  }

  sides.add(B);

  for (int i = 1; i < sliceSidesAmount; i++) {
    sides.add(PVector.lerp(B, C, (float) i / sliceSidesAmount));
  }

  sides.add(C);

  for (int i = 1; i < sliceSidesAmount; i++) {
    sides.add(PVector.lerp(C, D, (float) i / sliceSidesAmount));
  }

  sides.add(D);

  for (int i = 1; i < sliceSidesAmount; i++) {
    sides.add(PVector.lerp(D, A, (float) i / sliceSidesAmount));
  }

  return sides.toArray(new PVector[(sliceSidesAmount - 1) * 4 + 4]);
}

PVector[] getSliceNormals(PVector[] sliceCoords) {
  final PVector[] normals = new PVector[sliceCoords.length];
  final PVector pyramidTopPos = center.copy();
  pyramidTopPos.z = -pyramidSize.z;

  for (int i = 0; i < sliceCoords.length; i++) {
    final PVector pointA = sliceCoords[i];
    final PVector pointB = sliceCoords[(i == sliceCoords.length - 1) ? 0 : (i + 1)];

    normals[i] = pyramidTopPos.copy().sub(pointA)
      .cross(pointB.copy().sub(pointA))
      .normalize();
  }

  return normals;
}

void drawSliceSide(PVector sideSliceCoordA, PVector sideSliceCoordB, PVector sideSliceNormal) {
  color slideSideColor = changeColorIntensity(baseColor, ambientLightIntensity);

  final float dotLightNormal = lightSourceDir.dot(sideSliceNormal);
  final PVector AB = sideSliceCoordA.copy().add(sideSliceCoordB).div(2);

  if (simulateSelfShading || dotLightNormal <= 0) {
    final float dropoff = 1 / sqrt(lightSourcePos.dist(AB));
    final float intensity = 1.0 - dotLightNormal * dropoff * lightSourceIntensity;

    slideSideColor = changeColorIntensity(slideSideColor, intensity);
  }

  if (!debug)
    noStroke();

  fill(slideSideColor);

  quad(
    sideSliceCoordA.x, sideSliceCoordA.y,
    center.x, center.y,
    sideSliceCoordB.x, sideSliceCoordB.y,
    sideSliceCoordA.x, sideSliceCoordA.y
    );

  if (debug) {
    final PVector ABNormal = sideSliceNormal.copy().setMag(10);
    line(
      AB.x, AB.y,
      AB.x + ABNormal.x, AB.y + ABNormal.y
      );
  }
}

color changeColorIntensity(color orginalColor, float intensity) {
  return color(
    red(orginalColor) * intensity,
    green(orginalColor) * intensity,
    blue(orginalColor) * intensity);
}

void mouseMoved() {
  lightSourcePos = new PVector(mouseX, mouseY, lightSourcePos.z);
  lightSourceDir = center.copy().sub(lightSourcePos).normalize();
}
