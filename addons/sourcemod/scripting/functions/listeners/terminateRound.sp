public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason) {
	canSurrender = false;

	if (reason != CSRoundEnd_TerroristsSurrender && reason != CSRoundEnd_CTSurrender) {
		if (isVoteActive) {
			int entity = FindEntityByClassname(-1, "vote_controller");

			if (entity < 0) {
				return Plugin_Continue;
			}

			int activeIssue = GetEntProp(entity, Prop_Send, "m_iActiveIssueIndex", -1);

			// Surrender
			if (activeIssue == 0) {
				CreateTimer(1.0, Timer_VoteFail, 33);
			}
		}
	}

	return Plugin_Continue;
}