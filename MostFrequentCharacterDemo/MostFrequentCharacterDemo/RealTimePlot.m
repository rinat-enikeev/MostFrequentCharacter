//
//  RealTimePlot.m
//  CorePlotGallery
//

#import "RealTimePlot.h"

static const NSUInteger kFrameRate = 5;
static const NSUInteger kMaxDataPoints = 52;
static NSString *const kPlotIdentifier = @"Data Source Plot";

@implementation RealTimePlot

-(id)init
{
    if ( (self = [super init]) ) {
        plotData  = [[NSMutableArray alloc] initWithCapacity:kMaxDataPoints];
    }

    return self;
}

-(void)generateData
{
    [plotData removeAllObjects];
    _currentIndex = 0;
}

-(NSUInteger)yMinValue
{
    return _yMinValue;
}

-(void)setYMinValue:(NSUInteger)yMinValue
{
    _yMinValue = yMinValue;
    CPTGraph *theGraph = (self.graphs)[0];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)theGraph.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(_yMinValue) length:CPTDecimalFromUnsignedInteger(_yMaxValue)];
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];
    [thePlot setNeedsRelabel];
    
}

-(NSUInteger)yMaxValue
{
    return _yMaxValue;
}

-(void)setYMaxValue:(NSUInteger)yMaxValue
{
    _yMaxValue = yMaxValue;
    CPTGraph *theGraph = (self.graphs)[0];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)theGraph.defaultPlotSpace;
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(_yMinValue) length:CPTDecimalFromUnsignedInteger(_yMaxValue)];
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];
    [thePlot setNeedsRelabel];

}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{

    CGRect bounds = layerHostingView.bounds;
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds] ;
    [self addGraph:graph toHostingView:layerHostingView];
    [self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];

    [self setTitleDefaultsForGraph:graph withBounds:bounds];
    [self setPaddingDefaultsForGraph:graph withBounds:bounds];

    graph.plotAreaFrame.paddingTop    = 5.0;
    graph.plotAreaFrame.paddingRight  = 5.0;
    graph.plotAreaFrame.paddingBottom = 20.0;
    graph.plotAreaFrame.paddingLeft   = 20.0;
    graph.plotAreaFrame.masksToBorder = NO;

    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];

    // Axes
    // X axis
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x                  = axisSet.xAxis;
    x.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    x.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    x.majorGridLineStyle          = majorGridLineStyle;
    x.minorGridLineStyle          = minorGridLineStyle;
    x.minorTicksPerInterval       = 9;
    x.title                       = _xAxisText;
    x.titleOffset                 = 35.0;
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.numberStyle = NSNumberFormatterScientificStyle;
    x.labelFormatter           = labelFormatter;

    // Y axis
    CPTXYAxis *y = axisSet.yAxis;
    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    y.majorGridLineStyle          = majorGridLineStyle;
    y.minorGridLineStyle          = minorGridLineStyle;
    y.minorTicksPerInterval       = 4;
    y.labelOffset                 = 2.0;
    y.title                       = _yAxisText;
    y.titleOffset                 = 30.0;
    y.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
    y.labelFormatter              = labelFormatter;

    // Rotate the labels by 45 degrees, just to show it can be done.
    x.labelRotation = M_PI_4;

    // Create the plot
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier     = kPlotIdentifier;
    dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;

    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 3.0;
    lineStyle.lineColor              = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;

    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];

    // Plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(_xMinValue) length:CPTDecimalFromUnsignedInteger(_xMaxValue)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(_yMinValue) length:CPTDecimalFromUnsignedInteger(_yMaxValue)];

}

#pragma mark -
#pragma mark Timer callback

-(void)newData:(NSNumber *)number atIndex:(NSUInteger)index
{
    CPTGraph *theGraph = (self.graphs)[0];
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];

    if ( thePlot ) {
        if ( plotData.count >= kMaxDataPoints ) {
            [plotData removeObjectAtIndex:0];
            [thePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
        }

        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)theGraph.defaultPlotSpace;
        NSUInteger location       = (_currentIndex >= kMaxDataPoints ? _currentIndex - kMaxDataPoints + 2 : 0);

        CPTPlotRange *oldRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger( (location > 0) ? (location - 1) : 0 )
                                                              length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];
        CPTPlotRange *newRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
                                                              length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];

        [CPTAnimation animate:plotSpace
                     property:@"xRange"
                fromPlotRange:oldRange
                  toPlotRange:newRange
                     duration:CPTFloat(1.0 / kFrameRate)];

        _currentIndex++;
        [plotData addObject:number];
        [thePlot insertDataAtIndex:plotData.count - 1 numberOfRecords:1];
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [plotData count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num = nil;

    switch ( fieldEnum ) {
        case CPTScatterPlotFieldX:
            num = @(_xStep * (index + _currentIndex - plotData.count) + _xMinValue);
            break;

        case CPTScatterPlotFieldY:
            num = plotData[index];
            break;

        default:
            break;
    }

    return num;
}

@end
