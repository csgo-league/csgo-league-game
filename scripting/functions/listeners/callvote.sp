public Action Listener_Callvote(int client, const char[] command, int arg) {
    	
        /*
	0 = Vote Failed.
	1 = You cannot call a new vote while other players are still loading.
	2 = You called a vote recently and can not call another for %d seconds.
	3 = Vote Failed.
	4 = Vote Failed.
	5 = Server has disabled that issue.
	6 = That map does not exist.
	7 = You must specify a map name.
	8 = This vote recently failed. It can't be called again for &d secs.
	9 = Voting to kick this player failed recently. It can't be called for %d secs.
	10 = Voting to this map failed recently. It can't be called again for %d secs.
	11 = Voting to swap teams failed recently. It can't be called again for &d secs.
	12 = Voting to scramble failed recently. It can't be called again for %d secs.
	13 = Voting to restart failed recently. It can't be called again for %d secs.
	14 = Your team cannot call this vote.
	15 = Voting not allowed during warmup.
	16 = Vote failed.
	17 = You may not vote to kick the server admin.
	18 = A Team Scramble is in progress.
	19 = A Team Swap is in progress.
	20 = This server has disabled voting for Spectators.
	21 = This server has disabled voting.
	22 = The next level has already been set.
	23 = Vote Failed.
	24 = You cannot surrender until a teammate abandons the match.
	25 = Vote Failed.
	26 = The match is already paused!
	27 = The match is not paused!
	28 = The match is not in warmup!
	29 = This vote requires 10 players.
	30 = A timeout is already in progress.
	31 = Vote Failed.
	32 = Your team has no timeouts left.
	33 = Vote can't succeed after round has ended. Call vote again.
	*/

    if (arg < 1 || IsFakeClient(client)) {
        return Plugin_Continue;
    }

    int onlyUs[1];
    onlyUs[0] = client;

    if (isVoteActive) {
        int entity = FindEntityByClassname(-1, "vote_controller");

        if (entity < 0) {
            return Plugin_Stop;
        }

        if (GetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1) == GetClientTeam(client)) {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 0); // 0 = Vote Failed.
            PbSetInt(voteStart, "time", -1);
            EndMessage();
        } else {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 0); // 0 = Vote Failed.
            PbSetInt(voteStart, "time", -1);
            EndMessage();
        }

        return Plugin_Handled;
    }

    bool issueFound = false;

    char option[512];
    GetCmdArg(1, option, sizeof(option));

    if (strcmp(option, "Surrender", false) == 0 && (GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T)) {
        if (GameRules_GetProp("m_bWarmupPeriod") == 1) {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 15); // 15 = Voting not allowed during warmup.
            PbSetInt(voteStart, "time", -1);
            EndMessage();
            return Plugin_Handled;
        } else if (canSurrender == false) {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 5); // 5 = Server has disabled that issue.
            PbSetInt(voteStart, "time", -1);
            EndMessage();
            return Plugin_Handled;
        }

        voteType = 0;
        displayString = "#SFUI_vote_surrender";
        detailsString = "";
        otherTeamString = "#SFUI_otherteam_vote_unimplemented";
        passString = "#SFUI_vote_passed_surrender";
        passDetailsString = "";
        isTeamOnly = true;
        soloOnly = false;
        issueFound = true;
    } else if (strcmp(option, "StartTimeout", false) == 0 && (GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T)) {
        if (GameRules_GetProp("m_bTerroristTimeOutActive") == 1 || GameRules_GetProp("m_bCTTimeOutActive") == 1) {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 30); // 30 = A timeout is already in progress.
            PbSetInt(voteStart, "time", -1);
            EndMessage();
            return Plugin_Handled;
        } else if (GameRules_GetProp("m_bMatchWaitingForResume") == 1) {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 26); // 26 = The match is already paused!
            PbSetInt(voteStart, "time", -1);
            EndMessage();
            return Plugin_Handled;
        }

        int tTimeoutsLeft = GameRules_GetProp("m_nTerroristTimeOuts", 1);
        int ctTimeoutsLeft = GameRules_GetProp("m_nCTTimeOuts", 1);

        if ((GetClientTeam(client) == CS_TEAM_CT && ctTimeoutsLeft <= 0 || (GetClientTeam(client) == CS_TEAM_T && tTimeoutsLeft <= 0))) {
            Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
            PbSetInt(voteStart, "reason", 32); // 32 = Your team has no timeouts left.
            PbSetInt(voteStart, "time", -1);
            EndMessage();
            return Plugin_Handled;
        }
    }

    if (issueFound) {
        CreateTimer(0.0, Timer_StartVote, GetClientUserId(client));
        voteTimeout = CreateTimer(GetConVarFloat(FindConVar("sv_vote_timer_duration")), Timer_VoteTimeout, GetClientUserId(client));
    } else {
        Handle voteStart = StartMessage("CallVoteFailed", onlyUs, 1, USERMSG_RELIABLE);
        PbSetInt(voteStart, "reason", 14); // 14 = Your team cannot call this vote.
        PbSetInt(voteStart, "time", -1);
        EndMessage();
    }

    return Plugin_Handled;
}

