//
//  AppDelegate.h
//  bhkeverthing
//
//  Created by 白洪坤 on 16/10/26.
//  Copyright © 2016年 白洪坤. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Map/BMKMapView.h>//只引入所需的单个头文件

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    BMKMapManager* _mapManager; 
}

@property (strong, nonatomic) UIWindow *window;


@end

