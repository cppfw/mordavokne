namespace mordavokne{

const decltype(application::windowPimpl)& getWindowPimpl(application& app){
	return app.windowPimpl;
}

void render(application& app){
	app.render();
}

void updateWindowRect(application& app, const morda::rectangle& rect){
	app.updateWindowRect(rect);
}

void handleMouseMove(application& app, const r4::vector2<float>& pos, unsigned id){
	app.handleMouseMove(pos, id);
}

void handleMouseButton(application& app, bool isDown, const r4::vector2<float>& pos, morda::mouse_button button, unsigned id){
	app.handleMouseButton(isDown, pos, button, id);
}

void handleMouseHover(application& app, bool isHovered, unsigned pointerID){
	app.handleMouseHover(isHovered, pointerID);
}

void handleCharacterInput(application& app, const morda::gui::unicode_provider& unicode_resolver, morda::key key_code){
	app.handleCharacterInput(unicode_resolver, key_code);
}

void handleKeyEvent(application& app, bool isDown, morda::key keyCode){
	app.handleKeyEvent(isDown, keyCode);
}

}
