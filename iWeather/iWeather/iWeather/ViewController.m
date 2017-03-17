//
//  ViewController.m
//  iWeather
//
//  Created by Changsong Li on 11/3/16.
//  Copyright © 2016 ChangsongLiCo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController()

// location
@property (strong, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSString *latitutde;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentWeathDetailLabel;

// current
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *higheAndLowLabel;
@property (weak, nonatomic) IBOutlet UILabel *todayLabel;

// hour
@property (weak, nonatomic) IBOutlet UIScrollView *hourlyScrollView;

// future 7 days
@property (weak, nonatomic) IBOutlet UIScrollView *comingDaysScrollView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waitingIndicator;

// arrays for hourly
@property (strong, nonatomic) NSMutableArray *hourlyHour;
@property (strong, nonatomic) NSMutableArray *tempHour;
@property (strong, nonatomic) NSMutableArray *imageHour;

// arrays for dayly
@property (strong, nonatomic) NSMutableArray *dayOfWeekDay;
@property (strong, nonatomic) NSMutableArray *tempDay;
@property (strong, nonatomic) NSMutableArray *imageDay;

@property (nonatomic) int unit;
@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *timeNow;
@property (strong, nonatomic) NSString *tomorrowSummary;
@property (weak, nonatomic) IBOutlet UISegmentedControl *unitSettingSeg;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // choose temperature unit
    NSString *unit = [[NSUserDefaults standardUserDefaults] objectForKey:@"unit"];
    if(unit){
        [self.unitSettingSeg setSelectedSegmentIndex:[unit integerValue]];
    }
    
    [self setUpHourlyLabelArrays];
    [self setUpDaylyLabelArrays];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewWillAppear:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // start indicator
    [self.waitingIndicator startAnimating];
    
    // set up location managers
    locationManager = [[CLLocationManager alloc]init];
    geocoder = [[CLGeocoder alloc] init];
    
    NSString *unit = [[NSUserDefaults standardUserDefaults] objectForKey:@"unit"];
    if(unit){
        if([unit isEqualToString:@"0"]){
            self.unit = 0;
        }else{
            self.unit = 1;
        }
    }else{
        self.unit = 0;
    }
    
    [self getLocation];
}

- (IBAction)changeUnitAction:(UISegmentedControl *)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *unit = [NSString stringWithFormat:@"%ld", (long)[self.unitSettingSeg selectedSegmentIndex]];
    [userDefaults setObject:unit forKey:@"unit"];
    [userDefaults synchronize];
    [self viewWillAppear:YES];
}

#pragma mark - Notification

-(void)sendNotification:(NSString *)title withBody:(NSString *)body withTime:(long)time{
    
    // setting up notification
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.title = title;
    content.body = body;
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:time repeats:NO];
    
    NSString *identifier = @"UYLLocalNotification";
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                          content:content
                                                                          trigger:trigger];
    [center removeAllPendingNotificationRequests];
    // trigger notification
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
        }
    }];
}

- (NSString *)tempConvertFromFToC:(NSString *)fTemp{
    long temp = [fTemp integerValue];
    temp = (temp - 32) * 5 / 9;
    return [NSString stringWithFormat:@"%ld", temp];
}

- (void) setUpHourlyLabelArrays{
    // hourly Labels arrays
    self.hourlyHour = [[NSMutableArray alloc]init];
    self.tempHour = [[NSMutableArray alloc]init];
    self.imageHour = [[NSMutableArray alloc]init];
    
    for(int i = 0; i < 24; i++){
        // hour labels
        UILabel *hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(10 + 55 * i , 3, 40, 30)];
        hourLabel.backgroundColor = [UIColor clearColor];
        hourLabel.textAlignment = NSTextAlignmentCenter;
        hourLabel.textColor = [UIColor whiteColor];
        hourLabel.numberOfLines = 0;
        hourLabel.font = [hourLabel.font fontWithSize:12];
        [self.hourlyScrollView addSubview:hourLabel];
        [self.hourlyHour addObject:hourLabel];
        
        // temperature labels
        UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(10 + 55 * i , 50, 40, 30)];
        tempLabel.backgroundColor = [UIColor clearColor];
        tempLabel.textAlignment = NSTextAlignmentCenter;
        tempLabel.textColor = [UIColor whiteColor];
        tempLabel.numberOfLines = 0;
        tempLabel.font = [tempLabel.font fontWithSize:12];
        [self.hourlyScrollView addSubview:tempLabel];
        [self.tempHour addObject:tempLabel];
        
        // icon images
        UIImageView *icon =[[UIImageView alloc] initWithFrame:CGRectMake(17 + 55 * i, 30, 25, 25)];
        [self.hourlyScrollView addSubview:icon];
        [self.imageHour addObject:icon];
    }
}

