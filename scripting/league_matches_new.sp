#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <SteamWorks>
#include <smjansson>
#include <get5>

#pragma semicolon 1
#pragma newdecls required

#define PREFIX "[\x04League\x01]"

Database g_Database = null;

int g_iShotsFired[MAXPLAYERS + 1] = 0;
int g_iShotsHit[MAXPLAYERS + 1] = 0;
int g_iHeadshots[MAXPLAYERS + 1] = 0;
int g_iMatchID;

ConVar g_CVDiscordWebhook;
ConVar g_CVSiteURL;
ConVar g_CVEmbedColour;
ConVar g_CVEmbedAvatar;
ConVar g_CVApiKey;

ArrayList ga_sWinningPlayers;
ArrayList ga_iEndMatchVotesT;
ArrayList ga_iEndMatchVotesCT;

enum AllowedTeamStatus {
	NOT_AUTHORIZED = 0,
	TEAM_SPEC,
	TEAM_T,
	TEAM_CT,
	TEAM_ANY
};

AllowedTeamStatus g_eAllowedTeam[MAXPLAYERS + 1] = NOT_AUTHORIZED;

public Plugin myinfo = {
	name = "League Matches",
	author = "The Doggy, B3none",
	description = "League scoreboard saving system.",
	version = "2.0.0",
	url = "https://github.com/csgo-league"
};

public void OnPluginStart() {
	// Create Timer
	CreateTimer(1.0, AttemptMySQLConnection);

	// Hook Events
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("weapon_fire", Event_WeaponFired);
	HookEvent("player_hurt", Event_PlayerHurt);

	// ConVars
	g_CVDiscordWebhook = CreateConVar("sm_discord_webhook", "", "Discord web hook endpoint", FCVAR_PROTECTED);
	g_CVSiteURL = CreateConVar("league_matches_site_url", "", "Website url for viewing scores", FCVAR_PROTECTED);
	g_CVEmbedColour = CreateConVar("league_matches_embed_color", "16741688", "Color to use for webhook (Must be decimal value)", FCVAR_PROTECTED);
	g_CVEmbedAvatar = CreateConVar("league_matches_embed_avatar", "https://i.imgur.com/Y0J4yzv.png", "Avatar to use for webhook", FCVAR_PROTECTED);
	g_CVApiKey = CreateConVar("league_matches_api_key", "{apikey}", "api key (braces are needed probably, maybe)", FCVAR_PROTECTED);

	// Initialise ArrayLists
	ga_sWinningPlayers = new ArrayList(64);
	ga_iEndMatchVotesT = new ArrayList();
	ga_iEndMatchVotesCT = new ArrayList();

	// Register Command
	RegConsoleCmd("sm_gg", Command_EndMatch, "Ends the match once everyone on the team has used it.");

	// Register Command Listeners
	AddCommandListener(Command_JoinTeam, "jointeam");
	AddCommandListener(Command_JoinTeam, "joingame");
}

public void OnMapStart() {
	ga_iEndMatchVotesT.Clear();
	ga_iEndMatchVotesCT.Clear();

	if (Get5_GetGameState() != Get5State_None) {
		ServerCommand("get5_endmatch");
    }
}

public void ResetVars(int client) {
	if (!IsValidClient(client)) {
	    return;
	}

	g_iShotsFired[Client] = 0;
	g_iShotsHit[Client] = 0;
	g_iHeadshots[Client] = 0;
}

public Action AttemptMySQLConnection(Handle timer) {
	if (g_Database != null) {
		delete g_Database;
		g_Database = null;
	}

	if (SQL_CheckConfig("league")) {
		PrintToServer("Initialising Connection to MySQL Database");
		Database.Connect(SQL_InitialConnection, "sql_matches");
	} else {
	    char sFolder[32];
        GetGameFolderName(sFolder, sizeof(sFolder));

		LogError("Database Error: No Database Config Found! (%s/addons/sourcemod/configs/databases.cfg)", sFolder);
    }
}

