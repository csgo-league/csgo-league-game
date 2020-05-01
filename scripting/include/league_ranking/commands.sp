// from smlib
#define GAMEUNITS_TO_METERS	0.01905

static const char g_sSqlRemoveDuplicateMySQL[] = "delete from `%s` USING `%s`, `%s` as vtable WHERE (`%s`.id>vtable.id) AND (`%s`.steam=vtable.steam);";

#define SQL_ResetStatsData \
"UPDATE `%s` SET \
		`score` = %i, \
		`kills` = 0, \
		`deaths`= 0, \
		`assists`= 0, \
		`suicides`= 0, \
		`tk`= 0, \
		`shots`= 0, \
		`hits`= 0, \
		`headshots`= 0, \
		`connected`= 0, \
		`rounds_tr` = 0, \
		`rounds_ct` = 0, \
		`c4_planted`= 0, \
		`c4_exploded`= 0, \
		`c4_defused`= 0, \
		`ct_win`= 0, \
		`tr_win`= 0, \
		`hostages_rescued`= 0, \
		`vip_killed` = 0, \
		`vip_escaped` = 0, \
		`vip_played` = 0, \
		`mvp`= 0, \
		`damage`= 0, \
		`match_win`= 0, \
		`match_draw`= 0, \
		`match_lose`= 0, \
		`first_blood`= 0, \
		`no_scope`= 0, \
		`no_scope_dis`= 0, \
		`lastconnect`= 0, \
		`head`= 0, \
		`chest`= 0, \
		`stomach`= 0, \
		`left_arm`= 0, \
		`right_arm`= 0, \
		`left_leg`= 0, \
		`right_leg`= 0 \
WHERE \
		`steam` = '%s';"

#define SQL_ResetWeaponsData \
"UPDATE `%s` SET \
		`knife` = 0, \
		`glock` = 0, \
		`hkp2000`= 0, \
		`usp_silencer`= 0, \
		`p250`= 0, \
		`deagle`= 0, \
		`elite`= 0, \
		`fiveseven`= 0, \
		`tec9`= 0, \
		`cz75a`= 0, \
		`revolver` = 0, \
		`nova` = 0, \
		`xm1014`= 0, \
		`mag7`= 0, \
		`sawedoff`= 0, \
		`bizon`= 0, \
		`mac10`= 0, \
		`mp9`= 0, \
		`mp7` = 0, \
		`ump45` = 0, \
		`p90` = 0, \
		`galilar`= 0, \
		`ak47`= 0, \
		`scar20`= 0, \
		`famas`= 0, \
		`m4a1`= 0, \
		`m4a1_silencer`= 0, \
		`aug`= 0, \
		`ssg08`= 0, \
		`sg556`= 0, \
		`awp`= 0, \
		`g3sg1`= 0, \
		`m249`= 0, \
		`negev`= 0, \
		`hegrenade`= 0, \
		`flashbang`= 0, \
		`smokegrenade`= 0, \
		`inferno`= 0, \
		`decoy`= 0, \
		`taser`= 0, \
		`mp5sd`= 0, \
		`breachcharge`= 0 \
WHERE \
		`steam` = '%s';"

#define SQL_ResetStatsDataAll \
"UPDATE `%s` SET \
		`score` = %i, \
		`kills` = 0, \
		`deaths`= 0, \
		`assists`= 0, \
		`suicides`= 0, \
		`tk`= 0, \
		`shots`= 0, \
		`hits`= 0, \
		`headshots`= 0, \
		`connected`= 0, \
		`rounds_tr` = 0, \
		`rounds_ct` = 0, \
		`c4_planted`= 0, \
		`c4_exploded`= 0, \
		`c4_defused`= 0, \
		`ct_win`= 0, \
		`tr_win`= 0, \
		`hostages_rescued`= 0, \
		`vip_killed` = 0, \
		`vip_escaped` = 0, \
		`vip_played` = 0, \
		`mvp`= 0, \
		`damage`= 0, \
		`match_win`= 0, \
		`match_draw`= 0, \
		`match_lose`= 0, \
		`first_blood`= 0, \
		`no_scope`= 0, \
		`no_scope_dis`= 0, \
		`lastconnect`= 0, \
		`head`= 0, \
		`chest`= 0, \
		`stomach`= 0, \
		`left_arm`= 0, \
		`right_arm`= 0, \
		`left_leg`= 0, \
		`right_leg`= 0;"

