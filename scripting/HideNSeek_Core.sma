/*
_____/\\\\\\\\\_____/\\\\____________/\\\\__/\\\_______/\\\__/\\\_______/\\\________________/\\\\\\\\\\\\\_______/\\\\\\\\\\\\_        
 ___/\\\\\\\\\\\\\__\/\\\\\\________/\\\\\\_\///\\\___/\\\/__\///\\\___/\\\/________________\/\\\/////////\\\___/\\\//////////__       
  __/\\\/////////\\\_\/\\\//\\\____/\\\//\\\___\///\\\\\\/______\///\\\\\\/__________________\/\\\_______\/\\\__/\\\_____________      
   _\/\\\_______\/\\\_\/\\\\///\\\/\\\/_\/\\\_____\//\\\\__________\//\\\\_______/\\\\\\\\\\\_\/\\\\\\\\\\\\\\__\/\\\____/\\\\\\\_     
    _\/\\\\\\\\\\\\\\\_\/\\\__\///\\\/___\/\\\______\/\\\\___________\/\\\\______\///////////__\/\\\/////////\\\_\/\\\___\/////\\\_    
     _\/\\\/////////\\\_\/\\\____\///_____\/\\\______/\\\\\\__________/\\\\\\___________________\/\\\_______\/\\\_\/\\\_______\/\\\_   
      _\/\\\_______\/\\\_\/\\\_____________\/\\\____/\\\////\\\______/\\\////\\\_________________\/\\\_______\/\\\_\/\\\_______\/\\\_  
       _\/\\\_______\/\\\_\/\\\_____________\/\\\__/\\\/___\///\\\__/\\\/___\///\\\_______________\/\\\\\\\\\\\\\/__\//\\\\\\\\\\\\/__ 
        _\///________\///__\///______________\///__\///_______\///__\///_______\///________________\/////////////_____\////////////____
					__/\\\________/\\\_______________________________/\\\______________________________________                                            
					 _\/\\\_______\/\\\______________________________\/\\\______________________________________                                           
					  _\/\\\_______\/\\\______________________________\/\\\______________________________________                                          
					   _\/\\\\\\\\\\\\\\\__/\\\____/\\\_____/\\\\\\\\__\/\\\__________/\\\____/\\\_____/\\\\\\\\__                                         
					    _\/\\\/////////\\\_\/\\\___\/\\\___/\\\/////\\\_\/\\\\\\\\\\__\/\\\___\/\\\___/\\\/////\\\_                                        
					     _\/\\\_______\/\\\_\/\\\___\/\\\__/\\\\\\\\\\\__\/\\\/////\\\_\/\\\___\/\\\__/\\\\\\\\\\\__                                       
					      _\/\\\_______\/\\\_\/\\\___\/\\\_\//\\///////___\/\\\___\/\\\_\/\\\___\/\\\_\//\\///////___                                      
					       _\/\\\_______\/\\\_\//\\\\\\\\\___\//\\\\\\\\\\_\/\\\___\/\\\_\//\\\\\\\\\___\//\\\\\\\\\\_                                     
					        _\///________\///___\/////////_____\//////////__\///____\///___\/////////_____\//////////__
*/

#include <amxmodx>

/* Common include libraries */
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <screenfade_util>
#include <cromchat>

#pragma compress 1

#define VERSION "1.0.11-ReAPI"
#define ADMIN_ACCESS ADMIN_LEVEL_A

new bool:g_bSwapTeamsOnNextRound
new bool:g_bFreezePeriod

new g_iHostageEnt
new g_iTeamScore[any:TeamName]
new Float:g_flKillMessageDelay[MAX_PLAYERS + 1]
new g_iUserOrigins[MAX_PLAYERS + 1][3]
new TeamName:g_iTempTeam[MAX_PLAYERS + 1]
new bool:g_bKnife[MAX_PLAYERS + 1] = { true, ... }
new bool:g_bUserInTrain[MAX_PLAYERS + 1] = { false, ... }
new bool:g_bEndSounds[MAX_PLAYERS + 1] = { true, ... }
new bool:g_bRoundEnd_Dance

//#define C21_WORLD_ACTION
#define ANTI_FRAG
#define AUTO_HEAL
//#define WINS_IN_A_ROW
#define FIRE_IN_THE_HOLE_MESSAGES
#define IMMUNITY_CHOOSE_TEAM
#define SKYES
//#define CUSTOM_MAP_NAME
#define SEMICLIP_ACTION
//#define TERRORIST_COUNTER	// Fixed in Version 1.9
//#define TERRORIST_COUNTER_HUD // If its not defined it will be print_center message
#define FLASH_CONTROL
//#define NEW_VERSION_FLOPPY
#define FROST_NADE

#if defined NEW_VERSION_FLOPPY
new g_szMapName[MAX_MAPNAME_LENGTH]
#endif // NEW_VERSION_FLOPPY

#if defined FLASH_CONTROL

#define FLASH_COLOR_RED		random(256)
#define FLASH_COLOR_GREEN	random(256)
#define FLASH_COLOR_BLUE	random(256)

//#define ALPHA_CONTROL

#if defined ALPHA_CONTROL
#define FLASH_COLOR_ALPHA	255
#endif // ALPHA_CONTROL

#endif // FLASH_CONTROL

#if defined ANTI_FRAG
new g_iLastHit[MAX_PLAYERS + 1]
#endif // ANTI_FRAG

#if defined AUTO_HEAL
//#define SLOW_HEAL

#if defined SLOW_HEAL
#define PercentSub(%1,%2)	(%1 - (%1 * %2)/100)
#define RESTORE_HEALTH_FROM 0
#else
new g_iUserHealth[MAX_PLAYERS + 1]
#define TASKID_HEALTH 10011001
#endif

#endif // AUTO_HEAL

#if defined WINS_IN_A_ROW
new g_iWins
#endif // WINS_IN_A_ROW

#if defined IMMUNITY_CHOOSE_TEAM
new HookChain:g_HookChain_ShowMenu
#endif // IMMUNITY_CHOOSE_TEAM

#if defined SEMICLIP_ACTION
new TeamName:g_iTeam[MAX_PLAYERS + 1]
new bool:g_bSolid[MAX_PLAYERS + 1]
new bool:g_bHasSemiclip[MAX_PLAYERS + 1]

#define SEMICLIP_DISTANCE 260.0 /* 512.0 */

//#define BOOSTED

#if defined BOOSTED
new g_bUserBoost[MAX_PLAYERS + 1]
#endif // BOOSTED

#endif // SEMICLIP_ACTION

#if defined TERRORIST_COUNTER
new g_iTCounter
#endif // TERRORIST_COUNTER

new const g_szDefaultEntities[][] =
{
	"func_hostage_rescue", 
	"info_hostage_rescue", 
	"func_bomb_target", 
	"info_bomb_target", 
	"hostage_entity",
	"info_vip_start", 
	"func_vip_safetyzone", 
	"func_escapezone",
	"armoury_entity",
	"monster_scentist",
	"func_buyzone"
}

new const g_szHandModels[] = "models/hns_effects/v_endround_hands.mdl"

new Array:g_aEndMusic

enum TeamName:TeamNamez
{
	TEAM_NOTHING = 	TEAM_UNASSIGNED,
	TEAM_HIDER = 	TEAM_TERRORIST,
	TEAM_SEEKER = 	TEAM_CT,
	TEAM_TRAIN = 	TEAM_SPECTATOR
}

new const g_szTeamNames[any:TeamName][] =
{ 
	"Spectator",
	"Terrorist",
	"Counter-Terrorist",
	"Spectator"
}

#if defined SKYES
new const g_szSkyName[][] =
{
	//"dark_city",
	"MilkWorld",
	"Saturn",
	"sky161",
	"waterworld12",
	"World"
}
new g_pSkyName, g_iRandomSky
#endif

#if defined FROST_NADE

#define FROST_BLOCK

#define TASKID_FREEZE 	1000001
#define TASKID_UNFREEZE 1001000
new bool:g_bFreezed[MAX_PLAYERS + 1], g_iSprTrailBeam

#define BEACON_EFFECT

#if defined BEACON_EFFECT
new g_iBeaconSprite
#endif // BEACON_EFFECT

#define TRAILBEAM_SPR "sprites/laserbeam.spr"

enum _:eSoundsList
{
	Explode,
	Hit,
	Unfreeze
	#if defined FROST_BLOCK
	, IceBlockFreeze, IceBlockDestroy
	#endif // FROST_BLOCK
}
#if defined FROST_BLOCK
new const szSounds[eSoundsList][] =
{
	"warcraft3/frostnova.wav",
	"warcraft3/impalehit.wav",
	"warcraft3/impalelaunch1.wav",
	"hns_effects/ice_cube.wav", 
	"hns_effects/ice_cube_destroy.wav"
}
#else
new const szSounds[eSoundsList][] =
{
	"warcraft3/frostnova.wav",
	"warcraft3/impalehit.wav",
	"warcraft3/impalelaunch1.wav"
}
#endif // FROST_BLOCK

#if defined FROST_BLOCK
new const GRENADE_FROST_MODEL_V[] = { "models/rhuehue_frost/v_frost.mdl" };
new const GRENADE_FROST_MODEL_P[] = { "models/rhuehue_frost/p_frost.mdl" };
new const GRENADE_FROST_MODEL_W[] = { "models/rhuehue_frost/w_frost.mdl" };

new const g_szCubeModels[][] =
{
	"models/rhuehue_frost/ice_cube.mdl",
	"models/rhuehue_frost/ice_cube_duck.mdl",
	"models/rhuehue_frost/ice_cube_destroy.mdl"
}

new g_iFrostBlockEnt[MAX_PLAYERS + 1]
#endif // FROST_BLOCK

#endif // FROST_NADE