public void SQL_InitialConnection(Database db, const char[] sError, int data) {
	if (db == null) {
		LogMessage("Database Error: %s", sError);
		CreateTimer(10.0, AttemptMySQLConnection);
		return;
	}

	char sDriver[16];
	db.Driver.GetIdentifier(sDriver, sizeof(sDriver));
	if (StrEqual(sDriver, "mysql", false)) {
	    LogMessage("MySQL Database: connected");
	}

	g_Database = db;
	CreateAndVerifySQLTables();
}

public void CreateAndVerifySQLTables() {
	char sQuery[1024] = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS sql_matches_scoretotal (");
	StrCat(sQuery, 1024, "match_id INTEGER NOT NULL AUTO_INCREMENT, ");
	StrCat(sQuery, 1024, "timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, ");
	StrCat(sQuery, 1024, "live INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "team_t INTEGER NOT NULL, "); // Original plugin had 4 teams listed here but we only want CT / T so I'm just gonna stick with that
	StrCat(sQuery, 1024, "team_ct INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "map VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "server VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(match_id));");
	g_Database.Query(SQL_GenericQuery, sQuery);

	sQuery = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS sql_matches (");
	StrCat(sQuery, 1024, "match_id INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "name VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "steamid64 VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "team INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "alive INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "ping INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "account INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "kills INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "assists INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "deaths INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "mvps INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "score INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "disconnected INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "shots_fired INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "shots_hit INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "headshots INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(match_id, steamid64), ");
	StrCat(sQuery, 1024, "FOREIGN KEY(match_id) REFERENCES sql_matches_scoretotal(match_id));");
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public void OnClientAuthorized(int client, const char[] AuthID) {
	if (!IsClientConnected(client) || IsFakeClient(client)) {
	    return;
	}

	char sSteamID64[64], sQuery[1024];
	GetClientAuthId(Client, AuthId_SteamID64, sSteamID64, sizeof(sSteamID64));

	Format(sQuery, sizeof(sQuery), "SELECT a.live, b.team FROM sql_matches_scoretotal AS a INNER JOIN ( SELECT match_id, team FROM sql_matches WHERE steamid64='%s' GROUP BY match_id ) AS b ON a.match_id=b.match_id;", sSteamID64);
	g_Database.Query(SQL_LoadTeamStatus, sQuery, GetClientUserId(client));
}

public void SQL_LoadTeamStatus(Database db, DBResultSet results, const char[] sError, any userID) {
	int client = GetClientOfUserId(userID);

	if (client == 0 || !IsClientConnected(client) || IsFakeClient(client)) {
	    return;
	}

	if (results == null) {
		PrintToServer("MySQL Query Failed: %s", sError);
		LogError("MySQL Query Failed: %s", sError);
		return;
	}

	if (!results.FetchRow()) {
		g_eAllowedTeam[Client] = TEAM_ANY;
		return;
	}

	int liveCol, teamCol;
	results.FieldNameToNum("live", liveCol);

	do {
		// Is the player currently in a live match?
		if (results.FetchInt(liveCol) == 1) {
			results.FieldNameToNum("team", teamCol);
			g_eAllowedTeam[Client] = view_as<AllowedTeamStatus>(results.FetchInt(teamCol));
			return;
		}
	} while (results.FetchRow());

	// If we get to here then all the matches the player has been in are not live anymore
	g_eAllowedTeam[Client] = TEAM_ANY;
}

public void Get5_OnGameStateChanged(Get5State oldState, Get5State newState) {
	if (oldState == Get5State_GoingLive && newState == Get5State_Live) {
		char sQuery[1024], sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i, true)) {
				ResetVars(i);
            }
        }

		int ip[4];
		char pieces[4][8], sIP[32], sPort[32];
		FindConVar("hostport").GetString(sPort, sizeof(sPort));
		SteamWorks_GetPublicIP(ip);

		IntToString(ip[0], pieces[0], sizeof(pieces[]));
		IntToString(ip[1], pieces[1], sizeof(pieces[]));
		IntToString(ip[2], pieces[2], sizeof(pieces[]));
		IntToString(ip[3], pieces[3], sizeof(pieces[]));
		Format(sIP, sizeof(sIP), "%s.%s.%s.%s:%s", pieces[0], pieces[1], pieces[2], pieces[3], sPort);

		Format(sQuery, sizeof(sQuery), "INSERT INTO sql_matches_scoretotal (team_t, team_ct, map, live, server) VALUES (%i, %i, '%s', 1, '%s');", CS_GetTeamScore(CS_TEAM_T), CS_GetTeamScore(CS_TEAM_CT), sMap, sIP);
		g_Database.Query(SQL_InitialInsert, sQuery);
		UpdatePlayerStats();
	}
}

public void SQL_InitialInsert(Database db, DBResultSet results, const char[] sError, any data) {
	if (results == null) {
		PrintToServer("MySQL Query Failed: %s", sError);
		LogError("MySQL Query Failed: %s", sError);
		return;
	}

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "SELECT LAST_INSERT_ID() as ID;");
	g_Database.Query(SQL_MatchIDQuery, sQuery);
}
public void SQL_MatchIDQuery(Database db, DBResultSet results, const char[] sError, any data) {
	if (results == null) {
		PrintToServer("Fetching Match ID Failed due to Error: %s");
		LogError("Fetching Match ID Failed due to Error: %s");
		return;
	}

	if (!results.FetchRow()) {
		LogError("Retrieving Match ID returned no rows.");
		return;
	}

	int iCol;
	results.FieldNameToNum("ID", iCol);
	g_iMatchID = results.FetchInt(iCol);
}

public void Get5_OnMapResult(const char[] map, MatchTeam mapWinner, int team1Score, int team2Score, int mapNumber) {
	static float fTime;
	if (GetGameTime() - fTime < 1.0) {
	    return;
	}
	fTime = GetGameTime();

	UpdatePlayerStats();
	UpdateMatchStats();
	SendReport();
	SendMatchEndRequest();

	CreateTimer(10.0, Timer_KickEveryoneEnd); // Delay kicking everyone so they can see the chat message and so the plugin has time to update their stats

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "UPDATE sql_matches_scoretotal SET live=0 WHERE match_id=LAST_INSERT_ID();");
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public Action Command_JoinTeam(int client, char[] sCommand, int iArgs) {
	if (!IsValidClient(client) || Get5_GetGameState() == Get5State_GoingLive) {
	    return Plugin_Handled;
	}

	if (Get5_GetGameState() != Get5State_Live) {
	    return Plugin_Continue;
	}

	if (g_eAllowedTeam[Client] == NOT_AUTHORIZED) {
		PrintToChat(Client, "%s Your team authorization status is still loading. Please try again in a moment.", PREFIX);
		return Plugin_Handled;
	}

	if (GetClientTeam(client) == 1 || GetClientTeam(client) == 2 || GetClientTeam(client) == 3) {
	    return Plugin_Handled;
	}

	char sTeamName[32];
	GetCmdArg(1, sTeamName, sizeof(sTeamName)); // Get Team Name
	int iTeam = StringToInt(sTeamName);

	if (iTeam == 0 && g_eAllowedTeam[Client] != TEAM_ANY) {
	    // Auto join
		return Plugin_Handled;
	} else if (iTeam == 1 && (g_eAllowedTeam[Client] != TEAM_ANY && g_eAllowedTeam[Client] != TEAM_SPEC)) {
		return Plugin_Handled;
	} else if (iTeam == 2 && (g_eAllowedTeam[Client] != TEAM_ANY && g_eAllowedTeam[Client] != TEAM_T)) {
		return Plugin_Handled;
	} else if (iTeam == 3 && (g_eAllowedTeam[Client] != TEAM_ANY && g_eAllowedTeam[Client] != TEAM_CT)) {
		return Plugin_Handled;
	} else {
		CS_SwitchTeam(Client, iTeam);
		return Plugin_Continue;
	}
}

public Action Command_JoinGame(int client, char[] sCommand, int iArgs) {
	return Plugin_Handled;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	UpdatePlayerStats(false, GetClientOfUserId(event.GetInt("userid")));
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	UpdateMatchStats(true);
	UpdatePlayerStats();
	CheckSurrenderVotes();
}

void UpdatePlayerStats(bool allPlayers = true, int client = 0)
{
	if (Get5_GetGameState() != Get5State_Live) {
	    return;
	}

	char sQuery[1024], sName[64], sSteamID[64];
	int iEnt, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore;
	iEnt = FindEntityByClassname(-1, "cs_player_manager");

	if (allPlayers) {
		Transaction txn_UpdateStats = new Transaction();

		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidClient(i, true)) {
			    continue;
			}

			iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeam", _, i);
			iAlive = GetEntProp(iEnt, Prop_Send, "m_bAlive", _, i);
			iPing = GetEntProp(iEnt, Prop_Send, "m_iPing", _, i);
			iAccount = GetEntProp(i, Prop_Send, "m_iAccount");
			iKills = GetEntProp(iEnt, Prop_Send, "m_iKills", _, i);
			iAssists = GetEntProp(iEnt, Prop_Send, "m_iAssists", _, i);
			iDeaths = GetEntProp(iEnt, Prop_Send, "m_iDeaths", _, i);
			iMVPs = GetEntProp(iEnt, Prop_Send, "m_iMVPs", _, i);
			iScore = GetEntProp(iEnt, Prop_Send, "m_iScore", _, i);

			GetClientName(i, sName, sizeof(sName));
			g_Database.Escape(sName, sName, sizeof(sName));

			GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

			int len = 0;
			len += Format(sQuery[len], sizeof(sQuery) - len, "INSERT IGNORE INTO sql_matches (match_id, name, steamid64, team, alive, ping, account, kills, assists, deaths, mvps, score, disconnected, shots_fired, shots_hit, headshots) ");
			len += Format(sQuery[len], sizeof(sQuery) - len, "VALUES (LAST_INSERT_ID(), '%s', '%s', %i, %i, %i, %i, %i, %i, %i, %i, %i, 0, %i, %i, %i) ", sName, sSteamID, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore, g_iShotsFired[i], g_iShotsHit[i], g_iHeadshots[i]);
			len += Format(sQuery[len], sizeof(sQuery) - len, "ON DUPLICATE KEY UPDATE name='%s', team=%i, alive=%i, ping=%i, account=%i, kills=%i, assists=%i, deaths=%i, mvps=%i, score=%i, disconnected=0, shots_fired=%i, shots_hit=%i, headshots=%i;", sName, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore, g_iShotsFired[i], g_iShotsHit[i], g_iHeadshots[i]);
			txn_UpdateStats.AddQuery(sQuery);
		}
		g_Database.Execute(txn_UpdateStats, SQL_TranSuccess, SQL_TranFailure);
		return;
	}

	if (!IsValidClient(Client, true)) {
	    return;
	}

	iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeam", _, Client);
	iAlive = GetEntProp(iEnt, Prop_Send, "m_bAlive", _, Client);
	iPing = GetEntProp(iEnt, Prop_Send, "m_iPing", _, Client);
	iAccount = GetEntProp(Client, Prop_Send, "m_iAccount");
	iKills = GetEntProp(iEnt, Prop_Send, "m_iKills", _, Client);
	iAssists = GetEntProp(iEnt, Prop_Send, "m_iAssists", _, Client);
	iDeaths = GetEntProp(iEnt, Prop_Send, "m_iDeaths", _, Client);
	iMVPs = GetEntProp(iEnt, Prop_Send, "m_iMVPs", _, Client);
	iScore = GetEntProp(iEnt, Prop_Send, "m_iScore", _, Client);

	GetClientName(Client, sName, sizeof(sName));
	g_Database.Escape(sName, sName, sizeof(sName));

	GetClientAuthId(Client, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

	int len = 0;
	len += Format(sQuery[len], sizeof(sQuery) - len, "INSERT IGNORE INTO sql_matches (match_id, name, steamid64, team, alive, ping, account, kills, assists, deaths, mvps, score, disconnected, shots_fired, shots_hit, headshots) ");
	len += Format(sQuery[len], sizeof(sQuery) - len, "VALUES (LAST_INSERT_ID(), '%s', '%s', %i, %i, %i, %i, %i, %i, %i, %i, %i, 0, %i, %i, %i) ", sName, sSteamID, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore, g_iShotsFired[Client], g_iShotsHit[Client], g_iHeadshots[Client]);
	len += Format(sQuery[len], sizeof(sQuery) - len, "ON DUPLICATE KEY UPDATE name='%s', team=%i, alive=%i, ping=%i, account=%i, kills=%i, assists=%i, deaths=%i, mvps=%i, score=%i, disconnected=0, shots_fired=%i, shots_hit=%i, headshots=%i;", sName, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore, g_iShotsFired[Client], g_iShotsHit[Client], g_iHeadshots[Client]);
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public void SQL_TranSuccess(Database db, any data, int numQueries, Handle[] results, any[] queryData) {
	PrintToServer("Transaction Successful");
}

public void SQL_TranFailure(Database db, any data, int numQueries, const char[] sError, int failIndex, any[] queryData) {
	LogError("Transaction Failed! Error: %s. During Query: %i", sError, failIndex);
}

void UpdateMatchStats(bool duringMatch = false) {
	if (duringMatch && Get5_GetGameState() != Get5State_Live) {
	    return;
	}

	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "UPDATE sql_matches_scoretotal SET team_t=%i, team_ct=%i, live=%i WHERE match_id=LAST_INSERT_ID();", CS_GetTeamScore(CS_TEAM_T), CS_GetTeamScore(CS_TEAM_CT), Get5_GetGameState() == Get5State_Live);
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public Action Command_EndMatch(int client, int iArgs) {
	if (!IsValidClient(Client, true) || Get5_GetGameState() != Get5State_Live) {
	    return Plugin_Handled;
	}

	int iTeam = GetClientTeam(client);

	if (iTeam == CS_TEAM_T) {
        // Check if CT is 8 or more rounds ahead of T
		if (CS_GetTeamScore(CS_TEAM_CT) - 8 >= CS_GetTeamScore(iTeam)) {
		    // Check if client has already voted to surrender
			if (ga_iEndMatchVotesT.FindValue(client) == -1) {
				ga_iEndMatchVotesT.Push(client); // Add client to ArrayList

				int iTeamCount = GetTeamClientCount(iTeam);

				// Check if we have the amount of votes needed to surrender
				if (ga_iEndMatchVotesT.Length >= iTeamCount) {
					for (int i = 1; i <= MaxClients; i++) {
						if (IsValidClient(i, true) && GetClientTeam(i) == iTeam) {
							PrintToChat(i, "%s Terrorists have voted to surrender. Match ending...", PREFIX);
                        }
					}

					ServerCommand("get5_endmatch"); // Force end the match
					CreateTimer(10.0, Timer_KickEveryoneSurrender); // Delay kicking everyone so they can see the chat message and so the plugin has time to update their stats
					ga_iEndMatchVotesT.Clear(); // Reset the ArrayList
				} else {
					for (int i = 1; i <= MaxClients; i++) {
						if (IsValidClient(i, true) && GetClientTeam(i) == iTeam) {
							PrintToChat(i, "%s %N has voted to surrender, %i/%i votes needed.", PREFIX, Client, ga_iEndMatchVotesT.Length, iTeamCount);
                        }
					}
				}
			} else {
			    PrintToChat(Client, "%s You've already voted to surrender!", PREFIX);
			}
		} else {
		    PrintToChat(Client, "%s You must be at least 8 rounds behind the enemy team to vote to surrender.", PREFIX);
		}
	} else if (iTeam == CS_TEAM_CT) {
	    // Check if T is 8 or more rounds ahead of CT
		if (CS_GetTeamScore(CS_TEAM_T) - 8 >= CS_GetTeamScore(iTeam)) {
		    // Check if client has already voted to surrender
			if (ga_iEndMatchVotesCT.FindValue(client) == -1) {
				ga_iEndMatchVotesCT.Push(client); // Add client to ArrayList

				int iTeamCount = GetTeamClientCount(iTeam);
				if (ga_iEndMatchVotesCT.Length >= iTeamCount) {
				    // Check if we have the amount of votes needed to surrender
					for (int i = 1; i <= MaxClients; i++) {
						if (IsValidClient(i, true)) {
							PrintToChat(i, "%s Counter-Terrorists have voted to surrender. Match ending...", PREFIX);
                        }
					}

					ServerCommand("get5_endmatch"); // Force end the match
					CreateTimer(10.0, Timer_KickEveryoneSurrender); // Delay kicking everyone so they can see the chat message and so the plugin has time to update their stats
					ga_iEndMatchVotesCT.Clear(); // Reset the ArrayList
				} else {
					for (int i = 1; i <= MaxClients; i++) {
						if (IsValidClient(i, true) && GetClientTeam(i) == iTeam) {
							PrintToChat(i, "%s %N has voted to surrender, %i/%i votes needed.", PREFIX, Client, ga_iEndMatchVotesCT.Length, iTeamCount);
                        }
					}
				}
			} else {
			    PrintToChat(Client, "%s You've already voted to surrender!", PREFIX);
			}
		} else {
		    PrintToChat(Client, "%s You must be at least 8 rounds behind the enemy team to vote to surrender.", PREFIX);
		}
	}

	return Plugin_Handled;
}

public void CheckSurrenderVotes()
{
	int iTeamCount = GetTeamClientCount(CS_TEAM_CT);
	if (iTeamCount <= 1) {
	    return;
	}

    // Check if we have the amount of votes needed to surrender
	if (ga_iEndMatchVotesCT.Length >= iTeamCount) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i, true)) {
				PrintToChat(i, "%s Counter-Terrorists have voted to surrender. Match ending...", PREFIX);
            }
		}

		ServerCommand("get5_endmatch"); // Force end the match
		CreateTimer(10.0, Timer_KickEveryoneSurrender); // Delay kicking everyone so they can see the chat message and so the plugin has time to update their stats
		ga_iEndMatchVotesCT.Clear(); // Reset the ArrayList
		return;
	}

	iTeamCount = GetTeamClientCount(CS_TEAM_T);
	if (iTeamCount <= 1) {
	    return;
	}

    // Check if we have the amount of votes needed to surrender
	if (ga_iEndMatchVotesT.Length >= iTeamCount) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i, true)) {
				PrintToChat(i, "%s Terrorists have voted to surrender. Match ending...", PREFIX);
            }
		}

		ServerCommand("get5_endmatch"); // Force end the match
		CreateTimer(10.0, Timer_KickEveryoneSurrender); // Delay kicking everyone so they can see the chat message and so the plugin has time to update their stats
		ga_iEndMatchVotesT.Clear(); // Reset the ArrayList
		return;
	}
}

