package com.rectanglescanner.helpers;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.preference.PreferenceManager;
import android.util.Log;

import com.rectanglescanner.views.RectangleDetectionController;
import com.rectanglescanner.helpers.ImageProcessorMessage;
import com.rectanglescanner.helpers.Quadrilateral;
import com.rectanglescanner.helpers.CapturedImage;

import android.view.Surface;

import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.Mat;
import org.opencv.core.MatOfDouble;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Range;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.core.Rect;
import org.opencv.imgcodecs.Imgcodecs;
import org.opencv.imgproc.Imgproc;

import android.os.Bundle;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;

import com.facebook.react.bridge.Arguments;

/**
  Created by Jake on Jan 6, 2020.

  Async processes either the image preview frame to detect rectangles, or
  the captured image to crop and apply filters.
 */
public class ImageProcessor extends Handler {

    private static final String TAG = "ImageProcessor";
    private final RectangleDetectionController mMainActivity;
    private Quadrilateral lastDetectedRectangle = null;

    public ImageProcessor(Looper looper, RectangleDetectionController mainActivity, Context context) {
        super(looper);
        this.mMainActivity = mainActivity;
        SharedPreferences sharedPref = PreferenceManager.getDefaultSharedPreferences(context);
    }

    /**
    Receives an event message to handle async
    */
    public void handleMessage(Message msg) {
        if (msg.obj.getClass() == ImageProcessorMessage.class) {

            ImageProcessorMessage obj = (ImageProcessorMessage) msg.obj;

            String command = obj.getCommand();

            Log.d(TAG, "Message Received: " + command + " - " + obj.getObj().toString());
            if (command.equals("previewFrame")) {
                processPreviewFrame((Mat) obj.getObj());
            } else if (command.equals("pictureTaken")) {
                processCapturedImage((Mat) obj.getObj());
            }
        }
    }

    /**
    Detect a rectangle in the current frame from the camera video
    */
    private void processPreviewFrame(Mat frame) {
      rotateImageForScreen(frame);
      detectRectangleInFrame(frame);
      frame.release();
      mMainActivity.setImageProcessorBusy(false);
    }

    /**
    Process a single frame from the camera video
    */
    private void processCapturedImage(Mat picture) {
        Mat capturedImage = Imgcodecs.imdecode(picture, Imgcodecs.CV_LOAD_IMAGE_UNCHANGED);
        picture.release();

        Log.d(TAG, "processCapturedImage - imported image " + capturedImage.size().width + "x" + capturedImage.size().height);

        rotateImageForScreen(capturedImage);

        CapturedImage doc = cropImageToLatestQuadrilateral(capturedImage);

        mMainActivity.onProcessedCapturedImage(doc);
        doc.release();
        picture.release();

        mMainActivity.setImageProcessorBusy(false);
    }

    /**
    Detects a rectangle from the image and sets the last detected rectangle
    */
    private void detectRectangleInFrame(Mat inputRgba) {
        ArrayList<MatOfPoint> contours = findContours(inputRgba);
        Size srcSize = inputRgba.size();
        this.lastDetectedRectangle = getQuadrilateral(contours, srcSize);
        Bundle data = new Bundle();
        if (this.lastDetectedRectangle != null) {
          Bundle quadMap = this.lastDetectedRectangle.toBundle();
          data.putBundle("detectedRectangle", quadMap);
        } else {
          data.putBoolean("detectedRectangle", false);
        }

        mMainActivity.rectangleWasDetected(Arguments.fromBundle(data));
    }

    /**
    Crops the image to the latest detected rectangle and fixes perspective
    */
    private CapturedImage cropImageToLatestQuadrilateral(Mat capturedImage) {
        applyFilters(capturedImage);

        Mat doc;
        if (this.lastDetectedRectangle != null) {
            Mat croppedCapturedImage = this.lastDetectedRectangle.cropImageToRectangleSize(capturedImage);
            doc = fourPointTransform(croppedCapturedImage, this.lastDetectedRectangle.getPointsForSize(croppedCapturedImage.size()));
            croppedCapturedImage.release();
        } else {
            doc = new Mat(capturedImage.size(), CvType.CV_8UC4);
            capturedImage.copyTo(doc);
        }

        Core.flip(doc.t(), doc, 0);
        Core.flip(capturedImage.t(), capturedImage, 0);
        CapturedImage sd = new CapturedImage(capturedImage);

        sd.originalSize = capturedImage.size();
        sd.heightWithRatio = Double.valueOf(sd.originalSize.width).intValue();
        sd.widthWithRatio = Double.valueOf(sd.originalSize.height).intValue();
        return sd.setProcessed(doc);
    }