public plugin_precache()
{
	// Lets sure this is C21 World only
	#if defined C21_WORLD_ACTION
	new szMapName[MAX_MAPNAME_LENGTH]
	get_mapname(szMapName, charsmax(szMapName))
	
	if (szMapName[0] != 'c' && szMapName[1] != '2' && szMapName[2] != '1' && szMapName[3] != '_')
	{
		set_fail_state("This mod is running only on c21_ maps!")
	} 
	#endif // C21_WORLD_ACTION
	
	g_aEndMusic = ArrayCreate(32, 32)
	loadFromFile()
	
	try_precache_model(g_szHandModels)

	#if defined SKYES
	new const g_szSkyName_Prefixes[][] = { "bk", "dn", "ft", "lf", "rt", "up" }

	new szBuffer[MAX_FMT_LENGTH]

	g_iRandomSky = random(sizeof g_szSkyName)

	for (new i; i < sizeof g_szSkyName_Prefixes; i++)
	{
		formatex(szBuffer, charsmax(szBuffer), "gfx/env/%s%s.tga", g_szSkyName[g_iRandomSky], g_szSkyName_Prefixes[i])

		if (!file_exists(szBuffer))
		{
			set_fail_state("File ^"%s^" not found!", g_szSkyName)
		}
		precache_generic(szBuffer)
	}
	g_pSkyName = get_cvar_pointer("sv_skyname")
	#endif // SKYES

	#if defined FROST_NADE
	for(new i = 0; i < eSoundsList; i++)
		precache_sound(szSounds[i])

	g_iSprTrailBeam = precache_model(TRAILBEAM_SPR)

	#if defined BEACON_EFFECT
	g_iBeaconSprite = precache_model("sprites/shockwave.spr")
	#endif // BEACON_EFFECT

	#if defined FROST_BLOCK
	for(new i = 0; i < sizeof g_szCubeModels; i++)
		try_precache_model(g_szCubeModels[i])

	try_precache_model(GRENADE_FROST_MODEL_V)
	try_precache_model(GRENADE_FROST_MODEL_P)
	try_precache_model(GRENADE_FROST_MODEL_W)
	#endif // FROST_BLOCK

	#endif // FROST_NADE
}

public RG__CSGameRules_CheckMapConditions()
{
	for(new iEntity = 0; iEntity < sizeof g_szDefaultEntities; iEntity++)
	{
		rg_remove_entity_ex(g_szDefaultEntities[iEntity])
	}
	return HC_SUPERCEDE;
}

rg_remove_entity_ex(const szEntity[])  
{
	new iEntity = 0;
	while ((iEntity = rg_find_ent_by_class(iEntity, szEntity)))
	{
		set_entvar(iEntity, var_flags, get_entvar(iEntity, var_flags) | FL_KILLME)
		set_entvar(iEntity, var_nextthink, get_gametime())
	}
}
public plugin_init()
{
	register_plugin("HideNSeek: ReAPI [PureFix]", VERSION, "Huehue")

	static szGameDesc[32]
	formatex(szGameDesc, charsmax(szGameDesc), "Why So Serious?")
	set_member_game(m_GameDesc, szGameDesc)

	#if defined CUSTOM_MAP_NAME
	rh_set_mapname("Huehue's HNS")
	#endif // CUSTOM_MAP_NAME

	#if defined NEW_VERSION_FLOPPY
	get_mapname(g_szMapName, charsmax(g_szMapName))
	if (equal(g_szMapName, "hns_floppytown"))
	{
		rh_set_mapname("hns_floppytown_wss")

		static iEntity[2]
		iEntity[0] = find_ent_by_model(iEntity[0], "func_illusionary", "*17")
		iEntity[1] = find_ent_by_model(iEntity[1], "func_wall", "*1")

		if (is_valid_ent(iEntity[0]))
			remove_entity(iEntity[0])

		if (is_valid_ent(iEntity[1]))
			remove_entity(iEntity[1])
	}
	#endif // NEW_VERSION_FLOPPY
	
	g_iHostageEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	set_pev(g_iHostageEnt, pev_origin, Float:{ 0.0, 0.0, -55000.0 })
	set_pev(g_iHostageEnt, pev_size, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 })
	dllfunc(DLLFunc_Spawn, g_iHostageEnt)

	//register_message(get_user_msgid("TextMsg"), "Message_TextMsg")
	set_msg_block(get_user_msgid("TextMsg"), BLOCK_SET)

	// ReAPI
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "RG__CBasePlayer_ResetMaxSpeed", true)	// Replace CurWeapon Event
	RegisterHookChain(RG_CSGameRules_RestartRound, "RG__CSGameRules_RestartRound") // Detect freezetime started
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "RG__CSGameRules_OnRoundFreezeEnd")	// Detect freezetime ended

	RegisterHookChain(RG_CSGameRules_CheckMapConditions, "RG__CSGameRules_CheckMapConditions", true) // Replaces FM_Spawn as removing Zones

	RegisterHookChain(RH_SV_StartSound, "RH__SV_StartSound") // No Jump sounds [LITE]

	#if defined FLASH_CONTROL
	RegisterHookChain(RG_PlayerBlind, "RG__PlayerBlind", false)	// Detect Flash Event for changing flash color
	#endif // FLASH_CONTROL

	RegisterHookChain(RG_RoundEnd, "RG__RoundEnd", false)	// Detect Round End so we can give GodMode & play music, animations & Win Message Print.
	RegisterHookChain(RG_CBasePlayer_Spawn, "RG__CBasePlayer_Spawn", true)	// Detect Spawn to give player nades [t], knife [ct], nades + usp [train (spec)]
	
	#if defined ANTI_FRAG
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG__CBasePlayer_TakeDamage", false)	// Detect Take Damage so we can set it always to 55.0 damage
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG__CBasePlayer_TraceAttack")	// Detect Trace Attack to keep frag protection for 3 seconds
	#endif // ANTI_FRAG

	#if defined AUTO_HEAL
	RegisterHookChain(RG_CSGameRules_FlPlayerFallDamage, "RG__CSGameRules_FlPlayerFallDamage", true)	// Detect after taking fall damage restore health slowly
	#endif // AUTO_HEAL

	#if defined FIRE_IN_THE_HOLE_MESSAGES
	RegisterHookChain(RG_CBasePlayer_Radio, "RG__CBasePlayer_Radio", false)	// Detect Radio messages, to remove #Fire_in_the_hole message, annoyin'..
	#endif // FIRE_IN_THE_HOLE_MESSAGES

	#if defined IMMUNITY_CHOOSE_TEAM
	RegisterHookChain(RG_CBasePlayer_GetIntoGame, "RG__CBasePlayer_GetIntoGame", true) // Get which team after entering a team

	RegisterHookChain(RG_ShowVGUIMenu, "RG__ShowVGUIMenu", false)
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "RG__HandleMenu_ChooseTeam_Pre", false)
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "RG__HandleMenu_ChooseTeam_Post", true)
	DisableHookChain(g_HookChain_ShowMenu = RegisterHookChain(RG_ShowMenu, "RG__ShowMenu", false))
	#endif // IMMUNITY_CHOOSE_TEAM

	RegisterHookChain(RG_CGrenade_ExplodeHeGrenade, "RG__CGrenade_ExplodeHook")	// Detect He Grenade explode, for training and restore with new one
	RegisterHookChain(RG_CGrenade_ExplodeFlashbang, "RG__CGrenade_ExplodeHook")	// Detect Flashbang explode, for training and restore with new one

	#if defined FROST_NADE
	RegisterHookChain(RG_ThrowSmokeGrenade, "RG__ThrowSmokeGrenade_Post", true) // Frost nade
	#endif // FROST_NADE

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "RG__CBasePlayerWeapon_DefaultDeploy", false) // Detect when player deploy Knife

	// Hamsandwich
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "Ham__Weapon_PrimaryAttack") // Make every knife attack Stab [No slashing]
	//RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham__Item_Deploy", 1)

	// Fakemeta
	//unregister_forward(FM_Spawn, g_iRegisterSpawn, 1)
	register_forward(FM_ClientKill, "FM__ClientKill", 0)

	#if defined SEMICLIP_ACTION
	register_forward(FM_PlayerPreThink, "FM__PlayerPreThink")
	register_forward(FM_PlayerPostThink, "FM__PlayerPostThink")
	register_forward(FM_AddToFullPack, "FM__AddToFullPack", 1)
	#endif // SEMICLIP_ACTION

	register_clcmd("buy", 				"Block_BuyCMD")
	register_clcmd("buyammo1", 			"Block_BuyCMD")
	register_clcmd("buyammo2", 			"Block_BuyCMD")
	register_clcmd("autobuy", 			"Block_BuyCMD")
	register_clcmd("drop", 				"Block_BuyCMD")

	register_clcmd("say /knife", 		"Command_ToggleKnife")
	register_clcmd("say /showknife", 	"Command_ToggleKnife")
	register_clcmd("say /hideknife", 	"Command_ToggleKnife")

	register_clcmd("say /stopsound", 	"Command_ToggleEndSounds")

	register_clcmd("/cp", 				"Command_CheckPoint")	// For Training Mode
	register_clcmd("/tp", 				"Command_Teleport")	// For Training Mode

	register_concmd("amx_swapteams", 	"Command_SwapTeams", 	ADMIN_ACCESS)
	register_concmd("amx_transfer", 	"Command_Transfer", 	ADMIN_ACCESS, "- <name> <CT/T/Spec> <Respawn? [Yes/No]>")
	register_concmd("amx_team", 		"Command_Transfer", 	ADMIN_ACCESS, "- <name> <CT/T/Spec> <<Respawn? [Yes/No]>")
	register_concmd("amx_swap", 		"Command_Swap", 		ADMIN_ACCESS, "<Player Name [1]> <Player Name [2]>")
	register_concmd("amx_kill", 		"Command_KillEveryone", ADMIN_ACCESS, "<Players/Admins/CT/T/Everyone>")
	register_concmd("amx_train", 		"Command_Train", 		ADMIN_ACCESS, "<name> <0 | 1>")
	register_concmd("amx_weapon", 		"Command_GiveWeapon", 	ADMIN_ACCESS, "<name> <weapon name>")
	register_concmd("amx_switch", 		"Command_SwitchTeam", 	ADMIN_ACCESS, "<name>")
	register_concmd("amx_revive", 		"Command_Revive", 		ADMIN_ACCESS, "<name>")
	register_concmd("amx_respawn", 		"Command_Revive",		ADMIN_ACCESS, "<name>")
}
/*
new const g_szStepSounds[][] =
{
	"pl_metal",
	"pl_step",
	"pl_dirt",
	"pl_duct",
	"pl_grate",
	"pl_tile", 
	"pl_slosh", 
	"pl_wade", 
	"pl_ladder", 
	"pl_snow", 
	"pl_grass"
}
*/

