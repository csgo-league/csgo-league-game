#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <get5>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "[League] Clips",
	author = "PandahChan",
	description = "League clips plugin.",
	version = "1.0.0",
	url = "https://github.com/csgo-league"
};

int g_iRoundTick;

public void OnPluginStart() {
    // TODO: Declare DB

    HookEvent("round_start",Hook_RoundStart);
	AddAliasedCommand("clip", Command_Clip, "Allows a player create a clip ingame");

	AutoExecConfig(true, "league_clips");
}

public Action Hook_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_iRoundTick = GetGameTickCount();
}

public Action Command_Clip(int client, int args) {
	
}