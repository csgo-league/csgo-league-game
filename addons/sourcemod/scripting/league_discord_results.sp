#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <SteamWorks>
#include <smjansson>
#include <get5>

#pragma semicolon 1
#pragma newdecls required

int g_iMatchID = -1;
bool g_bFailedMatch = false;

ConVar g_CVDiscordWebhook;
ConVar g_CVSiteURL;
ConVar g_CVUsername;
ConVar g_CVEmbedColour;
ConVar g_CVEmbedAvatar;

ArrayList ga_sWinningPlayers;

public Plugin myinfo = {
	name = "[League] Match Result",
	author = "The Doggy, B3none, PandahChan",
	description = "Post the final score in Discord via Webhook",
	version = "1.0.0",
	url = "https://github.com/csgo-league"
};

public void OnPluginStart() {
	ga_sWinningPlayers = new ArrayList(64);

	g_CVDiscordWebhook = CreateConVar("sm_discord_webhook", "", "Discord web hook endpoint", FCVAR_PROTECTED);
	g_CVSiteURL = CreateConVar("league_discord_results_site_url", "", "Website url for viewing scores", FCVAR_PROTECTED);
	g_CVUsername = CreateConVar("league_discord_results_username", "League Results", "Username to use for webhook", FCVAR_PROTECTED);
	g_CVEmbedColour = CreateConVar("league_discord_results_embed_color", "16741688", "Color to use for webhook (Must be decimal value)", FCVAR_PROTECTED);
	g_CVEmbedAvatar = CreateConVar("league_discord_results_embed_avatar", "https://avatars1.githubusercontent.com/u/51230829", "Avatar to use for webhook", FCVAR_PROTECTED);	

	AutoExecConfig(true, "league_discord_results");
}

public void Get5_OnGameStateChanged(Get5State oldState, Get5State newState)
{
	if (newState != Get5State_None) {
		return;
	}
	else if (oldState > Get5State_None && oldState < Get5State_GoingLive) {
		g_bFailedMatch = true;
		SendReport();
	}
	g_bFailedMatch = false;
}


public void Get5_OnMapResult(const char[] map, MatchTeam mapWinner, int team1Score, int team2Score, int mapNumber) {
	static float fTime;
	if (GetGameTime() - fTime < 1.0) {
		return;
	}
	SendReport();
}

public void SendReport() {
	char sWebHook[128], sUserName[128], sSiteURL[128], sAvatarURL[128];
	g_CVDiscordWebhook.GetString(sWebHook, sizeof(sWebHook));
	g_CVUsername.GetString(sUserName, sizeof(sUserName));
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
	char matchid[64];
	Get5_GetMatchID(matchid, sizeof(matchid));
	g_iMatchID = StringToInt(matchid);
	
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

	char teamName1[32];
	char teamName2[32];
	GetConVarString(FindConVar("mp_teamname_1"), teamName1, sizeof(teamName1));
	GetConVarString(FindConVar("mp_teamname_2"), teamName2, sizeof(teamName2));
	
	if (g_bFailedMatch) {
		Format(sWinTitle, sizeof(sWinTitle), "Match was failed (not all players join the server)");
	}
	else if (bDraw) {
		Format(sWinTitle, sizeof(sWinTitle), "Match was a draw at %i:%i!", iTScore, iCTScore);
	}
	else if (iWinners == CS_TEAM_T) {
		Format(sWinTitle, sizeof(sWinTitle), "%s just won %i:%i!", teamName1, iTScore, iCTScore);
	} 
	else {
		Format(sWinTitle, sizeof(sWinTitle), "%s just won %i:%i!", teamName2, iCTScore, iTScore);
    }

	json_object_set_new(jContentAuthor, "name", json_string(sWinTitle));
	Format(sBuffer, sizeof sBuffer, "%s/match/%i", sSiteURL, g_iMatchID);
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
	

	len += Format(sDescription[len], sizeof(sDescription) - len, "\n[View more](%s/match/%i)", sSiteURL, g_iMatchID);
	json_object_set_new(jContent, "description", json_string(sDescription));
	ga_sWinningPlayers.Clear();

	json_array_append_new(jEmbeds, jContent);
	json_object_set_new(jRequest, "username", json_string(sUserName));
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

public int OnHTTPRequestComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode204NoContent) {
		LogError("HTTP request failed, status code: %i", eStatusCode);
    }

	CloseHandle(hRequest);
}

stock bool IsValidClient(int client) {
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client)) {
		return false;
	}

	return IsClientInGame(client);
}