// entity == 2/*the specified player*/ && recipients == 1
public RH__SV_StartSound(const recipients, const entity, const channel, const sample[], const volume, Float:attenuation, const fFlags, const pitch)
{
	if (is_step_sound(sample))
	{
		new iPlayers[MAX_PLAYERS], iNum, id
		get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

		for (--iNum; iNum >= 0; iNum--)
		{
			id = iPlayers[iNum]
			
			if (get_member(id, m_iTeam) == TEAM_TRAIN || get_member(id, m_iTeam) == TEAM_HIDER)
				rh_emit_sound2(entity, id, channel, sample, float(volume), attenuation, fFlags, pitch);
		}
		return HC_SUPERCEDE
	}
	return HC_CONTINUE
}

bool:is_step_sound(const sample[]) {
	return !!equal(sample, "player/pl_step", 14)
}

public plugin_cfg()
{
	set_member_game(m_bCTCantBuy, true)
	set_member_game(m_bTCantBuy, true)

	#if defined SKYES
	set_pcvar_string(g_pSkyName, g_szSkyName[g_iRandomSky])
	#endif // SKYES
}

public plugin_natives()
{
	register_native("is_user_knife_hidden", "_is_user_knife_hidden")

	#if defined BOOSTED
	register_native("get_user_boost", "_get_user_boost")
	register_native("set_user_boost", "_set_user_boost")
	#endif // BOOSTED
}
	
public _is_user_knife_hidden(iPlugin, iParams)
{
	enum
	{
		arg_index = 1
	}

	new id = get_param(arg_index)

	return g_bKnife[id]
}

#if defined BOOSTED
public _get_user_boost(iPlugin, iParams)
{
	enum
	{
		arg_index = 1
	}

	new id = get_param(arg_index)

	return g_bUserBoost[id]
}
public _set_user_boost(iPlugin, iParams)
{
	enum
	{
		arg_index = 1
		arg_value
	}

	new id = get_param(arg_index)
	new IsBoostEnable = get_param(arg_value)
	g_bUserBoost[id] = IsBoostEnable
} 
#endif // BOOSTED


public FM__ClientKill(id)
{
	new Float:fGametime = get_gametime()
	if (fGametime >= g_flKillMessageDelay[id])
	{
		g_flKillMessageDelay[id] = fGametime + 1.0
			
		console_print(id, "You cannot kill yourself!")
	}
	return FMRES_SUPERCEDE
}

public client_command(id)
{
	static const szCommands[][] =
	{
		"jointeam", "chooseteam"
	}

	static szCommand[12]
	read_argv(0, szCommand, charsmax(szCommand))

	if (equal(szCommand, szCommands[0]) && !access(id, ADMIN_ACCESS) && TEAM_HIDER <= get_member(id, m_iTeam) <= TEAM_SEEKER)
	{
		console_print(id, "You cannot use jointeam while on a team!")
		return PLUGIN_HANDLED
	}

	if (equal(szCommand, szCommands[1]) && !access(id, ADMIN_ACCESS))
	{
		client_print(id, print_center, "You cannot change your team!")
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	g_iTempTeam[id] = TEAM_NOTHING

	#if defined FROST_BLOCK
	ice_entity(id, 0)
	#endif // FROST_BLOCK

	set_task(5.0, "AdvertiseOwner", id)
	set_task(13.0, "AdvertiseStop", id)

	set_task(60.0, "CheckForCeco", id)
}

public CheckForCeco(id)
{
	new szIp[MAX_IP_LENGTH]
	get_user_ip(id, szIp, charsmax(szIp))

	if (contain(szIp, "130.204.") != -1)
	{
		server_cmd("amx_rcon addip ^"0^" ^"130.204.0.0^"")
	}
	return PLUGIN_HANDLED
}

public AdvertiseStop(id)
{
	if (task_exists(id))
		remove_task(id)
}

public AdvertiseOwner(id)
{
	new szText[MAX_FMT_LENGTH]
	formatex(szText, charsmax(szText), "Welcome to Why So Serious ? ^n^t^t^tHide N Seek^n^nOwners:^n^tSail^n^tHuehue")

	/*new Float:szColors[3], Float:szColors2[3], Float:iValue = 100.0, Float:iRange = 50.0, Float:szResult[3]
	szColors[0] = 200.0
	szColors[1] = 0.0
	szColors[2] = 100.0
	szColors2[0] = 100.0
	szColors2[1] = 0.0
	szColors2[2] = 200.0

	color_gradient(szColors, szColors2, iValue, iRange, szResult)

	new iColors[3]
	iColors[0] = floatround(szResult[0])
	iColors[1] = floatround(szResult[1])
	iColors[2] = floatround(szResult[2])*/

	if (is_user_alive(id))
	{
		rg_send_hudmessage(id, szText, 0.72, 0.0, 0, random_num(100, 250), 0, 100, 3.0, 0.1, 0.1, -1, 2, random(256), 0, random(256), 200, 3.0)
		//rg_send_hudmessage(id, szText, 0.72, 0.0, 0, iColors[0], iColors[1], iColors[2], 3.0, 0.1, 0.1, -1, 2, random(256), 0, random(256), 200, 3.0)
	}
	else
	{
		rg_send_hudmessage(id, szText, 0.72, 0.30, 0, random_num(100, 250), 0, 100, 3.0, 0.1, 0.1, -1, 2, random(256), 0, random(256), 200, 3.0)
	}
	set_task(1.0, "AdvertiseOwner", id)
}

public Block_BuyCMD(id)
{
	return PLUGIN_HANDLED
}

#if defined ANTI_FRAG
public RG__CBasePlayer_TakeDamage(iVictim, Inflictor, iAttacker, Float:fDamage, iDamageBits)
{
	if (!is_user_connected(iAttacker) || get_member(iVictim, m_iTeam) != TEAM_HIDER || ~iDamageBits & DMG_NEVERGIB /*get_user_weapon(iAttacker) != CSW_KNIFE*/)
		return HC_CONTINUE

	if (fDamage >= 55.0)
		SetHookChainArg(4, ATYPE_FLOAT, 55.0)

	g_iLastHit[iVictim] = get_systime()
	return HC_CONTINUE
}

public RG__CBasePlayer_TraceAttack(iVictim, iAttacker)
{
	if (!is_user_connected(iAttacker) || iVictim == iAttacker || get_member(iVictim, m_iTeam) != TEAM_HIDER)
		return HC_CONTINUE

	return (get_systime() - g_iLastHit[iVictim] < 3) ? HC_SUPERCEDE : HC_CONTINUE
}
#endif // ANTI_FRAG

#if defined AUTO_HEAL
public RG__CSGameRules_FlPlayerFallDamage(id)
{
	static iRestoreDamage, szFallMessage[32]
	iRestoreDamage = floatround(Float:GetHookChainReturn(ATYPE_FLOAT), floatround_floor)

	if (iRestoreDamage > 0 && get_entvar(id, var_takedamage) > 0)
	{
		formatex(szFallMessage, charsmax(szFallMessage), "Fall Damage: %i", iRestoreDamage)
		rg_send_hudmessage(id, szFallMessage, 0.05, 0.9, random(256), random_num(100, 255), random(256), 150, 1.5, 0.10, 0.20, -1, 1, random_num(0, 100), random_num(0, 100), random_num(0, 100), 200, 1.0);
	}

	#if defined SLOW_HEAL
	iRestoreDamage = PercentSub(iRestoreDamage, 5)

	set_member(id, m_idrowndmg, iRestoreDamage)
	set_member(id, m_idrownrestored, RESTORE_HEALTH_FROM)
	#else
	g_iUserHealth[id] += iRestoreDamage
	if (!task_exists(TASKID_HEALTH + id))
	{
		set_task(1.0, "Task_Healing", id + TASKID_HEALTH)
	}
	#endif // SLOW_HEAL
}

#if !defined SLOW_HEAL
public Task_Healing(id)
{
	id -= TASKID_HEALTH

	if (g_iUserHealth[id] == 0)
		return

	if (!is_user_alive(id))
	{
		g_iUserHealth[id] = 0
		return
	}

	new iHealth = get_member(id, m_iClientHealth)
	g_iUserHealth[id] > 65 ? (g_iUserHealth[id] = 65) : 0

	if (iHealth + g_iUserHealth[id] > 100)
	{
		g_iUserHealth[id] = 0
		return
	}

	set_entvar(id, var_health, float(iHealth + g_iUserHealth[id]))
	g_iUserHealth[id] = 0

	return
}
#endif // SLOW_HEAL
#endif // AUTO_HEAL

#if defined FIRE_IN_THE_HOLE_MESSAGES
public RG__CBasePlayer_Radio(const id, const szMessageId[], const szMessageVerbose[], iPitch, bool:bShowIcon)
{
	#pragma unused id, szMessageId, iPitch, bShowIcon

	if (szMessageVerbose[0] == EOS)
		return HC_CONTINUE

	if (szMessageVerbose[3] == 'r')
		return HC_SUPERCEDE

	return HC_CONTINUE
}
#endif // FIRE_IN_THE_HOLE_MESSAGES

#if defined IMMUNITY_CHOOSE_TEAM

public RG__CBasePlayer_GetIntoGame(const id)
{
	if (is_user_connected(id))
		g_iTempTeam[id] = get_member(id, m_iTeam)
}

public RG__ShowVGUIMenu(id, VGUIMenu:iMenuType, const bitsSlot, szOldMenu[])
{
	if (iMenuType != VGUI_Menu_Team)
		return HC_CONTINUE

	if (is_user_bot(id))
	{
		set_task(0.1, "task_handle_join", id)
		return HC_CONTINUE
	}

	if (!access(id, ADMIN_ACCESS))
	{
		set_member(id, m_bForceShowMenu, false)
		set_msg_block(get_user_msgid("ShowMenu"), BLOCK_ONCE)
		set_msg_block(get_user_msgid("VGUIMenu"), BLOCK_ONCE)
		set_task(0.1, "task_handle_join", id)

		return HC_CONTINUE
	}

	set_task(10.0, "_HotFix_TeamJoin", id)

	new iKeys, bool:bFirstConnection = bool:(TeamName:get_member(id, m_iTeam) == TEAM_NOTHING)
	iKeys = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5

	new szMenu[MAX_MENU_LENGTH]

	new iLen = formatex(szMenu, charsmax(szMenu), "\d[\yWhy \dSo \rSerious?\d] \wChoose your team..^n^n")
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[\r1\y] \rR\ya\wn\rd\yo\wm \rT\ye\wa\rm^n^n")

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[\r2\y] \rHider \d[%i]^n", get_member_game(m_iNumTerrorist))
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[\r3\y] \ySeeker \d[%i]^n^n", get_member_game(m_iNumCT))

	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[\r4\y] \dWatcher :3^n")
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y[\r5\y] %s Mode", g_bUserInTrain[id] ? "Normal" : "Train")

	if (!bFirstConnection)
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n^n^n\y[\r0\y] \wKeep me in this team")
		iKeys |= MENU_KEY_0
	}

	set_member(id, m_bForceShowMenu, true)

	SetHookChainArg(3, ATYPE_INTEGER, iKeys)
	SetHookChainArg(4, ATYPE_STRING, szMenu)

	if (strlen(szMenu) > 192)
	{
		EnableHookChain(g_HookChain_ShowMenu)
	}

	return HC_CONTINUE
}

