module quadtree
import scene2d

abstract class AbstractQuadtree[E]
	super Array[E]

	readable var _parent: nullable AbstractQuadtree[E]
	readable var _x: Int
	readable var _y: Int
	readable var _width: Int
	readable var _height: Int
	readable var _level: Int
	readable var _maxLevel: Int
	var nw: nullable AbstractQuadtree[E]
	var ne: nullable AbstractQuadtree[E]
	var sw: nullable AbstractQuadtree[E]
	var se: nullable AbstractQuadtree[E]

	init 
	do 
		_x = 0
		_y = 0
		_width = 0
		_height = 0
		_level = 0
		_maxLevel = 0
	end

	# Insert an item in the right part of the collection
	fun addItem(item: E)
	do
		var quad = getNode(item)
		quad.add(item)
	end
	
	fun updatePosition(item: E)
	do
		remove(item)
		addItem(item)
	end

	redef fun clear
	do
		if level == maxLevel then 
			super
		else
			nw.clear
			ne.clear
			sw.clear
			se.clear
		end	
		if not is_empty then super
	end
	
	# Get the right node where the item must be inserted
	fun getNode(item: E): nullable AbstractQuadtree[E]
	do
		# Get QuadTree where is localised 'sp'
		var quad = findNode(item)
		for i in [0..maxLevel]
		do
			if quad != null then 
				var quad2 = quad.findNode(item)
			 	if quad2 != null then quad = quad2
			end
			if quad.level == maxLevel  or (quad.level == maxLevel-1 and quad == self)  then break
		end
		return quad.as(not null)
	end

	# Need to be redef
	fun findNode(item: E): nullable AbstractQuadtree[E] do return null

	# Retrieve where was inserted an item
	fun retrieve(item: E): List[E]	
	do
		var index = findNode(item).as(not null)
		var list: List[E] = new List[E]
		if index.length > 0 then
			for i in index
			do
				if i != item then list.add(i)
			end
		end
		if index.level < maxLevel then
			if index.nw != null then
				list = index.retrieve(item)
			end
		end
		return list
	end
end

# A QuadTree allow to check more precisely if a LiveObject is in collision with another
class Quadtree[E: Sprite]
	super AbstractQuadtree[E]
	
	init with(x: Int, y: Int, width: Int, height: Int, level: Int, maxLevel: Int, parent: nullable Quadtree[E])
	do
		_x = x
		_y = y
		_width = width
		_height = height
		_level = level
		_maxLevel = maxLevel
		_parent = parent
		# Is it the max depth ?
		if level == maxLevel then return
		nw = new Quadtree[E].with(_x, _y, _width / 2, _height / 2, _level+1, _maxLevel, self)
		ne = new Quadtree[E].with(_x + _width / 2, _y, _width / 2, _height / 2, _level+1, _maxLevel, self)
		sw = new Quadtree[E].with(_x, _y + _height / 2, _width / 2, _height / 2, _level+1, _maxLevel, self)
		se = new Quadtree[E].with(_x + _width / 2, y + _height / 2, _width / 2, _height / 2, _level+1, _maxLevel, self)
	end
	
	redef fun findNode(item: E): nullable Quadtree[E]
	do
		var subWidth = _width / 2
		var subHeight = _height / 2
		var node = nw
		var left = (item.x > _x+subWidth)
		var top = (item.y > _y+subHeight)

		if left then
			if not top then node = sw
		else
			if top then
				node = ne
			else
				node = se
			end
		end
		if node is null then node = self
		return node.as(nullable Quadtree[E])
	end
end
