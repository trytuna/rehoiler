//
//  MCAppDelegate.m
//  rehoiler-iq8
//
//  Created by Timo Schrappe on 19/12/13.
//  Copyright (c) 2013 codium. All rights reserved.
//

#import "MCAppDelegate.h"
#import "ORSSerialPort.h"
#import "ORSSerialPortManager.h"

@implementation MCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [_progressBar setHidden:YES];
    _microprocessorVersion.stringValue = @"";
    
    self.receivedString = @"";
    
    ORSSerialPortManager *spm = [ORSSerialPortManager sharedSerialPortManager];
    NSArray *ports = [spm availablePorts];
    
    [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_availablePortsPopUp addItemWithTitle:[obj description]];
    }];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [_port sendData:[@"0\r" dataUsingEncoding:NSUTF8StringEncoding]];
    NSArray *ports = [[ORSSerialPortManager sharedSerialPortManager] availablePorts];
	for (ORSSerialPort *port in ports) { [port close]; }
}

- (IBAction)factoryDefault:(id)sender {
    [_impulses setStringValue:@"1"];
    [_circumference setStringValue:@"1880"];
    [_distance setStringValue:@"8000"];
    [_cockpitLEDTime setStringValue:@"750"];
    [_reedDelayTime setStringValue:@"8"];
    [_pumpCyclesUntilSavingsLED setStringValue:@"1000"];
    [_emergencyMode setState:NSOnState];
    
    [_programButton performClick:self];
}

- (IBAction)refreshPorts:(NSButton *)sender {
    [_availablePortsPopUp removeAllItems];
    
    ORSSerialPortManager *spm = [ORSSerialPortManager sharedSerialPortManager];
    NSArray *ports = [spm availablePorts];
    
    [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [_availablePortsPopUp addItemWithTitle:[obj description]];
    }];
}

- (IBAction)connectButton:(NSButton *)sender {
    float Y = 280;
    NSRect frame = [_window frame];
    if ([sender.title isEqualToString:@"Verbinden"]) {
        ORSSerialPortManager *spm = [ORSSerialPortManager sharedSerialPortManager];
        NSArray *ports = [spm availablePorts];
        [ports enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([[(ORSSerialPort *)obj description] isEqualToString:_availablePortsPopUp.selectedItem.title]) {
                _port = (ORSSerialPort *)obj;
                _port.baudRate = [NSNumber numberWithInteger:9600];
                _port.delegate = self;
            }
        }];
        
        dispatch_queue_t openSerialPort = dispatch_queue_create("de.codium.openSerialPort", DISPATCH_QUEUE_CONCURRENT);
        dispatch_sync(openSerialPort, ^{
            [_port open];
        });
        if ([_port isOpen]) {
            [_availablePortsPopUp setEnabled:NO];
            [_refreshButton setEnabled:NO];
            _connectButton.title = @"Trennen";
            
            frame.origin.y -= Y;
            frame.size.height = 363;
            [_window setFrame:frame display:YES animate:YES];
            
            [_progressBar startAnimation:self];
            [_progressBar setHidden:NO];
            [_port sendData:[@"9\r" dataUsingEncoding:NSUTF8StringEncoding]];
        } else {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Verbindung nicht möglich" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Vergewissern Sie sich, dass er Treiber installiert wurde und Sie die richtige Schnittstelle ausgewählt haben.", nil];
            [alert beginSheetModalForWindow:_window completionHandler:nil];
        }
    } else {
        [_port close];
        _connectButton.title = @"Verbinden";
        
        [_availablePortsPopUp setEnabled:YES];
        [_refreshButton setEnabled:YES];
        frame.origin.y += Y;
        frame.size.height = 83;
        
        [_window setFrame:frame display:YES animate:YES];
    }
    
}

