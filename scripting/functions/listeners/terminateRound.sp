public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason) {
    canSurrender = false;

    if (reason != CSRoundEnd_TerroristsSurrender && reason != CSRoundEnd_CTSurrender) {
        
    }
}