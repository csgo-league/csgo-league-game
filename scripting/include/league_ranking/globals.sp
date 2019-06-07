stock const char g_sWeaponsNamesGame[42][] =  { "knife", "glock", "hkp2000", "usp_silencer", "p250", "deagle", "elite", "fiveseven", "tec9", "cz75a", "revolver", "nova", "xm1014", "mag7", "sawedoff", "bizon", "mac10", "mp9", "mp7", "ump45", "p90", "galilar", "ak47", "scar20", "famas", "m4a1", "m4a1_silencer", "aug", "ssg08", "sg556", "awp", "g3sg1", "m249", "negev", "hegrenade", "flashbang", "smokegrenade", "inferno", "decoy", "taser", "mp5sd", "breachcharge"};
stock const char g_sWeaponsNamesFull[42][] =  { "Knife", "Glock", "P2000", "USP-S", "P250", "Desert Eagle", "Dual Berettas", "Five-Seven", "Tec 9", "CZ75-Auto", "R8 Revolver", "Nova", "XM1014", "Mag 7", "Sawed-off", "PP-Bizon", "MAC-10", "MP9", "MP7", "UMP45", "P90", "Galil AR", "AK-47", "SCAR-20", "Famas", "M4A4", "M4A1-S", "AUG", "SSG 08", "SG 553", "AWP", "G3SG1", "M249", "Negev", "HE Grenade", "Flashbang", "Smoke Grenade", "Inferno", "Decoy", "Zeus x27", "MP5-SD", "Breach Charges"};

ConVar g_cvarEnabled;
ConVar g_cvarChatChange;
ConVar g_cvarRankbots;
ConVar g_cvarAutopurge;
ConVar g_cvarDumpDB;
ConVar g_cvarPointsBombDefusedTeam;
ConVar g_cvarPointsBombDefusedPlayer;
ConVar g_cvarPointsBombPlantedTeam;
ConVar g_cvarPointsBombPlantedPlayer;
ConVar g_cvarPointsBombExplodeTeam;
ConVar g_cvarPointsBombExplodePlayer;
ConVar g_cvarPointsBombPickup;
ConVar g_cvarPointsBombDropped;
ConVar g_cvarPointsHostageRescTeam;
ConVar g_cvarPointsHostageRescPlayer;
ConVar g_cvarPointsVipEscapedTeam;
ConVar g_cvarPointsVipEscapedPlayer;
ConVar g_cvarPointsVipKilledTeam;
ConVar g_cvarPointsVipKilledPlayer;
ConVar g_cvarPointsHs;
ConVar g_cvarPointsKillCt;
ConVar g_cvarPointsKillTr;
ConVar g_cvarPointsKillBonusCt;
ConVar g_cvarPointsKillBonusTr;
ConVar g_cvarPointsKillBonusDifCt;
ConVar g_cvarPointsKillBonusDifTr;
ConVar g_cvarPointsStart;
ConVar g_cvarPointsKnifeMultiplier;
ConVar g_cvarPointsTaserMultiplier;
ConVar g_cvarPointsTrRoundWin;
ConVar g_cvarPointsCtRoundWin;
ConVar g_cvarPointsTrRoundLose;
ConVar g_cvarPointsCtRoundLose;
ConVar g_cvarPointsMvpCt;
ConVar g_cvarPointsMvpTr;
ConVar g_cvarMinimalKills;
ConVar g_cvarPercentPointsLose;
ConVar g_cvarPointsLoseRoundCeil;
ConVar g_cvarShowRankAll;
ConVar g_cvarRankAllTimer;
ConVar g_cvarResetOwnRank;
ConVar g_cvarMinimumPlayers;
ConVar g_cvarVipEnabled;
ConVar g_cvarPointsLoseTk;
ConVar g_cvarPointsLoseSuicide;
ConVar g_cvarShowBotsOnRank;
ConVar g_cvarFfa;
ConVar g_cvarMysql;
ConVar g_cvarGatherStats;
ConVar g_cvarDaysToNotShowOnRank;
ConVar g_cvarRankMode;
ConVar g_cvarSQLTable;
ConVar g_cvarChatTriggers;

bool g_bEnabled;
bool g_bResetOwnRank;
bool g_bRankBots;
bool g_bPointsLoseRoundCeil;
bool g_bShowRankAll;
bool g_bShowBotsOnRank;
bool g_bFfa;
bool g_bMysql;
bool g_bGatherStats;
bool g_bDumpDB;
bool g_bChatTriggers;

