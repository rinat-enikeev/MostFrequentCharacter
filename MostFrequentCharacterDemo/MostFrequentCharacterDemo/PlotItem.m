//
//  PlotItem.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/4/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <tgmath.h>
#import "PlotItem.h"

@implementation PlotItem

-(id)init
{
    if ( (self = [super init]) ) {
        self.defaultLayerHostingView = nil;
        self.graphs                  = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void)addGraph:(CPTGraph *)graph toHostingView:(CPTGraphHostingView *)layerHostingView
{
    [_graphs addObject:graph];
    if ( layerHostingView ) {
        layerHostingView.hostedGraph = graph;
    }
}

-(void)addGraph:(CPTGraph *)graph
{
    [self addGraph:graph toHostingView:nil];
}

-(void)killGraph
{
    [[CPTAnimation sharedInstance] removeAllAnimationOperations];

    // Remove the CPTLayerHostingView
    if ( _defaultLayerHostingView ) {
        [_defaultLayerHostingView removeFromSuperview];

        _defaultLayerHostingView.hostedGraph = nil;
        _defaultLayerHostingView = nil;
    }

    cachedImage = nil;

    [_graphs removeAllObjects];
}

// override to generate data for the plot if needed
-(void)generateData
{
}

-(void)setTitleDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color                = [CPTColor grayColor];
    textStyle.fontName             = @"Helvetica-Bold";
    textStyle.fontSize             = round( bounds.size.height / CPTFloat(20.0) );
    graph.titleTextStyle           = textStyle;
    graph.titleDisplacement        = CPTPointMake( 0.0, textStyle.fontSize * CPTFloat(1.5) );
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
}

-(void)setPaddingDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds
{
    CGFloat boundsPadding = round( bounds.size.width / CPTFloat(20.0) ); // Ensure that padding falls on an integral pixel

    graph.paddingLeft = boundsPadding;

    if ( graph.titleDisplacement.y > 0.0 ) {
        graph.paddingTop = graph.titleTextStyle.fontSize * 2.0;
    }
    else {
        graph.paddingTop = boundsPadding;
    }

    graph.paddingRight  = boundsPadding;
    graph.paddingBottom = boundsPadding;
}

-(UIImage *)image
{
    if ( cachedImage == nil ) {
        CGRect imageFrame = CGRectMake(0, 0, 400, 300);
        UIView *imageView = [[UIView alloc] initWithFrame:imageFrame];
        [imageView setOpaque:YES];
        [imageView setUserInteractionEnabled:NO];

        [self renderInView:imageView withTheme:nil animated:NO];

        CGSize boundsSize = imageView.bounds.size;

        if ( UIGraphicsBeginImageContextWithOptions ) {
            UIGraphicsBeginImageContextWithOptions(boundsSize, YES, 0.0);
        }
        else {
            UIGraphicsBeginImageContext(boundsSize);
        }

        CGContextRef context = UIGraphicsGetCurrentContext();

        CGContextSetAllowsAntialiasing(context, true);

        for ( UIView *subView in imageView.subviews ) {
            if ( [subView isKindOfClass:[CPTGraphHostingView class]] ) {
                CPTGraphHostingView *hostingView = (CPTGraphHostingView *)subView;
                CGRect frame                     = hostingView.frame;

                CGContextSaveGState(context);

                CGContextTranslateCTM(context, frame.origin.x, frame.origin.y + frame.size.height);
                CGContextScaleCTM(context, 1.0, -1.0);
                [hostingView.hostedGraph layoutAndRenderInContext:context];

                CGContextRestoreGState(context);
            }
        }

        CGContextSetAllowsAntialiasing(context, false);

        cachedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    return cachedImage;
}

-(void)applyTheme:(CPTTheme *)theme toGraph:(CPTGraph *)graph withDefault:(CPTTheme *)defaultTheme
{
    if ( theme == nil ) {
        [graph applyTheme:defaultTheme];
    }
    else if ( ![theme isKindOfClass:[NSNull class]] ) {
        [graph applyTheme:theme];
    }
}


-(void)renderInView:(UIView *)hostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
    [self killGraph];

    _defaultLayerHostingView = [[CPTGraphHostingView alloc] initWithFrame:hostingView.bounds];

    _defaultLayerHostingView.collapsesLayers = NO;
    [_defaultLayerHostingView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];

    [_defaultLayerHostingView setAutoresizesSubviews:YES];

    [hostingView addSubview:_defaultLayerHostingView];
    [self generateData];
    [self renderInLayer:_defaultLayerHostingView withTheme:theme animated:animated];
}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
    NSLog(@"PlotItem:renderInLayer: Override me");
}

-(void)reloadData
{
    for ( CPTGraph *g in _graphs ) {
        [g reloadData];
    }
}


@end