    private Quadrilateral getQuadrilateral(ArrayList<MatOfPoint> contours, Size srcSize) {

        int height = Double.valueOf(srcSize.height).intValue();
        int width = Double.valueOf(srcSize.width).intValue();
        Size size = new Size(width, height);

        double areaOfPreview = height * width;
        double minArea = size.area() * 0.01;
        MatOfPoint bestFittingContour = null;

        Log.i(TAG, "Size----->" + size);
        for (MatOfPoint c : contours) {
            double contourArea = Imgproc.contourArea(c);

            if (contourArea < minArea) {
                continue;
            }

            MatOfPoint2f c2f = new MatOfPoint2f(c.toArray());
            double peri = Imgproc.arcLength(c2f, true);
            MatOfPoint2f approx = new MatOfPoint2f();
            Imgproc.approxPolyDP(c2f, approx, 0.02 * peri, true);
            Point[] foundPoints = sortPoints(approx.toArray());
            if (isValidRectangle(foundPoints)) {
              return new Quadrilateral(c, foundPoints, new Size(srcSize.width, srcSize.height));
            }
        }
        return null;
    }

    private Point[] sortPoints(Point[] src) {

        ArrayList<Point> srcPoints = new ArrayList<>(Arrays.asList(src));

        Point[] result = { null, null, null, null };

        Comparator<Point> sumComparator = new Comparator<Point>() {
            @Override
            public int compare(Point lhs, Point rhs) {
                return Double.compare(lhs.y + lhs.x, rhs.y + rhs.x);
            }
        };

        Comparator<Point> diffComparator = new Comparator<Point>() {

            @Override
            public int compare(Point lhs, Point rhs) {
                return Double.compare(lhs.y - lhs.x, rhs.y - rhs.x);
            }
        };

        // top-left corner = minimal sum
        result[0] = Collections.min(srcPoints, sumComparator);

        // bottom-right corner = maximal sum
        result[2] = Collections.max(srcPoints, sumComparator);

        // top-right corner = minimal difference
        result[1] = Collections.min(srcPoints, diffComparator);

        // bottom-left corner = maximal difference
        result[3] = Collections.max(srcPoints, diffComparator);

        return result;
    }

    private boolean isValidRectangle(Point[] rp) {
        boolean isANormalShape = rp[0].x != rp[1].x && rp[1].y != rp[0].y && rp[2].y != rp[3].y && rp[3].x != rp[2].x;
        if (!isANormalShape) {
            return false;
        }

        double leftOffset = Math.abs(rp[0].x - rp[3].x);
        double rightOffset = Math.abs(rp[1].x - rp[2].x);
        double bottomOffset = Math.abs(rp[0].y - rp[1].y);
        double topOffset = Math.abs(rp[2].y - rp[3].y);

        double largestVertical = Math.max(leftOffset, rightOffset);
        double verticalOffset = Math.abs(leftOffset - rightOffset);
        double largestHorizontal = Math.max(topOffset, bottomOffset);
        double horizontalOffset = Math.abs(topOffset - bottomOffset);
        double largestSide = Math.max(largestHorizontal, largestVertical);
        double sideOffset = Math.abs(largestHorizontal - largestVertical);

        if (verticalOffset > (largestVertical * 0.9)) {
            return false;
        }

        if (horizontalOffset > (largestHorizontal * 0.9)) {
            return false;
        }

//        if (sideOffset > (largestSide * 0.995)) {
//            return false;
//        }
        return true;
    }

    private Mat fourPointTransform(Mat src, Point[] pts) {
        Point tl = pts[0];
        Point tr = pts[1];
        Point br = pts[2];
        Point bl = pts[3];

        double widthA = Math.sqrt(Math.pow(br.x - bl.x, 2) + Math.pow(br.y - bl.y, 2));
        double widthB = Math.sqrt(Math.pow(tr.x - tl.x, 2) + Math.pow(tr.y - tl.y, 2));

        double dw = Math.max(widthA, widthB);
        int maxWidth = Double.valueOf(dw).intValue();

        double heightA = Math.sqrt(Math.pow(tr.x - br.x, 2) + Math.pow(tr.y - br.y, 2));
        double heightB = Math.sqrt(Math.pow(tl.x - bl.x, 2) + Math.pow(tl.y - bl.y, 2));

        double dh = Math.max(heightA, heightB);
        int maxHeight = Double.valueOf(dh).intValue();

        Mat doc = new Mat(maxHeight, maxWidth, CvType.CV_8UC4);

        Mat src_mat = new Mat(4, 1, CvType.CV_32FC2);
        Mat dst_mat = new Mat(4, 1, CvType.CV_32FC2);

        src_mat.put(0, 0, tl.x, tl.y, tr.x, tr.y, br.x, br.y,
                bl.x, bl.y);
        dst_mat.put(0, 0, 0.0, 0.0, dw, 0.0, dw, dh, 0.0, dh);

        Mat m = Imgproc.getPerspectiveTransform(src_mat, dst_mat);

        Imgproc.warpPerspective(src, doc, m, doc.size());

        return doc;
    }

