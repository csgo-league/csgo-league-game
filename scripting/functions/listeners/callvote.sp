public Action Listener_Callvote(int client, const char[] command, int arg) {
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
            PbSetInt(voteStart, "reason", 0);
            PbSetInt(voteStart, "time" -1);
            EndMessage();
        }
        
    }
}