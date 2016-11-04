//
//  ViewController.m
//  iWeather
//
//  Created by Changsong Li on 11/3/16.
//  Copyright © 2016 ChangsongLiCo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;

// location
@property (strong, nonatomic) NSString *longitude;
@property (strong, nonatomic) NSString *latitutde;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;

// current
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTempLabel;
@property (weak, nonatomic) IBOutlet UILabel *higheAndLowLabel;

// future 7 days
@property (weak, nonatomic) IBOutlet UILabel *comingDay1Label;
@property (weak, nonatomic) IBOutlet UILabel *comingDay2Label;
@property (weak, nonatomic) IBOutlet UILabel *comingDay3Label;
@property (weak, nonatomic) IBOutlet UILabel *comingDay4Label;
@property (weak, nonatomic) IBOutlet UILabel *comingDay5Label;
@property (weak, nonatomic) IBOutlet UILabel *comingDay6Label;
@property (weak, nonatomic) IBOutlet UILabel *comingDay7Label;

@property (strong, nonatomic) NSMutableArray *labels;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // set up location managers
    locationManager = [[CLLocationManager alloc]init];
    geocoder = [[CLGeocoder alloc] init];
    
    
    [self updateView];
    [self getLocation];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    // get location and then get temperature after get location
    [self getLocation];
}

- (void)updateView{
    // init label array
    self.labels =[[NSMutableArray alloc]init];
    [self.labels addObject:self.comingDay1Label];
    [self.labels addObject:self.comingDay2Label];
    [self.labels addObject:self.comingDay3Label];
    [self.labels addObject:self.comingDay4Label];
    [self.labels addObject:self.comingDay5Label];
    [self.labels addObject:self.comingDay6Label];
    [self.labels addObject:self.comingDay7Label];
    
    self.cityLabel.text = @"Loading...";
    self.currentTimeLabel.text = @"";
    self.currentTempLabel.text = @"";
    self.higheAndLowLabel.text = @"";
    for(UILabel *label in self.labels){
        label.text = @"";
    }
    
    CGFloat width = self.view.frame.size.width;
    
    switch ((int)width) {
        case 320:
            self.currentTimeLabel.font = [self.currentTimeLabel.font fontWithSize:13];
            //self.currentTempLabel.font = [self.currentTempLabel.font fontWithSize:13];
            self.higheAndLowLabel.font = [self.higheAndLowLabel.font fontWithSize:13];
            for(UILabel *label in self.labels){
                label.font = [label.font fontWithSize:13];
            }
            break;
            
        default:
            self.topConstraint.constant = 50;
            break;
    }
}
#pragma mark - Temperature

- (void)getTemperature{
    NSError *error;
    NSURLResponse *response;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.darksky.net/forecast/59189b267af121d768bcdc739d4040bc/%@,%@",self.latitutde, self.longitude]];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
    
    if(data){
        NSData *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        [self updateCurrentLabelsWithDatas:jsonData];
        [self updateComming7DaysLabelsWithDatas:jsonData];
    }
}

- (void)updateCurrentLabelsWithDatas:(NSData *) data{
    NSData *currently = [data valueForKey:@"currently"];
    
    // current temperature
    NSString *temp = [currently valueForKey:@"temperature"];
    self.currentTempLabel.text = [NSString stringWithFormat:@"%@",[self doubleStringToIntTempString:temp]];
    self.currentTempLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Image"]];
    [self.currentTempLabel setOpaque:NO];
    
    // current time
    NSString *time = [currently valueForKey:@"time"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]];
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitDay | NSCalendarUnitMonth  | NSCalendarUnitMinute | NSCalendarUnitHour fromDate:date];
    NSInteger minute = [components minute];
    NSInteger hour = [components hour];
    NSInteger month = [components month];
    NSInteger day = [components day];
    
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%zd/%zd  %02zd:%02zd", month, day, hour, minute];
    
    // highest and lowest temperature
    NSData *today = [[[data valueForKey:@"daily"] valueForKey:@"data"] objectAtIndex:0];
    NSString *highestTemp = [today valueForKey:@"temperatureMax"];
    NSString *lowestTemp = [today valueForKey:@"temperatureMin"];
    
    self.higheAndLowLabel.text = [NSString stringWithFormat:@"%@ %@", [self doubleStringToIntTempString:highestTemp], [self doubleStringToIntTempString:lowestTemp]];
    
}

- (void)updateComming7DaysLabelsWithDatas:(NSData *) data{
    for(int i = 0; i < [self.labels count]; i++){
        // get all info needed
        NSData *comingDay = [[[data valueForKey:@"daily"] valueForKey:@"data"] objectAtIndex:i+1];
        NSString *time = [comingDay valueForKey:@"time"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[time doubleValue]];
        
        NSDateComponents *components = [[NSCalendar currentCalendar] components: NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
        
        NSInteger day = [components day];
        NSInteger month = [components month];
        NSString *highestTemp = [comingDay valueForKey:@"temperatureMax"];
        NSString *lowestTemp = [comingDay valueForKey:@"temperatureMin"];
        
        
        // update to label
        UILabel *comingDateLabel = [self.labels objectAtIndex:i];
        comingDateLabel.text = [NSString stringWithFormat:@"%zd/%zd  %@-%@", month, day, [self doubleStringToIntTempString:highestTemp], [self doubleStringToIntTempString:lowestTemp]];
    }
}

-(NSString *) doubleStringToIntTempString:(NSString *)temp{
    return [NSString stringWithFormat:@"%dº",((int)[temp floatValue])];
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
    
    // set up temperatures
    [self getTemperature];
    
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error == nil && [placemarks count] > 0) {
            placemark = [placemarks lastObject];
            self.cityLabel.text = placemark.locality;
        }else {
            NSLog(@"%@", error.debugDescription);
        }
    } ];
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

@end
