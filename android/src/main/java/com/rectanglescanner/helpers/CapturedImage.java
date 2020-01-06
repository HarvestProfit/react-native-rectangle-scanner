package com.rectanglescanner.helpers;

import org.opencv.core.Mat;
import org.opencv.core.Point;
import org.opencv.core.Size;

/**
 * Created by Jake on Jan 6, 2020.
 */
public class CapturedImage {

    public Mat original;
    public Mat processed;
    public Point[] previewPoints;
    public Size previewSize;
    public Size originalSize;

    public Point[] originalPoints;

    public int heightWithRatio;
    public int widthWithRatio;

    public CapturedImage(Mat original) {
        this.original = original;
    }

    public Mat getProcessed() {
        return processed;
    }

    public CapturedImage setProcessed(Mat processed) {
        this.processed = processed;
        return this;
    }

    public void release() {
        if (processed != null) {
            processed.release();
        }
        if (original != null) {
            original.release();
        }
    }
}
