extends RefCounted
# Merge only static siblings, never across an animated joint or visibility boundary.
static func merge(node:Node)->void:
 var groups:Dictionary={}
 for child in node.get_children():
  if child is MeshInstance3D and child.visible and child.get_child_count()==0 and child.mesh!=null:
   var mat:Material=child.material_override
   if mat==null:continue
   if not groups.has(mat):groups[mat]=[]
   groups[mat].append(child)
  elif not child is MeshInstance3D:merge(child)
 for mat in groups:
  var parts:Array=groups[mat]
  if parts.size()<2:continue
  var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  for part in parts:
   for i in range(part.mesh.get_surface_count()):surface.append_from(part.mesh,i,part.transform)
  var combined:=MeshInstance3D.new();combined.mesh=surface.commit();combined.material_override=mat;combined.layers=parts[0].layers
  node.add_child(combined)
  for part in parts:node.remove_child(part);part.free()