public Action Timer_KickEveryoneSurrender(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
	    if (IsValidClient(i)) {
	        KickClient(i, "Match force ended by surrender vote");
	    }
	}
	SendMatchEndRequest();
	return Plugin_Stop;
}

public Action Timer_KickEveryoneEnd(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++) {
	    if (IsValidClient(i)) {
	        KickClient(i, "Thanks for playing!\nView the match on our website for statistics.");
	    }
	}
	ServerCommand("get5_endmatch");
	SendMatchEndRequest();
	return Plugin_Stop;
}

public void SendReport()
{
	char sWebHook[128], sSiteURL[128], sAvatarURL[128];
	g_CVDiscordWebhook.GetString(sWebHook, sizeof(sWebHook));
	g_CVSiteURL.GetString(sSiteURL, sizeof(sSiteURL));
	g_CVEmbedAvatar.GetString(sAvatarURL, sizeof(sAvatarURL));

	if (StrEqual(sWebHook, "") || StrEqual(sSiteURL, "") || StrEqual(sAvatarURL, "")) {
		LogError("Missing Webhook Endpoint, Site Url or Embed Avatar Url.");
		return;
	}

	int iTScore = CS_GetTeamScore(CS_TEAM_T);
	int iCTScore = CS_GetTeamScore(CS_TEAM_CT);
	int iWinners = 0;
	bool bDraw = false;

	if (iTScore > iCTScore) {
	    iWinners = CS_TEAM_T;
	} else if (iCTScore > iTScore) {
	    iWinners = CS_TEAM_CT;
	} else if (iTScore == iCTScore) {
	    bDraw = true;
	}

	Handle jRequest = json_object();
	Handle jEmbeds = json_array();
	Handle jContent = json_object();
	Handle jContentAuthor = json_object();

	json_object_set(jContent, "color", json_integer(g_CVEmbedColour.IntValue));

	char sWinTitle[64], sBuffer[128], sDescription[1024];
	int len = 0;
	if (bDraw) {
		Format(sWinTitle, sizeof(sWinTitle), "Match was a draw at %i:%i!", iTScore, iCTScore);
	} else if (iWinners == CS_TEAM_T) {
		Format(sWinTitle, sizeof(sWinTitle), "Terrorists just won %i:%i!", iTScore, iCTScore);
	} else {
		Format(sWinTitle, sizeof(sWinTitle), "Counter-Terrorists just won %i:%i!", iCTScore, iTScore);
    }

	json_object_set_new(jContentAuthor, "name", json_string(sWinTitle));
	Format(sBuffer, sizeof sBuffer, "%s/scoreboard.php?id=%i", sSiteURL, g_iMatchID);
	json_object_set_new(jContentAuthor, "url", json_string(sBuffer));
	json_object_set_new(jContentAuthor, "icon_url", json_string(sAvatarURL));
	json_object_set_new(jContent, "author", jContentAuthor);

	if (iWinners != 0) {
		for (int i = 1; i <= MaxClients; i++) {
			char sTemp[64];
			if (IsValidClient(i)) {
				if (GetClientTeam(i) == iWinners) {
					GetClientName(i, sTemp, sizeof(sTemp));
					ga_sWinningPlayers.PushString(sTemp);
				}
			}
		}

		len += Format(sDescription[len], sizeof(sDescription) - len, "\nCongratulations:\n");
		for (int i = 0; i < ga_sWinningPlayers.Length; i++) {
			char sName[64];
			ga_sWinningPlayers.GetString(i, sName, sizeof(sName));
			len += Format(sDescription[len], sizeof(sDescription) - len, "%s\n", sName);
		}
	}

	len += Format(sDescription[len], sizeof(sDescription) - len, "\n[View more](%s/scoreboard.php?id=%i)", sSiteURL, g_iMatchID);
	json_object_set_new(jContent, "description", json_string(sDescription));

	json_array_append_new(jEmbeds, jContent);
	json_object_set_new(jRequest, "username", json_string("Match Bot"));
	json_object_set_new(jRequest, "avatar_url", json_string(sAvatarURL));
	json_object_set_new(jRequest, "embeds", jEmbeds);

	char sJson[2048];
	json_dump(jRequest, sJson, sizeof sJson, 0, false, false, true);

	CloseHandle(jRequest);

	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sWebHook);

	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "payload_json", sJson);
	SteamWorks_SetHTTPCallbacks(hRequest, OnHTTPRequestComplete);

	if (!SteamWorks_SendHTTPRequest(hRequest)) {
		LogError("HTTP request failed, request was null");
    }
}

