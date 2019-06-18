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
stock PrintValveTranslation(int[] clients, int numClients, int msg_dest, const char[] msg_name, const char[] param1, const char[] param2, const char[] param3, const char[] param4)
{
	new Handle:bf = StartMessage("TextMsg", clients, numClients, USERMSG_RELIABLE);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(bf, "msg_dst", msg_dest);
		PbAddString(bf, "params", msg_name);
		
		PbAddString(bf, "params", param1);
		PbAddString(bf, "params", param2);
		PbAddString(bf, "params", param3);
		PbAddString(bf, "params", param4);
	}
	else
	{
		BfWriteByte(bf, msg_dest);
		BfWriteString(bf, msg_name);
		
		BfWriteString(bf, param1);
		BfWriteString(bf, param2);
		BfWriteString(bf, param3);
		BfWriteString(bf, param4);
	}
	
	EndMessage();
}

stock PrintValveTranslationToAll(int msg_dest, const char[] msg_name, const char[] param1, const char[] param2, const char[] param3, const char[] param4)
{
	int total = 0;
	int clients[MaxClients];
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			clients[total++] = i;
		}
	}
	PrintValveTranslation(clients, total, msg_dest, msg_name, param1, param2, param3, param4);
}