- (void) setUpDaylyLabelArrays{
    // dayly labels arrays
    self.dayOfWeekDay = [[NSMutableArray alloc]init];
    self.tempDay = [[NSMutableArray alloc]init];
    self.imageDay = [[NSMutableArray alloc]init];
    for(int i = 0; i < 7; i++){
        // create day of week label
        UILabel *dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(13, 5 + 32 * i, 100, 30)];
        dayLabel.backgroundColor = [UIColor clearColor];
        dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.textColor = [UIColor whiteColor];
        dayLabel.numberOfLines = 0;
        dayLabel.textAlignment = NSTextAlignmentLeft;
        dayLabel.font = [dayLabel.font fontWithSize:16];
        [self.comingDaysScrollView addSubview:dayLabel];
        [self.dayOfWeekDay addObject:dayLabel];
        
        // create temperature range labels
        UILabel *tempLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 113, 5 + 32 * i, 100, 30)];
        tempLabel.backgroundColor = [UIColor clearColor];
        tempLabel.textAlignment = NSTextAlignmentCenter;
        tempLabel.textColor = [UIColor whiteColor];
        tempLabel.numberOfLines = 0;
        tempLabel.textAlignment = NSTextAlignmentRight;
        tempLabel.font = [tempLabel.font fontWithSize:16];
        [self.comingDaysScrollView addSubview:tempLabel];
        [self.tempDay addObject:tempLabel];
        
        //create icon
        UIImageView *icon =[[UIImageView alloc] initWithFrame:CGRectMake( self.view.frame.size.width / 2 - 13, 8 + 32 * i, 26, 26)];
        [self.comingDaysScrollView addSubview:icon];
        [self.imageDay addObject:icon];
    }
}

- (IBAction)powerByDarkSkyAction:(UIButton *)sender {
    UIApplication *application = [UIApplication sharedApplication];
    NSURL *url = [NSURL URLWithString:@"https://darksky.net/poweredby/"];
    [application openURL:url options:@{} completionHandler:nil];
}

#pragma mark - Temperature

- (void)getTemperature{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.darksky.net/forecast/59189b267af121d768bcdc739d4040bc/%@,%@",self.latitutde, self.longitude]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:
                                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                                      
                                        if(data){
                                            NSData *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [self updateCurrentLabelsWithDatas:jsonData];
                                                [self createHourlyLabelsWithDatas:jsonData];
                                                [self updateComming7DaysLabelsWithDatas:jsonData];
                                                // stop active indicator
                                                [self.waitingIndicator stopAnimating];});
                                        }
                                  }];
    [task resume];

}

static inline NSString *stringFromWeekday(int weekday){
    static NSString *strings[] = {
        @"Sunday",
        @"Monday",
        @"Tuesday",
        @"Wednesday",
        @"Thursday",
        @"Friday",
        @"Saturday",
    };
    
    return strings[weekday - 1];
}

