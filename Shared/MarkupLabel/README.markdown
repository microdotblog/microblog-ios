# MarkupLabel

This is a subset of my CoreTextToy (https://github.com/schwa/CoreTextToy) project extracted out into its own github repo.

Specifically this code allows you to use (simple) HTML markup with UILabel.

Obligatory screenshots:

![Before](Documentation/Before.png "Before")
![After](Documentation/After.png "After")

## License

This code is licensed under the 2-clause BSD license ("Simplified BSD License" or "FreeBSD License") license. The license is reproduced below:

Copyright 2011 Jonathan Wight. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ''AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of Jonathan Wight.

## Requirements

The master and develop branches require iOS 6.0 or higher with ARC.

## Design

### UILabel+MarkupExtensions

This implements a "setMarkup:" method. Pass it HTML. This is the point of this library.

### CMarkupValueTransformer

A value transformer capable of converting _simple_ markup (a small subset of HTML) into a NSAttributedString.

### UIFont+MarkupExtensions

Extension on UIFont to get a CTFont and to get bold/italic, etc variations of the font. Scans the font name to work out the attributes of a particular font.

This code is crude and effective - but needs to be tested on _all_ iOS font names (especially the weirder ones).

## FAQ

### Why does this even exist? Why not just use UIWebView?

UIWebViews are expensive to create and are pretty much overkill when all you need is a simple UILabel type class that shows static styled text.

### Why does this even exist? Why not use NSHTMLTextDocumentType?

TODO: Elaborate here (https://twitter.com/mattyohe/status/444320277812748288)

### How much HTML does this thing support?

It uses a minimal subset of HTML. In fact don't think of it as pure HTML - think of it as just a convenient method for creating NSAttributedString.

Only a handful of tags are supported right now, but you can define your own quite easily.

### What about all the tags CoreTextToy provides?

UILabel isn't quite as configurable as CoreTextToy's label code. As such not all tags supported there are supported by this code. Go use CoreTextToy or NSHTMLTextDocumentType if you need image tags.

### So how do I get HTML into a UILabel?

The quick way:

    NSString *theMarkup = @"<b>Hello world</b>";
    NSError *theError = NULL;
    NSString *theAttributedString = [NSAttributedString attributedStringWithMarkup:theMarkup error:&theError];
    // Error checking goes here.
    theLabel.attributedString = theAttributedString

The quicker way:

    NSString *theMarkup = @"<b>Hello world</b>";
    [theLabel setMarkup:theMarkup];

For the long way, see "How do I add custom styles?"

### How do I add custom styles?

If you dont like the built-in standard styles you can replace them or add new ones. The process is pretty straightforward:

    // Here's the markup we want to put into our UILabel. Note the custom <username> tag
    NSString *theMarkup = [NSString stringWithFormat:@"<username>%@</username> %@", theUsername, theBody];

    NSError *theError = NULL;

    // Create a transformer and set up the standard styling (that part is optional)
    CMarkupTransformer *theTransformer = [[CMarkupTransformer alloc] init];
    [theTransformer addStandardStyles];

    // Create custom attributes for our new "username" tag
    NSDictionary *theFormatDictionary = @{
        NSForegroundColorAttributeName: [UIColor blueColor],
        kMarkupFontNameMetaAttributeName: @"Helvetica",
        };
    [self addFormatDictionary:theFormatDictionary forTag:@"username"];

    // Transform the markup into a NSAttributedString
    NSAttributedString *theAttributedString = [theTransformer transformMarkup:inMarkup baseFont:self.font error:&theError];

    // Give the attributed string to the CCoreTextLabel.
    self.label.attributedString = theAttributedString;