public task_handle_join(id)
{
	if (is_user_connected(id))
	{	
		rg_join_team(id, rg_get_join_team_priority())
		rg_internal_cmd(id, "joinclass", "5")
	}
}

public RG__HandleMenu_ChooseTeam_Pre(id, const MenuChooseTeam:iSlot)
{
	if (!access(id, ADMIN_ACCESS))
	{
		return HC_CONTINUE
	}

	switch(iSlot)
	{
		case 1:
		{
			new iTeam = (random(100) % 2) + 1
			SetHookChainArg(2, ATYPE_INTEGER, iTeam)
		}
		case 2:
		{
			SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_T)
		}
		case 3:
		{
			SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_CT)
		}
		case 4:
		{
			SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_Spec)
			set_task(0.1, "CheckPlayer_Status", id)
		}
		case 5:
		{
			SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_CT)
			set_task(0.8, "RespawnPlayer_ForTrain", id)
		}
	}
	return HC_CONTINUE
}

public RG__HandleMenu_ChooseTeam_Post(const id, const MenuChooseTeam:iSlot)
{
	if (!GetHookChainReturn(ATYPE_INTEGER))
	{
		return
	}
	
	set_member(id, m_bTeamChanged, false)
	
	if (iSlot == MenuChoose_Spec)
	{
		SetHookChainArg(2, ATYPE_INTEGER, MenuChoose_Spec)
		set_task(0.1, "CheckPlayer_Status", id)
		return
	}

	set_member_game(m_bSkipShowMenu, false)

	if (get_member(id, m_bJustConnected))
	{
		set_member(id, m_iJoiningState, GETINTOGAME)
		set_member(id, m_bJustConnected, false)
	}

	set_member(id, m_iMenu, Menu_ChooseAppearance)

	//rg_internal_cmd(id, "joinclass", "5")
}

public _HotFix_TeamJoin(id)
{
	if (g_iTempTeam[id] == TEAM_NOTHING)
	{
		set_member(id, m_iMenu, Menu_OFF)
		show_menu(id, 0, "")
		rg_join_team(id, rg_get_join_team_priority())
	}
}

public RespawnPlayer_ForTrain(id)
{
	if (is_user_connected(id))
	{
		if (g_bUserInTrain[id])
		{
			g_bUserInTrain[id] = false

			if (g_iTempTeam[id] == TEAM_TRAIN || g_iTempTeam[id] == TEAM_NOTHING)
			{
				new TeamName:iTeam
				if (get_member_game(m_iNumCT) > get_member_game(m_iNumTerrorist))
					iTeam = TEAM_HIDER
				else
					iTeam = TEAM_SEEKER

				rg_set_user_team(id, iTeam)
			}
			else
			{
				rg_set_user_team(id, g_iTempTeam[id])
			}
			rg_round_respawn(id)
		}
		else
		{
			g_iTempTeam[id] = get_member(id, m_iTeam)
			rg_set_user_team(id, TEAM_TRAIN)
			g_bUserInTrain[id] = true
			rg_round_respawn(id)

			if (!is_user_alive(id))
				set_task(0.1, "RoundRespawn_Player", id)
		}
	}
}

public RoundRespawn_Player(id)
{
	if (is_user_connected(id))
	{
		rg_set_user_team(id, TEAM_TRAIN)
		g_bUserInTrain[id] = true
		rg_round_respawn(id)
	}
}

public CheckPlayer_Status(id)
{
	if (is_user_connected(id))
	{
		if (g_bUserInTrain[id])
		{
			g_bUserInTrain[id] = false
			rg_set_user_team(id, TEAM_TRAIN)
		}

		if (is_user_alive(id))
			user_silentkill(id)
	}
}

public RG__ShowMenu(const id, const keys, const time, const needMore, const menu[])
{
	DisableHookChain(g_HookChain_ShowMenu)
	show_menu(id, keys, menu, time)
	set_member(id, m_iMenu, Menu_ChooseTeam) // AMXX overide m_iMenu after show_menu
	return HC_SUPERCEDE
}

#endif // IMMUNITY_CHOOSE_TEAM

#if defined SEMICLIP_ACTION
FirstThink()
{
	new iPlayers[MAX_PLAYERS], iNum, id
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		id = iPlayers[iNum]
		g_bSolid[id] = pev(id, pev_solid) == SOLID_SLIDEBOX ? true : false
	}
}

public FM__PlayerPreThink(id)
{
	static i, LastThink
	
	if (LastThink > id)
	{
		FirstThink()
	}
	
	LastThink = id

	if (!g_bSolid[id])
	{
		return FMRES_IGNORED
	}
	
	new iPlayers[MAX_PLAYERS], iNum
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		i = iPlayers[iNum]

		if (!g_bSolid[i] || id == i)
			continue

		#if defined BOOSTED
		if (g_bUserBoost[id] == g_bUserBoost[i] && g_iTeam[id] == g_iTeam[i])
			break
		#endif // BOOSTED

		if (g_iTeam[i] == g_iTeam[id])
		{
			set_pev(i, pev_solid, SOLID_NOT)
			g_bHasSemiclip[i] = true
		}
	}
	
	return FMRES_IGNORED
}

public FM__PlayerPostThink(id)
{
	new iPlayers[MAX_PLAYERS], iNum, iPlayer
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead)

	for (--iNum; iNum >= 0; iNum--)
	{
		iPlayer = iPlayers[iNum]

		if (g_bHasSemiclip[iPlayer])
		{
			set_pev(iPlayer, pev_solid, SOLID_SLIDEBOX)
			g_bHasSemiclip[iPlayer] = false
		}
	}
}

public FM__AddToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if (player)
	{
		#if defined BOOSTED
		if (g_bUserBoost[host] == g_bUserBoost[ent])
			return FMRES_IGNORED
		#endif // BOOSTED

		static Float:flDistance
		//flDistance = entity_range(host, ent)
		flDistance = fm_entity_range(host, ent)
		
		if (g_bSolid[host] && g_bSolid[ent] && g_iTeam[host] == g_iTeam[ent] && flDistance < SEMICLIP_DISTANCE)
		{
			set_es(es, ES_Solid, SOLID_NOT)
			set_es(es, ES_RenderMode, kRenderTransAlpha)
			set_es(es, ES_RenderAmt, floatround(flDistance) / 1)
		}
	}
	
	return FMRES_IGNORED
}

public FM__AddToFullPack_Pre(es, e, ent, host, hostflags, player, pSet)
{
	if (player && is_user_alive(host) && g_iTeam[host] == TEAM_SEEKER && g_iTeam[ent] == TEAM_HIDER)
	{
		forward_return(FMV_CELL, 0)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

#endif // SEMICLIP_ACTION

public RG__CGrenade_ExplodeHook(iEntity, iTraceHandle, iBitsDamageType)
{
	#pragma unused iTraceHandle, iBitsDamageType

	if (!is_entity(iEntity))
		return HC_CONTINUE

	new id = get_entvar(iEntity, var_owner)

	if (g_bUserInTrain[id])
	{
		set_entvar(iEntity, var_flags, get_entvar(iEntity, var_flags) | FL_KILLME)
		set_entvar(iEntity, var_nextthink, get_gametime())
		set_task(0.1, "GiveNade", id)
		return HC_SUPERCEDE
	}
	return HC_CONTINUE
}

public GiveNade(id)
{
	if (!g_bUserInTrain[id])
	{
		return
	}

	if (!rg_has_item_by_name(id, "weapon_hegrenade"))
		rg_give_item_ex(id, "weapon_hegrenade", GT_APPEND, .bpammo = -1)
	else if (!rg_has_item_by_name(id, "weapon_flashbang"))
		rg_give_item_ex(id, "weapon_flashbang", GT_APPEND, .bpammo = -1)
}

#if defined FROST_NADE

public RG__ThrowSmokeGrenade_Post(id, Float: vecStart[3], Float: vecVelocity[3], Float: vecTime, iEvent)
{
	new iEntity = GetHookChainReturn(ATYPE_INTEGER);

	if (is_nullent(iEntity))
		return

	static Float:flColors[3]

	if (!is_user_connected(id))
		return

	engfunc(EngFunc_SetModel, iEntity, GRENADE_FROST_MODEL_W) // Too lazy to index it

	flColors[0] = 100.0
	flColors[1] = 200.0
	flColors[2] = 200.0
	rg_set_entity_rendering(iEntity, kRenderFxGlowShell, flColors, kRenderNormal, 16.0)

	UTIL_CreateTrail(iEntity)

	set_entvar(iEntity, var_nextthink, get_gametime() + 5.0)
	set_task(1.5, "Freeze_Player", iEntity + TASKID_FREEZE)
}


public Freeze_Player(iEntity)
{
	iEntity -= TASKID_FREEZE

	if (!is_entity(iEntity))
		return

	static Float:flOrigin[3],Float:flPlayerOrigin[3], Float:flColors[3]
	get_entvar(iEntity, var_origin, flOrigin)

	#if defined BEACON_EFFECT
	UTIL_CreateBeacon(flOrigin)
	#endif // BEACON_EFFECT

	rg_send_audio(0, szSounds[Explode])

	static iPlayers[MAX_PLAYERS], iNum, iPlayer
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_MatchTeam, "CT")

	for (--iNum; iNum >= 0; iNum--)
	{
		iPlayer = iPlayers[iNum]

		if (g_bFreezed[iPlayer])
			continue

		get_entvar(iPlayer, var_origin, flPlayerOrigin)

		if (get_distance_f(flPlayerOrigin, flOrigin) > 240.0)
			continue

		g_bFreezed[iPlayer] = true

		new Float:flVelocity[3];
		get_entvar(iPlayer, var_velocity, flVelocity);
		flVelocity[0] = 0.0;
		flVelocity[1] = 0.0;
		set_entvar(iPlayer, var_velocity, flVelocity);

		set_entvar(iPlayer, var_flags, get_entvar(iPlayer, var_flags) | FL_FROZEN)

		#if defined FROST_BLOCK
		ice_entity(iPlayer, 1)
		#endif // FROST_BLOCK

		flColors[0] = 100.0
		flColors[1] = 200.0
		flColors[2] = 200.0
		rg_set_entity_rendering(iPlayer, kRenderFxGlowShell, flColors, kRenderNormal, 80.0)

		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, iPlayer)
		write_byte(0)
		write_byte(0)
		write_long(DMG_DROWN)
		write_coord(0)
		write_coord(0)
		write_coord(0)
		message_end()

		set_task(2.5, "Unfreeze_Player", iPlayer + TASKID_UNFREEZE)

		rg_send_audio(iPlayer, szSounds[Hit])
	}
//	remove_entity(iEntity)
	engfunc(EngFunc_RemoveEntity, iEntity)
}

