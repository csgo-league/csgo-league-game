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

ConVar g_WarmupCfgCvar;
bool g_InExtendedPause = false;
bool g_bIsOvertime = false;

#include "league/util.sp"

public void OnPluginStart() {
    LoadTranslations("get5.phrases");
    AddCommandListener(Listener_Vote, "vote");
    AddCommandListener(Listener_Callvote, "callvote");
    AddCommandListener(Listener_Listissues, "listissues");


    g_WarmupCfgCvar = CreateConVar("get5_warmup_cfg", "get5/warmup.cfg", "Config file to exec in warmup periods");

    HookEventEx("round_end", Event_RoundEnd);
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
