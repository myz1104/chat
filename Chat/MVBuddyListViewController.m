//
//  MVBuddyListViewController.m
//  Chat
//
//  Created by Michaël Villar on 5/6/13.
//
//

#import "MVBuddyListViewController.h"
#import "MVBuddyViewCell.h"
#import "MVBuddyListView.h"

@interface MVBuddyListViewController () <TUITableViewDataSource, TUITableViewDelegate>

@property (strong, readwrite) XMPPStream *xmppStream;
@property (strong, readwrite) XMPPRoster *xmppRoster;
@property (strong, readwrite) XMPPvCardAvatarModule *xmppAvatarModule;
@property (strong, readwrite) TUIView *view;
@property (strong, readwrite) MVBuddyListView *buddyListView;
@property (strong, readwrite) TUITableView *tableView;
@property (strong, readwrite) NSArray *users;

@end

@implementation MVBuddyListViewController

@synthesize xmppStream = xmppStream_,
            xmppRoster = xmppRoster_,
            xmppAvatarModule = xmppAvatarModule_,
            view = view_,
            buddyListView = buddyListView_,
            tableView = tableView_,
            users = users_,
            delegate = delegate_;

- (id)initWithStream:(XMPPStream*)xmppStream
{
  self = [super init];
  if(self)
  {
    delegate_ = nil;
    xmppStream_ = xmppStream;
    xmppRoster_ = (XMPPRoster*)[xmppStream moduleOfClass:[XMPPRoster class]];
    xmppAvatarModule_ = (XMPPvCardAvatarModule*)[xmppStream moduleOfClass:
                                                 [XMPPvCardAvatarModule class]];
    
    [xmppStream_ autoAddDelegate:self
                  delegateQueue:dispatch_get_main_queue()
               toModulesOfClass:[XMPPvCardAvatarModule class]];
    
    self.view = self.buddyListView = [[MVBuddyListView alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    self.tableView = self.buddyListView.tableView;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    users_ = [NSArray array];
    
    [self reload];
    
    [xmppRoster_ addDelegate:self delegateQueue:dispatch_get_main_queue()];
  }
  return self;
}

- (void)reload
{
  XMPPRosterMemoryStorage *storage = self.xmppRoster.xmppRosterStorage;
  self.users = [storage sortedUsersByName];
  [self.tableView reloadData];
}

#pragma mark TUITableViewDelegate Methods

- (void)tableView:(TUITableView *)tableView
didClickRowAtIndexPath:(TUIFastIndexPath *)indexPath
        withEvent:(NSEvent *)event
{
  NSObject<XMPPUser> *user = [self.users objectAtIndex:indexPath.row];
  if([self.delegate respondsToSelector:@selector(buddyListViewController:didClickBuddy:)])
    [self.delegate buddyListViewController:self didClickBuddy:user];
}

#pragma mark TUITableViewDataSource Methods

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section
{
  return self.users.count;
}

- (CGFloat)tableView:(TUITableView *)tableView
heightForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
  return 36;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView
          cellForRowAtIndexPath:(TUIFastIndexPath *)indexPath
{
  NSObject<XMPPUser> *user = [self.users objectAtIndex:indexPath.row];
  
  MVBuddyViewCell *cell = reusableTableCellOfClass(tableView, MVBuddyViewCell);
  cell.email = user.jid.bare;
  cell.fullname = user.nickname;
  cell.online = user.isOnline;
  cell.alternate = indexPath.row % 2 == 1;
  cell.firstRow = indexPath.row == 0;
  cell.lastRow = (indexPath.row == [self tableView:tableView
                             numberOfRowsInSection:indexPath.section] - 1);
  cell.representedObject = user.jid;
  NSData *photoData = [self.xmppAvatarModule photoDataForJID:user.jid];
  if(photoData)
  {
    cell.avatar = [TUIImage imageWithData:photoData];
  }
  [cell setNeedsDisplay];
	return cell;
}

#pragma mark XMPPRosterMemoryStorageDelegate Methods

- (void)xmppRosterDidChange:(XMPPRosterMemoryStorage *)sender
{
  NSLog(@"did change!");
  [self reload];
}

#pragma mark XMPPvCardAvatarModuleDelegate Methods

- (void)xmppvCardAvatarModule:(XMPPvCardAvatarModule *)vCardTempModule
              didReceivePhoto:(NSImage *)photo
                       forJID:(XMPPJID *)jid
{
  NSArray *visibleCells = self.tableView.visibleCells;
  for(MVBuddyViewCell *cell in visibleCells)
  {
    XMPPJID *cellJid = (XMPPJID*)cell.representedObject;
    if(cellJid && [cellJid isEqualToJID:jid options:XMPPJIDCompareBare])
    {
      cell.avatar = [TUIImage imageWithNSImage:photo];
      [cell setNeedsDisplay];
    }
  }
  NSLog(@"did receipve photo for %@",jid);
}

@end
