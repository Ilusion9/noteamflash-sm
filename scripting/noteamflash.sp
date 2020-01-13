#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo =
{
    name = "No Team Flash",
    author = "Ilusion9",
    description = "Players will not be flashed by teammates",
    version = "1.0",
    url = "https://github.com/Ilusion9/"
};

int g_ThrowerId;
int g_ThrowerTeam;
float g_FlashDuration[MAXPLAYERS + 1];

ConVar g_Cvar_NoTeamFlash;

public void OnPluginStart()
{
	g_Cvar_NoTeamFlash = CreateConVar("sm_no_team_flash", "1", "Determine whether players should be protected by flashes done by teammates or not.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("flashbang_detonate", Event_FlashbangDetonate);
	HookEvent("player_blind", Event_PlayerBlind);
	
	AutoExecConfig(true, "noteamflash");
}

public void Event_FlashbangDetonate(Event event, const char[] name, bool dontBroadcast)
{
	g_ThrowerId = event.GetInt("userid");
	int client = GetClientOfUserId(g_ThrowerId);
	
	if (!client || !IsClientInGame(client))
	{
		g_ThrowerTeam = CS_TEAM_NONE;
		return;
	}
	
	g_ThrowerTeam = GetClientTeam(client);
	GetFlashDurations();
}

public void Event_PlayerBlind(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Cvar_NoTeamFlash.BoolValue || g_ThrowerTeam == CS_TEAM_NONE)
	{
		return;
	}
	
	int userId = event.GetInt("userid");
	if (g_ThrowerId == userId)
	{
		return;
	}
	
	int client = GetClientOfUserId(userId);
	if (!client || !IsClientInGame(client))
	{
		return;
	}
	
	if (IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == g_ThrowerTeam)
		{
			if (CheckCommandAccess(client, "NoTeamFlash", 0, false))
			{
				SetClientFlashDuration(client, g_FlashDuration[client]);
			}
		}
	}
	else
	{
		if (IsClientObserver(client))
		{
			/* First person mode */
			if (GetClientObserverMode(client) != 4)
			{
				return;
			}
			
			int specTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (specTarget < 1 || specTarget > MaxClients)
			{
				return;
			}
			
			SetClientFlashDuration(client, g_FlashDuration[specTarget]);
		}
	}
}

void GetFlashDurations()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			g_FlashDuration[i] = GetClientFlashDuration(i);
		}
	}
}

int GetClientObserverMode(int client)
{
	return GetEntProp(client, Prop_Send, "m_iObserverMode");
}

float GetClientFlashDuration(int client)
{
	return GetEntPropFloat(client, Prop_Send, "m_flFlashDuration");
}

void SetClientFlashDuration(int client, float duration)
{
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", duration);
}