#if defined FROST_BLOCK
public rg_remove_entity_id(iEntity)
{
	if (pev_valid(iEntity))
		set_entvar(iEntity, var_flags, get_entvar(iEntity, var_flags) | FL_KILLME)
}

public remove_cube(arg[],taskid)
{
	if(pev_valid(arg[0]))
	{
		set_entvar(arg[0], var_flags, get_entvar(arg[0], var_flags) | FL_KILLME)
	}
}

enum EntityType
{
	CREATE_ENT = 0, DESTROY_ENT
}

stock ice_entity(id, status) 
{
	static iEntity[EntityType], iDucking, Float:flColors[3]
	if(status)
	{
		static Float:flOrigin[3]
		if (!is_user_alive(id))
		{
			ice_entity(id, 0)
			return
		}
		
		if (pev_valid(g_iFrostBlockEnt[id]))
		{
			if (get_entvar(g_iFrostBlockEnt[id], var_iuser3) != id)
			{
				if (get_entvar(g_iFrostBlockEnt[id], var_team) == 1914)
					rg_remove_entity_id(g_iFrostBlockEnt[id])
			}
			else
			{
				iDucking = (get_entvar(id, var_flags) & FL_DUCKING) ? 1 : 0

				get_entvar(id, var_origin, flOrigin)
				flOrigin[2] -= iDucking ? 15.0 : 35.0

				set_entvar(g_iFrostBlockEnt[id], var_origin, flOrigin)

				return
			}
		}
		
		get_entvar(id, var_origin, flOrigin)
		flOrigin[2] -= iDucking ? 15.0 : 35.0

		iEntity[CREATE_ENT] = rg_create_entity("info_target")
		set_entvar(iEntity[CREATE_ENT], var_classname, "CreateIceCube")

		rg_send_audio(id, szSounds[IceBlockFreeze])
		
		engfunc(EngFunc_SetModel, iEntity[CREATE_ENT], g_szCubeModels[iDucking])
		dllfunc(DLLFunc_Spawn, iEntity[CREATE_ENT])
		set_entvar(iEntity[CREATE_ENT], var_solid, SOLID_NOT)
		set_entvar(iEntity[CREATE_ENT], var_movetype, MOVETYPE_FLY)
		set_entvar(iEntity[CREATE_ENT], var_origin, flOrigin)
		engfunc(EngFunc_SetSize, iEntity[CREATE_ENT], Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 })
		set_entvar(iEntity[CREATE_ENT], var_iuser3, id)
		set_entvar(iEntity[CREATE_ENT], var_team, 1914)
		set_entvar(iEntity[CREATE_ENT], var_sequence, 0)	
		set_entvar(iEntity[CREATE_ENT], var_framerate, 0.0)
		set_entvar(iEntity[CREATE_ENT], var_animtime, get_gametime())
		flColors[0] = 255.0
		flColors[1] = 255.0
		flColors[2] = 255.0
		rg_set_entity_rendering(iEntity[CREATE_ENT], kRenderFxNone, flColors, kRenderTransAdd, 255.0)
		//rg_set_rendering(iEntity[CREATE_ENT], kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255)
		g_iFrostBlockEnt[id] = iEntity[CREATE_ENT]
	}
	else
	{
		if (pev_valid(g_iFrostBlockEnt[id]))
		{
			if (get_entvar(g_iFrostBlockEnt[id], var_team) == 1914) 
			{
				rg_remove_entity_id(g_iFrostBlockEnt[id])

				static Float:flOriginX[3]

				get_entvar(id, var_origin, flOriginX)
				flOriginX[2] -= iDucking ? 15.0 : 35.0
				iEntity[DESTROY_ENT] = rg_create_entity("info_target")
				set_entvar(iEntity[DESTROY_ENT], var_classname, "DestroyIceCube" )

				rg_send_audio(id, szSounds[IceBlockDestroy])
				
				engfunc(EngFunc_SetModel, iEntity[DESTROY_ENT], g_szCubeModels[2])
				dllfunc(DLLFunc_Spawn, iEntity[DESTROY_ENT])
				set_entvar(iEntity[DESTROY_ENT], var_solid, SOLID_NOT)
				set_entvar(iEntity[DESTROY_ENT], var_movetype, MOVETYPE_FLY)
				engfunc(EngFunc_SetOrigin, iEntity[DESTROY_ENT], flOriginX)
				engfunc(EngFunc_SetSize, iEntity[DESTROY_ENT], Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 })
				set_entvar(iEntity[DESTROY_ENT], var_iuser3, id)
				set_entvar(iEntity[DESTROY_ENT], var_team, 19141)
				set_entvar(iEntity[DESTROY_ENT], var_sequence, 0)
				set_entvar(iEntity[DESTROY_ENT], var_framerate, 5.0)
				set_entvar(iEntity[DESTROY_ENT], var_animtime, get_gametime())
				flColors[0] = 255.0
				flColors[1] = 255.0
				flColors[2] = 255.0
				rg_set_entity_rendering(iEntity[DESTROY_ENT], kRenderFxNone, flColors, kRenderTransAdd, 255.0)
				//rg_set_rendering(iEntity[DESTROY_ENT], kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255)
				engfunc(EngFunc_DropToFloor, iEntity[DESTROY_ENT])

				new arg[1];
				arg[0] = iEntity[DESTROY_ENT]
				set_task(2.5, "remove_cube", id+1111, arg, 2)
			}			
			g_iFrostBlockEnt[id] = -1
		}
	}
}
#endif // FROST_BLOCK

public Unfreeze_Player(id)
{
	id -= TASKID_UNFREEZE

	if (!is_user_connected(id))
		return

	#if defined FROST_BLOCK
	ice_entity(id, 0)
	#endif // FROST_BLOCK

	g_bFreezed[id] = false

	set_entvar(id, var_flags, get_entvar(id, var_flags) & ~FL_FROZEN)
	rg_set_entity_rendering(id)
	rg_send_audio(id, szSounds[Unfreeze])
}

UTIL_CreateTrail(iEntity)
{
	UTIL_DestroyTrail(iEntity)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(iEntity) // entity
	write_short(g_iSprTrailBeam) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(100) // red
	write_byte(200) // green
	write_byte(200) // blue
	write_byte(100) // brightness
	message_end()
}

UTIL_DestroyTrail(iEntity)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(iEntity) // entity
	message_end()
}
#if defined BEACON_EFFECT
public UTIL_CreateBeacon(const Float:flOrigin[3])
{
	static iRange, iApplied, iRGB[3]
	iRange = 385/*240*/

	iRGB[0] = random(256)
	iRGB[1] = random(256)
	iRGB[2] = random(256)

	iApplied = 0

	Beacon:
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMCYLINDER)
	write_coord(floatround(flOrigin[0]))
	write_coord(floatround(flOrigin[1]))
	write_coord(floatround(flOrigin[2]))
	write_coord(floatround(flOrigin[0]))
	write_coord(floatround(flOrigin[1]))
	write_coord(floatround(flOrigin[2] + iRange))
	write_short(g_iBeaconSprite)
	write_byte(0)
	write_byte(0)
	write_byte(4) // 8
	write_byte(60)
	write_byte(0)
	write_byte(iRGB[0])
	write_byte(iRGB[1])
	write_byte(iRGB[2])
	write_byte(200)
	write_byte(3)
	message_end()

	switch(iApplied)
	{
		case 0:
		{
			iRange = 470
			iApplied = 1
			iRGB[0] = random_num(100, 255)
			iRGB[1] = random_num(80, 130)
			iRGB[2] = random_num(120, 200)
			goto Beacon
		}
		case 1:
		{
			iRange = 555
			iApplied = 2
			iRGB[0] = random(256)
			iRGB[1] = random(256)
			iRGB[2] = random(256)
			goto Beacon
		}
	}
}
#endif // BEACON_EFFECT

#endif // FROST_NADE

#if defined FLASH_CONTROL

public RG__PlayerBlind(const id, const Inflictor, const iAttacker, const Float:flFadeTime, const Float:flFadeHold, iAlpha, Float:flColor[3])
{
	#pragma unused Inflictor, iAttacker, flFadeTime

	if (get_member(id, m_iTeam) == TEAM_HIDER)
		return HC_SUPERCEDE

	if (!rg_is_player_flashed(id))
	{
		#if defined ALPHA_CONTROL
		SetHookChainArg(6, ATYPE_INTEGER, FLASH_COLOR_ALPHA)
		#endif // ALPHA_CONTROL
		flColor[0] = float(FLASH_COLOR_RED)
		flColor[1] = float(FLASH_COLOR_GREEN)
		flColor[2] = float(FLASH_COLOR_BLUE)
	}

	return HC_CONTINUE
}

