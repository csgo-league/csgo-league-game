#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <get5>
#include "include/restorecvars.inc"

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

/** Chat aliases loaded **/
#define ALIAS_LENGTH 64
#define COMMAND_LENGTH 64
ArrayList g_ChatAliases;
ArrayList g_ChatAliasesCommands;

#include "league/util.sp"

public void OnPluginStart() {
    LoadTranslations("get5.phrases");
    g_WarmupCfgCvar = CreateConVar("get5_warmup_cfg", "get5/warmup.cfg", "Config file to exec in warmup periods");
    HookEventEx("round_end", Event_RoundEnd);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
    int roundsPlayed = GameRules_GetProp("m_totalRoundsPlayed");
    int maxrounds = GetCvarIntSafe("mp_maxrounds");
    Get5State state = Get5_GetGameState();
    g_bIsOvertime = false;

    PrintToChatAll("The round has ended.");

    if (CS_GetTeamScore(CS_TEAM_T) == CS_GetTeamScore(CS_TEAM_CT) && roundsPlayed == maxrounds) {
        g_bIsOvertime = true;
    }
    
    if (g_bIsOvertime && state == Get5State_Live) {
        CreateVoteMenu();
        CreateTimer(1.0, Timer_PreOT);
    }
}

void CreateVoteMenu() {
  if (IsVoteInProgress()) {
      return;
  }

  Menu menu = new Menu(Handle_VoteMenu);
  menu.VoteResultCallback = Handle_VoteResults;
  menu.SetTitle("Play Overtime?");
  menu.AddItem("yes", "Yes");
  menu.AddItem("no", "No");
  menu.ExitButton = false;
  menu.DisplayVoteToAll(60);
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

public void Handle_VoteResults(Menu menu,
                              int num_votes,
                              int num_clients,
                              const int[][] client_info,
                              int num_items,
                              const int[][] item_info)
{
    int winner = 0;
    if (num_items > 1 &&(item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES])) {
        winner = 1;
    }

    char strWinnerInfo[64];
    menu.GetItem(item_info[winner][VOTEINFO_ITEM_INDEX], strWinnerInfo, sizeof(strWinnerInfo));

    if (StrEqual(strWinnerInfo, "yes")) {
        Get5_MessageToAll("%t", "OvertimeCommencing");
        InOvertime();
        Unpause();
        g_bIsOvertime = false;

    } else {
        Get5_MessageToAll("%t", "MatchDraw");
        Unpause();
        ServerCommand("get5_endmatch");
        StartWarmup();
        EnsurePausedWarmup();
        g_bIsOvertime = false;
    }
}

public Action Timer_PreOT(Handle timer) {
    // PrintToChatAll("-1");
    Pause();
    
    if (!IsVoteInProgress()) {
        Menu menu = new Menu(Handle_VoteMenu);
        menu.VoteResultCallback = Handle_VoteResults;
        menu.SetTitle("Play Overtime?");
        menu.AddItem("yes", "Yes");
        menu.AddItem("no", "No");
        menu.ExitButton = false;
        menu.DisplayVoteToAll(20);
    }
}
