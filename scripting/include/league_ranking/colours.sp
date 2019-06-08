#if defined _colours_included
 #endinput
#endif
#define _colours_included

#define MAX_MESSAGE_LENGTH 1000
#define MAX_COLOURS 12

#define SERVER_INDEX 0
#define NO_INDEX -1
#define NO_PLAYER -2

enum Colours {
 	Colour_Default = 0,
	Colour_Darkred,
	Colour_Pink,
	Colour_Green,
	Colour_Yellow,
	Colour_Red,
	Colour_Gray,
	Colour_Blue,
	Colour_Darkblue,
	Colour_Purple,
	Colour_Lightgreen,
	Colour_Orange,
}

// Colours' properties
char CTag[][] = {"{NORMAL}", "{DARKRED}", "{PINK}", "{GREEN}", "{YELLOW}", "{LIGHTGREEN}", "{RED}", "{GRAY}", "{BLUE}", "{DARKBLUE}", "{PURPLE}", "{ORANGE}"};
char CTagCode[][] = {"\x01", "\x02", "\x03", "\x04", "\x09", "\x06", "\x07", "\x08", "\x0B", "\x0C", "\x0E", "\x10"};
bool CTagReqSayText2[] = {false, false, false, false, false, false, false, false, false, false, false, false};
bool CEventIsHooked = false;
bool CSkipList[MAXPLAYERS+1] = {false,...};

// Game default profile
bool CProfile_Colours[] = {true, false, false, false, false, false, false, false, false, false, false, false};
int CProfile_TeamIndex[] = {NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX, NO_INDEX};
bool CProfile_SayText2 = false;

/**
 * Prints a message to a specific client in the chat area.
 * Supports colour tags.
 *
 * @param client	  Client index.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 *
 * On error/Errors:   If the client is not connected an error will be thrown.
 */
stock void CPrintToChat(int client, const char[] szMessage, any ...) {
	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
    }

	if (!IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
    }

	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];

	SetGlobalTransTarget(client);

	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 3);

	int index = CFormat(szCMessage, sizeof(szCMessage));

	if (index == NO_INDEX) {
		PrintToChat(client, "%s", szCMessage);
	} else {
		CSayText2(client, index, szCMessage);
    }
}

stock void CReplyToCommand(int client, const char[] szMessage, any ...) {
	char szCMessage[MAX_MESSAGE_LENGTH];
	VFormat(szCMessage, sizeof(szCMessage), szMessage, 3);

	if (client == 0) {
		CRemoveTags(szCMessage, sizeof(szCMessage));
		PrintToServer("%s", szCMessage);
	} else if (GetCmdReplySource() == SM_REPLY_TO_CONSOLE) {
		CRemoveTags(szCMessage, sizeof(szCMessage));
		PrintToConsole(client, "%s", szCMessage);
	} else {
		CPrintToChat(client, "%s", szCMessage);
	}
}


/**
 * Prints a message to all clients in the chat area.
 * Supports colour tags.
 *
 * @param client	  Client index.
 * @param szMessage   Message (formatting rules)
 * @return			  No return
 */
stock void CPrintToChatAll(const char[] szMessage, any ...) {
	char szBuffer[MAX_MESSAGE_LENGTH];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i]) {
			SetGlobalTransTarget(i);
			VFormat(szBuffer, sizeof(szBuffer), szMessage, 2);

			CPrintToChat(i, "%s", szBuffer);
		}

		CSkipList[i] = false;
	}
}

/**
 * Prints a message to a specific client in the chat area.
 * Supports colour tags and teamcolour tag.
 *
 * @param client	  Client index.
 * @param author	  Author index whose colour will be used for teamcolour tag.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 *
 * On error/Errors:   If the client or author are not connected an error will be thrown.
 */
stock void CPrintToChatEx(int client, int author, const char[] szMessage, any ...) {
	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
    }

	if (!IsClientInGame(client)) {
		ThrowError("Client %d is not in game", client);
    }

	if (author < 0 || author > MaxClients) {
		ThrowError("Invalid client index %d", author);
    }

	char szBuffer[MAX_MESSAGE_LENGTH];
	char szCMessage[MAX_MESSAGE_LENGTH];

	SetGlobalTransTarget(client);

	Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
	VFormat(szCMessage, sizeof(szCMessage), szBuffer, 4);

	int index = CFormat(szCMessage, sizeof(szCMessage), author);

	if (index == NO_INDEX) {
		PrintToChat(client, "%s", szCMessage);
	} else {
		CSayText2(client, author, szCMessage);
    }
}

