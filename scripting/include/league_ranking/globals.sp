static const char g_sSqliteCreate[] = "CREATE TABLE IF NOT EXISTS `%s` (id INTEGER PRIMARY KEY, steam TEXT, name TEXT, score NUMERIC, kills NUMERIC, deaths NUMERIC, assists NUMERIC, suicides NUMERIC, tk NUMERIC, shots NUMERIC, hits NUMERIC, headshots NUMERIC, connected NUMERIC, rounds_tr NUMERIC, rounds_ct NUMERIC, lastconnect NUMERIC,knife NUMERIC,glock NUMERIC,hkp2000 NUMERIC,usp_silencer NUMERIC,p250 NUMERIC,deagle NUMERIC,elite NUMERIC,fiveseven NUMERIC,tec9 NUMERIC,cz75a NUMERIC,revolver NUMERIC,nova NUMERIC,xm1014 NUMERIC,mag7 NUMERIC,sawedoff NUMERIC,bizon NUMERIC,mac10 NUMERIC,mp9 NUMERIC,mp7 NUMERIC,ump45 NUMERIC,p90 NUMERIC,galilar NUMERIC,ak47 NUMERIC,scar20 NUMERIC,famas NUMERIC,m4a1 NUMERIC,m4a1_silencer NUMERIC,aug NUMERIC,ssg08 NUMERIC,sg556 NUMERIC,awp NUMERIC,g3sg1 NUMERIC,m249 NUMERIC,negev NUMERIC,hegrenade NUMERIC,flashbang NUMERIC,smokegrenade NUMERIC,inferno NUMERIC,decoy NUMERIC,taser NUMERIC,mp5sd NUMERIC,breachcharge NUMERIC,head NUMERIC, chest NUMERIC, stomach NUMERIC, left_arm NUMERIC, right_arm NUMERIC, left_leg NUMERIC, right_leg NUMERIC,c4_planted NUMERIC,c4_exploded NUMERIC,c4_defused NUMERIC,ct_win NUMERIC, tr_win NUMERIC, hostages_rescued NUMERIC, vip_killed NUMERIC, vip_escaped NUMERIC, vip_played NUMERIC, mvp NUMERIC, damage NUMERIC, match_win NUMERIC, match_draw NUMERIC, match_lose NUMERIC, first_blood NUMERIC, no_scope NUMERIC, no_scope_dis NUMERIC)";
static const char g_sMysqlCreate[] = "CREATE TABLE IF NOT EXISTS `%s` (id INTEGER PRIMARY KEY, steam TEXT, name TEXT, score NUMERIC, kills NUMERIC, deaths NUMERIC, assists NUMERIC, suicides NUMERIC, tk NUMERIC, shots NUMERIC, hits NUMERIC, headshots NUMERIC, connected NUMERIC, rounds_tr NUMERIC, rounds_ct NUMERIC, lastconnect NUMERIC,knife NUMERIC,glock NUMERIC,hkp2000 NUMERIC,usp_silencer NUMERIC,p250 NUMERIC,deagle NUMERIC,elite NUMERIC,fiveseven NUMERIC,tec9 NUMERIC,cz75a NUMERIC,revolver NUMERIC,nova NUMERIC,xm1014 NUMERIC,mag7 NUMERIC,sawedoff NUMERIC,bizon NUMERIC,mac10 NUMERIC,mp9 NUMERIC,mp7 NUMERIC,ump45 NUMERIC,p90 NUMERIC,galilar NUMERIC,ak47 NUMERIC,scar20 NUMERIC,famas NUMERIC,m4a1 NUMERIC,m4a1_silencer NUMERIC,aug NUMERIC,ssg08 NUMERIC,sg556 NUMERIC,awp NUMERIC,g3sg1 NUMERIC,m249 NUMERIC,negev NUMERIC,hegrenade NUMERIC,flashbang NUMERIC,smokegrenade NUMERIC,inferno NUMERIC,decoy NUMERIC,taser NUMERIC,mp5sd NUMERIC,breachcharge NUMERIC,head NUMERIC, chest NUMERIC, stomach NUMERIC, left_arm NUMERIC, right_arm NUMERIC, left_leg NUMERIC, right_leg NUMERIC,c4_planted NUMERIC,c4_exploded NUMERIC,c4_defused NUMERIC,ct_win NUMERIC, tr_win NUMERIC, hostages_rescued NUMERIC, vip_killed NUMERIC, vip_escaped NUMERIC, vip_played NUMERIC, mvp NUMERIC, damage NUMERIC, match_win NUMERIC, match_draw NUMERIC, match_lose NUMERIC, first_blood NUMERIC, no_scope NUMERIC, no_scope_dis NUMERIC)";
static const char g_sSqlInsert[] = "INSERT INTO `%s` VALUES (null,'%s','%d','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0','0');";

/* SM1.9 Fix */
static const char g_sSqlSave[] = "UPDATE `%s` SET score = '%i', kills = '%i', deaths='%i', assists='%i',suicides='%i',tk='%i',shots='%i',hits='%i',headshots='%i', rounds_tr = '%i', rounds_ct = '%i',name='%s'%s,head='%i',chest='%i', stomach='%i',left_arm='%i',right_arm='%i',left_leg='%i',right_leg='%i' WHERE steam = '%s';";
static const char g_sSqlSave2[] = "UPDATE `%s` SET c4_planted='%i',c4_exploded='%i',c4_defused='%i',ct_win='%i',tr_win='%i', hostages_rescued='%i',vip_killed = '%d',vip_escaped = '%d',vip_played = '%d', mvp='%i', damage='%i', match_win='%i', match_draw='%i', match_lose='%i', first_blood='%i', no_scope='%i', no_scope_dis='%i', lastconnect='%i', connected='%i' WHERE steam = '%s';";

static const char g_sSqlRetrieveClient[] = "SELECT * FROM `%s` WHERE steam='%s';";
static const char g_sSqlRemoveDuplicateSQLite[] = "delete from `%s` where `%s`.id > (SELECT min(id) from `%s` as t2 WHERE t2.steam=`%s`.steam);";
static const char g_sSqlRemoveDuplicateMySQL[] = "delete from `%s` USING `%s`, `%s` as vtable WHERE (`%s`.id>vtable.id) AND (`%s`.steam=vtable.steam);";
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

/*RankMe Connect Announcer*/
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