- (void)updateCurrentLabelsWithDatas:(NSData *) data{
    NSData *currently = [data valueForKey:@"currently"];
    
    // current temperature
    NSString *temp = [currently valueForKey:@"temperature"];
    temp = [NSString stringWithFormat:@"%.0f", [temp doubleValue]];
    if(self.unit == 0){
        temp = [self tempConvertFromFToC:temp];
    }
    self.currentTempLabel.text = temp;
    [self.currentTempLabel setOpaque:NO];
    
    // current time
    self.timeNow = [currently valueForKey:@"time"];
    
    // current weather detail
    NSString *weatherDetail = [currently valueForKey:@"summary"];
    weatherDetail = [weatherDetail stringByReplacingOccurrencesOfString:@" Day" withString:@""];
    weatherDetail = [weatherDetail stringByReplacingOccurrencesOfString:@" Night" withString:@""];
    
    self.currentWeathDetailLabel.text = weatherDetail;
    
    // current day of week
    NSString *time = [currently valueForKey:@"time"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
    NSString *dayOfWeek = stringFromWeekday((int)[components weekday]);
    self.todayLabel.text = @"Today";
    self.currentTimeLabel.text = dayOfWeek;
    
    // highest and lowest temperature
    NSData *today = [[[data valueForKey:@"daily"] valueForKey:@"data"] objectAtIndex:0];
    NSString *highestTemp = [today valueForKey:@"temperatureMax"];
    NSString *lowestTemp = [today valueForKey:@"temperatureMin"];
    
    if(self.unit == 0){
        highestTemp = [self tempConvertFromFToC:highestTemp];
        lowestTemp = [self tempConvertFromFToC:lowestTemp];
    }
    
    self.higheAndLowLabel.text = [NSString stringWithFormat:@"%.0f°     %.0f°", [lowestTemp doubleValue], [highestTemp doubleValue]];
    
}

- (void)createHourlyLabelsWithDatas:(NSData *) data{
    NSString *notificationTime = @"0";
    
    for(int i = 0; i < 24; i++){
        // hour detail
        NSData *hourDetail = [[[data valueForKey:@"hourly"] valueForKey:@"data"] objectAtIndex:i];
        NSString *time = [hourDetail valueForKey:@"time"];
        
        // get hour and temp string
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:(NSCalendarUnitHour) fromDate:date];
        
        long hourNum = [components hour];
        NSString *hour = @"";
        if(hourNum == 0){
            hour = @"12AM";
        }else if(hourNum == 12){
            hour = @"12PM";
        }else if(hourNum > 12){
            hour = [NSString stringWithFormat:@"%ldPM", hourNum - 12];
        }else{
            hour = [NSString stringWithFormat:@"%ldAM", hourNum];
        }
        
        if(i == 0)
            hour = @"Now";
        
        NSString *temp = [NSString stringWithFormat:@"%.0f", [[hourDetail valueForKey:@"temperature"] doubleValue]];
        
        if(self.unit == 0){
            temp = [self tempConvertFromFToC:temp];
        }
        
        //create hour labels
        UILabel *hourLabel = [self.hourlyHour objectAtIndex:i];
        hourLabel.text = hour;
        
        //create temperature labels
        UILabel *tempLabel = [self.tempHour objectAtIndex:i];
        tempLabel.text = [temp stringByAppendingString:@"°"];
        
        //create icon
        NSString *iconString = [hourDetail valueForKey:@"icon"];
        UIImageView *icon = [self.imageHour objectAtIndex:i];
        NSString *imageName = [self getIconImageNameByIcon:iconString];
        icon.image = [UIImage imageNamed:imageName];
        
        if([hour isEqualToString:@"8PM"])
            notificationTime = time;
        
    }

    // if now is notification time, don't set notification schedule. Otherwise, set notification.
    if([notificationTime doubleValue] != 0){
        double notificationTimeFromNow = [notificationTime doubleValue] - [self.timeNow doubleValue];
        NSLog(@"%f", notificationTimeFromNow);
        [self sendNotification:@"Tomorrow's weather" withBody:self.tomorrowSummary withTime:notificationTimeFromNow];
    }
    
    // set content size and border
    int contentWidth = 5 + 24 * 55;
    self.hourlyScrollView.contentSize = CGSizeMake(contentWidth, 80);
    
    CALayer *TopBorder = [CALayer layer];
    TopBorder.frame = CGRectMake(0.0f, 0.0f, contentWidth, 0.4f);
    TopBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.hourlyScrollView.layer addSublayer:TopBorder];
    
    CALayer *botBorder = [CALayer layer];
    botBorder.frame = CGRectMake(0.0f, self.hourlyScrollView.frame.size.height - 0.4f, contentWidth, 0.4f);
    botBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.hourlyScrollView.layer addSublayer:botBorder];
}

