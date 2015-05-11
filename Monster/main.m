//
//  main.m
//  Monster
//
//  Created by Kristopher Giesing on 11/17/13.
//  Copyright (c) 2013 Kristopher Giesing. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <iostream>

int usage()
{
	printf("Usage: monster <command> <url> [<key>] [<value>] [<expiry>]\n");
	printf("  where command is one of: get, set, eat\n");
	printf("  url is the URL of the cookie\n");
	printf("  key is the name of the cookie\n");
	printf("  -- required if the command is 'set' or 'eat', otherwise optional\n");
	printf("  value is the value of the cookie\n");
	printf("  -- required if the command is 'set', otherwise ignored\n");
	printf("  expiry is the expiration, in <N><unit> (from now) notation\n");
	printf("  -- units: s = seconds, m = minutes, h = hours, d = days, y = years\n");
	printf("  -- optional if the command is 'set', otherwise ignored\n");
	return 1;
}

const char *sPolicyLabels[3] = {
	"NSHTTPCookieAcceptPolicyAlways",
	"NSHTTPCookieAcceptPolicyNever",
	"NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain"
};

static const int sOneSecondInSeconds = 1;
static const int sOneMinuteInSeconds = 60;
static const int sOneHourInSeconds = sOneMinuteInSeconds*60;
static const int sOneDayInSeconds = sOneHourInSeconds*24;
static const int sOneYearInSeconds = sOneDayInSeconds*365;

int
getExpiry(int argc, const char *argv[])
{
	int result = sOneYearInSeconds;
	if (argc > 5) {
		NSString *expiry = [NSString stringWithUTF8String:argv[5]];
		NSScanner *scanner = [NSScanner scannerWithString:expiry];
		if ([scanner scanInt:&result]) {
			NSString *remainder = [[[scanner string] substringFromIndex:[scanner scanLocation]] lowercaseString];
			if ([remainder isEqualToString:@"s"]) {
				result *= sOneSecondInSeconds;
			} else if ([remainder isEqualToString:@"m"]) {
				result *= sOneMinuteInSeconds;
			} else if ([remainder isEqualToString:@"h"]) {
				result *= sOneHourInSeconds;
			} else if ([remainder isEqualToString:@"d"]) {
				result *= sOneDayInSeconds;
			} else if ([remainder isEqualToString:@"y"]) {
				result *= sOneYearInSeconds;
			} else {
				result = sOneYearInSeconds;
				fprintf(stderr, "Warning: Unrecognized expiry %s\n", argv[5]);
			}
		} else {
			fprintf(stderr, "Warning: Unrecognized expiry %s\n", argv[5]);
		}
	}
	return result;
}

int
main(int argc, const char *argv[])
{
	@autoreleasepool {

		if (argc < 3) {
			return usage();
		}
		
		NSString *command = [NSString stringWithUTF8String:argv[1]];
		
		if ([command isEqualToString:@"set"] && argc < 5) {
			return usage();
		} else if ([command isEqualToString:@"eat"] && argc < 4) {
			return usage();
		}
		
		NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:argv[2]]];
		NSString *key = nil;
		if (argc > 3) {
			key = [NSString stringWithUTF8String:argv[3]];
		}

		NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		
		NSHTTPCookieAcceptPolicy policy = storage.cookieAcceptPolicy;
		if ([command isEqualToString:@"set"] || [command isEqualToString:@"eat"]) {
			if (policy != NSHTTPCookieAcceptPolicyAlways) {
				storage.cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;
				fprintf(stderr, "Warning: Temporarily setting cookie storage policy %s to NSHTTPCookieAcceptPolicyAlways\n", sPolicyLabels[policy]);
				if (storage.cookieAcceptPolicy != NSHTTPCookieAcceptPolicyAlways) {
					fprintf(stderr, "Error: Cookie storage has an accept policy of %s, cannot edit\n", sPolicyLabels[storage.cookieAcceptPolicy]);
					return 1;
				}
			}
		}
		
		if ([command isEqualToString:@"get"]) {
			NSArray *cookies = [storage cookiesForURL:url];
			if (key == nil) {
				printf("%s: Found %lu cookies\n", [[url absoluteString] UTF8String], (unsigned long)cookies.count);
			}
			for (NSHTTPCookie *cookie in cookies) {
				if (key == nil) {
					printf("%s: %s\n", [cookie.name UTF8String], [cookie.value UTF8String]);
				} else if ([cookie.name isEqualToString:key]) {
					printf("%s\n", [cookie.value UTF8String]);
				}
			}
		} else if ([command isEqualToString:@"set"]) {
			NSString *value = [NSString stringWithUTF8String:argv[4]];
			int expiry = getExpiry(argc, argv);
			NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:
										url, NSHTTPCookieOriginURL,
										[url path], NSHTTPCookiePath,
										key, NSHTTPCookieName,
										value, NSHTTPCookieValue,
										[NSDate dateWithTimeIntervalSinceNow:expiry], NSHTTPCookieExpires,
										nil];
			NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:properties];
			[storage setCookie:cookie];
			printf("%s: Set %s: %s\n", [[url absoluteString] UTF8String], [cookie.name UTF8String], [cookie.value UTF8String]);
		} else if ([command isEqualToString:@"eat"]) {
			NSArray *cookies = [storage cookiesForURL:url];
			for (NSHTTPCookie *cookie in cookies) {
				if ([cookie.name isEqualToString:key]) {
					printf("%s: Ate %s: %s\n", [[url absoluteString] UTF8String], [cookie.name UTF8String], [cookie.value UTF8String]);
					[storage deleteCookie:cookie];
				}
			}
		} else {
			return usage();
		}

		if (([command isEqualToString:@"set"] || [command isEqualToString:@"eat"]) && policy != NSHTTPCookieAcceptPolicyAlways) {
			storage.cookieAcceptPolicy = policy;
		}
		
		return 0;
	}
}
