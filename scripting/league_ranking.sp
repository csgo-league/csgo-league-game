// This is a heavily modified version of Kento's RankMe
// https://github.com/rogeraabbccdd/Kento-Rankme

#include <sourcemod>
#include <adminmenu>
#include <geoip>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <league_ranking/rankme>
#include <league_ranking/colours.sp>
#include <league_ranking/globals.sp>
#include <league_ranking/cmds.sp>

#pragma semicolon 1
#pragma newdecls required

// SQL Queries
static const char g_sSqlInsert[] = "INSERT INTO `%s` VALUES (null,'%s','%d','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0');";
static const char g_sSqlSave[] = "UPDATE `%s` SET score = '%i', kills = '%i', deaths='%i', assists='%i',suicides='%i',tk='%i',shots='%i',hits='%i',headshots='%i', rounds_tr = '%i', rounds_ct = '%i',head='%i',chest='%i', stomach='%i',left_arm='%i',right_arm='%i',left_leg='%i',right_leg='%i' WHERE steam = '%s';";
static const char g_sSqlSave2[] = "UPDATE `%s` SET c4_planted='%i',c4_exploded='%i',c4_defused='%i',ct_win='%i',tr_win='%i', hostages_rescued='%i',vip_killed = '%d',vip_escaped = '%d',vip_played = '%d', mvp='%i', damage='%i', match_win='%i', match_draw='%i', match_lose='%i', first_blood='%i', no_scope='%i', no_scope_dis='%i', lastconnect='%i', connected='%i' WHERE steam = '%s';";
static const char g_sSqlRetrieveClient[] = "SELECT * FROM `%s` WHERE steam='%s';";
static const char g_sSqlRemoveDuplicateMySQL[] = "delete from `%s` USING `%s`, `%s` as vtable WHERE (`%s`.id>vtable.id) AND (`%s`.steam=vtable.steam);";

public Plugin myinfo = {
	name = "[League] Ranking",
	author = "B3none, Kento",
	description = "League ranking plugin.",
	version = "1.0.0",
	url = "https://github.com/csgo-league"
};

