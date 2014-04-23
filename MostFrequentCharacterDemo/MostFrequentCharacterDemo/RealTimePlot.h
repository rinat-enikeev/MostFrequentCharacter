//
//  RealTimePlot.h
//  CorePlotGallery
//

#import "PlotItem.h"

@interface RealTimePlot : PlotItem<CPTPlotDataSource>
{
    @private
    NSMutableArray *plotData;
    NSUInteger _currentIndex;
    NSUInteger _yMaxValue;
    NSUInteger _yMinValue;
}
@property (strong, nonatomic) NSString* xAxisText;
@property (strong, nonatomic) NSString* yAxisText;
@property NSUInteger xMaxValue;
@property NSUInteger xMinValue;
@property NSUInteger xStep;

-(void)newData:(NSNumber*)number atIndex:(NSUInteger)index;
-(NSUInteger)yMaxValue;
-(void)setYMaxValue:(NSUInteger)yMaxValue;
-(NSUInteger)yMinValue;
-(void)setYMinValue:(NSUInteger)yMaxValue;


@end
