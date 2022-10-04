::AcquireCvar <- function(cvar, logfilename=null)
{
	if(logfilename == null) logfilename = UniqueString("cvar_getter");
	cvar_queue.append(cvar);
	// Start logging console messages to a file that's in a cfg directory, putting it here will allow us to execute it later, sneaky!
	// We need a new filename each time because we can't clear the old one, and adding another say command right below it will not work, because of chat spam prevention.
	// Unfortunately this approach will quickly create a lot of files in the directory, and while technically it won't cause issues it's still not cool, especially from perspective of a regular player.
	SendToConsole(format("con_logfile \"cfg/%s.log\"", logfilename));
	EntFireByHandle(Entities.First(), "RunScriptCode", format("::_FinishAcquireCvar(\"%s\", \"%s\")", cvar, logfilename), 0.01, null, null);
}

::_FinishAcquireCvar <- function(cvar, logfilename)
{
	// Anything printed here will be put to the log file that we will want to execute later.
	print("say_team "); // prepend say_team to the file, we will make the hosting player / server say the output of the convar, so we can catch it as an event and prase it. It's important that we don't have newline at the end!!!
	// Sending just the convar name (without assigning it) to the console will make it print out the value of it along with other stuff, we can use it to out advantage and grab the value from it.
	SendToConsole(cvar);
	SendToConsole(@"con_logfile """" "); // stop logging information
	SendToConsole(format("exec %s.log",logfilename)); // execute the log file which will looks similar to this: (say_team "mp_ignore_round_win_conditions" = "1" ( def. "0" ) game replicated - Ignore conditions which would end the current round)
}

function SetupListener()
{
	// listen to player_say event. Using metamethods here to speed up the process of acquiring the event_data, will be the same tick the event occured as opposed to one tick later if we used outputs.
	// not all that important we do that but the faster we have the info the better.
	cvar_listener.__KeyValueFromString("classname", "info_target");
	cvar_listener.ValidateScriptScope();
	local cvar_listener_sc = cvar_listener.GetScriptScope();
	delegate {
		_newslot = function(k,v)
		{
			try {
			if(k=="event_data")
			{
				local current_cvar = cvar_queue.remove(0);
				local event = v;
				// one quote is ommited so let's add it back so that we can use regex properly.
				local text_fixed = "\""+event.text;
				// capture stuff between quotes into groups
				local exp = regexp(@" ""([^""]*)"" "); 
				local group = exp.capture(text_fixed);
				if(text_fixed.find(current_cvar)!=null && group.len() > 1)
				{
					// the second capture group will be the value.
					::known_cvars[current_cvar] <- text_fixed.slice(group[1].begin, group[1].end);
				}

			}
			else rawset(k,v);

			} catch(x) print("\n\nplayer_say event error: "+x);
		}
	} : cvar_listener_sc

	// listen to server_cvar event, this will only allow us to get some cvars that have been updated, and that are replicated to clients. The more the better.
	cvar_update_listener.__KeyValueFromString("classname", "info_target");
	cvar_update_listener.ValidateScriptScope();
	local cvar_update_listener_sc = cvar_update_listener.GetScriptScope();
	delegate {
		_newslot = function(k,v)
		{
			if(k=="event_data")
			{
				try
				{
					local event = v;
					::known_cvars[event.cvarname] <- event.cvarvalue;
				} catch(x) printl("\n\nserver_cvar event error: "+x);
			}
			else rawset(k,v)
		}
	} : cvar_update_listener_sc
}

::cvar_queue <- []
::known_cvars <- {}

// Returns the convar, if not acquire it. During its acquisition it will not be returned! The user needs to do it manually after a slight delay.
::GetConVar <- function(cvar)
{
	if (cvar in known_cvars)
	{
		return known_cvars[cvar];
	}
	else
	{
		AcquireCvar(cvar);
		printl("Acquiring cvar: "+cvar);
	}
}

function OnPostSpawn()
{
	::cvar_listener <- Entities.FindByName(null, "cvar_listener");
	::cvar_update_listener <- Entities.FindByName(null, "cvar_update_listener");
	SetupListener();
}

function Test(){
	local cvar = ::GetConVar("mp_ignore_round_win_conditions");
	if(cvar!=null) printl(cvar);
}