public void OnPluginStart() {
	CreateCvars();

	g_arrayRankCache[0] = CreateArray(ByteCountToCells(128));
	g_arrayRankCache[1] = CreateArray(ByteCountToCells(128));
	g_arrayRankCache[2] = CreateArray(ByteCountToCells(128));

	AddCvarListeners();

	// EVENTS
	HookEventEx("player_death", EventPlayerDeath);
	HookEventEx("player_hurt", EventPlayerHurt);
	HookEventEx("weapon_fire", EventWeaponFire);
	HookEventEx("bomb_planted", Event_BombPlanted);
	HookEventEx("bomb_defused", Event_BombDefused);
	HookEventEx("bomb_exploded", Event_BombExploded);
	HookEventEx("bomb_dropped", Event_BombDropped);
	HookEventEx("bomb_pickup", Event_BombPickup);
	HookEventEx("hostage_rescued", Event_HostageRescued);
	HookEventEx("vip_killed", Event_VipKilled);
	HookEventEx("vip_escaped", Event_VipEscaped);
	HookEventEx("round_end", Event_RoundEnd);
	HookEventEx("round_start", Event_RoundStart);
	HookEventEx("round_mvp", Event_RoundMVP);
	HookEventEx("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEventEx("cs_win_panel_match", Event_WinPanelMatch);

	// Admin commands
	RegAdminCmd("sm_resetrank", CMD_ResetRank, ADMFLAG_ROOT, "LeagueRanking: Resets the rank of a player");
	RegAdminCmd("sm_league_ranking_remove_duplicate", CMD_Duplicate, ADMFLAG_ROOT, "LeagueRanking: Removes the duplicated rows on the database");
	RegAdminCmd("sm_rankpurge", CMD_Purge, ADMFLAG_ROOT, "LeagueRanking: Purges from the rank players that didn't connected for X days");
	RegAdminCmd("sm_resetrank_all", CMD_ResetRankAll, ADMFLAG_ROOT, "LeagueRanking: Resets the rank of all players");

	// Player commands
	RegConsoleCmd("sm_rank", CMD_Rank, "LeagueRanking: Shows your rank");
	RegConsoleCmd("sm_top", CMD_Top, "LeagueRanking: Shows the TOP");

	// Load league.ranking.cfg
	AutoExecConfig(true, "league_ranking");

	// Load Translations
	LoadTranslations("league_ranking.phrases");

	//	Hook the say and say_team for chat triggers
	AddCommandListener(OnSayText, "say");
	AddCommandListener(OnSayText, "say_team");

	// Create the forwards
	g_fwdOnPlayerLoaded = CreateGlobalForward("LeagueRanking_OnPlayerLoaded", ET_Hook, Param_Cell);
	g_fwdOnPlayerSaved = CreateGlobalForward("LeagueRanking_OnPlayerSaved", ET_Hook, Param_Cell);
}

public void OnConVarChanged_SQLTable(Handle convar, const char[] oldValue, const char[] newValue) {
	g_cvarSQLTable.GetString(g_sSQLTable, sizeof(g_sSQLTable));
	DB_Connect(true); // Force reloading the stats
}

public void DB_Connect(bool firstload) {
    // Needs to connect if it hasn't connected yet
	if (firstload) {
		g_cvarSQLTable.GetString(g_sSQLTable, sizeof(g_sSQLTable));
		char sError[256];
		g_hStatsDb = SQL_Connect("league", false, sError, sizeof(sError));

		if (g_hStatsDb == null) {
		    LogError("[LeagueRanking] If you haven't already you'll need to run the migrations on the web interface.");
			SetFailState("[LeagueRanking] Unable to connect to the database (%s)", sError);
		}

		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnConfigsExecuted() {
	DB_Connect(g_hStatsDb == null);
	int AutoPurge = g_cvarAutopurge.IntValue;
	char sQuery[1000];
	if (AutoPurge > 0) {
		int DeleteBefore = GetTime() - (AutoPurge * 86400);
		Format(sQuery, sizeof(sQuery), "DELETE FROM `%s` WHERE lastconnect < '%d'", g_sSQLTable, DeleteBefore);
		SQL_TQuery(g_hStatsDb, SQL_PurgeCallback, sQuery);
	}

	g_bShowBotsOnRank = g_cvarShowBotsOnRank.BoolValue;
	g_bEnabled = g_cvarEnabled.BoolValue;
	g_bShowRankAll = g_cvarShowRankAll.BoolValue;
	g_fRankAllTimer = g_cvarRankAllTimer.FloatValue;
	g_bRankBots = g_cvarRankbots.BoolValue;
	g_bFfa = g_cvarFfa.BoolValue;
	g_PointsBombDefusedTeam = g_cvarPointsBombDefusedTeam.IntValue;
	g_PointsBombDefusedPlayer = g_cvarPointsBombDefusedPlayer.IntValue;
	g_PointsBombPlantedTeam = g_cvarPointsBombPlantedTeam.IntValue;
	g_PointsBombPlantedPlayer = g_cvarPointsBombPlantedPlayer.IntValue;
	g_PointsBombExplodeTeam = g_cvarPointsBombExplodeTeam.IntValue;
	g_PointsBombExplodePlayer = g_cvarPointsBombExplodePlayer.IntValue;
	g_PointsHostageRescTeam = g_cvarPointsHostageRescTeam.IntValue;
	g_PointsHostageRescPlayer = g_cvarPointsHostageRescPlayer.IntValue;
	g_PointsHs = g_cvarPointsHs.IntValue;
	g_PointsKill[CT] = g_cvarPointsKillCt.IntValue;
	g_PointsKill[TR] = g_cvarPointsKillTr.IntValue;
	g_PointsKillBonus[CT] = g_cvarPointsKillBonusCt.IntValue;
	g_PointsKillBonus[TR] = g_cvarPointsKillBonusTr.IntValue;
	g_PointsKillBonusDif[CT] = g_cvarPointsKillBonusDifCt.IntValue;
	g_PointsKillBonusDif[TR] = g_cvarPointsKillBonusDifTr.IntValue;
	g_PointsStart = g_cvarPointsStart.IntValue;
	g_fPointsKnifeMultiplier = g_cvarPointsKnifeMultiplier.FloatValue;
	g_fPointsTaserMultiplier = g_cvarPointsTaserMultiplier.FloatValue;
	g_PointsRoundWin[TR] = g_cvarPointsTrRoundWin.IntValue;
	g_PointsRoundWin[CT] = g_cvarPointsCtRoundWin.IntValue;
	g_PointsRoundLose[TR] = g_cvarPointsTrRoundLose.IntValue;
	g_PointsRoundLose[CT] = g_cvarPointsCtRoundLose.IntValue;
	g_MinimalKills = g_cvarMinimalKills.IntValue;
	g_fPercentPointsLose = g_cvarPercentPointsLose.FloatValue;
	g_bPointsLoseRoundCeil = g_cvarPointsLoseRoundCeil.BoolValue;
	g_MinimumPlayers = g_cvarMinimumPlayers.IntValue;
	g_bResetOwnRank = g_cvarResetOwnRank.BoolValue;
	g_PointsVipEscapedTeam = g_cvarPointsVipEscapedTeam.IntValue;
	g_PointsVipEscapedPlayer = g_cvarPointsVipEscapedPlayer.IntValue;
	g_PointsVipKilledTeam = g_cvarPointsVipKilledTeam.IntValue;
	g_PointsVipKilledPlayer = g_cvarPointsVipKilledPlayer.IntValue;
	g_PointsLoseTk = g_cvarPointsLoseTk.IntValue;
	g_PointsLoseSuicide = g_cvarPointsLoseSuicide.IntValue;
	g_DaysToNotShowOnRank = g_cvarDaysToNotShowOnRank.IntValue;
	g_bGatherStats = g_cvarGatherStats.BoolValue;
	g_bChatTriggers = g_cvarChatTriggers.BoolValue;
	g_PointsMvpCt = g_cvarPointsMvpCt.IntValue;
	g_PointsMvpTr = g_cvarPointsMvpTr.IntValue;
	g_PointsBombDropped = g_cvarPointsBombDropped.IntValue;
	g_PointsBombPickup = g_cvarPointsBombPickup.IntValue;
	g_PointsMatchWin = g_cvarPointsMatchWin.IntValue;
	g_PointsMatchDraw = g_cvarPointsMatchDraw.IntValue;
	g_PointsMatchLose = g_cvarPointsMatchLose.IntValue;
	g_PointsFb = g_cvarPointsFb.IntValue;
	g_PointsNS = g_cvarPointsNS.IntValue;
	g_bNSAllSnipers = g_cvarNSAllSnipers.BoolValue;
	g_PointsAssistKill = g_cvarPointsAssistKill.IntValue;
	g_PointsMin = g_cvarPointsMin.IntValue;
	g_bPointsMinEnabled = g_cvarPointsMin.BoolValue;
	g_bAnnounceConnect = g_cvarAnnounceConnect.BoolValue;
	g_bAnnounceConnectChat = g_cvarAnnounceConnectChat.BoolValue;
	g_bAnnounceConnectHint = g_cvarAnnounceConnectHint.BoolValue;
	g_bAnnounceDisconnect = g_cvarAnnounceDisconnect.BoolValue;
	g_bAnnounceTopConnect = g_cvarAnnounceTopConnect.BoolValue;
	g_AnnounceTopPosConnect = g_cvarAnnounceTopPosConnect.BoolValue;
	g_bAnnounceTopConnectChat = g_cvarAnnounceTopConnectChat.BoolValue;
	g_bAnnounceTopConnectHint = g_cvarAnnounceTopConnectHint.BoolValue;

	if (g_bRankBots) {
		Format(sQuery, sizeof(sQuery), "SELECT * FROM `%s` WHERE kills >= '%d'", g_sSQLTable, g_MinimalKills);
	} else {
		Format(sQuery, sizeof(sQuery), "SELECT * FROM `%s` WHERE kills >= '%d' AND steam <> 'BOT'", g_sSQLTable, g_MinimalKills);
	}

	SQL_TQuery(g_hStatsDb, SQL_GetPlayersCallback, sQuery);

	BuildRankCache();
}

void BuildRankCache() {
	if (!g_bRankCache) {
		return;
	}

	ClearArray(g_arrayRankCache[0]);
	ClearArray(g_arrayRankCache[1]);
	ClearArray(g_arrayRankCache[2]);

	PushArrayString(g_arrayRankCache[0], "Rank By SteamId: This is First Line in Array");

	char query[1000];
	MakeSelectQuery(query, sizeof(query));

	Format(query, sizeof(query), "%s ORDER BY score DESC", query);

	SQL_TQuery(g_hStatsDb, SQL_BuildRankCache, query);
}

public void SQL_BuildRankCache(Handle owner, Handle hndl, const char[] error, any unuse) {
	if (hndl == null) {
		LogError("[LeagueRanking] build rank cache failed", error);
		return;
	}

	if (SQL_GetRowCount(hndl)) {
		char steamid[32];
		while(SQL_FetchRow(hndl)) {
			SQL_FetchString(hndl, 1, steamid, 32);
			PushArrayString(g_arrayRankCache[0], steamid);
		}
	} else {
		LogMessage("[LeagueRanking] No more rank");
	}
}

public Action CMD_Duplicate(int client, int args) {
	char sQuery[512];

	FormatEx(sQuery, sizeof(sQuery), g_sSqlRemoveDuplicateMySQL, g_sSQLTable, g_sSQLTable, g_sSQLTable, g_sSQLTable, g_sSQLTable);

	SQL_TQuery(g_hStatsDb, SQL_DuplicateCallback, sQuery, client);

	return Plugin_Handled;
}

public void SQL_DuplicateCallback(Handle owner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogError("[LeagueRanking] Query Fail: %s", error);
		return;
	}

	PrintToServer("[LeagueRanking] %d duplicated rows removed", SQL_GetAffectedRows(owner));
	if (client != 0) {
		CPrintToChat(client, "[LeagueRanking] %d duplicated rows removed", SQL_GetAffectedRows(owner));
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("LeagueRanking_GivePoint", Native_GivePoint);
	CreateNative("LeagueRanking_GetRank", Native_GetRank);
	CreateNative("LeagueRanking_GetPoints", Native_GetPoints);
	CreateNative("LeagueRanking_GetStats", Native_GetStats);
	CreateNative("LeagueRanking_GetWeaponStats", Native_GetWeaponStats);
	CreateNative("LeagueRanking_IsPlayerLoaded", Native_IsPlayerLoaded);
	CreateNative("LeagueRanking_GetHitbox", Native_GetHitbox);

	RegPluginLibrary("LeagueRanking");

	return APLRes_Success;
}

public int Native_GivePoint(Handle plugin, int numParams) {
	int iClient = GetNativeCell(1);
	int iPoints = GetNativeCell(2);

	int len;
	GetNativeStringLength(3, len);

	if (len <= 0) {
		return;
	}

	char[] Reason = new char[len + 1];
	GetNativeString(3, Reason, len + 1);
	g_aStats[iClient][SCORE] += iPoints;
}


public int Native_GetRank(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	Function callback = GetNativeCell(2);
	any data = GetNativeCell(3);

	Handle pack = CreateDataPack();

	WritePackCell(pack, client);
	WritePackFunction(pack, callback);
	WritePackCell(pack, data);
	WritePackCell(pack, view_as<int>(plugin));

	if (g_bRankCache) {
		GetClientRank(pack);
		return;
	}

	char query[10000];
	MakeSelectQuery(query, sizeof(query));

	Format(query, sizeof(query), "%s ORDER BY score DESC", query);

	SQL_TQuery(g_hStatsDb, SQL_GetRankCallback, query, pack);
}

void GetClientRank(Handle pack) {
	ResetPack(pack);
	int client = ReadPackCell(pack);
	Function callback = ReadPackFunction(pack);
	any args = ReadPackCell(pack);
	Handle plugin = ReadPackCell(pack);
	CloseHandle(pack);

	int rank;
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32, true);
	rank = FindStringInArray(g_arrayRankCache[0], steamid);

	if (rank > 0) {
		CallRankCallback(client, rank, callback, args, plugin);
	} else {
		CallRankCallback(client, 0, callback, args, plugin);
	}
}

public void SQL_GetRankCallback(Handle owner, Handle hndl, const char[] error, any data) {
	Handle pack = data;
	ResetPack(pack);
	int client = ReadPackCell(pack);
	Function callback = ReadPackFunction(pack);
	any args = ReadPackCell(pack);
	Handle plugin = ReadPackCell(pack);
	CloseHandle(pack);

	if (hndl == null) {
		LogError("[LeagueRanking] Query Fail: %s", error);
		CallRankCallback(0, 0, callback, 0, plugin);
		return;
	}

	int i;
	g_TotalPlayers = SQL_GetRowCount(hndl);

	char Receive[64];

	while (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		i++;
		SQL_FetchString(hndl, 1, Receive, sizeof(Receive));

		if (StrEqual(Receive, g_aClientSteam[client], false)) {
			CallRankCallback(client, i, callback, args, plugin);
			break;
        }
	}
}

void CallRankCallback(int client, int rank, Function callback, any data, Handle plugin) {
	Call_StartFunction(plugin, callback);
	Call_PushCell(client);
	Call_PushCell(rank);
	Call_PushCell(data);
	Call_Finish();
	CloseHandle(plugin);
}

public int Native_GetPoints(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	return g_aStats[client][SCORE];
}

public int Native_GetStats(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int array[20];
	for (int i = 0; i < 20; i++) {
		array[i] = g_aStats[client][i];
	}

	SetNativeArray(2, array, 20);
}

public int Native_IsPlayerLoaded(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	return OnDB[client];
}

public int Native_GetWeaponStats(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int array[41];
	for (int i = 0; i < 42; i++) {
		array[i] = g_aWeapons[client][i];
	}

	SetNativeArray(2, array, 41);
}

public int Native_GetHitbox(Handle plugin, int numParams) {
	int client = GetNativeCell(1);
	int array[8];
	for (int i = 0; i < 8; i++) {
		array[i] = g_aHitBox[client][i];
	}

	SetNativeArray(2, array, 8);
}

// Code made by Antithasys
public Action OnSayText(int client, const char[] command, int argc) {
	if (!g_bEnabled || !g_bChatTriggers || client == SENDER_WORLD || IsChatTrigger()) {
		// Don't parse if plugin is disabled or if is from the console or a chat trigger (e.g: ! or /)
		return Plugin_Continue;
	}

	char cpMessage[256];
	char sWords[64][256];
	GetCmdArgString(cpMessage, sizeof(cpMessage)); // Get the message
	StripQuotes(cpMessage); // Text come inside quotes
	ExplodeString(cpMessage, " ", sWords, sizeof(sWords), sizeof(sWords[])); // Explode it for use at top, topknife, topnade and topweapon

	// Process the text
	if (StrEqual(cpMessage, "rank", false)) {
		CMD_Rank(client, 0);
	} else if (StrContains(sWords[0], "top", false) == 0) {
		if (strcmp(cpMessage, "top") == 0) {
			ShowTOP(client, 0);
		} else {
			ShowTOP(client, StringToInt(cpMessage[3]));
		}
	}

	return Plugin_Continue;
}

int GetCurrentPlayers() {
	int count;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && (!IsFakeClient(i) || g_bRankBots)) {
			count++;
		}
	}
	return count;
}

