--@name PaThorV1 CoreV002
--@author Neatro
--@server

Settings = {}
Settings.doPrint = true
Settings.doDrawNodes = true
Settings.doDrawPath = true
Settings.doRunExample = true

function printAllowed(String)
    if Settings.doPrint == true then
        print(String)
    end
end

if SERVER then
    
	Nodes = {} --table of data [I] = {Vec Pos,Table Attached, Num totalCost, Num Checked}
	 --buffer nodes to check
	Phase = 0
    --*************************************************************************************************************
    --instructions:
    
    --node struct = Nodes[ID]={vec Pos, tbl Connected ID's, num Added cost} example: Nodes[1]={Vector(0,0,0),{},0}
    --example of two connected nodes: 
    
    --Nodes[1]={Vector(0,0,0),{2},0}
    --Nodes[2]={Vector(100,0,0),{1},0}
    
    --paThor.validatePath( tbl Nodes ) //update the node table
    --paThor.navi( num Startnode, num Goalnode, cb(Path) ) //let paThor calculate the path
    --paThor.iFuckedUp() //run if paThor gets stuck

    --Please do not claim this script as your own! -Neatro.
    
    --*************************************************************************************************************
    paThor = {}
    
    paThor.validatePath = function(Tbl) --Updates the node table
        if Phase == 0 then
            table.copyFromTo( Tbl, Nodes)
        else
            print("Cannot update nodemap, paThor is still running")
        end
    end
    
    paThor.iFuckedUp = function() --Basically, if pathor is stuck, run this function to unstuck
        Phase = 0
        hook.remove("tick","PaThorRuntime")
    end
    
	
	local function dist4node2node(I, I2) --gets the round length; for cost value
        return math.round((Nodes[I][1]-Nodes[I2][1]):getLength())
    end
	
	paThor.navi = function(vStart, vGoal, Callback) --Generate path table, callback: function(Path)
        
        if Phase == 0 then
            Nodes.Buffer = {}
        	Nodes.Path = {}
        	
        	Start=vStart --start node
        	Goal=vGoal --end node
        	
        	--visualise nodes and connections
        	if Settings.doDrawNodes == true then
        	
            	Nodes.Holos = {}
            	for I = 1, #Nodes do
            	    Nodes.Holos[I] = holograms.create(chip():localToWorld(Nodes[I][1]),Angle(0),"models/holograms/cube.mdl",Vector(1/2,1/2,4))
            	    Nodes.Holos[I]:setColor(Color(0,0,255))
            	    for J = 1, #Nodes[I][2] do
            	        --holograms.create(chip():localToWorld((Nodes[I][1]+Nodes[Nodes[I][2][J]][1])/2),chip():localToWorldAngles((Nodes[I][1]-Nodes[Nodes[I][2][J]][1]):getAngle()),"models/hunter/geometric/tri1x1eq.mdl",Vector((Nodes[Nodes[I][2][J]][1]-Nodes[I][1]):getLength()/82*2,1/12,1/12))
            	        local Arrow = holograms.create(chip():localToWorld((Nodes[I][1])),chip():localToWorldAngles((Nodes[I][1]-Nodes[Nodes[I][2][J]][1]):getAngle()),"models/hunter/geometric/tri1x1eq.mdl",Vector((Nodes[Nodes[I][2][J]][1]-Nodes[I][1]):getLength()/82*2,1/12,1/12))
            	        --Arrow:setColor(Color())
            	        Arrow:setMaterial("holograms/hologram")
                    end
            	end
        	
        	end
        	--actual code
        	setmetatable(Nodes, {__index = function(k, v) --exception catching
        		Nodes[k] = {Vector(0),{1},0,nil} 
        		return {Vector(0),{1},0,nil} 
        	end})
        	
        	
        	Nodes.Buffer[1] = Goal
        	
        	Phase = 1
        	
        	hook.add("tick","PaThorRuntime",function() 
        		if Phase == 1 then --calculate costs on nodes based on position
        			local CheckNode = Nodes.Buffer[1] --Read cheapest/first node
        			local CheckNodeData = Nodes[CheckNode] --Read node data
        			local CheckNodeAtta = CheckNodeData[2] --Read constrained
        			Nodes[CheckNode][4] = 1 --set node to 'checked'
        			table.remove(Nodes.Buffer,1) --remove node from buffer
        			for I = 1, #CheckNodeAtta do
        				if Nodes[CheckNodeAtta[I]][4] then
        					printAllowed("P1 Ignored "..CheckNodeAtta[I])
        				else
        					if CheckNodeAtta[I] == Start then
        						Phase = 2
        						local Dist = dist4node2node(CheckNode, CheckNodeAtta[I])
                                Nodes[CheckNodeAtta[I]][3] = Nodes[CheckNode][3] + Dist
        						table.empty(Nodes.Buffer)
        						table.empty(Nodes.Path)
        						Nodes.Buffer[1] = Start
        						printAllowed("Written: "..json.encode(Nodes))
        						printAllowed("P1 reached end node") --reached end, go to phase 2
        					else
        						table.insert(Nodes.Buffer,CheckNodeAtta[I]) --Add to buffer
        						local Dist = dist4node2node(CheckNode, CheckNodeAtta[I])
                                Nodes[CheckNodeAtta[I]][3] = Nodes[CheckNode][3] + Dist
        						printAllowed("P1 added: "..CheckNodeAtta[I].." Length: "..Dist.." Cost: "..Nodes[CheckNodeAtta[I]][3])
        					end
        				end
        			end
        			
        		end
        		if Phase == 2 then --find path based on cheapest connected value
        		    
        		    local CheckNode = Nodes.Buffer[1]
        		    local CheckNodeData = Nodes[CheckNode]
        		    local CheckNodeAtta = CheckNodeData[2]
        		    local ToSort = {}
        		    
        			table.insert(Nodes.Path,CheckNode)
        			
        		    for I = 1, #CheckNodeAtta do
        		        --ToSort[I] = {Nodes[CheckNodeAtta[I]][3],CheckNodeAtta[I]}
        		        if Nodes[CheckNodeAtta[I]][4] == 1 then
        		            table.insert(ToSort,{Nodes[CheckNodeAtta[I]][3],CheckNodeAtta[I]})
        		        end
        		    end
        		    
        		    --print(json.encode(ToSort))
        		    
        		    --if #
        		    table.sort( ToSort, function( a, b ) --sort buffer based on cost. low to high
        		        return a[1] < b[1]
        	        end )
        	        printAllowed("Sorted: "..json.encode(ToSort))
        	        printAllowed("P2 "..ToSort[1][2])
        	        Nodes.Buffer[1] = ToSort[1][2]
        	        
        	        if ToSort[1][1] == 0 then
        				table.insert(Nodes.Path,ToSort[1][2])
        	            Phase = 3
                    end
                    
        		end
        		if Phase == 3 then --results
        		    printAllowed(json.encode(Nodes.Path))
        		       
        		    if Settings.doDrawPath then
            		    for I = 1, (#Nodes.Path-1) do
                            G = holograms.create(chip():localToWorld((Nodes[Nodes.Path[I]][1]+Nodes[Nodes.Path[I+1]][1])/2)+Vector(0,0,12),chip():localToWorldAngles((Nodes[Nodes.Path[I]][1]-Nodes[Nodes.Path[I+1]][1]):getAngle()),"models/holograms/cube.mdl",Vector((Nodes[Nodes.Path[I]][1]-Nodes[Nodes.Path[I+1]][1]):getLength()/12,2/6,2/6))
                            G:setColor(Color(0,255,0))
                        end
                    end
                    
                    Path = Nodes.Path
                    
                    Callback(Path)
                    
                    Phase = 0
                    hook.remove("tick","PaThorRuntime")
        		end
    	    end)
	    else
	        --Pathor is still running.
	        print("Slow down partner! paThor is trying to find the path!")
	    end
	end
end

if SERVER then --example code
    if Settings.doRunExample then
        Table = {}
        
        Table[1]={Vector(0,0,0),{2},0}
    	Table[2]={Vector(0,200,0),{1,3},0}
    	Table[3]={Vector(200,200,0),{2,4},0}
    	Table[4]={Vector(200,0,0),{3},0}
    	
        paThor.validatePath(Table)   
        paThor.navi(1,4,function(Path) print("Path = "..json.encode(Path)) end)
    end
end
