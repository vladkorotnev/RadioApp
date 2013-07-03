//
//  MRShoutcastMetadata.m
//  Radio
//
//  Created by Vladislav Korotnev on 6/30/13.
//  Copyright (c) 2013 Vladislav Korotnev. All rights reserved.
//

#import "MRShoutcastMetadata.h"

@implementation MRShoutcastMetadata
static NSString* curStreamUrl;
static NSMutableData*data;
- (void)beginReceivingUpdatesToDelegate:(id<MRSCMetadataReceiver>)del forStream:(NSString*)streamUrl {
    self.delegate=del;
    curStreamUrl=streamUrl;
    [self performSelectorInBackground:@selector(_receiveUpd) withObject:nil];
}
-(void) streamUrlChange:(NSString*)newUrl {
    curStreamUrl=newUrl;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
     [self performSelectorInBackground:@selector(_receiveUpd) withObject:nil];
}
- (void) _receiveUpd {
    NSLog(@"RRR %@",curStreamUrl);
	//We need to make the url mutable as we need to append another string to it
	NSMutableString *value = [NSMutableString stringWithString:curStreamUrl];
	//Gets the last character of the string
	NSString *lastCharacter = [value substringFromIndex:([value length] - 1)];
	//Now checks if it is equal to "/"
	if([lastCharacter isEqualToString:@"/"]){
		[value appendFormat:@"7.html"];
	}
	else {
		[value appendFormat:@"/7.html"];
	}
	//Now let's transform the URL entered by the user to a NSURL
	NSURL *URL = [NSURL URLWithString:value];
	//Check if the URL is valid
	if(!URL){
		//The URL is not valid, let's tell the user
		[self.delegate thereIsNoMetadataForStream:curStreamUrl];
		//Stops the method execution
        NSLog(@"%@ inv",curStreamUrl);
		return;
	}
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
	//Let's set the user-agent header. The app must identifies itself as browser, so the server will return a HTML file
	[request setValue:@"Mozilla/1.0 SHOUTcast example" forHTTPHeaderField:@"user-agent"];
	//Let's send the request
	NSURLConnection*c=[NSURLConnection connectionWithRequest:request delegate:self];
    [c start];
}
//If anything went wrong, this method will be called
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"%@",error.localizedDescription);
		[self.delegate thereIsNoMetadataForStream:@""];
}
//Once the server replies, this method gets called
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)res{
	//Now let's create the data that will hold the response file
    NSLog(@"DRR");
	data = [[NSMutableData alloc]initWithLength:0];
}
//When the server sends data, this method will get called
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d{
    NSLog(@"D");
	//Let's append the data we got to the NSMutableData object we created
	[data appendData:d];
}
//This method will get called once
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    //Let's create a string from the data we've got from the server
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	//Let's parse the string
	[self parseMetadata:string];
    NSLog(@"F");
}
//This method parses the string
-(void)parseMetadata:(NSString *)metadata{
    NSLog(@"P");
	//Checks if the returned file contains the <body> tag
	if([metadata rangeOfString:@"<body>"].length == 0){
		[self.delegate thereIsNoMetadataForStream:@""];
		return;
	}
	//Gets the index of the character after the body tag
	int index = ([metadata rangeOfString:@"<body>"].location + 1);
	//Removes the <html> and the <body> tag
	metadata = [metadata substringFromIndex:index];
	//Gets the index of the character before the <body> tag is closed
	index = [metadata rangeOfString:@"</body>"].location;
	//Removes the "</body></html>" string
	metadata = [metadata substringToIndex:index];
	//Keep checking if there are still any "," on the string
	while ([metadata rangeOfString:@","].length > 0) {
		//Removes the ","s and other junk like bitrate
		metadata = [NSString stringWithString:[metadata substringFromIndex:([metadata rangeOfString:@","].location + 1)]];
	}
	//Checks if the artist name is provided
	if([metadata rangeOfString:@"-"].length > 0){
		//Gets the index of the "-"
		index = [metadata rangeOfString:@" - "].location;
		//Artist name comes first
		NSString *artistName = [metadata substringToIndex:index];

		//Gets the song name
		NSString *name = [metadata substringFromIndex:(index + 3)];
		//Sets the songName's value
		[self.delegate gotMetadataUpdate:[NSString stringWithFormat:@"%@ - %@",artistName,name]];
	}
	else {
		//Artist name was not provided, so let's set what we have as the song name
		[self.delegate gotMetadataUpdate:metadata];
	}
    [self performSelector:@selector(_receiveUpd) withObject:nil afterDelay:5];
	


}
@end
