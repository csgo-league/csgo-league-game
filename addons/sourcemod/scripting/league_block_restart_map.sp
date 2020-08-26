public Plugin myinfo = 
{
	name = "[League] Block restart map",
	author = "Bacardi",
	description = "Block server command 'map xxx reserved' when first human player connect to server",
	version = "1.0",
	url = "https://github.com/ambaca/Bacardi-Dumpster-of-SM-Plugins"
};

public void OnPluginStart()
{
	AddCommandListener(listen, "map");
}

public Action listen(int client, const char[] command, int args)
{
	// console
	if(client == 0)
	{
		// I know, we can do this more simple code than what is ahead.

		char buffer[PLATFORM_MAX_PATH];
		char reserved[] = " reserved";

		int argument_len = GetCmdArgString(buffer, sizeof(buffer));
		int reserved_len = strlen(reserved);
		int offset = argument_len - reserved_len;

		// map mapname reserved
		if(offset > 0 && StrContains(buffer[offset], reserved, true) >= 0)
		{
			bool IsHumanInGame = false;

			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsClientInGame(i) || IsFakeClient(i)) continue;

				IsHumanInGame = true;
			}
			
			if(!IsHumanInGame)
			{
				PrintToServer(" - BLOCK map '%s'", buffer);
				LogAction(-1, -1, " Plugin block command 'map %s'", buffer);

				return Plugin_Handled
			}
		}
	}

	return Plugin_Continue;
}