public void OnPluginEnd() {
	if (!g_bEnabled) {
		return;
	}

	SQL_LockDatabase(g_hStatsDb);
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
				return;
			}

			char weapons_query[2000] = "";
			for (int i = 0; i < 42; i++) {
				Format(weapons_query, sizeof(weapons_query), "%s,%s='%d'", weapons_query, g_sWeaponsNamesGame[i], g_aWeapons[client][i]);
			}

			/* SM1.9 Fix */
			char query[4000];
			char query2[4000];

			Format(query, sizeof(query), g_sSqlSave, g_sSQLTable, g_aStats[client][SCORE], g_aStats[client][KILLS], g_aStats[client][DEATHS], g_aStats[client][ASSISTS], g_aStats[client][SUICIDES], g_aStats[client][TK],
                g_aStats[client][SHOTS], g_aStats[client][HITS], g_aStats[client][HEADSHOTS], g_aStats[client][ROUNDS_TR], g_aStats[client][ROUNDS_CT], weapons_query,
                g_aHitBox[client][1], g_aHitBox[client][2], g_aHitBox[client][3], g_aHitBox[client][4], g_aHitBox[client][5], g_aHitBox[client][6], g_aHitBox[client][7], g_aClientSteam[client]);

			Format(query2, sizeof(query2), g_sSqlSave2, g_sSQLTable, g_aStats[client][C4_PLANTED], g_aStats[client][C4_EXPLODED], g_aStats[client][C4_DEFUSED], g_aStats[client][CT_WIN], g_aStats[client][TR_WIN],
                g_aStats[client][HOSTAGES_RESCUED], g_aStats[client][VIP_KILLED], g_aStats[client][VIP_ESCAPED], g_aStats[client][VIP_PLAYED], g_aStats[client][MVP], g_aStats[client][DAMAGE], g_aStats[client][MATCH_WIN], g_aStats[client][MATCH_DRAW], g_aStats[client][MATCH_LOSE], g_aStats[client][FB], g_aStats[client][NS], g_aStats[client][NSD], GetTime(), g_aStats[client][CONNECTED] + GetTime() - connectTime[client], g_aClientSteam[client]);

			LogMessage(query);
			LogMessage(query2);
			SQL_FastQuery(g_hStatsDb, query);
			SQL_FastQuery(g_hStatsDb, query2);

			/**
			Start the forward OnPlayerSaved
			*/
			Action fResult;
			Call_StartForward(g_fwdOnPlayerSaved);
			Call_PushCell(client);
			int fError = Call_Finish(fResult);

			if (fError != SP_ERROR_NONE) {
				ThrowNativeError(fError, "Forward failed");
			}
		}
	}

	SQL_UnlockDatabase(g_hStatsDb);
}

public int GetWeaponNum(char[] weaponname) {
	for (int i = 0; i < 42; i++) {
		if (StrEqual(weaponname, g_sWeaponsNamesGame[i])) {
			return i;
		}
	}

	return 43;
}

public Action Event_VipEscaped(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == CT) {
			g_aStats[i][SCORE] += g_PointsVipEscapedTeam;
		}
	}

	g_aStats[client][VIP_PLAYED]++;
	g_aStats[client][VIP_ESCAPED]++;
	g_aStats[client][SCORE] += g_PointsVipEscapedPlayer;
}

public Action Event_VipKilled(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int killer = GetClientOfUserId(GetEventInt(event, "attacker"));

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TR) {
			g_aStats[i][SCORE] += g_PointsVipKilledTeam;
		}
	}
	g_aStats[client][VIP_PLAYED]++;
	g_aStats[killer][VIP_KILLED]++;
	g_aStats[killer][SCORE] += g_PointsVipKilledPlayer;
}

public Action Event_HostageRescued(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == CT) {
			g_aStats[i][SCORE] += g_PointsHostageRescTeam;
		}
	}

	g_aStats[client][HOSTAGES_RESCUED]++;
	g_aStats[client][SCORE] += g_PointsHostageRescPlayer;
}

public Action Event_RoundMVP(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsClientInGame(client)) {
		return;
	}

	int team = GetClientTeam(client);

	if (((team == 2 && g_PointsMvpTr > 0) || (team == 3 && g_PointsMvpCt > 0)) && client != 0 && (g_bRankBots && !IsFakeClient(client))) {
		if (team == 2) {
			g_aStats[client][SCORE] += g_PointsMvpTr;
		} else {
			g_aStats[client][SCORE] += g_PointsMvpCt;
		}
	}

	g_aStats[client][MVP]++;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int i;
	int Winner = GetEventInt(event, "winner");
	for (i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && (g_bRankBots || !IsFakeClient(i))) {
			if (Winner == TR) {
				if (GetClientTeam(i) == TR) {
					g_aStats[i][TR_WIN]++;

					if (g_PointsRoundWin[TR] > 0) {
						g_aStats[i][SCORE] += g_PointsRoundWin[TR];
					}
				} else if (GetClientTeam(i) == CT) {
					if (g_PointsRoundLose[CT] > 0) {
						g_aStats[i][SCORE] -= g_PointsRoundLose[CT];
					}
				}
			} else if (Winner == CT) {
				if (GetClientTeam(i) == CT) {
					g_aStats[i][CT_WIN]++;

					if (g_PointsRoundWin[CT] > 0) {
						g_aStats[i][SCORE] += g_PointsRoundWin[CT];
					}
				} else if (GetClientTeam(i) == TR) {
					if (g_PointsRoundLose[TR] > 0) {
						g_aStats[i][SCORE] -= g_PointsRoundLose[TR];
					}
				}
			}

			SavePlayer(i);
		}
	}
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	firstblood = false;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TR) {
			g_aStats[i][ROUNDS_TR]++;
		} else if (IsClientInGame(i) && GetClientTeam(i) == CT) {
			g_aStats[i][ROUNDS_CT]++;
		}
	}
}

public Action Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_C4PlantedBy = client;

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TR) {
			g_aStats[i][SCORE] += g_PointsBombPlantedTeam;
		}
	}

	g_aStats[client][C4_PLANTED]++;
	g_aStats[client][SCORE] += g_PointsBombPlantedPlayer;
}

public Action Event_BombDefused(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == CT) {
			g_aStats[i][SCORE] += g_PointsBombDefusedTeam;
		}
	}

	g_aStats[client][C4_DEFUSED]++;
	g_aStats[client][SCORE] += g_PointsBombDefusedPlayer;
}

public Action Event_BombExploded(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = g_C4PlantedBy;

	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) == TR) {
			g_aStats[i][SCORE] += g_PointsBombExplodeTeam;
		}
	}

	g_aStats[client][C4_EXPLODED]++;
	g_aStats[client][SCORE] += g_PointsBombExplodePlayer;
}

public Action Event_BombPickup(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_aStats[client][SCORE] += g_PointsBombPickup;
}

public Action Event_BombDropped(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_aStats[client][SCORE] -= g_PointsBombDropped;
}