public Action Timer_StartVote(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);
    if (client <= 0 && client > MaxClients) {
        return;
    }

    int entity = FindEntityByClassname(-1, "vote_controller");

    if (entity < 0) {
        return;
    }

    SetEntProp(entity, Prop_Send, "m_iActiveIssueIndex", voteType);

    if (soloOnly) {
        SetEntProp(entity, Prop_Send, "m_nPotentialVotes", 1);
    } else if (isTeamOnly) {
        SetEntProp(entity, Prop_Send, "m_nPotentialVotes", RealPlayerCount(client, true, true, false));
    } else {
        SetEntProp(entity, Prop_Send, "m_nPotentialVotes", RealPlayerCount(client, true, false, true));
    }

    if (isTeamOnly || soloOnly) {
        SetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", GetClientTeam(client));
    } else {
        SetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1);
    }

    SetEntProp(entity, Prop_Send, "m_bIsYesNoVote", true);

    for (int i = 0; i < 5; i++) {
        SetEntProp(entity, Prop_Send, "m_nVoteOptionCount", 0, _, i);
    }

    CreateTimer(0.0, Timer_voteStart, GetClientUserId(client));
}

public Action Timer_voteStart(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);

    if (client <= 0 && client > MaxClients) {
        return;
    }

    teamVoteID = GetClientTeam(client);

    Handle voteStart;

    if (isTeamOnly) {
        int[] sendto = new int[MaxClients];
        int index = 0;
        for (int i = 1; i < MaxClients; i++) {
            if (IsClientInGame(i) && teamVoteID == GetClientTeam(i)) {
                sendto[index] = i;
                index++;
            }
        }
        voteStart = StartMessage("VoteStart", sendto, index, USERMSG_RELIABLE);
    } else if (soloOnly) {
        int onlyUs[1];
        onlyUs[0] = client;

        voteStart = StartMessage("VoteStart", onlyUs, 1, USERMSG_RELIABLE);
    } else {
        voteStart = StartMessageAll("VoteStart", USERMSG_RELIABLE);
    }

    if (isTeamOnly || soloOnly) {
        PbSetInt(voteStart, "team", GetClientTeam(client)) // -1 = All, 0 = Unassigned, 1 = Spectators, 2 = Terrorists, 3 = Counter-Terrorists
    } else {
        PbSetInt(voteStart, "team", -1);
    }

    PbSetInt(voteStart, "ent_idx", client); // Vote caller
    PbSetString(voteStart, "disp_str", displayString); // String to display.
    PbSetString(voteStart, "details_str", detailsString); // Details to display.
    PbSetBool(voteStart, "is_yes_no_vote", true); // CSGO only supports Yes/No
    PbSetString(voteStart, "other_team_str", otherTeamString) // What to display if we call the vote while being on the wrong team.
    PbSetInt(voteStart, "vote_type", voteType);
    EndMessage();

    CreateTimer(0.0, Timer_VoteCast, GetClientUserId(client));
    voteCaller = GetClientUserId(client);
    return;
}

public Action Timer_VoteCast(Handle timer, int userid) {
    int client = GetClientOfUserId(userid);
    if (client <= 0 && client > MaxClients) {
        return Plugin_Continue;
    }

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) == true && GetClientTeam(i) == CS_TEAM_SPECTATOR) {
            alreadyVoted[i] = true;
        }
    }
    
    voteYes(client);
    isVoteActive = true;
    alreadyVoted[client] = true;

    return Plugin_Handled;
}