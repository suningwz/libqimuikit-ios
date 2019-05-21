//
//  QIMFileCell.m
//  qunarChatIphone
//
//  Created by xueping on 15/7/15.
//
//

#import "QIMMsgBaloonBaseCell.h"
#import "QIMFileCell.h"
#import "QIMFileIconTools.h"
#import "QIMFilePreviewVC.h"
#import "QIMJSONSerializer.h"
#import "QIMVideoPlayerVC.h"
#import "UILabel+VerticalAlign.h"
#import "NSBundle+QIMLibrary.h"

#define kCellWidth      250
#define kCellHeight     109

@interface QIMFileCell()<QIMMenuImageViewDelegate>

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *fileNameLabel;
@property (nonatomic, strong) UILabel *fileSizeLabel;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UILabel *fileStateLabel;
@property (nonatomic, strong) UILabel *platFormLabel;

@end

@implementation QIMFileCell

+ (CGFloat)getCellHeightWithMessage:(QIMMessageModel *)message chatType:(ChatType)chatType{
    return kCellHeight + 20 + (chatType == ChatType_GroupChat ? 20 : 0);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        [self.backView setBubbleBgColor:[UIColor whiteColor]];
        self.backgroundView = nil;
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.selectedBackgroundView = nil;
        
        _bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCellWidth, kCellHeight)];
        _bgView.backgroundColor = [UIColor clearColor];
        [self.backView addSubview:_bgView];
        
        UIView *fileBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kCellWidth, kCellHeight - 27)];
        [_bgView addSubview:fileBackView];
        fileBackView.backgroundColor = [UIColor clearColor];
        
        _fileNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(18, 12, kCellWidth - 50 - 20 - 20, 42)];
        [_fileNameLabel setBackgroundColor:[UIColor clearColor]];
        [_fileNameLabel setTextColor:[UIColor qim_colorWithHex:0x333333]];
        [_fileNameLabel setFont:[UIFont boldSystemFontOfSize:15]];
        [_fileNameLabel setTextAlignment:NSTextAlignmentLeft];
        [_fileNameLabel setNumberOfLines:2];
        [fileBackView addSubview:_fileNameLabel];
        
        _fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(_fileNameLabel.left, _fileNameLabel.bottom + 3, _fileNameLabel.width - 10, 18)];
        [_fileSizeLabel setBackgroundColor:[UIColor clearColor]];
        [_fileSizeLabel setTextColor:[UIColor qim_colorWithHex:0x999999]];
        [_fileSizeLabel setFont:[UIFont systemFontOfSize:12]];
        [_fileSizeLabel setTextAlignment:NSTextAlignmentLeft];
        [fileBackView addSubview:_fileSizeLabel];
        
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(fileBackView.width - 12 - 50, 12, AVATAR_WIDTH, AVATAR_WIDTH)];
        [fileBackView addSubview:_iconImageView];
        
        _lineView = [[UIView alloc] initWithFrame:CGRectMake(0, fileBackView.bottom, _bgView.width - 7, 0.5f)];
        _lineView.backgroundColor = [UIColor qim_colorWithHex:0xEAEAEA];
        _lineView.contentMode   = UIViewContentModeBottom;
        _lineView.clipsToBounds = YES;
        [_bgView addSubview:_lineView];
        
        _platFormLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, _lineView.bottom + 8, 60, 12)];
        _platFormLabel.text = ([QIMKit getQIMProjectType] == QIMProjectTypeQChat) ? @"来自QChat" : @"来自QTalk";
        _platFormLabel.font = [UIFont systemFontOfSize:12];
        _platFormLabel.backgroundColor = [UIColor clearColor];
        _platFormLabel.textAlignment = NSTextAlignmentLeft;
        _platFormLabel.textColor = [UIColor qim_colorWithHex:0x999999];
        [_bgView addSubview:_platFormLabel];
        
        _fileStateLabel = [[UILabel alloc] initWithFrame:CGRectMake(_bgView.right - 12 - 150, _lineView.bottom + 8, 150, 12)];
        [_fileStateLabel setBackgroundColor:[UIColor clearColor]];
        [_fileStateLabel setTextColor:[UIColor qim_colorWithHex:0x999999]];
        [_fileStateLabel setFont:[UIFont systemFontOfSize:12]];
        [_fileStateLabel setTextAlignment:NSTextAlignmentRight];
        [_bgView addSubview:_fileStateLabel];
        
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
        [self.backView addGestureRecognizer:tap];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downfileNotify:) name:kNotifyDownloadFileComplete object:nil];
    }
    return self;
}

- (void)downfileNotify:(NSNotification *)nofity {
    if ([self.message.messageId isEqualToString:nofity.object]) {
        [self refreshUI];
    }
}