    private ArrayList<MatOfPoint> findContours(Mat src) {
        Mat cannedImage = applyCannedFilterToImage(src);

        ArrayList<MatOfPoint> contours = new ArrayList<>();
        Mat hierarchy = new Mat();

        Imgproc.findContours(cannedImage, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE);

        hierarchy.release();

        Collections.sort(contours, new Comparator<MatOfPoint>() {

            @Override
            public int compare(MatOfPoint lhs, MatOfPoint rhs) {
                return Double.compare(Imgproc.contourArea(rhs), Imgproc.contourArea(lhs));
            }
        });

        cannedImage.release();

        return contours;
    }

    /*!
     Applies filters to the image based on the set filter
     */
    public void applyFilters(Mat image) {
      int filterId = this.mMainActivity.getFilterId();
      switch (filterId) {
        case 1: {
          // original image
          break;
        }
        case 2: {
          applyGreyscaleFilterToImage(image);
          break;
        }
        case 3: {
          applyColorFilterToImage(image);
          break;
        }
        case 4: {
          applyBlackAndWhiteFilterToImage(image);
          break;
        }
        default:
          // original image
      }
    }

    /**
     * Returns the mean brightness level of the provided image
     * @param image
     * @return brightness level
     */
    public double brightnessOfImage(Mat image)
    {
        MatOfDouble meansrc= new MatOfDouble();
        MatOfDouble stdsrc= new MatOfDouble();

        Core.meanStdDev(image, meansrc, stdsrc);
        return meansrc.get(0,0)[0];
    }

    /*!
     Slightly enhances the black and white image
     */
    public Mat applyGreyscaleFilterToImage(Mat image)
    {
      Imgproc.cvtColor(image, image, Imgproc.COLOR_RGBA2GRAY);
      return image;
    }

    /*!
     Slightly enhances the black and white image
     */
    public Mat applyBlackAndWhiteFilterToImage(Mat image)
    {
      double imageBrightnessLevel = brightnessOfImage(image);
      image.convertTo(image, -1, 2.8  - (imageBrightnessLevel * 0.0045), imageBrightnessLevel * -1.15);
      Imgproc.cvtColor(image, image, Imgproc.COLOR_RGBA2GRAY);
      return image;
    }

    /*!
     Slightly enhances the color on the image
     */
    public Mat applyColorFilterToImage(Mat image)
    {
      double imageBrightnessLevel = brightnessOfImage(image);
      image.convertTo(image, -1, 2.8  - (imageBrightnessLevel * 0.0045), imageBrightnessLevel * -1.15);
      return image;
    }

    public Mat applyCannedFilterToImage(Mat image)
    {
      int blurSize = 5;
      int thresh = 100;
      double imageBrightnessLevel = brightnessOfImage(image);
      Mat colorAdjustedImage = new Mat();
      Mat cannedImage = new Mat();

      image.convertTo(colorAdjustedImage, -1, 2.8  - (imageBrightnessLevel * 0.0045), imageBrightnessLevel * -1.15);
      Imgproc.cvtColor(colorAdjustedImage, colorAdjustedImage, Imgproc.COLOR_RGBA2GRAY, 4);
        // Imgproc.equalizeHist(colorAdjustedImage, colorAdjustedImage);
      Imgproc.bilateralFilter(colorAdjustedImage, cannedImage, blurSize, blurSize * 2, blurSize / 2);
      Imgproc.Canny(cannedImage, cannedImage, thresh, thresh * 3, 3, true);
      colorAdjustedImage.release();
      return cannedImage;
    }


    public void rotateImageForScreen(Mat image) {
      switch (this.mMainActivity.lastDetectedRotation) {
        case Surface.ROTATION_90: {
          // Do nothing
          break;
        }
        case Surface.ROTATION_180: {
          Core.flip(image.t(), image, 0);
          break;
        }
        case Surface.ROTATION_270: {
          Core.flip(image, image, 0);
          Core.flip(image, image, 1);
          break;
        }
        case Surface.ROTATION_0:
        default: {
          Core.flip(image.t(), image, 1);
          break;
        }
      }
    }
}
