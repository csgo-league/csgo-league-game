bool DidWePassQuorumRatio(int yesVotes, int noVotes, int quorum) {
    int resultQuorum = yesVotes / (yesVotes + noVotes) *100;

    if (resultQuorum >= quorum) {
        return true;
    } else {
        return false;
    }
}

int RealPlayerCount(int client, bool InGameOnly, bool teamOnly, bool noSpectators) {
    int clientTeam = CS_TEAM_NONE;

    if (client > 0) {
        clientTeam = GetClientTeam(client);
    }

    int players = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (InGameOnly) {
            if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
                if (teamOnly) {
                    if (clientTeam == GetClientTeam(i)) {
                        players++;
                    }
                } else {
                    if (noSpectators) {
                        if (GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T) {
                            players++
                        }
                    } else {
                        players++;
                    }
                }
            }
        } else {
            if (IsClientConnected(i) && !IsFakeClient(i)) {
                if (teamOnly) {
                    if (clientTeam == GetClientTeam(i)) {
                        players++;
                    }
                } else {
                    players++;
                }
            }
        }
    }

    return players;
}

public Action Timer_ResetData(Handle timer) {
    isVoteActive = false;
    for (int i = 0; i < MAXPLAYERS + 1; i++) {
        alreadyVoted[i] = false;
    }

    int entity = FindEntityByClassname(-1, "vote_controller");
    if (entity > -1) {
        for (int i = 0; i < 5; i++) {
            SetEntProp(entity, Prop_Send, "m_nVoteOptionCount", 0, _, i);
        }
        SetEntProp(entity, Prop_Send, "m_nPotentialVotes", 0);
        SetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1);
        SetEntProp(entity, Prop_Send, "m_bIsYesNoVote", true);
    }
}

/*
	Credit: https://github.com/powerlord/sourcemod-tf2-scramble/blob/master/addons/sourcemod/scripting/include/valve.inc#L18
*/


enum Destination
{
	Destination_HintText 		= 1,
	Destination_ClientConsole	= 2,
	Destination_Chat			= 3,
	Destination_CenterText		= 4,
}

stock void PrintValveTranslation(int[] clients,
								 int numClients,
								 Destination msg_dest,
								 const char[] msg_name,
								 const char[] param1="",
								 const char[] param2="",
								 const char[] param3="",
								 const char[] param4="")
{
	Handle msg = StartMessage("TextMsg", clients, numClients, USERMSG_RELIABLE);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		Protobuf proto = UserMessageToProtobuf(msg);
		
		proto.SetInt("msg_dst", view_as<int>(msg_dest));
		proto.AddString("params", msg_name);
		
		proto.AddString("params", param1);
		proto.AddString("params", param2);
		proto.AddString("params", param3);
		proto.AddString("params", param4);
	}
	else
	{
		BfWrite bf = UserMessageToBfWrite(msg);
		
		bf.WriteByte(view_as<int>(msg_dest));
		bf.WriteString(msg_name);
		
		bf.WriteString(param1);
		bf.WriteString(param2);
		bf.WriteString(param3);
		bf.WriteString(param4);
	}
	
	EndMessage();
}

stock void PrintValveTranslationToAll(Destination msg_dest, const char[] msg_name,const char[] param1="",const char[] param2="",const char[] param3="",const char[] param4="")
{
	int total = 0;
	int[] clients = new int[MaxClients];
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			clients[total++] = i;
		}
	}
	PrintValveTranslation(clients, total, msg_dest, msg_name, param1, param2, param3, param4);
}