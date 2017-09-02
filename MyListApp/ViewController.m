//
//  ViewController.m
//  MyListApp
//
//  Created by Dragos Bercea  on 8/29/17.
//  Copyright © 2017 Dragos Bercea . All rights reserved.
//

#import "ViewController.h"
// a boolean to check if the user is on an ipad or an ipod:
#define ONIPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

@interface ViewController () <UITableViewDataSource,UITableViewDelegate> {
    
    NSMutableArray* tasks; // the array of strings with tasks
    NSMutableArray* dates; // the array of strings with dates
    
    __weak IBOutlet UITextField *addTaskField; // the text field for creating new tasks

}

@property (weak, nonatomic) IBOutlet UITableView *table; // the table

// for the date picker feature:
@property (strong, nonatomic) UIDatePicker* datePicker;
@property (strong,nonatomic) UIToolbar* toolBar;

@end


@implementation ViewController


- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self createArrays];
    
    // initialize the date picker:
    if (ONIPAD)
        self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake((self.view.frame.size.width)/4, 200, 400, 100)]; // x = 200
    else
        self.datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 200, 400, 100)]; // x = 200
    [self.datePicker setDatePickerMode:UIDatePickerModeDate];
    self.datePicker.backgroundColor = [UIColor grayColor];
    

    // initialize the tool bar:

    if (ONIPAD)
        _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake((self.view.frame.size.width)/4, 150, _datePicker.frame.size.width, 44)]; // x= 200
    else
        _toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 150, _datePicker.frame.size.width, 44)]; // x= 200

    [_toolBar setTintColor:[UIColor blackColor]];
    [_toolBar setBarTintColor:[UIColor grayColor]];
    UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(addTaskWithDate)];
        UIBarButtonItem* cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelOption)];
    [_toolBar setItems:[NSArray arrayWithObjects: cancel,done,nil]];

    
    // add both the date picker and the tool bar to the view, and hide them (initially):
    [self.view addSubview:_datePicker];
    [self.view addSubview:_toolBar];
    
    _datePicker.hidden = YES;
    _toolBar.hidden = YES;
    
    /**
     For the serialization of tasks, keep a list of all the
     serialized task descriptions and dates:
     **/
    [self loadSerializedTasks];
    
}

/**
 Read from the sandbox/documents/property list file, to get the saved tasks
 and display them upon reloading the view:
**/
-(void) loadSerializedTasks {
    // get the path to the property list:
    NSString* pathToPList = [self getPathToPropertyListFile];
    
    // if the plist file exists:
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToPList]) {
        
        // read in the data from the property list file, and put it into a mutable array
        NSMutableArray* serializedTasks = [[NSMutableArray alloc] initWithContentsOfFile:pathToPList];
        // iterate over the task,date pairs in the above array:
        for (int i = 0; i < [serializedTasks count]; i ++) {
            // get the current date value pair from the current dictionary:
            NSDictionary* currentTaskDatePair = [serializedTasks objectAtIndex:i];
            
            NSString* date = [currentTaskDatePair valueForKeyPath:@"date"];
            NSString* task = [currentTaskDatePair valueForKeyPath:@"task"];
            
            // now add a cell to the table view from this serialized data:
            [tasks addObject:task];
            [dates addObject:date];
        }
        
        // update the table with serealized data:
        [_table reloadData];

    }

}

/**
 write to the sandbox/documents/property list file to save any tasks:
 **/