#define SQL_ResetWeaponsDataAll \
"UPDATE `%s` SET \
		`knife` = 0, \
		`glock` = 0, \
		`hkp2000`= 0, \
		`usp_silencer`= 0, \
		`p250`= 0, \
		`deagle`= 0, \
		`elite`= 0, \
		`fiveseven`= 0, \
		`tec9`= 0, \
		`cz75a`= 0, \
		`revolver` = 0, \
		`nova` = 0, \
		`xm1014`= 0, \
		`mag7`= 0, \
		`sawedoff`= 0, \
		`bizon`= 0, \
		`mac10`= 0, \
		`mp9`= 0, \
		`mp7` = 0, \
		`ump45` = 0, \
		`p90` = 0, \
		`galilar`= 0, \
		`ak47`= 0, \
		`scar20`= 0, \
		`famas`= 0, \
		`m4a1`= 0, \
		`m4a1_silencer`= 0, \
		`aug`= 0, \
		`ssg08`= 0, \
		`sg556`= 0, \
		`awp`= 0, \
		`g3sg1`= 0, \
		`m249`= 0, \
		`negev`= 0, \
		`hegrenade`= 0, \
		`flashbang`= 0, \
		`smokegrenade`= 0, \
		`inferno`= 0, \
		`decoy`= 0, \
		`taser`= 0, \
		`mp5sd`= 0, \
		`breachcharge`= 0;"

stock int Array_FindHighestValue(any[] array, int size, int start = 0) {
	if (start < 0) {
	    start = 0;
	}

	any value = array[start];
	any tempValue;
	int x = start;

	for (int i=start; i < size; i++) {
		tempValue = array[i];

		if (tempValue > value) {
			value = tempValue;
			x = i;
		}
	}

	return x;
}

stock float Math_UnitsToMeters(float units) {
	return (units * GAMEUNITS_TO_METERS);
}

stock float Entity_GetDistanceOrigin(int entity, const float vec[3]) {
	float entityVec[3];
	Entity_GetAbsOrigin(entity, entityVec);

	return GetVectorDistance(entityVec, vec);
}

stock float Entity_GetDistance(int entity, int target) {
	float targetVec[3];
	Entity_GetAbsOrigin(target, targetVec);

	return Entity_GetDistanceOrigin(entity, targetVec);
}

stock void Entity_GetAbsOrigin(int entity, float vec[3]) {
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vec);
}

public Action Command_ResetRank(int client, int args) {
	if (!g_bEnabled || client == 0 || !IsClientInGame(client)) {
		return Plugin_Handled;
    }

	char arg1[64];
	GetCmdArg(1,arg1,sizeof(arg1));
	char sEscapeArg1[129];
	SQL_EscapeString(g_hStatsDb,arg1,sEscapeArg1,sizeof(sEscapeArg1));
	//ReplaceString(arg1,sizeof(arg1)," ","");
	//ReplaceString(arg1,sizeof(arg1),"\"","");
	char query[2000];
	char query2[2000];
	FormatEx(query, sizeof(query), SQL_ResetStatsData, g_sSQLTable, g_PointsStart, sEscapeArg1);
	FormatEx(query2, sizeof(query2), SQL_ResetWeaponsData, g_sSQLTable, sEscapeArg1);
	SQL_TQuery(g_hStatsDb, SQL_NothingCallback, query);
	SQL_TQuery(g_hStatsDb, SQL_NothingCallback, query2);

	LogAction(client,-1,"[League] Rank has been reset (%s)",arg1);

	char auth[64];
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			GetClientAuthId(i,AuthId_SteamID64,auth,sizeof(auth));

			if (StrEqual(auth,arg1,false)) {
				OnClientPutInServer(i);
            }
		}
	}
	CPrintToChat(client, "%s %T", MSG, "The rank has been reset",client);
	return Plugin_Handled;
}

