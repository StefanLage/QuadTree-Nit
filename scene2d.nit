# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# 2D management of game elements
#
# TODO: collision framework (with quad tree?)
module scene2d

# The root class of the living objects (sprites, group of sprites, etc.)
abstract class LiveObject
	# Compute the position, state and appearance.
	fun update do end

	# Controls whether `update' and `draw' are automatically called by `LiveGroup'
	var exists writable = true

	# Redefine this method to asks how to draw on a view
	fun draw(view: View) is abstract
end


# The basic atomic living and moving object.
#
# A sprite has a position and a velocity
class Sprite
	super LiveObject

	# x coordinate of the center point
	var x: Int writable = 0

	# y coordinate of the center point
	var y: Int writable = 0

	# width of the sprite
	var width: Int writable = 100

	# height of the sprite
	var height: Int writable = 100

	fun left: Int do return x - width/2
	fun right: Int do return x + width/2
	fun top: Int do return y - height/2
	fun bottom: Int do return y + height/2

	# x velocity (applied by `update')
	var vx: Int writable = 0

	# y velocity (applied by `update')
	var vy: Int writable = 0

	redef fun update
	do
		self.x += self.vx
		self.y += self.vy
	end

	redef fun draw(view) do view.draw_sprite(self)

	# Is self overlaps (or contains) an other sprite
	# `x', `y', `width', and `height' of both sprites are considered
	fun overlaps(other: Sprite): Bool
	do
		return self.right > other.left and self.left < other.right and self.bottom > other.top and self.top < other.bottom
	end

	# Return the current angle of velocity
	# Often used to rotate the displayed image with the correct angle
	fun velocity_angle: Float
	do
		return atan2(self.vx.to_f, -self.vy.to_f)
	end

	# Return the angle to target an other sprite
	fun angle_to(target: Sprite): Float
	do
		return atan2((target.x-self.x).to_f, (self.y-target.y).to_f)
	end

	# Update of vx and vy toward a given angle and magnitude
	fun set_velocity(angle: Float, maginude: Int)
	do
		var magf = maginude.to_f
		self.vx = (angle.sin * magf).to_i
		self.vy = (angle.cos * -magf).to_i
	end

end

# Organizational class to manage groups of sprites and other live objects.
class LiveGroup[E: LiveObject]
	super LiveObject
	super List[E]

	init
	do
	end

	# Recursively update each live objects that `exists'
	redef fun update
	do
		for x in self do if x.exists then x.update
	end

	# Remove all live Objects that do not exists
	# Call this to cleanup the live group
	fun gc
	do
		var i = self.iterator
		while i.is_ok do
			var e = i.item
			if not e.exists then
				i.delete
			else if e isa LiveGroup[LiveObject] then
				e.gc
			end
			i.next
		end
	end

	# Recursively draw each live objects that `exists'
	redef fun draw(view)
	do
		for x in self do if x.exists then x.draw(view)
	end
end

# A state in the game logic
# A scene manage a bunch of live objects
class Scene
	super LiveObject
end

# 
# A QuadTree allow to check more precisely if a LiveObject is in collision with another
class QuadTree
	readable var _x: Int
	readable var _y: Int
	readable var _width: Int
	readable var _height: Int
	readable var _level: Int
	readable var _maxLevel: Int
	var objects: List[Sprite]
	var nw: nullable QuadTree
	var ne: nullable QuadTree
	var sw: nullable QuadTree
	var se: nullable QuadTree

	var nodeType: String = ""
	var digraph = ""

	init with(x: Int, y: Int, width: Int, height: Int, level: Int, maxLevel: Int, nodeT: String)
	do
		# Check if the scene is respecting the normal size for a quadtree
		if width % 2 > 0 or height % 2 > 0 then 
			print "To implement a QuadTree your scene needs to have each side with a length 2n"
			return
		end

		_x = x
		_y = y
		_width = width
		_height = height
		_level = level
		_maxLevel = maxLevel
		objects = new List[Sprite]
		nodeType = nodeT

		if _level == _maxLevel then return

		nw = new QuadTree.with(_x, _y, _width / 2, _height / 2, _level+1, _maxLevel, "NW")
		ne = new QuadTree.with(_x + _width / 2, _y, _width / 2, _height / 2, _level+1, _maxLevel, "NE")
		sw = new QuadTree.with(_x, _y + _height / 2, _width / 2, _height / 2, _level+1, _maxLevel, "SW")
		se = new QuadTree.with(_x + _width / 2, y + _height / 2, _width / 2, _height / 2, _level+1, _maxLevel, "SE")
	end
	
	# Insert a LiveObject in the right QuadTree based on its coordinates
	fun insert(sp: Sprite)
	do
		var quad = getNode(sp)
		quad.objects.push(sp)
	end
	
	# Remove a sprite in his node
	fun remove(sp: Sprite)
	do 
		var quad = getNode(sp)
		quad.objects.remove(sp)
	end

	# Update the position of a given Sprite
	fun updatePosition(sp: Sprite)
	do
		remove(sp)
		insert(sp)
	end

	# Remove all items in each QuaTrees
	fun clear
	do
		if level == maxLevel then 
			objects.clear
		else
			nw.clear
			ne.clear
			sw.clear
			se.clear
		end	
		if not objects.is_empty then objects.clear
	end
	
	fun getNode(sp: Sprite): QuadTree
	do
		# Get QuadTree where is localised 'sp'
		var quad = findNode(sp)
		for i in [0..maxLevel]
		do
			if quad != null then quad = quad.findNode(sp)
			if quad.level == maxLevel then break
		end
		return quad.as(not null)
	end

	fun findNode(sp: Sprite): nullable QuadTree
	do
		var node = nw

		var left = (sp.x > _x+(_width/2))
		var top = (sp.y > _y+(_height/2))

		if left then
			if not top then node = sw
		else
			if top then
				node = ne
			else
				node = se
			end
		end

		return node
	end
	
	fun retrieve(sp: Sprite): List[Sprite]	
	do
		var index = findNode(sp).as(not null)
		var list: List[Sprite] = new List[Sprite]
		if index.objects.length > 0 then
			for i in index.objects
			do
				if i != sp then list.add(i)
			end
		end
		
		if index.level < maxLevel then
			if index.nw != null then
				list = index.retrieve(sp)
			end
		end
		return list
	end
end


# Abstract view do draw sprites
#
# Concrete views are specific for each back-end.
# View can also be used to implements camera and other fun things.
interface View
	# Draw a specific sprite on the view
	#
	# This method must be implemented for each specific view.
	# A traditional way of implementation is to use a double-dispatch mechanism
	#
	# Exemple:
	#     class MyView
	#         redef fun draw_sprite(s) do s.draw_on_myview(self)
	#     end
	#     redef class Sprite
	#         # How to draw a sprite on my specific view
	#         fun draw_on_myview(myview: MyView) is abstract
	#     end
	fun draw_sprite(s: Sprite) is abstract
end
