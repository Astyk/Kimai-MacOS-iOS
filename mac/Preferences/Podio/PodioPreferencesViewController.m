
#import "PodioPreferencesViewController.h"
#import "BMCredentials.h"
#import "AppDelegate.h"


@implementation PodioPreferencesViewController


#pragma mark -

- (id)init
{
    return [super initWithNibName:@"PodioPreferencesView" bundle:nil];
}


- (void)viewWillAppear {
    [BMCredentials loadCredentialsWithServicename:PODIO_SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
        
        [self.usernameTextField setStringValue:username];
        [self.passwordTextField setStringValue:password];
        
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
}


#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"PodioPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUser];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Podio", @"Toolbar item name for the Account preference pane");
}


- (IBAction)signInOutButtonClicked:(id)sender {

    NSString *username = [self.usernameTextField stringValue];
    NSString *password = [self.passwordTextField stringValue];
    
    if (username.length == 0 ||
        password.length == 0) {
        return;
    }
    
    AppDelegate *appDelegate = (AppDelegate*)[NSApp delegate];
//    Kimai *kimai = appDelegate.kimai;
    
//#ifndef DEBUG‚
    [BMCredentials storeServiceURL:nil username:username password:password servicename:PODIO_SERVICENAME success:^{
        [appDelegate hidePreferences];
        [appDelegate initPodio];
    } failure:^(NSError *error) {
        [appDelegate showAlertSheetWithError:error];
        //[appDelegate reloadMenu];
    }];
//#endif

}


@end
