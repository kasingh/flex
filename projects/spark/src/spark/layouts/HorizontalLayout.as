////////////////////////////////////////////////////////////////////////////////
//
//  ADOBE SYSTEMS INCORPORATED
//  Copyright 2008 Adobe Systems Incorporated
//  All Rights Reserved.
//
//  NOTICE: Adobe permits you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

package mx.layout
{
import flash.display.DisplayObject;	
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.events.EventDispatcher;	
import flash.ui.Keyboard;

import mx.components.baseClasses.GroupBase;
import mx.graphics.IGraphicElement;

import mx.containers.utilityClasses.Flex;
import mx.events.PropertyChangeEvent;


/**
 *  Documentation is not currently available.
 */
public class HorizontalLayout extends LayoutBase
{
    include "../core/Version.as";

    //--------------------------------------------------------------------------
    //
    //  Class methods
    //
    //--------------------------------------------------------------------------
    
    private static function calculatePercentHeight( layoutItem:ILayoutItem, height:Number ):Number
    {
    	var percentHeight:Number = LayoutItemHelper.pinBetween(layoutItem.percentSize.y * 0.01 * height,
    	                                                       layoutItem.minSize.y,
    	                                                       layoutItem.maxSize.y );
    	return percentHeight < height ? percentHeight : height;
    }
        
    //--------------------------------------------------------------------------
    //
    //  Constructor
    //
    //--------------------------------------------------------------------------

    /**
     *  Constructor. 
     */    
    public function HorizontalLayout():void
    {
		super();
    }
    
    //--------------------------------------------------------------------------
    //
    //  Properties
    //
    //--------------------------------------------------------------------------
    
    //----------------------------------
    //  gap
    //----------------------------------

    private var _gap:int = 6;

    [Inspectable(category="General")]

    /**
     *  Horizontal space between columns.
     * 
     *  @default 6
     */
    public function get gap():int
    {
        return _gap;
    }

    /**
     *  @private
     */
    public function set gap(value:int):void
    {
        if (_gap == value) 
            return;
    
	    _gap = value;
 	    invalidateTargetSizeAndDisplayList();
    }
    
    //----------------------------------
    //  columnCount
    //----------------------------------

    private var _columnCount:int = -1;
    
    [Bindable("propertyChange")]
    [Inspectable(category="General")]

    /**
     *  Specifies the number of items to display.
     * 
     *  If <code>columnCount</code> is -1, then all of them items are displayed.
     * 
     *  This value implies the layout's <code>measuredWidth</code>.
     * 
     *  If the width of the <code>target</code> has been explicitly set,
     *  then this property has no effect.
     * 
     *  @default -1
     */
    public function get columnCount():int
    {
        return _columnCount;
    }

    /**
     *  Sets the <code>columnCount</code> property without causing
     *  invalidation.  
     * 
     *  This method is intended to be used by subclass updateDisplayList() 
     *  methods to sync the columnCount property with the actual number
     *  of visible columns.
     *
     *  @param value The number of visible columns.
     */
    protected function setColumnCount(value:int):void
    {
        if (_columnCount == value)
            return;
        var oldValue:int = _columnCount;
        _columnCount = value;
        dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, "columnCount", oldValue, value));
    }
        
    
    //----------------------------------
    //  requestedColumnCount
    //----------------------------------

    private var _requestedColumnCount:int = -1;
    
    [Inspectable(category="General")]

    /**
     *  Specifies the number of items to display.
     * 
     *  If <code>requestedColumnCount</code> is -1, then all of them items are displayed.
     * 
     *  This value implies the layout's <code>measuredWidth</code>.
     * 
     *  If the width of the <code>target</code> has been explicitly set,
     *  this property has no effect.
     * 
     *  @default -1
     */
    public function get requestedColumnCount():int
    {
        return _requestedColumnCount;
    }

    /**
     *  @private
     */
    public function set requestedColumnCount(value:int):void
    {
        if (_requestedColumnCount == value)
            return;
                               
        _requestedColumnCount = value;
        invalidateTargetSizeAndDisplayList();
    }    
    
    //----------------------------------
    //  explicitColumnWidth
    //----------------------------------

    /**
     *  The column width requested by explicitly setting
     *  <code>columnWidth</code>.
     */
    protected var explicitColumnWidth:Number;

    //----------------------------------
    //  columnWidth
    //----------------------------------
    
    private var _columnWidth:Number = 20;

    [Inspectable(category="General")]

    /**
     *  Specifies the width of the columns if <code>variableColumnWidth</code>
     *  is false.
     *  
     *  @default 20
     */
    public function get columnWidth():Number
    {
        return _columnWidth;
    }

    /**
     *  @private
     */
    public function set columnWidth(value:Number):void
    {
        explicitColumnWidth = value;

        if (_columnWidth != value)
        {
            setColumnWidth(value);
 		   	var layoutTarget:GroupBase = target;
        	if (layoutTarget != null) 
        	{
            	layoutTarget.invalidateSize();
	            layoutTarget.invalidateDisplayList();
        	}
        }
    }

    /**
     *  Sets the <code>columnWidth</code> property without causing invalidation or 
     *  setting of <code>explicitColumnWidth</code> which
     *  permanently locks in the width of the columns.
     *
     *  @param value The column width, in pixels.
     */
    protected function setColumnWidth(value:Number):void
    {
        _columnWidth = value;
    }    


    //----------------------------------
    //  variableColumnWidth
    //----------------------------------

    /**
     *  @private
     */
    private var _variableColumnWidth:Boolean = true;

    [Inspectable(category="General")]

    /**
     *  If false, i.e. "fixed column width" is specified, the width of
     *  each item is set to the value of <code>columnWidth</code>.
     * 
     *  If the <code>columnWidth</code> property wasn't explicitly set,
     *  then it's initialized with the <code>measuredWidth</code> of
     *  the first item.
     * 
     *  The items' <code>includeInLayout</code>, 
     *  <code>measuredWidth</code>, <code>minWidth</code>,
     *  and <code>percentWidth</code> properties are ignored when 
     *  <code>variableColumnWidth</code> is false.
     * 
     *  @default true
     */
    public function get variableColumnWidth():Boolean
    {
        return _variableColumnWidth;
    }

    /**
     *  @private
     */
    public function set variableColumnWidth(value:Boolean):void
    {
        if (value == _variableColumnWidth) return;
        
        _variableColumnWidth = value;
 		var layoutTarget:GroupBase = target;
        if (layoutTarget != null) {
    		layoutTarget.invalidateSize();
        	layoutTarget.invalidateDisplayList();
        }
    }
    
    //----------------------------------
    //  firstIndexInView
    //----------------------------------

    /**
     *  @private
     */
    private var _firstIndexInView:int = -1;

    [Inspectable(category="General")]
    [Bindable("indexInViewChanged")]    

    /**
     *  The index of the first column that's part of the layout and within
     *  the layout target's scrollRect, or -1 if nothing has been displayed yet.
     * 
     *  Note that the column may only be partially in view.
     * 
     *  @see lastIndexInView
     *  @see inView
     */
    public function get firstIndexInView():int
    {
        return _firstIndexInView;
    }
    
    
    //----------------------------------
    //  lastIndexInView
    //----------------------------------

    /**
     *  @private
     */
    private var _lastIndexInView:int = -1;
    
    [Inspectable(category="General")]
    [Bindable("indexInViewChanged")]    

    /**
     *  The index of the last column that's part of the layout and within
     *  the layout target's scrollRect, or -1 if nothing has been displayed yet.
     * 
     *  Note that the column may only be partially in view.
     * 
     *  @see firstIndexInView
     *  @see inView
     */
    public function get lastIndexInView():int
    {
        return _lastIndexInView;
    }

    /**
     *  Sets the <code>firstIndexInView</code> and <code>lastIndexInView</code>
     *  properties and dispatches a <code>"indexInViewChanged"</code>
     *  event.  
     * 
     *  This method is intended to be used by subclasses that 
     *  override updateDisplayList() to sync the first and 
     *  last indexInView properties with the current display.
     *
     *  @param firstIndex The new value for firstIndexInView.
     *  @param lastIndex The new value for lastIndexInView.
     * 
     *  @see firstIndexInView
     *  @see lastIndexInview
     */
    protected function setIndexInView(firstIndex:int, lastIndex:int):void
    {
        if ((_firstIndexInView == firstIndex) && (_lastIndexInView == lastIndex))
            return;
            
        _firstIndexInView = firstIndex;
        _lastIndexInView = lastIndex;
        dispatchEvent(new Event("indexInViewChanged"));
    }
    
    /**
     *  An index is "in view" if the corresponding non-null layout item is 
     *  within the horizontal limits of the layout target's scrollRect
     *  and included in the layout.
     *  
     *  Returns 1.0 if the specified index is completely in view, 0.0 if
     *  it's not, and a value in between if the index is partially 
     *  within the view.
     * 
     *  If the specified index is partially within the view, the 
     *  returned value is the percentage of the corresponding
     *  layout item that's visible.
     * 
     *  Returns 0.0 if the specified index is invalid or if it corresponds to
     *  null item, or a ILayoutItem for which includeInLayout is false.
     * 
     *  @return the percentage of the specified item that's in view.
     *  @see firstIndexInView
     *  @see lastIndexInView
     */
   public function inView(index:int):Number 
    {
        var g:GroupBase = GroupBase(target);
        if (!g)
            return 0.0;
            
        if ((index < 0) || (index >= g.numLayoutItems))
           return 0.0;   
           
        var li:ILayoutItem = g.getLayoutItemAt(index);
        if ((li == null) || !li.includeInLayout)
            return 0.0;
            
        var c0:int = firstIndexInView; 
        var c1:int = lastIndexInView;
        
        // outside the visible index range
        if ((c0 == -1) || (c1 == -1) || (index < c0) || (index > c1))
            return 0.0;
            
        // within the visible index range, but not first or last            
        if ((index > c0) && (index < c1))
            return 1.0;

        // index is first (c0) or last (c1) visible column
        var x0:Number = g.horizontalScrollPosition;
        var x1:Number = x0 + g.width;
        var ix0:Number = li.actualPosition.x;
        var ix1:Number = ix0 + li.actualSize.x;
        if (ix0 >= ix1)  // item has 0 or negative width
            return 1.0;
        if ((ix0 >= x0) && (ix1 <= x1))
            return 1.0;
        return (Math.max(x0, ix0) - Math.min(x1, ix1)) / (ix1 - ix0);
    } 
    
    /**
     *  Binary search for the first layout item that contains y.  
     * 
     *  This function considers both the item's actual bounds and 
     *  the gap that follows it to be part of the item.  The search 
     *  covers index i0 through i1 (inclusive).
     * 
     *  This function is intended for variable height items.
     * 
     *  Returns the index of the item that contains x, or -1.
     * 
     *  Implementation note: currently the inclusion test is slightly
     *  incorrect, since we're comparing y with the _closed_ interval
     *  from p.x to p.x + s.x + gap.  This is to accomodate checking the
     *  "right" of the scrollRect, see the computation of i1 in
     *  scrollPositionChanged.  One alternative that would restore
     *  the more correct open ended interval, would be to check
     *  the right of the scrollRect less some infintesimally small
     *  amount.
     * 
     * @private 
     */
    private static function findIndexAt(x:Number, gap:int, g:GroupBase, i0:int, i1:int):int
    {
        var index:int = (i0 + i1) / 2;
        var item:ILayoutItem = g.getLayoutItemAt(index);        
        var p:Point = item.actualPosition;
        var s:Point = item.actualSize;
        // TBD: deal with null item, includeInLayout false.
        if ((x >= p.x) && (x <= p.x + s.x + gap))
            return index;
        else if (i0 == i1)
            return -1;
        else if (x < p.x)
            return findIndexAt(x, gap, g, i0, Math.max(i0, index-1));
        else 
            return findIndexAt(x, gap, g, Math.min(index+1, i1), i1);
    }  
    
   /**
    *  Returns the index of the first non-null includeInLayout item, 
    *  beginning with the item at index i.  
    * 
    *  Returns -1 if no such item can be found.
    *  
    *  @private
    */
    private static function findLayoutItemIndex(g:GroupBase, i:int, dir:int):int
    {
        var n:int = g.numLayoutItems;
        while((i >= 0) && (i < n))
        {
           var item:ILayoutItem = g.getLayoutItemAt(i);
           if (item && item.includeInLayout)
           {
               return i;      
           }
           i += dir;
        }
        return -1;
    } 
    
  /**
    *  Updates the first,lastIndexInView properties per the new
    *  scroll position.
    *  
    *  @see setIndexInView
    */
    override protected function scrollPositionChanged():void
    {
        super.scrollPositionChanged();
        
        var g:GroupBase = target;
        if (!g)
            return;     

        var n:int = g.numLayoutItems - 1;
        if (n < 0) 
        {
            setIndexInView(-1, -1);
            return;
        }
        
        var scrollR:Rectangle = g.scrollRect;
        if (!scrollR)
        {
            setIndexInView(0, n);
            return;    
        }
        
        var x0:Number = scrollR.left;
        var x1:Number = scrollR.right;
        if (x1 <= x0)
        {
            setIndexInView(-1, -1);
            return;
        }

        // TBD: special case for variableRowHeight false

        var i0:int = findIndexAt(x0 + gap, gap, g, 0, n);
        var i1:int = findIndexAt(x1, gap, g, 0, n);

        // Special case: no item overlaps x0, is index 0 visible?
        if (i0 == -1)
        {   
            var index0:int = findLayoutItemIndex(g, 0, +1);
            if (index0 != -1)
            {
                var item0:ILayoutItem = g.getLayoutItemAt(index0); 
                var p0:Point = item0.actualPosition;
                var s0:Point = item0.actualSize;                 
                if ((p0.x < x1) && ((p0.x + s0.x) > x0))
                    i0 = index0;
            }
        }

        // Special case: no item overlaps y1, is index n visible?
        if (i1 == -1)
        {
            var index1:int = findLayoutItemIndex(g, n, -1);
            if (index1 != -1)
            {
                var item1:ILayoutItem = g.getLayoutItemAt(index1); 
                var p1:Point = item1.actualPosition;
                var s1:Point = item1.actualSize;                 
                if ((p1.x < x1) && ((p1.x + s1.x) > x0))
                    i1 = index1;
            }
        }   

        setIndexInView(i0, i1);
    }

       /**
     *  If the item at index i is non-null and includeInLayout,
     *  then return it's actual bounds, otherwise return null.
     * 
     *  @private
     */
    private static function layoutItemBounds(g:GroupBase, i:int):Rectangle
    {
        var item:ILayoutItem = g.getLayoutItemAt(i);
        if (item && item.includeInLayout)
        {
            var p:Point = item.actualPosition;
            var s:Point = item.actualSize; 
            return new Rectangle(p.x, p.y, s.x, s.y);        
        }
        return null;    
    }

    /**
     *  Returns the actual position/size Rectangle of the first partially 
     *  visible or not-visible, non-null includeInLayout item, beginning
     *  with the item at index i, searching in direction dir (dir must
     *  be +1 or -1).   The last argument is the GroupBase scrollRect, it's
     *  guaranteed to be non-null.
     * 
     *  Returns null if no such item can be found.
     *  
     *  @private
     */
    private function findLayoutItemBounds(g:GroupBase, i:int, dir:int, r:Rectangle):Rectangle
    {
        var n:int = g.numLayoutItems;

        if (inView(i) >= 1)
            i = Math.max(0, Math.min(n - 1, i + dir));

        while((i >= 0) && (i < n))
        {
           var itemR:Rectangle = layoutItemBounds(g, i);
           // Special case: if the scrollRect r _only_ contains
           // itemR, then if we're searching left (dir == -1),
           // and itemR's left edge is visible, then try again
           // with i-1.   Likewise for dir == +1.
           if (itemR)
           {
               var overlapsLeft:Boolean = (dir == -1) && (itemR.left == r.left) && (itemR.right >= r.right);
               var overlapsRight:Boolean = (dir == +1) && (itemR.right == r.right) && (itemR.left <= r.left);
               if (!(overlapsLeft || overlapsRight))             
                   return itemR;               
           }
           i += dir;
        }
        return null;
    }

    /**
     *  Overrides the default handling of UP/DOWN and 
     *  PAGE_UP, PAGE_DOWN. 
     * 
     *  <ul>
     * 
     *  <li> 
     *  <code>LEFT</code>
     *  If the firstIndexInView item is partially visible then top justify
     *  it, otherwise top justify the item at the previous index.
     *  </li>
     * 
     *  <li> 
     *  <code>RIGHT</code>
     *  If the lastIndexInView item is partially visible, then bottom justify
     *  it, otherwise bottom justify the item at the following index.
     *  </li>
     * 
     *  <code>PAGE_UP</code>
     *  <li>
     *  If the firstIndexInView item is partially visible, then bottom
     *  justify it, otherwise bottom justify item at the previous index.  
     *  </li>
     * 
     *  <li> 
     *  <code>PAGE_DOWN</code>
     *  If the lastIndexInView item is partially visible, then top
     *  justify it, otherwise top justify item at the following index.  
     *  </li>
     *  
     *  </ul>
     *   
     *  @see firstIndexInView
     *  @see lastIndexInView
     *  @see horizontalScrollPosition
     */
    override public function horizontalScrollPositionDelta(unit:uint):Number
    {
        var g:GroupBase = target;
        if (!g)
            return 0;     

        var maxIndex:int = g.numLayoutItems -1;
        if (maxIndex < 0)
            return 0;
            
        var scrollR:Rectangle = g.scrollRect;
        if (!scrollR)
            return 0;
            
        var itemR:Rectangle = null;
        switch(unit)
        {
            case Keyboard.LEFT:
            case Keyboard.PAGE_UP:
                itemR = findLayoutItemBounds(g, firstIndexInView, -1, scrollR);
                break;

            case Keyboard.RIGHT:
            case Keyboard.PAGE_DOWN:
                itemR = findLayoutItemBounds(g, lastIndexInView, +1, scrollR);
                break;

            default:
                return super.horizontalScrollPositionDelta(unit);
        }
        
        if (!itemR)
            return 0;
            
        var delta:Number = 0;     
        switch (unit)
        {
            case Keyboard.LEFT:
                delta = Math.max(-scrollR.width, itemR.left - scrollR.left);
                break;
                
            case Keyboard.RIGHT:
                delta = Math.min(scrollR.width, itemR.right - scrollR.right);
                break;
                
            case Keyboard.PAGE_UP:
                if ((itemR.left < scrollR.left) && (itemR.right >= scrollR.right))
                    delta = Math.max(-scrollR.width, itemR.left - scrollR.left);
                else
                    delta = itemR.right - scrollR.right;
                break;

            case Keyboard.PAGE_DOWN:
                if ((itemR.left < scrollR.left) && (itemR.right >= scrollR.right))
                    delta = Math.min(scrollR.width, itemR.right - scrollR.right);
                else
                    delta = itemR.left - scrollR.left;
                break;
        }
        
        var maxDelta:Number = g.contentWidth - scrollR.width - scrollR.x;
        var minDelta:Number = -scrollR.x;
        return Math.min(maxDelta, Math.max(minDelta, delta));        
    }     

    public function variableColumnWidthMeasure(layoutTarget:GroupBase):void
    {
        var minWidth:Number = 0;
        var minHeight:Number = 0;
        var preferredWidth:Number = 0;
        var preferredHeight:Number = 0;
        var visibleWidth:Number = 0;
        var visibleColumns:uint = 0;
        var reqColumns:int = requestedColumnCount;        
        
        var count:uint = layoutTarget.numLayoutItems;
        var totalCount:uint = count; // How many items will be laid out
        for (var i:int = 0; i < count; i++)
        {
            var li:ILayoutItem = layoutTarget.getLayoutItemAt(i);
            if (!li || !li.includeInLayout)
            {
            	totalCount--;
                continue;
            }            

            preferredHeight = Math.max(preferredHeight, li.preferredSize.y);
            preferredWidth += li.preferredSize.x; 
            
            var vcr:Boolean = (reqColumns != -1) && (visibleColumns < reqColumns);
            if (vcr || (reqColumns == -1))
            {
                var mw:Number =  hasPercentWidth(li) ? li.minSize.x : li.preferredSize.x;
                var mh:Number = hasPercentHeight(li) ? li.minSize.y : li.preferredSize.y;                   
                minWidth += mw;
                minHeight = Math.max(minHeight, mh);
            }
            if (vcr) 
            {
            	visibleWidth = preferredWidth;
            	visibleColumns += 1;
            }
        }
        
        if (totalCount > 1)
        { 
            preferredWidth += gap * (totalCount - 1);
            var vgap:Number = (visibleColumns > 1) ? ((visibleColumns - 1) * gap) : 0;
            visibleWidth +=  vgap;
            minWidth += vgap;
        }
        
        layoutTarget.measuredWidth = (reqColumns == -1) ? preferredWidth : visibleWidth;
        layoutTarget.measuredHeight = preferredHeight;

        layoutTarget.measuredMinWidth = minWidth; 
        layoutTarget.measuredMinHeight = minHeight;
        
        layoutTarget.setContentSize(preferredWidth, preferredHeight);
    }
    
    
    private function fixedColumnWidthMeasure(layoutTarget:GroupBase):void
    {
        var cols:uint = layoutTarget.numLayoutItems;
        
		var columnWidth:Number = this.columnWidth;
        if (isNaN(explicitColumnWidth))
        {
            if (cols == 0)
            	columnWidth = 0;
            else 
      			columnWidth = layoutTarget.getLayoutItemAt(0).preferredSize.x;
        	setColumnWidth(columnWidth);
        }

        var reqColumns:int = requestedColumnCount;        
        var visibleCols:uint = (reqColumns == -1) ? cols : reqColumns;
        var contentWidth:Number = (cols * columnWidth) + ((cols > 1) ? (gap * (cols - 1)) : 0);
        var visibleWidth:Number = (visibleCols * columnWidth) + ((visibleCols > 1) ? (gap * (visibleCols - 1)) : 0);
        
        var rowHeight:Number = layoutTarget.explicitHeight;
        var minRowHeight:Number = rowHeight;
        if (isNaN(rowHeight)) 
        {
			minRowHeight = rowHeight = 0;
	        var count:uint = layoutTarget.numLayoutItems;
	        for (var i:int = 0; i < count; i++)
	        {
	            var layoutItem:ILayoutItem = layoutTarget.getLayoutItemAt(i);
	            if (!layoutItem || !layoutItem.includeInLayout) continue;
	            rowHeight = Math.max(rowHeight, layoutItem.preferredSize.y);
	            var itemMinHeight:Number = hasPercentHeight(layoutItem) ? layoutItem.minSize.y : layoutItem.preferredSize.y;
	            minRowHeight = Math.max(minRowHeight, itemMinHeight);
	        }
        }     
        
        layoutTarget.measuredWidth = visibleWidth;
        layoutTarget.measuredHeight = rowHeight;
        
        layoutTarget.measuredMinWidth = visibleWidth;
        layoutTarget.measuredMinHeight = minRowHeight;
        
        layoutTarget.setContentSize(contentWidth, rowHeight);
    }
    

    override public function measure():void
    {
    	var layoutTarget:GroupBase = target;
        if (!layoutTarget)
            return;
            
        if (variableColumnWidth) 
        	variableColumnWidthMeasure(layoutTarget);
        else 
        	fixedColumnWidthMeasure(layoutTarget);
    }    
    
    
    override public function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
    {
    	var layoutTarget:GroupBase = target; 
        if (!layoutTarget)
            return;
        
        // TODO EGeorgie: use vector
        var layoutItemArray:Array = new Array();
        var layoutItem:ILayoutItem;
        var count:uint = layoutTarget.numLayoutItems;
        var totalCount:uint = count; // How many items will be laid out
        for (var i:int = 0; i < count; i++)
        {
            layoutItem = layoutTarget.getLayoutItemAt(i);
            if (!layoutItem || !layoutItem.includeInLayout)
            {
            	totalCount--;
                continue;
            } 
            layoutItemArray.push(layoutItem);
        }

        var totalWidthToDistribute:Number = unscaledWidth;
        if (totalCount > 1)
            totalWidthToDistribute -= (totalCount - 1) * gap;

        distributeWidth(layoutItemArray, totalWidthToDistribute, unscaledHeight); 
                            
        // TODO EGeorgie: verticalAlign
        var vAlign:Number = 0;
        
        // If columnCount wasn't set, then as the LayoutItems are positioned
        // we'll count how many columns fall within the layoutTarget's scrollRect
        var visibleColumns:uint = 0;
        var minVisibleX:Number = layoutTarget.horizontalScrollPosition;
        var maxVisibleX:Number = minVisibleX + unscaledWidth
            
        // Finally, position the LayoutItems and find the first/last
        // visible indices, the content size, and the number of 
        // visible items. 
        var x:Number = 0;
        var maxX:Number = 0;
        var maxY:Number = 0;     
        var firstColInView:int = -1;
        var lastColInView:int = -1;
        
        for (var index:int = 0; index < count; index++)
        {
            layoutItem = layoutTarget.getLayoutItemAt(index);
            if (!layoutItem || !layoutItem.includeInLayout)
                continue;        
        
            // Set the layout item's acutual size and position
            var y:Number = (unscaledHeight - layoutItem.actualSize.y) * vAlign;
            layoutItem.setActualPosition(x, y);
            var dy:Number = layoutItem.actualSize.y;
            if (!variableColumnWidth)
                layoutItem.setActualSize(columnWidth, dy);

            // Update maxX,Y, first,lastVisibleIndex, and x
            var dx:Number = layoutItem.actualSize.x;
            maxX = Math.max(maxX, x + dx);
            maxY = Math.max(maxY, y + dy);            
            if (((x < maxVisibleX) && ((x + dx) > minVisibleX)) || 
                ((dx <= 0) && ((x == maxVisibleX) || (x == minVisibleX))))            
            {
                visibleColumns += 1;
                if (firstColInView == -1)
                   firstColInView = lastColInView = index;
                else
                   lastColInView = index;
            }                
            x += dx + gap;
        }

        setColumnCount(visibleColumns);  
        setIndexInView(firstColInView, lastColInView);
        layoutTarget.setContentSize(maxX, maxY);      	      
        updateScrollRect(unscaledWidth, unscaledHeight);
    }


    /**
     *  This function sets the width of each child
     *  so that the widths add up to <code>width</code>. 
     *  Each child is set to its preferred width
     *  if its percentWidth is zero.
     *  If its percentWidth is a positive number,
     *  the child grows (or shrinks) to consume its
     *  share of extra space.
     *  
     *  The return value is any extra space that's left over
     *  after growing all children to their maxWidth.
     */
    public function distributeWidth(layoutItemArray:Array,
                                     width:Number,
                                     height:Number):Number
    {
        var spaceToDistribute:Number = width;
        var totalPercentWidth:Number = 0;
        var childInfoArray:Array = [];
        var childInfo:HLayoutItemFlexChildInfo;
        var newHeight:Number;
        
        // If the child is flexible, store information about it in the
        // childInfoArray. For non-flexible children, just set the child's
        // width and height immediately.
        for each (var layoutItem:ILayoutItem in layoutItemArray)
        {
            if (hasPercentWidth(layoutItem))
            {
                totalPercentWidth += layoutItem.percentSize.x;

                childInfo = new HLayoutItemFlexChildInfo();
                childInfo.layoutItem = layoutItem;
                childInfo.percent    = layoutItem.percentSize.x;
                childInfo.min        = layoutItem.minSize.x;
                childInfo.max        = layoutItem.maxSize.x;
                
                childInfoArray.push(childInfo);                
            }
            else
            {
                newHeight = NaN;
                if (hasPercentHeight(layoutItem))
                   newHeight = calculatePercentHeight(layoutItem, height);
                
                layoutItem.setActualSize(NaN, newHeight);
                spaceToDistribute -= layoutItem.actualSize.x;
            } 
        }

        // Distribute the extra space among the flexible children
        if (totalPercentWidth)
        {
            spaceToDistribute = Flex.flexChildrenProportionally(width,
                                                                spaceToDistribute,
                                                                totalPercentWidth,
                                                                childInfoArray);
            for each (childInfo in childInfoArray)
            {
            	newHeight = NaN;
            	if (hasPercentHeight(childInfo.layoutItem))
            	   newHeight = calculatePercentHeight(childInfo.layoutItem, height);

                childInfo.layoutItem.setActualSize(childInfo.size, newHeight);
            }
        }
        return spaceToDistribute;
    }

}
}

[ExcludeClass]

import mx.layout.ILayoutItem;
import mx.containers.utilityClasses.FlexChildInfo;

class HLayoutItemFlexChildInfo extends FlexChildInfo
{
    public var layoutItem:ILayoutItem;	
}
