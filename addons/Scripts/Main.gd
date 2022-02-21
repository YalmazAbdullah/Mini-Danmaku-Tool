extends Node2D

#_PRELOADS
#
var _Emitter = preload("res://addons/Scenes/Editable_Emitter.tscn")		#emitter
var _Tab = preload("res://addons/Scenes/UI/Tab.tscn")					#tab in editor

#_GLOBALS:
#
var tab_emitter_map = {}				#maps every tab to an emitter
var emitter_count = 0					#count of created emitters
onready var editor = find_node("UI").get_node("Editor")	#easy access to editor ui node
var repositioning_emitter = false		#indicates if repositioning
var rotating_emitter = false			#indicates if adjusting rotate
var emitter_editing:Node2D
var screen_size = OS.get_screen_size()
var tab_count = 0

#_MAIN: 
#
# handles user input
# param: input event
# return: null
func _unhandled_input(event):
	if event.is_action_pressed("mouse_left"):
		var emitter = spawn_Emitter()#create new emitter at location of right click
		var tab = spawn_Editior(emitter)#create tabs in editor for each new emitter spawned
	if event.is_action_released("mouse_right"):
		repositioning_emitter = false
		rotating_emitter = false
	if event.is_action_released("rotate"):
		rotating_emitter = false

# calls adjustment functions when needed
# warning-ignore:unused_argument
# param: delta(time between frames)
# return: null
func _process(delta):
	if repositioning_emitter: reposition_Emitter(delta)
	if rotating_emitter: rotate_Emitter()
	return

#_HELPER FUNCTIONS:
#
#spawns the emitter
#param: null
#return: emitter
func spawn_Emitter():
	var emitter = _Emitter.instance()
	emitter_count+=1
	emitter.init(get_global_mouse_position(),"Default_Emitter_"+str(emitter_count))
	self.add_child(emitter)#emitter enters tree
	emitter_editing = emitter#sets current emitter to be the one that is being edited
	return emitter

#makes editor visable and spawns a tab that is responsible for this emitter, triggers on middle mouse
#param: the emitter this tab is responsible for
#return: tab
func spawn_Editior(emitter):
	var tab
	if(emitter_count<=1):#first emitter create both editor and tab
		editor.set_visible(true)
	tab = _Tab.instance()
	editor.add_child(tab)
	tab.init(str(tab_count),emitter.name)
	tab_emitter_map[tab] = emitter#adds emitter and tab pair to map
	emitter.tab_idx = tab_count#informs emitter that the tab responsible for it is at this index
	editor.current_tab = tab_count#sets editor to the page of the new tab
	tab_count+=1
	return tab

#handles user input for adjusting an emitter directly
#param:emitter that is being adjusted, the input event
#return: null
func adjustment_Input(emitter,event):
	if event.is_action_pressed("mouse_right"):
		repositioning_emitter = true
		emitter_editing = emitter
		editor.current_tab = emitter.tab_idx
		if Input.is_action_pressed("rotate"):
			repositioning_emitter = false
			rotating_emitter = true

#drag and reposition emitter by lerping to mouse positon at rate of 25*delta, triggers on right click
#param:delta(time between frames)
#return: null
func reposition_Emitter(delta):
	#calculates new position
	var new_position = lerp(emitter_editing.position,get_global_mouse_position(),25*delta)
	#clamps values so emitter dosnt go off screen
	new_position.x = clamp(new_position.x,0,screen_size.x)
	new_position.y = clamp(new_position.y,0,screen_size.y)
	#assigns
	emitter_editing.position = new_position
#	if Input.is_action_just_released("mouse_right"):
#		repositioning_emitter = false

#adjust rotation of emitter to look at mouse location, triggers on ctrl+right click
#param:delta(time between frames)
#return: null
func rotate_Emitter():
	emitter_editing.look_at(get_global_mouse_position())
#	if Input.is_action_just_released("rotate"):
#		rotating_emitter = false

#_UPDATE VIEW:
#
#checks to see if the associated emitter of a tab has been changed directly and 
#reflects the changes to tab if it has
#param: tab
#return: null
func update_Tab(tab):
	if(emitter_editing == tab_emitter_map[tab]):
		if(repositioning_emitter):
			tab.set_position_field(tab_emitter_map[tab].position)	
		if(rotating_emitter):
			tab.set_rotation_field(tab_emitter_map[tab].rotation)
	return