/**
 * Prints a message to all clients in the chat area.
 * Supports colour tags and teamcolour tag.
 *
 * @param author	  Author index whos colour will be used for teamcolour tag.
 * @param szMessage   Message (formatting rules).
 * @return			  No return
 *
 * On error/Errors:   If the author is not connected an error will be thrown.
 */
stock void CPrintToChatAllEx(int author, const char[] szMessage, any ...) {
	if (author < 0 || author > MaxClients) {
		ThrowError("Invalid client index %d", author);
    }

	if (!IsClientInGame(author)) {
		ThrowError("Client %d is not in game", author);
    }

	char szBuffer[MAX_MESSAGE_LENGTH];

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && !CSkipList[i]) {
			SetGlobalTransTarget(i);
			VFormat(szBuffer, sizeof(szBuffer), szMessage, 3);

			CPrintToChatEx(i, author, "%s", szBuffer);
		}

		CSkipList[i] = false;
	}
}

/**
 * Removes colour tags from the string.
 *
 * @param szMessage   String.
 * @return			  No return
 */
stock void CRemoveTags(char[] szMessage, int maxlength) {
	for (int i = 0; i < MAX_COLOURS; i++) {
		ReplaceString(szMessage, maxlength, CTag[i], "", false);
    }

	ReplaceString(szMessage, maxlength, "{teamcolour}", "", false);
}

/**
 * Checks whether a colour is allowed or not
 *
 * @param tag   		Colour Tag.
 * @return			 	True when colour is supported, otherwise false
 */
stock int CColourAllowed(Colours colour) {
	if (!CEventIsHooked) {
		CSetupProfile();

		CEventIsHooked = true;
	}

	return CProfile_Colours[colour];
}

/**
 * Replace the colour with another colour
 * Handle with care!
 *
 * @param colour   			colour to replace.
 * @param newColour   		colour to replace with.
 * @noreturn
 */
stock void CReplaceColour(Colours colour, Colours newColour) {
	if (!CEventIsHooked) {
		CSetupProfile();

		CEventIsHooked = true;
	}

	CProfile_Colours[colour] = CProfile_Colours[newColour];
	CProfile_TeamIndex[colour] = CProfile_TeamIndex[newColour];

	CTagReqSayText2[colour] = CTagReqSayText2[newColour];
	Format(CTagCode[colour], sizeof(CTagCode[]), CTagCode[newColour])
}

/**
 * This function should only be used right in front of
 * CPrintToChatAll or CPrintToChatAllEx and it tells
 * to those functions to skip specified client when printing
 * message to all clients. After message is printed client will
 * no more be skipped.
 *
 * @param client   Client index
 * @return		   No return
 */
stock void CSkipNextClient(int client) {
	if (client <= 0 || client > MaxClients) {
		ThrowError("Invalid client index %d", client);
    }

	CSkipList[client] = true;
}

/**
 * Replaces colour tags in a string with colour codes
 *
 * @param szMessage   String.
 * @param maxlength   Maximum length of the string buffer.
 * @return			  Client index that can be used for SayText2 author index
 *
 * On error/Errors:   If there is more then one team colour is used an error will be thrown.
 */
