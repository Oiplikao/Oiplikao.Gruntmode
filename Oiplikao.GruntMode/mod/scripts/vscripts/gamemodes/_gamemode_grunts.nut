global function GamemodeGrunts_Init


/*
Workflow:
1. Loading screen
1. Game chooses pilot(s)
1. Intro
1.? Pilots spawn as normal in a ship, grunts spawn in droppods
1. Grunts should definitely respawn, pilots maybe not?
1.? Pilot could spawn in a titan first

Whatever just do a working draft first
1. Loading screen
1. Game chooses pilot, everyone else is a grunt
1. Give grunts shit weapons, pilot keeps his stuff
1. FFA spawnpoints for now
1. Grunts have to kill the pilot, grunts respawn
1. Pilot just has to survive lol will do for now


Suggestions:
1. Disable grunt minimap
1. Announce pilot to mid-game connected clients
1. Remove lunge melee from grunts
*/

//based mostly on the hidden
void function GamemodeGrunts_Init()
{
	SetLoadoutGracePeriodEnabled( false ) // prevent modifying loadouts with grace period
	SetWeaponDropsEnabled( false )
	//SetRespawnsEnabled( false ) //grunts should definitely respawn
	//Riff_ForceTitanAvailability( eTitanAvailability.Never )
	//Riff_ForceBoostAvailability( eBoostAvailability.Disabled )
	//Riff_ForceSetEliminationMode( eEliminationMode.Pilots )

	//hide n seek has smoother intro i think
	//man i dont know anymore, let's just have infection-like intro for now
	//ClassicMP_SetCustomIntro( GamemodeGruntsIntroSetup, 0.0 )
	//ClassicMP_SetCustomIntro( ClassicMP_DefaultNoIntro_Setup, ClassicMP_DefaultNoIntro_GetLength() )
	ClassicMP_ForceDisableEpilogue( true )

	AddCallback_OnClientConnected( GruntsPlayerConnected )
	AddCallback_OnPlayerRespawned( GruntsOnPlayerRespawned )
	AddCallback_OnPlayerKilled( GruntsOnPlayerKilled )
	AddCallback_GameStateEnter( eGameState.Playing, GruntsStartUp )

	
	//AddCallback_GameStateEnter( eGameState.Postmatch, RemoveHidden )
	SetTimeoutWinnerDecisionFunc( TimeoutCheckSurvivors )

	//thread PredatorMain()
}
/*
void function GamemodeGruntsIntroSetup()
{
	AddCallback_GameStateEnter( eGameState.Prematch, GruntsIntroPrematch )
}
*/

/* Droppod spawning from Hide n seek. Definitely need this for grunts

//dunno what this does
AddSpawnCallback( "info_spawnpoint_droppod_start", AddDroppodSpawn )

void function AddDroppodSpawn( entity spawn )
{
	file.droppodSpawns.append( spawn )
}


if ( file.droppodSpawns.len() != 0 )
	podSpawn = file.droppodSpawns.getrandom()
else
	podSpawn = SpawnPoints_GetPilot().getrandom()

SpawnPlayersInDropPod( seekers, podSpawn.GetOrigin(), podSpawn.GetAngles() )
	
*/
/*
void function GruntsIntroPrematch()
{
	ClassicMP_OnIntroStarted()
	
	foreach ( entity player in GetPlayerArray() )
		AddPlayerToGruntsIntro( player )
		
	//-! why?
	// this intro is mostly done in playing, so just finish the intro up now and we can do fully custom logic from here
	//wait 2.5
	ClassicMP_OnIntroFinished()
}
*/
void function GruntsPlayerConnected ( entity player )
{		
	SetTeam( player, GRUNTS_TEAM_GRUNTS )
}

void function GruntsOnPlayerRespawned( entity player )
{
	// so it doesnt affect the possible pilot
	if( GetGameState() != eGameState.Playing )
		return 

	thread UpdateGruntLoadout( player )
}

void function UpdateGruntLoadout ( entity player )
{	
	if (player.GetTeam() != GRUNTS_TEAM_GRUNTS || !IsAlive(player) || player == null)
			return
	
	thread OnPlayerRespawned_Threaded( player )
	
	PlayerEarnMeter_DisableGoal( player )
	PlayerEarnMeter_DisableReward( player )
	
	Remote_CallFunction_NonReplay( player, "ServerCallback_DisableMinimap" )
	
	//player.SetPlayerSettingsWithMods( player.GetPlayerSettings(), [ /*"disable_wallrun", "disable_doublejump",*/ "disable_slide"])
	player.SetPlayerSettingsWithMods( "pilot_grunt", [] )
	thread SetAirAccelerationAFrameLater( player )
	
	//player.SetModel($"models/humans/grunts/imc_grunt_rifle.mdl")

	foreach ( entity weapon in player.GetOffhandWeapons() )
		player.TakeWeaponNow( weapon.GetWeaponClassName() )
		
	foreach ( entity weapon in player.GetMainWeapons() )
		player.TakeWeaponNow( weapon.GetWeaponClassName() )


	//-! TODO: randomized grunt loadouts
	try {
		player.GiveWeapon("mp_weapon_rspn101")
		//player.GiveOffhandWeapon("mp_ability_cloak", OFFHAND_SPECIAL )
		player.GiveOffhandWeapon("mp_weapon_frag_grenade", OFFHAND_ORDNANCE )
		//player.GiveOffhandWeapon( "melee_pilot_emptyhanded", OFFHAND_MELEE )
	} catch (ex) {}
}