public Action EventPlayerDeath(Handle event, const char [] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int assist = GetClientOfUserId(GetEventInt(event, "assister"));

	char weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	ReplaceString(weapon, sizeof(weapon), "weapon_", "");

	if (!g_bRankBots && attacker != 0 && (IsFakeClient(victim) || IsFakeClient(attacker))) {
		return;
	}

	if (victim == attacker || attacker == 0) {
		g_aStats[victim][SUICIDES]++;
		g_aStats[victim][SCORE] -= g_PointsLoseSuicide;

		/* Min points */
		if (g_bPointsMinEnabled) {
			if (g_aStats[victim][SCORE] < g_PointsMin) {
				g_aStats[victim][SCORE] = g_PointsMin;
			}
		}

	} else if (!g_bFfa && (GetClientTeam(victim) == GetClientTeam(attacker))) {
		if (attacker < MaxClients) {
			g_aStats[attacker][TK]++;
			g_aStats[attacker][SCORE] -= g_PointsLoseTk;

			/* Min points */
			if (g_bPointsMinEnabled) {
				if (g_aStats[victim][SCORE] < g_PointsMin) {
					g_aStats[victim][SCORE] = g_PointsMin;
				}
			}
		}
	} else {
		int team = GetClientTeam(attacker);
		bool headshot = GetEventBool(event, "headshot");

		/* knife */
		if (StrContains(weapon, "knife") != -1 ||
			StrEqual(weapon, "bayonet") ||
			StrEqual(weapon, "melee") ||
			StrEqual(weapon, "axe") ||
			StrEqual(weapon, "hammer") ||
			StrEqual(weapon, "spanner") ||
			StrEqual(weapon, "fists")) {
			weapon = "knife";
		}

		/* breachcharge has projectile */
		if (StrContains(weapon, "breachcharge") != -1) {
			weapon = "breachcharge";
		}

		/* firebomb = molotov */
		if (StrEqual(weapon, "firebomb")) {
			weapon = "molotov";
		}

		/* diversion = decoy, and decoy has projectile */
		if (StrContains(weapon, "diversion") != -1 || StrContains(weapon, "decoy") != -1) {
			weapon = "decoy";
		}

		int score_dif;
		if (attacker < MaxClients) {
			score_dif = g_aStats[victim][SCORE] - g_aStats[attacker][SCORE];
		}

		if (score_dif < 0 || attacker >= MaxClients) {
			score_dif = g_PointsKill[team];
		} else {
			if (g_PointsKillBonusDif[team] == 0) {
				score_dif = g_PointsKill[team] + ((g_aStats[victim][SCORE] - g_aStats[attacker][SCORE]) * g_PointsKillBonus[team]);
			} else {
				score_dif = g_PointsKill[team] + (((g_aStats[victim][SCORE] - g_aStats[attacker][SCORE]) / g_PointsKillBonusDif[team]) * g_PointsKillBonus[team]);
			}
		}

		if (StrEqual(weapon, "knife")) {
			score_dif = RoundToCeil(score_dif * g_fPointsKnifeMultiplier);
		} else if (StrEqual(weapon, "taser")) {
			score_dif = RoundToCeil(score_dif * g_fPointsTaserMultiplier);
		}

		if (headshot && attacker < MaxClients) {
			g_aStats[attacker][HEADSHOTS]++;
		}

		g_aStats[victim][DEATHS]++;

		if (attacker < MaxClients) {
			g_aStats[attacker][KILLS]++;
		}

		if (g_bPointsLoseRoundCeil) {
			g_aStats[victim][SCORE] -= RoundToCeil(score_dif * g_fPercentPointsLose);

			if (g_bPointsMinEnabled) {
				if (g_aStats[victim][SCORE] < g_PointsMin) {
					g_aStats[victim][SCORE] = g_PointsMin;
				}
			}
		} else {
			g_aStats[victim][SCORE] -= RoundToFloor(score_dif * g_fPercentPointsLose);

			if (g_bPointsMinEnabled) {
				if (g_aStats[victim][SCORE] < g_PointsMin) {
					g_aStats[victim][SCORE] = g_PointsMin;
				}
			}
		}

		if (attacker < MaxClients) {
			g_aStats[attacker][SCORE] += score_dif;

			if (GetWeaponNum(weapon) < 42) {
				g_aWeapons[attacker][GetWeaponNum(weapon)]++;
			}
		}

		if (headshot && attacker < MaxClients) {
			g_aStats[attacker][SCORE] += g_PointsHs;
		}

		if (!firstblood && attacker < MaxClients) {
			g_aStats[attacker][SCORE] += g_PointsFb;

			g_aStats[attacker][FB] ++;
		}

		if (attacker < MaxClients && ((StrContains(weapon, "awp") != -1 || StrContains(weapon, "ssg08") != -1) || (g_bNSAllSnipers && (StrContains(weapon, "g3sg1") != -1 || StrContains(weapon, "scar20") != -1))) && (GetEntProp(attacker, Prop_Data, "m_iFOV") <= 0 || GetEntProp(attacker, Prop_Data, "m_iFOV") == GetEntProp(attacker, Prop_Data, "m_iDefaultFOV"))) {
			g_aStats[attacker][SCORE]+= g_PointsNS;
			g_aStats[attacker][NS]++;

			float fNSD = Math_UnitsToMeters(Entity_GetDistance(victim, attacker));

			// stats are int, so we change it from m to cm
			int iNSD = RoundToFloor(fNSD * 100);
			if (iNSD > g_aStats[attacker][NSD]) {
				g_aStats[attacker][NSD] = iNSD;
			}
		}
	}

	if (assist && attacker < MaxClients) {
		//Do not attack your teammate, my friend
		if (GetClientTeam(victim) == GetClientTeam(assist))	{
			return;
		} else {
			g_aStats[assist][SCORE]+= g_PointsAssistKill;
			g_aStats[assist][ASSISTS]++;
		}
	}

	if (attacker < MaxClients) {
		if (g_aStats[attacker][KILLS] == 50) {
			g_TotalPlayers++;
		}
	}

	firstblood = true;
}

public Action EventPlayerHurt(Handle event, const char [] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (!g_bRankBots && (attacker == 0 || IsFakeClient(victim) || IsFakeClient(attacker))) {
		return;
	}

	if (victim != attacker && attacker > 0 && attacker < MaxClients) {
		int hitgroup = GetEventInt(event, "hitgroup");
		if (hitgroup == 0) {
			// Player was hit by knife, he, flashbang, or smokegrenade.
			return;
		}

		if (hitgroup == 8) {
			hitgroup = 1;
		}

		g_aStats[attacker][HITS]++;
		g_aHitBox[attacker][hitgroup]++;

		int damage = GetEventInt(event, "dmg_health");
		g_aStats[attacker][DAMAGE] += damage;
	}
}

public Action EventWeaponFire(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return;
	}

	// Don't count knife being used neither hegrenade, flashbang and smokegrenade being threw
	char sWeaponUsed[50];
	GetEventString(event, "weapon", sWeaponUsed, sizeof(sWeaponUsed));
	ReplaceString(sWeaponUsed, sizeof(sWeaponUsed), "weapon_", "");
	if (StrContains(sWeaponUsed, "knife") != -1 ||
		StrEqual(sWeaponUsed, "bayonet") ||
		StrEqual(sWeaponUsed, "melee") ||
		StrEqual(sWeaponUsed, "axe") ||
		StrEqual(sWeaponUsed, "hammer") ||
		StrEqual(sWeaponUsed, "spanner") ||
		StrEqual(sWeaponUsed, "fists") ||
		StrEqual(sWeaponUsed, "hegrenade") ||
		StrEqual(sWeaponUsed, "flashbang") ||
		StrEqual(sWeaponUsed, "smokegrenade") ||
		StrEqual(sWeaponUsed, "inferno") ||
		StrEqual(sWeaponUsed, "molotov") ||
		StrEqual(sWeaponUsed, "incgrenade") ||
		StrContains(sWeaponUsed, "decoy") != -1 ||
		StrEqual(sWeaponUsed, "firebomb") ||
		StrEqual(sWeaponUsed, "diversion") ||
		StrContains(sWeaponUsed, "breachcharge") != -1) {
		return;
	}

	g_aStats[client][SHOTS]++;
}

public void SavePlayer(int client) {
	if (!g_bEnabled || !g_bGatherStats || g_MinimumPlayers > GetCurrentPlayers()) {
		return;
	}

	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return;
	}

	if (!OnDB[client]) {
		return;
	}

	char weapons_query[1000] = "";
	for (int i = 0; i < 42; i++) {
		Format(weapons_query, sizeof(weapons_query), "%s,%s='%d'", weapons_query, g_sWeaponsNamesGame[i], g_aWeapons[client][i]);
	}

	char query[4000];
	char query2[4000];

	Format(query, sizeof(query), g_sSqlSave, g_sSQLTable, g_aStats[client][SCORE], g_aStats[client][KILLS], g_aStats[client][DEATHS], g_aStats[client][ASSISTS], g_aStats[client][SUICIDES], g_aStats[client][TK], g_aStats[client][SHOTS], g_aStats[client][HITS], g_aStats[client][HEADSHOTS], g_aStats[client][ROUNDS_TR], g_aStats[client][ROUNDS_CT], weapons_query, g_aHitBox[client][1], g_aHitBox[client][2], g_aHitBox[client][3], g_aHitBox[client][4], g_aHitBox[client][5], g_aHitBox[client][6], g_aHitBox[client][7], g_aClientSteam[client]);

	Format(query2, sizeof(query2), g_sSqlSave2, g_sSQLTable, g_aStats[client][C4_PLANTED], g_aStats[client][C4_EXPLODED], g_aStats[client][C4_DEFUSED], g_aStats[client][CT_WIN], g_aStats[client][TR_WIN], g_aStats[client][HOSTAGES_RESCUED], g_aStats[client][VIP_KILLED], g_aStats[client][VIP_ESCAPED], g_aStats[client][VIP_PLAYED], g_aStats[client][MVP], g_aStats[client][DAMAGE], g_aStats[client][MATCH_WIN], g_aStats[client][MATCH_DRAW], g_aStats[client][MATCH_LOSE], g_aStats[client][FB], g_aStats[client][NS], g_aStats[client][NSD], GetTime(), g_aStats[client][CONNECTED] + GetTime() - connectTime[client], g_aClientSteam[client]);

	SQL_TQuery(g_hStatsDb, SQL_SaveCallback, query, client, DBPrio_High);
	SQL_TQuery(g_hStatsDb, SQL_SaveCallback, query2, client, DBPrio_High);

	if (DEBUGGING) {
		PrintToServer(query);
		PrintToServer(query2);
		LogError("%s", query);
		LogError("%s", query2);
	}
}


