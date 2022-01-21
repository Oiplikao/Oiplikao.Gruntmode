global function Sh_GamemodeGrunts_Init

global const string GAMEMODE_GRUNTS = "grunts"
global const int GRUNTS_TEAM_GRUNTS = TEAM_IMC
global const int GRUNTS_TEAM_PILOTS = TEAM_MILITIA

void function Sh_GamemodeGrunts_Init()
{	
	// create custom gamemode
	AddCallback_OnCustomGamemodesInit( CreateGamemodeGrunts )
	AddCallback_OnRegisteringCustomNetworkVars( GruntsRegisterNetworkVars )
}

void function CreateGamemodeGrunts()
{
	GameMode_Create( GAMEMODE_GRUNTS )
	GameMode_SetName( GAMEMODE_GRUNTS, "#GAMEMODE_GRUNTS" )
	GameMode_SetDesc( GAMEMODE_GRUNTS, "#PL_grunts_desc" )
	GameMode_SetGameModeAnnouncement( GAMEMODE_GRUNTS, "ffa_modeDesc" ) // !-TODO: whats this?
	GameMode_SetDefaultTimeLimits( GAMEMODE_GRUNTS, 5, 0.0 )
	GameMode_AddScoreboardColumnData( GAMEMODE_GRUNTS, "#SCOREBOARD_SCORE", PGS_ASSAULT_SCORE, 2 )
	GameMode_AddScoreboardColumnData( GAMEMODE_GRUNTS, "#SCOREBOARD_PILOT_KILLS", PGS_PILOT_KILLS, 2 )
	GameMode_SetColor( GAMEMODE_GRUNTS, [147, 204, 57, 255] )

	AddPrivateMatchMode( GAMEMODE_GRUNTS ) // add to private lobby modes

	#if SERVER
		GameMode_AddServerInit( GAMEMODE_GRUNTS, GamemodeGrunts_Init )
		GameMode_SetPilotSpawnpointsRatingFunc( GAMEMODE_GRUNTS, RateSpawnpoints_Generic )
		GameMode_SetTitanSpawnpointsRatingFunc( GAMEMODE_GRUNTS, RateSpawnpoints_Generic )
	#elseif CLIENT
		GameMode_AddClientInit( GAMEMODE_GRUNTS, ClGamemodeGrunts_Init )
	#endif
	#if !UI
		GameMode_SetScoreCompareFunc( GAMEMODE_GRUNTS, CompareAssaultScore )
	#endif
}

void function GruntsRegisterNetworkVars()
{
	if ( GAMETYPE != GAMEMODE_GRUNTS )
		return

	Remote_RegisterFunction( "ServerCallback_YouArePilot" )
	Remote_RegisterFunction( "ServerCallback_AnnouncePilot" )
	Remote_RegisterFunction( "ServerCallback_DisableMinimap" )
}