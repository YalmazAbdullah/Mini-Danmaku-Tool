extends Node2D

#_PRELOADS:
var bullet_adress:String = "res://addons/Scenes/Provided Bullets/Bullet.tscn"
var _Bullet = preload("res://addons/Scenes/Provided Bullets/Bullet.tscn")

#_EDITABLE PARAMS:
var burst_cooldown = 0.5			#cooldown between shots
var rotation_rate = 0				#rate of eimiter rotaiotn
#_-spread params
var spread_enabled = false		#cone spread enabled
var burst_count = 1					#bulletcount in a single burst
var cone_angle=0					#spread angle between bullets
var spread_width=0					#spread width between bullets
#_-aim params
var aim_enabled = false				#aiming at player
var aim_pause = 0					#calls to player position per second
var aim_offset = 0					#offset from player
#_-array params
var array_count = 1
var array_angle = 0


#_GLOBALS:
onready var controler = get_tree().get_root().get_child(0)	#for easy access to root
onready var player = get_parent().find_node("Player") 		#for easy access to player node
var shot_timer = burst_cooldown								#timer between shots
var aim_timer = 0											#delay between re-aim
var repositioning_emitter = false							#indicates if repositioning
var rotating_emitter = false								#indicates if adjusting rotate

#_MAIN:
#
#main function calls aim or rotate based on enabled profiles
#after targeting calls shoot function
func _process(delta):
	_move()
	_bound_Handler()
	# warning-ignore:standalone_ternary
	aim(delta,player.position) if aim_enabled else rotate(delta)
	shoot(delta)
	return

#_HELPER FUNCTIONS:
#
#moves the emitter, meant to be overriden
#param: none
#return: null
func _move():
	pass

#handle going out of bounds, meant to be overriden
#param: none
#return: null
func _bound_Handler():
	pass

#aims at player
#param:delta(time between frames), player position vector
#return: null
#@TODO: aim offset not functioning correctly
func aim(delta,player_position):
	aim_timer += delta
	if(aim_timer>=aim_pause):
		look_at(player_position)
		self.rotation+=aim_offset
		aim_timer =0
	return

#rotates emitter
#param:delta(time between frames)
#return: null
func rotate(delta):
	self.rotation += rotation_rate*delta
	if(self.rotation_degrees >= 360 or self.rotation_degrees <= -360):
		self.rotation_degrees = 0
	return

#responsible for shooting bullets
#param:delta(time between frames)
#return: null
func shoot(delta):
	shot_timer += delta
	if(shot_timer>=burst_cooldown):#shoot when cooldown complete
		for array in array_count:#shoot burst for each array 
			var current_angle= self.rotation+(array*array_angle)#find angle of current array
			var childBullets = []
			childBullets = instance_Bullet(childBullets,current_angle)#instance bullets of this array
			#adjust their transforms based on params
			childBullets = position_Bullet(childBullets)
			childBullets = rotate_Bullet(childBullets)
			for bullet in childBullets:#enter each bullet to tree
				controler.add_child(bullet)
			shot_timer = 0
	return

#instantites bullet and sets correct transforms
#param:array of bullets that are the child of this emitter
#return: same as above
func instance_Bullet(childBullets,angle):
	for i in burst_count:
		var bullet = _Bullet.instance()
		bullet.position = self.position
		bullet.rotation = angle
		childBullets.append(bullet)
	return childBullets

#transforms position of bullet
#param:array of bullets that are the child of this emitter
#return: same as above
func position_Bullet(childBullets):
	if(spread_enabled):
		var spread = (spread_width/2)*-1
		var spread_increment = spread_width/(burst_count-1)
		var angle = self.rotation+deg2rad(90)
		for bullet in childBullets:
			var new_pos = Vector2(spread*cos(angle),spread*sin(angle))
			bullet.translate(new_pos)
			spread+=spread_increment
	return childBullets

#transforms rotation of bullet trajectory to match direction of emitter
#param:array of bullets that are the child of this emitter
#return: same as above
func rotate_Bullet(childBullets):
	if(spread_enabled):
		var cone_angle_increment = cone_angle/(burst_count-1)
		var curr_angle = (cone_angle/2)*-1
		for bullet in childBullets:
			bullet.rotation += curr_angle
			curr_angle+=cone_angle_increment
	return childBullets

#load the params for emitter
#param:save file name
#return: null
func load_Emitter(file_name):
	var file = File.new()
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		position = file.get_var()
		rotation = file.get_var()
		
		#load the new bullet
		bullet_adress = file.get_var()
		var directory = Directory.new();
		if directory.file_exists(bullet_adress):
			_Bullet = load(bullet_adress)
		
		burst_cooldown = file.get_var()
		rotation_rate = file.get_var()
		spread_enabled = file.get_var()
		burst_count = file.get_var()
		cone_angle = file.get_var()
		spread_width = file.get_var()
		aim_enabled = file.get_var()
		aim_pause = file.get_var()
		aim_offset = file.get_var()
		array_count = file.get_var()
		array_angle = file.get_var()
		file.close()
	return