float g_fRankAllTimer;

int g_PointsBombDefusedTeam;
int g_PointsBombDefusedPlayer;
int g_PointsBombPlantedTeam;
int g_PointsBombPlantedPlayer;
int g_PointsBombExplodeTeam;
int g_PointsBombExplodePlayer;
int g_PointsBombPickup;
int g_PointsBombDropped;
int g_PointsHostageRescTeam;
int g_PointsHostageRescPlayer;
int g_PointsHs;
// Size = 4 -> for using client team for points
int g_PointsKill[4];
int g_PointsKillBonus[4];
int g_PointsKillBonusDif[4];
int g_PointsMvpTr;
int g_PointsMvpCt;
int g_MinimalKills;
int g_PointsStart;

float g_fPointsKnifeMultiplier;
float g_fPointsTaserMultiplier;
float g_fPercentPointsLose;

int g_PointsRoundWin[4];
int g_PointsRoundLose[4];
int g_MinimumPlayers;
int g_PointsLoseTk;
int g_PointsLoseSuicide;
int g_PointsVipEscapedTeam;
int g_PointsVipEscapedPlayer;
int g_PointsVipKilledTeam;
int g_PointsVipKilledPlayer;
int g_DaysToNotShowOnRank;
int g_RankMode;

char g_sSQLTable[200];
Handle g_hStatsDb;
bool OnDB[MAXPLAYERS + 1];
int g_aStats[MAXPLAYERS + 1][STATS_NAMES];
int g_aWeapons[MAXPLAYERS + 1][WEAPONS_ENUM];
int g_aHitBox[MAXPLAYERS + 1][HITBOXES];
int connectTime[MAXPLAYERS + 1];
int g_TotalPlayers;

ConVar g_cvarPointsMatchWin;
ConVar g_cvarPointsMatchDraw;
ConVar g_cvarPointsMatchLose;
int g_PointsMatchWin;
int g_PointsMatchDraw;
int g_PointsMatchLose;

Handle g_fwdOnPlayerLoaded;
Handle g_fwdOnPlayerSaved;

bool DEBUGGING = false;
int g_C4PlantedBy;
char g_sC4PlantedByName[MAX_NAME_LENGTH];

// Preventing duplicates
char g_aClientSteam[MAXPLAYERS + 1][64];

/* Rank cache */
ConVar g_cvarRankCache;
Handle g_arrayRankCache[3];
bool g_bRankCache;

/* Cooldown Timer */
Handle hRankTimer[MAXPLAYERS + 1] = null;

/* Connect Announcer */
ConVar g_cvarAnnounceConnect;
ConVar g_cvarAnnounceConnectChat;
ConVar g_cvarAnnounceConnectHint;
ConVar g_cvarAnnounceDisconnect;
ConVar g_cvarAnnounceTopConnect;
ConVar g_cvarAnnounceTopPosConnect;
ConVar g_cvarAnnounceTopConnectChat;
ConVar g_cvarAnnounceTopConnectHint;

bool g_bAnnounceConnect;
bool g_bAnnounceConnectChat;
bool g_bAnnounceConnectHint;
bool g_bAnnounceDisconnect;
bool g_bAnnounceTopConnect;
bool g_bAnnounceTopConnectChat;
bool g_bAnnounceTopConnectHint;

int g_AnnounceTopPosConnect;

int g_aPointsOnConnect[MAXPLAYERS+1];
int g_aPointsOnDisconnect[MAXPLAYERS+1];
int g_aRankOnConnect[MAXPLAYERS+1];
char g_sBufferClientName[MAXPLAYERS+1][MAX_NAME_LENGTH];

/* Assist */
ConVar g_cvarPointsAssistKill;
int g_PointsAssistKill;

/* Min points */
ConVar g_cvarPointsMin;
int g_PointsMin;
ConVar g_cvarPointsMinEnabled;
bool g_bPointsMinEnabled;

/* First blood */
bool firstblood = false;
ConVar g_cvarPointsFb;
int g_PointsFb;

/* No scope */
ConVar g_cvarPointsNS;
int g_PointsNS;
ConVar g_cvarNSAllSnipers;
bool g_bNSAllSnipers;

#define MSG "[\x04League\x01]"
#define SPEC 1
#define TR 2
#define CT 3
#define SENDER_WORLD 0
#define MAX_LENGTH_MENU 470