public Action Command_ResetRankAll(int client, int args) {
	if (!g_bEnabled || client == 0 || !IsClientInGame(client)) {
		return Plugin_Handled;
    }

	char query[2000];
	char query2[2000];
	FormatEx(query, sizeof(query), SQL_ResetStatsDataAll, g_sSQLTable, g_PointsStart);
	FormatEx(query2, sizeof(query2), SQL_ResetWeaponsDataAll, g_sSQLTable);
	SQL_TQuery(g_hStatsDb, SQL_NothingCallback, query);
	SQL_TQuery(g_hStatsDb, SQL_NothingCallback, query2);

	LogAction(client,-1,"[League] All rank data has been reset");

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
        }
	}
	CPrintToChat(client, "%s %T", MSG, "All rank data has been reset",client);
	return Plugin_Handled;
}

public Action Command_Duplicate(int client, int args) {
	char sQuery[512];

	FormatEx(sQuery, sizeof(sQuery), g_sSqlRemoveDuplicateMySQL, g_sSQLTable, g_sSQLTable, g_sSQLTable, g_sSQLTable, g_sSQLTable);

	SQL_TQuery(g_hStatsDb, SQL_DuplicateCallback, sQuery, client);

	return Plugin_Handled;
}

public Action Command_Purge(int client, int args) {
	if (!g_bEnabled || client == 0 || !IsClientInGame(client)) {
		return Plugin_Handled;
    }

	char arg1[64];

	GetCmdArg(1,arg1,sizeof(arg1));
	char sEscapeArg1[129];
	SQL_EscapeString(g_hStatsDb,arg1,sEscapeArg1,sizeof(sEscapeArg1));
	//ReplaceString(arg1,sizeof(arg1)," ","");
	//ReplaceString(arg1,sizeof(arg1),"\"","");

	int deletebefore;
	if (StringToInt(arg1) == 0) {
		CPrintToChat(client, "%s %T", MSG, "Usagepurge",client);
		return Plugin_Handled;
	}
	deletebefore = GetTime() - (StringToInt(arg1)*86400);
	char query[2000];
	Format(query,sizeof(query),"DELETE FROM `%s` WHERE lastconnect < '%d'",g_sSQLTable,deletebefore);
	SQL_TQuery(g_hStatsDb,SQL_PurgeCallback,query);
	LogAction(client,-1,"[League] Purged rank (%s days inactivity)",arg1);
	CPrintToChat(client, "%s %T", MSG, "Purged",client);
	return Plugin_Handled;
}