public void SendMatchEndRequest() {
	int ip[4];
	char sUrl[128], sFormattedUrl[128], sPort[32], sIp[32], sApiKey[64];

	g_CVSiteURL.GetString(sUrl, sizeof(sUrl));
	g_CVApiKey.GetString(sApiKey, sizeof(sApiKey));
	FindConVar("hostport").GetString(sPort, sizeof(sPort));
	Format(sIp, sizeof(sIp), "%i.%i.%i.%i:%s", ip[0], ip[1], ip[2], ip[3], sPort);

	Format(sFormattedUrl, sizeof(sFormattedUrl), "%s/api/get5/server-change.php", sUrl);
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sFormattedUrl);

	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "ip", sIp);
	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "key", sApiKey);
	SteamWorks_SetHTTPCallbacks(hRequest, MatchEndRequestComplete);

	if (!SteamWorks_SendHTTPRequest(hRequest)) {
		LogError("HTTP request failed, request was null");
    }
}

public int OnHTTPRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode204NoContent) {
		LogError("HTTP request failed, status code: %i", eStatusCode);
    }

	CloseHandle(hRequest);
}

public int MatchEndRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode)
{
	if (!bRequestSuccessful) {
		LogError("HTTP request failed, status code: %i", eStatusCode);
		delete hRequest;
		return;
	}

	int iBodySize;
	if (!SteamWorks_GetHTTPResponseBodySize(hRequest, iBodySize)) {
		delete hRequest;
		return;
	}

	char[] sBody = new char[iBodySize + 1];
	if (!SteamWorks_GetHTTPResponseBodyData(hRequest, sBody, iBodySize)) {
		delete hRequest;
		return;
	}

	LogMessage("JSON Response = %s", sBody);
	CloseHandle(hRequest);
}