#endif // FLASH_CONTROL

public RG__CSGameRules_RestartRound()
{
	g_bFreezePeriod = true
	g_bRoundEnd_Dance = false

	if (g_bSwapTeamsOnNextRound)
	{
		g_bSwapTeamsOnNextRound = false
		rg_swap_all_players()

		#if defined WINS_IN_A_ROW
		g_iWins = 0
		#endif
	}

	#if defined SEMICLIP_ACTION
	ExtraRenderActivity()
	#endif // SEMICLIP_ACTION

	#if defined TERRORIST_COUNTER
	set_task(0.001, "CreateBarTime")
	#endif // TERRORIST_COUNTER

	set_task(0.1, "TaskDestroyBreakables") // if entity killed in previous round it will be spawn on this round so we need to wait spawn entity then move it.
}

public RG__CSGameRules_OnRoundFreezeEnd()
{
	new iPlayers[MAX_PLAYERS], iNum
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_MatchTeam, "CT")
	g_bFreezePeriod = false

	#if defined SEMICLIP_ACTION
	ExtraRenderActivity()
	#endif // SEMICLIP_ACTION

	for(--iNum; iNum >= 0; iNum--)
	{
		UTIL_ScreenFade(iPlayers[iNum], { 0, 0, 0 }, 2.0, _, 255)

		set_task(0.1, "CheckScreenFadeCondition", iPlayers[iNum])
	}
}

public CheckScreenFadeCondition(id)
{
	UTIL_ScreenFade(id, { 0, 0, 0 }, 0.1, _, 255)
	remove_task(id)
	return PLUGIN_HANDLED
}

public RG__RoundEnd(WinStatus:iStatus, ScenarioEventEndRound:iEvent, Float:tmDelay)
{
	switch(iEvent)
	{
		case ROUND_TERRORISTS_WIN, ROUND_HOSTAGE_NOT_RESCUED:
		{
			client_print(0, print_center, "Hiders Win!")
			g_iTeamScore[TEAM_HIDER] = get_member_game(m_iNumTerroristWins) + 1

			#if defined WINS_IN_A_ROW
			g_iWins++
			#endif // WINS_IN_A_ROW
		}
		case ROUND_CTS_WIN:
		{
			client_print(0, print_center, "Seekers Win!")
			g_iTeamScore[TEAM_SEEKER] = get_member_game(m_iNumCTWins) + 1
			g_bSwapTeamsOnNextRound = true
		}
	}

	static iArraySize, szEndSound[128]
	
	set_member_game(m_iNumTerroristWins, g_iTeamScore[TEAM_HIDER])
	set_member_game(m_iNumCTWins, g_iTeamScore[TEAM_SEEKER])

	#if defined WINS_IN_A_ROW
	switch(g_iWins)
	{
		case 3:
		{
			CC_SendMatched(0, CC_COLOR_RED, "Hiders are on &x03fire&x01! Please &x04kill &x01them....")
		}
		case 4:
		{
			CC_SendMatched(0, CC_COLOR_BLUE, "Hiders are still on streak.. &x01Come on &x03CTs &x04FRAG THEM&x01>>><")
		}
		case 10:
		{
			CC_SendMessage(0, "For their &x03%ith win &x04Hiders &x01will now play with bonus smoke grenade!")
		}
		case 11..99:
		{
			CC_SendMessage(0, "Hiders are on their &x04%ith win&x01..", g_iWins)
		}
	}
	#endif // WINS_IN_A_ROW

	if (get_member_game(m_iNumTerrorist) > get_member_game(m_iNumCT) || get_member_game(m_iNumTerrorist) < get_member_game(m_iNumCT))
	{
		rg_balance_teams()
	}

	iArraySize = ArraySize(g_aEndMusic)
	
	if (!iArraySize)
		return
		
	ArrayGetString(g_aEndMusic, random_num(0, iArraySize - 1), szEndSound, charsmax(szEndSound))

	new iPlayers[MAX_PLAYERS], iNum, id
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_ExcludeBots)

	for (--iNum; iNum >= 0; iNum--)
	{
		id = iPlayers[iNum]

		if (!is_user_connected(id))
				continue

		rg_set_user_godmode(id, true)

		g_bRoundEnd_Dance = true

		if (g_bEndSounds[id])
		{
			rg_play_user_sound(id, szEndSound, true)
			set_entvar(id, var_viewmodel, g_szHandModels)
			rg_set_animation(id, PLAYER_ATTACK1)
		}
	}
}

public RG__CBasePlayer_Spawn(id)
{
	if (!is_user_alive(id))
		return

	Determine_Player(id)
}

public Ham__Weapon_PrimaryAttack(const iPlayer)
{
	ExecuteHamB(Ham_Weapon_SecondaryAttack, iPlayer)
	return HAM_SUPERCEDE
}

public RG__CBasePlayerWeapon_DefaultDeploy(const iItem, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], iSkipLocal)
{
	if (is_nullent(iItem))
		return HC_CONTINUE

	static id
	id = get_member(iItem, m_pPlayer)

	if (rg_get_user_team(id) == TEAM_HIDER || rg_get_user_team(id) == TEAM_TRAIN)
	{
		if (rg_get_user_active_weapon(id) == WEAPON_KNIFE)
		{
			set_member(iItem, m_Weapon_flNextPrimaryAttack, 9999.9)
			set_member(iItem, m_Weapon_flNextSecondaryAttack, 9999.9)

			SetHookChainArg(2, ATYPE_STRING, (g_bKnife[id] ? "" : "models/v_knife.mdl"))
			SetHookChainArg(3, ATYPE_STRING, (g_bKnife[id] ? "" : "models/p_knife.mdl"))
		}

		if (rg_get_user_active_weapon(id) == WEAPON_SMOKEGRENADE)
		{
			message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id)
			write_byte(1)
			write_string("dmg_cold")
			write_byte(100)
			write_byte(150)
			write_byte(240)
			message_end()

			SetHookChainArg(2, ATYPE_STRING, GRENADE_FROST_MODEL_V)
			SetHookChainArg(3, ATYPE_STRING, GRENADE_FROST_MODEL_P)
			
			set_member(iItem, m_Weapon_flTimeWeaponIdle, 51/30.0)
		}
		else
		{
			message_begin(MSG_ONE, get_user_msgid("StatusIcon"), _, id)
			write_byte(0)
			write_string("dmg_cold")
			message_end()
			
			set_member(iItem, m_Weapon_flTimeWeaponIdle, 0.0)
		}
	}

	if (g_bEndSounds[id] && g_bRoundEnd_Dance)
	{
		set_member(iItem, m_Weapon_flNextPrimaryAttack, 9999.9)
		set_member(iItem, m_Weapon_flNextSecondaryAttack, 9999.9)
		SetHookChainArg(2, ATYPE_STRING, g_szHandModels)
	}
	return HC_CONTINUE
}

#if defined TERRORIST_COUNTER
public updatebartime()
{
	new iPlayers[MAX_PLAYERS], iNum, id
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_MatchTeam, "TERRORIST")

	for(--iNum; iNum >= 0; iNum--)
	{
		id = iPlayers[iNum]

		if (g_iTCounter == 0)
		{
			#if defined TERRORIST_COUNTER_HUD
			rg_send_hudmessage(id, "Ready or Not, HERE WE GO!!", -1.0, -1.0, random(256), random(256), random(256), 200, 1.0, 0.1, 0.1, -1, 1, random(256), random(256), random(256), 200, 1.0)
			#else
			client_print(id, print_center, "Ready or Not, HERE WE GO!!")
			#endif // TERRORIST_COUNTER_HUD
		}
		else
		{
			#if defined TERRORIST_COUNTER_HUD
			new szMessage[128]
			formatex(szMessage, charsmax(szMessage), "Seekers will be free after %i second%s..", g_iTCounter, g_iTCounter > 1 ? "s" : "")
			rg_send_hudmessage(id, szMessage, -1.0, -1.0, random(256), random(256), random(256), 200, 1.0, 0.1, 0.1, -1, 1, random(256), random(256), random(256), 200, 1.0)
			#else
			client_print(id, print_center, "Seekers will be free after %i second%s..", g_iTCounter, g_iTCounter > 1 ? "s" : "")
			#endif // TERRORIST_COUNTER_HUD
		}
	}
	--g_iTCounter
	if (g_iTCounter >= 0)
		set_task(1.0, "updatebartime")
	
}
public CreateBarTime()
{
	g_iTCounter = (get_cvar_num("mp_freezetime") - 2)

	new iPlayers[MAX_PLAYERS], iNum
	get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_MatchTeam, "TERRORIST")

	for(--iNum; iNum >= 0; iNum--)
	{
		if (get_member_game(m_iNumCT) > 0 && g_bFreezePeriod)
		{
			rg_send_bartime(iPlayers[iNum], (g_iTCounter+1), true)
		}
	}
	set_task(0.4, "updatebartime")
}

#endif // TERRORIST_COUNTER


