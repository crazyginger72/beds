local beds_list = {
	{ "Red Bed", "red"},
	{ "Orange Bed", "orange"},	
	{ "Yellow Bed", "yellow"},
	{ "Green Bed", "green"},
	{ "Blue Bed", "blue"},
	{ "Violet Bed", "violet"},
	{ "Black Bed", "black"},
	{ "Grey Bed", "grey"},
	{ "White Bed", "white"},
}

for i in ipairs(beds_list) do
	local beddesc = beds_list[i][1]
	local colour = beds_list[i][2]
	local player_in_bed = 0
	local guy
	local hand
	local old_yaw = 0

	local function get_dir(pos)
		local btop = "beds:bed_top_"..colour
		if minetest.env:get_node({x=pos.x+1,y=pos.y,z=pos.z}).name == btop then
			return 7.9
		elseif minetest.env:get_node({x=pos.x-1,y=pos.y,z=pos.z}).name == btop then
			return 4.75
		elseif minetest.env:get_node({x=pos.x,y=pos.y,z=pos.z+1}).name == btop then
			return 3.15
		elseif minetest.env:get_node({x=pos.x,y=pos.y,z=pos.z-1}).name == btop then
			return 6.28
		end
	end

	function plock(start, max, tick, player, yaw)
		if start+tick < max then
			player:set_look_pitch(-1.2)
			player:set_look_yaw(yaw)
			minetest.after(tick, plock, start+tick, max, tick, player, yaw) 
		else
			player:set_look_pitch(0)
			if old_yaw ~= 0 then minetest.after(0.1+tick, function() player:set_look_yaw(old_yaw) end) end
		end
	end

	function exit(pos)
		local npos = minetest.env:find_node_near(pos, 1, "beds:bed_bottom_"..colour)
		if npos ~= nil then pos = npos end
		if minetest.env:get_node({x=pos.x+1,y=pos.y,z=pos.z}).name == "air" then
			return {x=pos.x+1,y=pos.y,z=pos.z}
		elseif minetest.env:get_node({x=pos.x-1,y=pos.y,z=pos.z}).name == "air" then
			return {x=pos.x-1,y=pos.y,z=pos.z}
		elseif minetest.env:get_node({x=pos.x,y=pos.y,z=pos.z+1}).name == "air" then
			return {x=pos.x,y=pos.y,z=pos.z+1}
		elseif minetest.env:get_node({x=pos.x,y=pos.y,z=pos.z-1}).name == "air" then
			return {x=pos.x,y=pos.y,z=pos.z-1}
		else 
			return {x=pos.x,y=pos.y,z=pos.z}
		end
	end

	beds_player_spawns = {}
	local file = io.open(minetest.get_worldpath().."/beds_player_spawns", "r")
	if file then
		beds_player_spawns = minetest.deserialize(file:read("*all"))
		file:close()
	end

	local timer = 0
	local wait = false
	minetest.register_globalstep(function(dtime)
		if timer<2 then
			timer = timer+dtime
			return
		end
		timer = 0
		
		local players = #minetest.get_connected_players()
		if players == player_in_bed and players ~= 0 then
			if minetest.env:get_timeofday() < 0.2 or minetest.env:get_timeofday() > 0.805 then
				if not wait then
					minetest.after(2, function()
						minetest.env:set_timeofday(0.23)
						wait = false
						guy:set_physics_override(1,1,1)
						guy:setpos(exit(guy:getpos()))
						
					end)
					wait = true
					for _,player in ipairs(minetest.get_connected_players()) do
						beds_player_spawns[player:get_player_name()] = player:getpos()
					end
					local file = io.open(minetest.get_worldpath().."/beds_player_spawns", "w")
					if file then
						file:write(minetest.serialize(beds_player_spawns))
						file:close()
					end
				end
			end
		end
	end)

	minetest.register_on_respawnplayer(function(player)
		local name = player:get_player_name()
		if beds_player_spawns[name] then
			player:setpos(beds_player_spawns[name])
			return true
		end
	end)

	minetest.register_node("beds:bed_bottom_"..colour, {
		description = beddesc,
		drawtype = "nodebox",
		tiles = {"beds_bed_top_bottom_"..colour..".png", "default_wood.png",  "beds_bed_side_"..colour..".png",  "beds_bed_side_"..colour..".png",  "beds_bed_side_"..colour..".png",  "beds_bed_side_"..colour..".png"},
		paramtype = "light",
		paramtype2 = "facedir",
		groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3,bed=1},
		sounds = default.node_sound_wood_defaults(),
		node_box = {
			type = "fixed",
			fixed = {
						-- bed
						{-0.5, -0.125, -0.5, 0.5, 0.3125, 0.5},
						
						-- legs
						{-0.5, -0.5, -0.5, -0.375, 0.0, -0.375},
						{0.375, 0.0, -0.375, 0.5, -0.5, -0.5},
					}
		},
		selection_box = {
			type = "fixed",
			fixed = {
						-- bed
						{-0.5, -0.125, -0.5, 0.5, 0.3125, 1.5},
						
						-- legs
						{-0.5, -0.5, -0.5, -0.375, 0.0, -0.375},
						{0.375, 0.0, -0.375, 0.5, -0.5, -0.5},
						{-0.375, 0.0, 1.375, -0.5, -0.5, 1.5},
						{0.5, -0.5, 1.5, 0.375, 0.0, 1.375},
					}
		},
		after_place_node = function(pos, placer, itemstack)
			local node = minetest.get_node(pos)
			local p = {x=pos.x, y=pos.y, z=pos.z}
			local param2 = node.param2
			node.name = "beds:bed_top_"..colour
			if param2 == 0 then
				pos.z = pos.z+1
			elseif param2 == 1 then
				pos.x = pos.x+1
			elseif param2 == 2 then
				pos.z = pos.z-1
			elseif param2 == 3 then
				pos.x = pos.x-1
			end
			pos2 = {x=pos.x, y=pos.y-1, z=pos.z}
			if minetest.registered_nodes[minetest.get_node(pos).name].buildable_to  then
				minetest.set_node(pos, node)
			else
				minetest.remove_node(p)
				return true
			end
		end,
			
		on_destruct = function(pos)
			local node = minetest.get_node(pos)
			local param2 = node.param2
			if param2 == 0 then
				pos.z = pos.z+1
			elseif param2 == 1 then
				pos.x = pos.x+1
			elseif param2 == 2 then
				pos.z = pos.z-1
			elseif param2 == 3 then
				pos.x = pos.x-1
			end
			if( minetest.get_node({x=pos.x, y=pos.y, z=pos.z}).name == "beds:bed_top_"..colour ) then
				if( minetest.get_node({x=pos.x, y=pos.y, z=pos.z}).param2 == param2 ) then
					minetest.remove_node(pos)
				end	
			end
		end,

	on_rightclick = function(pos, node, clicker, itemstack)
		if not clicker:is_player() then
			return
		end

		if minetest.env:get_timeofday() > 0.2 and minetest.env:get_timeofday() < 0.805 then
			minetest.chat_send_all("You can only sleep at night")
			return
		else			
			clicker:set_physics_override(0,0,0)
			old_yaw = clicker:get_look_yaw()
			guy = clicker
			clicker:set_look_yaw(get_dir(pos))
			minetest.chat_send_all("Good night")
			plock(0,2,0.1,clicker, get_dir(pos))
		end

		if not clicker:get_player_control().sneak then
			local meta = minetest.env:get_meta(pos)
			local param2 = node.param2
			if param2 == 0 then
				pos.z = pos.z+1
			elseif param2 == 1 then
				pos.x = pos.x+1
			elseif param2 == 2 then
				pos.z = pos.z-1
			elseif param2 == 3 then
				pos.x = pos.x-1
			end
			if clicker:get_player_name() == meta:get_string("player") then
				if param2 == 0 then
					pos.x = pos.x-1
				elseif param2 == 1 then
					pos.z = pos.z+1
				elseif param2 == 2 then
					pos.x = pos.x+1
				elseif param2 == 3 then
					pos.z = pos.z-1
				end
				pos.y = pos.y-0.5
				clicker:setpos(pos)
				meta:set_string("player", "")
				player_in_bed = player_in_bed-1
			elseif meta:get_string("player") == "" then
				pos.y = pos.y-0.5
				clicker:setpos(pos)
				meta:set_string("player", clicker:get_player_name())
				player_in_bed = player_in_bed+1
			end
		end
	end

		--[[on_rightclick = function(pos, node, clicker)
		local node = minetest.get_node(pos)
			local param2 = node.param2
			if param2 == 0 then
				pos.z = pos.z+0.5
			elseif param2 == 1 then
				pos.x = pos.x+0.5
			elseif param2 == 2 then
				pos.z = pos.z-.05
			elseif param2 == 3 then
				pos.x = pos.x-0.5
			end
			if not clicker:is_player() then
				return
			end
			pos.y = pos.y-0.5
			clicker:setpos(pos)
			clicker:set_hp(20)
		end]]--
	})
	
	minetest.register_node("beds:bed_top_"..colour, {
		drawtype = "nodebox",
		tiles = {"beds_bed_top_top_"..colour..".png", "default_wood.png",  "beds_bed_side_top_r_"..colour..".png",  "beds_bed_side_top_l_"..colour..".png",  "beds_bed_top_front.png",  "beds_bed_side_"..colour..".png"},
		paramtype = "light",
		paramtype2 = "facedir",
		pointable = false,
		groups = {snappy=1,choppy=2,oddly_breakable_by_hand=2,flammable=3,bed=1},
		sounds = default.node_sound_wood_defaults(),
		node_box = {
			type = "fixed",
			fixed = {
						-- bed
						{-0.5, -0.125, -0.5, 0.5, 0.3125, 0.5},
						{-0.375, 0.3125, 0.1, 0.375, 0.375, 0.5},
						
						-- legs
						{-0.375, 0.0, 0.375, -0.5, -0.5, 0.5},
						{0.5, -0.5, 0.5, 0.375, 0.0, 0.375},
					}
		},
	})

	minetest.register_alias("bed_"..colour, "beds:bed_bottom_"..colour)
	
	minetest.register_craft({
		output = "beds:bed_"..colour,
		recipe = {
			{"wool:"..colour, "wool:"..colour, "wool:white", },
			{"group:stick",   "",              "group:stick", }
		}
	})
end


if minetest.setting_get("log_mods") then
	minetest.log("action", "beds loaded")
end