#_UPDATE MODEL:
#
#function to update the x cooridnate of emitter
#params: tab that was updated and new value
#return: null
func update_XCoord(tab,x):
	tab_emitter_map[tab].position.x = x

#function to update the y cooridnate of emitter
#params: tab that was updated and new value
#return: null
func update_YCoord(tab,y):
	tab_emitter_map[tab].position.y = y

#function to update the angle of emitter
#params: tab that was updated and new value
#return: null
func update_Angle(tab,deg):
	tab_emitter_map[tab].set_rotation(deg2rad(deg))

#function to update the burst cooldown of emitter
#params: tab that was updated and new value
#return: null
func update_BurstCooldown(tab,value):
	tab_emitter_map[tab].burst_cooldown = value

#function to update the spread status of emitter
#params: tab that was updated and new value
#return: null
func update_SpreadEnabled(tab,button_pressed):
	if(tab_emitter_map[tab].burst_count <=1):
		tab.get_node("Menu/Spread_Input").pressed = false
		tab.get_node("SpreadWarning").popup_centered()
		return
	tab_emitter_map[tab].spread_enabled = button_pressed

#function to update the burst count of emitter
#params: tab that was updated and new value
#return: null
func update_BurstCount(tab,value):
	if(tab_emitter_map[tab].spread_enabled==true and value<=1):
		tab.set_BurstCooldown(tab_emitter_map[tab].burst_count)
		tab.get_node("SpreadWarning").popup_centered()
		return
	tab_emitter_map[tab].burst_count = value

#function to update the burst cone angle of emitter
#params: tab that was updated and new value
#return: null
func update_ConeAngle(tab,value):
	tab_emitter_map[tab].cone_angle = deg2rad(value)

#function to update the spread width value of emitter
#params: tab that was updated and new value
#return: null
func update_SpreadWidth(tab,value):
	tab_emitter_map[tab].spread_width = value

#function to update the rotation rate of emitter
#params: tab that was updated and new value
#return: null
func update_RotationRate(tab,value):
	tab_emitter_map[tab].rotation_rate = value

#function to update the aim status of emitter
#params: tab that was updated and new value
#return: null
func update_AimEnabled(tab,button_pressed):
	tab_emitter_map[tab].aim_enabled = button_pressed

#function to update the aim cooldon value of emitter
#params: tab that was updated and new value
#return: null
func update_AimCooldown(tab,value):
	tab_emitter_map[tab].aim_pause = value

#function to update the x offset value of emitter
#params: tab that was updated and new value
#return: null
func update_AimOff(tab,value):
	tab_emitter_map[tab].aim_offset = deg2rad(value)

#function to update the x offset value of emitter
#params: tab that was updated and new value
#return: null
func update_ArrayCount(tab,value):
	tab_emitter_map[tab].array_count = value

#function to update the x offset value of emitter
#params: tab that was updated and new value
#return: null
func update_ArrayAngle(tab,value):
	tab_emitter_map[tab].array_angle = deg2rad(value)

#function to update the load path of emitter
#params: tab that was updated and new value
#return: null
func load_Selected(tab,path):
	var emitter = tab_emitter_map[tab]
	emitter.load_Emitter(path)
	tab.set_name_field(emitter.name)
	tab.set_position_field(emitter.position)
	tab.set_rotation_field(emitter.rotation)
	tab.set_BurstCooldown(emitter.burst_cooldown)
	tab.set_SpreadEnabled(emitter.spread_enabled)
	tab.set_BurstCount(emitter.burst_count)
	tab.set_ConeAngle(emitter.cone_angle)
	tab.set_SpreadWidth(emitter.spread_width)
	tab.set_RotationRate(emitter.rotation_rate)
	tab.set_AimEnabled(emitter.aim_enabled)
	tab.set_AimCooldown(emitter.aim_pause)
	tab.set_AimOffset(emitter.aim_offset)
	tab.set_ArrayCount(emitter.array_count)
	tab.set_ArrayAngle(emitter.array_angle)

#function to update the save path of emitter
#params: tab that was updated and new value
#return: null
func update_savePathSelected(tab,path):
	print (path)
	tab_emitter_map[tab].save(path)

#function to delete the current node
#params: tab that was updated
#return: null
func delete_Emitter(tab):
	print("hi")
	tab_emitter_map[tab].queue_free()
	tab.queue_free()