stock int CFormat(char[] szMessage, int maxlength, int author = NO_INDEX) {
	char szGameName[30];

	GetGameFolderName(szGameName, sizeof(szGameName));

	// Hook event for auto profile setup on map start
	if (!CEventIsHooked) {
		CSetupProfile();
		HookEvent("server_spawn", CEvent_MapStart, EventHookMode_PostNoCopy);

		CEventIsHooked = true;
	}

	int iRandomPlayer = NO_INDEX;

	// On CS:GO set invisible pre-colour
	if (StrEqual(szGameName, "csgo", false)) {
		Format(szMessage, maxlength, " \x01\x0B\x01%s", szMessage);
    }

	/* If author was specified replace {teamcolour} tag */
	if (author != NO_INDEX) {
		if (CProfile_SayText2) {
			ReplaceString(szMessage, maxlength, "{teamcolour}", "\x03", false);

			iRandomPlayer = author;
		} else {
		    // If saytext2 is not supported by game replace {teamcolour} with green tag
			ReplaceString(szMessage, maxlength, "{teamcolour}", CTagCode[Colour_Green], false);
        }
	} else {
        ReplaceString(szMessage, maxlength, "{teamcolour}", "", false);
	}

	// For other colour tags we need a loop
	for (int i = 0; i < MAX_COLOURS; i++) {
		if (StrContains(szMessage, CTag[i], false) == -1) {
		    // If tag not found - skip
			continue;
		} else if (!CProfile_Colours[i]) {
		    // If tag is not supported by game replace it with green tag
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Colour_Green], false);
		} else if (!CTagReqSayText2[i]) {
		    // If tag doesn't need saytext2 simply replace
			ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], false);
		} else if (!CProfile_SayText2) {
		    // Tag needs saytext2
            // If saytext2 is not supported by game replace tag with green tag
            ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Colour_Green], false);
		} else {
            // Game supports saytext2
            // If random player for tag wasn't specified replace tag and find player
            if (iRandomPlayer == NO_INDEX) {
                // Searching for valid client for tag
                iRandomPlayer = CFindRandomPlayerByTeam(CProfile_TeamIndex[i]);

                if (iRandomPlayer == NO_PLAYER) {
                    // If player not found replace tag with green colour tag
                    ReplaceString(szMessage, maxlength, CTag[i], CTagCode[Colour_Green], false);
                } else {
                    // If player was found simply replace
                    ReplaceString(szMessage, maxlength, CTag[i], CTagCode[i], false);
                }
            } else {
                // If found another team colour tag throw error
                //ReplaceString(szMessage, maxlength, CTag[i], "");
                ThrowError("Using two team colours in one message is not allowed");
            }
        }
	}

	return iRandomPlayer;
}

/**
 * Founds a random player with specified team
 *
 * @param colour_team  Client team.
 * @return			  Client index or NO_PLAYER if no player found
 */
stock int CFindRandomPlayerByTeam(int colour_team) {
	if (colour_team == SERVER_INDEX) {
		return 0;
	}

	for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == colour_team) {
            return i;
        }
    }

	return NO_PLAYER;
}

/**
 * Sends a SayText2 usermessage to a client
 *
 * @param szMessage   Client index
 * @param maxlength   Author index
 * @param szMessage   Message
 * @return			  No return.
 */
stock void CSayText2(int client, int author, const char[] szMessage) {
	Handle hBuffer = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		PbSetInt(hBuffer, "ent_idx", author);
		PbSetBool(hBuffer, "chat", true);
		PbSetString(hBuffer, "msg_name", szMessage);
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
		PbAddString(hBuffer, "params", "");
	} else {
		BfWriteByte(hBuffer, author);
		BfWriteByte(hBuffer, true);
		BfWriteString(hBuffer, szMessage);
	}

	EndMessage();
}

/**
 * Creates game colour profile
 * This function must be edited if you want to add more games support
 *
 * @return			  No return.
 */
stock void CSetupProfile() {
	char szGameName[30];
	GetGameFolderName(szGameName, sizeof(szGameName));

	if (StrEqual(szGameName, "csgo", false)) {
		CProfile_Colours[Colour_Darkred] = true;
		CProfile_Colours[Colour_Pink] = true;
		CProfile_Colours[Colour_Green] = true;
		CProfile_Colours[Colour_Yellow] = true;
		CProfile_Colours[Colour_Red] = true;
		CProfile_Colours[Colour_Gray] = true;
		CProfile_Colours[Colour_Blue] = true;
		CProfile_Colours[Colour_Darkblue] = true;
		CProfile_Colours[Colour_Purple] = true;
		CProfile_Colours[Colour_Lightgreen] = true;
		CProfile_Colours[Colour_Orange] = true;
		CProfile_TeamIndex[Colour_Red] = 2;
		CProfile_TeamIndex[Colour_Blue] = 3;
		CProfile_SayText2 = true;
	} else if (GetUserMessageId("SayText2") == INVALID_MESSAGE_ID) {
	    // Profile for other games
        CProfile_SayText2 = false;
	} else {
        CProfile_Colours[Colour_Red] = true;
        CProfile_Colours[Colour_Blue] = true;
        CProfile_TeamIndex[Colour_Red] = 2;
        CProfile_TeamIndex[Colour_Blue] = 3;
        CProfile_SayText2 = true;
    }
}

public Action CEvent_MapStart(Handle event, const char[] name, bool dontBroadcast) {
	CSetupProfile();

	for (int i = 1; i <= MaxClients; i++) {
		CSkipList[i] = false;
    }
}