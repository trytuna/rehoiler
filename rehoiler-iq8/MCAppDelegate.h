//
//  MCAppDelegate.h
//  rehoiler-iq8
//
//  Created by Timo Schrappe on 19/12/13.
//  Copyright (c) 2013 codium. All rights reserved.
//

/*  CMD | Output position | Parameter           | Discription                               */
/*  ----|-----------------|---------------------|------------------------------------------ */
/*  0   |                 | none                | exit programming mode                     */
/** 2   | 0               | number of impulses  | number of impluses per wheel revolution   */
/** 3   | 1               | wheel revolutions   | distance/(wheel-circumference/1000)       */
/** 4   | 7               | milliseconds        | cockpit led on-time in ms                 */
/** 5   | 5               | seconds             | reedrelay interval                        */
/** 6   | 4               | 1 (on) / 0 (off)    | Notbetrieb                                */
/** 7   | 2               | pump cycles         | tank capacity as amount of pumping cycles */
/*  8   | 3               | pump cylce count    | Number of pump cycles until now           */
/** 9   |                 | none                | current settings                          */
/** 10  | 8               | wheel-circumference | wheel-circumference in millimeter         */
/** 11  | 9               | distance            | distance in meter                         */

/* default values: 1;4800;1000;0;1;8;1;2046;1880;8000;8.03;ATmega168 */

#import <Cocoa/Cocoa.h>

#import "ORSSerialPort.h"

typedef NS_ENUM(NSInteger, MCConfigOption) {
    MCConfigOptionImpulses,
    MCConfigOptionDistance,
    MCConfigOptionCircumference,
    MCConfigOptionTankPumpCycle,
    MCConfigOptionCockpitLED,
    MCConfigOptionReedDelay,
    MCConfigOptionEmergency,
    MCConfigOptionVersion,
    MCConfigOptionProcessor,
    MCConfigOptionPumpCycled
};


@interface MCAppDelegate : NSObject <NSApplicationDelegate, ORSSerialPortDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (strong) ORSSerialPort *port;
@property NSString *receivedString;
@property (weak) IBOutlet NSButton *connectButton;
@property (weak) IBOutlet NSPopUpButton *availablePortsPopUp;
@property (weak) IBOutlet NSButton *programButton;
@property (getter = isProgramming) BOOL programming;
@property (weak) IBOutlet NSButton *refreshButton;
@property (weak) IBOutlet NSProgressIndicator *progressBar;

@property (weak) IBOutlet NSTextField *impulses;
@property (weak) IBOutlet NSTextField *circumference;
@property (weak) IBOutlet NSTextField *distance;
@property (weak) IBOutlet NSTextField *cockpitLEDTime;
@property (weak) IBOutlet NSTextField *reedDelayTime;
@property (weak) IBOutlet NSTextField *pumpCyclesUntilSavingsLED;
@property (weak) IBOutlet NSTextField *pumpCycles;
@property (weak) IBOutlet NSButton *emergencyMode;
@property (weak) IBOutlet NSTextField *microprocessorVersion;


- (IBAction)factoryDefault:(id)sender;
- (IBAction)refreshPorts:(NSButton *)sender;
- (IBAction)connectButton:(NSButton *)sender;
- (IBAction)program:(NSButton *)sender;
- (NSDictionary *)parseOutput:(NSString *)output;

@end