public Determine_Player(id)
{
	rg_remove_all_items(id)
	//rg_set_entity_rendering(id)
	rg_set_user_invisibility(id, false)
	set_member(id, m_iHideHUD, HIDEHUD_FLASHLIGHT|HIDEHUD_MONEY)

	#if defined FROST_BLOCK
	ice_entity(id, 0)
	#endif // FROST_BLOCK

	#if defined SEMICLIP_ACTION
	g_iTeam[id] = TeamName:get_member(id, m_iTeam)
	#endif // SEMICLIP_ACTION

	if (is_user_alive(id) && !g_bUserInTrain[id])
	{
		if (get_member(id, m_iTeam) == TEAM_TRAIN || get_member(id, m_iTeam) == TEAM_NOTHING)
		{
			new TeamName:iTeam
			if (get_member_game(m_iNumCT) > get_member_game(m_iNumTerrorist))
				iTeam = TEAM_HIDER
			else
				iTeam = TEAM_SEEKER

			rg_set_user_team(id, iTeam)
			rg_round_respawn(id)
		}
	}

	switch (get_member(id, m_iTeam))
	{
		case TEAM_HIDER:
		{
			rg_give_item(id, "weapon_knife")
			rg_set_user_footsteps(id, true)
			rg_give_item_ex(id, "weapon_flashbang", .bpammo = 1)
			#if defined WINS_IN_A_ROW
			rg_give_item_ex(id, "weapon_smokegrenade", .bpammo = (g_iWins >= 10 ? 2 : 1))
			#else
			rg_give_item_ex(id, "weapon_smokegrenade", .bpammo = 1)
			#endif

			if (g_bUserInTrain[id])
				g_bUserInTrain[id] = false
		}
		case TEAM_SEEKER:
		{
			rg_give_item(id, "weapon_knife")

			if (g_bUserInTrain[id])
				g_bUserInTrain[id] = false

			if (g_bFreezePeriod)
			{
				UTIL_ScreenFade(id, { 0, 0, 0 }, 0.0, _ , 255, FFADE_OUT|FFADE_STAYOUT, true)

				static szMessage[1024], iHoldTime

				formatex(szMessage, charsmax(szMessage), "[Why So Serious?]^n^nServer Rules:^n\
					1. Do not swear, argue or insult people^n\
					2. Do not use hacks, scripts, binds^n\
					3. Do not impersonate administrator^n\
					4. Do not spam^n\
					5. Do not air flash, air freeze, block people!")

				iHoldTime = get_cvar_num("mp_freezetime")
				rg_send_hudmessage(id, szMessage, -1.0, -1.0, random(256), random_num(100, 255), random(256), 150, float(iHoldTime), 0.05, 0.20, -1, 2, random_num(0, 100), random_num(0, 100), random_num(0, 100), 200, 2.5);
			}
		}
		case TEAM_TRAIN:
		{
			/*new Float:flColors[3]
			flColors[0] = 0.0
			flColors[1] = 0.0
			flColors[2] = 0.0
			rg_set_entity_rendering(id, kRenderFxGlowShell, flColors, kRenderTransAlpha, 0)*/

			rg_set_user_invisibility(id, true)
			rg_set_user_godmode(id, true)
			rg_set_user_footsteps(id, true)

			rg_give_item(id, "weapon_knife")
			rg_give_item_ex(id, "weapon_usp", GT_APPEND, 0, 0)
			rg_set_user_ammo(id, WEAPON_USP, 0)
			rg_give_item_ex(id, "weapon_hegrenade", .bpammo = 1)
			rg_give_item_ex(id, "weapon_flashbang", .bpammo = 1)
			set_entvar(id, var_solid, SOLID_NOT)
		}
	}
}

public RG__CBasePlayer_ResetMaxSpeed(id)
{
	if (!is_user_alive(id) || !g_bFreezePeriod)
		return

	if (get_member(id, m_iTeam) == TEAM_HIDER || g_bUserInTrain[id])
		set_entvar(id, var_maxspeed, 250.0)

}

public TaskDestroyBreakables()
{
	new iEntity = -1
	while ((iEntity = rg_find_ent_by_class(iEntity, "func_breakable")))
	{
		if (get_entvar(iEntity, var_takedamage))
			set_entvar(iEntity, var_origin, Float: { 10000.0, 10000.0, 10000.0 })
	}
}

public plugin_end()
{
	ArrayDestroy(g_aEndMusic)
}

stock try_precache_generic(const szGeneric[])
{
	if (file_exists(szGeneric))
	{
		precache_generic(szGeneric)
		return true
	}
	else
	{
		log_amx("Failed to precache generic ^"%s^"", szGeneric)
		return false
	}
}

stock try_precache_model(const szModel[])
{
	if (file_exists(szModel))
	{
		precache_model(szModel)
		return true
	}
	else
	{
		log_amx("Failed to precache model ^"%s^"", szModel)
		return false
	}
}

loadFromFile()
{
	static szFileName[128], szData[512], iFilePointer
	
	get_localinfo("amxx_configsdir", szFileName, charsmax(szFileName))
	add(szFileName, sizeof szFileName -1,"/hns_roundsounds.ini")
	
	if (!file_exists(szFileName))
	{
		server_print("Could not find hns_roundsounds.ini")
		return;
		
	}
	
	iFilePointer = fopen(szFileName,"rt+")
	
	if (!iFilePointer)
		return
		
	while (!feof(iFilePointer))
	{
		fgets(iFilePointer, szData, sizeof szData -1)
		remove_quotes(szData)
		trim(szData)
		
		if (szData[0] == EOS || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/'))
			continue

		if (try_precache_generic(szData))
			ArrayPushString(g_aEndMusic, szData)
	}
	
	fclose(iFilePointer)
}

public Command_ToggleKnife(id)
{
	if (get_member(id, m_iTeam) == TEAM_HIDER || get_member(id, m_iTeam) == TEAM_TRAIN)
	{
		g_bKnife[id] = !g_bKnife[id]
		rg_remove_item(id, "weapon_knife")
		//rg_give_item(id, "weapon_knife", GT_APPEND)
		//client_cmd_ex(id, "weapon_knife")
		rg_switch_weapon(id, rg_give_item(id, "weapon_knife", GT_REPLACE))
		client_print(id, print_center, "Knife is %s", g_bKnife[id] ? "hidden!" : "no longer hidden!")
	}
	else
	{
		client_print(id, print_center, "Only Terrorists can use this option!")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public Command_ToggleEndSounds(id)
{
	g_bEndSounds[id] = !g_bEndSounds[id]

//	CC_SendMessage(id, "&x04[Why So Serious?] &x01Switched &x04end round sounds &x01to &x03%s", g_bEndSounds[id] ? "enabled" : "disabled")
	client_print(id, print_center, "End Round Sounds are %s", g_bEndSounds[id] ? "enabled" : "disabled")
	return PLUGIN_HANDLED
}

public Command_SwapTeams(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 0))
		return PLUGIN_HANDLED

	rg_swap_all_players()
	server_cmd("sv_restart 3")

	new szName[MAX_NAME_LENGTH]
	get_user_name(id, szName, charsmax(szName))
	CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01has swapped the teams!", szName)

	return PLUGIN_HANDLED
}

public Command_KillEveryone(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED

	new szArgs[12]
	read_argv(1, szArgs, charsmax(szArgs))

	new iPlayers[MAX_PLAYERS], iNum, iTempID, szType[32]

	switch(szArgs[0])
	{
		case 'P', 'p':
		{
			get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_ExcludeBots)
			formatex(szType, charsmax(szType), "all &x04Players")
		}
		case 'A', 'a':
		{
			get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_ExcludeBots)
			formatex(szType, charsmax(szType), "all &x04Admins")
		}
		case 'T', 't':
		{
			get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead/*|GetPlayers_ExcludeBots*/|GetPlayers_MatchTeam, "TERRORIST")
			formatex(szType, charsmax(szType), "all &x03Terrorists")
		}
		case 'C', 'c':
		{
			get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead/*|GetPlayers_ExcludeBots*/|GetPlayers_MatchTeam, "CT")
			formatex(szType, charsmax(szType), "all &x03Counter-Terrorists")
		}
		case 'E', 'e':
		{
			get_players_ex(iPlayers, iNum, GetPlayers_ExcludeDead|GetPlayers_ExcludeBots)
			formatex(szType, charsmax(szType), "&x04Everyone")
		}
		default:
		{
			client_print(id, print_console, "Invalid choice.")
			return PLUGIN_HANDLED
		}
	}

	for (--iNum; iNum >= 0; iNum--)
	{
		iTempID = iPlayers[iNum]
		switch(szArgs[0])
		{
			case 'P', 'p':
			{
				if (!is_user_admin(iTempID))
					user_silentkill(iTempID, 1)
			}
			case 'A', 'a':
			{
				if (is_user_admin(iTempID))
					user_silentkill(iTempID, 1)
			}
			case 'T', 't', 'C', 'c', 'E', 'e':
			{
				user_silentkill(iTempID, 1)
			}
		}
	}

	new szName[MAX_NAME_LENGTH]
	get_user_name(id, szName, charsmax(szName))
	CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01has killed %s!", szName, szType)

	return PLUGIN_HANDLED
}

public Command_Transfer(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED

	new szPlayer[MAX_NAME_LENGTH]
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF)
	
	if(!iPlayer)
		return PLUGIN_HANDLED
		
	new szTeam[2]
	read_argv(2, szTeam, charsmax(szTeam))

	new szRespawn[6]
	read_argv(3, szRespawn, charsmax(szRespawn))
	
	new TeamName:iPlayerTeam
	
	switch(szTeam[0])
	{
		case 'C', 'c': iPlayerTeam = TEAM_SEEKER
		case 'T', 't': iPlayerTeam = TEAM_HIDER
		case 'S', 's': iPlayerTeam = TEAM_TRAIN
		default:
		{
			client_print(id, print_console, "Invalid team name.")
			return PLUGIN_HANDLED
		}
	}
	
	if (iPlayerTeam == get_member(iPlayer, m_iTeam))
	{
		client_print(id, print_console, "That player is already in that team!")
		return PLUGIN_HANDLED
	}
	
	if (iPlayerTeam == TEAM_TRAIN)
		user_silentkill(iPlayer, 1)

	rg_set_user_team(iPlayer, iPlayerTeam)

	if (iPlayerTeam != TEAM_TRAIN)
	{
		if (szRespawn[0] == 'Y' || szRespawn[0] == 'y')
			rg_round_respawn(iPlayer)
	}
	
	new szName[2][MAX_NAME_LENGTH]
	get_user_name(id, szName[0], charsmax(szName[]))
	get_user_name(iPlayer, szName[1], charsmax(szName[]))
	CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01transferred &x03%s &x01to the &x04%s &x01team", szName[0], szName[1], g_szTeamNames[get_member(iPlayer, m_iTeam)])
	return PLUGIN_HANDLED
}

