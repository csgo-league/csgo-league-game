#include <sourcemod>
#include <cstrike>
#include <get5>

#include "get5/util.sp"

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "[League] Team Voting",
	author = "B3none, PandahChan",
	description = "League team voting plugin.",
	version = "1.0.0",
	url = "https://github.com/csgo-league"
};

ConVar g_cvTimeoutTime = null;
Handle g_Timeout = null;
int g_iTotalVotes = 0;
int g_iVotes[5];
bool g_bCanVote[MAXPLAYERS + 1] = {false, ...};

public void OnPluginStart() {
	g_cvTimeoutTime = FindConVar("get5_time_to_make_knife_decision");
}

public Action OnKnifeFinished(int team) {
	if (team != CS_TEAM_T && team != CS_TEAM_CT) {
		return Plugin_Continue;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (GetClientTeam(i) == team) {
			g_bCanVote[i] = true;
		}
	}

	g_Timeout = CreateTimer(view_as<float>(g_cvTimeoutTime.IntValue), Timeout_Reached);
	// Wait for above

	// Return accordingly
}

public Action Timeout_Reached(Handle timer) {
	HandleVotes();
}

public Action Command_VoteTerrorist(int client, int args) {

}

public Action Command_VoteCounterTerrorist(int client, int args) {

}

void HandleVotes() {
	if (g_iTotalVotes == 0) {
		// Stay?
		EndKnifeRound(false);
	} else {
		// Take a majority from those that have already voted
	}

	delete g_Timeout;
}