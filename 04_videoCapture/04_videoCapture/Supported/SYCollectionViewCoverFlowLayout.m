//
//  SYCollectionViewCoverFlowLayout.m
//  04_videoCapture
//
//  Created by sy on 2019/8/16.
//  Copyright © 2019 sy. All rights reserved.
//

#import "SYCollectionViewCoverFlowLayout.h"
#import "SYCollectionViewCoverFlowLayoutAttributes.h"

#define ACTIVE_DISTANCE         250
#define TRANSLATE_DISTANCE      100
#define ZOOM_FACTOR             0.2f
#define FLOW_OFFSET             40
#define INACTIVE_GREY_VALUE     0.5f


@implementation SYCollectionViewCoverFlowLayout

- (instancetype)init
{
    return [self initWithCollectionViewSize:[UIScreen mainScreen].bounds.size];
}

- (instancetype)initWithCollectionViewSize:(CGSize)size {
    if (!(self = [super init]))
        return nil;
    
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.minimumInteritemSpacing = MAX(size.width, size.height);
    self.minimumLineSpacing = - 60;
    return self;
}

+ (Class)layoutAttributesClass {
    return [SYCollectionViewCoverFlowLayoutAttributes class];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return TRUE;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray* layoutAtrributes = [super layoutAttributesForElementsInRect:rect];
    
    CGRect visibleRect = CGRectMake(self.collectionView.contentOffset.x,
                                    self.collectionView.contentOffset.y,
                                    CGRectGetWidth(self.collectionView.bounds),
                                    CGRectGetHeight(self.collectionView.bounds));
    for (UICollectionViewLayoutAttributes* layoutAtrribute in layoutAtrributes) {
        if (CGRectIntersectsRect(visibleRect, layoutAtrribute.frame)) {
            [self applyCoverFlowAttributesToLayoutAtrributes:layoutAtrribute forVisibleRect:visibleRect];
        }
    }
    
    return layoutAtrributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes* layoutAtrribute = [super layoutAttributesForItemAtIndexPath:indexPath];
    CGRect visibleRect = CGRectMake(self.collectionView.contentOffset.x,
                                    self.collectionView.contentOffset.y,
                                    CGRectGetWidth(self.collectionView.bounds),
                                    CGRectGetHeight(self.collectionView.bounds));
    [self applyCoverFlowAttributesToLayoutAtrributes:layoutAtrribute forVisibleRect:visibleRect];
    return layoutAtrribute;
}

- (void)applyCoverFlowAttributesToLayoutAtrributes:(UICollectionViewLayoutAttributes*)layoutAtrributes forVisibleRect:(CGRect)visibleRect {
     // We want to skip supplementary views.
    if (layoutAtrributes.representedElementKind) return;
    
    // Calculate the distance from the center of the visible rect to the center of the attributes.
    // Then normalize it so we can compare them all. This way, all items further away than the
    // active get the same transform.
    CGFloat distanceFromVisibleRectToItem = CGRectGetMidX(visibleRect) - layoutAtrributes.center.x;
    CGFloat normalizedDistance = distanceFromVisibleRectToItem / ACTIVE_DISTANCE;
    BOOL isLeft = distanceFromVisibleRectToItem > 0;
    CATransform3D transform = CATransform3DIdentity;
    
    CGFloat maskAlpha = 0.0f;
    
    if (fabs(distanceFromVisibleRectToItem) < ACTIVE_DISTANCE)
    {
        // We're close enough to apply the transform in relation to
        // how far away from the center we are.
        
        transform = CATransform3DTranslate(CATransform3DIdentity, (isLeft? - FLOW_OFFSET : FLOW_OFFSET)*ABS(distanceFromVisibleRectToItem/TRANSLATE_DISTANCE), 0, (1 - fabs(normalizedDistance)) * 40000 + (isLeft? 200 : 0));
        
        // Set the perspective of the transform.
        transform.m34 = -1/(4.6777 * self.itemSize.width);
        
        // Set the zoom factor.
        CGFloat zoom = 1 + ZOOM_FACTOR*(1 - ABS(normalizedDistance));
        transform = CATransform3DRotate(transform, (isLeft? 1 : -1) * fabs(normalizedDistance) * 45 * M_PI / 180, 0, 1, 0);
        transform = CATransform3DScale(transform, zoom, zoom, 1);
        layoutAtrributes.zIndex = 1;
        
        CGFloat ratioToCenter = (ACTIVE_DISTANCE - fabs(distanceFromVisibleRectToItem)) / ACTIVE_DISTANCE;
        // Interpolate between 0.0f and INACTIVE_GREY_VALUE
        maskAlpha = INACTIVE_GREY_VALUE + ratioToCenter * (-INACTIVE_GREY_VALUE);
    }
    else
    {
        // We're too far away - just apply a standard perspective transform.
        
        transform.m34 = -1/(4.6777 * self.itemSize.width);
        transform = CATransform3DTranslate(transform, isLeft? -FLOW_OFFSET : FLOW_OFFSET, 0, 0);
        transform = CATransform3DRotate(transform, (isLeft? 1 : -1) * 45 * M_PI / 180, 0, 1, 0);
        layoutAtrributes.zIndex = 0;
        
        maskAlpha = INACTIVE_GREY_VALUE;
    }
    
    layoutAtrributes.transform3D = transform;
    
    // Rasterize the cells for smoother edges.
    SYCollectionViewCoverFlowLayoutAttributes* coverFlowLayoutAttributes = (SYCollectionViewCoverFlowLayoutAttributes*)layoutAtrributes;
    coverFlowLayoutAttributes.shouldRaster = TRUE;
    coverFlowLayoutAttributes.maskAlpha = maskAlpha;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    // Returns a point where we want the collection view to stop scrolling at.
    
    // First, calculate the proposed center of the collection view once the collection view has stopped
    CGFloat offsetAdjustment = MAXFLOAT;
    CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);
    // Use the center to find the proposed visible rect.
    CGRect proposedRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
    // Get the attributes for the cells in that rect.
    NSArray* array = [self layoutAttributesForElementsInRect:proposedRect];
    
    // This loop will find the closest cell to proposed center of the collection view
    for (UICollectionViewLayoutAttributes* layoutAttributes in array)
    {
        // We want to skip supplementary views
        if (layoutAttributes.representedElementCategory != UICollectionElementCategoryCell)
            continue;
        
        // Determine if this layout attribute's cell is closer than the closest we have so far
        CGFloat itemHorizontalCenter = layoutAttributes.center.x;
        if (fabs(itemHorizontalCenter - horizontalCenter) < fabs(offsetAdjustment))
        {
            offsetAdjustment = itemHorizontalCenter - horizontalCenter;
        }
    }
    
    return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}


@end
