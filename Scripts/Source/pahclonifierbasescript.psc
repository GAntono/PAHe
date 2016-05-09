Scriptname PAHClonifierBaseScript extends ObjectReference  

PAHCloneNodeScript[] Property clone_nodes Auto

Actor[] Property original_actors Auto
Actor[] Property cloned_actors Auto


Function StartCloning(Actor the_actor)
	original_actors = new Actor[10]
	cloned_actors = new Actor[10]
	int i = 0
	while (i < 10)
		clone_nodes[i].node_index = i
		i += 1
	endwhile

	GoToState("initialised")
	start_cloning(the_actor)
EndFunction

State initialised
	Function StartCloning(Actor the_actor)
		start_cloning(the_actor)
	EndFunction
EndState

Actor Function GetClone(Actor original_actor)
	int node_index = get_handling_node(original_actor)
	if node_index != -1
		return cloned_actors[node_index]
	endif
	return None
EndFunction

Actor Function SwitchClone(Actor original_actor)
	int node_index = get_handling_node(original_actor)
	if node_index != -1
		return clone_nodes[node_index].SwitchClone()
	endif
	return None
EndFunction

Function start_cloning(Actor the_actor)
	int node_index
	if get_handling_node(the_actor) == -1
		node_index = get_free_node()
		if node_index == -1
			return
		endif
		original_actors[node_index] = the_actor
		clone_nodes[node_index].Clone(the_actor)
	endif
EndFunction

int Function get_handling_node(Actor original_actor)
	int i = 0
	while (i < original_actors.length)
		if original_actors[i] == original_actor
			return i
		endif
		i += 1
	endwhile
	return -1
EndFunction

int Function get_free_node()
	int i = 0
	while (i < original_actors.length)
		if original_actors[i] == None
			return i
		endif
		i += 1
	endwhile
	return -1
EndFunction