public void Event_WeaponFired(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (Get5_GetGameState() != Get5State_Live || !IsValidClient(Client, true)) {
	    return;
	}

	int iWeapon = GetEntPropEnt(Client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(iWeapon)) {
	    return;
	}

	if (GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType") != -1 && GetEntProp(iWeapon, Prop_Send, "m_iClip1") != 255) {
	    g_iShotsFired[Client]++; //should filter knife and grenades
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("attacker"));
	if (Get5_GetGameState() != Get5State_Live || !IsValidClient(Client, true)) {
	    return;
	}

	if (event.GetInt("hitgroup") >= 0) {
		g_iShotsHit[Client]++;

		if (event.GetInt("hitgroup") == 1) {
		    g_iHeadshots[Client]++;
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client)) {
		int iIndexT = ga_iEndMatchVotesT.FindValue(client);
		int iIndexCT = ga_iEndMatchVotesCT.FindValue(client);

		if (iIndexT != -1) {
		    ga_iEndMatchVotesT.Erase(iIndexT);
		}
		if (iIndexCT != -1) {
		    ga_iEndMatchVotesCT.Erase(iIndexCT);
		}

		UpdatePlayerStats(false, Client);

		CheckSurrenderVotes();

		ResetVars(client);

		if (Get5_GetGameState() == Get5State_Live && IsValidClient(Client, true)) {
			char sQuery[1024], sSteamID[64];
			GetClientAuthId(Client, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
			Format(sQuery, sizeof(sQuery), "UPDATE sql_matches SET disconnected=1 WHERE match_id=LAST_INSERT_ID() AND steamid64='%s'", sSteamID);
			g_Database.Query(SQL_GenericQuery, sQuery);
		}
	}
}

// generic query handler
public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data) {
	if (results == null) {
		PrintToServer("MySQL Query Failed: %s", sError);
		LogError("MySQL Query Failed: %s", sError);
		return;
	}
}

stock bool IsValidClient(int client, bool inPug = false)
{
	if (client >= 1 &&
	client <= MaxClients &&
	IsClientConnected(client) &&
	IsClientInGame(client) &&
	!IsFakeClient(client) &&
	(inPug == false || (Get5_GetGameState() == Get5State_Live && (GetClientTeam(client) == CS_TEAM_CT || GetClientTeam(client) == CS_TEAM_T))))
		return true;
	return false;
}