public Action Timer_DoStartTimeout(Handle timer, int team)
{
	if (team == CS_TEAM_CT)
	{
		ServerCommand("timeout_ct_start");
	}
	else if (team == CS_TEAM_T)
	{
		ServerCommand("timeout_terrorist_start");
	}
}