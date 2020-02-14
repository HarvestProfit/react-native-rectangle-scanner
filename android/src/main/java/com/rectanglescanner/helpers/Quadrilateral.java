package com.rectanglescanner.helpers;

import org.opencv.core.MatOfPoint;
import org.opencv.core.Rect;
import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.core.Size;

import android.os.Bundle;

/**
 * Created by Jake on Jan 6, 2020.
 * Represents the detected rectangle from an image
 */
public class Quadrilateral {
    public MatOfPoint contour;
    public Point[] points;
    public Size sourceSize;

    public Quadrilateral(MatOfPoint contour, Point[] points, Size sourceSize) {
        this.contour = contour;
        this.points = points;
        this.sourceSize = sourceSize;
    }

    /**
    Crops the edges of the image to the aspect ratio of the detected rectangle.
    */
    public Mat cropImageToRectangleSize(Mat image) {
      Size imageSize = image.size();
      double rectangleRatio = this.sourceSize.height / this.sourceSize.width;
      double imageRatio = imageSize.height / imageSize.width;

      double cropHeight = imageSize.height;
      double cropWidth = imageSize.width;
      // Used to center the crop in the middle
      int rectangleXCoord = 0;
      int rectangleYCoord = 0;
      if (imageRatio > rectangleRatio) {
        // Height should be cropped
        cropHeight = cropWidth * rectangleRatio;
        rectangleYCoord = (int)((imageSize.height - cropHeight) / 2);
      } else {
        // Width should be cropped
        cropWidth = cropHeight / rectangleRatio;
        rectangleXCoord = (int)((imageSize.width - cropWidth) / 2);
      }

      Rect rectCrop = new Rect(rectangleXCoord, rectangleYCoord, (int)cropWidth, (int)cropHeight);
      return new Mat(image, rectCrop);
    }

    /**
    Returns the points of the rectangle scaled to the given size
    */
    public Point[] getPointsForSize(Size outputSize) {
      double scale = outputSize.height / this.sourceSize.height;
      if (scale == 1) {
        return this.points;
      }

      Point[] scaledPoints = new Point[4];
      for (int i = 0;i < this.points.length;i++ ) {
        scaledPoints[i] = this.points[i].clone();
        scaledPoints[i].x *= scale;
        scaledPoints[i].y *= scale;
      }

      return scaledPoints;
    }


    /**
    Returns the rectangle as a bundle object
    */
    public Bundle toBundle() {
      Bundle quadMap = new Bundle();

      Bundle bottomLeft = new Bundle();
      bottomLeft.putDouble("x", this.points[2].x);
      bottomLeft.putDouble("y", this.points[2].y);
      quadMap.putBundle("bottomLeft", bottomLeft);

      Bundle bottomRight = new Bundle();
      bottomRight.putDouble("x", this.points[1].x);
      bottomRight.putDouble("y", this.points[1].y);
      quadMap.putBundle("bottomRight", bottomRight);

      Bundle topLeft = new Bundle();
      topLeft.putDouble("x", this.points[3].x);
      topLeft.putDouble("y", this.points[3].y);
      quadMap.putBundle("topLeft", topLeft);

      Bundle topRight = new Bundle();
      topRight.putDouble("x", this.points[0].x);
      topRight.putDouble("y", this.points[0].y);
      quadMap.putBundle("topRight", topRight);

      Bundle dimensions = new Bundle();
      dimensions.putDouble("height", this.sourceSize.height);
      dimensions.putDouble("width", this.sourceSize.width);
      quadMap.putBundle("dimensions", dimensions);

      return quadMap;
    }
}
