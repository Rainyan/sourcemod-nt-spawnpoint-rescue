#include <sourcemod>
#include <sdktools>
#include <dhooks>

#include <neotokyo>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.2.2"
#define PLUGIN_TAG "[SPAWN RESCUE]"

int _lastest_spawn_team[NEO_MAXPLAYERS + 1] = { TEAM_NONE, ... };

bool _logged_map_error;
int _last_used_backup_spawn;

public Plugin myinfo = {
    name = "NT Spawnpoint Rescue",
    description = "If a player spawns to incorrect location, move them to a valid spawn point.",
    author = "Rain",
    version = PLUGIN_VERSION,
    url = "https://github.com/Rainyan/sourcemod-nt-spawnpoint-rescue"
};

public void OnPluginStart()
{
    GameData gd = LoadGameConfigFile("neotokyo/spawnpoint_rescue");
    if (!gd)
    {
        SetFailState("Failed to load GameData");
    }

    DynamicDetour dd = DynamicDetour.FromConf(gd, "Fn_CNEOGameRules__GetPlayerSpawnSpot");
    if (!dd)
    {
        SetFailState("Failed to create dynamic detour");
    }
    if (!dd.Enable(Hook_Post, GetPlayerSpawnSpot))
    {
        SetFailState("Failed to detour");
    }

    if (!HookEventEx("game_round_start", OnRoundStart) ||
        !HookEventEx("player_spawn", OnPlayerSpawn))
    {
        SetFailState("Failed to hook event");
    }

    delete gd;
}

public void OnMapStart()
{
    _logged_map_error = false;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    _last_used_backup_spawn = -1;
    for (int i = 1; i < sizeof(_lastest_spawn_team); ++i)
    {
        _lastest_spawn_team[i] = TEAM_NONE;
    }
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client == 0 || GetClientTeam(client) <= TEAM_SPECTATOR)
    {
        return;
    }

    RescueSpawnIfNeeded(client);
}

#if(0)
// Checks if the spot is clear of (other) players, and the client is set to spawn here.
// Uses a 128 unit radius check for nearby players.
bool IsSpawnPointValid(int spawnpoint, int client)
{
    static Handle call = INVALID_HANDLE;
    if (call == INVALID_HANDLE)
    {
        StartPrepSDKCall(SDKCall_GameRules);
        PrepSDKCall_SetSignature(
            SDKLibrary_Server,
            "\x81\xEC\x08\x08\x00\x00\x56\x8B\xB4\x24\x10\x08\x00\x00",
            14
        );
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
        call = EndPrepSDKCall();
        if (call == INVALID_HANDLE)
        {
            SetFailState("Failed to prep SDK call");
        }
    }
    return SDKCall(call, spawnpoint, client);
}
#endif

void RescueSpawnIfNeeded(int client)
{
    int team = GetClientTeam(client);
    if (team != TEAM_JINRAI && team != TEAM_NSF)
    {
        ThrowError("Unexpected team (%d) for client %d (%N)", team, client, client);
    }

    int attacker = GameRules_GetProp("m_iAttackingTeam");

    // TODO: refactor
    int index; // index for the spawn_ents array below
    if (team == TEAM_JINRAI)
    {
        if (attacker == TEAM_JINRAI)
        {
            if (_lastest_spawn_team[client] == TEAM_JINRAI)
            {
                return;
            }
        }
        else
        {
            if (_lastest_spawn_team[client] == TEAM_NSF)
            {
                return;
            }
            index = 1;
        }
    }
    else
    {
        if (attacker == TEAM_NSF)
        {
            if (_lastest_spawn_team[client] == TEAM_JINRAI)
            {
                return;
            }
        }
        else
        {
            if (_lastest_spawn_team[client] == TEAM_NSF)
            {
                return;
            }
            index = 1;
        }
    }

    // Are we looking for an attacker or defender spawnpoint this round?
    char spawn_ents[][] = {
        "info_player_attacker",
        "info_player_defender",
    };

    // Find the next spawn we haven't yet used for rescue spawning
    int backup_spawn = FindEntityByClassname(
        _last_used_backup_spawn != -1 ? _last_used_backup_spawn : MaxClients + 1,
        spawn_ents[index]
    );
    // If we didn't find a spawn from this range, look up a previous valid edict
    if (backup_spawn == -1)
    {
        // Found one; just stack any remaining spawners to this one
        if (_last_used_backup_spawn != -1)
        {
            backup_spawn = _last_used_backup_spawn;
        }
        // We have no valid spawn points in the level at all, have to give up
        else
        {
            return;
        }
    }

    _last_used_backup_spawn = backup_spawn;
    MoveToSpawnPoint(client, backup_spawn);

    // Log only once, so we don't annoy players and spam the server log file too much.
    if (!_logged_map_error)
    {
        LogToGame("%s MAP ERROR: Player spawned outside a valid spawn point! \
This is an error with map's spawn points being too close to each other or the \
surrounding geometry; please let the mapper know so they can fix the problem!",
            PLUGIN_TAG);

        PrintToChatAll("%s Player was about to spawn to incorrect spawn location!",
            PLUGIN_TAG);
        PrintToChatAll("This is a map problem; please let the mapper know so they can fix this.");
#if(0)
        char classname[32];
        float pos[3];
        LogToGame("\tPossibly problematic spawn(s):");
        for (int ent = MaxClients + 1; ent < GetMaxEntities(); ++ent)
        {
            if (!IsValidEdict(ent))
            {
                continue;
            }
            if (!GetEdictClassname(ent, classname, sizeof(classname)))
            {
                continue;
            }
            if (!StrEqual(classname, "info_player_attacker") &&
                !StrEqual(classname, "info_player_defender"))
            {
                continue;
            }

            bool is_valid = false;
            for (int i = 1; i <= MaxClients; ++i)
            {
                if (!IsClientInGame(i))
                {
                    continue;
                }
                if (IsSpawnPointValid(ent, i))
                {
                    is_valid = true;
                    break;
                }
            }
            if (is_valid)
            {
                continue;
            }

            GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
            LogToGame("\t%s: position %f, %f, %f",
                classname, pos[0], pos[1], pos[2]);
        }
#endif
        _logged_map_error = true;
    }
}

// Given a valid client index and spawnpoint edict,
// teleport the client to the spawnpoint's coordinates.
void MoveToSpawnPoint(int client, int spawnpoint)
{
    float pos[3];
    GetEntPropVector(spawnpoint, Prop_Data, "m_vecOrigin", pos);
    TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
}

// Gamerules' GetPlayerSpawnSpot detour
public MRESReturn GetPlayerSpawnSpot(DHookReturn hReturn, DHookParam hParams)
{
    int client = hParams.Get(1);
    if (client <= 0 || client > MaxClients)
    {
        return MRES_Ignored;
    }

    if (!IsValidEdict(hReturn.Value))
    {
        return MRES_Ignored;
    }

    char classname[32];
    if (!GetEdictClassname(hReturn.Value, classname, sizeof(classname)))
    {
        return MRES_Ignored;
    }

    if (StrEqual(classname, "info_player_attacker"))
    {
        _lastest_spawn_team[client] = TEAM_JINRAI;
    }
    else if (StrEqual(classname, "info_player_defender"))
    {
        _lastest_spawn_team[client] = TEAM_NSF;
    }

    return MRES_Ignored;
}