//
//  MapViewController.m
//  bhkeverthing
//
//  Created by 白洪坤 on 16/10/26.
//  Copyright © 2016年 白洪坤. All rights reserved.
//

#import "MapViewController.h"
#import <BaiduMapAPI_Map/BMKMapView.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import "BikeModel.h"


#define BikeURL @"http://c.ggzxc.com.cn/wz/np_getBikes.do"

@interface MapViewController ()<BMKMapViewDelegate,BMKLocationServiceDelegate,NSURLConnectionDataDelegate>{
    BMKMapView *_mapView;
    BMKLocationService *_locService;
}
@property (nonatomic, strong) NSMutableArray *bikeModelarray;
@property (nonatomic, assign) CLLocationDegrees latitude;
@property (nonatomic, assign) CLLocationDegrees longitude;
@property (nonatomic, assign) BOOL isZero;
@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化BMKLocationService
    _locService = [[BMKLocationService alloc]init];
    _locService.delegate = self;
    //启动LocationService
    [_locService startUserLocationService];
    
    _mapView = [[BMKMapView alloc]initWithFrame:self.view.frame];
    //开启定位
    _mapView.showsUserLocation = YES;
    [_mapView setUserTrackingMode:BMKUserTrackingModeFollow];
    [_mapView setZoomLevel:18];
    self.view = _mapView;
    
    _bikeModelarray = [[NSMutableArray alloc]init];
    
    double latitudel = 30.193614;
    double longitudel = 120.227127;
    [self didUpdateBikeLocation:latitudel longitude:longitudel];
}

- (void)viewWillAppear:(BOOL)animated
{
    [_mapView viewWillAppear];
    _mapView.delegate = self; // 此处记得不用的时候需要置nil，否则影响内存的释放
}
- (void)viewWillDisappear:(BOOL)animated
{
    [_mapView viewWillDisappear];
    _mapView.delegate = nil; // 不用时，置nil
}

- (void)BikePointAnnotation:(BikeModel *)bikeModel{
    BMKPointAnnotation *pointAnnotation = [[BMKPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(bikeModel.lat - 0.000220, bikeModel.lon - 0.000080);
    pointAnnotation.title = bikeModel.name;
    pointAnnotation.subtitle = [NSString stringWithFormat:@"可租%ld，可还%ld",(long)bikeModel.rentcount,(long)bikeModel.restorecount];
    [_mapView addAnnotation:pointAnnotation];
    [_bikeModelarray addObject:bikeModel];
    
}

- (void)BikeRemovePointAnnotation:(BikeModel *)bikeModel{
    BMKPointAnnotation *pointAnnotation = [[BMKPointAnnotation alloc] init];
    pointAnnotation.coordinate = CLLocationCoordinate2DMake(bikeModel.lat - 0.000220, bikeModel.lon - 0.000080);
    [_mapView removeAnnotation:pointAnnotation];
    //[_bikeModelarray removeObject:bikeModel];
}

//根据anntation生成对应的View
- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id<BMKAnnotation>)annotation{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]])
    {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        BMKAnnotationView *annotationView = (BMKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[BMKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        NSInteger Bikecount = [[annotation.subtitle substringFromIndex:annotation.subtitle.length - 1] intValue];
        BOOL isPureInt = [self isPureInt:[annotation.subtitle substringFromIndex:annotation.subtitle.length - 2]];
        if (isPureInt) {
            annotationView.image = [UIImage imageNamed:@"58.png"];
        }else{
            if (Bikecount == 0) {
                annotationView.image = [UIImage imageNamed:@"29.png"];
            }else{
                annotationView.image = [UIImage imageNamed:@"58.png"];
            }
        }
        annotationView.canShowCallout = YES;
        //设置中心点偏移，使得标注底部中间点成为经纬度对应点
        annotationView.centerOffset = CGPointMake(0, -18);
        return annotationView;
    }
    return nil;
}

//处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation{
    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
    [_mapView updateLocationData:userLocation];
    _latitude = userLocation.location.coordinate.latitude;
    _longitude = userLocation.location.coordinate.longitude;
    [self didUpdateBikeLocation:_latitude longitude:_longitude];
}
//当mapView新添加annotation views时，调用此接口
- (void)mapView:(BMKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
    BMKAnnotationView *view = views[0];
    
    // 放到该方法中用以保证userlocation的annotationView已经添加到地图上了。
    if ([view.annotation isKindOfClass:[BMKUserLocation class]])
    {
        view.calloutOffset = CGPointMake(0, 0);
    }

}

//根据位置信息更新车位信息
- (void)didUpdateBikeLocation:(double)latitude longitude:(double)longitude{
    NSString *bikeUrl = [NSString stringWithFormat:@"%@?lat=%f&lng=%f",BikeURL,latitude,longitude];
    NSURL *url=[NSURL URLWithString:bikeUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue=[NSOperationQueue mainQueue];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        if (!connectionError) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            BikeModel *bikeModel;
            NSInteger countI = [dic[@"count"] integerValue];
            for (int i = 0;i < countI; i++) {
                bikeModel = [BikeModel DeviceinfoWithDict:dic[@"data"][i]];
                for (BikeModel *bikeModelold in _bikeModelarray) {
                    if (bikeModel.number == bikeModelold.number) {
                        if (bikeModel.restorecount == bikeModelold.restorecount) {
                            return;
                        }else{
                            //移除坐标
                            NSLog(@"旧：%@ 可租%ld，可还%ld",bikeModelold.name,bikeModelold.rentcount,bikeModelold.restorecount);
                            NSLog(@"新：%@ 可租%ld，可还%ld",bikeModel.name,bikeModel.rentcount,bikeModel.restorecount);
                            [self BikeRemovePointAnnotation:bikeModelold];
                        }
                    }
                }
                [self BikePointAnnotation:bikeModel];
            }
        }
    }];
}

- (BOOL)isPureInt:(NSString *)string{
    
    NSScanner* scan = [NSScanner scannerWithString:string];
    
    int val;
    
    return [scan scanInt:&val] && [scan isAtEnd];
    
}
@end
