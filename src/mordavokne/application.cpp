#include "application.hpp"

#include <utki/debug.hpp>
#include <utki/config.hpp>

#include <papki/FSFile.hpp>
#include <papki/RootDirFile.hpp>


using namespace mordavokne;



application::T_Instance application::instance;




void application::render(){
	//TODO: render only if needed?
	this->gui.renderer().clearFramebuffer();

	this->gui.render(this->gui.renderer().initialMatrix);

	this->swapFrameBuffers();
}



void application::updateWindowRect(const morda::Rectr& rect){
	if(this->curWinRect == rect){
		return;
	}

	this->curWinRect = rect;

	TRACE(<< "application::UpdateWindowRect(): this->curWinRect = " << this->curWinRect << std::endl)
	this->gui.renderer().setViewport(r4::recti(
			int(this->curWinRect.p.x),
			int(this->curWinRect.p.y),
			int(this->curWinRect.d.x),
			int(this->curWinRect.d.y)
		));

	this->gui.setViewportSize(this->curWinRect.d);

}



#if M_OS_NAME != M_OS_NAME_ANDROID && M_OS_NAME != M_OS_NAME_IOS
std::unique_ptr<papki::File> application::get_res_file(const std::string& path)const{
	return utki::makeUnique<papki::FSFile>(path);
}

void application::showVirtualKeyboard()noexcept{
	TRACE(<< "application::ShowVirtualKeyboard(): invoked" << std::endl)
	//do nothing
}



void application::hideVirtualKeyboard()noexcept{
	TRACE(<< "application::HideVirtualKeyboard(): invoked" << std::endl)
	//do nothing
}
#endif



morda::real application::findDotsPerDp(r4::vec2ui resolution, r4::vec2ui screenSizeMm){

	//NOTE: for ordinary desktop displays the PT size should be equal to 1 pixel.
	//For high density displays it should be more than one pixel, depending on display ppi.
	//For hand held devices the size of PT should be determined from physical screen size and pixel resolution.

#if M_OS_NAME == M_OS_NAME_IOS
	return morda::real(1);//TODO:
#else
	unsigned xIndex;
	if(resolution.x > resolution.y){
		xIndex = 0;
	}else{
		xIndex = 1;
	}

	if(screenSizeMm[xIndex] < 300){
		return resolution[xIndex] / morda::real(700);
	}else if(screenSizeMm[xIndex] < 150) {
        return resolution[xIndex] / morda::real(200);
    }

	return morda::real(1);
#endif
}
