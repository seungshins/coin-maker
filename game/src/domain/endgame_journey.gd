extends RefCounted
# Continuous volcanic ridge: each sector shares its boundary with the next.
static func build(source:Dictionary,tier:int,variant:int)->Dictionary:
	var stage:Dictionary=source.duplicate(true)
	var count:int=7 if tier>=12 else (5 if tier>=6 else 3)
	stage.layout_revision=int(source.get("layout_revision",0))+1300+tier
	var theme:int=variant%6
	stage["journey_theme"]=theme
	stage.name=str(source.name)+" · "+["화산 능선","굽이진 계곡","초승달 해안","십자 신전","트로이 성곽","해상 잔해"][theme]+" T%d"%tier
	stage["journey"]=true
	stage["miniboss_zones"]=[1,3,5] if tier>=12 else ([2] if tier>=6 else [])
	stage.centers=[];stage.polygons=[];stage.roads=[];stage.connections=[];stage.counts=[];stage.zones=[];stage.rocks=[]
	stage.road_width=220
	stage["volcano_center"]=[3000,3000]
	var total:float=TAU*(.76+(variant%3)*.06)
	var rotation:float=variant*.65
	stage["curve_total"]=total;stage["curve_rotation"]=rotation
	for zone in range(count):
		var polygon:Array=[]
		for side in [1,-1]:
			for step in range(13):
				var t:float=(zone+(step if side==1 else 12-step)/12.0)/count
				var a:float=rotation+total*t
				var radius:float=2350-1450*t+side*(600+45*sin(t*TAU*5))
				polygon.append([3000+cos(a)*radius,3000+sin(a)*radius])
		stage.polygons.append(polygon)
		var mid:float=(zone+.5)/count
		stage.centers.append([3000+cos(rotation+total*mid)*(2350-1450*mid),3000+sin(rotation+total*mid)*(2350-1450*mid)])
		stage.counts.append(20+zone*3)
		stage.zones.append("화구의 지배자" if zone==count-1 else ("수문장 %d"%(zone+1) if zone in stage.miniboss_zones else "화산 능선 %d"%(zone+1)))

	if theme!=0:
		stage.centers=[];stage.polygons=[]
		for zone in range(count-1):
			var t:float=float(zone)/maxi(1,count-2)
			var center:Vector2=route_point(theme,t)
			stage.centers.append([center.x,center.y])
			var polygon:Array=[]
			if theme>=3:
				for offset in [Vector2(-600,-480),Vector2(600,-480),Vector2(600,480),Vector2(-600,480)]:polygon.append([center.x+offset.x,center.y+offset.y])
			else:
				for i in range(24):
					var point:Vector2=center+Vector2.from_angle(i*TAU/24)*(720+45*sin(i*2.3))
					polygon.append([point.x,point.y])
			stage.polygons.append(polygon)
			stage.zones[zone]="항로 %d"%(zone+1) if theme==5 else "전초 구역 %d"%(zone+1)
			if zone>0:
				var road:Array=[]
				for step in range(49):
					var point:Vector2=route_point(theme,(zone-1+step/48.0)/maxi(1,count-2))
					road.append([point.x,point.y])
				stage.roads.append(road);stage.connections.append([zone-1,zone])
		stage.centers.append([10000,3000]);stage.polygons.append([])
	# A separate arena is reachable only through the unlocked portal.
	stage["portal_origin"]=stage.centers[count-2]
	stage.centers[count-1]=[10000,3000]
	stage.polygons[count-1]=[[9400,2400],[10600,2400],[10600,3600],[9400,3600]]
	stage.zones[count-1]="진 보스의 투기장"
	stage.counts[count-1]=0
	return stage

static func route_point(theme:int,t:float)->Vector2:
	if theme==2:return Vector2(3000,3000)+Vector2.from_angle(-PI*.7+PI*1.4*t)*2200
	if theme in [3,4]:
		var path:Array=[Vector2(3000,5200),Vector2(3000,3000),Vector2(1600,3000),Vector2(3000,3000),Vector2(4400,3000),Vector2(3000,3000),Vector2(3000,1600)] if theme==3 else [Vector2(1400,5000),Vector2(1400,3300),Vector2(1400,1400),Vector2(3400,1400),Vector2(4900,1400),Vector2(4900,3400)]
		var phase:float=t*(path.size()-1)
		var index:int=mini(int(phase),path.size()-2)
		return (path[index] as Vector2).lerp(path[index+1],phase-index)
	return Vector2(600+6000*t,3000+(400*sin(t*PI*3) if theme==5 else 1000*sin(t*TAU)))