//for some reason it doesnt apply after respawning but does work on game start
void function SetAirAccelerationAFrameLater( entity player )
{
	WaitFrame()
	player.kv.airacceleration = 50
}

void function OnPlayerRespawned_Threaded( entity player )
{
	// -! Do I even need this?
	// bit of a hack, need to rework earnmeter code to have better support for completely disabling it
	// rn though this just waits for earnmeter code to set the mode before we set it back
	WaitFrame()
	if ( IsValid( player ) )
		PlayerEarnMeter_SetMode( player, eEarnMeterMode.DISABLED )
}

void function GruntsStartUp()
{
	thread GruntsStartUpDelayed()
}

void function GruntsStartUpDelayed()
{
	//wait 10.0 + RandomFloat( 5.0 )
	
	var amount_of_pilots = 1 //!-TODO: maybe have a whole squad
	
	array<entity> randomPlayers = GetPlayerArray()
	randomPlayers.randomize()
	for(int i = 0; i < amount_of_pilots; i++)
	{
		entity randomPlayer = randomPlayers.pop()
		if (randomPlayer != null || IsAlive(randomPlayer))
			MakePlayerPilot( randomPlayer )
	}

	//foreach ( entity otherPlayer in GetPlayerArray() ) //!-TODO: announce multiple pilots, dunno if translation strings support arrays
	//		if ( hidden != otherPlayer )
	//			Remote_CallFunction_NonReplay( otherPlayer, "ServerCallback_AnnounceHidden", hidden.GetEncodedEHandle() )

	PlayMusicToAll( eMusicPieceID.GAMEMODE_1 )
	
	foreach( entity gruntPlayer in GetPlayerArrayOfTeam( GRUNTS_TEAM_GRUNTS ) )
		UpdateGruntLoadout( gruntPlayer )
}

void function MakePlayerPilot(entity player)
{
	if (player == null)
		return;

	SetTeam( player, GRUNTS_TEAM_PILOTS )
	player.SetPlayerGameStat( PGS_ASSAULT_SCORE, 0 ) // reset kills
	RespawnPilot( player )
	Remote_CallFunction_NonReplay( player, "ServerCallback_YouArePilot" )
}

void function RespawnPilot(entity player)
{
	if (player.GetTeam() != GRUNTS_TEAM_PILOTS )
		return
		
	//no modifiers for now, its the grunts that are modified negatively

	// no scaling for now
	//player.SetMaxHealth( 80 + ( (GetPlayerArrayOfTeam( TEAM_MILITIA ).len() + 1 ) * 20) )
	//player.SetHealth( 80 + ( (GetPlayerArrayOfTeam( TEAM_MILITIA ).len() + 1 ) * 20) )

	//if ( !player.IsMechanical() )
	//	player.SetBodygroup( player.FindBodyGroup( "head" ), 1 )

	//-! pilot keeps his loadout
	// set loadout
	//foreach ( entity weapon in player.GetMainWeapons() )
	//	player.TakeWeaponNow( weapon.GetWeaponClassName() )
	//
	//foreach ( entity weapon in player.GetOffhandWeapons() )
	//	player.TakeWeaponNow( weapon.GetWeaponClassName() )
	//
	//player.GiveWeapon("mp_weapon_wingman_n")
	//player.GiveOffhandWeapon( "melee_pilot_emptyhanded", OFFHAND_MELEE )
	//player.GiveOffhandWeapon( "mp_weapon_grenade_sonar", OFFHAND_SPECIAL );
	//thread UpdateLoadout(player)
}

void function GruntsOnPlayerKilled( entity victim, entity attacker, var damageInfo )
{
	if ( !victim.IsPlayer() || GetGameState() != eGameState.Playing )
		return

	if ( attacker.IsPlayer() && victim != attacker )
	{
		// increase kills by 1
		attacker.SetPlayerGameStat( PGS_ASSAULT_SCORE, attacker.GetPlayerGameStat( PGS_ASSAULT_SCORE ) + 1 )
	}
	
	if ( victim.GetTeam() == GRUNTS_TEAM_PILOTS )
	{
		//instawin for grunts if pilot dies for any reason
		SetRespawnsEnabled( false )
		SetKillcamsEnabled( false )
		if( attacker.IsPlayer() )
		{
			SetRoundWinningKillReplayAttacker( attacker )
		}
		SetWinner( GRUNTS_TEAM_GRUNTS )
	}
}

/*
void function RemoveHidden()
{
	foreach (entity player in GetPlayerArray())
	{
		if (player.GetTeam() == TEAM_IMC && player != null)
			player.kv.VisibilityFlags = ENTITY_VISIBLE_TO_EVERYONE
	}
}
*/

int function TimeoutCheckSurvivors()
{
	return GRUNTS_TEAM_PILOTS
}