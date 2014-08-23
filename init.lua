-- Minetest 0.4 mod: bones
-- See README.txt for licensing and other information. 

bones={}
bones.timeout=1200
if tonumber(minetest.setting_get("share_bones_time")) then
    bones.timeout = tonumber(minetest.setting_get("share_bones_time"))
end


local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
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
		footstep = {name="default_gravel_footstep", gain=0.5},
		dug = {name="default_gravel_footstep", gain=1.0},
	}),
	
	can_dig = function(pos, player)
		local inv = minetest.get_meta(pos):get_inventory()
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
		local meta = minetest.get_meta(pos)
		if meta:get_string("owner") ~= "" and meta:get_inventory():is_empty("main") then
			meta:set_string("infotext", meta:get_string("owner").."'s old bones")
			meta:set_string("formspec", "")
			meta:set_string("owner", "")
		end
	end,
	
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local time = meta:get_int("bonetime_counter")*10 +elapsed
		local timeout = bones.timeout

		if timeout == 0 then
			return
		end
		-- spawn bones expire faster
		if pos.x>-30 and pos.x<30 and pos.y>-30 and pos.y<60 and pos.z>-30 and pos.z<30 then
			timeout=timeout/3
		end
		
		if time >= timeout then
			meta:set_string("infotext", meta:get_string("owner").."'s old bones")
			meta:set_string("owner", "")
		else
            meta:set_int("bonetime_counter", meta:get_int("bonetime_counter") + 1)
			return true
		end
	end,
})

minetest.register_on_dieplayer(function(player)
	if minetest.setting_getbool("creative_mode") then
		return
	end
	
	local pos = player:getpos()
	
	-- no bones at spawn point
	if pos.x>-3 and pos.x<3 and pos.y>-3 and pos.y<6 and pos.z>-3 and pos.z<3 then
		return
	end
	
	pos.x = math.floor(pos.x+0.5)
	pos.y = math.floor(pos.y+0.5)
	pos.z = math.floor(pos.z+0.5)
	local param2 = minetest.dir_to_facedir(player:get_look_dir())
	local player_name = player:get_player_name()
	local player_inv = player:get_inventory()

	
	local nn = minetest.get_node(pos).name
    local nnn = minetest.get_node({x=pos.x,y=pos.y+1,z=pos.z}).name
    local nnnn = minetest.get_node({x=pos.x,y=pos.y+2,z=pos.z}).name
    local spaceforbones=nil
	-- if minetest.registered_nodes[nn].can_dig and
	-- 	not minetest.registered_nodes[nn].can_dig(pos, player) then
	if nn=="air" or nn=="default:water_flowing" or nn=="default:water_source" or nn=="default:lava_source" or nn=="default:lava_flowing" then
        spaceforbones=pos
    elseif nnn=="air" or nnn=="default:water_flowing" or nnn=="default:water_source" or nnn=="default:lava_source" or nnn=="default:lava_flowing" then
        spaceforbones={x=pos.x,y=pos.y+1,z=pos.z}
    elseif nnnn=="air" or nnnn=="default:water_flowing" or nnnn=="default:water_source" or nnnn=="default:lava_source" or nnnn=="default:lava_flowing" then
        spaceforbones={x=pos.x,y=pos.y+2,z=pos.z}
    else
		-- empty lists main and craft
		player_inv:set_list("main", {})
		player_inv:set_list("craft", {})
		return
	end
	
	minetest.dig_node(spaceforbones)
	minetest.add_node(spaceforbones, {name="bones:bones", param2=param2})
	
	local meta = minetest.get_meta(spaceforbones)
	local inv = meta:get_inventory()
	inv:set_size("main", 8*4)
	
	inv:set_list("main", player_inv:get_list("main"))
	
	for i=1,player_inv:get_size("craft") do
        local stack = player_inv:get_stack("craft", i)
        if inv:room_for_item("main", stack) then
            inv:add_item("main", stack)
        end
	end

	player_inv:set_list("main", {})
	player_inv:set_list("craft", {})

	
	meta:set_string("formspec", "size[8,9;]"..
			"list[current_name;main;0,0;8,4;]"..
			"list[current_player;main;0,5;8,4;]")
	meta:set_string("infotext", player_name.."'s fresh bones")
	meta:set_string("owner", player_name)
    meta:set_int("bonetime_counter", 0)
	
	local timer  = minetest.get_node_timer(spaceforbones)
	timer:start(10)
end)