public void SQL_SaveCallback(Handle owner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogError("[LeagueRanking] Save Player Fail: %s", error);
		return;
	}

	/**
		Start the forward OnPlayerSaved
	*/
	Action fResult;
	Call_StartForward(g_fwdOnPlayerSaved);
	Call_PushCell(client);
	int fError = Call_Finish(fResult);

	if (fError != SP_ERROR_NONE) {
		ThrowNativeError(fError, "Forward failed");
	}
}

public void OnClientPutInServer(int client) {
	connectTime[client] = GetTime();

	// If the database isn't connected, you can't run SQL_EscapeString.
	if (g_hStatsDb != null) {
		LoadPlayer(client);
	}
}

public void LoadPlayer(int client) {
	OnDB[client] = false;
	for (int i = 0; i <= 19; i++) {
		g_aStats[client][i] = 0;
	}

	g_aStats[client][SCORE] = g_PointsStart;

	for (int i = 0; i < 42; i++) {
		g_aWeapons[client][i] = 0;
	}

	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	strcopy(g_aClientSteam[client], sizeof(g_aClientSteam[]), auth);
	char query[10000];

	FormatEx(query, sizeof(query), g_sSqlRetrieveClient, g_sSQLTable, auth);

	if (DEBUGGING) {
		PrintToServer(query);
		LogError("%s", query);
	}

	if (g_hStatsDb != null) {
		SQL_TQuery(g_hStatsDb, SQL_LoadPlayerCallback, query, client);
	}
}

public void SQL_LoadPlayerCallback(Handle owner, Handle hndl, const char[] error, any client) {
	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return;
	}

	if (hndl == null) {
		LogError("[LeagueRanking] Load Player Fail: %s", error);
		return;
	}

	if (!IsClientInGame(client)) {
		return;
	}

	char auth[64];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	if (!StrEqual(auth, g_aClientSteam[client])) {
        return;
    }

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		//Player info
		for (int i = 0; i < 10; i++) {
			g_aStats[client][i] = SQL_FetchInt(hndl, 2 + i);
		}

		//ALL 41 Weapons
		for (int i = 0; i < 42; i++) {
			g_aWeapons[client][i] = SQL_FetchInt(hndl, 16 + i);
		}

		//ALL 8 Hitboxes
		for (int i = 0; i < 8; i++) {
			g_aHitBox[client][i] = SQL_FetchInt(hndl, 58 + i);
		}

		g_aStats[client][C4_PLANTED] = SQL_FetchInt(hndl, 65);
		g_aStats[client][C4_EXPLODED] = SQL_FetchInt(hndl, 66);
		g_aStats[client][C4_DEFUSED] = SQL_FetchInt(hndl, 67);
		g_aStats[client][CT_WIN] = SQL_FetchInt(hndl, 68);
		g_aStats[client][TR_WIN] = SQL_FetchInt(hndl, 69);
		g_aStats[client][HOSTAGES_RESCUED] = SQL_FetchInt(hndl, 70);
		g_aStats[client][VIP_KILLED] = SQL_FetchInt(hndl, 71);
		g_aStats[client][VIP_ESCAPED] = SQL_FetchInt(hndl, 72);
		g_aStats[client][VIP_PLAYED] = SQL_FetchInt(hndl, 73);
		g_aStats[client][MVP] = SQL_FetchInt(hndl, 74);
		g_aStats[client][DAMAGE] = SQL_FetchInt(hndl, 75);
		g_aStats[client][MATCH_WIN] = SQL_FetchInt(hndl, 76);
		g_aStats[client][MATCH_DRAW] = SQL_FetchInt(hndl, 77);
		g_aStats[client][MATCH_LOSE] = SQL_FetchInt(hndl, 78);
		g_aStats[client][FB] = SQL_FetchInt(hndl, 79);
		g_aStats[client][NS] = SQL_FetchInt(hndl, 80);
		g_aStats[client][NSD] = SQL_FetchInt(hndl, 81);
	} else {
		char query[10000];

		Format(query, sizeof(query), g_sSqlInsert, g_sSQLTable, g_aClientSteam[client], g_PointsStart);
		SQL_TQuery(g_hStatsDb, SQL_NothingCallback, query, _, DBPrio_High);

		if (DEBUGGING) {
			PrintToServer(query);

			LogError("%s", query);
		}
	}
	OnDB[client] = true;
	/**
	Start the forward OnPlayerLoaded
	*/
	Action fResult;
	Call_StartForward(g_fwdOnPlayerLoaded);
	Call_PushCell(client);
	int fError = Call_Finish(fResult);

	if (fError != SP_ERROR_NONE) {
		ThrowNativeError(fError, "Forward failed");
	}
}

public void SQL_PurgeCallback(Handle owner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogError("[LeagueRanking] Query Fail: %s", error);
		return;
	}

	PrintToServer("[LeagueRanking] %d players purged by inactivity", SQL_GetAffectedRows(owner));
	if (client != 0) {
		CPrintToChat(client, "[LeagueRanking] %d players purged by inactivity", SQL_GetAffectedRows(owner));
	}
}

public void SQL_NothingCallback(Handle owner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogError("[LeagueRanking] Query Fail: %s", error);
		return;
	}
}

