
#import "MASPreferencesViewController.h"

@interface PodioPreferencesViewController : NSViewController <MASPreferencesViewController> {

}

@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *signInOutButton;

- (IBAction)signInOutButtonClicked:(id)sender;

@end
