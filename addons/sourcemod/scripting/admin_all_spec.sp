#pragma semicolon 1

#include <dhooks>

#pragma newdecls required

Handle
		hIsValidTarget,
		mp_forcecamera;
		
bool 
		g_bCheckNullPtr = false;

public Plugin myinfo = 
{
	name = "Admin all spec",
	author = "Dr!fter, babka68",
	description = "Allows admin to spec all players",
	version = "1.1",
	url = "sourcemod.net, tmb-css.ru",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("DHookIsNullParam");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	mp_forcecamera = FindConVar("mp_forcecamera");
	
	if(!mp_forcecamera)
	{
		SetFailState("Failed to locate mp_forcecamera");
	}
	
	Handle temp = LoadGameConfigFile("allow-spec.games");
	
	if(!temp)
	{
		SetFailState("Failed to load allow-spec.games.txt");
	}
	
	int offset = GameConfGetOffset(temp, "IsValidObserverTarget");
	
	hIsValidTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsValidTarget);
	
	DHookAddParam(hIsValidTarget, HookParamType_CBaseEntity);
	
	CloseHandle(temp);
	
	g_bCheckNullPtr = (GetFeatureStatus(FeatureType_Native, "DHookIsNullParam") == FeatureStatus_Available);
}
public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(CheckCommandAccess(client, "admin_allspec_flag", ADMFLAG_CHAT))
	{
		SendConVarValue(client, mp_forcecamera, "0");
		DHookEntity(hIsValidTarget, true, client);
	}
}

public MRESReturn IsValidTarget(int thisPointer, Handle hReturn, Handle hParams)
{
	if (g_bCheckNullPtr && DHookIsNullParam(hParams, 1))
	{
		return MRES_Ignored;
	}
	
	int target = DHookGetParam(hParams, 1);
	if(target <= 0 || target > MaxClients || !IsClientInGame(thisPointer) || !IsClientInGame(target) || !IsPlayerAlive(target) || IsPlayerAlive(thisPointer) || GetClientTeam(thisPointer) <= 1 || GetClientTeam(target) <= 1)
	{
		return MRES_Ignored;
	}
	DHookSetReturn(hReturn, true);
	return MRES_Override;
}