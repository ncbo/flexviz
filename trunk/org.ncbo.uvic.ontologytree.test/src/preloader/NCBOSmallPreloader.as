package preloader
{
	// Copied from: http://www.pathf.com/blogs/2008/08/custom-flex-3-lightweight-preloader-with-source-code/
	
    //As seen at: https://defiantmouse.com/yetanotherforum.net/Default.aspx?g=posts&t=82
    //Code for this base provided by Andrew
    //base has been slightly modified to exculude _msecMinimumDuration
    import flash.display.DisplayObject;
    import flash.display.GradientType;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.TimerEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Matrix;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    
    import mx.events.FlexEvent;
    import mx.preloaders.IPreloaderDisplay;

	/**
	 * This custom preloader was originally copied from the examples on this website:
	 * http://www.pathf.com/blogs/2008/08/custom-flex-3-lightweight-preloader-with-source-code/
	 * 
	 * I merged the two classes (PathfinderCustomPreloader.as and PreloaderDisplayBase.as) into this one class
	 * and added more constants for defining the sizes and colors of the preloader.
	 * 
	 * The preloader has a main box which is rendered in a blue gradient background, and it contains
	 * a logo, a progress bar Sprite, a progress bar frame Sprite, and a TextField for showing the "Loading 0%" text.
	 * It also checks the loaderInfo parameters to see if the "simplepreloader" flag equals true.
	 * If so then the preloader is much simplified to use basic colors and no images or text.
	 * 
	 * @author Chris Callendar
	 */
    public class NCBOSmallPreloader extends Sprite implements IPreloaderDisplay
    {
    	
    	[Embed("assets/bioportal_logo.png") ]
        [Bindable] 
        public var LogoClass:Class; 
        private var logo:DisplayObject;
    	
        // Implementation variables, used to make everything work properly
        private var _IsInitComplete:Boolean = false;
        private var _timer:Timer;                 // we have a timer for animation
        private var _bytesLoaded:uint = 0;
        private var _bytesExpected:uint = 1;      // we start at 1 to avoid division by zero errors.
        private var _fractionLoaded:Number = 0;   // 0-1
        private var _preloader:Sprite;

        private var bg:Sprite;
        // this is the border mainBox
        private var mainBox:Sprite;
        // the progress sprite
        private var bar:Sprite = new Sprite();
        // draws the border around the progress bar
        private var barFrame:Sprite;
		// the textfield for rendering the "Loading 0%" string
        private var loadingTextField:TextField;

        // the background color(s) - specify 1 or 2 colors
        private var bgColors:Array = [ 0xffffff, 0xe2ebf0 ];
        // the mainBox background gradient colors - specify 1 or 2 colors
        private var boxColors:Array = [ 0x3f78b8, 0x234979 ];
		// the progress bar color - specify either 1, 2, or 4 colors
        private var barColors:Array = [ 0x95b7e7, 0x6e99d5, 0x1379fb, 0x2d9be8 ];  //0x0687d7;
        // the progress bar border color
        private var barBorderColor:uint = 0xdddddd;
        // the rounded corner radius for the progressbar
        private var barRadius:int = 0;
        // the width of the progressbar
        private var barWidth:int = 100;
        // the height of the progressbar
        private var barHeight:int = 17;
        // the loading text font
        private var textFont:String = "Tahoma"; // "Verdana";
        // the loading text color
        private var textColor:uint = 0xcccccc;
        // the loading text size
        private var textSize:uint = 10;
        
        // Use different colors/sizes when the simplepreloader flag is true
        private var simpleBGColors:Array = [ 0xe0e0e0 ];
        private var simpleBarColors:Array = [ 0x99bbdd ];
        private var simpleBarBorderColor:uint = 0x9999aa;
        private var simpleBarWidth:Number = 80;
        private var simpleBarHeight:Number = 10;
        private var simple:Boolean = false;
        
        private var loading:String = "Loading ";
        
        public function NCBOSmallPreloader() {
            super();
        }
         
        virtual public function initialize():void {
			checkSimpleFlag();
            
            // draw bg here, rather than in draw(), to speed up the drawing
            drawBackground();
              
            //creates all visual elements
            createAssets();

            _timer = new Timer(1);
            _timer.addEventListener(TimerEvent.TIMER, timerHandler);
            _timer.start();            
        }
        
        private function checkSimpleFlag():void {
            // check if the simplepreloader flag is set - if so then use the simple colors/sizes
            if (loaderInfo && loaderInfo.parameters && 
            	(loaderInfo.parameters["simplepreloader"] == "true")) {
            	simple = true;
            }
            if (simple) {
            	bgColors = simpleBGColors;
            	barColors = simpleBarColors;
            	barBorderColor = simpleBarBorderColor;
            	barWidth = simpleBarWidth;
            	barHeight = simpleBarHeight;
            }        	
        }
        
        private function drawBackground():void {
        	bg = new Sprite();
            // Draw background
            if (bgColors.length == 2) {
	            var matrix:Matrix =  new Matrix();
	            matrix.createGradientBox(stageWidth, stageHeight, Math.PI/2);
	            bg.graphics.beginGradientFill(GradientType.LINEAR, bgColors, [1, 1], [0, 255], matrix);
            } else {
	            bg.graphics.beginFill(uint(bgColors[0]));
            }
            bg.graphics.drawRect(0, 0, stageWidth, stageHeight);
            bg.graphics.endFill(); 
            addChild(bg);
        }
             
        private function createAssets():void {
        	if (simple) {
				createSimpleAssets();
        	} else {
        		createAllAssets();
        	}
        }
        
        private function createSimpleAssets():void {
    		//create progress bar
            bar = new Sprite();
            bar.graphics.drawRoundRect(0, 0, barWidth, barHeight, barRadius, barRadius);
           	bar.x = stageWidth/2 - barWidth/2;
        	bar.y = stageHeight/2 - barHeight/2;
            addChild(bar);
            
            //create progressbar frame
            barFrame = new Sprite();
            barFrame.graphics.lineStyle(1, barBorderColor, 1)
            barFrame.graphics.drawRoundRect(0, 0, barWidth, barHeight, barRadius, barRadius);
            barFrame.x = bar.x;
            barFrame.y = bar.y;
            addChild(barFrame);	
        }
        
        private function createAllAssets():void {
			var smallDropShadow:DropShadowFilter = new DropShadowFilter(2, 45, 0x000000,0.8)
		    var largeDropShadow:DropShadowFilter = new DropShadowFilter(6, 45, 0x000000, 0.9)
    		
        	// load the logo first so that we can get its dimensions
        	logo = new LogoClass();
        	var logoWidth:Number = logo.width;
        	var logoHeight:Number = logo.height;

			var hpad:uint = 20;
			var vpad:uint = 15;
			var vgap:int = 8;

        	// make the progress bar the same width as the logo if the logo is large
        	barWidth = Math.max(barWidth, logoWidth);
        	// calculate the box size & add some padding
        	var boxWidth:Number = Math.max(logoWidth, barWidth) + (2 * hpad);
        	var boxHeight:Number = logoHeight + barHeight + (2 * vpad) + vgap;

			// create and position the main box (all other sprites are added to it)
        	mainBox = new Sprite();
        	mainBox.x = stageWidth/2 - boxWidth/2;
        	mainBox.y = stageHeight/2 - boxHeight/2;
        	mainBox.filters = [ largeDropShadow ];
        	if (boxColors.length == 2) {
           		var matrix:Matrix =  new Matrix();
            	matrix.createGradientBox(boxWidth, boxHeight, Math.PI/2);
            	mainBox.graphics.beginGradientFill(GradientType.LINEAR, boxColors, [1, 1], [0, 255], matrix);
         	} else {
         		mainBox.graphics.beginFill(uint(boxColors[0]));
         	}
            mainBox.graphics.drawRoundRectComplex(0, 0, boxWidth, boxHeight, 12, 0, 0, 12);
            mainBox.graphics.endFill(); 
        	addChild(mainBox);
        	
        	// position the logo
        	logo.y = vpad;
        	logo.x = hpad;
        	mainBox.addChild(logo);
        	
            //create progress bar
            bar = new Sprite();
            bar.graphics.drawRoundRect(0, 0, barWidth, barHeight, barRadius, barRadius);
            bar.x = hpad;
            bar.y = logo.y + logoHeight + vgap;
            mainBox.addChild(bar);
            
            //create progressbar frame
            barFrame = new Sprite();
            barFrame.graphics.lineStyle(1, barBorderColor, 1)
            barFrame.graphics.drawRoundRect(0, 0, barWidth, barHeight, barRadius, barRadius);
            barFrame.x = bar.x;
            barFrame.y = bar.y;
            barFrame.filters = [ smallDropShadow ];
            mainBox.addChild(barFrame);
            
            //create text field to show percentage of loading, centered over the progress bar
            loadingTextField = new TextField()
            loadingTextField.width = barWidth;
            // setup the loading text font, color, and center alignment
            var tf:TextFormat = new TextFormat(textFont, textSize, textColor, true, null, null, null, null, "center");
            loadingTextField.defaultTextFormat = tf;
            // set the text AFTER the textformat has been set, otherwise the text sizes are wrong
            loadingTextField.text = loading + " 0%";
            // important - give the textfield a proper height
            loadingTextField.height = loadingTextField.textHeight + 8;
            loadingTextField.x = barFrame.x;
            // center the textfield vertically on the progress bar
            loadingTextField.y = barFrame.y + Math.round((barHeight - loadingTextField.height) / 2) + 1;
            mainBox.addChild(loadingTextField);
        }
         
        // This function is called whenever the state of the preloader changes.  
        // Use the _fractionLoaded variable to draw your progress bar.
        virtual protected function draw():void {
        	if (loadingTextField) {
	        	// update the % loaded string
	  			loadingTextField.text = loading + Math.round(_fractionLoaded * 100).toString() + "%";
	        }
			// draw a complex gradient progress bar
			var matrix:Matrix =  new Matrix();
            matrix.createGradientBox(bar.width, bar.height, Math.PI/2);
            if (barColors.length == 2) {
            	bar.graphics.beginGradientFill(GradientType.LINEAR, barColors, [1, 1], [0, 255], matrix);
            } else if (barColors.length == 4) {
            	bar.graphics.beginGradientFill(GradientType.LINEAR, barColors, [1, 1, 1, 1], [0, 127, 128, 255], matrix);
            } else {
            	bar.graphics.beginFill(uint(barColors[0]), 1);
            }
            bar.graphics.drawRoundRect(0, 0, bar.width * _fractionLoaded, bar.height, barRadius, barRadius);
            bar.graphics.endFill();
		}
    
        /**
         * The Preloader class passes in a reference to itself to the display class
         * so that it can listen for events from the preloader.
         * This code comes from DownloadProgressBar.  I have modified it to remove some unused event handlers.
         */
        virtual public function set preloader(value:Sprite):void {
            _preloader = value;
        
            value.addEventListener(ProgressEvent.PROGRESS, progressHandler);    
            value.addEventListener(Event.COMPLETE, completeHandler);
            value.addEventListener(FlexEvent.INIT_PROGRESS, initProgressHandler);
            value.addEventListener(FlexEvent.INIT_COMPLETE, initCompleteHandler);
        }

        virtual public function set backgroundAlpha(alpha:Number):void{}
        virtual public function get backgroundAlpha():Number { return 1; }
        
        protected var _backgroundColor:uint = 0xffffffff;
        virtual public function set backgroundColor(color:uint):void { _backgroundColor = color; }
        virtual public function get backgroundColor():uint { return _backgroundColor; }
        
        virtual public function set backgroundImage(image:Object):void {}
        virtual public function get backgroundImage():Object { return null; }
        
        virtual public function set backgroundSize(size:String):void {}
        virtual public function get backgroundSize():String { return "auto"; }
        
        protected var _stageHeight:Number = 300;
        virtual public function set stageHeight(height:Number):void { _stageHeight = height; }
        virtual public function get stageHeight():Number { return _stageHeight; }

        protected var _stageWidth:Number = 400;
        virtual public function set stageWidth(width:Number):void { _stageWidth = width; }
        virtual public function get stageWidth():Number { return _stageWidth; }

        //--------------------------------------------------------------------------
        //  Event handlers
        //--------------------------------------------------------------------------
        
        // Called from time to time as the download progresses.
        virtual protected function progressHandler(event:ProgressEvent):void {
            _bytesLoaded = event.bytesLoaded;
            _bytesExpected = event.bytesTotal;
            _fractionLoaded = Number(_bytesLoaded) / Number(_bytesExpected);
             if (isNaN(_fractionLoaded)) {
            	_fractionLoaded = 0;
            }
           
           	draw();
        }
        
        // Called when the download is complete, but initialization might not be done yet.  (I *think*)
        // Note that there are two phases- download, and init
        virtual protected function completeHandler(event:Event):void {
        }
    
        
        // Called from time to time as the initialization continues.        
        virtual protected function initProgressHandler(event:Event):void {
            draw();
        }
    
        // Called when both download and initialization are complete    
        virtual protected function initCompleteHandler(event:Event):void {
            _IsInitComplete = true;
        }

        // Called as often as possible
        virtual protected function timerHandler(event:Event):void {
            if (_IsInitComplete) {    
                // We're done!
                _timer.stop();
                dispatchEvent(new Event(Event.COMPLETE));
            } else {
            	draw();
            }
        }
        
    }
    
}