-(void) writeSerializedTasks {
    NSMutableArray* objectsToSeralize = [[NSMutableArray alloc] init]; // the array containing the objects to save to a property list
    NSArray* cells = [_table visibleCells]; // all visible cells in the table
    // iterate over the cells, and add the (task,date) objects to the objects to be searlized array:
    for (UITableViewCell* currentCell in cells) {
        NSString* currentTask = currentCell.textLabel.text;
        NSString* currentDate = currentCell.detailTextLabel.text;
        [objectsToSeralize addObject:@{@"task":currentTask,@"date":currentDate}];
    }
    
    NSError* error;
    NSData* dataForPList = [NSPropertyListSerialization dataWithPropertyList:objectsToSeralize format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    // writing the returned NSData to a file:
    
    // write the priority list to the saved plist file (in the apps sandbox/documents directory):
    [dataForPList writeToFile:[self getPathToPropertyListFile] atomically:YES];
}

// called once "done" is pressed:
// this will be called once the tool bar and date picker are visible (i.e after the user has entered a valid task in the text field)
// it will add a task with the specified description, and the users selected date.
-(void) addTaskWithDate {
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [dateFormatter setDateFormat:@"dd/MM/YYYY"];
    NSString* chosenDate = [dateFormatter stringFromDate:_datePicker.date];
    
    // hide the date picker and the done button:
    _datePicker.hidden = YES;
    _toolBar.hidden = YES;
    
    // task is ok to add:
    [tasks addObject:addTaskField.text];
    [dates addObject:chosenDate];
    [_table reloadData];
    
    /***
     write all of the current tasks to a property list (for serialization):
     ***/
    [self writeSerializedTasks];
}

// the method that gets called when cancel is pressed (cancel adding this task, once the date selector appears):
-(void) cancelOption {
    addTaskField.text = @""; // clear the task field
    
    // hide the date picker and the tool bar:
    _datePicker.hidden = YES;
    _toolBar.hidden = YES;
    
}

// return the file path to the priority list file, in the apps sandbox/documents directory:
-(NSString*) getPathToPropertyListFile {
    // access the Document directory of the apps sandbox use: (each app gets it's own sandbox directory where the app data can be stored)
    NSString* documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    // obtain the path to the saved property list file, which is in the documents directory of the apps sandbox:
    NSString* pathToSavedData = [documentDir stringByAppendingString:@"savedTaskData.plist"];
    
    return pathToSavedData;
}

// initialize the image names array:
-(void) createArrays {
    // extremly hacky, but hey it's beta:
    // just trying something: if I add an empty cell, then the rest will appear lower
    tasks = [NSMutableArray arrayWithArray:@[]];//[@""]];
    dates = [NSMutableArray arrayWithArray:@[]];
}

// methods needed to be implemented:
#pragma mark - UITableView DataSource Methods
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { // return how many rows in the table
    return [tasks count];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { // returns a cell for a table view
    
    static NSString* cellId = @"Cell";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    cell.textLabel.text = tasks[indexPath.row];
    cell.detailTextLabel.text = dates[indexPath.row];
    cell.backgroundColor = [UIColor whiteColor];
    
    return cell;
}
//


-(void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath{
    // for deleteing a cell from the table view:
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tasks removeObjectAtIndex:indexPath.row];
        [dates removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation:UITableViewRowAnimationFade];
        // update the property list, so we never see the deleted task again:
        [self writeSerializedTasks];
    }
}


// to ensure all tasks are removed once this button is pressed
- (IBAction)clearAllTasks:(id)sender {
    [tasks removeAllObjects];
    [dates removeAllObjects];

    [_table reloadData];
    
    // update the property list:
    [self writeSerializedTasks];
}


// obtain all the tasks to be done by today and highlight them:
- (IBAction)getTodaysTasks:(id)sender {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/YYYY"];
    
    // obtain the date:
    NSString* todaysDate = [dateFormatter stringFromDate:[NSDate date]];
    
    int totalTasks = 0;
    
    // search for the tasks with todays date:
    NSArray* cells = [_table visibleCells];
    
    for (UITableViewCell* currentCell in cells) {
        
        NSString* dateForCurrentCell = currentCell.detailTextLabel.text;
        if ([dateForCurrentCell isEqualToString:todaysDate]) {
            // found a cell with a task to be done by today:
            currentCell.backgroundColor = [UIColor orangeColor];
            totalTasks++;
        }
    }

    NSString* tasksFoundMessage;
    if (totalTasks == 0)
        tasksFoundMessage = @"No tasks for today were found";
    else
        tasksFoundMessage = [NSString stringWithFormat: @"%i",totalTasks];
    
        NSLog(tasksFoundMessage);
}


// refresh the tasks, so that todays tasks are no longer highlighted:

- (IBAction)refresh:(id)sender {
    NSLog(@"Refresh was called");
    
    NSArray* cells = [_table visibleCells];
    
    for (UITableViewCell* currentCell in cells)
        currentCell.backgroundColor = [UIColor whiteColor];

}

// when add is pressed, get the current text from the user
// and add a task:
- (IBAction)addTap:(id)sender {
    
    NSString* newTask = addTaskField.text;
    // check for an empty task:
    NSString* stringWithNoSpaces = [newTask stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([stringWithNoSpaces length] == 0) {
        addTaskField.text = @"Error: the task cannot be empty";
        return;
    }
    
    // task is ok to add, so allow the user to set the date:
    _datePicker.hidden = NO;
    _toolBar.hidden = NO;

}


@end