- (void)updateComming7DaysLabelsWithDatas:(NSData *) data{
    for(int i = 0; i < 7; i++){
        // get all info needed
        NSData *comingDay = [[[data valueForKey:@"daily"] valueForKey:@"data"] objectAtIndex:i+1];
        NSString *time = [comingDay valueForKey:@"time"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]];
        
        // get tomorrow summary
        if(i == 0){
            self.tomorrowSummary = [comingDay valueForKey:@"summary"];
            NSLog(@"%@",self.tomorrowSummary);
        }
        
        // get day of week
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:date];
        NSString *dayOfWeek = stringFromWeekday((int)[components weekday]);
        
        self.currentTimeLabel.text = dayOfWeek;
        
        // get lowest and highest temperature
        NSString *highestTemp = [comingDay valueForKey:@"temperatureMax"];
        NSString *lowestTemp = [comingDay valueForKey:@"temperatureMin"];
        
        if(self.unit == 0){
            highestTemp = [self tempConvertFromFToC:highestTemp];
            lowestTemp = [self tempConvertFromFToC:lowestTemp];
        }
        
        // create day of week labels
        UILabel *dayLabel = [self.dayOfWeekDay objectAtIndex:i];
        dayLabel.text = dayOfWeek;
        
        // create temperature range labels
        UILabel *tempLabel = [self.tempDay objectAtIndex:i];
        tempLabel.text = [NSString stringWithFormat:@"%3.0f  %3.0f", [lowestTemp doubleValue], [highestTemp doubleValue] ];
        
        // set content size and border
        int contentWidth = 5 + 32 * 7;
        self.comingDaysScrollView.contentSize = CGSizeMake(self.comingDaysScrollView.frame.size.width, contentWidth);
        
        //create icon
        NSString *iconString = [comingDay valueForKey:@"icon"];
        UIImageView *icon = [self.imageDay objectAtIndex:i];
        icon.image = [UIImage imageNamed:[self getIconImageNameByIcon:iconString]];
    }
}

- (NSString *)getIconImageNameByIcon:(NSString *)icon{
    if([icon isEqualToString:@"clear-day"])
        return @"Sun";
    else if([icon isEqualToString:@"clear-night"])
        return @"Moon";
    else if([icon isEqualToString:@"rain"])
        return @"Rain";
    else if([icon isEqualToString:@"snow"])
        return @"Snow";
    else if([icon isEqualToString:@"sleet"])
        return @"Sleet";
    else if([icon isEqualToString:@"wind"])
        return @"Windy Weather";
    else if([icon isEqualToString:@"fog"])
        return @"Fog Day";
    else if([icon isEqualToString:@"partly-cloudy-day"])
        return @"Partly Cloudy Day";
    else
        return @"Cloud";
}

#pragma mark - Location

- (void)getLocation{
    // init location manager and setting up
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager requestWhenInUseAuthorization];
    [locationManager startUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self displayMessageWithTitle:@"Error" withMessage:@"Fail to get your location."];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        self.longitude = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        self.latitutde = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    
    // Stop Location Manager
    [locationManager stopUpdatingLocation];
    
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            self.cityLabel.text = placemark.locality;
            self.city = placemark.locality;
        }else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
    
    // set up temperatures
    [self getTemperature];
}

- (void)displayMessageWithTitle:(NSString *) title withMessage:(NSString *) message{
    UIAlertController *myAlertController = [UIAlertController alertControllerWithTitle: title
                                                                               message: message
                                                                        preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"OK"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             [myAlertController dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    
    [myAlertController addAction: ok];
    [self presentViewController:myAlertController animated:YES completion:nil];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    segue.destinationViewController.view.backgroundColor = self.view.backgroundColor;
}

@end
