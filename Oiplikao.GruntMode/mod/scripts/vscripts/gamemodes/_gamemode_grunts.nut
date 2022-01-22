global function GamemodeGrunts_Init
global function DevTurnIntoGrunt
global function DevTurnIntoPilot

/*
Workflow:
1. Loading screen
1. Game chooses pilot(s)
1. Intro
1.? Pilots spawn as normal in a ship, grunts spawn in droppods
1. Grunts should definitely respawn, pilots maybe not?
1.? Pilot could spawn in a titan first

Suggestions:
1. Announce pilot to mid-game connected clients
1. Remove lunge melee from grunts
1. Make grunt jump distance shitty (or disable completely)
1. Make grunt weapons shit
1. Randomized grunt loadouts
1. Multiple pilots
*/

void function GamemodeGrunts_Init()
{
	SetLoadoutGracePeriodEnabled( false ) // prevent modifying loadouts with grace period
	SetWeaponDropsEnabled( false )

	ClassicMP_ForceDisableEpilogue( true )

	AddCallback_OnClientConnected( GruntsPlayerConnected )
	AddCallback_OnPlayerRespawned( GruntsOnPlayerRespawned )
	AddCallback_OnPlayerKilled( GruntsOnPlayerKilled )
	AddCallback_GameStateEnter( eGameState.Playing, GruntsStartUp )

	SetTimeoutWinnerDecisionFunc( TimeoutCheckSurvivors )
}

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

void function GruntsPlayerConnected ( entity player )
{		
	SetTeam( player, GRUNTS_TEAM_GRUNTS )
}

void function GruntsOnPlayerRespawned( entity player )
{
	// so gruntification doesnt affect the possible pilot
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
	//couldn't disable sliding through ClassMods so I made a separate class
	//except to make it load i have to replace the whole classes.txt import file so it'll conflict with other modes
	//keyvalue method didnt work probably because each line starts the same
	player.SetPlayerSettingsWithMods( "pilot_grunt", [] )
	
	foreach ( entity weapon in player.GetOffhandWeapons() )
		player.TakeWeaponNow( weapon.GetWeaponClassName() )
		
	foreach ( entity weapon in player.GetMainWeapons() )
		player.TakeWeaponNow( weapon.GetWeaponClassName() )

	try {
		player.GiveWeapon("mp_weapon_rspn101")
		//player.GiveOffhandWeapon("mp_ability_cloak", OFFHAND_SPECIAL )
		player.GiveOffhandWeapon("mp_weapon_frag_grenade", OFFHAND_ORDNANCE )
		player.GiveOffhandWeapon( "melee_pilot_emptyhanded", OFFHAND_MELEE )
	} catch (ex) {}
}

void function OnPlayerRespawned_Threaded( entity player )
{
	WaitFrame()
	if ( IsValid( player ) )
	{
		//for some reason it doesnt apply after respawning but does work on game start
		player.kv.airacceleration = 50
		// -! Do I even need this?
		// bit of a hack, need to rework earnmeter code to have better support for completely disabling it
		// rn though this just waits for earnmeter code to set the mode before we set it back
		PlayerEarnMeter_SetMode( player, eEarnMeterMode.DISABLED )
	}
}

void function GruntsStartUp()
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

int function TimeoutCheckSurvivors()
{
	return GRUNTS_TEAM_PILOTS
}

void function DevTurnIntoGrunt( entity player )
{
	player.SetTeam( GRUNTS_TEAM_GRUNTS )
	UpdateGruntLoadout( player )
}

void function DevTurnIntoPilot( entity player )
{
	MakePlayerPilot( player )
}
