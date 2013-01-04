-- Minetest 0.4 mod: bones
-- See README.txt for licensing and other information. 

local function is_owner(pos, name)
	local owner = minetest.env:get_meta(pos):get_string("owner")
	if owner == "" or owner == name then
		return true
	end
	return false
end

minetest.register_node("bones:bones", {
	description = "Bones",
	tiles = {
		"bones_top.png",
		"bones_bottom.png",
		"bones_side.png",
		"bones_side.png",
		"bones_rear.png",
		"bones_front.png"
	},
	paramtype2 = "facedir",
	groups = {dig_immediate=2},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.45},
	}),
	
	can_dig = function(pos, player)
		local inv = minetest.env:get_meta(pos):get_inventory()
		return is_owner(pos, player:get_player_name()) and inv:is_empty("main")
	end,
	
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if is_owner(pos, player:get_player_name()) then
			return count
		end
		return 0
	end,
	
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,
	
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if is_owner(pos, player:get_player_name()) then
			return stack:get_count()
		end
		return 0
	end,
	
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.env:get_meta(pos)
		if meta:get_string("owner") ~= "" and meta:get_inventory():is_empty("main") then
			meta:set_string("infotext", meta:get_string("owner").."'s old bones")
			meta:set_string("formspec", "")
			meta:set_string("owner", "")
		end
	end,
	
	on_timer = function(pos, elapsed)
		local meta = minetest.env:get_meta(pos)
		local time = meta:get_int("time")+elapsed
		local publish = 1200
		if tonumber(minetest.setting_get("share_bones_time")) then
			publish = tonumber(minetest.setting_get("share_bones_time"))
		end
		if publish == 0 then
			return
		end
		if time >= publish then
			meta:set_string("infotext", meta:get_string("owner").."'s old bones")
			meta:set_string("owner", "")
		else
			return true
		end
	end,
})

minetest.register_on_dieplayer(function(player)
	if minetest.setting_getbool("creative_mode") then
		return
	end
	
	local pos = player:getpos()
	pos.x = math.floor(pos.x+0.5)
	pos.y = math.floor(pos.y+0.5)
	pos.z = math.floor(pos.z+0.5)
	local param2 = minetest.dir_to_facedir(player:get_look_dir())

	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	if not inv:is_empty("main") -- chests
		or not inv:is_empty("fuel") -- furnaces
		or not inv:is_empty("src") -- furnaces
		or not inv:is_empty("dst") -- furnaces
		or meta:get_string("owner") ~= "" -- owned objects, such as locked chests and steel doors
	then
		return
	end

	local replaced = minetest.env:get_node(pos).name
	local add_to_bones = minetest.get_node_drops(replaced, "") -- prevents lost nodes
	minetest.env:dig_node(pos) -- prevents partial doors

	minetest.env:add_node(pos, {name="bones:bones", param2=param2})
	
	local meta = minetest.env:get_meta(pos)
	local inv = meta:get_inventory()
	local player_inv = player:get_inventory()
	inv:set_size("main", 8*4)
	
	local empty_list = inv:get_list("main")
	inv:set_list("main", player_inv:get_list("main"))
	player_inv:set_list("main", empty_list)
	
	inv:set_size("main", 11*4)
	for i=1,player_inv:get_size("craft") do
		inv:add_item("main", player_inv:get_stack("craft", i))
		player_inv:set_stack("craft", i, nil)
	end

	if not minetest.registered_items[replaced].buildable_to then
		for _,item in ipairs(add_to_bones) do
			inv:add_item("main", item)
		end
	end
	
	meta:set_string("formspec", "size[11,9;]"..
			"list[current_name;main;0,0;11,4;]"..
			"list[current_player;main;1.5,5;8,4;]")
	meta:set_string("infotext", player:get_player_name().."'s fresh bones")
	meta:set_string("owner", player:get_player_name())
	meta:set_int("time", 0)
	
	local timer  = minetest.env:get_node_timer(pos)
	timer:start(10)
end)