public void OnClientDisconnect(int client) {
	if (!g_bEnabled) {
		return;
	}

	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return;
	}

	SavePlayer(client);
	OnDB[client] = false;
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue) {
	int g_bQueryPlayerCount;

	if (convar == g_cvarShowBotsOnRank) {
		g_bShowBotsOnRank = g_cvarShowBotsOnRank.BoolValue;
		g_bQueryPlayerCount = true;
	} else if (convar == g_cvarEnabled) {
		g_bEnabled = g_cvarEnabled.BoolValue;
	} else if (convar == g_cvarShowRankAll) {
		g_bShowRankAll = g_cvarShowRankAll.BoolValue;
	} else if (convar == g_cvarRankAllTimer) {
		g_fRankAllTimer = g_cvarRankAllTimer.FloatValue;
	} else if (convar == g_cvarRankbots) {
		g_bRankBots = g_cvarRankbots.BoolValue;
		g_bQueryPlayerCount = true;
	} else if (convar == g_cvarFfa) {
		g_bFfa = g_cvarFfa.BoolValue;
	} else if (convar == g_cvarPointsBombDefusedTeam) {
		g_PointsBombDefusedTeam = g_cvarPointsBombDefusedTeam.IntValue;
	} else if (convar == g_cvarPointsBombDefusedPlayer) {
		g_PointsBombDefusedPlayer = g_cvarPointsBombDefusedPlayer.IntValue;
	} else if (convar == g_cvarPointsBombPlantedTeam) {
		g_PointsBombPlantedTeam = g_cvarPointsBombPlantedTeam.IntValue;
	} else if (convar == g_cvarPointsBombPlantedPlayer) {
		g_PointsBombPlantedPlayer = g_cvarPointsBombPlantedPlayer.IntValue;
	} else if (convar == g_cvarPointsBombExplodeTeam) {
		g_PointsBombExplodeTeam = g_cvarPointsBombExplodeTeam.IntValue;
	} else if (convar == g_cvarPointsBombExplodePlayer) {
		g_PointsBombExplodePlayer = g_cvarPointsBombExplodePlayer.IntValue;
	} else if (convar == g_cvarPointsHostageRescTeam) {
		g_PointsHostageRescTeam = g_cvarPointsHostageRescTeam.IntValue;
	} else if (convar == g_cvarPointsHostageRescPlayer) {
		g_PointsHostageRescPlayer = g_cvarPointsHostageRescPlayer.IntValue;
	} else if (convar == g_cvarPointsHs) {
		g_PointsHs = g_cvarPointsHs.IntValue;
	} else if (convar == g_cvarPointsKillCt) {
		g_PointsKill[CT] = g_cvarPointsKillCt.IntValue;
	} else if (convar == g_cvarPointsKillTr) {
		g_PointsKill[TR] = g_cvarPointsKillTr.IntValue;
	} else if (convar == g_cvarPointsKillBonusCt) {
		g_PointsKillBonus[CT] = g_cvarPointsKillBonusCt.IntValue;
	} else if (convar == g_cvarPointsKillBonusTr) {
		g_PointsKillBonus[TR] = g_cvarPointsKillBonusTr.IntValue;
	} else if (convar == g_cvarPointsKillBonusDifCt) {
		g_PointsKillBonusDif[CT] = g_cvarPointsKillBonusDifCt.IntValue;
	} else if (convar == g_cvarPointsKillBonusDifTr) {
		g_PointsKillBonusDif[TR] = g_cvarPointsKillBonusDifTr.IntValue;
	} else if (convar == g_cvarPointsStart) {
		g_PointsStart = g_cvarPointsStart.IntValue;
	} else if (convar == g_cvarPointsKnifeMultiplier) {
		g_fPointsKnifeMultiplier = g_cvarPointsKnifeMultiplier.FloatValue;
	} else if (convar == g_cvarPointsTaserMultiplier) {
		g_fPointsTaserMultiplier = g_cvarPointsTaserMultiplier.FloatValue;
	} else if (convar == g_cvarPointsTrRoundWin) {
		g_PointsRoundWin[TR] = g_cvarPointsTrRoundWin.IntValue;
	} else if (convar == g_cvarPointsCtRoundWin) {
		g_PointsRoundWin[CT] = g_cvarPointsCtRoundWin.IntValue;
	} else if (convar == g_cvarPointsTrRoundLose) {
		g_PointsRoundLose[TR] = g_cvarPointsTrRoundLose.IntValue;
	} else if (convar == g_cvarPointsCtRoundLose) {
		g_PointsRoundLose[CT] = g_cvarPointsCtRoundLose.IntValue;
	} else if (convar == g_cvarMinimalKills) {
		g_MinimalKills = g_cvarMinimalKills.IntValue;
	} else if (convar == g_cvarPercentPointsLose) {
		g_fPercentPointsLose = g_cvarPercentPointsLose.FloatValue;
	} else if (convar == g_cvarPointsLoseRoundCeil) {
		g_bPointsLoseRoundCeil = g_cvarPointsLoseRoundCeil.BoolValue;
	} else if (convar == g_cvarMinimumPlayers) {
		g_MinimumPlayers = g_cvarMinimumPlayers.IntValue;
	} else if (convar == g_cvarResetOwnRank) {
		g_bResetOwnRank = g_cvarResetOwnRank.BoolValue;
	} else if (convar == g_cvarPointsVipEscapedTeam) {
		g_PointsVipEscapedTeam = g_cvarPointsVipEscapedTeam.IntValue;
	} else if (convar == g_cvarPointsVipEscapedPlayer) {
		g_PointsVipEscapedPlayer = g_cvarPointsVipEscapedPlayer.IntValue;
	} else if (convar == g_cvarPointsVipKilledTeam) {
		g_PointsVipKilledTeam = g_cvarPointsVipKilledTeam.IntValue;
	} else if (convar == g_cvarPointsVipKilledPlayer) {
		g_PointsVipKilledPlayer = g_cvarPointsVipKilledPlayer.IntValue;
	} else if (convar == g_cvarDaysToNotShowOnRank) {
		g_DaysToNotShowOnRank = g_cvarDaysToNotShowOnRank.IntValue;
		g_bQueryPlayerCount = true;
	} else if (convar == g_cvarGatherStats) {
		g_bGatherStats = g_cvarGatherStats.BoolValue;
	} else if (convar == g_cvarChatTriggers) {
		g_bChatTriggers = g_cvarChatTriggers.BoolValue;
	} else if (convar == g_cvarPointsMvpCt) {
		g_PointsMvpCt = g_cvarPointsMvpCt.IntValue;
	} else if (convar == g_cvarPointsMvpTr) {
		g_PointsMvpTr = g_cvarPointsMvpTr.IntValue;
	} else if (convar == g_cvarPointsBombPickup) {
		g_PointsBombDropped = g_cvarPointsBombPickup.IntValue;
	} else if (convar == g_cvarPointsBombDropped) {
		g_PointsBombDropped = g_cvarPointsBombDropped.IntValue;
	} else if (convar == g_cvarAnnounceConnect) {
		g_bAnnounceConnect = g_cvarAnnounceConnect.BoolValue;
	} else if (convar == g_cvarAnnounceConnectChat) {
		g_bAnnounceConnectChat = g_cvarAnnounceConnectChat.BoolValue;
	} else if (convar == g_cvarAnnounceConnectHint) {
		g_bAnnounceConnectHint = g_cvarAnnounceConnectHint.BoolValue;
	} else if (convar == g_cvarAnnounceDisconnect) {
		g_bAnnounceDisconnect = g_cvarAnnounceDisconnect.BoolValue;
	} else if (convar == g_cvarAnnounceTopConnect) {
		g_bAnnounceTopConnect = g_cvarAnnounceTopConnect.BoolValue;
	} else if (convar == g_cvarAnnounceTopPosConnect) {
		g_AnnounceTopPosConnect = g_cvarAnnounceTopPosConnect.IntValue;
	} else if (convar == g_cvarAnnounceTopConnectChat) {
		g_bAnnounceTopConnectChat = g_cvarAnnounceTopConnectChat.BoolValue;
	} else if (convar == g_cvarAnnounceTopConnectHint) {
		g_bAnnounceTopConnectHint = g_cvarAnnounceTopConnectHint.BoolValue;
	} else if (convar == g_cvarPointsAssistKill) {
		g_PointsAssistKill = g_cvarPointsAssistKill.IntValue;
	} else if (convar == g_cvarPointsMin) {
		g_PointsMin = g_cvarPointsMin.IntValue;
	} else if (convar == g_cvarPointsMinEnabled) {
		g_bPointsMinEnabled = g_cvarPointsMinEnabled.BoolValue;
	} else if (convar == g_cvarRankCache) {
		g_bRankCache = g_cvarRankCache.BoolValue;
	} else if (convar == g_cvarPointsMatchWin) {
		g_PointsMatchWin = g_cvarPointsMatchWin.IntValue;
	} else if (convar == g_cvarPointsMatchDraw) {
		g_PointsMatchDraw = g_cvarPointsMatchDraw.IntValue;
	} else if (convar == g_cvarPointsMatchLose) {
		g_PointsMatchLose = g_cvarPointsMatchLose.IntValue;
	} else if (convar == g_cvarPointsFb) {
		g_PointsFb = g_cvarPointsFb.IntValue;
	} else if (convar == g_cvarPointsNS) {
		g_PointsNS = g_cvarPointsNS.IntValue;
	} else if (convar == g_cvarNSAllSnipers) {
		g_bNSAllSnipers = g_cvarNSAllSnipers.BoolValue;
	}

	if (g_bQueryPlayerCount && g_hStatsDb != null) {
		char query[10000];
		MakeSelectQuery(query, sizeof(query));
		SQL_TQuery(g_hStatsDb, SQL_GetPlayersCallback, query);
	}
}

stock bool IsValidClient(int client, bool nobots = true) {
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client))) {
		return false;
	}

	return IsClientInGame(client);
}

stock void MakeSelectQuery(char[] sQuery, int strsize) {
	// Make basic query
	Format(sQuery, strsize, "SELECT * FROM `%s` WHERE kills >= '%d'", g_sSQLTable, g_MinimalKills);

	// Append check for bots
	if (!g_bShowBotsOnRank) {
		Format(sQuery, strsize, "%s AND steam <> 'BOT'", sQuery);
	}

	// Append check for inactivity
	if (g_DaysToNotShowOnRank > 0) {
		Format(sQuery, strsize, "%s AND lastconnect >= '%d'", sQuery, GetTime() - (g_DaysToNotShowOnRank * 86400));
	}
}

public Action LeagueRanking_OnPlayerLoaded(int client) {
	if (!g_bAnnounceConnect && !g_bAnnounceTopConnect) {
		return Plugin_Handled;
    }

	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return Plugin_Handled;
    }

	LeagueRanking_GetRank(client, RankConnectCallback);

	return Plugin_Continue;
}

public Action RankConnectCallback(int client, int rank, any data) {
	if (!g_bRankBots && (!IsValidClient(client) || IsFakeClient(client))) {
		return;
	}

	g_aPointsOnConnect[client] = LeagueRanking_GetPoints(client);

	g_aRankOnConnect[client] = rank;

	char sClientName[MAX_NAME_LENGTH];
	GetClientName(client,sClientName,sizeof(sClientName));

	char s_Country[32];
	char s_ip[32];
	GetClientIP(client, s_ip, 32);
	Format(s_Country, sizeof(s_Country), "Unknown");
	GeoipCountry(s_ip, s_Country, sizeof(s_Country));

	if (s_Country[0] == 0) {
		Format(s_Country, sizeof(s_Country), "Unknown", s_Country);
	} else if (StrContains(s_Country, "United", false) != -1 ||
        StrContains(s_Country, "Republic", false) != -1 ||
        StrContains(s_Country, "Federation", false) != -1 ||
        StrContains(s_Country, "Island", false) != -1 ||
        StrContains(s_Country, "Netherlands", false) != -1 ||
        StrContains(s_Country, "Isle", false) != -1 ||
        StrContains(s_Country, "Bahamas", false) != -1 ||
        StrContains(s_Country, "Maldives", false) != -1 ||
        StrContains(s_Country, "Philippines", false) != -1 ||
        StrContains(s_Country, "Vatican", false) != -1 ) {
        Format(s_Country, sizeof(s_Country), "The %s", s_Country);
    }

	if (g_bAnnounceConnect) {
		if (g_bAnnounceConnectChat) {
			CPrintToChatAll("%s %t",MSG,"PlayerJoinedChat",sClientName,g_aRankOnConnect[client],g_aPointsOnConnect[client],s_Country);
		}

		if (g_bAnnounceConnectHint) {
			PrintHintTextToAll("%t","PlayerJoinedHint",sClientName,g_aRankOnConnect[client],g_aPointsOnConnect[client],s_Country);
		}
	}

	if (g_bAnnounceTopConnect && rank <= g_AnnounceTopPosConnect) {
		if (g_bAnnounceTopConnectChat) {
			CPrintToChatAll("%s %t",MSG,"TopPlayerJoinedChat",g_AnnounceTopPosConnect,sClientName,g_aRankOnConnect[client],s_Country);
		}

		if (g_bAnnounceTopConnectHint) {
			PrintHintTextToAll("%t","TopPlayerJoinedHint",g_AnnounceTopPosConnect,sClientName,g_aRankOnConnect[client],s_Country);
		}
	}
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast) {
	if (!g_bAnnounceDisconnect) {
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !g_bRankBots) {
		return;
	}

	char sName[MAX_NAME_LENGTH];
	GetClientName(client,sName,MAX_NAME_LENGTH);
	strcopy(g_sBufferClientName[client],MAX_NAME_LENGTH,sName);

	g_aPointsOnDisconnect[client] = LeagueRanking_GetPoints(client);

	char disconnectReason[64];
	GetEventString(event, "reason", disconnectReason, sizeof(disconnectReason));

	CPrintToChatAll("%s %t",MSG,"PlayerLeft",g_sBufferClientName[client], g_aPointsOnDisconnect[client], disconnectReason);
}