- (void)tapHandle:(UITapGestureRecognizer *)tap {
    
    QIMFilePreviewVC *preview = [[QIMFilePreviewVC alloc] init];
    [preview setMessage:self.message];
    [self.owerViewController.navigationController pushViewController:preview animated:YES];
}

#pragma mark - ui

- (void)refreshUI {
    
    self.backView.message = self.message;
    if (self.message.extendInformation.length > 0) {
        self.message.message = self.message.extendInformation;
    }
    float backWidth = kCellWidth + kBackViewCap + 2;
    float backHeight = kCellHeight + 1;
    
    [self setBackViewWithWidth:backWidth WithHeight:backHeight];
    [super refreshUI];
    NSDictionary *infoDic = [[QIMJSONSerializer sharedInstance] deserializeObject:self.message.message error:nil];
    NSString *fileName = [infoDic objectForKey:@"FileName"];
    NSString *fileSize = [[infoDic objectForKey:@"FileSize"] description];
    NSString *fileUrl = [infoDic objectForKey:@"HttpUrl"];
    if (![fileUrl qim_hasPrefixHttpHeader]) {
        fileUrl = [NSString stringWithFormat:@"%@/%@", [[QIMKit sharedInstance] qimNav_HttpHost], fileUrl];
    }
    
    NSString *fileMd5 = [[QIMKit sharedInstance] getFileNameFromUrl:fileUrl];
    if (!fileMd5.length) {
        fileMd5 = [[QIMKit sharedInstance] getFileNameFromUrl:fileUrl];
    }
    NSString *fileExt = [[QIMKit sharedInstance] getFileExtFromUrl:fileUrl];
    if (!fileExt.length) {
        fileExt = [fileName pathExtension];
        fileMd5 = [NSString stringWithFormat:@"%@.%@", fileMd5, fileExt];
    }
    
    NSString *filePath = [[[QIMKit sharedInstance] getDownloadFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileMd5?fileMd5:@""]];

    NSString *fileState = [NSBundle qim_localizedStringForKey:@"common_sent"];
    if (self.message.messageDirection == QIMMessageDirection_Received) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:nil]) {
            fileState = [NSBundle qim_localizedStringForKey:@"common_not_download"];
        } else {
            fileState = [NSBundle qim_localizedStringForKey:@"common_already_download"];
        }
    } else {
        
    }
    if (fileName.length <= 0) {
        fileName = [NSBundle qim_localizedStringForKey:@"common_old_file"];
        fileSize = @"0.00B";
    }
    UIImage *icon = [QIMFileIconTools getFileIconWithExtension:fileName.pathExtension];
    [_iconImageView setImage:icon];
    [_fileNameLabel setText:fileName];
    [_fileSizeLabel setText:fileSize];
    [_fileStateLabel setText:fileState];
    [_fileNameLabel alignTop];
    if (self.message.messageDirection == QIMMessageDirection_Received) {
        [_bgView setLeft:kBackViewCap+2];
        [_fileNameLabel setTextColor:[UIColor qim_colorWithHex:0x212121]];
        [_fileSizeLabel setTextColor:[UIColor qim_colorWithHex:0x9E9E9E]];
        [_fileStateLabel setTextColor:[UIColor qim_colorWithHex:0x9E9E9E]];
    } else {
        [_bgView setLeft:0];
        [_fileNameLabel setTextColor:[UIColor qim_colorWithHex:0x212121]];
        [_fileSizeLabel setTextColor:[UIColor qim_colorWithHex:0x9E9E9E]];
        [_fileStateLabel setTextColor:[UIColor qim_colorWithHex:0x9E9E9E]];
    }
    [self.backView setBubbleBgColor:[UIColor whiteColor]];
}


- (NSArray *)showMenuActionTypeList {
    NSMutableArray *menuList = [NSMutableArray arrayWithCapacity:4];
    switch (self.message.messageDirection) {
        case QIMMessageDirection_Received: {
            [menuList addObjectsFromArray:@[@(MA_Repeater), @(MA_Delete), @(MA_Forward)]];
        }
            break;
        case QIMMessageDirection_Sent: {
            [menuList addObjectsFromArray:@[@(MA_Repeater), @(MA_ToWithdraw), @(MA_Delete), @(MA_Forward)]];
        }
            break;
        default:
            break;
    }
    if ([[[QIMKit sharedInstance] qimNav_getDebugers] containsObject:[QIMKit getLastUserName]]) {
        [menuList addObject:@(MA_CopyOriginMsg)];
    }
    if ([[QIMKit sharedInstance] getIsIpad]) {
//        [menuList removeObject:@(MA_Refer)];
//        [menuList removeObject:@(MA_Repeater)];
//        [menuList removeObject:@(MA_Delete)];
        [menuList removeObject:@(MA_Forward)];
//        [menuList removeObject:@(MA_Repeater)];
    }
    return menuList;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