public void SQL_GetPlayersCallback(Handle owner, Handle hndl, const char[] error, any Datapack) {
	if (hndl == null) {
		LogError("[League] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}

	g_TotalPlayers = SQL_GetRowCount(hndl);
}

public Action Command_Top(int client, int args) {
	if (!g_bEnabled || client == 0 || !IsClientInGame(client)) {
		return Plugin_Handled;
    }

	char arg1[5];
	GetCmdArg(1,arg1,sizeof(arg1));
	if (!StrEqual(arg1,"") && StringToInt(arg1) != 0) {
		ShowTOP(client,StringToInt(arg1));
	} else {
		ShowTOP(client,0);
	}
	return Plugin_Handled;
}

void ShowTOP(int client, int at) {
	if (client == 0 || !IsClientInGame(client)) {
		return;
    }
	Handle Datapack = CreateDataPack();

	WritePackCell(Datapack,client);

	if (at > 0) {
		WritePackCell(Datapack,at-1);
	} else {
		WritePackCell(Datapack,0);
		at = 1; // For not needing to build twice the query. (for at > 0 and at <= 0)
	}
	char query[2000];
	MakeSelectQuery(query,sizeof(query));
	Format(query,sizeof(query),"%s ORDER BY score DESC LIMIT %i, 10",query,at-1);


	SQL_TQuery(g_hStatsDb,SQL_TopCallback,query,Datapack);
}

public void SQL_TopCallback(Handle owner, Handle hndl, const char[] error, any Datapack) {
	if (hndl == null) {
		LogError("[League] Query Fail: %s", error);
		PrintToServer(error);
		return;
	}

	ResetPack(Datapack);
	int i;
	int client = ReadPackCell(Datapack);
	if (client == 0 || !IsClientInGame(client)) {
		return;
    }
	int at = ReadPackCell(Datapack);
	CloseHandle(Datapack);
	if (!SQL_HasResultSet(hndl) || SQL_GetRowCount(hndl) == 0) {
		ShowTOP(client,g_TotalPlayers-9);
		return;
	}
	char name[256];
	char temp[500];

	Menu menu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio),MenuHandler_Top);

	float kdr;
	Format(temp,sizeof(temp)," %T\n","Showing",client,at+1,at+10,g_TotalPlayers);
	menu.SetTitle("");
	char sBuffer[200];
	while (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		i++;

		SQL_FetchString(hndl,2,name,sizeof(name));

		int deaths;
		if (SQL_FetchInt(hndl,6) == 0) {
			deaths = 1;
		} else {
			deaths=SQL_FetchInt(hndl,6);
        }

		kdr = SQL_FetchFloat(hndl,5)/deaths;
		Format(sBuffer,sizeof(sBuffer),"%d - %s (%d) - KDR: %.2f\n",i+at,name,SQL_FetchInt(hndl,4),kdr);

		if (strlen(temp)+strlen(sBuffer) < MAX_LENGTH_MENU) {
			Format(temp,sizeof(temp),"%s%s",temp,sBuffer);
			sBuffer="\0";
		}
	}
	Format(temp,sizeof(temp),"%s\n ",temp);
	menu.AddItem(temp,temp);

	IntToString(at+i,temp,sizeof(temp));
	char temp1[20];
	Format(temp1,sizeof(temp1),"%T","Next",client);
	if (i > 9) {
		menu.AddItem(temp,temp1);
    }

	IntToString(at-i,temp,sizeof(temp));
	Format(temp1,sizeof(temp1),"%T","Back",client);
	if (at + i - 1 > 9) {
		menu.AddItem(temp,temp1);
    }

	menu.DisplayAt(client,at,MENU_TIME_FOREVER);
}

public int MenuHandler_Top(Menu menu, MenuAction action, int param1, int param2) {

	if (action == MenuAction_Select) {
		char temp[250];

		menu.GetItem(param2, temp, sizeof(temp));
		if (StringToInt(temp) >= 0) {
			ShowTOP(param1,StringToInt(temp)+1);
		} else {
			ShowTOP(param1,0);
		}
	}

	if (action == MenuAction_End) {
		delete menu;
	}
}

public int MenuHandler_DoNothing(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_End) {
		delete menu;
	}
}

public Action Command_Rank(int client, int args) {
	if (!g_bEnabled || client == 0 || !IsClientInGame(client)) {
		return Plugin_Handled;
	}

	if (g_aStats[client].KILLS < g_MinimalKills) {
		CPrintToChat(client,"%s %T",MSG,"NotRanked",client,g_aStats[client].KILLS,g_MinimalKills);
		return Plugin_Handled;
	}

	// check cooldown
	if (g_bShowRankAll && hRankTimer[client] != null) {
		CPrintToChat(client,"%s %T",MSG,"RankCooldown",client);
		return Plugin_Handled;
	}

	char query[2000];
	MakeSelectQuery(query,sizeof(query));

	Format(query,sizeof(query),"%s ORDER BY score DESC",query);

	SQL_TQuery(g_hStatsDb,SQL_RankCallback,query,client);
	return Plugin_Handled;
}

