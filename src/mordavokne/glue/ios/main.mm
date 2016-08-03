#include "../../App.hpp"
#include "../../AppFactory.hpp"

#include <papki/FSFile.hpp>
#include <papki/RootDirFile.hpp>

#include <sstream>

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


using namespace mordavokne;

namespace mordavokne{
	
	void ios_render(){
		App::inst().render();
	}
	
	std::uint32_t ios_update(){
		return App::inst().gui.update();
	}
	
	void ios_updateWindowRect(morda::Vec2r dim){
		App::inst().updateWindowRect(
											morda::Rectr(
														 morda::Vec2r(0),
														 dim
														 )
											);
	}
	
	void ios_handleMouseMove(const morda::Vec2r& pos, unsigned id){
		App::inst().handleMouseMove(
										   morda::Vec2r(pos.x, pos.y),
										   id
										   );
	}
	
	void ios_handleMouseButton(bool isDown, const morda::Vec2r& pos, morda::MouseButton_e button, unsigned id){
//		TRACE(<< "mouse pos = " << morda::Vec2r(pos.x, pos.y) << std::endl)
		App::inst().handleMouseButton(
											 isDown,
											 morda::Vec2r(pos.x, pos.y),
											 button,
											 id
											 );
	}
	
	const App::WindowParams& ios_getWindowParams(){
		return App::inst().windowParams;
	}
}


@interface AppDelegate : UIResponder <UIApplicationDelegate>{
	App* app;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self->app = createAppUnix(0, nullptr, utki::Buf<std::uint8_t>()).release();
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	ASSERT(self->app)
	delete self->app;
}

@end



int main(int argc, char * argv[]){
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	[pool release];
	return retVal;
}



void App::postToUiThread_ts(std::function<void()>&& f){
	auto p = reinterpret_cast<NSInteger>(new std::function<void()>(std::move(f)));
	
	dispatch_async(dispatch_get_main_queue(), ^{
		std::unique_ptr<std::function<void()>> m(reinterpret_cast<std::function<void()>*>(p));
		(*m)();
	});
}



void App::setFullscreen(bool enable){
	UIWindow* w = (UIWindow*)this->windowObject.id;
	
	float scale = [[UIScreen mainScreen] scale];
	
	if(enable){
		if( [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f ) {
			CGRect rect = w.frame;
			w.rootViewController.view.frame = rect;
		}
		ios_updateWindowRect(morda::Vec2r(
												 std::round(w.frame.size.width * scale),
												 std::round(w.frame.size.height * scale)
			));
		w.windowLevel = UIWindowLevelStatusBar;
	}else{
		CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
		
		if( [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0f ) {
				CGRect rect = w.frame;
				rect.origin.y += statusBarSize.height;
				rect.size.height -= statusBarSize.height;
				w.rootViewController.view.frame = rect;
		}
		
		ios_updateWindowRect(morda::Vec2r(
												 std::round(w.frame.size.width * scale),
												 std::round((w.frame.size.height - statusBarSize.height) * scale)
			));
		w.windowLevel = UIWindowLevelNormal;
	}
}


void App::quit()noexcept{
	//TODO:
}


namespace{

morda::real getDotsPerInch(){
	float scale = [[UIScreen mainScreen] scale];

	morda::real value;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		value = 132 * scale;
	} else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
		value = 163 * scale;
	} else {
		value = 160 * scale;
	}
	TRACE(<< "dpi = " << value << std::endl)
	return value;
}

morda::real getDotsPerPt(){
	float scale = [[UIScreen mainScreen] scale];

	//TODO: use findDotsPerPt() function from morda util
	
	return morda::real(scale);
}

}//~namespace

App::App(const App::WindowParams& wp) :
		windowParams(wp),
		windowObject(wp),
		gui(getDotsPerInch(), getDotsPerPt())
{
	this->setFullscreen(false);//this will intialize the viewport
}



@interface ViewController : GLKViewController{
	
}

@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ViewController

