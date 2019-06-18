public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
    int CTScore = CS_GetTeamScore(CS_TEAM_CT);
    int TScore = CS_GetTeamScore(CS_TEAM_T);
    int totalScore = CTScore + TScore;
    int maxRounds = GetConVarInt(FindConVar("mp_maxrounds"))

    if (totalScore >= maxRounds) {
        totalScore = totalScore - maxRounds;
        maxRounds = GetConVarInt(FindConVar("mp_overtime_maxrounds"));

        while (totalScore >= maxRounds) {
            totalScore = totalScore - maxRounds;
        }
    }

    int res = RoundToNearest(float(maxRounds / 2)) - totalScore;

    if (res == 1) { // Match is now 1 round before halftime
        canSurrender = false;
    } else if (res == ((RoundToNearest(float(maxRounds / 2)) - maxRounds) + 1)) {
        canSurrender = false;
    } else if (CTScore - 8 >= TScore || TScore - 8 >= CTScore) {
        canSurrender = true;
    }
    // TODO: Check players if game is 5v3 if yes then surrender is available.
    else {
        canSurrender = false;
    }
    
    return Plugin_Continue;
}