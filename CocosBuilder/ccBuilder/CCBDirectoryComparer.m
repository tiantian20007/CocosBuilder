/*
 * CocosBuilder: http://www.cocosbuilder.com
 *
 * Copyright (c) 2012 Zynga Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "CCBDirectoryComparer.h"

@implementation CCBDirectoryComparer

- (id) init
{
    self = [super init];
    if (!self) return NULL;
    
    _files = [[NSMutableDictionary dictionary] retain];
    
    return self;
}

- (NSDate*) modificationDateForFile:(NSString*)file
{
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL];
    return [attr objectForKey:NSFileModificationDate];
}

- (void) loadDirectory: (NSString*) dir subDir:(NSString*) subDir
{
    NSFileManager* fm = [NSFileManager defaultManager];
    
    NSString* absDir = dir;
    if (subDir) absDir = [dir stringByAppendingPathComponent:subDir];
    
    NSArray* contents = [fm contentsOfDirectoryAtPath:absDir error:NULL];
    
    for (NSString* file in contents)
    {
        NSString* absFile = [absDir stringByAppendingPathComponent:file];
        NSString* relFile = file;
        if (subDir) relFile = [subDir stringByAppendingPathComponent:file];
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:absFile isDirectory:&isDir])
        {
            if (isDir)
            {
                // Go down in sub directory
                NSString* subSubDir = file;
                if (subDir) subSubDir = [subDir stringByAppendingPathComponent:file];
                [self loadDirectory:dir subDir:subSubDir];
            }
            else
            {
                // Add file
                NSDate* date = [self modificationDateForFile:absFile];
                
                [_files setObject:date forKey:relFile];
            }
        }
    }
}

- (void) loadDirectory: (NSString*) dir
{
    [_files removeAllObjects];
    [self loadDirectory:dir subDir: NULL];
}

// More approximate comparison of dates
- (BOOL) isEqualDate:(NSDate*) d1 to:(NSDate*) d2
{
    NSTimeInterval delta = fabs([d1 timeIntervalSinceDate:d2]);
    return (delta < 2.0);
}

- (NSArray*) diffWithFiles:(NSDictionary*) diffFiles
{
    NSMutableArray* diff = [NSMutableArray array];
    
    for (NSString* file in _files)
    {
        NSDate* fileDate = [_files objectForKey:file];
        
        NSDate* diffFileDate = [diffFiles objectForKey:file];
        
        if (diffFileDate && [self isEqualDate:fileDate to:diffFileDate])
        {
            // Files are equal, there is no diff
            continue;
        }
        
        // Add to list of modified files
        [diff addObject:file];
        
        NSLog(@"MOD: %@ src: %@ dst: %@", file, fileDate, diffFileDate);
    }
    
    return diff;
}

- (void) dealloc
{
    [_files release];
    [super dealloc];
}

@end
