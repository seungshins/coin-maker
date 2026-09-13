extends RefCounted
static var cache:Dictionary={}
static func for_text(text:String)->Texture2D:
	var key:=""
	if "비우기" in text or "해제" in text:key="clear"
	elif "가차" in text or "뽑기" in text:key="dice"
	elif "구매" in text:key="buy"
	elif "판매" in text:key="sell"
	if key.is_empty():return null
	if cache.has(key):return cache[key]
	var paths:Dictionary={"clear":'<path d="M5 7h14M9 7V4h6v3M7 7l1 14h8l1-14M10 11v6M14 11v6"/>',"dice":'<rect x="3" y="3" width="18" height="18" rx="3"/><circle cx="7" cy="7" r="1"/><circle cx="17" cy="17" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="7" cy="17" r="1"/><circle cx="17" cy="7" r="1"/>',"buy":'<path d="M3 5h3l3 11h10l2-8H7M11 3v8m-3-3 3 3 3-3"/><circle cx="10" cy="20" r="1"/><circle cx="18" cy="20" r="1"/>',"sell":'<circle cx="12" cy="12" r="9"/><path d="M8 15h7v-4H9V7h7M12 5v14"/>'}
	var svg:String='<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="#e7c78b" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">'+paths[key]+'</g></svg>'
	var image:=Image.new()
	image.load_svg_from_string(svg)
	cache[key]=ImageTexture.create_from_image(image)
	return cache[key]
