//
//  DlibWrapper.m
//  dlibDemo
//
//  Created by Xun Gong on 2017-11-04.
//  Copyright © 2017 clarke. All rights reserved.
//
// https://github.com/lincolnhard/head-pose-estimation/blob/master/video_test_shape.cpp

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>
#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <dlib/opencv/cv_image.h>
#include <dlib/opencv.h>
#include "opencv2/calib3d/calib3d.hpp"

@interface DlibWrapper ()

@property (assign) BOOL prepared;

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end
@implementation DlibWrapper {
    dlib::shape_predictor sp;
    std::vector<cv::Point2d> image_pts;
    std::vector<cv::Point3d> object_pts;
    std::vector<cv::Point3d> reprojectsrc;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
    //fill in 3D ref points(world coordinates), model referenced from http://aifi.isr.uc.pt/Downloads/OpenGL/glAnthropometric3DModel.cpp
//    object_pts.push_back(cv::Point3d(6.825897, 6.760612, 4.402142));     //#33 left brow left corner
//    object_pts.push_back(cv::Point3d(1.330353, 7.122144, 6.903745));     //#29 left brow right corner
//    object_pts.push_back(cv::Point3d(-1.330353, 7.122144, 6.903745));    //#34 right brow left corner
//    object_pts.push_back(cv::Point3d(-6.825897, 6.760612, 4.402142));    //#38 right brow right corner
//    object_pts.push_back(cv::Point3d(5.311432, 5.485328, 3.987654));     //#13 left eye left corner
//    object_pts.push_back(cv::Point3d(1.789930, 5.393625, 4.413414));     //#17 left eye right corner
//    object_pts.push_back(cv::Point3d(-1.789930, 5.393625, 4.413414));    //#25 right eye left corner
//    object_pts.push_back(cv::Point3d(-5.311432, 5.485328, 3.987654));    //#21 right eye right corner
//    object_pts.push_back(cv::Point3d(2.005628, 1.409845, 6.165652));     //#55 nose left corner
//    object_pts.push_back(cv::Point3d(-2.005628, 1.409845, 6.165652));    //#49 nose right corner
//    object_pts.push_back(cv::Point3d(2.774015, -2.080775, 5.048531));    //#43 mouth left corner
//    object_pts.push_back(cv::Point3d(-2.774015, -2.080775, 5.048531));   //#39 mouth right corner
//    object_pts.push_back(cv::Point3d(0.000000, -3.116408, 6.097667));    //#45 mouth central bottom corner
//    object_pts.push_back(cv::Point3d(0.000000, -7.415691, 4.070434));    //#6 chin corner
    object_pts.push_back(cv::Point3d(0,0,0)); // nose tip
    object_pts.push_back(cv::Point3d(0, 330, -65)); // chin
    object_pts.push_back(cv::Point3d(-225,-170,-135)); // left eye left corner
    object_pts.push_back(cv::Point3d(225,-170,-135)); // right eye right corner
    object_pts.push_back(cv::Point3d(-150,150,-125)); // left mouth corner
    object_pts.push_back(cv::Point3d(150,150,-125)); // right mouth corner
    //reproject 3D points world coordinate axis to verify result pose
    reprojectsrc.push_back(cv::Point3d(0, 0, 1000.0));
//    reprojectsrc.push_back(cv::Point3d(10.0, 10.0, -10.0));
//    reprojectsrc.push_back(cv::Point3d(10.0, -10.0, -10.0));
//    reprojectsrc.push_back(cv::Point3d(10.0, -10.0, 10.0));
//    reprojectsrc.push_back(cv::Point3d(-10.0, 10.0, 10.0));
//    reprojectsrc.push_back(cv::Point3d(-10.0, 10.0, -10.0));
//    reprojectsrc.push_back(cv::Point3d(-10.0, -10.0, -10.0));
//    reprojectsrc.push_back(cv::Point3d(-10.0, -10.0, 10.0));
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects {
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    // set_size expects rows, cols format
    img.set_size(height, width);
    
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [DlibWrapper convertCGRectValueArray:rects];
    cv::Mat cvImage = dlib::toMat(img);
    
    // for every detected face
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        dlib::point a, b, c, d;
        a.x() = oneFaceRect.left();
        a.y() = oneFaceRect.top();
        b.x() = oneFaceRect.left();
        b.y() = oneFaceRect.bottom();
        c.x() = oneFaceRect.right();
        c.y() = oneFaceRect.top();
        d.x() = oneFaceRect.right();
        d.y() = oneFaceRect.bottom();
        draw_solid_circle(img, a, 10, dlib::rgb_pixel(255, 255, 0));
        draw_solid_circle(img, b, 10, dlib::rgb_pixel(255, 255, 0));
        draw_solid_circle(img, c, 10, dlib::rgb_pixel(255, 255, 0));
        draw_solid_circle(img, d, 10, dlib::rgb_pixel(255, 255, 0));
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
//            if (k == 30 || k == 8 || k == 36 || k == 45 || k == 48 || k == 54) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
//            }
        }
        // draw model 2d points
        for (unsigned long k = 0; k < object_pts.size(); k++) {
            dlib::point p;
            p.x() = object_pts[k].x + width / 2;
            p.y() = object_pts[k].y + height / 2;
            draw_solid_circle(img, p, 3, dlib::rgb_pixel(255,0,0));
        }
        //fill in 2D ref points, annotations follow https://ibug.doc.ic.ac.uk/resources/300-W/
//        image_pts.push_back(cv::Point2d(shape.part(17).x(), shape.part(17).y())); //#17 left brow left corner
//        image_pts.push_back(cv::Point2d(shape.part(21).x(), shape.part(21).y())); //#21 left brow right corner
//        image_pts.push_back(cv::Point2d(shape.part(22).x(), shape.part(22).y())); //#22 right brow left corner
//        image_pts.push_back(cv::Point2d(shape.part(26).x(), shape.part(26).y())); //#26 right brow right corner
//        image_pts.push_back(cv::Point2d(shape.part(36).x(), shape.part(36).y())); //#36 left eye left corner
//        image_pts.push_back(cv::Point2d(shape.part(39).x(), shape.part(39).y())); //#39 left eye right corner
//        image_pts.push_back(cv::Point2d(shape.part(42).x(), shape.part(42).y())); //#42 right eye left corner
//        image_pts.push_back(cv::Point2d(shape.part(45).x(), shape.part(45).y())); //#45 right eye right corner
//        image_pts.push_back(cv::Point2d(shape.part(31).x(), shape.part(31).y())); //#31 nose left corner
//        image_pts.push_back(cv::Point2d(shape.part(35).x(), shape.part(35).y())); //#35 nose right corner
//        image_pts.push_back(cv::Point2d(shape.part(48).x(), shape.part(48).y())); //#48 mouth left corner
//        image_pts.push_back(cv::Point2d(shape.part(54).x(), shape.part(54).y())); //#54 mouth right corner
//        image_pts.push_back(cv::Point2d(shape.part(57).x(), shape.part(57).y())); //#57 mouth central bottom corner
//        image_pts.push_back(cv::Point2d(shape.part(8).x(), shape.part(8).y()));   //#8 chin corner
        image_pts.push_back(cv::Point2d(shape.part(30).x(), shape.part(30).y()));   //#30 nose tip
        image_pts.push_back(cv::Point2d(shape.part(8).x(), shape.part(8).y()));   //#8 chin corner
        image_pts.push_back(cv::Point2d(shape.part(36).x(), shape.part(36).y())); //#36 left eye left corner
        image_pts.push_back(cv::Point2d(shape.part(45).x(), shape.part(45).y())); //#45 right eye right corner
        image_pts.push_back(cv::Point2d(shape.part(48).x(), shape.part(48).y())); //#48 mouth left corner
        image_pts.push_back(cv::Point2d(shape.part(54).x(), shape.part(54).y())); //#54 mouth right corner
        
        draw_solid_circle(img, shape.part(17), 5, dlib::rgb_pixel(0, 255, 0));
        
        //Intrisics can be calculated using opencv sample code under opencv/sources/samples/cpp/tutorial_code/calib3d
        //Normally, you can also apprximate fx and fy by image width, cx by half image width, cy by half image height instead
        double focalLength = width;
        cv::Point center = cv::Point(width / 2.0, height / 2.0);
        double K[9] = { double(focalLength), 0.0, double(center.x),
                        0.0, double(focalLength), double(center.y),
                        0.0, 0.0, 1.0 };
        double D[5] = { 0,0,0,0,0};
        //fill in cam intrinsics and distortion coefficients
        cv::Mat cam_matrix = cv::Mat(3, 3, CV_64FC1, K);
        cv::Mat dist_coeffs = cv::Mat(5, 1, CV_64FC1, D);
        //result
        cv::Mat rotation_vec;                           //3 x 1
        cv::Mat rotation_mat;                           //3 x 3 R
        cv::Mat translation_vec;                        //3 x 1 T
        cv::Mat pose_mat = cv::Mat(3, 4, CV_64FC1);     //3 x 4 R | T
        cv::Mat euler_angle = cv::Mat(3, 1, CV_64FC1);
        //calc pose
        cv::solvePnP(object_pts, image_pts, cam_matrix, dist_coeffs, rotation_vec, translation_vec);
        
        //reproject
        
        std::vector<cv::Point2d> reprojectdst;
        //reprojected 2D points
        reprojectdst.resize(1);
        cv::projectPoints(reprojectsrc, rotation_vec, translation_vec, cam_matrix, dist_coeffs, reprojectdst);
        
        //draw axis
        dlib::draw_line(reprojectdst[0].x, reprojectdst[0].y, shape.part(30).x(), shape.part(30).y(), img, dlib::rgb_pixel(255, 0, 0));
//        dlib::draw_line(reprojectdst[0].x, reprojectdst[0].y, reprojectdst[1].x, reprojectdst[1].y, img, dlib::rgb_pixel(255, 0, 0));
//        dlib::draw_line(reprojectdst[2].x, reprojectdst[2].y, reprojectdst[1].x, reprojectdst[1].y, img, dlib::rgb_pixel(255, 0, 0));
//        dlib::draw_line(reprojectdst[2].x, reprojectdst[2].y, reprojectdst[3].x, reprojectdst[3].y, img, dlib::rgb_pixel(255, 0, 0));
//        dlib::draw_line(reprojectdst[0].x, reprojectdst[0].y, reprojectdst[3].x, reprojectdst[3].y, img, dlib::rgb_pixel(255, 0, 0));
//        line(temp, reprojectdst[0], reprojectdst[1], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[1], reprojectdst[2], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[2], reprojectdst[3], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[3], reprojectdst[0], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[4], reprojectdst[5], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[5], reprojectdst[6], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[6], reprojectdst[7], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[7], reprojectdst[4], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[0], reprojectdst[4], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[1], reprojectdst[5], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[2], reprojectdst[6], cv::Scalar(0, 0, 255));
//        line(temp, reprojectdst[3], reprojectdst[7], cv::Scalar(0, 0, 255));
        image_pts.clear();
    }
    
    // lets put everything back where it belongs
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);
        
        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}

@end