public void OnGameFrame() {
    if (GameRules_GetProp("m_bWarmupPeriod") == 1) {
        //In Warmup
        g_bGatherStats = false;
    } else {
        //Not in warmup
        g_bGatherStats = true;
    }
}

public Action Event_WinPanelMatch(Handle event, const char[] name, bool dontBroadcast) {
	if (CS_GetTeamScore(CT) > CS_GetTeamScore(TR)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				if (GetClientTeam(i) == TR) {
					g_aStats[i][MATCH_LOSE]++;
					g_aStats[i][SCORE] -= g_PointsMatchLose;
				} else if (GetClientTeam(i) == CT) {
					g_aStats[i][MATCH_WIN]++;
					g_aStats[i][SCORE] += g_PointsMatchWin;
				}
			}
		}
	} else if (CS_GetTeamScore(CT) == CS_GetTeamScore(TR)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && (GetClientTeam(i) == TR || GetClientTeam(i) == CT)) {
				g_aStats[i][MATCH_DRAW]++;
				g_aStats[i][SCORE] += g_PointsMatchDraw;
			}
		}
	} else if (CS_GetTeamScore(CT) < CS_GetTeamScore(TR)) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i)) {
				if (GetClientTeam(i) == TR) {
					g_aStats[i][MATCH_WIN]++;
					g_aStats[i][SCORE] += g_PointsMatchWin;
				} else if (GetClientTeam(i) == CT) {
					g_aStats[i][MATCH_LOSE]++;
					g_aStats[i][SCORE] -= g_PointsMatchLose;
				}
			}
		}
	}
}

