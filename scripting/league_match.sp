#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <SteamWorks>
#include <smjansson>
#include <get5>

#pragma semicolon 1
#pragma newdecls required

#define PREFIX "[\x04League\x01]"

int g_iMatchID;

ConVar g_AllowTechPauseCvar;
ConVar g_DamagePrintCvar;
ConVar g_DamagePrintFormat;
ConVar g_MaxPausesCvar;
ConVar g_MaxPauseTimeCvar;
ConVar g_PausingEnabledCvar;

ArrayList ga_sWinningPlayers;

enum AllowedTeamStatus {
    NOT_AUTHORIZED = 0,
    TEAM_T,
    TEAM_CT
}

AllowedTeamStatus g_eAllowedTeam[MAXPLAYERS + 1] = NOT_AUTHORIZED;

public Plugin info = {
    name = "[League] Match Handler",
    author = "PandahChan, B3none, The Doggy",
    description = "Full match handler",
    version = "1.0",
    url = "https://github.com/csgo-league"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("weapon_fire", EventWeaponFired);
    HookEvent("player_hurt", Event_PlayerHurt);

    ga_sWinningPlayers = new ArrayList(64);

    RegConsoleCmd("sm_pause", Command_PauseMatch, "Uses a tactical timeout");
    RegConsoleCmd("sm_gg", Command_EndMatch, "Pushes a surrender vote.");
}

public Action Command_PauseMatch(int Client)
{
    
}

public Action Command_EndMatch(int Client, int iArgs)
{

}