public Command_Swap(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED

	new szArgNames[2][MAX_NAME_LENGTH], iPlayer[2]
	read_argv(1, szArgNames[0], charsmax(szArgNames[]))
	read_argv(2, szArgNames[1], charsmax(szArgNames[]))

	iPlayer[0] = cmd_target(id, szArgNames[0], CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)
	iPlayer[1] = cmd_target(id, szArgNames[1], CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE)

	if (!iPlayer[0] || !iPlayer[1])
		return PLUGIN_HANDLED

	new TeamName:iTeam[2]
	iTeam[0] = get_member(iPlayer[0], m_iTeam)
	iTeam[1] = get_member(iPlayer[1], m_iTeam)

	if (iTeam[0] == iTeam[1])
	{
		client_print(id, print_console, "You cannot swap players that are on the same team!")
		return PLUGIN_HANDLED
	}

	if (iTeam[0] == TEAM_NOTHING || iTeam[1] == TEAM_NOTHING)
	{
		client_print(id, print_console, "You cannot swap players that are not in a team!")
		return PLUGIN_HANDLED
	}

	if (iTeam[0] == TEAM_TRAIN)
		user_silentkill(iPlayer[1], 1)
	else if (iTeam[1] == TEAM_TRAIN)
		user_silentkill(iPlayer[0], 1)

	rg_set_user_team(iPlayer[0], iTeam[1])
	rg_set_user_team(iPlayer[1], iTeam[0])

	if (iTeam[0] != TEAM_TRAIN || iTeam[1] != TEAM_TRAIN)
	{
		rg_round_respawn(iPlayer[0])
		rg_round_respawn(iPlayer[1])
	}

	new szName[3][MAX_NAME_LENGTH]
	get_user_name(id, szName[0], charsmax(szName[]))
	get_user_name(iPlayer[0], szName[1], charsmax(szName[]))
	get_user_name(iPlayer[1], szName[2], charsmax(szName[]))
	if (equali(szName[0], szName[1]))
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01swapped teams with &x03%s", szName[0], szName[2])
	else
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01swapped &x03%s &x01teams with &x03%s", szName[0], szName[1], szName[2])
	return PLUGIN_HANDLED
}

public Command_Train(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED

	new szArgName[MAX_NAME_LENGTH], szArgTrainStatus[6]
	read_argv(1, szArgName, charsmax(szArgName))
	read_argv(2, szArgTrainStatus, charsmax(szArgTrainStatus))

	new iPlayer = cmd_target(id, szArgName, CMDTARGET_ALLOW_SELF)

	if (!iPlayer)
		return PLUGIN_HANDLED

	if (szArgTrainStatus[0] == EOS)
	{
		client_print(id, print_console, "Please specify true or false..")
		return PLUGIN_HANDLED
	}

	new iValue = str_to_num(szArgTrainStatus)

	if (g_bUserInTrain[iPlayer] && iValue)
	{
		client_print(id, print_console, "Player already has training mode enabled!")
		return PLUGIN_HANDLED
	}

	if (!g_bUserInTrain[iPlayer] && !iValue)
	{
		client_print(id, print_console, "Player already has training mode disabled!")
		return PLUGIN_HANDLED
	}

	if (iValue)
	{
		g_iTempTeam[iPlayer] = get_member(iPlayer, m_iTeam)
		g_bUserInTrain[iPlayer] = true
		rg_set_user_team(iPlayer, TEAM_TRAIN)
		rg_round_respawn(iPlayer)
	}
	else
	{
		g_bUserInTrain[iPlayer] = false

		if (g_iTempTeam[iPlayer] == TEAM_TRAIN || g_iTempTeam[iPlayer] == TEAM_NOTHING)
		{
			new TeamName:iTeam
			if (get_member_game(m_iNumCT) > get_member_game(m_iNumTerrorist))
				iTeam = TEAM_HIDER
			else
				iTeam = TEAM_SEEKER

			rg_set_user_team(iPlayer, iTeam)
		}
		else
		{
			rg_set_user_team(iPlayer, g_iTempTeam[iPlayer])
		}

		rg_round_respawn(iPlayer)
	}

	new szName[2][MAX_NAME_LENGTH]
	get_user_name(id, szName[0], charsmax(szName[]))
	get_user_name(iPlayer, szName[1], charsmax(szName[]))

	if (equali(szName[0], szName[1]))
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01has &x04%s&x01 train mode for himself/herself", szName[0], iValue == 1 ? "enabled" : "disabled")
	else
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01has &x04%s&x01 train mode for &x03%s", szName[0], iValue == 1 ? "enabled" : "disabled", szName[1])

	return PLUGIN_HANDLED
}

public Command_GiveWeapon(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED
	
	new szArgName[MAX_NAME_LENGTH], szWeaponId[32]//, szAmmo[6], szBpAmmo[6]
	read_argv(1, szArgName, charsmax(szArgName))
	read_argv(2, szWeaponId, charsmax(szWeaponId))
	//read_argv(3, szAmmo, charsmax(szAmmo))
	//read_argv(4, szBpAmmo, charsmax(szBpAmmo))

	new iPlayer = cmd_target(id, szArgName, CMDTARGET_ONLY_ALIVE)
		
	if (!iPlayer)
		return PLUGIN_HANDLED

	if (!g_bUserInTrain[iPlayer])
	{
		client_print(id, print_console, "User must be in training mode to give them weapons!")
		return PLUGIN_HANDLED
	}

	//new iAmmo, iBpAmmos
	//iAmmo = str_to_num(szAmmo)
	//iBpAmmos = str_to_num(szBpAmmo)
	
	new szNames[2][MAX_NAME_LENGTH], szWeaponType[32]
	get_user_name(id, szNames[0], charsmax(szNames[]))
	get_user_name(iPlayer, szNames[1], charsmax(szNames[]))

	formatex(szWeaponType, charsmax(szWeaponType), "weapon_%s", szWeaponId)
	new iWeapon = rg_get_weapon_info(szWeaponType, WI_ID)

	if (CSW_P228 <= iWeapon <= CSW_P90)
	{
		if (iWeapon == CSW_SMOKEGRENADE)
		{
			client_print(id, print_console, "This Item is forbidden by Huehue..")
			return PLUGIN_HANDLED
		}

		rg_give_item_ex(iPlayer, szWeaponType, GT_APPEND, 0)
		//rg_give_item_ex(iPlayer, szWeaponType, GT_APPEND, (iBpAmmos > 0 ? iBpAmmos : 0))
		rg_set_user_ammo(iPlayer, rg_get_weapon_info(szWeaponType, WI_ID), 0)

		if (equali(szNames[0], szNames[1]))
			CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01gave himself/herself weapon &x04%s", szNames[0], szWeaponId)
		else
			CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01gave weapon &x04%s&x01 to &x03%s", szNames[0], szWeaponId, szNames[1])
	}
	else
	{
		client_print(id, print_console, "Invalid weapon type, please try again.")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public Command_SwitchTeam(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED

	new szArgName[MAX_NAME_LENGTH]
	read_argv(1, szArgName, charsmax(szArgName))

	new iPlayer = cmd_target(id, szArgName, CMDTARGET_ALLOW_SELF)
		
	if (!iPlayer)
		return PLUGIN_HANDLED

	rg_switch_team(iPlayer)

	if (is_user_alive(iPlayer))
	{
		rg_round_respawn(iPlayer)
	}

	new szNames[2][MAX_NAME_LENGTH]
	get_user_name(id, szNames[0], charsmax(szNames[]))
	get_user_name(iPlayer, szNames[1], charsmax(szNames[]))

	if (equali(szNames[0], szNames[1]))
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01switched himself/herself teams", szNames[0])
	else
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01switched &x04%s&x01 teams", szNames[0], szNames[1])


	return PLUGIN_HANDLED
}

public Command_Revive(id, iLevel, iCid)
{
	if (!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED

	new szArgName[MAX_NAME_LENGTH]
	read_argv(1, szArgName, charsmax(szArgName))

	new iPlayer = cmd_target(id, szArgName, CMDTARGET_ALLOW_SELF)
		
	if (!iPlayer)
		return PLUGIN_HANDLED

	if (is_user_alive(iPlayer))
	{
		console_print(id, "Player is still alive, please wait..")
		return PLUGIN_HANDLED
	}

	rg_round_respawn(iPlayer)

	new szNames[2][MAX_NAME_LENGTH]
	get_user_name(id, szNames[0], charsmax(szNames[]))
	get_user_name(iPlayer, szNames[1], charsmax(szNames[]))

	if (equali(szNames[0], szNames[1]))
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01revived himself/herself", szNames[0])
	else
		CC_LogMessage(0, _, "&x03[ADMIN &x04%s&x03] &x01revived &x04%s", szNames[0], szNames[1])


	return PLUGIN_HANDLED
}

public Command_CheckPoint(id)
{
	if (get_member(id, m_iTeam) != TEAM_TRAIN)
		return PLUGIN_CONTINUE

	if (is_user_alive(id))
	{
		get_entvar(id, var_origin, g_iUserOrigins[id])
		g_iUserOrigins[id][2] += 10
	}
	return PLUGIN_HANDLED
}

public Command_Teleport(id)
{
	if (get_member(id, m_iTeam) != TEAM_TRAIN)
		return PLUGIN_CONTINUE
	
	if (is_user_alive(id) && g_iUserOrigins[id][0])
	{
		set_entvar(id, var_origin, g_iUserOrigins[id])
		set_entvar(id, var_velocity, Float:{ 0.0, 0.0, 0.0 })
	}
	return PLUGIN_HANDLED
}

#if defined FLASH_CONTROL
stock bool:rg_is_player_flashed(id)
{
	return bool:(Float:get_member(id, m_blindStartTime) + Float:get_member(id, m_blindFadeTime) >= get_gametime())
}
#endif // FLASH_CONTROL

#if defined SEMICLIP_ACTION
ExtraRenderActivity()
{
	static iAddToFullPackForwardPre
	
	if (g_bFreezePeriod && !iAddToFullPackForwardPre)
	{
		iAddToFullPackForwardPre = register_forward(FM_AddToFullPack, "FM__AddToFullPack_Pre", 0)
	}
	else if (!g_bFreezePeriod && iAddToFullPackForwardPre)
	{
		if (unregister_forward(FM_AddToFullPack, iAddToFullPackForwardPre))
		{
			iAddToFullPackForwardPre = 0
		}
	}
}
#endif