- (IBAction)program:(NSButton *)sender {
    if (![_port isOpen]) {
        [_programButton performClick:self];
        return;
    }
    NSLog(@"%hhd", [_port isOpen]);
    [_progressBar setHidden:NO];
    [_progressBar setIndeterminate:NO];
    [_progressBar setUsesThreadedAnimation:YES];
    [self setProgramming:YES];
    
    double timeInterval = 0.2;
    
    double numberOfParameters = 15;
    __block double numberOfProgrammedParameters = 0;
    
    dispatch_queue_t queue = dispatch_queue_create("de.codium.program-mc", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        /** 2   | 0               | number of impulses  | number of impluses per wheel revolution   */
        if (_impulses && _impulses.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@2]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_impulses.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 10  | 8               | wheel-circumference | wheel-circumference in millimeter         */
        if (_circumference && _circumference.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@10]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_circumference.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 11  | 9               | distance            | distance in meter                         */
        if (_distance && _distance.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@11]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_distance.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 3   | 1               | wheel revolutions   | distance/(wheel-circumference/1000)       */
        if (_distance && _distance.integerValue > 0 && _circumference && _circumference.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@3]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(round(_distance.integerValue/(_circumference.integerValue/1000)))]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 4   | 7               | milliseconds        | cockpit led on-time in ms                 */
        if (_cockpitLEDTime && _cockpitLEDTime.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@4]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_cockpitLEDTime.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 5   | 5               | seconds             | reedrelay interval                        */
        if (_reedDelayTime && _reedDelayTime.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@5]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_reedDelayTime.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];        }
        
        /** 7   | 2               | pump cycles         | tank capacity as amount of pumping cycles */
        if (_pumpCyclesUntilSavingsLED && _pumpCyclesUntilSavingsLED.integerValue > 0) {
            [_port sendData:[self commandWithNumber:@7]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_pumpCyclesUntilSavingsLED.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 6   | 4               | 1 (on) / 0 (off)    | Notbetrieb                                */
        if (_emergencyMode.state == NSOnState || _emergencyMode.state == NSOffState) {
            [_port sendData:[self commandWithNumber:@6]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
            [_port sendData:[self commandWithNumber:@(_emergencyMode.integerValue)]];
            numberOfProgrammedParameters++;
            [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
            [NSThread sleepForTimeInterval:timeInterval];
        }
        
        /** 9   |                 | none                | current settings                          */
        [_port sendData:[self commandWithNumber:@9]];
        numberOfProgrammedParameters++;
        [_progressBar setDoubleValue:numberOfProgrammedParameters / numberOfParameters];
    });
}

- (NSDictionary *)parseOutput:(NSString *)output {
    NSString *trimedOutput = [output substringWithRange:NSMakeRange(0, output.length-3)];
    NSArray *outputArray = [trimedOutput componentsSeparatedByString:@";"];
    return @{@(MCConfigOptionImpulses) : [outputArray objectAtIndex:0],
             @(MCConfigOptionTankPumpCycle) : [outputArray objectAtIndex:2],
             @(MCConfigOptionPumpCycled) : [outputArray objectAtIndex:3],
             @(MCConfigOptionEmergency) : [outputArray objectAtIndex:4],
             @(MCConfigOptionReedDelay) : [outputArray objectAtIndex:5],
             @(MCConfigOptionCockpitLED) : [outputArray objectAtIndex:7],
             @(MCConfigOptionCircumference) : [outputArray objectAtIndex:8],
             @(MCConfigOptionDistance) : [outputArray objectAtIndex:9],
             @(MCConfigOptionVersion) : [outputArray objectAtIndex:10],
             @(MCConfigOptionProcessor) : [outputArray objectAtIndex:11]};
}

- (NSData *)commandWithNumber:(NSNumber *)cmd {
    NSData *command = nil;
    NSString *skeleton = [NSString stringWithFormat:@"%@\r", cmd];
    command = [skeleton dataUsingEncoding:NSUTF8StringEncoding];
    return command;
}

#pragma mark SerialPort Delegate
-(void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data {
    NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.receivedString = [NSString stringWithFormat:@"%@%@", self.receivedString, stringData];
    
    if ([_receivedString hasSuffix:@"\r\n"]) {
        NSDictionary *parsedOutput = [self parseOutput:self.receivedString];
        [_impulses setStringValue:[parsedOutput objectForKey:@(MCConfigOptionImpulses)]];
        [_circumference setStringValue:[parsedOutput objectForKey:@(MCConfigOptionCircumference)]];
        [_distance setStringValue:[parsedOutput objectForKey:@(MCConfigOptionDistance)]];
        [_cockpitLEDTime setStringValue:[parsedOutput objectForKey:@(MCConfigOptionCockpitLED)]];
        [_reedDelayTime setStringValue:[parsedOutput objectForKey:@(MCConfigOptionReedDelay)]];
        [_pumpCyclesUntilSavingsLED setStringValue:[parsedOutput objectForKey:@(MCConfigOptionTankPumpCycle)]];
        [_emergencyMode setState:[(NSString *)[parsedOutput objectForKey:@(MCConfigOptionEmergency)] integerValue]];
        [_pumpCycles setStringValue:[parsedOutput objectForKey:@(MCConfigOptionPumpCycled)]];
        [_microprocessorVersion setStringValue:[parsedOutput objectForKey:@(MCConfigOptionVersion)]];
        
        [_progressBar stopAnimation:self];
        [_progressBar setHidden:YES];
        
        if ([self isProgramming]) {
            NSAlert *alert = [NSAlert alertWithMessageText:@"Programmiert" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"Programmierung war erfolgreich"];
            [alert beginSheetModalForWindow:_window completionHandler:nil];
            _programming = NO;
        }
        
        self.receivedString = @"";
    }
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort {
    if ([[serialPort description] isEqualToString:[_port description]] && [_connectButton.stringValue isEqualToString:@"Trennen"]) {
        [_connectButton performClick:self];
    }
    [_availablePortsPopUp removeItemWithTitle:[serialPort description]];
}

@end
