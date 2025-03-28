/* ============================================================================================================
// EN: Connects the specified file/library
// RU: Подключает указанный файл/библиотеку
// ==========================================================================================================*/
#include <dhooks>

/* ============================================================================================================
// EN: Notifies the compiler that there should be a character at the end of each expression ;
// RU: Сообщает компилятору о том, что в конце каждого выражения должен стоять символ ;
// ==========================================================================================================*/

#pragma semicolon 1
/* =============================================================================================================
// EN: Notifies the compiler that the plugin syntax is exceptionally new
// RU: Сообщает компилятору о том, что синтаксис плагина исключительно новый
// ===========================================================================================================*/
#pragma newdecls required

/* =============================================================================================================
// EN: Desired access flag at g_cvMpForceCamera 1
// RU: Желаемый флаг доступа при g_cvMpForceCamera 1
// ===========================================================================================================*/
#define  FlAG ADMFLAG_CHEATS 

DynamicHook g_hIsValidTarget = null;
ConVar g_cvMpForceCamera;

/* =============================================================================================================
// EN: Public information about the plugin.
// RU: Общественная информация о плагине.
// ===========================================================================================================*/
public Plugin myinfo = 
{
	name = "Admin all spec", 
	author = "Dr!fter, babka68", 
	description = "Плагин позволяет мертвым администраторам наблюдать за всеми игроками при mp_forcecamera 1", 
	version = "1.2", 
	url = "sourcemod.net, vk.com/zakazserver68", 
};

/* =============================================================================================================
// EN: A built-in global event whose function is a single call when the plugin is fully initialized.
// RU: Встроенное глобальное событие, функция которого - единождый вызов при полной инициализации плагина.
// =============================================================================================================*/
public void OnPluginStart()
{
	g_cvMpForceCamera = FindConVar("mp_forcecamera");
	if (!g_cvMpForceCamera)SetFailState("Не удалось найти переменную 'mp_forcecamera'");
	
	GameData hGameData = new GameData("allow-spec.games");
	if (hGameData == null)SetFailState("Не удалось загрузить файл 'allow-spec.games.txt'");
	
	int offset = hGameData.GetOffset("IsValidObserverTarget");
	if (offset == -1)SetFailState("Не удалось получить смещение 'IsValidObserverTarget' из файла 'allow-spec.games.txt'");
	
	g_hIsValidTarget = new DynamicHook(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (g_hIsValidTarget == null)SetFailState("Не удалось создать DynamicHook");
	
	g_hIsValidTarget.AddParam(HookParamType_CBaseEntity);
	
	// больше нигде не используется, удаляем.
	hGameData.Close();
}

public void OnClientPostAdminCheck(int entity)
{
	if (IsFakeClient(entity) || !CheckCommandAccess(entity, "admin_allspec_flag", FlAG))
		return;
	// Hook_Pre - Обратный вызов будет выполнен ДО запуска исходной функции.
	// HookEntity(HookMode mode, int entity, DHookCallback callback, DHookRemovalCB removalcb=INVALID_FUNCTION);
	g_hIsValidTarget.HookEntity(Hook_Pre, entity, IsValidObserverTarget);
	
	if (g_cvMpForceCamera != null)SendConVarValue(entity, g_cvMpForceCamera, "0");
}

public MRESReturn IsValidObserverTarget(int thisPointer, DHookReturn hReturn, DHookParam hParams)
{
	if (!IsClientInGame(thisPointer) || IsPlayerAlive(thisPointer) || GetClientTeam(thisPointer) <= 1)
		return MRES_Ignored; // будет вызвана исходная функция.
	
	if (hParams.IsNull(1))
		return MRES_Ignored; // будет вызвана исходная функция.
	
	int target = hParams.Get(1);
	if (target <= 0 || target > MaxClients || thisPointer == target || !IsClientInGame(target) || !IsPlayerAlive(target) || GetClientTeam(target) <= 1)
		return MRES_Ignored; // будет вызвана исходная функция.
	
	hReturn.Value = true;
	// Исходная функция не будет вызвана. Вместо нее будет использовано новое возвращаемое значение (если таковое имеется).
	return MRES_Supercede;
} 
