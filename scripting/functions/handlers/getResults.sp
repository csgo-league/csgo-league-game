public Action Timer_GetResults(Handle timer, int userid) {
    int entity = FindEntityByClassname(-1, "vote_controller");

    if (entity < 0) {
        return Plugin_Stop;
    }

    int activeIssue = GetEntProp(entity, Prop_Send, "m_iActiveIssueIndex", -1);
    int potentialVotes = GetEntProp(entity, Prop_Send, "m_nPotentialVotes", -1);
    int teamOnly = GetEntProp(entity, Prop_Send, "m_iOnlyTeamToVote", -1);
    int option1 = GetEntProp(entity, Prop_Send, "m_nVoteOptionCount", -1, 0);
    int option2 = GetEntProp(entity, Prop_Send, "m_nVoteOptionCount", -1, 1);

    // Surrender Issue
    if (activeIssue == 0)  {
        if ((option1 + option2) >= potentialVotes) {
            if (DidWePassQuorumRatio(option1, option2, 100)) {
                VotePass();
                CreateTimer(0.5, Timer_DoSurrender, teamOnly);
                canSurrender = false;
            } else {
                CreateTimer(0.5, Timer_VoteFail, 3);
            }
        }
    } else if (activeIssue == 6 && option1 >= 1) {
        VotePass();
        CreateTimer(0.5, Timer_DoStartTimeout, teamOnly);
    }

    return Plugin_Handled;
}