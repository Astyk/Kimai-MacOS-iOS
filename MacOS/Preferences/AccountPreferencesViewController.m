
#import "AccountPreferencesViewController.h"
#import "BMCredentials.h"
#import "AppDelegate.h"


@implementation AccountPreferencesViewController


#pragma mark -

- (id)init
{
    return [super initWithNibName:@"AdvancedPreferencesView" bundle:nil];
}


- (void)viewWillAppear {
    [BMCredentials loadCredentialsWithServicename:SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
        
        [self.kimaiURLTextField setStringValue:serviceURL];
        [self.usernameTextField setStringValue:username];
        [self.passwordTextField setStringValue:password];
        
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}


#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUser];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Account", @"Toolbar item name for the Account preference pane");
}


- (IBAction)signInOutButtonClicked:(id)sender {

    NSString *kimaiServerURL = [self.kimaiURLTextField stringValue];
    NSString *username = [self.usernameTextField stringValue];
    NSString *password = [self.passwordTextField stringValue];
    
    if (kimaiServerURL.length == 0 ||
        username.length == 0 ||
        password.length == 0) {
        return;
    }
    
    AppDelegate *appDelegate = (AppDelegate*)[NSApp delegate];
//    Kimai *kimai = appDelegate.kimai;
    
//#ifndef DEBUG
    [BMCredentials storeServiceURL:kimaiServerURL username:username password:password servicename:SERVICENAME success:^{
        [appDelegate hidePreferences];
        [appDelegate initKimai];
    } failure:^(NSError *error) {
        [appDelegate showAlertSheetWithError:error];
        [appDelegate reloadMenu];
    }];
//#endif

}


@end