public void SQL_RankCallback(Handle owner, Handle hndl, const char[] error, any client) {
	if (hndl == null) {
		LogError("[League] Query Fail: %s", error);
		return;
	}

	if (client == 0 || !IsClientInGame(client)) {
		return;
    }
	int i;

	g_TotalPlayers =SQL_GetRowCount(hndl);
	char Name_receive[MAX_NAME_LENGTH];
	char Auth_receive[64];

	int ikills = g_aStats[client].KILLS;
	int ideaths = g_aStats[client].DEATHS;

	int deaths;
	if (ideaths == 0) {
		deaths = 1;
	} else {
		deaths = ideaths;
    }

	float kills = IntToFloat(ikills);

	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	while (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl)) {
		i++;
		SQL_FetchString(hndl,2,Name_receive,MAX_NAME_LENGTH*2+1);
		SQL_FetchString(hndl,1,Auth_receive,64);

		if (StrEqual(Auth_receive, g_aClientSteam[client], false)) {
			if (g_bShowRankAll) {
				for (int j = 1; j <= MaxClients;j++) {
					if (IsClientInGame(j)) {
						if (client == j) {
							CPrintToChat(j,"%s %T",MSG,"IsRankedAt",client,name,i,g_TotalPlayers,g_aStats[client].SCORE,g_aStats[client].KILLS,g_aStats[client].DEATHS,g_aStats[client].ASSISTS,kills/deaths,g_aStats[client].TK,g_aStats[client].MVP);
                        }

						if (g_fRankAllTimer > 0.0) {
						    hRankTimer[j] = CreateTimer(g_fRankAllTimer, KillRankAllTimer, j);
						}
					}
				}
			} else {
				CPrintToChat(client,"%s %T",MSG,"IsRankedAt",client,name,i,g_TotalPlayers,g_aStats[client].SCORE,g_aStats[client].KILLS,g_aStats[client].DEATHS,g_aStats[client].ASSISTS,kills/deaths,g_aStats[client].TK,g_aStats[client].MVP);
			}

			break;
		}
	}
}

public Action KillRankAllTimer(Handle timer, int client)
{
	if (hRankTimer[client] != null) {
		hRankTimer[client] = null;
	}
}

public int PanelNoHandle(Menu menu, MenuAction action, int param1, int param2) {

}

public Action Command_ResetOwnRank(int client, int args) {
	if (!g_bEnabled || !g_bResetOwnRank || client == 0 || !IsClientInGame(client)) {
		return Plugin_Handled;
    }
	char query[2000];

	Format(query,sizeof(query),"DELETE FROM `%s` WHERE steam='%s'",g_sSQLTable,g_aClientSteam[client]);
	SQL_TQuery(g_hStatsDb,SQL_NothingCallback,query);
	LogAction(client,-1,"[League] Reset own rank (%s)",g_aClientSteam[client]);
	OnClientPutInServer(client);
	CPrintToChat(client,"%s %T",MSG,"ResetMyRank", client);
	return Plugin_Handled;
}

public float IntToFloat(int integer) {
	char s[300];
	IntToString(integer,s,sizeof(s));
	return StringToFloat(s);
}

public int FloatToInt(float ifloat) {
	char s[300];
	FloatToString(ifloat,s,sizeof(s));
	return StringToInt(s);
}

public int MenuHandler_TargetResetRank(Menu menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		char temp[250];

		menu.GetItem(param2, temp, sizeof(temp));
		int target = GetClientOfUserId(StringToInt(temp));

		ClientCommand(client,"sm_resetrank \"%s\"",g_aClientSteam[target]);
	}

	if (action == MenuAction_End) {
		delete menu;
	}
}