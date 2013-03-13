//
// This is a sample Advanced preference pane
//

#import "MASPreferencesViewController.h"

@interface AccountPreferencesViewController : NSViewController <MASPreferencesViewController> {

}

@property (weak) IBOutlet NSTextField *kimaiURLTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *signInOutButton;

- (IBAction)signInOutButtonClicked:(id)sender;

@end
