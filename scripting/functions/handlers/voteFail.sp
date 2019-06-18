public Action Timer_VoteFail(Handle timer, int reason) {
    int entity = FindEntityByClassname(-1, "vote_controller");

    if (entity < 0) {
        return;
    }

    Handle voteFailed;

    if (soloOnly) {
        int client = GetClientOfUserId(voteCaller);
        if (client <=0 && client > MaxClients) {
            CreateTimer(0.5, Timer_ResetData);
            return;
        }

        int onlyUs[1];
        onlyUs[0] = client;

        voteFailed = StartMessage("VoteFailed", onlyUs, 1, USERMSG_RELIABLE);
    } else if (GetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1) != -1) {
        int[] sendto = new int[MaxClients];
        int index = 0;
        for (int i = 1; i < MaxClients; i++) {
            if (IsClientInGame(i) && teamVoteID == GetClientTeam(i)) {
                sendto[index] = i;
                index++;
            }
        }
        voteFailed = StartMessage("VoteFailed", sendto, index, USERMSG_RELIABLE);
    } else {
        voteFailed = StartMessageAll("VoteFailed", USERMSG_RELIABLE);
    }

    PbSetInt(voteFailed, "team", GetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1));
    PbSetInt(voteFailed, "reason", reason);
    /*
    0 = Vote Failed.
    1 = *Empty*
    2 = *Empty*
    3 = Yes votes must exceed No votes
    4 = Not enough players voted
    */
    EndMessage();

    if (voteTimeout != null) {
        KillTimer(voteTimeout);
        voteTimeout = null;
    }

    CreateTimer(1.0, Timer_ResetData);
}