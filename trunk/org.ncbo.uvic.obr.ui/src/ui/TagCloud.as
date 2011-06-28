package ui
{
	import events.TagClickedEvent;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import flexlib.containers.FlowBox;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.controls.LinkButton;
	import mx.core.ClassFactory;
	import mx.core.IDataRenderer;
	import mx.core.IFactory;
	import mx.core.ScrollPolicy;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.utils.ArrayUtil;

	/**
	 *  Dispatched when the user clicks on an item in the tag cloud.
	 *  @eventType events.TagClickedEvent.TAG_CLICKED
	 */
	[Event(name="tagClicked", type="events.TagClickedEvent")]

	/**
	 *  Dispatched when the <code>dataProvider</code> property changes.
	 *  @eventType mx.events.CollectionEvent.COLLECTION_CHANGE
	 */
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]

	/** Dispatched when the <code>itemRenderer</code> changes. */
	[Event(name="itemRendererChanged", type="flash.events.Event")]

	[IconFile("TagCloud.png")]

	/**
	 * Displays tags in a cloud.  The items are set using the dataProvider property
	 * and then an itemRenderer is created for each item and added to this container.
	 * 
	 * @author Chris Callendar
	 * @date January 27th, 2009
	 */
	public class TagCloud extends FlowBox
	{
		
		private var collection:ICollectionView;
		private var _dataField:String;
		private var _sizeField:String;
		private var itemRendererMap:Dictionary;
		private var _itemRenderer:IFactory;
		private var _tagSizeFunction:Function;
		
		public function TagCloud() {
			super();
			collection = null;
			_dataField = null;
			_sizeField = null;
			_itemRenderer = new ClassFactory(LinkButton);
			_tagSizeFunction = null;
			horizontalScrollPolicy = ScrollPolicy.OFF;
			verticalScrollPolicy = ScrollPolicy.AUTO;
		}

		
		 [Inspectable(category="Data")]
	    /**
	     * This is an optional function that gets called after the tag is created.
	     * It should take two parameters - the first is the data object, and the second
	     * is the tag UIComponent.  
	     * It should return the fontSize value for the tag.
	     */
		public function get tagSizeFunction():Function {
			return _tagSizeFunction;
		}
		
		public function set tagSizeFunction(func:Function):void {
			_tagSizeFunction = func;
			updateTags();
		}
		
	    [Inspectable(category="Data")]
		public function get dataField():String {
			return _dataField;
		}
		
		public function set dataField(field:String):void {
			if (field != _dataField) {
				_dataField = field;
				updateTagLabels();
			}
		}
		
		[Inspectable(category="Data")]
		public function get tagSizeField():String {
			return _sizeField;
		}
		
		public function set tagSizeField(field:String):void {
			if (field != _sizeField) {
				_sizeField = field;
				updateTags();
			}
		}

	    [Inspectable(category="Data")]
	    /**
	     *  The custom item renderer for the control.
	     *  You can specify a drop-in, inline, or custom item renderer.
	     *  <p>The default item renderer is a CheckBox.</p>
	     */
	    public function get itemRenderer():IFactory {
	        return _itemRenderer;
	    }
	
	    public function set itemRenderer(value:IFactory):void {
	    	if ((value != null) && (value != _itemRenderer)) {
		        _itemRenderer = value;
		        itemRendererMap = new Dictionary();
		        collectionChangeHandler(null);	
		        invalidateSize();
		        invalidateDisplayList();
		        dispatchEvent(new Event("itemRendererChanged"));
		    }
	    }
	    
		[Inspectable(category="Data", defaultValue="undefined")]
		public function get dataCollection():ICollectionView {
			return collection;
		}
		
		[Inspectable(category="Data", defaultValue="undefined")]
		public function get dataProvider():Object {
			return collection;
		}
		
		public function set dataProvider(value:Object):void {
			// copied from ListBase
	        if (collection) {
	            collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
	        }
	        if (value is Array) {
	            collection = new ArrayCollection(value as Array);
	        } else if (value is ICollectionView) {
	            collection = ICollectionView(value);
	        } else if (value is IList) {
	            collection = new ListCollectionView(IList(value));
	        } else if (value is XMLList) {
	            collection = new XMLListCollection(value as XMLList);
	        } else if (value is XML) {
	            var xl:XMLList = new XMLList();
	            xl += value;
	            collection = new XMLListCollection(xl);
	        } else {
	            collection = new ArrayCollection(ArrayUtil.toArray(value));
	        }
	        collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
	        
	        itemRendererMap = new Dictionary();
	
	        var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
	        event.kind = CollectionEventKind.RESET;
	        collectionChangeHandler(event);
	        dispatchEvent(event);
	
	        invalidateProperties();
	        invalidateSize();
	        invalidateDisplayList();
	    }
	    
	    public function clear():void {
	    	itemRendererMap = new Dictionary();
	    	removeAllChildren();
	    }
	    
		private function collectionChangeHandler(event:CollectionEvent):void {
			removeAllChildren();
			if (collection != null) {
				for (var i:int = 0; i < collection.length; i++) {
					var obj:Object = collection[i];
					if (obj != null) {
						var tag:UIComponent = (itemRendererMap[obj] as UIComponent);
						if (tag == null) {
							tag = createTag();
							itemRendererMap[obj] = tag;
							initializeTag(tag);
						}
						tag.addEventListener(MouseEvent.CLICK, tagClickedHandler);
						addChild(tag);
						// do this after adding it to the parent!
						if (tag is IDataRenderer) {
							IDataRenderer(tag).data = obj;
						}
						// after the data property is set
						updateTagLabel(tag);
						updateTag(tag);
					}
				}
			}
		}
				
		override public function removeChild(item:DisplayObject):DisplayObject {
			var child:DisplayObject = super.removeChild(item);
			if (child is UIComponent) {
				(child as UIComponent).removeEventListener(MouseEvent.CLICK, tagClickedHandler);
			}
			return child;
		}
		
		protected function createTag():UIComponent {
			var obj:Object = _itemRenderer.newInstance();
			if (obj is UIComponent) {
				return (obj as UIComponent);
			}
			return null;
		}
		
		protected function initializeTag(tag:UIComponent):void {
			tag.useHandCursor = true;
			tag.buttonMode = true;
			tag.setStyle("paddingLeft", 4);
			tag.setStyle("paddingTop", 4);
			tag.setStyle("paddingRight", 4);
			tag.setStyle("paddingBottom", 4);
		}
		
		private function updateTags():void {
			for (var i:int = 0; i < numChildren; i++) {
				var tag:UIComponent = getTagAt(i);
				updateTag(tag);
			}			
		}
	
		protected function updateTag(tag:UIComponent):void {
			if (tag) {
				var obj:Object = getTagData(tag);
				var fontSize:Number = NaN;
				if ((tagSizeField != null) && (obj != null) && obj.hasOwnProperty(tagSizeField)) {
					fontSize = Number(obj[tagSizeField]);
				} else if (tagSizeFunction != null) {
					fontSize = Number(tagSizeFunction(obj, tag));
				} 
				if (!isNaN(fontSize)) {
					tag.setStyle("fontSize", fontSize);
				}
			}
		}
		
		private function updateTagLabels():void {
			for (var i:int = 0; i < numChildren; i++) {
				var tag:UIComponent = getTagAt(i);
				updateTagLabel(tag);
			}
		}

		protected function updateTagLabel(tag:UIComponent):void {
			if (tag) {
				var obj:Object = getTagData(tag);
				var lbl:String = getTagLabel(obj);
				tag.toolTip = lbl;
				if (tag.hasOwnProperty("label")) {
					tag["label"] = lbl;
				}
			}
		}
		
		protected function getTagLabel(data:Object):String {
			if ((dataField != null) && (data != null) && data.hasOwnProperty(dataField)) {
				return String(data[dataField]);
			}
			return ((data != null) ? data.toString() : "null");
		}
		
		protected function getTagData(tag:UIComponent):Object {
			return (tag is IDataRenderer ? IDataRenderer(tag).data : null);
		}
		
		protected function tagClickedHandler(event:MouseEvent):void {
			var target:UIComponent = UIComponent(event.currentTarget);
			var item:Object = getTagData(target);
			dispatchEvent(new TagClickedEvent(TagClickedEvent.TAG_CLICKED, item, event));
		}
		
		/**
		 * Returns the tag UIComponent at the given index.
		 */
		protected function getTagAt(index:int):UIComponent {
			if ((index >= 0) && (index < numChildren)) {
				return (getChildAt(index) as UIComponent);
			}
			return null;
		}
		
		/** Returns the data item at the given index, or null. */
		public function getItemAt(index:int):Object {
			if (collection && (index >= 0) && (index < collection.length)) {
				return collection[index];
			}
			return null;
		}
		
		/** Returns the index of the given data item. */
		public function indexOf(dataItem:Object):int {
			var index:int = -1;
			if (collection && dataItem) {
				for (var i:int = 0; i < collection.length; i++) {
					if (collection[i] == dataItem) {
						index = i;
						break;
					}
				}
			}
			return index;
		}
			
		/**
		 * Scrolls the box to show the item at the given index.
		 */
		public function scrollToIndex(index:int):void {
			if (verticalScrollBar && verticalScrollBar.visible) {
				var tag:UIComponent = getTagAt(index);
				if (tag) {
					var tagY:Number = tag.y;
					verticalScrollPosition = tagY;
				}
			}
		}
		
		/**
		 * Scrolls the box to show the given item.
		 */
		public function scrollToItem(item:Object):void {
			scrollToIndex(indexOf(item));
		}
		
	}
}