void CreateCvars()
{
    // CVARs
    g_cvarEnabled = CreateConVar("league_ranking_enabled", "1", "Is ranking enabled? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarRankbots = CreateConVar("league_ranking_rankbots", "0", "Rank bots? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarAutopurge = CreateConVar("league_ranking_autopurge", "0", "Auto-Purge inactive players? X = Days  0 = Off", _, true, 0.0);
    g_cvarPointsBombDefusedTeam = CreateConVar("league_ranking_points_bomb_defused_team", "2", "How many points CTs got for defusing the C4?", _, true, 0.0);
    g_cvarPointsBombDefusedPlayer = CreateConVar("league_ranking_points_bomb_defused_player", "2", "How many points the CT who defused got additional?", _, true, 0.0);
    g_cvarPointsBombPlantedTeam = CreateConVar("league_ranking_points_bomb_planted_team", "2", "How many points TRs got for planting the C4?", _, true, 0.0);
    g_cvarPointsBombPlantedPlayer = CreateConVar("league_ranking_points_bomb_planted_player", "2", "How many points the TR who planted got additional?", _, true, 0.0);
    g_cvarPointsBombExplodeTeam = CreateConVar("league_ranking_points_bomb_exploded_team", "2", "How many points TRs got for exploding the C4?", _, true, 0.0);
    g_cvarPointsBombExplodePlayer = CreateConVar("league_ranking_points_bomb_exploded_player", "2", "How many points the TR who planted got additional?", _, true, 0.0);
    g_cvarPointsHostageRescTeam = CreateConVar("league_ranking_points_hostage_rescued_team", "2", "How many points CTs got for rescuing the hostage?", _, true, 0.0);
    g_cvarPointsHostageRescPlayer = CreateConVar("league_ranking_points_hostage_rescued_player", "2", "How many points the CT who rescued got additional?", _, true, 0.0);
    g_cvarPointsHs = CreateConVar("league_ranking_points_hs", "1", "How many additional points a player got for a HeadShot?", _, true, 0.0);
    g_cvarPointsKillCt = CreateConVar("league_ranking_points_kill_ct", "2", "How many points a CT got for killing?", _, true, 0.0);
    g_cvarPointsKillTr = CreateConVar("league_ranking_points_kill_tr", "2", "How many points a TR got for killing?", _, true, 0.0);
    g_cvarPointsKillBonusCt = CreateConVar("league_ranking_points_kill_bonus_ct", "1", "How many points a CT got for killing additional by the difference of points?", _, true, 0.0);
    g_cvarPointsKillBonusTr = CreateConVar("league_ranking_points_kill_bonus_tr", "1", "How many points a TR got for killing additional by the difference of points?", _, true, 0.0);
    g_cvarPointsKillBonusDifCt = CreateConVar("league_ranking_points_kill_bonus_dif_ct", "100", "How many points of difference is needed for a CT to got the bonus?", _, true, 0.0);
    g_cvarPointsKillBonusDifTr = CreateConVar("league_ranking_points_kill_bonus_dif_tr", "100", "How many points of difference is needed for a TR to got the bonus?", _, true, 0.0);
    g_cvarPointsCtRoundWin = CreateConVar("league_ranking_points_ct_round_win", "0", "How many points CT got for winning the round?", _, true, 0.0);
    g_cvarPointsTrRoundWin = CreateConVar("league_ranking_points_tr_round_win", "0", "How many points TR got for winning the round?", _, true, 0.0);
    g_cvarPointsCtRoundLose = CreateConVar("league_ranking_points_ct_round_lose", "0", "How many points CT lost for losing the round?", _, true, 0.0);
    g_cvarPointsTrRoundLose = CreateConVar("league_ranking_points_tr_round_lose", "0", "How many points TR lost for losing the round?", _, true, 0.0);
    g_cvarPointsKnifeMultiplier = CreateConVar("league_ranking_points_knife_multiplier", "2.0", "Multiplier of points by knife", _, true, 0.0);
    g_cvarPointsTaserMultiplier = CreateConVar("league_ranking_points_taser_multiplier", "2.0", "Multiplier of points by taser", _, true, 0.0);
    g_cvarPointsStart = CreateConVar("league_ranking_points_start", "1000", "Starting points", _, true, 0.0);
    g_cvarMinimalKills = CreateConVar("league_ranking_minimal_kills", "0", "Minimal kills for entering the rank", _, true, 0.0);
    g_cvarPercentPointsLose = CreateConVar("league_ranking_percent_points_lose", "1.0", "Multiplier of losing points. (WARNING: MAKE SURE TO INPUT IT AS FLOAT) 1.0 equals lose same amount as won by the killer, 0.0 equals no lose", _, true, 0.0);
    g_cvarPointsLoseRoundCeil = CreateConVar("league_ranking_points_lose_round_ceil", "1", "If the points is f1oat, round it to next the highest or lowest? 1 = highest 0 = lowest", _, true, 0.0, true, 1.0);
    g_cvarChatChange = CreateConVar("league_ranking_changes_chat", "1", "Show points changes on chat? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarShowRankAll = CreateConVar("league_ranking_show_rank_all", "0", "When rank command is used, show for all the rank of the player? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarRankAllTimer = CreateConVar("league_ranking_rank_all_timer", "30.0", "Cooldown timer to prevent rank command spam.\n0.0 = disabled", _, true, 0.0);
    g_cvarShowBotsOnRank = CreateConVar("league_ranking_show_bots_on_rank", "0", "Show bots on rank/top/etc? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarResetOwnRank = CreateConVar("league_ranking_resetownrank", "0", "Allow player to reset his own rank? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarMinimumPlayers = CreateConVar("league_ranking_minimumplayers", "2", "Minimum players to start giving points", _, true, 0.0);
    g_cvarVipEnabled = CreateConVar("league_ranking_vip_enabled", "0", "Show AS_ maps statistics (VIP mod) on statsme and session?", _, true, 0.0, true, 1.0);
    g_cvarPointsVipEscapedTeam = CreateConVar("league_ranking_points_vip_escaped_team", "2", "How many points CTs got helping the VIP to escaping?", _, true, 0.0);
    g_cvarPointsVipEscapedPlayer = CreateConVar("league_ranking_points_vip_escaped_player", "2", "How many points the VIP got for escaping?", _, true, 0.0);
    g_cvarPointsVipKilledTeam = CreateConVar("league_ranking_points_vip_killed_team", "2", "How many points TRs got for killing the VIP?", _, true, 0.0);
    g_cvarPointsVipKilledPlayer = CreateConVar("league_ranking_points_vip_killed_player", "2", "How many points the TR who killed the VIP got additional?", _, true, 0.0);
    g_cvarPointsLoseTk = CreateConVar("league_ranking_points_lose_tk", "0", "How many points a player lose for Team Killing?", _, true, 0.0);
    g_cvarPointsLoseSuicide = CreateConVar("league_ranking_points_lose_suicide", "0", "How many points a player lose for Suiciding?", _, true, 0.0);
    g_cvarPointsFb = CreateConVar("league_ranking_points_fb", "1", "How many additional points a player got for a First Blood?", _, true, 0.0);
    g_cvarPointsNS = CreateConVar("league_ranking_points_ns", "1", "How many additional points a player got for a no scope kill?", _, true, 0.0);
    g_cvarNSAllSnipers = CreateConVar("league_ranking_points_ns_allsnipers", "0", "0: ssg08 and awp only, 1: ssg08, awp, g3sg1, scar20", _, true, 0.0, true, 1.0);
    g_cvarFfa = CreateConVar("league_ranking_ffa", "0", "Free-For-All (FFA) mode? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarGatherStats = CreateConVar("league_ranking_gather_stats", "1", "Gather Statistics (a.k.a count points)? (turning this off won't disallow to see the stats already gathered) 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarDaysToNotShowOnRank = CreateConVar("league_ranking_days_to_not_show_on_rank", "0", "Days inactive to not be shown on rank? X = days 0 = off", _, true, 0.0);
    g_cvarSQLTable = CreateConVar("league_ranking_sql_table", "rankme", "The name of the table that will be used. (Max: 100)");
    g_cvarChatTriggers = CreateConVar("league_ranking_chat_triggers", "1", "Enable (non-command) chat triggers. (e.g: rank, statsme, top) Recommended to be set to 0 when running with EventScripts for avoiding double responses. 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarPointsMvpCt = CreateConVar("league_ranking_points_mvp_ct", "1", "How many points a CT got for being the MVP?", _, true, 0.0);
    g_cvarPointsMvpTr = CreateConVar("league_ranking_points_mvp_tr", "1", "How many points a TR got for being the MVP?", _, true, 0.0);
    g_cvarPointsBombPickup = CreateConVar("league_ranking_points_bomb_pickup", "0", "How many points a player gets for picking up the bomb?", _, true, 0.0);
    g_cvarPointsBombDropped = CreateConVar("league_ranking_points_bomb_dropped", "0", "How many points a player loess for dropping the bomb?", _, true, 0.0);
    g_cvarPointsMatchWin = CreateConVar("league_ranking_points_match_win", "2", "How many points a player win for winning the match?", _, true, 0.0);
    g_cvarPointsMatchLose = CreateConVar("league_ranking_points_match_lose", "2", "How many points a player loess for losing the match?", _, true, 0.0);
    g_cvarPointsMatchDraw = CreateConVar("league_ranking_points_match_draw", "0", "How many points a player win when match draw?", _, true, 0.0);
    g_cvarPointsAssistKill = CreateConVar("league_ranking_points_assist_kill","1","How many points a player gets for assist kill?",_,true,0.0);
    g_cvarPointsMinEnabled = CreateConVar("league_ranking_points_min_enabled", "1", "Is minimum points enabled? 1 = true 0 = false", _, true, 0.0, true, 1.0);
    g_cvarPointsMin = CreateConVar("league_ranking_points_min", "0", "Minimum points", _, true, 0.0);
    g_cvarRankCache = CreateConVar("league_ranking_rank_cache", "0", "Get player rank via cache, auto build cache on every OnMapStart.", _, true, 0.0, true, 1.0);
    g_cvarAnnounceConnect = CreateConVar("league_ranking_announcer_player_connect","1","Announce when a player connect with position and points?",_,true,0.0,true,1.0);
    g_cvarAnnounceConnectChat = CreateConVar("league_ranking_announcer_player_connect_chat","1","Announce when a player connect at chat?",_,true,0.0,true,1.0);
    g_cvarAnnounceConnectHint = CreateConVar("league_ranking_announcer_player_connect_hint","0","Announce when a player connect at hintbox?",_,true,0.0,true,1.0);
    g_cvarAnnounceDisconnect = CreateConVar("league_ranking_announcer_player_disconnect","1","Announce when a player disconnect with position and points?",_,true,0.0,true,1.0);
    g_cvarAnnounceTopConnect = CreateConVar("league_ranking_announcer_top_player_connect","1","Announce when a top player connect?",_,true,0.0,true,1.0);
    g_cvarAnnounceTopPosConnect = CreateConVar("league_ranking_announcer_top_pos_player_connect","10","Max position to announce that a top player connect?",_,true,0.0);
    g_cvarAnnounceTopConnectChat = CreateConVar("league_ranking_announcer_top_player_connect_chat","1","Announce when a top player connect at chat?",_,true,0.0,true,1.0);
    g_cvarAnnounceTopConnectHint = CreateConVar("league_ranking_announcer_top_player_connect_hint","0","Announce when a top player connect at hintbox?",_,true,0.0,true,1.0);
}

void AddCvarListeners()
{
    // CVAR HOOK
	g_cvarEnabled.AddChangeHook(OnConVarChanged);
	g_cvarChatChange.AddChangeHook(OnConVarChanged);
	g_cvarShowBotsOnRank.AddChangeHook(OnConVarChanged);
	g_cvarShowRankAll.AddChangeHook(OnConVarChanged);
	g_cvarRankAllTimer.AddChangeHook(OnConVarChanged);
	g_cvarResetOwnRank.AddChangeHook(OnConVarChanged);
	g_cvarMinimumPlayers.AddChangeHook(OnConVarChanged);
	g_cvarRankbots.AddChangeHook(OnConVarChanged);
	g_cvarAutopurge.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombDefusedTeam.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombDefusedPlayer.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombPlantedTeam.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombPlantedPlayer.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombExplodeTeam.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombExplodePlayer.AddChangeHook(OnConVarChanged);
	g_cvarPointsHostageRescTeam.AddChangeHook(OnConVarChanged);
	g_cvarPointsHostageRescPlayer.AddChangeHook(OnConVarChanged);
	g_cvarPointsHs.AddChangeHook(OnConVarChanged);
	g_cvarPointsKillCt.AddChangeHook(OnConVarChanged);
	g_cvarPointsKillTr.AddChangeHook(OnConVarChanged);
	g_cvarPointsKillBonusCt.AddChangeHook(OnConVarChanged);
	g_cvarPointsKillBonusTr.AddChangeHook(OnConVarChanged);
	g_cvarPointsKillBonusDifCt.AddChangeHook(OnConVarChanged);
	g_cvarPointsKillBonusDifTr.AddChangeHook(OnConVarChanged);
	g_cvarPointsCtRoundWin.AddChangeHook(OnConVarChanged);
	g_cvarPointsTrRoundWin.AddChangeHook(OnConVarChanged);
	g_cvarPointsCtRoundLose.AddChangeHook(OnConVarChanged);
	g_cvarPointsTrRoundLose.AddChangeHook(OnConVarChanged);
	g_cvarPointsKnifeMultiplier.AddChangeHook(OnConVarChanged);
	g_cvarPointsTaserMultiplier.AddChangeHook(OnConVarChanged);
	g_cvarPointsStart.AddChangeHook(OnConVarChanged);
	g_cvarMinimalKills.AddChangeHook(OnConVarChanged);
	g_cvarPercentPointsLose.AddChangeHook(OnConVarChanged);
	g_cvarPointsLoseRoundCeil.AddChangeHook(OnConVarChanged);
	g_cvarVipEnabled.AddChangeHook(OnConVarChanged);
	g_cvarPointsVipEscapedTeam.AddChangeHook(OnConVarChanged);
	g_cvarPointsVipEscapedPlayer.AddChangeHook(OnConVarChanged);
	g_cvarPointsVipKilledTeam.AddChangeHook(OnConVarChanged);
	g_cvarPointsVipKilledPlayer.AddChangeHook(OnConVarChanged);
	g_cvarPointsLoseTk.AddChangeHook(OnConVarChanged);
	g_cvarPointsLoseSuicide.AddChangeHook(OnConVarChanged);
	g_cvarFfa.AddChangeHook(OnConVarChanged);
	g_cvarGatherStats.AddChangeHook(OnConVarChanged);
	g_cvarDaysToNotShowOnRank.AddChangeHook(OnConVarChanged);
	g_cvarSQLTable.AddChangeHook(OnConVarChanged_SQLTable);
	g_cvarChatTriggers.AddChangeHook(OnConVarChanged);
	g_cvarPointsMvpCt.AddChangeHook(OnConVarChanged);
	g_cvarPointsMvpTr.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombPickup.AddChangeHook(OnConVarChanged);
	g_cvarPointsBombDropped.AddChangeHook(OnConVarChanged);
	g_cvarPointsMatchWin.AddChangeHook(OnConVarChanged);
	g_cvarPointsMatchDraw.AddChangeHook(OnConVarChanged);
	g_cvarPointsMatchLose.AddChangeHook(OnConVarChanged);
	g_cvarPointsFb.AddChangeHook(OnConVarChanged);
	g_cvarPointsNS.AddChangeHook(OnConVarChanged);
	g_cvarNSAllSnipers.AddChangeHook(OnConVarChanged);
	g_cvarPointsAssistKill.AddChangeHook(OnConVarChanged);
	g_cvarPointsMinEnabled.AddChangeHook(OnConVarChanged);
	g_cvarPointsMin.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceConnect.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceConnectChat.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceConnectHint.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceDisconnect.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceTopConnect.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceTopPosConnect.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceTopConnectChat.AddChangeHook(OnConVarChanged);
	g_cvarAnnounceTopConnectHint.AddChangeHook(OnConVarChanged);
}