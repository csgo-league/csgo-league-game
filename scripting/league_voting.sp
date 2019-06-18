#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <get5>
#include <restorecvars>


public Plugin myinfo = {
	name = "[League] Voting",
	author = "PandahChan",
	description = "League voting plugin.",
	version = "1.1.0",
	url = "https://github.com/csgo-league"
};

#pragma newdecls required;

ConVar g_WarmupCfgCvar;
bool g_InExtendedPause = false;
bool g_bIsOvertime = false;

char steamid[64];

/* Server Voting Variables */
int teamVoteID = -1;
int voteType = -1;
int voteCaller = -1;
char displayString[512];
char detailsString[512];
char otherTeamString[512];
char passString[512];
char passDetailsString[512];
bool isTeamOnly = false;
bool soloOnly = false;
bool isVoteActive = false;
bool alreadyVoted[MAXPLAYERS + 1];
bool canSurrender = false;
Handle voteTimeout = null;
ConVar g_hVoteDuration = null;
ConVar g_hMaxrounds = null;
ConVar g_hMaxroundsOT = null;

#include "functions/listeners/listissues.sp"
#include "functions/listeners/callvote.sp"
#include "functions/listeners/vote.sp"
#include "functions/listeners/convarChange.sp"
#include "functions/listeners/roundStart.sp"
#include "functions/listeners/terminateRound.sp"

#include "functions/handlers/voteYes.sp"
#include "functions/handlers/voteNo.sp"
#include "functions/handlers/getResults.sp"
#include "functions/handlers/votePass.sp"
#include "functions/handlers/voteFail.sp"
#include "functions/handlers/voteTimeout.sp"

#include "functions/resolvers/doSurrender.sp"
#include "functions/resolvers/doStartTimeout.sp"

#include "functions/functions.sp"
#include "league/util.sp"

public void OnPluginStart() {
    LoadTranslations("get5.phrases");

    for (int i = 0; i < MAXPLAYERS + 1; i++) alreadyVoted[i] = false;
    AddCommandListener(Listener_Vote, "vote");
    AddCommandListener(Listener_Callvote, "callvote");
    AddCommandListener(Listener_Listissues, "listissues");

    g_hVoteDuration = FindConVar("sv_vote_timer_duration");
    g_hMaxrounds = FindConVar("mp_maxrounds");
    g_hMaxroundsOT = FindConVar("mp_overtime_maxrounds");

    g_hVoteDuration.AddChangeHook(OnConVarChange_voteDuration);
	g_hMaxrounds.AddChangeHook(OnConVarChange_checkSurrender);
    g_hMaxroundsOT.AddChangeHook(OnConVarChange_checkSurrender);

    g_WarmupCfgCvar = CreateConVar("get5_warmup_cfg", "get5/warmup.cfg", "Config file to exec in warmup periods");

    HookEvent("player_connect_full", Event_PlayerConnect); 
    HookEvent("round_start", Event_RoundStart);
    HookEventEx("round_end", Event_RoundEnd);
}

public void OnClientConnected(int client) {
    if (GetConVarFloat(g_hVoteDuration) < 1.0) {
        SetConVarFloat(g_hVoteDuration, 1.0);
    }
    alreadyVoted[client] = false;
}

public void OnClientDisconnect(int client) {
    alreadyVoted[client] = false;
}

public void Event_PlayerConnect(Event event, const char[] name, bool dontBroadcast) 
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
    ChangeClientTeam(client, Get5_MatchTeamToCSTeam(Get5_GetPlayerTeam(steamid)));
}  

public void OnMapStart(){
    GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
    canSurrender = false;
    for (int i = 0; i < MAXPLAYERS + 1; i++) alreadyVoted[i] = false;
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) {
        delete menu;
    } else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes) {
        Get5_MessageToAll("%t", "MatchDraw");
        Unpause();
        ServerCommand("get5_endmatch");
        StartWarmup();
        EnsurePausedWarmup();
        g_bIsOvertime = false;
    }
}

public void Handle_VoteResults(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info) {
    int total_votes = 0;

    for (int i = 0; i < num_items; i++){
        if (item_info[i][VOTEINFO_ITEM_INDEX] == 0) {
            total_votes = item_info[i][VOTEINFO_ITEM_VOTES];
            break;
        }
    }

    if ((total_votes * 100 / num_clients) >= 80) {
        Get5_MessageToAll("%t", "OvertimeCommencing");
        InOvertime();
        Unpause();
        g_bIsOvertime = false;
        return;
    }

    Get5_MessageToAll("%t", "MatchDraw");
    Unpause();
    ServerCommand("get5_endmatch");
    StartWarmup();
    EnsurePausedWarmup();
    g_bIsOvertime = false;
}

public Action Timer_PreOT(Handle timer) {
    Pause();

    Menu menu = new Menu(Handle_VoteMenu);
    menu.VoteResultCallback = Handle_VoteResults;
    menu.SetTitle("Play Overtime?");
    menu.AddItem("yes", "Yes");
    menu.AddItem("no", "No");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
    int roundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");
    int maxrounds = GetCvarIntSafe("mp_maxrounds");
    Get5State state = Get5_GetGameState();
    g_bIsOvertime = false;

    if (CS_GetTeamScore(CS_TEAM_T) == CS_GetTeamScore(CS_TEAM_CT) && roundsPlayed == maxrounds) {
        g_bIsOvertime = true;
    }
    
    if (g_bIsOvertime && state == Get5State_Live) {
        CreateTimer(0.1, Timer_PreOT);
    }
}

public Action Command_Surrender(int client, int args) {
    int CTScore = CS_GetTeamScore(CS_TEAM_CT);
    int TScore = CS_GetTeamScore(CS_TEAM_T);
    if (CTScore - 8 >= TScore || TScore - 8 >= CTScore) {
        FakeClientCommandEx(client,"callvote Surrender");
    }
    else {
        Get5_Message(client, "Surrender is currently unavailable. You need to be 8 rounds behind.");
    }