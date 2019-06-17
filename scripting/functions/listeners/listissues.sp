public Action Listener_Listissues(int client, const char[] command, int arg) {
    if (GameRules_GetProp("m_bIsQueuedMatchmaking", 1) == 1) {
        PrintToConsole(client, "---Vote commands---");
        PrintToConsole(client, "callvote Surrender");
        PrintToConsole(client, "callvote StartTimeout");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}