- (void)viewDidLoad{
	[super viewDidLoad];
	
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
	if (self.context == nil) {
		self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	}
	
	if (!self.context) {
		NSLog(@"Failed to create ES context");
	}
	
	GLKView *view = (GLKView *)self.view;
	view.context = self.context;
	view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;

	{
		const App::WindowParams& wp = ios_getWindowParams();
		if(wp.buffers.get(App::WindowParams::Buffer_e::DEPTH)){
			view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
		}else{
			view.drawableDepthFormat = GLKViewDrawableDepthFormatNone;
		}
		if(wp.buffers.get(App::WindowParams::Buffer_e::STENCIL)){
			view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
		}else{
			view.drawableStencilFormat = GLKViewDrawableStencilFormatNone;
		}
	}
	
	[EAGLContext setCurrentContext:self.context];
	
	view.multipleTouchEnabled = YES;
	
	if([self respondsToSelector:@selector(edgesForExtendedLayout)]){
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
}

- (void)dealloc{
	[super dealloc];
	
	if ([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
	[self.context release];
}

- (void)didReceiveMemoryWarning{
	// Dispose of any resources that can be recreated.
}


- (void)update{
	//TODO: adapt to nothing to update, lower frame rate
	ios_update();
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
	ios_render();
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
	float scale = [UIScreen mainScreen].scale;
	
	for(UITouch * touch in touches ){
		CGPoint p = [touch locationInView:self.view ];
		
//		TRACE(<< "touch began = " << morda::Vec2r(p.x * scale, p.y * scale).rounded() << std::endl)
		ios_handleMouseButton(
				true,
				morda::Vec2r(p.x * scale, p.y * scale).rounded(),
				morda::MouseButton_e::LEFT,
				0//TODO: id
			);
	}
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	float scale = [UIScreen mainScreen].scale;
	
	for(UITouch * touch in touches ){
		CGPoint p = [touch locationInView:self.view ];
		
//		TRACE(<< "touch moved = " << morda::Vec2r(p.x * scale, p.y * scale).rounded() << std::endl)
		ios_handleMouseMove(
									 morda::Vec2r(p.x * scale, p.y * scale).rounded(),
									 0 //TODO: id
			);
	}
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	float scale = [UIScreen mainScreen].scale;
	
	for(UITouch * touch in touches ){
		CGPoint p = [touch locationInView:self.view ];
		
//		TRACE(<< "touch ended = " << morda::Vec2r(p.x * scale, p.y * scale).rounded() << std::endl)
		ios_handleMouseButton(
									 false,
									 morda::Vec2r(p.x * scale, p.y * scale).rounded(),
									 morda::MouseButton_e::LEFT,
									 0//TODO: id
			);
	}
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
	//TODO:
}

@end












App::WindowObject::WindowObject(const App::WindowParams& wp){
	UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	if(!window){
		throw morda::Exc("failed to create a UIWindow");
	}
	
	this->id = window;
	
	window.screen = [UIScreen mainScreen];
	
	window.backgroundColor = [UIColor redColor];
	window.rootViewController = [[ViewController alloc] init];
	
	[window makeKeyAndVisible];
}

App::WindowObject::~WindowObject()noexcept{
	UIWindow* window = (UIWindow*)this->id;
	[window release];
}


void App::showVirtualKeyboard()noexcept{
	//TODO:
}

void App::hideVirtualKeyboard()noexcept{
	//TODO:
}


std::unique_ptr<papki::File> App::createResourceFileInterface(const std::string& path)const{
	std::string dir([[[NSBundle mainBundle] resourcePath] fileSystemRepresentation]);
	
//	TRACE(<< "res path = " << dir << std::endl)

	auto rdf = utki::makeUnique<papki::RootDirFile>(utki::makeUnique<papki::FSFile>(), dir + "/");
	rdf->setPath(path);
	
	return std::move(rdf);
}

void App::setMouseCursorVisible(bool visible){
	//do nothing
}
