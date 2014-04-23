//
//  PlotItem.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 8/31/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "CorePlot-CocoaTouch.h"
#import <UIKit/UIKit.h>

typedef CGRect CGNSRect;


@class CPTGraph;
@class CPTTheme;

@interface PlotItem : NSObject
{
    @private
    CPTNativeImage *cachedImage;
}

@property (nonatomic, retain) CPTGraphHostingView *defaultLayerHostingView;
@property (nonatomic, retain) NSMutableArray *graphs;

-(void)renderInView:(UIView *)hostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated;
-(CPTNativeImage *)image;

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated;

-(void)setTitleDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds;
-(void)setPaddingDefaultsForGraph:(CPTGraph *)graph withBounds:(CGRect)bounds;

-(void)reloadData;
-(void)applyTheme:(CPTTheme *)theme toGraph:(CPTGraph *)graph withDefault:(CPTTheme *)defaultTheme;

-(void)addGraph:(CPTGraph *)graph;
-(void)addGraph:(CPTGraph *)graph toHostingView:(CPTGraphHostingView *)layerHostingView;
-(void)killGraph;

-(void)generateData;

@end
