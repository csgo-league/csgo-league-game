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
        PrintToChatAll("Match is now 1 round before halftime")
        PrintToChatAll("%i", CTScore);
        PrintToChatAll("%i", TScore);
        canSurrender = false;
    } else if (res == ((RoundToNearest(float(maxRounds / 2)) - maxRounds) + 1)) {
        PrintToChatAll("Match is now 1 round before ending")
        PrintToChatAll("%i", CTScore);
        PrintToChatAll("%i", TScore);
        canSurrender = false;
    } else if (CTScore - 8 >= TScore || TScore - 8 >= CTScore) {
        PrintToChatAll("We are 8 rounds behind. Surrender available.")
        PrintToChatAll("%i", CTScore);
        PrintToChatAll("%i", TScore);
        canSurrender = true;
    } else {
        canSurrender = false;
    }
    
    return Plugin_Continue;
}