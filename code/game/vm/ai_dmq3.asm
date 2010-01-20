export BotSetUserInfo
code
proc BotSetUserInfo 1024 12
file "../ai_dmq3.c"
line 118
;1:/*
;2:===========================================================================
;3:Copyright (C) 1999-2005 Id Software, Inc.
;4:
;5:This file is part of Quake III Arena source code.
;6:
;7:Quake III Arena source code is free software; you can redistribute it
;8:and/or modify it under the terms of the GNU General Public License as
;9:published by the Free Software Foundation; either version 2 of the License,
;10:or (at your option) any later version.
;11:
;12:Quake III Arena source code is distributed in the hope that it will be
;13:useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
;14:MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;15:GNU General Public License for more details.
;16:
;17:You should have received a copy of the GNU General Public License
;18:along with Foobar; if not, write to the Free Software
;19:Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
;20:
;21:Modified by Greg Dolley [1/1/2008]
;22:===========================================================================
;23:*/
;24://
;25:
;26:/*****************************************************************************
;27: * name:		ai_dmq3.c
;28: *
;29: * desc:		Quake3 bot AI
;30: *
;31: * $Archive: /MissionPack/code/game/ai_dmq3.c $
;32: *
;33: *****************************************************************************/
;34:
;35:
;36:#include "g_local.h"
;37:#include "botlib.h"
;38:#include "be_aas.h"
;39:#include "be_ea.h"
;40:#include "be_ai_char.h"
;41:#include "be_ai_chat.h"
;42:#include "be_ai_gen.h"
;43:#include "be_ai_goal.h"
;44:#include "be_ai_move.h"
;45:#include "be_ai_weap.h"
;46://
;47:#include "ai_main.h"
;48:#include "ai_dmq3.h"
;49:#include "ai_chat.h"
;50:#include "ai_cmd.h"
;51:#include "ai_dmnet.h"
;52:#include "ai_team.h"
;53://
;54:#include "chars.h"				//characteristics
;55:#include "inv.h"				//indexes into the inventory
;56:#include "syn.h"				//synonyms
;57:#include "match.h"				//string matching types and vars
;58:
;59:// for the voice chats
;60:#include "../../ui/menudef.h" // sos001205 - for q3_ui also
;61:
;62:// from aasfile.h
;63:#define AREACONTENTS_MOVER				1024
;64:#define AREACONTENTS_MODELNUMSHIFT		24
;65:#define AREACONTENTS_MAXMODELNUM		0xFF
;66:#define AREACONTENTS_MODELNUM			(AREACONTENTS_MAXMODELNUM << AREACONTENTS_MODELNUMSHIFT)
;67:
;68:#define IDEAL_ATTACKDIST			140
;69:
;70:#define MAX_WAYPOINTS		128
;71://
;72:bot_waypoint_t botai_waypoints[MAX_WAYPOINTS];
;73:bot_waypoint_t *botai_freewaypoints;
;74:
;75://NOTE: not using a cvars which can be updated because the game should be reloaded anyway
;76:int gametype;		//game type
;77:int maxclients;		//maximum number of clients
;78:
;79:vmCvar_t bot_grapple;
;80:vmCvar_t bot_rocketjump;
;81:vmCvar_t bot_fastchat;
;82:vmCvar_t bot_nochat;
;83:vmCvar_t bot_testrchat;
;84:vmCvar_t bot_challenge;
;85:vmCvar_t bot_predictobstacles;
;86:vmCvar_t g_spSkill;
;87:
;88:extern vmCvar_t bot_developer;
;89:
;90:vec3_t lastteleport_origin;		//last teleport event origin
;91:float lastteleport_time;		//last teleport event time
;92:int max_bspmodelindex;			//maximum BSP model index
;93:
;94://CTF flag goals
;95:bot_goal_t ctf_redflag;
;96:bot_goal_t ctf_blueflag;
;97:#ifdef MISSIONPACK
;98:bot_goal_t ctf_neutralflag;
;99:bot_goal_t redobelisk;
;100:bot_goal_t blueobelisk;
;101:bot_goal_t neutralobelisk;
;102:#endif
;103:
;104:#define MAX_ALTROUTEGOALS		32
;105:
;106:int altroutegoals_setup;
;107:aas_altroutegoal_t red_altroutegoals[MAX_ALTROUTEGOALS];
;108:int red_numaltroutegoals;
;109:aas_altroutegoal_t blue_altroutegoals[MAX_ALTROUTEGOALS];
;110:int blue_numaltroutegoals;
;111:
;112:
;113:/*
;114:==================
;115:BotSetUserInfo
;116:==================
;117:*/
;118:void BotSetUserInfo(bot_state_t *bs, char *key, char *value) {
line 121
;119:	char userinfo[MAX_INFO_STRING];
;120:
;121:	trap_GetUserinfo(bs->client, userinfo, sizeof(userinfo));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetUserinfo
CALLV
pop
line 122
;122:	Info_SetValueForKey(userinfo, key, value);
ADDRLP4 0
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRFP4 8
INDIRP4
ARGP4
ADDRGP4 Info_SetValueForKey
CALLV
pop
line 123
;123:	trap_SetUserinfo(bs->client, userinfo);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 trap_SetUserinfo
CALLV
pop
line 124
;124:	ClientUserinfoChanged( bs->client );
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 ClientUserinfoChanged
CALLV
pop
line 125
;125:}
LABELV $53
endproc BotSetUserInfo 1024 12
export BotCTFCarryingFlag
proc BotCTFCarryingFlag 0 0
line 132
;126:
;127:/*
;128:==================
;129:BotCTFCarryingFlag
;130:==================
;131:*/
;132:int BotCTFCarryingFlag(bot_state_t *bs) {
line 133
;133:	if (gametype != GT_CTF) return CTF_FLAG_NONE;
ADDRGP4 gametype
INDIRI4
CNSTI4 4
EQI4 $55
CNSTI4 0
RETI4
ADDRGP4 $54
JUMPV
LABELV $55
line 135
;134:
;135:	if (bs->inventory[INVENTORY_REDFLAG] > 0) return CTF_FLAG_RED;
ADDRFP4 0
INDIRP4
CNSTI4 5132
ADDP4
INDIRI4
CNSTI4 0
LEI4 $57
CNSTI4 1
RETI4
ADDRGP4 $54
JUMPV
LABELV $57
line 136
;136:	else if (bs->inventory[INVENTORY_BLUEFLAG] > 0) return CTF_FLAG_BLUE;
ADDRFP4 0
INDIRP4
CNSTI4 5136
ADDP4
INDIRI4
CNSTI4 0
LEI4 $59
CNSTI4 2
RETI4
ADDRGP4 $54
JUMPV
LABELV $59
line 137
;137:	return CTF_FLAG_NONE;
CNSTI4 0
RETI4
LABELV $54
endproc BotCTFCarryingFlag 0 0
export BotTeam
proc BotTeam 1044 12
line 145
;138:}
;139:
;140:/*
;141:==================
;142:BotTeam
;143:==================
;144:*/
;145:int BotTeam(bot_state_t *bs) {
line 148
;146:	char info[1024];
;147:
;148:	if (bs->client < 0 || bs->client >= MAX_CLIENTS) {
ADDRLP4 1024
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
ADDRLP4 1024
INDIRI4
CNSTI4 0
LTI4 $64
ADDRLP4 1024
INDIRI4
CNSTI4 64
LTI4 $62
LABELV $64
line 150
;149:		//BotAI_Print(PRT_ERROR, "BotCTFTeam: client out of range\n");
;150:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $61
JUMPV
LABELV $62
line 152
;151:	}
;152:	trap_GetConfigstring(CS_PLAYERS+bs->client, info, sizeof(info));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 154
;153:	//
;154:	if (atoi(Info_ValueForKey(info, "t")) == TEAM_RED) return TEAM_RED;
ADDRLP4 0
ARGP4
ADDRGP4 $67
ARGP4
ADDRLP4 1028
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 1028
INDIRP4
ARGP4
ADDRLP4 1032
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 1032
INDIRI4
CNSTI4 1
NEI4 $65
CNSTI4 1
RETI4
ADDRGP4 $61
JUMPV
LABELV $65
line 155
;155:	else if (atoi(Info_ValueForKey(info, "t")) == TEAM_BLUE) return TEAM_BLUE;
ADDRLP4 0
ARGP4
ADDRGP4 $67
ARGP4
ADDRLP4 1036
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 1036
INDIRP4
ARGP4
ADDRLP4 1040
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 1040
INDIRI4
CNSTI4 2
NEI4 $68
CNSTI4 2
RETI4
ADDRGP4 $61
JUMPV
LABELV $68
line 156
;156:	return TEAM_FREE;
CNSTI4 0
RETI4
LABELV $61
endproc BotTeam 1044 12
export BotOppositeTeam
proc BotOppositeTeam 12 4
line 164
;157:}
;158:
;159:/*
;160:==================
;161:BotOppositeTeam
;162:==================
;163:*/
;164:int BotOppositeTeam(bot_state_t *bs) {
line 165
;165:	switch(BotTeam(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 4
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 4
INDIRI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 1
EQI4 $74
ADDRLP4 0
INDIRI4
CNSTI4 2
EQI4 $75
ADDRGP4 $71
JUMPV
LABELV $74
line 166
;166:		case TEAM_RED: return TEAM_BLUE;
CNSTI4 2
RETI4
ADDRGP4 $70
JUMPV
LABELV $75
line 167
;167:		case TEAM_BLUE: return TEAM_RED;
CNSTI4 1
RETI4
ADDRGP4 $70
JUMPV
LABELV $71
line 168
;168:		default: return TEAM_FREE;
CNSTI4 0
RETI4
LABELV $70
endproc BotOppositeTeam 12 4
export BotEnemyFlag
proc BotEnemyFlag 4 4
line 177
;169:	}
;170:}
;171:
;172:/*
;173:==================
;174:BotEnemyFlag
;175:==================
;176:*/
;177:bot_goal_t *BotEnemyFlag(bot_state_t *bs) {
line 178
;178:	if (BotTeam(bs) == TEAM_RED) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 1
NEI4 $77
line 179
;179:		return &ctf_blueflag;
ADDRGP4 ctf_blueflag
RETP4
ADDRGP4 $76
JUMPV
LABELV $77
line 181
;180:	}
;181:	else {
line 182
;182:		return &ctf_redflag;
ADDRGP4 ctf_redflag
RETP4
LABELV $76
endproc BotEnemyFlag 4 4
export BotTeamFlag
proc BotTeamFlag 4 4
line 191
;183:	}
;184:}
;185:
;186:/*
;187:==================
;188:BotTeamFlag
;189:==================
;190:*/
;191:bot_goal_t *BotTeamFlag(bot_state_t *bs) {
line 192
;192:	if (BotTeam(bs) == TEAM_RED) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 1
NEI4 $80
line 193
;193:		return &ctf_redflag;
ADDRGP4 ctf_redflag
RETP4
ADDRGP4 $79
JUMPV
LABELV $80
line 195
;194:	}
;195:	else {
line 196
;196:		return &ctf_blueflag;
ADDRGP4 ctf_blueflag
RETP4
LABELV $79
endproc BotTeamFlag 4 4
export EntityIsDead
proc EntityIsDead 472 8
line 206
;197:	}
;198:}
;199:
;200:
;201:/*
;202:==================
;203:EntityIsDead
;204:==================
;205:*/
;206:qboolean EntityIsDead(aas_entityinfo_t *entinfo) {
line 209
;207:	playerState_t ps;
;208:
;209:	if (entinfo->number >= 0 && entinfo->number < MAX_CLIENTS) {
ADDRLP4 468
ADDRFP4 0
INDIRP4
CNSTI4 20
ADDP4
INDIRI4
ASGNI4
ADDRLP4 468
INDIRI4
CNSTI4 0
LTI4 $83
ADDRLP4 468
INDIRI4
CNSTI4 64
GEI4 $83
line 211
;210:		//retrieve the current client state
;211:		BotAI_GetClientState( entinfo->number, &ps );
ADDRFP4 0
INDIRP4
CNSTI4 20
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotAI_GetClientState
CALLI4
pop
line 212
;212:		if (ps.pm_type != PM_NORMAL) return qtrue;
ADDRLP4 0+4
INDIRI4
CNSTI4 0
EQI4 $85
CNSTI4 1
RETI4
ADDRGP4 $82
JUMPV
LABELV $85
line 213
;213:	}
LABELV $83
line 214
;214:	return qfalse;
CNSTI4 0
RETI4
LABELV $82
endproc EntityIsDead 472 8
export EntityCarriesFlag
proc EntityCarriesFlag 0 0
line 222
;215:}
;216:
;217:/*
;218:==================
;219:EntityCarriesFlag
;220:==================
;221:*/
;222:qboolean EntityCarriesFlag(aas_entityinfo_t *entinfo) {
line 223
;223:	if ( entinfo->powerups & ( 1 << PW_REDFLAG ) )
ADDRFP4 0
INDIRP4
CNSTI4 124
ADDP4
INDIRI4
CNSTI4 128
BANDI4
CNSTI4 0
EQI4 $89
line 224
;224:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $88
JUMPV
LABELV $89
line 225
;225:	if ( entinfo->powerups & ( 1 << PW_BLUEFLAG ) )
ADDRFP4 0
INDIRP4
CNSTI4 124
ADDP4
INDIRI4
CNSTI4 256
BANDI4
CNSTI4 0
EQI4 $91
line 226
;226:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $88
JUMPV
LABELV $91
line 231
;227:#ifdef MISSIONPACK
;228:	if ( entinfo->powerups & ( 1 << PW_NEUTRALFLAG ) )
;229:		return qtrue;
;230:#endif
;231:	return qfalse;
CNSTI4 0
RETI4
LABELV $88
endproc EntityCarriesFlag 0 0
export EntityIsInvisible
proc EntityIsInvisible 4 4
line 239
;232:}
;233:
;234:/*
;235:==================
;236:EntityIsInvisible
;237:==================
;238:*/
;239:qboolean EntityIsInvisible(aas_entityinfo_t *entinfo) {
line 241
;240:	// the flag is always visible
;241:	if (EntityCarriesFlag(entinfo)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 0
EQI4 $94
line 242
;242:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $93
JUMPV
LABELV $94
line 244
;243:	}
;244:	if (entinfo->powerups & (1 << PW_INVIS)) {
ADDRFP4 0
INDIRP4
CNSTI4 124
ADDP4
INDIRI4
CNSTI4 16
BANDI4
CNSTI4 0
EQI4 $96
line 245
;245:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $93
JUMPV
LABELV $96
line 247
;246:	}
;247:	return qfalse;
CNSTI4 0
RETI4
LABELV $93
endproc EntityIsInvisible 4 4
export EntityIsShooting
proc EntityIsShooting 0 0
line 255
;248:}
;249:
;250:/*
;251:==================
;252:EntityIsShooting
;253:==================
;254:*/
;255:qboolean EntityIsShooting(aas_entityinfo_t *entinfo) {
line 256
;256:	if (entinfo->flags & EF_FIRING) {
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
CNSTI4 256
BANDI4
CNSTI4 0
EQI4 $99
line 257
;257:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $98
JUMPV
LABELV $99
line 259
;258:	}
;259:	return qfalse;
CNSTI4 0
RETI4
LABELV $98
endproc EntityIsShooting 0 0
export EntityIsChatting
proc EntityIsChatting 0 0
line 267
;260:}
;261:
;262:/*
;263:==================
;264:EntityIsChatting
;265:==================
;266:*/
;267:qboolean EntityIsChatting(aas_entityinfo_t *entinfo) {
line 268
;268:	if (entinfo->flags & EF_TALK) {
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
CNSTI4 4096
BANDI4
CNSTI4 0
EQI4 $102
line 269
;269:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $101
JUMPV
LABELV $102
line 271
;270:	}
;271:	return qfalse;
CNSTI4 0
RETI4
LABELV $101
endproc EntityIsChatting 0 0
export EntityHasQuad
proc EntityHasQuad 0 0
line 279
;272:}
;273:
;274:/*
;275:==================
;276:EntityHasQuad
;277:==================
;278:*/
;279:qboolean EntityHasQuad(aas_entityinfo_t *entinfo) {
line 280
;280:	if (entinfo->powerups & (1 << PW_QUAD)) {
ADDRFP4 0
INDIRP4
CNSTI4 124
ADDP4
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $105
line 281
;281:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $104
JUMPV
LABELV $105
line 283
;282:	}
;283:	return qfalse;
CNSTI4 0
RETI4
LABELV $104
endproc EntityHasQuad 0 0
export BotRememberLastOrderedTask
proc BotRememberLastOrderedTask 16 12
line 347
;284:}
;285:
;286:#ifdef MISSIONPACK
;287:/*
;288:==================
;289:EntityHasKamikze
;290:==================
;291:*/
;292:qboolean EntityHasKamikaze(aas_entityinfo_t *entinfo) {
;293:	if (entinfo->flags & EF_KAMIKAZE) {
;294:		return qtrue;
;295:	}
;296:	return qfalse;
;297:}
;298:
;299:/*
;300:==================
;301:EntityCarriesCubes
;302:==================
;303:*/
;304:qboolean EntityCarriesCubes(aas_entityinfo_t *entinfo) {
;305:	entityState_t state;
;306:
;307:	if (gametype != GT_HARVESTER)
;308:		return qfalse;
;309:	//FIXME: get this info from the aas_entityinfo_t ?
;310:	BotAI_GetEntityState(entinfo->number, &state);
;311:	if (state.generic1 > 0)
;312:		return qtrue;
;313:	return qfalse;
;314:}
;315:
;316:/*
;317:==================
;318:Bot1FCTFCarryingFlag
;319:==================
;320:*/
;321:int Bot1FCTFCarryingFlag(bot_state_t *bs) {
;322:	if (gametype != GT_1FCTF) return qfalse;
;323:
;324:	if (bs->inventory[INVENTORY_NEUTRALFLAG] > 0) return qtrue;
;325:	return qfalse;
;326:}
;327:
;328:/*
;329:==================
;330:BotHarvesterCarryingCubes
;331:==================
;332:*/
;333:int BotHarvesterCarryingCubes(bot_state_t *bs) {
;334:	if (gametype != GT_HARVESTER) return qfalse;
;335:
;336:	if (bs->inventory[INVENTORY_REDCUBE] > 0) return qtrue;
;337:	if (bs->inventory[INVENTORY_BLUECUBE] > 0) return qtrue;
;338:	return qfalse;
;339:}
;340:#endif
;341:
;342:/*
;343:==================
;344:BotRememberLastOrderedTask
;345:==================
;346:*/
;347:void BotRememberLastOrderedTask(bot_state_t *bs) {
line 348
;348:	if (!bs->ordered) {
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
INDIRI4
CNSTI4 0
NEI4 $108
line 349
;349:		return;
ADDRGP4 $107
JUMPV
LABELV $108
line 351
;350:	}
;351:	bs->lastgoal_decisionmaker = bs->decisionmaker;
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
INDIRP4
CNSTI4 6756
ADDP4
ADDRLP4 0
INDIRP4
CNSTI4 6608
ADDP4
INDIRI4
ASGNI4
line 352
;352:	bs->lastgoal_ltgtype = bs->ltgtype;
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 6760
ADDP4
ADDRLP4 4
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
ASGNI4
line 353
;353:	memcpy(&bs->lastgoal_teamgoal, &bs->teamgoal, sizeof(bot_goal_t));
ADDRLP4 8
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 8
INDIRP4
CNSTI4 6768
ADDP4
ARGP4
ADDRLP4 8
INDIRP4
CNSTI4 6624
ADDP4
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 354
;354:	bs->lastgoal_teammate = bs->teammate;
ADDRLP4 12
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 12
INDIRP4
CNSTI4 6764
ADDP4
ADDRLP4 12
INDIRP4
CNSTI4 6604
ADDP4
INDIRI4
ASGNI4
line 355
;355:}
LABELV $107
endproc BotRememberLastOrderedTask 16 12
export BotSetTeamStatus
proc BotSetTeamStatus 0 0
line 362
;356:
;357:/*
;358:==================
;359:BotSetTeamStatus
;360:==================
;361:*/
;362:void BotSetTeamStatus(bot_state_t *bs) {
line 419
;363:#ifdef MISSIONPACK
;364:	int teamtask;
;365:	aas_entityinfo_t entinfo;
;366:
;367:	teamtask = TEAMTASK_PATROL;
;368:
;369:	switch(bs->ltgtype) {
;370:		case LTG_TEAMHELP:
;371:			break;
;372:		case LTG_TEAMACCOMPANY:
;373:			BotEntityInfo(bs->teammate, &entinfo);
;374:			if ( ( (gametype == GT_CTF || gametype == GT_1FCTF) && EntityCarriesFlag(&entinfo))
;375:				|| ( gametype == GT_HARVESTER && EntityCarriesCubes(&entinfo)) ) {
;376:				teamtask = TEAMTASK_ESCORT;
;377:			}
;378:			else {
;379:				teamtask = TEAMTASK_FOLLOW;
;380:			}
;381:			break;
;382:		case LTG_DEFENDKEYAREA:
;383:			teamtask = TEAMTASK_DEFENSE;
;384:			break;
;385:		case LTG_GETFLAG:
;386:			teamtask = TEAMTASK_OFFENSE;
;387:			break;
;388:		case LTG_RUSHBASE:
;389:			teamtask = TEAMTASK_DEFENSE;
;390:			break;
;391:		case LTG_RETURNFLAG:
;392:			teamtask = TEAMTASK_RETRIEVE;
;393:			break;
;394:		case LTG_CAMP:
;395:		case LTG_CAMPORDER:
;396:			teamtask = TEAMTASK_CAMP;
;397:			break;
;398:		case LTG_PATROL:
;399:			teamtask = TEAMTASK_PATROL;
;400:			break;
;401:		case LTG_GETITEM:
;402:			teamtask = TEAMTASK_PATROL;
;403:			break;
;404:		case LTG_KILL:
;405:			teamtask = TEAMTASK_PATROL;
;406:			break;
;407:		case LTG_HARVEST:
;408:			teamtask = TEAMTASK_OFFENSE;
;409:			break;
;410:		case LTG_ATTACKENEMYBASE:
;411:			teamtask = TEAMTASK_OFFENSE;
;412:			break;
;413:		default:
;414:			teamtask = TEAMTASK_PATROL;
;415:			break;
;416:	}
;417:	BotSetUserInfo(bs, "teamtask", va("%d", teamtask));
;418:#endif
;419:}
LABELV $110
endproc BotSetTeamStatus 0 0
export BotSetLastOrderedTask
proc BotSetLastOrderedTask 60 16
line 426
;420:
;421:/*
;422:==================
;423:BotSetLastOrderedTask
;424:==================
;425:*/
;426:int BotSetLastOrderedTask(bot_state_t *bs) {
line 428
;427:
;428:	if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $112
line 430
;429:		// don't go back to returning the flag if it's at the base
;430:		if ( bs->lastgoal_ltgtype == LTG_RETURNFLAG ) {
ADDRFP4 0
INDIRP4
CNSTI4 6760
ADDP4
INDIRI4
CNSTI4 6
NEI4 $114
line 431
;431:			if ( BotTeam(bs) == TEAM_RED ) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 1
NEI4 $116
line 432
;432:				if ( bs->redflagstatus == 0 ) {
ADDRFP4 0
INDIRP4
CNSTI4 6952
ADDP4
INDIRI4
CNSTI4 0
NEI4 $117
line 433
;433:					bs->lastgoal_ltgtype = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6760
ADDP4
CNSTI4 0
ASGNI4
line 434
;434:				}
line 435
;435:			}
ADDRGP4 $117
JUMPV
LABELV $116
line 436
;436:			else {
line 437
;437:				if ( bs->blueflagstatus == 0 ) {
ADDRFP4 0
INDIRP4
CNSTI4 6956
ADDP4
INDIRI4
CNSTI4 0
NEI4 $120
line 438
;438:					bs->lastgoal_ltgtype = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6760
ADDP4
CNSTI4 0
ASGNI4
line 439
;439:				}
LABELV $120
line 440
;440:			}
LABELV $117
line 441
;441:		}
LABELV $114
line 442
;442:	}
LABELV $112
line 444
;443:
;444:	if ( bs->lastgoal_ltgtype ) {
ADDRFP4 0
INDIRP4
CNSTI4 6760
ADDP4
INDIRI4
CNSTI4 0
EQI4 $122
line 445
;445:		bs->decisionmaker = bs->lastgoal_decisionmaker;
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 0
INDIRP4
CNSTI4 6756
ADDP4
INDIRI4
ASGNI4
line 446
;446:		bs->ordered = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 1
ASGNI4
line 447
;447:		bs->ltgtype = bs->lastgoal_ltgtype;
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 6600
ADDP4
ADDRLP4 4
INDIRP4
CNSTI4 6760
ADDP4
INDIRI4
ASGNI4
line 448
;448:		memcpy(&bs->teamgoal, &bs->lastgoal_teamgoal, sizeof(bot_goal_t));
ADDRLP4 8
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 8
INDIRP4
CNSTI4 6624
ADDP4
ARGP4
ADDRLP4 8
INDIRP4
CNSTI4 6768
ADDP4
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 449
;449:		bs->teammate = bs->lastgoal_teammate;
ADDRLP4 12
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 12
INDIRP4
CNSTI4 6604
ADDP4
ADDRLP4 12
INDIRP4
CNSTI4 6764
ADDP4
INDIRI4
ASGNI4
line 450
;450:		bs->teamgoal_time = FloatTime() + 300;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1133903872
ADDF4
ASGNF4
line 451
;451:		BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 453
;452:		//
;453:		if ( gametype == GT_CTF ) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $124
line 454
;454:			if ( bs->ltgtype == LTG_GETFLAG ) {
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 4
NEI4 $126
line 458
;455:				bot_goal_t *tb, *eb;
;456:				int tt, et;
;457:
;458:				tb = BotTeamFlag(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 32
ADDRGP4 BotTeamFlag
CALLP4
ASGNP4
ADDRLP4 16
ADDRLP4 32
INDIRP4
ASGNP4
line 459
;459:				eb = BotEnemyFlag(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 36
ADDRGP4 BotEnemyFlag
CALLP4
ASGNP4
ADDRLP4 20
ADDRLP4 36
INDIRP4
ASGNP4
line 460
;460:				tt = trap_AAS_AreaTravelTimeToGoalArea(bs->areanum, bs->origin, tb->areanum, TFL_DEFAULT);
ADDRLP4 40
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 40
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 40
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRLP4 16
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 18616254
ARGI4
ADDRLP4 44
ADDRGP4 trap_AAS_AreaTravelTimeToGoalArea
CALLI4
ASGNI4
ADDRLP4 24
ADDRLP4 44
INDIRI4
ASGNI4
line 461
;461:				et = trap_AAS_AreaTravelTimeToGoalArea(bs->areanum, bs->origin, eb->areanum, TFL_DEFAULT);
ADDRLP4 48
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 48
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 48
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRLP4 20
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 18616254
ARGI4
ADDRLP4 52
ADDRGP4 trap_AAS_AreaTravelTimeToGoalArea
CALLI4
ASGNI4
ADDRLP4 28
ADDRLP4 52
INDIRI4
ASGNI4
line 463
;462:				// if the travel time towards the enemy base is larger than towards our base
;463:				if (et > tt) {
ADDRLP4 28
INDIRI4
ADDRLP4 24
INDIRI4
LEI4 $128
line 465
;464:					//get an alternative route goal towards the enemy base
;465:					BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 56
ADDRGP4 BotOppositeTeam
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 56
INDIRI4
ARGI4
ADDRGP4 BotGetAlternateRouteGoal
CALLI4
pop
line 466
;466:				}
LABELV $128
line 467
;467:			}
LABELV $126
line 468
;468:		}
LABELV $124
line 469
;469:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $111
JUMPV
LABELV $122
line 471
;470:	}
;471:	return qfalse;
CNSTI4 0
RETI4
LABELV $111
endproc BotSetLastOrderedTask 60 16
export BotRefuseOrder
proc BotRefuseOrder 8 12
line 479
;472:}
;473:
;474:/*
;475:==================
;476:BotRefuseOrder
;477:==================
;478:*/
;479:void BotRefuseOrder(bot_state_t *bs) {
line 480
;480:	if (!bs->ordered)
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
INDIRI4
CNSTI4 0
NEI4 $131
line 481
;481:		return;
ADDRGP4 $130
JUMPV
LABELV $131
line 483
;482:	// if the bot was ordered to do something
;483:	if ( bs->order_time && bs->order_time > FloatTime() - 10 ) {
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 6616
ADDP4
INDIRF4
ASGNF4
ADDRLP4 0
INDIRF4
CNSTF4 0
EQF4 $133
ADDRLP4 0
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1092616192
SUBF4
LEF4 $133
line 484
;484:		trap_EA_Action(bs->client, ACTION_NEGATIVE);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
CNSTI4 2097152
ARGI4
ADDRGP4 trap_EA_Action
CALLV
pop
line 485
;485:		BotVoiceChat(bs, bs->decisionmaker, VOICECHAT_NO);
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
ARGP4
ADDRLP4 4
INDIRP4
CNSTI4 6608
ADDP4
INDIRI4
ARGI4
ADDRGP4 $135
ARGP4
ADDRGP4 BotVoiceChat
CALLV
pop
line 486
;486:		bs->order_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6616
ADDP4
CNSTF4 0
ASGNF4
line 487
;487:	}
LABELV $133
line 488
;488:}
LABELV $130
endproc BotRefuseOrder 8 12
export BotCTFSeekGoals
proc BotCTFSeekGoals 240 12
line 495
;489:
;490:/*
;491:==================
;492:BotCTFSeekGoals
;493:==================
;494:*/
;495:void BotCTFSeekGoals(bot_state_t *bs) {
line 502
;496:	float rnd, l1, l2;
;497:	int flagstatus, c;
;498:	vec3_t dir;
;499:	aas_entityinfo_t entinfo;
;500:
;501:	//when carrying a flag in ctf the bot should rush to the base
;502:	if (BotCTFCarryingFlag(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 172
ADDRGP4 BotCTFCarryingFlag
CALLI4
ASGNI4
ADDRLP4 172
INDIRI4
CNSTI4 0
EQI4 $137
line 504
;503:		//if not already rushing to the base
;504:		if (bs->ltgtype != LTG_RUSHBASE) {
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 5
EQI4 $139
line 505
;505:			BotRefuseOrder(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotRefuseOrder
CALLV
pop
line 506
;506:			bs->ltgtype = LTG_RUSHBASE;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 5
ASGNI4
line 507
;507:			bs->teamgoal_time = FloatTime() + CTF_RUSHBASE_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1123024896
ADDF4
ASGNF4
line 508
;508:			bs->rushbaseaway_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6152
ADDP4
CNSTF4 0
ASGNF4
line 509
;509:			bs->decisionmaker = bs->client;
ADDRLP4 176
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 176
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 176
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 510
;510:			bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 512
;511:			//
;512:			switch(BotTeam(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 184
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 180
ADDRLP4 184
INDIRI4
ASGNI4
ADDRLP4 180
INDIRI4
CNSTI4 1
EQI4 $144
ADDRLP4 180
INDIRI4
CNSTI4 2
EQI4 $149
ADDRGP4 $141
JUMPV
LABELV $144
line 513
;513:				case TEAM_RED: VectorSubtract(bs->origin, ctf_blueflag.origin, dir); break;
ADDRLP4 192
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 160
ADDRLP4 192
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
ADDRGP4 ctf_blueflag
INDIRF4
SUBF4
ASGNF4
ADDRLP4 160+4
ADDRLP4 192
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
ADDRGP4 ctf_blueflag+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 160+8
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
ADDRGP4 ctf_blueflag+8
INDIRF4
SUBF4
ASGNF4
ADDRGP4 $142
JUMPV
LABELV $149
line 514
;514:				case TEAM_BLUE: VectorSubtract(bs->origin, ctf_redflag.origin, dir); break;
ADDRLP4 196
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 160
ADDRLP4 196
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
ADDRGP4 ctf_redflag
INDIRF4
SUBF4
ASGNF4
ADDRLP4 160+4
ADDRLP4 196
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
ADDRGP4 ctf_redflag+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 160+8
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
ADDRGP4 ctf_redflag+8
INDIRF4
SUBF4
ASGNF4
ADDRGP4 $142
JUMPV
LABELV $141
line 515
;515:				default: VectorSet(dir, 999, 999, 999); break;
ADDRLP4 200
CNSTF4 1148829696
ASGNF4
ADDRLP4 160
ADDRLP4 200
INDIRF4
ASGNF4
ADDRLP4 160+4
ADDRLP4 200
INDIRF4
ASGNF4
ADDRLP4 160+8
CNSTF4 1148829696
ASGNF4
LABELV $142
line 518
;516:			}
;517:			// if the bot picked up the flag very close to the enemy base
;518:			if ( VectorLength(dir) < 128 ) {
ADDRLP4 160
ARGP4
ADDRLP4 192
ADDRGP4 VectorLength
CALLF4
ASGNF4
ADDRLP4 192
INDIRF4
CNSTF4 1124073472
GEF4 $156
line 520
;519:				// get an alternative route goal through the enemy base
;520:				BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 196
ADDRGP4 BotOppositeTeam
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 196
INDIRI4
ARGI4
ADDRGP4 BotGetAlternateRouteGoal
CALLI4
pop
line 521
;521:			} else {
ADDRGP4 $157
JUMPV
LABELV $156
line 523
;522:				// don't use any alt route goal, just get the hell out of the base
;523:				bs->altroutegoal.areanum = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6692
ADDP4
CNSTI4 0
ASGNI4
line 524
;524:			}
LABELV $157
line 525
;525:			BotSetUserInfo(bs, "teamtask", va("%d", TEAMTASK_OFFENSE));
ADDRGP4 $159
ARGP4
CNSTI4 1
ARGI4
ADDRLP4 196
ADDRGP4 va
CALLP4
ASGNP4
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $158
ARGP4
ADDRLP4 196
INDIRP4
ARGP4
ADDRGP4 BotSetUserInfo
CALLV
pop
line 526
;526:			BotVoiceChat(bs, -1, VOICECHAT_IHAVEFLAG);
ADDRFP4 0
INDIRP4
ARGP4
CNSTI4 -1
ARGI4
ADDRGP4 $160
ARGP4
ADDRGP4 BotVoiceChat
CALLV
pop
line 527
;527:		}
ADDRGP4 $136
JUMPV
LABELV $139
line 528
;528:		else if (bs->rushbaseaway_time > FloatTime()) {
ADDRFP4 0
INDIRP4
CNSTI4 6152
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
LEF4 $136
line 529
;529:			if (BotTeam(bs) == TEAM_RED) flagstatus = bs->redflagstatus;
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 176
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 176
INDIRI4
CNSTI4 1
NEI4 $163
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 6952
ADDP4
INDIRI4
ASGNI4
ADDRGP4 $164
JUMPV
LABELV $163
line 530
;530:			else flagstatus = bs->blueflagstatus;
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 6956
ADDP4
INDIRI4
ASGNI4
LABELV $164
line 532
;531:			//if the flag is back
;532:			if (flagstatus == 0) {
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $136
line 533
;533:				bs->rushbaseaway_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6152
ADDP4
CNSTF4 0
ASGNF4
line 534
;534:			}
line 535
;535:		}
line 536
;536:		return;
ADDRGP4 $136
JUMPV
LABELV $137
line 539
;537:	}
;538:	// if the bot decided to follow someone
;539:	if ( bs->ltgtype == LTG_TEAMACCOMPANY && !bs->ordered ) {
ADDRLP4 176
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 176
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 2
NEI4 $167
ADDRLP4 176
INDIRP4
CNSTI4 6612
ADDP4
INDIRI4
CNSTI4 0
NEI4 $167
line 541
;540:		// if the team mate being accompanied no longer carries the flag
;541:		BotEntityInfo(bs->teammate, &entinfo);
ADDRFP4 0
INDIRP4
CNSTI4 6604
ADDP4
INDIRI4
ARGI4
ADDRLP4 16
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 542
;542:		if (!EntityCarriesFlag(&entinfo)) {
ADDRLP4 16
ARGP4
ADDRLP4 180
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 180
INDIRI4
CNSTI4 0
NEI4 $169
line 543
;543:			bs->ltgtype = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 0
ASGNI4
line 544
;544:		}
LABELV $169
line 545
;545:	}
LABELV $167
line 547
;546:	//
;547:	if (BotTeam(bs) == TEAM_RED) flagstatus = bs->redflagstatus * 2 + bs->blueflagstatus;
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 180
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 180
INDIRI4
CNSTI4 1
NEI4 $171
ADDRLP4 184
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
ADDRLP4 184
INDIRP4
CNSTI4 6952
ADDP4
INDIRI4
CNSTI4 1
LSHI4
ADDRLP4 184
INDIRP4
CNSTI4 6956
ADDP4
INDIRI4
ADDI4
ASGNI4
ADDRGP4 $172
JUMPV
LABELV $171
line 548
;548:	else flagstatus = bs->blueflagstatus * 2 + bs->redflagstatus;
ADDRLP4 188
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
ADDRLP4 188
INDIRP4
CNSTI4 6956
ADDP4
INDIRI4
CNSTI4 1
LSHI4
ADDRLP4 188
INDIRP4
CNSTI4 6952
ADDP4
INDIRI4
ADDI4
ASGNI4
LABELV $172
line 550
;549:	//if our team has the enemy flag and our flag is at the base
;550:	if (flagstatus == 1) {
ADDRLP4 0
INDIRI4
CNSTI4 1
NEI4 $173
line 552
;551:		//
;552:		if (bs->owndecision_time < FloatTime()) {
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
INDIRI4
CVIF4 4
ADDRGP4 floattime
INDIRF4
GEF4 $136
line 554
;553:			//if Not defending the base already
;554:			if (!(bs->ltgtype == LTG_DEFENDKEYAREA &&
ADDRLP4 192
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 192
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 3
NEI4 $181
ADDRLP4 196
ADDRLP4 192
INDIRP4
CNSTI4 6668
ADDP4
INDIRI4
ASGNI4
ADDRLP4 196
INDIRI4
ADDRGP4 ctf_redflag+44
INDIRI4
EQI4 $136
ADDRLP4 196
INDIRI4
ADDRGP4 ctf_blueflag+44
INDIRI4
EQI4 $136
LABELV $181
line 556
;555:					(bs->teamgoal.number == ctf_redflag.number ||
;556:					bs->teamgoal.number == ctf_blueflag.number))) {
line 558
;557:				//if there is a visible team mate flag carrier
;558:				c = BotTeamFlagCarrierVisible(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 200
ADDRGP4 BotTeamFlagCarrierVisible
CALLI4
ASGNI4
ADDRLP4 156
ADDRLP4 200
INDIRI4
ASGNI4
line 559
;559:				if (c >= 0 &&
ADDRLP4 204
ADDRLP4 156
INDIRI4
ASGNI4
ADDRLP4 204
INDIRI4
CNSTI4 0
LTI4 $136
ADDRLP4 208
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 208
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 2
NEI4 $184
ADDRLP4 208
INDIRP4
CNSTI4 6604
ADDP4
INDIRI4
ADDRLP4 204
INDIRI4
EQI4 $136
LABELV $184
line 561
;560:						// and not already following the team mate flag carrier
;561:						(bs->ltgtype != LTG_TEAMACCOMPANY || bs->teammate != c)) {
line 563
;562:					//
;563:					BotRefuseOrder(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotRefuseOrder
CALLV
pop
line 565
;564:					//follow the flag carrier
;565:					bs->decisionmaker = bs->client;
ADDRLP4 212
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 212
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 212
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 566
;566:					bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 568
;567:					//the team mate
;568:					bs->teammate = c;
ADDRFP4 0
INDIRP4
CNSTI4 6604
ADDP4
ADDRLP4 156
INDIRI4
ASGNI4
line 570
;569:					//last time the team mate was visible
;570:					bs->teammatevisible_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6748
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 572
;571:					//no message
;572:					bs->teammessage_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6740
ADDP4
CNSTF4 0
ASGNF4
line 574
;573:					//no arrive message
;574:					bs->arrive_time = 1;
ADDRFP4 0
INDIRP4
CNSTI4 6172
ADDP4
CNSTF4 1065353216
ASGNF4
line 576
;575:					//
;576:					BotVoiceChat(bs, bs->teammate, VOICECHAT_ONFOLLOW);
ADDRLP4 216
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 216
INDIRP4
ARGP4
ADDRLP4 216
INDIRP4
CNSTI4 6604
ADDP4
INDIRI4
ARGI4
ADDRGP4 $185
ARGP4
ADDRGP4 BotVoiceChat
CALLV
pop
line 578
;577:					//get the team goal time
;578:					bs->teamgoal_time = FloatTime() + TEAM_ACCOMPANY_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1142292480
ADDF4
ASGNF4
line 579
;579:					bs->ltgtype = LTG_TEAMACCOMPANY;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 2
ASGNI4
line 580
;580:					bs->formation_dist = 3.5 * 32;		//3.5 meter
ADDRFP4 0
INDIRP4
CNSTI4 7012
ADDP4
CNSTF4 1121976320
ASGNF4
line 581
;581:					BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 582
;582:					bs->owndecision_time = FloatTime() + 5;
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1084227584
ADDF4
CVFI4 4
ASGNI4
line 583
;583:				}
line 584
;584:			}
line 585
;585:		}
line 586
;586:		return;
ADDRGP4 $136
JUMPV
LABELV $173
line 589
;587:	}
;588:	//if the enemy has our flag
;589:	else if (flagstatus == 2) {
ADDRLP4 0
INDIRI4
CNSTI4 2
NEI4 $186
line 591
;590:		//
;591:		if (bs->owndecision_time < FloatTime()) {
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
INDIRI4
CVIF4 4
ADDRGP4 floattime
INDIRF4
GEF4 $136
line 593
;592:			//if enemy flag carrier is visible
;593:			c = BotEnemyFlagCarrierVisible(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 192
ADDRGP4 BotEnemyFlagCarrierVisible
CALLI4
ASGNI4
ADDRLP4 156
ADDRLP4 192
INDIRI4
ASGNI4
line 594
;594:			if (c >= 0) {
ADDRLP4 156
INDIRI4
CNSTI4 0
LTI4 $190
line 596
;595:				//FIXME: fight enemy flag carrier
;596:			}
LABELV $190
line 598
;597:			//if not already doing something important
;598:			if (bs->ltgtype != LTG_GETFLAG &&
ADDRLP4 196
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
ASGNI4
ADDRLP4 196
INDIRI4
CNSTI4 4
EQI4 $136
ADDRLP4 196
INDIRI4
CNSTI4 6
EQI4 $136
ADDRLP4 196
INDIRI4
CNSTI4 1
EQI4 $136
ADDRLP4 196
INDIRI4
CNSTI4 2
EQI4 $136
ADDRLP4 196
INDIRI4
CNSTI4 8
EQI4 $136
ADDRLP4 196
INDIRI4
CNSTI4 9
EQI4 $136
ADDRLP4 196
INDIRI4
CNSTI4 10
EQI4 $136
line 604
;599:				bs->ltgtype != LTG_RETURNFLAG &&
;600:				bs->ltgtype != LTG_TEAMHELP &&
;601:				bs->ltgtype != LTG_TEAMACCOMPANY &&
;602:				bs->ltgtype != LTG_CAMPORDER &&
;603:				bs->ltgtype != LTG_PATROL &&
;604:				bs->ltgtype != LTG_GETITEM) {
line 606
;605:
;606:				BotRefuseOrder(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotRefuseOrder
CALLV
pop
line 607
;607:				bs->decisionmaker = bs->client;
ADDRLP4 200
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 200
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 200
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 608
;608:				bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 610
;609:				//
;610:				if (random() < 0.5) {
ADDRLP4 204
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 204
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
GEF4 $194
line 612
;611:					//go for the enemy flag
;612:					bs->ltgtype = LTG_GETFLAG;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 4
ASGNI4
line 613
;613:				}
ADDRGP4 $195
JUMPV
LABELV $194
line 614
;614:				else {
line 615
;615:					bs->ltgtype = LTG_RETURNFLAG;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 6
ASGNI4
line 616
;616:				}
LABELV $195
line 618
;617:				//no team message
;618:				bs->teammessage_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6740
ADDP4
CNSTF4 0
ASGNF4
line 620
;619:				//set the time the bot will stop getting the flag
;620:				bs->teamgoal_time = FloatTime() + CTF_GETFLAG_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1142292480
ADDF4
ASGNF4
line 622
;621:				//get an alternative route goal towards the enemy base
;622:				BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 208
ADDRGP4 BotOppositeTeam
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 208
INDIRI4
ARGI4
ADDRGP4 BotGetAlternateRouteGoal
CALLI4
pop
line 624
;623:				//
;624:				BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 625
;625:				bs->owndecision_time = FloatTime() + 5;
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1084227584
ADDF4
CVFI4 4
ASGNI4
line 626
;626:			}
line 627
;627:		}
line 628
;628:		return;
ADDRGP4 $136
JUMPV
LABELV $186
line 631
;629:	}
;630:	//if both flags Not at their bases
;631:	else if (flagstatus == 3) {
ADDRLP4 0
INDIRI4
CNSTI4 3
NEI4 $196
line 633
;632:		//
;633:		if (bs->owndecision_time < FloatTime()) {
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
INDIRI4
CVIF4 4
ADDRGP4 floattime
INDIRF4
GEF4 $136
line 635
;634:			// if not trying to return the flag and not following the team flag carrier
;635:			if ( bs->ltgtype != LTG_RETURNFLAG && bs->ltgtype != LTG_TEAMACCOMPANY ) {
ADDRLP4 192
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
ASGNI4
ADDRLP4 192
INDIRI4
CNSTI4 6
EQI4 $136
ADDRLP4 192
INDIRI4
CNSTI4 2
EQI4 $136
line 637
;636:				//
;637:				c = BotTeamFlagCarrierVisible(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 196
ADDRGP4 BotTeamFlagCarrierVisible
CALLI4
ASGNI4
ADDRLP4 156
ADDRLP4 196
INDIRI4
ASGNI4
line 639
;638:				// if there is a visible team mate flag carrier
;639:				if (c >= 0) {
ADDRLP4 156
INDIRI4
CNSTI4 0
LTI4 $202
line 640
;640:					BotRefuseOrder(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotRefuseOrder
CALLV
pop
line 642
;641:					//follow the flag carrier
;642:					bs->decisionmaker = bs->client;
ADDRLP4 200
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 200
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 200
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 643
;643:					bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 645
;644:					//the team mate
;645:					bs->teammate = c;
ADDRFP4 0
INDIRP4
CNSTI4 6604
ADDP4
ADDRLP4 156
INDIRI4
ASGNI4
line 647
;646:					//last time the team mate was visible
;647:					bs->teammatevisible_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6748
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 649
;648:					//no message
;649:					bs->teammessage_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6740
ADDP4
CNSTF4 0
ASGNF4
line 651
;650:					//no arrive message
;651:					bs->arrive_time = 1;
ADDRFP4 0
INDIRP4
CNSTI4 6172
ADDP4
CNSTF4 1065353216
ASGNF4
line 653
;652:					//
;653:					BotVoiceChat(bs, bs->teammate, VOICECHAT_ONFOLLOW);
ADDRLP4 204
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 204
INDIRP4
ARGP4
ADDRLP4 204
INDIRP4
CNSTI4 6604
ADDP4
INDIRI4
ARGI4
ADDRGP4 $185
ARGP4
ADDRGP4 BotVoiceChat
CALLV
pop
line 655
;654:					//get the team goal time
;655:					bs->teamgoal_time = FloatTime() + TEAM_ACCOMPANY_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1142292480
ADDF4
ASGNF4
line 656
;656:					bs->ltgtype = LTG_TEAMACCOMPANY;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 2
ASGNI4
line 657
;657:					bs->formation_dist = 3.5 * 32;		//3.5 meter
ADDRFP4 0
INDIRP4
CNSTI4 7012
ADDP4
CNSTF4 1121976320
ASGNF4
line 659
;658:					//
;659:					BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 660
;660:					bs->owndecision_time = FloatTime() + 5;
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1084227584
ADDF4
CVFI4 4
ASGNI4
line 661
;661:				}
ADDRGP4 $136
JUMPV
LABELV $202
line 662
;662:				else {
line 663
;663:					BotRefuseOrder(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotRefuseOrder
CALLV
pop
line 664
;664:					bs->decisionmaker = bs->client;
ADDRLP4 200
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 200
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 200
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 665
;665:					bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 667
;666:					//get the enemy flag
;667:					bs->teammessage_time = FloatTime() + 2 * random();
ADDRLP4 204
ADDRGP4 rand
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
CNSTI4 6740
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1073741824
ADDRLP4 204
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
ADDF4
ASGNF4
line 669
;668:					//get the flag
;669:					bs->ltgtype = LTG_RETURNFLAG;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 6
ASGNI4
line 671
;670:					//set the time the bot will stop getting the flag
;671:					bs->teamgoal_time = FloatTime() + CTF_RETURNFLAG_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1127481344
ADDF4
ASGNF4
line 673
;672:					//get an alternative route goal towards the enemy base
;673:					BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 208
ADDRGP4 BotOppositeTeam
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 208
INDIRI4
ARGI4
ADDRGP4 BotGetAlternateRouteGoal
CALLI4
pop
line 675
;674:					//
;675:					BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 676
;676:					bs->owndecision_time = FloatTime() + 5;
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1084227584
ADDF4
CVFI4 4
ASGNI4
line 677
;677:				}
line 678
;678:			}
line 679
;679:		}
line 680
;680:		return;
ADDRGP4 $136
JUMPV
LABELV $196
line 683
;681:	}
;682:	// don't just do something wait for the bot team leader to give orders
;683:	if (BotTeamLeader(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 192
ADDRGP4 BotTeamLeader
CALLI4
ASGNI4
ADDRLP4 192
INDIRI4
CNSTI4 0
EQI4 $204
line 684
;684:		return;
ADDRGP4 $136
JUMPV
LABELV $204
line 687
;685:	}
;686:	// if the bot is ordered to do something
;687:	if ( bs->lastgoal_ltgtype ) {
ADDRFP4 0
INDIRP4
CNSTI4 6760
ADDP4
INDIRI4
CNSTI4 0
EQI4 $206
line 688
;688:		bs->teamgoal_time += 60;
ADDRLP4 196
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ASGNP4
ADDRLP4 196
INDIRP4
ADDRLP4 196
INDIRP4
INDIRF4
CNSTF4 1114636288
ADDF4
ASGNF4
line 689
;689:	}
LABELV $206
line 691
;690:	// if the bot decided to do something on it's own and has a last ordered goal
;691:	if ( !bs->ordered && bs->lastgoal_ltgtype ) {
ADDRLP4 196
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 200
CNSTI4 0
ASGNI4
ADDRLP4 196
INDIRP4
CNSTI4 6612
ADDP4
INDIRI4
ADDRLP4 200
INDIRI4
NEI4 $208
ADDRLP4 196
INDIRP4
CNSTI4 6760
ADDP4
INDIRI4
ADDRLP4 200
INDIRI4
EQI4 $208
line 692
;692:		bs->ltgtype = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 0
ASGNI4
line 693
;693:	}
LABELV $208
line 695
;694:	//if already a CTF or team goal
;695:	if (bs->ltgtype == LTG_TEAMHELP ||
ADDRLP4 204
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
ASGNI4
ADDRLP4 204
INDIRI4
CNSTI4 1
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 2
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 3
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 4
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 5
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 6
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 8
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 9
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 10
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 14
EQI4 $221
ADDRLP4 204
INDIRI4
CNSTI4 15
NEI4 $210
LABELV $221
line 705
;696:			bs->ltgtype == LTG_TEAMACCOMPANY ||
;697:			bs->ltgtype == LTG_DEFENDKEYAREA ||
;698:			bs->ltgtype == LTG_GETFLAG ||
;699:			bs->ltgtype == LTG_RUSHBASE ||
;700:			bs->ltgtype == LTG_RETURNFLAG ||
;701:			bs->ltgtype == LTG_CAMPORDER ||
;702:			bs->ltgtype == LTG_PATROL ||
;703:			bs->ltgtype == LTG_GETITEM ||
;704:			bs->ltgtype == LTG_MAKELOVE_UNDER ||
;705:			bs->ltgtype == LTG_MAKELOVE_ONTOP) {
line 706
;706:		return;
ADDRGP4 $136
JUMPV
LABELV $210
line 709
;707:	}
;708:	//
;709:	if (BotSetLastOrderedTask(bs))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 208
ADDRGP4 BotSetLastOrderedTask
CALLI4
ASGNI4
ADDRLP4 208
INDIRI4
CNSTI4 0
EQI4 $222
line 710
;710:		return;
ADDRGP4 $136
JUMPV
LABELV $222
line 712
;711:	//
;712:	if (bs->owndecision_time > FloatTime())
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
INDIRI4
CVIF4 4
ADDRGP4 floattime
INDIRF4
LEF4 $224
line 713
;713:		return;;
ADDRGP4 $136
JUMPV
LABELV $224
line 715
;714:	//if the bot is roaming
;715:	if (bs->ctfroam_time > FloatTime())
ADDRFP4 0
INDIRP4
CNSTI4 6164
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
LEF4 $226
line 716
;716:		return;
ADDRGP4 $136
JUMPV
LABELV $226
line 718
;717:	//if the bot has anough aggression to decide what to do
;718:	if (BotAggression(bs) < 50)
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 212
ADDRGP4 BotAggression
CALLF4
ASGNF4
ADDRLP4 212
INDIRF4
CNSTF4 1112014848
GEF4 $228
line 719
;719:		return;
ADDRGP4 $136
JUMPV
LABELV $228
line 721
;720:	//set the time to send a message to the team mates
;721:	bs->teammessage_time = FloatTime() + 2 * random();
ADDRLP4 216
ADDRGP4 rand
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
CNSTI4 6740
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1073741824
ADDRLP4 216
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
ADDF4
ASGNF4
line 723
;722:	//
;723:	if (bs->teamtaskpreference & (TEAMTP_ATTACKER|TEAMTP_DEFENDER)) {
ADDRFP4 0
INDIRP4
CNSTI4 6752
ADDP4
INDIRI4
CNSTI4 3
BANDI4
CNSTI4 0
EQI4 $230
line 724
;724:		if (bs->teamtaskpreference & TEAMTP_ATTACKER) {
ADDRFP4 0
INDIRP4
CNSTI4 6752
ADDP4
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $232
line 725
;725:			l1 = 0.7f;
ADDRLP4 8
CNSTF4 1060320051
ASGNF4
line 726
;726:		}
ADDRGP4 $233
JUMPV
LABELV $232
line 727
;727:		else {
line 728
;728:			l1 = 0.2f;
ADDRLP4 8
CNSTF4 1045220557
ASGNF4
line 729
;729:		}
LABELV $233
line 730
;730:		l2 = 0.9f;
ADDRLP4 12
CNSTF4 1063675494
ASGNF4
line 731
;731:	}
ADDRGP4 $231
JUMPV
LABELV $230
line 732
;732:	else {
line 733
;733:		l1 = 0.4f;
ADDRLP4 8
CNSTF4 1053609165
ASGNF4
line 734
;734:		l2 = 0.7f;
ADDRLP4 12
CNSTF4 1060320051
ASGNF4
line 735
;735:	}
LABELV $231
line 737
;736:	//get the flag or defend the base
;737:	rnd = random();
ADDRLP4 220
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 4
ADDRLP4 220
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ASGNF4
line 738
;738:	if (rnd < l1 && ctf_redflag.areanum && ctf_blueflag.areanum) {
ADDRLP4 4
INDIRF4
ADDRLP4 8
INDIRF4
GEF4 $234
ADDRLP4 224
CNSTI4 0
ASGNI4
ADDRGP4 ctf_redflag+12
INDIRI4
ADDRLP4 224
INDIRI4
EQI4 $234
ADDRGP4 ctf_blueflag+12
INDIRI4
ADDRLP4 224
INDIRI4
EQI4 $234
line 739
;739:		bs->decisionmaker = bs->client;
ADDRLP4 228
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 228
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 228
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 740
;740:		bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 741
;741:		bs->ltgtype = LTG_GETFLAG;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 4
ASGNI4
line 743
;742:		//set the time the bot will stop getting the flag
;743:		bs->teamgoal_time = FloatTime() + CTF_GETFLAG_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1142292480
ADDF4
ASGNF4
line 745
;744:		//get an alternative route goal towards the enemy base
;745:		BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 232
ADDRGP4 BotOppositeTeam
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 232
INDIRI4
ARGI4
ADDRGP4 BotGetAlternateRouteGoal
CALLI4
pop
line 746
;746:		BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 747
;747:	}
ADDRGP4 $235
JUMPV
LABELV $234
line 748
;748:	else if (rnd < l2 && ctf_redflag.areanum && ctf_blueflag.areanum) {
ADDRLP4 4
INDIRF4
ADDRLP4 12
INDIRF4
GEF4 $238
ADDRLP4 228
CNSTI4 0
ASGNI4
ADDRGP4 ctf_redflag+12
INDIRI4
ADDRLP4 228
INDIRI4
EQI4 $238
ADDRGP4 ctf_blueflag+12
INDIRI4
ADDRLP4 228
INDIRI4
EQI4 $238
line 749
;749:		bs->decisionmaker = bs->client;
ADDRLP4 232
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 232
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 232
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 750
;750:		bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 752
;751:		//
;752:		if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &ctf_redflag, sizeof(bot_goal_t));
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 236
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 236
INDIRI4
CNSTI4 1
NEI4 $242
ADDRFP4 0
INDIRP4
CNSTI4 6624
ADDP4
ARGP4
ADDRGP4 ctf_redflag
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
ADDRGP4 $243
JUMPV
LABELV $242
line 753
;753:		else memcpy(&bs->teamgoal, &ctf_blueflag, sizeof(bot_goal_t));
ADDRFP4 0
INDIRP4
CNSTI4 6624
ADDP4
ARGP4
ADDRGP4 ctf_blueflag
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
LABELV $243
line 755
;754:		//set the ltg type
;755:		bs->ltgtype = LTG_DEFENDKEYAREA;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 3
ASGNI4
line 757
;756:		//set the time the bot stops defending the base
;757:		bs->teamgoal_time = FloatTime() + TEAM_DEFENDKEYAREA_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1142292480
ADDF4
ASGNF4
line 758
;758:		bs->defendaway_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6144
ADDP4
CNSTF4 0
ASGNF4
line 759
;759:		BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 760
;760:	}
ADDRGP4 $239
JUMPV
LABELV $238
line 761
;761:	else {
line 762
;762:		bs->ltgtype = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 0
ASGNI4
line 764
;763:		//set the time the bot will stop roaming
;764:		bs->ctfroam_time = FloatTime() + CTF_ROAM_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6164
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1114636288
ADDF4
ASGNF4
line 765
;765:		BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 766
;766:	}
LABELV $239
LABELV $235
line 767
;767:	bs->owndecision_time = FloatTime() + 5;
ADDRFP4 0
INDIRP4
CNSTI4 6620
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1084227584
ADDF4
CVFI4 4
ASGNI4
line 771
;768:#ifdef DEBUG
;769:	BotPrintTeamGoal(bs);
;770:#endif //DEBUG
;771:}
LABELV $136
endproc BotCTFSeekGoals 240 12
export BotCTFRetreatGoals
proc BotCTFRetreatGoals 8 4
line 778
;772:
;773:/*
;774:==================
;775:BotCTFRetreatGoals
;776:==================
;777:*/
;778:void BotCTFRetreatGoals(bot_state_t *bs) {
line 780
;779:	//when carrying a flag in ctf the bot should rush to the base
;780:	if (BotCTFCarryingFlag(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ADDRGP4 BotCTFCarryingFlag
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 0
EQI4 $245
line 782
;781:		//if not already rushing to the base
;782:		if (bs->ltgtype != LTG_RUSHBASE) {
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 5
EQI4 $247
line 783
;783:			BotRefuseOrder(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotRefuseOrder
CALLV
pop
line 784
;784:			bs->ltgtype = LTG_RUSHBASE;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 5
ASGNI4
line 785
;785:			bs->teamgoal_time = FloatTime() + CTF_RUSHBASE_TIME;
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1123024896
ADDF4
ASGNF4
line 786
;786:			bs->rushbaseaway_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6152
ADDP4
CNSTF4 0
ASGNF4
line 787
;787:			bs->decisionmaker = bs->client;
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 4
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 788
;788:			bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 789
;789:			BotSetTeamStatus(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeamStatus
CALLV
pop
line 790
;790:		}
LABELV $247
line 791
;791:	}
LABELV $245
line 792
;792:}
LABELV $244
endproc BotCTFRetreatGoals 8 4
export BotTeamGoals
proc BotTeamGoals 0 4
line 1328
;793:
;794:#ifdef MISSIONPACK
;795:/*
;796:==================
;797:Bot1FCTFSeekGoals
;798:==================
;799:*/
;800:void Bot1FCTFSeekGoals(bot_state_t *bs) {
;801:	aas_entityinfo_t entinfo;
;802:	float rnd, l1, l2;
;803:	int c;
;804:
;805:	//when carrying a flag in ctf the bot should rush to the base
;806:	if (Bot1FCTFCarryingFlag(bs)) {
;807:		//if not already rushing to the base
;808:		if (bs->ltgtype != LTG_RUSHBASE) {
;809:			BotRefuseOrder(bs);
;810:			bs->ltgtype = LTG_RUSHBASE;
;811:			bs->teamgoal_time = FloatTime() + CTF_RUSHBASE_TIME;
;812:			bs->rushbaseaway_time = 0;
;813:			bs->decisionmaker = bs->client;
;814:			bs->ordered = qfalse;
;815:			//get an alternative route goal towards the enemy base
;816:			BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
;817:			//
;818:			BotSetTeamStatus(bs);
;819:			BotVoiceChat(bs, -1, VOICECHAT_IHAVEFLAG);
;820:		}
;821:		return;
;822:	}
;823:	// if the bot decided to follow someone
;824:	if ( bs->ltgtype == LTG_TEAMACCOMPANY && !bs->ordered ) {
;825:		// if the team mate being accompanied no longer carries the flag
;826:		BotEntityInfo(bs->teammate, &entinfo);
;827:		if (!EntityCarriesFlag(&entinfo)) {
;828:			bs->ltgtype = 0;
;829:		}
;830:	}
;831:	//our team has the flag
;832:	if (bs->neutralflagstatus == 1) {
;833:		if (bs->owndecision_time < FloatTime()) {
;834:			// if not already following someone
;835:			if (bs->ltgtype != LTG_TEAMACCOMPANY) {
;836:				//if there is a visible team mate flag carrier
;837:				c = BotTeamFlagCarrierVisible(bs);
;838:				if (c >= 0) {
;839:					BotRefuseOrder(bs);
;840:					//follow the flag carrier
;841:					bs->decisionmaker = bs->client;
;842:					bs->ordered = qfalse;
;843:					//the team mate
;844:					bs->teammate = c;
;845:					//last time the team mate was visible
;846:					bs->teammatevisible_time = FloatTime();
;847:					//no message
;848:					bs->teammessage_time = 0;
;849:					//no arrive message
;850:					bs->arrive_time = 1;
;851:					//
;852:					BotVoiceChat(bs, bs->teammate, VOICECHAT_ONFOLLOW);
;853:					//get the team goal time
;854:					bs->teamgoal_time = FloatTime() + TEAM_ACCOMPANY_TIME;
;855:					bs->ltgtype = LTG_TEAMACCOMPANY;
;856:					bs->formation_dist = 3.5 * 32;		//3.5 meter
;857:					BotSetTeamStatus(bs);
;858:					bs->owndecision_time = FloatTime() + 5;
;859:					return;
;860:				}
;861:			}
;862:			//if already a CTF or team goal
;863:			if (bs->ltgtype == LTG_TEAMHELP ||
;864:					bs->ltgtype == LTG_TEAMACCOMPANY ||
;865:					bs->ltgtype == LTG_DEFENDKEYAREA ||
;866:					bs->ltgtype == LTG_GETFLAG ||
;867:					bs->ltgtype == LTG_RUSHBASE ||
;868:					bs->ltgtype == LTG_CAMPORDER ||
;869:					bs->ltgtype == LTG_PATROL ||
;870:					bs->ltgtype == LTG_ATTACKENEMYBASE ||
;871:					bs->ltgtype == LTG_GETITEM ||
;872:					bs->ltgtype == LTG_MAKELOVE_UNDER ||
;873:					bs->ltgtype == LTG_MAKELOVE_ONTOP) {
;874:				return;
;875:			}
;876:			//if not already attacking the enemy base
;877:			if (bs->ltgtype != LTG_ATTACKENEMYBASE) {
;878:				BotRefuseOrder(bs);
;879:				bs->decisionmaker = bs->client;
;880:				bs->ordered = qfalse;
;881:				//
;882:				if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &ctf_blueflag, sizeof(bot_goal_t));
;883:				else memcpy(&bs->teamgoal, &ctf_redflag, sizeof(bot_goal_t));
;884:				//set the ltg type
;885:				bs->ltgtype = LTG_ATTACKENEMYBASE;
;886:				//set the time the bot will stop getting the flag
;887:				bs->teamgoal_time = FloatTime() + TEAM_ATTACKENEMYBASE_TIME;
;888:				BotSetTeamStatus(bs);
;889:				bs->owndecision_time = FloatTime() + 5;
;890:			}
;891:		}
;892:		return;
;893:	}
;894:	//enemy team has the flag
;895:	else if (bs->neutralflagstatus == 2) {
;896:		if (bs->owndecision_time < FloatTime()) {
;897:			c = BotEnemyFlagCarrierVisible(bs);
;898:			if (c >= 0) {
;899:				//FIXME: attack enemy flag carrier
;900:			}
;901:			//if already a CTF or team goal
;902:			if (bs->ltgtype == LTG_TEAMHELP ||
;903:					bs->ltgtype == LTG_TEAMACCOMPANY ||
;904:					bs->ltgtype == LTG_CAMPORDER ||
;905:					bs->ltgtype == LTG_PATROL ||
;906:					bs->ltgtype == LTG_GETITEM) {
;907:				return;
;908:			}
;909:			// if not already defending the base
;910:			if (bs->ltgtype != LTG_DEFENDKEYAREA) {
;911:				BotRefuseOrder(bs);
;912:				bs->decisionmaker = bs->client;
;913:				bs->ordered = qfalse;
;914:				//
;915:				if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &ctf_redflag, sizeof(bot_goal_t));
;916:				else memcpy(&bs->teamgoal, &ctf_blueflag, sizeof(bot_goal_t));
;917:				//set the ltg type
;918:				bs->ltgtype = LTG_DEFENDKEYAREA;
;919:				//set the time the bot stops defending the base
;920:				bs->teamgoal_time = FloatTime() + TEAM_DEFENDKEYAREA_TIME;
;921:				bs->defendaway_time = 0;
;922:				BotSetTeamStatus(bs);
;923:				bs->owndecision_time = FloatTime() + 5;
;924:			}
;925:		}
;926:		return;
;927:	}
;928:	// don't just do something wait for the bot team leader to give orders
;929:	if (BotTeamLeader(bs)) {
;930:		return;
;931:	}
;932:	// if the bot is ordered to do something
;933:	if ( bs->lastgoal_ltgtype ) {
;934:		bs->teamgoal_time += 60;
;935:	}
;936:	// if the bot decided to do something on it's own and has a last ordered goal
;937:	if ( !bs->ordered && bs->lastgoal_ltgtype ) {
;938:		bs->ltgtype = 0;
;939:	}
;940:	//if already a CTF or team goal
;941:	if (bs->ltgtype == LTG_TEAMHELP ||
;942:			bs->ltgtype == LTG_TEAMACCOMPANY ||
;943:			bs->ltgtype == LTG_DEFENDKEYAREA ||
;944:			bs->ltgtype == LTG_GETFLAG ||
;945:			bs->ltgtype == LTG_RUSHBASE ||
;946:			bs->ltgtype == LTG_RETURNFLAG ||
;947:			bs->ltgtype == LTG_CAMPORDER ||
;948:			bs->ltgtype == LTG_PATROL ||
;949:			bs->ltgtype == LTG_ATTACKENEMYBASE ||
;950:			bs->ltgtype == LTG_GETITEM ||
;951:			bs->ltgtype == LTG_MAKELOVE_UNDER ||
;952:			bs->ltgtype == LTG_MAKELOVE_ONTOP) {
;953:		return;
;954:	}
;955:	//
;956:	if (BotSetLastOrderedTask(bs))
;957:		return;
;958:	//
;959:	if (bs->owndecision_time > FloatTime())
;960:		return;;
;961:	//if the bot is roaming
;962:	if (bs->ctfroam_time > FloatTime())
;963:		return;
;964:	//if the bot has anough aggression to decide what to do
;965:	if (BotAggression(bs) < 50)
;966:		return;
;967:	//set the time to send a message to the team mates
;968:	bs->teammessage_time = FloatTime() + 2 * random();
;969:	//
;970:	if (bs->teamtaskpreference & (TEAMTP_ATTACKER|TEAMTP_DEFENDER)) {
;971:		if (bs->teamtaskpreference & TEAMTP_ATTACKER) {
;972:			l1 = 0.7f;
;973:		}
;974:		else {
;975:			l1 = 0.2f;
;976:		}
;977:		l2 = 0.9f;
;978:	}
;979:	else {
;980:		l1 = 0.4f;
;981:		l2 = 0.7f;
;982:	}
;983:	//get the flag or defend the base
;984:	rnd = random();
;985:	if (rnd < l1 && ctf_neutralflag.areanum) {
;986:		bs->decisionmaker = bs->client;
;987:		bs->ordered = qfalse;
;988:		bs->ltgtype = LTG_GETFLAG;
;989:		//set the time the bot will stop getting the flag
;990:		bs->teamgoal_time = FloatTime() + CTF_GETFLAG_TIME;
;991:		BotSetTeamStatus(bs);
;992:	}
;993:	else if (rnd < l2 && ctf_redflag.areanum && ctf_blueflag.areanum) {
;994:		bs->decisionmaker = bs->client;
;995:		bs->ordered = qfalse;
;996:		//
;997:		if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &ctf_redflag, sizeof(bot_goal_t));
;998:		else memcpy(&bs->teamgoal, &ctf_blueflag, sizeof(bot_goal_t));
;999:		//set the ltg type
;1000:		bs->ltgtype = LTG_DEFENDKEYAREA;
;1001:		//set the time the bot stops defending the base
;1002:		bs->teamgoal_time = FloatTime() + TEAM_DEFENDKEYAREA_TIME;
;1003:		bs->defendaway_time = 0;
;1004:		BotSetTeamStatus(bs);
;1005:	}
;1006:	else {
;1007:		bs->ltgtype = 0;
;1008:		//set the time the bot will stop roaming
;1009:		bs->ctfroam_time = FloatTime() + CTF_ROAM_TIME;
;1010:		BotSetTeamStatus(bs);
;1011:	}
;1012:	bs->owndecision_time = FloatTime() + 5;
;1013:#ifdef DEBUG
;1014:	BotPrintTeamGoal(bs);
;1015:#endif //DEBUG
;1016:}
;1017:
;1018:/*
;1019:==================
;1020:Bot1FCTFRetreatGoals
;1021:==================
;1022:*/
;1023:void Bot1FCTFRetreatGoals(bot_state_t *bs) {
;1024:	//when carrying a flag in ctf the bot should rush to the enemy base
;1025:	if (Bot1FCTFCarryingFlag(bs)) {
;1026:		//if not already rushing to the base
;1027:		if (bs->ltgtype != LTG_RUSHBASE) {
;1028:			BotRefuseOrder(bs);
;1029:			bs->ltgtype = LTG_RUSHBASE;
;1030:			bs->teamgoal_time = FloatTime() + CTF_RUSHBASE_TIME;
;1031:			bs->rushbaseaway_time = 0;
;1032:			bs->decisionmaker = bs->client;
;1033:			bs->ordered = qfalse;
;1034:			//get an alternative route goal towards the enemy base
;1035:			BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
;1036:			BotSetTeamStatus(bs);
;1037:		}
;1038:	}
;1039:}
;1040:
;1041:/*
;1042:==================
;1043:BotObeliskSeekGoals
;1044:==================
;1045:*/
;1046:void BotObeliskSeekGoals(bot_state_t *bs) {
;1047:	float rnd, l1, l2;
;1048:
;1049:	// don't just do something wait for the bot team leader to give orders
;1050:	if (BotTeamLeader(bs)) {
;1051:		return;
;1052:	}
;1053:	// if the bot is ordered to do something
;1054:	if ( bs->lastgoal_ltgtype ) {
;1055:		bs->teamgoal_time += 60;
;1056:	}
;1057:	//if already a team goal
;1058:	if (bs->ltgtype == LTG_TEAMHELP ||
;1059:			bs->ltgtype == LTG_TEAMACCOMPANY ||
;1060:			bs->ltgtype == LTG_DEFENDKEYAREA ||
;1061:			bs->ltgtype == LTG_GETFLAG ||
;1062:			bs->ltgtype == LTG_RUSHBASE ||
;1063:			bs->ltgtype == LTG_RETURNFLAG ||
;1064:			bs->ltgtype == LTG_CAMPORDER ||
;1065:			bs->ltgtype == LTG_PATROL ||
;1066:			bs->ltgtype == LTG_ATTACKENEMYBASE ||
;1067:			bs->ltgtype == LTG_GETITEM ||
;1068:			bs->ltgtype == LTG_MAKELOVE_UNDER ||
;1069:			bs->ltgtype == LTG_MAKELOVE_ONTOP) {
;1070:		return;
;1071:	}
;1072:	//
;1073:	if (BotSetLastOrderedTask(bs))
;1074:		return;
;1075:	//if the bot is roaming
;1076:	if (bs->ctfroam_time > FloatTime())
;1077:		return;
;1078:	//if the bot has anough aggression to decide what to do
;1079:	if (BotAggression(bs) < 50)
;1080:		return;
;1081:	//set the time to send a message to the team mates
;1082:	bs->teammessage_time = FloatTime() + 2 * random();
;1083:	//
;1084:	if (bs->teamtaskpreference & (TEAMTP_ATTACKER|TEAMTP_DEFENDER)) {
;1085:		if (bs->teamtaskpreference & TEAMTP_ATTACKER) {
;1086:			l1 = 0.7f;
;1087:		}
;1088:		else {
;1089:			l1 = 0.2f;
;1090:		}
;1091:		l2 = 0.9f;
;1092:	}
;1093:	else {
;1094:		l1 = 0.4f;
;1095:		l2 = 0.7f;
;1096:	}
;1097:	//get the flag or defend the base
;1098:	rnd = random();
;1099:	if (rnd < l1 && redobelisk.areanum && blueobelisk.areanum) {
;1100:		bs->decisionmaker = bs->client;
;1101:		bs->ordered = qfalse;
;1102:		//
;1103:		if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &blueobelisk, sizeof(bot_goal_t));
;1104:		else memcpy(&bs->teamgoal, &redobelisk, sizeof(bot_goal_t));
;1105:		//set the ltg type
;1106:		bs->ltgtype = LTG_ATTACKENEMYBASE;
;1107:		//set the time the bot will stop attacking the enemy base
;1108:		bs->teamgoal_time = FloatTime() + TEAM_ATTACKENEMYBASE_TIME;
;1109:		//get an alternate route goal towards the enemy base
;1110:		BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
;1111:		BotSetTeamStatus(bs);
;1112:	}
;1113:	else if (rnd < l2 && redobelisk.areanum && blueobelisk.areanum) {
;1114:		bs->decisionmaker = bs->client;
;1115:		bs->ordered = qfalse;
;1116:		//
;1117:		if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &redobelisk, sizeof(bot_goal_t));
;1118:		else memcpy(&bs->teamgoal, &blueobelisk, sizeof(bot_goal_t));
;1119:		//set the ltg type
;1120:		bs->ltgtype = LTG_DEFENDKEYAREA;
;1121:		//set the time the bot stops defending the base
;1122:		bs->teamgoal_time = FloatTime() + TEAM_DEFENDKEYAREA_TIME;
;1123:		bs->defendaway_time = 0;
;1124:		BotSetTeamStatus(bs);
;1125:	}
;1126:	else {
;1127:		bs->ltgtype = 0;
;1128:		//set the time the bot will stop roaming
;1129:		bs->ctfroam_time = FloatTime() + CTF_ROAM_TIME;
;1130:		BotSetTeamStatus(bs);
;1131:	}
;1132:}
;1133:
;1134:/*
;1135:==================
;1136:BotGoHarvest
;1137:==================
;1138:*/
;1139:void BotGoHarvest(bot_state_t *bs) {
;1140:	//
;1141:	if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &blueobelisk, sizeof(bot_goal_t));
;1142:	else memcpy(&bs->teamgoal, &redobelisk, sizeof(bot_goal_t));
;1143:	//set the ltg type
;1144:	bs->ltgtype = LTG_HARVEST;
;1145:	//set the time the bot will stop harvesting
;1146:	bs->teamgoal_time = FloatTime() + TEAM_HARVEST_TIME;
;1147:	bs->harvestaway_time = 0;
;1148:	BotSetTeamStatus(bs);
;1149:}
;1150:
;1151:/*
;1152:==================
;1153:BotObeliskRetreatGoals
;1154:==================
;1155:*/
;1156:void BotObeliskRetreatGoals(bot_state_t *bs) {
;1157:	//nothing special
;1158:}
;1159:
;1160:/*
;1161:==================
;1162:BotHarvesterSeekGoals
;1163:==================
;1164:*/
;1165:void BotHarvesterSeekGoals(bot_state_t *bs) {
;1166:	aas_entityinfo_t entinfo;
;1167:	float rnd, l1, l2;
;1168:	int c;
;1169:
;1170:	//when carrying cubes in harvester the bot should rush to the base
;1171:	if (BotHarvesterCarryingCubes(bs)) {
;1172:		//if not already rushing to the base
;1173:		if (bs->ltgtype != LTG_RUSHBASE) {
;1174:			BotRefuseOrder(bs);
;1175:			bs->ltgtype = LTG_RUSHBASE;
;1176:			bs->teamgoal_time = FloatTime() + CTF_RUSHBASE_TIME;
;1177:			bs->rushbaseaway_time = 0;
;1178:			bs->decisionmaker = bs->client;
;1179:			bs->ordered = qfalse;
;1180:			//get an alternative route goal towards the enemy base
;1181:			BotGetAlternateRouteGoal(bs, BotOppositeTeam(bs));
;1182:			//
;1183:			BotSetTeamStatus(bs);
;1184:		}
;1185:		return;
;1186:	}
;1187:	// don't just do something wait for the bot team leader to give orders
;1188:	if (BotTeamLeader(bs)) {
;1189:		return;
;1190:	}
;1191:	// if the bot decided to follow someone
;1192:	if ( bs->ltgtype == LTG_TEAMACCOMPANY && !bs->ordered ) {
;1193:		// if the team mate being accompanied no longer carries the flag
;1194:		BotEntityInfo(bs->teammate, &entinfo);
;1195:		if (!EntityCarriesCubes(&entinfo)) {
;1196:			bs->ltgtype = 0;
;1197:		}
;1198:	}
;1199:	// if the bot is ordered to do something
;1200:	if ( bs->lastgoal_ltgtype ) {
;1201:		bs->teamgoal_time += 60;
;1202:	}
;1203:	//if not yet doing something
;1204:	if (bs->ltgtype == LTG_TEAMHELP ||
;1205:			bs->ltgtype == LTG_TEAMACCOMPANY ||
;1206:			bs->ltgtype == LTG_DEFENDKEYAREA ||
;1207:			bs->ltgtype == LTG_GETFLAG ||
;1208:			bs->ltgtype == LTG_CAMPORDER ||
;1209:			bs->ltgtype == LTG_PATROL ||
;1210:			bs->ltgtype == LTG_ATTACKENEMYBASE ||
;1211:			bs->ltgtype == LTG_HARVEST ||
;1212:			bs->ltgtype == LTG_GETITEM ||
;1213:			bs->ltgtype == LTG_MAKELOVE_UNDER ||
;1214:			bs->ltgtype == LTG_MAKELOVE_ONTOP) {
;1215:		return;
;1216:	}
;1217:	//
;1218:	if (BotSetLastOrderedTask(bs))
;1219:		return;
;1220:	//if the bot is roaming
;1221:	if (bs->ctfroam_time > FloatTime())
;1222:		return;
;1223:	//if the bot has anough aggression to decide what to do
;1224:	if (BotAggression(bs) < 50)
;1225:		return;
;1226:	//set the time to send a message to the team mates
;1227:	bs->teammessage_time = FloatTime() + 2 * random();
;1228:	//
;1229:	c = BotEnemyCubeCarrierVisible(bs);
;1230:	if (c >= 0) {
;1231:		//FIXME: attack enemy cube carrier
;1232:	}
;1233:	if (bs->ltgtype != LTG_TEAMACCOMPANY) {
;1234:		//if there is a visible team mate carrying cubes
;1235:		c = BotTeamCubeCarrierVisible(bs);
;1236:		if (c >= 0) {
;1237:			//follow the team mate carrying cubes
;1238:			bs->decisionmaker = bs->client;
;1239:			bs->ordered = qfalse;
;1240:			//the team mate
;1241:			bs->teammate = c;
;1242:			//last time the team mate was visible
;1243:			bs->teammatevisible_time = FloatTime();
;1244:			//no message
;1245:			bs->teammessage_time = 0;
;1246:			//no arrive message
;1247:			bs->arrive_time = 1;
;1248:			//
;1249:			BotVoiceChat(bs, bs->teammate, VOICECHAT_ONFOLLOW);
;1250:			//get the team goal time
;1251:			bs->teamgoal_time = FloatTime() + TEAM_ACCOMPANY_TIME;
;1252:			bs->ltgtype = LTG_TEAMACCOMPANY;
;1253:			bs->formation_dist = 3.5 * 32;		//3.5 meter
;1254:			BotSetTeamStatus(bs);
;1255:			return;
;1256:		}
;1257:	}
;1258:	//
;1259:	if (bs->teamtaskpreference & (TEAMTP_ATTACKER|TEAMTP_DEFENDER)) {
;1260:		if (bs->teamtaskpreference & TEAMTP_ATTACKER) {
;1261:			l1 = 0.7f;
;1262:		}
;1263:		else {
;1264:			l1 = 0.2f;
;1265:		}
;1266:		l2 = 0.9f;
;1267:	}
;1268:	else {
;1269:		l1 = 0.4f;
;1270:		l2 = 0.7f;
;1271:	}
;1272:	//
;1273:	rnd = random();
;1274:	if (rnd < l1 && redobelisk.areanum && blueobelisk.areanum) {
;1275:		bs->decisionmaker = bs->client;
;1276:		bs->ordered = qfalse;
;1277:		BotGoHarvest(bs);
;1278:	}
;1279:	else if (rnd < l2 && redobelisk.areanum && blueobelisk.areanum) {
;1280:		bs->decisionmaker = bs->client;
;1281:		bs->ordered = qfalse;
;1282:		//
;1283:		if (BotTeam(bs) == TEAM_RED) memcpy(&bs->teamgoal, &redobelisk, sizeof(bot_goal_t));
;1284:		else memcpy(&bs->teamgoal, &blueobelisk, sizeof(bot_goal_t));
;1285:		//set the ltg type
;1286:		bs->ltgtype = LTG_DEFENDKEYAREA;
;1287:		//set the time the bot stops defending the base
;1288:		bs->teamgoal_time = FloatTime() + TEAM_DEFENDKEYAREA_TIME;
;1289:		bs->defendaway_time = 0;
;1290:		BotSetTeamStatus(bs);
;1291:	}
;1292:	else {
;1293:		bs->ltgtype = 0;
;1294:		//set the time the bot will stop roaming
;1295:		bs->ctfroam_time = FloatTime() + CTF_ROAM_TIME;
;1296:		BotSetTeamStatus(bs);
;1297:	}
;1298:}
;1299:
;1300:/*
;1301:==================
;1302:BotHarvesterRetreatGoals
;1303:==================
;1304:*/
;1305:void BotHarvesterRetreatGoals(bot_state_t *bs) {
;1306:	//when carrying cubes in harvester the bot should rush to the base
;1307:	if (BotHarvesterCarryingCubes(bs)) {
;1308:		//if not already rushing to the base
;1309:		if (bs->ltgtype != LTG_RUSHBASE) {
;1310:			BotRefuseOrder(bs);
;1311:			bs->ltgtype = LTG_RUSHBASE;
;1312:			bs->teamgoal_time = FloatTime() + CTF_RUSHBASE_TIME;
;1313:			bs->rushbaseaway_time = 0;
;1314:			bs->decisionmaker = bs->client;
;1315:			bs->ordered = qfalse;
;1316:			BotSetTeamStatus(bs);
;1317:		}
;1318:		return;
;1319:	}
;1320:}
;1321:#endif
;1322:
;1323:/*
;1324:==================
;1325:BotTeamGoals
;1326:==================
;1327:*/
;1328:void BotTeamGoals(bot_state_t *bs, int retreat) {
line 1330
;1329:
;1330:	if ( retreat ) {
ADDRFP4 4
INDIRI4
CNSTI4 0
EQI4 $250
line 1331
;1331:		if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $251
line 1332
;1332:			BotCTFRetreatGoals(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotCTFRetreatGoals
CALLV
pop
line 1333
;1333:		}
line 1345
;1334:#ifdef MISSIONPACK
;1335:		else if (gametype == GT_1FCTF) {
;1336:			Bot1FCTFRetreatGoals(bs);
;1337:		}
;1338:		else if (gametype == GT_OBELISK) {
;1339:			BotObeliskRetreatGoals(bs);
;1340:		}
;1341:		else if (gametype == GT_HARVESTER) {
;1342:			BotHarvesterRetreatGoals(bs);
;1343:		}
;1344:#endif
;1345:	}
ADDRGP4 $251
JUMPV
LABELV $250
line 1346
;1346:	else {
line 1347
;1347:		if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $254
line 1349
;1348:			//decide what to do in CTF mode
;1349:			BotCTFSeekGoals(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotCTFSeekGoals
CALLV
pop
line 1350
;1350:		}
LABELV $254
line 1362
;1351:#ifdef MISSIONPACK
;1352:		else if (gametype == GT_1FCTF) {
;1353:			Bot1FCTFSeekGoals(bs);
;1354:		}
;1355:		else if (gametype == GT_OBELISK) {
;1356:			BotObeliskSeekGoals(bs);
;1357:		}
;1358:		else if (gametype == GT_HARVESTER) {
;1359:			BotHarvesterSeekGoals(bs);
;1360:		}
;1361:#endif
;1362:	}
LABELV $251
line 1365
;1363:	// reset the order time which is used to see if
;1364:	// we decided to refuse an order
;1365:	bs->order_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6616
ADDP4
CNSTF4 0
ASGNF4
line 1366
;1366:}
LABELV $249
endproc BotTeamGoals 0 4
export BotPointAreaNum
proc BotPointAreaNum 68 20
line 1373
;1367:
;1368:/*
;1369:==================
;1370:BotPointAreaNum
;1371:==================
;1372:*/
;1373:int BotPointAreaNum(vec3_t origin) {
line 1377
;1374:	int areanum, numareas, areas[10];
;1375:	vec3_t end;
;1376:
;1377:	areanum = trap_AAS_PointAreaNum(origin);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 60
ADDRGP4 trap_AAS_PointAreaNum
CALLI4
ASGNI4
ADDRLP4 12
ADDRLP4 60
INDIRI4
ASGNI4
line 1378
;1378:	if (areanum) return areanum;
ADDRLP4 12
INDIRI4
CNSTI4 0
EQI4 $257
ADDRLP4 12
INDIRI4
RETI4
ADDRGP4 $256
JUMPV
LABELV $257
line 1379
;1379:	VectorCopy(origin, end);
ADDRLP4 0
ADDRFP4 0
INDIRP4
INDIRB
ASGNB 12
line 1380
;1380:	end[2] += 10;
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
CNSTF4 1092616192
ADDF4
ASGNF4
line 1381
;1381:	numareas = trap_AAS_TraceAreas(origin, end, areas, NULL, 10);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ARGP4
ADDRLP4 20
ARGP4
CNSTP4 0
ARGP4
CNSTI4 10
ARGI4
ADDRLP4 64
ADDRGP4 trap_AAS_TraceAreas
CALLI4
ASGNI4
ADDRLP4 16
ADDRLP4 64
INDIRI4
ASGNI4
line 1382
;1382:	if (numareas > 0) return areas[0];
ADDRLP4 16
INDIRI4
CNSTI4 0
LEI4 $260
ADDRLP4 20
INDIRI4
RETI4
ADDRGP4 $256
JUMPV
LABELV $260
line 1383
;1383:	return 0;
CNSTI4 0
RETI4
LABELV $256
endproc BotPointAreaNum 68 20
export ClientName
proc ClientName 1032 12
line 1391
;1384:}
;1385:
;1386:/*
;1387:==================
;1388:ClientName
;1389:==================
;1390:*/
;1391:char *ClientName(int client, char *name, int size) {
line 1394
;1392:	char buf[MAX_INFO_STRING];
;1393:
;1394:	if (client < 0 || client >= MAX_CLIENTS) {
ADDRLP4 1024
ADDRFP4 0
INDIRI4
ASGNI4
ADDRLP4 1024
INDIRI4
CNSTI4 0
LTI4 $265
ADDRLP4 1024
INDIRI4
CNSTI4 64
LTI4 $263
LABELV $265
line 1395
;1395:		BotAI_Print(PRT_ERROR, "ClientName: client out of range\n");
CNSTI4 3
ARGI4
ADDRGP4 $266
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 1396
;1396:		return "[client out of range]";
ADDRGP4 $267
RETP4
ADDRGP4 $262
JUMPV
LABELV $263
line 1398
;1397:	}
;1398:	trap_GetConfigstring(CS_PLAYERS+client, buf, sizeof(buf));
ADDRFP4 0
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 1399
;1399:	strncpy(name, Info_ValueForKey(buf, "n"), size-1);
ADDRLP4 0
ARGP4
ADDRGP4 $268
ARGP4
ADDRLP4 1028
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 1028
INDIRP4
ARGP4
ADDRFP4 8
INDIRI4
CNSTI4 1
SUBI4
ARGI4
ADDRGP4 strncpy
CALLP4
pop
line 1400
;1400:	name[size-1] = '\0';
ADDRFP4 8
INDIRI4
CNSTI4 1
SUBI4
ADDRFP4 4
INDIRP4
ADDP4
CNSTI1 0
ASGNI1
line 1401
;1401:	Q_CleanStr( name );
ADDRFP4 4
INDIRP4
ARGP4
ADDRGP4 Q_CleanStr
CALLP4
pop
line 1402
;1402:	return name;
ADDRFP4 4
INDIRP4
RETP4
LABELV $262
endproc ClientName 1032 12
export ClientSkin
proc ClientSkin 1032 12
line 1410
;1403:}
;1404:
;1405:/*
;1406:==================
;1407:ClientSkin
;1408:==================
;1409:*/
;1410:char *ClientSkin(int client, char *skin, int size) {
line 1413
;1411:	char buf[MAX_INFO_STRING];
;1412:
;1413:	if (client < 0 || client >= MAX_CLIENTS) {
ADDRLP4 1024
ADDRFP4 0
INDIRI4
ASGNI4
ADDRLP4 1024
INDIRI4
CNSTI4 0
LTI4 $272
ADDRLP4 1024
INDIRI4
CNSTI4 64
LTI4 $270
LABELV $272
line 1414
;1414:		BotAI_Print(PRT_ERROR, "ClientSkin: client out of range\n");
CNSTI4 3
ARGI4
ADDRGP4 $273
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 1415
;1415:		return "[client out of range]";
ADDRGP4 $267
RETP4
ADDRGP4 $269
JUMPV
LABELV $270
line 1417
;1416:	}
;1417:	trap_GetConfigstring(CS_PLAYERS+client, buf, sizeof(buf));
ADDRFP4 0
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 1418
;1418:	strncpy(skin, Info_ValueForKey(buf, "model"), size-1);
ADDRLP4 0
ARGP4
ADDRGP4 $274
ARGP4
ADDRLP4 1028
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 1028
INDIRP4
ARGP4
ADDRFP4 8
INDIRI4
CNSTI4 1
SUBI4
ARGI4
ADDRGP4 strncpy
CALLP4
pop
line 1419
;1419:	skin[size-1] = '\0';
ADDRFP4 8
INDIRI4
CNSTI4 1
SUBI4
ADDRFP4 4
INDIRP4
ADDP4
CNSTI1 0
ASGNI1
line 1420
;1420:	return skin;
ADDRFP4 4
INDIRP4
RETP4
LABELV $269
endproc ClientSkin 1032 12
bss
align 4
LABELV $276
skip 4
export ClientFromName
code
proc ClientFromName 1040 12
line 1428
;1421:}
;1422:
;1423:/*
;1424:==================
;1425:ClientFromName
;1426:==================
;1427:*/
;1428:int ClientFromName(char *name) {
line 1433
;1429:	int i;
;1430:	char buf[MAX_INFO_STRING];
;1431:	static int maxclients;
;1432:
;1433:	if (!maxclients)
ADDRGP4 $276
INDIRI4
CNSTI4 0
NEI4 $277
line 1434
;1434:		maxclients = trap_Cvar_VariableIntegerValue("sv_maxclients");
ADDRGP4 $279
ARGP4
ADDRLP4 1028
ADDRGP4 trap_Cvar_VariableIntegerValue
CALLI4
ASGNI4
ADDRGP4 $276
ADDRLP4 1028
INDIRI4
ASGNI4
LABELV $277
line 1435
;1435:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $283
JUMPV
LABELV $280
line 1436
;1436:		trap_GetConfigstring(CS_PLAYERS+i, buf, sizeof(buf));
ADDRLP4 0
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 4
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 1437
;1437:		Q_CleanStr( buf );
ADDRLP4 4
ARGP4
ADDRGP4 Q_CleanStr
CALLP4
pop
line 1438
;1438:		if (!Q_stricmp(Info_ValueForKey(buf, "n"), name)) return i;
ADDRLP4 4
ARGP4
ADDRGP4 $268
ARGP4
ADDRLP4 1032
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 1032
INDIRP4
ARGP4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 1036
ADDRGP4 Q_stricmp
CALLI4
ASGNI4
ADDRLP4 1036
INDIRI4
CNSTI4 0
NEI4 $284
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $275
JUMPV
LABELV $284
line 1439
;1439:	}
LABELV $281
line 1435
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $283
ADDRLP4 0
INDIRI4
ADDRGP4 $276
INDIRI4
GEI4 $286
ADDRLP4 0
INDIRI4
CNSTI4 64
LTI4 $280
LABELV $286
line 1440
;1440:	return -1;
CNSTI4 -1
RETI4
LABELV $275
endproc ClientFromName 1040 12
bss
align 4
LABELV $288
skip 4
export ClientOnSameTeamFromName
code
proc ClientOnSameTeamFromName 1044 12
line 1448
;1441:}
;1442:
;1443:/*
;1444:==================
;1445:ClientOnSameTeamFromName
;1446:==================
;1447:*/
;1448:int ClientOnSameTeamFromName(bot_state_t *bs, char *name) {
line 1453
;1449:	int i;
;1450:	char buf[MAX_INFO_STRING];
;1451:	static int maxclients;
;1452:
;1453:	if (!maxclients)
ADDRGP4 $288
INDIRI4
CNSTI4 0
NEI4 $289
line 1454
;1454:		maxclients = trap_Cvar_VariableIntegerValue("sv_maxclients");
ADDRGP4 $279
ARGP4
ADDRLP4 1028
ADDRGP4 trap_Cvar_VariableIntegerValue
CALLI4
ASGNI4
ADDRGP4 $288
ADDRLP4 1028
INDIRI4
ASGNI4
LABELV $289
line 1455
;1455:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $294
JUMPV
LABELV $291
line 1456
;1456:		if (!BotSameTeam(bs, i))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 1032
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 1032
INDIRI4
CNSTI4 0
NEI4 $295
line 1457
;1457:			continue;
ADDRGP4 $292
JUMPV
LABELV $295
line 1458
;1458:		trap_GetConfigstring(CS_PLAYERS+i, buf, sizeof(buf));
ADDRLP4 0
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 4
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 1459
;1459:		Q_CleanStr( buf );
ADDRLP4 4
ARGP4
ADDRGP4 Q_CleanStr
CALLP4
pop
line 1460
;1460:		if (!Q_stricmp(Info_ValueForKey(buf, "n"), name)) return i;
ADDRLP4 4
ARGP4
ADDRGP4 $268
ARGP4
ADDRLP4 1036
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 1036
INDIRP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 1040
ADDRGP4 Q_stricmp
CALLI4
ASGNI4
ADDRLP4 1040
INDIRI4
CNSTI4 0
NEI4 $297
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $287
JUMPV
LABELV $297
line 1461
;1461:	}
LABELV $292
line 1455
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $294
ADDRLP4 0
INDIRI4
ADDRGP4 $288
INDIRI4
GEI4 $299
ADDRLP4 0
INDIRI4
CNSTI4 64
LTI4 $291
LABELV $299
line 1462
;1462:	return -1;
CNSTI4 -1
RETI4
LABELV $287
endproc ClientOnSameTeamFromName 1044 12
export stristr
proc stristr 12 4
line 1470
;1463:}
;1464:
;1465:/*
;1466:==================
;1467:stristr
;1468:==================
;1469:*/
;1470:char *stristr(char *str, char *charset) {
ADDRGP4 $302
JUMPV
LABELV $301
line 1473
;1471:	int i;
;1472:
;1473:	while(*str) {
line 1474
;1474:		for (i = 0; charset[i] && str[i]; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $307
JUMPV
LABELV $304
line 1475
;1475:			if (toupper(charset[i]) != toupper(str[i])) break;
ADDRLP4 0
INDIRI4
ADDRFP4 4
INDIRP4
ADDP4
INDIRI1
CVII4 1
ARGI4
ADDRLP4 4
ADDRGP4 toupper
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
ADDP4
INDIRI1
CVII4 1
ARGI4
ADDRLP4 8
ADDRGP4 toupper
CALLI4
ASGNI4
ADDRLP4 4
INDIRI4
ADDRLP4 8
INDIRI4
EQI4 $308
ADDRGP4 $306
JUMPV
LABELV $308
line 1476
;1476:		}
LABELV $305
line 1474
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $307
ADDRLP4 8
CNSTI4 0
ASGNI4
ADDRLP4 0
INDIRI4
ADDRFP4 4
INDIRP4
ADDP4
INDIRI1
CVII4 1
ADDRLP4 8
INDIRI4
EQI4 $310
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
ADDP4
INDIRI1
CVII4 1
ADDRLP4 8
INDIRI4
NEI4 $304
LABELV $310
LABELV $306
line 1477
;1477:		if (!charset[i]) return str;
ADDRLP4 0
INDIRI4
ADDRFP4 4
INDIRP4
ADDP4
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $311
ADDRFP4 0
INDIRP4
RETP4
ADDRGP4 $300
JUMPV
LABELV $311
line 1478
;1478:		str++;
ADDRFP4 0
ADDRFP4 0
INDIRP4
CNSTI4 1
ADDP4
ASGNP4
line 1479
;1479:	}
LABELV $302
line 1473
ADDRFP4 0
INDIRP4
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $301
line 1480
;1480:	return NULL;
CNSTP4 0
RETP4
LABELV $300
endproc stristr 12 4
export EasyClientName
proc EasyClientName 204 12
line 1488
;1481:}
;1482:
;1483:/*
;1484:==================
;1485:EasyClientName
;1486:==================
;1487:*/
;1488:char *EasyClientName(int client, char *buf, int size) {
line 1493
;1489:	int i;
;1490:	char *str1, *str2, *ptr, c;
;1491:	char name[128];
;1492:
;1493:	strcpy(name, ClientName(client, name, sizeof(name)));
ADDRFP4 0
INDIRI4
ARGI4
ADDRLP4 5
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 148
ADDRGP4 ClientName
CALLP4
ASGNP4
ADDRLP4 5
ARGP4
ADDRLP4 148
INDIRP4
ARGP4
ADDRGP4 strcpy
CALLP4
pop
line 1494
;1494:	for (i = 0; name[i]; i++) name[i] &= 127;
ADDRLP4 136
CNSTI4 0
ASGNI4
ADDRGP4 $317
JUMPV
LABELV $314
ADDRLP4 152
ADDRLP4 136
INDIRI4
ADDRLP4 5
ADDP4
ASGNP4
ADDRLP4 152
INDIRP4
ADDRLP4 152
INDIRP4
INDIRI1
CVII4 1
CNSTI4 127
BANDI4
CVII1 4
ASGNI1
LABELV $315
ADDRLP4 136
ADDRLP4 136
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $317
ADDRLP4 136
INDIRI4
ADDRLP4 5
ADDP4
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $314
line 1496
;1495:	//remove all spaces
;1496:	for (ptr = strstr(name, " "); ptr; ptr = strstr(name, " ")) {
ADDRLP4 5
ARGP4
ADDRGP4 $322
ARGP4
ADDRLP4 156
ADDRGP4 strstr
CALLP4
ASGNP4
ADDRLP4 0
ADDRLP4 156
INDIRP4
ASGNP4
ADDRGP4 $321
JUMPV
LABELV $318
line 1497
;1497:		memmove(ptr, ptr+1, strlen(ptr+1)+1);
ADDRLP4 0
INDIRP4
CNSTI4 1
ADDP4
ARGP4
ADDRLP4 160
ADDRGP4 strlen
CALLI4
ASGNI4
ADDRLP4 0
INDIRP4
ARGP4
ADDRLP4 168
CNSTI4 1
ASGNI4
ADDRLP4 0
INDIRP4
ADDRLP4 168
INDIRI4
ADDP4
ARGP4
ADDRLP4 160
INDIRI4
ADDRLP4 168
INDIRI4
ADDI4
ARGI4
ADDRGP4 memmove
CALLP4
pop
line 1498
;1498:	}
LABELV $319
line 1496
ADDRLP4 5
ARGP4
ADDRGP4 $322
ARGP4
ADDRLP4 160
ADDRGP4 strstr
CALLP4
ASGNP4
ADDRLP4 0
ADDRLP4 160
INDIRP4
ASGNP4
LABELV $321
ADDRLP4 0
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $318
line 1500
;1499:	//check for [x] and ]x[ clan names
;1500:	str1 = strstr(name, "[");
ADDRLP4 5
ARGP4
ADDRGP4 $323
ARGP4
ADDRLP4 164
ADDRGP4 strstr
CALLP4
ASGNP4
ADDRLP4 140
ADDRLP4 164
INDIRP4
ASGNP4
line 1501
;1501:	str2 = strstr(name, "]");
ADDRLP4 5
ARGP4
ADDRGP4 $324
ARGP4
ADDRLP4 168
ADDRGP4 strstr
CALLP4
ASGNP4
ADDRLP4 144
ADDRLP4 168
INDIRP4
ASGNP4
line 1502
;1502:	if (str1 && str2) {
ADDRLP4 172
CNSTU4 0
ASGNU4
ADDRLP4 140
INDIRP4
CVPU4 4
ADDRLP4 172
INDIRU4
EQU4 $325
ADDRLP4 144
INDIRP4
CVPU4 4
ADDRLP4 172
INDIRU4
EQU4 $325
line 1503
;1503:		if (str2 > str1) memmove(str1, str2+1, strlen(str2+1)+1);
ADDRLP4 144
INDIRP4
CVPU4 4
ADDRLP4 140
INDIRP4
CVPU4 4
LEU4 $327
ADDRLP4 144
INDIRP4
CNSTI4 1
ADDP4
ARGP4
ADDRLP4 176
ADDRGP4 strlen
CALLI4
ASGNI4
ADDRLP4 140
INDIRP4
ARGP4
ADDRLP4 180
CNSTI4 1
ASGNI4
ADDRLP4 144
INDIRP4
ADDRLP4 180
INDIRI4
ADDP4
ARGP4
ADDRLP4 176
INDIRI4
ADDRLP4 180
INDIRI4
ADDI4
ARGI4
ADDRGP4 memmove
CALLP4
pop
ADDRGP4 $328
JUMPV
LABELV $327
line 1504
;1504:		else memmove(str2, str1+1, strlen(str1+1)+1);
ADDRLP4 140
INDIRP4
CNSTI4 1
ADDP4
ARGP4
ADDRLP4 184
ADDRGP4 strlen
CALLI4
ASGNI4
ADDRLP4 144
INDIRP4
ARGP4
ADDRLP4 188
CNSTI4 1
ASGNI4
ADDRLP4 140
INDIRP4
ADDRLP4 188
INDIRI4
ADDP4
ARGP4
ADDRLP4 184
INDIRI4
ADDRLP4 188
INDIRI4
ADDI4
ARGI4
ADDRGP4 memmove
CALLP4
pop
LABELV $328
line 1505
;1505:	}
LABELV $325
line 1507
;1506:	//remove Mr prefix
;1507:	if ((name[0] == 'm' || name[0] == 'M') &&
ADDRLP4 176
ADDRLP4 5
INDIRI1
CVII4 1
ASGNI4
ADDRLP4 176
INDIRI4
CNSTI4 109
EQI4 $333
ADDRLP4 176
INDIRI4
CNSTI4 77
NEI4 $329
LABELV $333
ADDRLP4 5+1
INDIRI1
CVII4 1
CNSTI4 114
EQI4 $334
ADDRLP4 5+1
INDIRI1
CVII4 1
CNSTI4 82
NEI4 $329
LABELV $334
line 1508
;1508:			(name[1] == 'r' || name[1] == 'R')) {
line 1509
;1509:		memmove(name, name+2, strlen(name+2)+1);
ADDRLP4 5+2
ARGP4
ADDRLP4 180
ADDRGP4 strlen
CALLI4
ASGNI4
ADDRLP4 5
ARGP4
ADDRLP4 5+2
ARGP4
ADDRLP4 180
INDIRI4
CNSTI4 1
ADDI4
ARGI4
ADDRGP4 memmove
CALLP4
pop
line 1510
;1510:	}
LABELV $329
line 1512
;1511:	//only allow lower case alphabet characters
;1512:	ptr = name;
ADDRLP4 0
ADDRLP4 5
ASGNP4
ADDRGP4 $338
JUMPV
LABELV $337
line 1513
;1513:	while(*ptr) {
line 1514
;1514:		c = *ptr;
ADDRLP4 4
ADDRLP4 0
INDIRP4
INDIRI1
ASGNI1
line 1515
;1515:		if ((c >= 'a' && c <= 'z') ||
ADDRLP4 180
ADDRLP4 4
INDIRI1
CVII4 1
ASGNI4
ADDRLP4 180
INDIRI4
CNSTI4 97
LTI4 $343
ADDRLP4 180
INDIRI4
CNSTI4 122
LEI4 $344
LABELV $343
ADDRLP4 184
ADDRLP4 4
INDIRI1
CVII4 1
ASGNI4
ADDRLP4 184
INDIRI4
CNSTI4 48
LTI4 $345
ADDRLP4 184
INDIRI4
CNSTI4 57
LEI4 $344
LABELV $345
ADDRLP4 4
INDIRI1
CVII4 1
CNSTI4 95
NEI4 $340
LABELV $344
line 1516
;1516:				(c >= '0' && c <= '9') || c == '_') {
line 1517
;1517:			ptr++;
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 1
ADDP4
ASGNP4
line 1518
;1518:		}
ADDRGP4 $341
JUMPV
LABELV $340
line 1519
;1519:		else if (c >= 'A' && c <= 'Z') {
ADDRLP4 188
ADDRLP4 4
INDIRI1
CVII4 1
ASGNI4
ADDRLP4 188
INDIRI4
CNSTI4 65
LTI4 $346
ADDRLP4 188
INDIRI4
CNSTI4 90
GTI4 $346
line 1520
;1520:			*ptr += 'a' - 'A';
ADDRLP4 0
INDIRP4
ADDRLP4 0
INDIRP4
INDIRI1
CVII4 1
CNSTI4 32
ADDI4
CVII1 4
ASGNI1
line 1521
;1521:			ptr++;
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 1
ADDP4
ASGNP4
line 1522
;1522:		}
ADDRGP4 $347
JUMPV
LABELV $346
line 1523
;1523:		else {
line 1524
;1524:			memmove(ptr, ptr+1, strlen(ptr + 1)+1);
ADDRLP4 0
INDIRP4
CNSTI4 1
ADDP4
ARGP4
ADDRLP4 192
ADDRGP4 strlen
CALLI4
ASGNI4
ADDRLP4 0
INDIRP4
ARGP4
ADDRLP4 200
CNSTI4 1
ASGNI4
ADDRLP4 0
INDIRP4
ADDRLP4 200
INDIRI4
ADDP4
ARGP4
ADDRLP4 192
INDIRI4
ADDRLP4 200
INDIRI4
ADDI4
ARGI4
ADDRGP4 memmove
CALLP4
pop
line 1525
;1525:		}
LABELV $347
LABELV $341
line 1526
;1526:	}
LABELV $338
line 1513
ADDRLP4 0
INDIRP4
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $337
line 1527
;1527:	strncpy(buf, name, size-1);
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 5
ARGP4
ADDRFP4 8
INDIRI4
CNSTI4 1
SUBI4
ARGI4
ADDRGP4 strncpy
CALLP4
pop
line 1528
;1528:	buf[size-1] = '\0';
ADDRFP4 8
INDIRI4
CNSTI4 1
SUBI4
ADDRFP4 4
INDIRP4
ADDP4
CNSTI1 0
ASGNI1
line 1529
;1529:	return buf;
ADDRFP4 4
INDIRP4
RETP4
LABELV $313
endproc EasyClientName 204 12
export BotSynonymContext
proc BotSynonymContext 8 4
line 1537
;1530:}
;1531:
;1532:/*
;1533:==================
;1534:BotSynonymContext
;1535:==================
;1536:*/
;1537:int BotSynonymContext(bot_state_t *bs) {
line 1540
;1538:	int context;
;1539:
;1540:	context = CONTEXT_NORMAL|CONTEXT_NEARBYITEM|CONTEXT_NAMES;
ADDRLP4 0
CNSTI4 1027
ASGNI4
line 1542
;1541:	//
;1542:	if (gametype == GT_CTF
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $349
line 1546
;1543:#ifdef MISSIONPACK
;1544:		|| gametype == GT_1FCTF
;1545:#endif
;1546:		) {
line 1547
;1547:		if (BotTeam(bs) == TEAM_RED) context |= CONTEXT_CTFREDTEAM;
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 4
ADDRGP4 BotTeam
CALLI4
ASGNI4
ADDRLP4 4
INDIRI4
CNSTI4 1
NEI4 $351
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 4
BORI4
ASGNI4
ADDRGP4 $352
JUMPV
LABELV $351
line 1548
;1548:		else context |= CONTEXT_CTFBLUETEAM;
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 8
BORI4
ASGNI4
LABELV $352
line 1549
;1549:	}
LABELV $349
line 1560
;1550:#ifdef MISSIONPACK
;1551:	else if (gametype == GT_OBELISK) {
;1552:		if (BotTeam(bs) == TEAM_RED) context |= CONTEXT_OBELISKREDTEAM;
;1553:		else context |= CONTEXT_OBELISKBLUETEAM;
;1554:	}
;1555:	else if (gametype == GT_HARVESTER) {
;1556:		if (BotTeam(bs) == TEAM_RED) context |= CONTEXT_HARVESTERREDTEAM;
;1557:		else context |= CONTEXT_HARVESTERBLUETEAM;
;1558:	}
;1559:#endif
;1560:	return context;
ADDRLP4 0
INDIRI4
RETI4
LABELV $348
endproc BotSynonymContext 8 4
export BotChooseWeapon
proc BotChooseWeapon 20 8
line 1568
;1561:}
;1562:
;1563:/*
;1564:==================
;1565:BotChooseWeapon
;1566:==================
;1567:*/
;1568:void BotChooseWeapon(bot_state_t *bs) {
line 1571
;1569:	int newweaponnum;
;1570:
;1571:	if (bs->cur_ps.weaponstate == WEAPON_RAISING ||
ADDRLP4 4
ADDRFP4 0
INDIRP4
CNSTI4 164
ADDP4
INDIRI4
ASGNI4
ADDRLP4 4
INDIRI4
CNSTI4 1
EQI4 $356
ADDRLP4 4
INDIRI4
CNSTI4 2
NEI4 $354
LABELV $356
line 1572
;1572:			bs->cur_ps.weaponstate == WEAPON_DROPPING) {
line 1573
;1573:		trap_EA_SelectWeapon(bs->client, bs->weaponnum);
ADDRLP4 8
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 8
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 8
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_SelectWeapon
CALLV
pop
line 1574
;1574:	}
ADDRGP4 $355
JUMPV
LABELV $354
line 1575
;1575:	else {
line 1576
;1576:		newweaponnum = trap_BotChooseBestFightWeapon(bs->ws, bs->inventory);
ADDRLP4 8
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 8
INDIRP4
CNSTI4 6536
ADDP4
INDIRI4
ARGI4
ADDRLP4 8
INDIRP4
CNSTI4 4952
ADDP4
ARGP4
ADDRLP4 12
ADDRGP4 trap_BotChooseBestFightWeapon
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 12
INDIRI4
ASGNI4
line 1577
;1577:		if (bs->weaponnum != newweaponnum) bs->weaponchange_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
ADDRLP4 0
INDIRI4
EQI4 $357
ADDRFP4 0
INDIRP4
CNSTI4 6192
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
LABELV $357
line 1578
;1578:		bs->weaponnum = newweaponnum;
ADDRFP4 0
INDIRP4
CNSTI4 6560
ADDP4
ADDRLP4 0
INDIRI4
ASGNI4
line 1580
;1579:		//BotAI_Print(PRT_MESSAGE, "bs->weaponnum = %d\n", bs->weaponnum);
;1580:		trap_EA_SelectWeapon(bs->client, bs->weaponnum);
ADDRLP4 16
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 16
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 16
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_SelectWeapon
CALLV
pop
line 1581
;1581:	}
LABELV $355
line 1582
;1582:}
LABELV $353
endproc BotChooseWeapon 20 8
export BotSetupForMovement
proc BotSetupForMovement 88 12
line 1589
;1583:
;1584:/*
;1585:==================
;1586:BotSetupForMovement
;1587:==================
;1588:*/
;1589:void BotSetupForMovement(bot_state_t *bs) {
line 1592
;1590:	bot_initmove_t initmove;
;1591:
;1592:	memset(&initmove, 0, sizeof(bot_initmove_t));
ADDRLP4 0
ARGP4
CNSTI4 0
ARGI4
CNSTI4 68
ARGI4
ADDRGP4 memset
CALLP4
pop
line 1593
;1593:	VectorCopy(bs->cur_ps.origin, initmove.origin);
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 36
ADDP4
INDIRB
ASGNB 12
line 1594
;1594:	VectorCopy(bs->cur_ps.velocity, initmove.velocity);
ADDRLP4 0+12
ADDRFP4 0
INDIRP4
CNSTI4 48
ADDP4
INDIRB
ASGNB 12
line 1595
;1595:	VectorClear(initmove.viewoffset);
ADDRLP4 68
CNSTF4 0
ASGNF4
ADDRLP4 0+24+8
ADDRLP4 68
INDIRF4
ASGNF4
ADDRLP4 0+24+4
ADDRLP4 68
INDIRF4
ASGNF4
ADDRLP4 0+24
ADDRLP4 68
INDIRF4
ASGNF4
line 1596
;1596:	initmove.viewoffset[2] += bs->cur_ps.viewheight;
ADDRLP4 0+24+8
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 180
ADDP4
INDIRI4
CVIF4 4
ADDF4
ASGNF4
line 1597
;1597:	initmove.entitynum = bs->entitynum;
ADDRLP4 0+36
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ASGNI4
line 1598
;1598:	initmove.client = bs->client;
ADDRLP4 0+40
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 1599
;1599:	initmove.thinktime = bs->thinktime;
ADDRLP4 0+44
ADDRFP4 0
INDIRP4
CNSTI4 4904
ADDP4
INDIRF4
ASGNF4
line 1601
;1600:	//set the onground flag
;1601:	if (bs->cur_ps.groundEntityNum != ENTITYNUM_NONE) initmove.or_moveflags |= MFL_ONGROUND;
ADDRFP4 0
INDIRP4
CNSTI4 84
ADDP4
INDIRI4
CNSTI4 1023
EQI4 $371
ADDRLP4 0+64
ADDRLP4 0+64
INDIRI4
CNSTI4 2
BORI4
ASGNI4
LABELV $371
line 1603
;1602:	//set the teleported flag
;1603:	if ((bs->cur_ps.pm_flags & PMF_TIME_KNOCKBACK) && (bs->cur_ps.pm_time > 0)) {
ADDRLP4 72
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 76
CNSTI4 0
ASGNI4
ADDRLP4 72
INDIRP4
CNSTI4 28
ADDP4
INDIRI4
CNSTI4 64
BANDI4
ADDRLP4 76
INDIRI4
EQI4 $374
ADDRLP4 72
INDIRP4
CNSTI4 32
ADDP4
INDIRI4
ADDRLP4 76
INDIRI4
LEI4 $374
line 1604
;1604:		initmove.or_moveflags |= MFL_TELEPORTED;
ADDRLP4 0+64
ADDRLP4 0+64
INDIRI4
CNSTI4 32
BORI4
ASGNI4
line 1605
;1605:	}
LABELV $374
line 1607
;1606:	//set the waterjump flag
;1607:	if ((bs->cur_ps.pm_flags & PMF_TIME_WATERJUMP) && (bs->cur_ps.pm_time > 0)) {
ADDRLP4 80
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 84
CNSTI4 0
ASGNI4
ADDRLP4 80
INDIRP4
CNSTI4 28
ADDP4
INDIRI4
CNSTI4 256
BANDI4
ADDRLP4 84
INDIRI4
EQI4 $377
ADDRLP4 80
INDIRP4
CNSTI4 32
ADDP4
INDIRI4
ADDRLP4 84
INDIRI4
LEI4 $377
line 1608
;1608:		initmove.or_moveflags |= MFL_WATERJUMP;
ADDRLP4 0+64
ADDRLP4 0+64
INDIRI4
CNSTI4 16
BORI4
ASGNI4
line 1609
;1609:	}
LABELV $377
line 1611
;1610:	//set presence type
;1611:	if (bs->cur_ps.pm_flags & PMF_DUCKED) initmove.presencetype = PRESENCE_CROUCH;
ADDRFP4 0
INDIRP4
CNSTI4 28
ADDP4
INDIRI4
CNSTI4 1
BANDI4
CNSTI4 0
EQI4 $380
ADDRLP4 0+48
CNSTI4 4
ASGNI4
ADDRGP4 $381
JUMPV
LABELV $380
line 1612
;1612:	else initmove.presencetype = PRESENCE_NORMAL;
ADDRLP4 0+48
CNSTI4 2
ASGNI4
LABELV $381
line 1614
;1613:	//
;1614:	if (bs->walker > 0.5) initmove.or_moveflags |= MFL_WALK;
ADDRFP4 0
INDIRP4
CNSTI4 6056
ADDP4
INDIRF4
CNSTF4 1056964608
LEF4 $384
ADDRLP4 0+64
ADDRLP4 0+64
INDIRI4
CNSTI4 512
BORI4
ASGNI4
LABELV $384
line 1616
;1615:	//
;1616:	VectorCopy(bs->viewangles, initmove.viewangles);
ADDRLP4 0+52
ADDRFP4 0
INDIRP4
CNSTI4 6564
ADDP4
INDIRB
ASGNB 12
line 1618
;1617:	//
;1618:	trap_BotInitMoveState(bs->ms, &initmove);
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 trap_BotInitMoveState
CALLV
pop
line 1619
;1619:}
LABELV $359
endproc BotSetupForMovement 88 12
export BotCheckItemPickup
proc BotCheckItemPickup 0 0
line 1626
;1620:
;1621:/*
;1622:==================
;1623:BotCheckItemPickup
;1624:==================
;1625:*/
;1626:void BotCheckItemPickup(bot_state_t *bs, int *oldinventory) {
line 1713
;1627:#ifdef MISSIONPACK
;1628:	int offence, leader;
;1629:
;1630:	if (gametype <= GT_TEAM)
;1631:		return;
;1632:
;1633:	offence = -1;
;1634:	// go into offence if picked up the kamikaze or invulnerability
;1635:	if (!oldinventory[INVENTORY_KAMIKAZE] && bs->inventory[INVENTORY_KAMIKAZE] >= 1) {
;1636:		offence = qtrue;
;1637:	}
;1638:	if (!oldinventory[INVENTORY_INVULNERABILITY] && bs->inventory[INVENTORY_INVULNERABILITY] >= 1) {
;1639:		offence = qtrue;
;1640:	}
;1641:	// if not already wearing the kamikaze or invulnerability
;1642:	if (!bs->inventory[INVENTORY_KAMIKAZE] && !bs->inventory[INVENTORY_INVULNERABILITY]) {
;1643:		if (!oldinventory[INVENTORY_SCOUT] && bs->inventory[INVENTORY_SCOUT] >= 1) {
;1644:			offence = qtrue;
;1645:		}
;1646:		if (!oldinventory[INVENTORY_GUARD] && bs->inventory[INVENTORY_GUARD] >= 1) {
;1647:			offence = qtrue;
;1648:		}
;1649:		if (!oldinventory[INVENTORY_DOUBLER] && bs->inventory[INVENTORY_DOUBLER] >= 1) {
;1650:			offence = qfalse;
;1651:		}
;1652:		if (!oldinventory[INVENTORY_AMMOREGEN] && bs->inventory[INVENTORY_AMMOREGEN] >= 1) {
;1653:			offence = qfalse;
;1654:		}
;1655:	}
;1656:
;1657:	if (offence >= 0) {
;1658:		leader = ClientFromName(bs->teamleader);
;1659:		if (offence) {
;1660:			if (!(bs->teamtaskpreference & TEAMTP_ATTACKER)) {
;1661:				// if we have a bot team leader
;1662:				if (BotTeamLeader(bs)) {
;1663:					// tell the leader we want to be on offence
;1664:					BotVoiceChat(bs, leader, VOICECHAT_WANTONOFFENSE);
;1665:					//BotAI_BotInitialChat(bs, "wantoffence", NULL);
;1666:					//trap_BotEnterChat(bs->cs, leader, CHAT_TELL);
;1667:				}
;1668:				else if (g_spSkill.integer <= 3) {
;1669:					if ( bs->ltgtype != LTG_GETFLAG &&
;1670:						 bs->ltgtype != LTG_ATTACKENEMYBASE &&
;1671:						 bs->ltgtype != LTG_HARVEST ) {
;1672:						//
;1673:						if ((gametype != GT_CTF || (bs->redflagstatus == 0 && bs->blueflagstatus == 0)) &&
;1674:							(gametype != GT_1FCTF || bs->neutralflagstatus == 0) ) {
;1675:							// tell the leader we want to be on offence
;1676:							BotVoiceChat(bs, leader, VOICECHAT_WANTONOFFENSE);
;1677:							//BotAI_BotInitialChat(bs, "wantoffence", NULL);
;1678:							//trap_BotEnterChat(bs->cs, leader, CHAT_TELL);
;1679:						}
;1680:					}
;1681:					bs->teamtaskpreference |= TEAMTP_ATTACKER;
;1682:				}
;1683:			}
;1684:			bs->teamtaskpreference &= ~TEAMTP_DEFENDER;
;1685:		}
;1686:		else {
;1687:			if (!(bs->teamtaskpreference & TEAMTP_DEFENDER)) {
;1688:				// if we have a bot team leader
;1689:				if (BotTeamLeader(bs)) {
;1690:					// tell the leader we want to be on defense
;1691:					BotVoiceChat(bs, -1, VOICECHAT_WANTONDEFENSE);
;1692:					//BotAI_BotInitialChat(bs, "wantdefence", NULL);
;1693:					//trap_BotEnterChat(bs->cs, leader, CHAT_TELL);
;1694:				}
;1695:				else if (g_spSkill.integer <= 3) {
;1696:					if ( bs->ltgtype != LTG_DEFENDKEYAREA ) {
;1697:						//
;1698:						if ((gametype != GT_CTF || (bs->redflagstatus == 0 && bs->blueflagstatus == 0)) &&
;1699:							(gametype != GT_1FCTF || bs->neutralflagstatus == 0) ) {
;1700:							// tell the leader we want to be on defense
;1701:							BotVoiceChat(bs, -1, VOICECHAT_WANTONDEFENSE);
;1702:							//BotAI_BotInitialChat(bs, "wantdefence", NULL);
;1703:							//trap_BotEnterChat(bs->cs, leader, CHAT_TELL);
;1704:						}
;1705:					}
;1706:				}
;1707:				bs->teamtaskpreference |= TEAMTP_DEFENDER;
;1708:			}
;1709:			bs->teamtaskpreference &= ~TEAMTP_ATTACKER;
;1710:		}
;1711:	}
;1712:#endif
;1713:}
LABELV $388
endproc BotCheckItemPickup 0 0
export BotUpdateInventory
proc BotUpdateInventory 1224 12
line 1720
;1714:
;1715:/*
;1716:==================
;1717:BotUpdateInventory
;1718:==================
;1719:*/
;1720:void BotUpdateInventory(bot_state_t *bs) {
line 1723
;1721:	int oldinventory[MAX_ITEMS];
;1722:
;1723:	memcpy(oldinventory, bs->inventory, sizeof(oldinventory));
ADDRLP4 0
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 4952
ADDP4
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 1725
;1724:	//armor
;1725:	bs->inventory[INVENTORY_ARMOR] = bs->cur_ps.stats[STAT_ARMOR];
ADDRLP4 1024
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1024
INDIRP4
CNSTI4 4956
ADDP4
ADDRLP4 1024
INDIRP4
CNSTI4 212
ADDP4
INDIRI4
ASGNI4
line 1727
;1726:	//weapons
;1727:	bs->inventory[INVENTORY_GAUNTLET] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_GAUNTLET)) != 0;
ADDRLP4 1032
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1032
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $391
ADDRLP4 1028
CNSTI4 1
ASGNI4
ADDRGP4 $392
JUMPV
LABELV $391
ADDRLP4 1028
CNSTI4 0
ASGNI4
LABELV $392
ADDRLP4 1032
INDIRP4
CNSTI4 4968
ADDP4
ADDRLP4 1028
INDIRI4
ASGNI4
line 1728
;1728:	bs->inventory[INVENTORY_SHOTGUN] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_SHOTGUN)) != 0;
ADDRLP4 1040
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1040
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 8
BANDI4
CNSTI4 0
EQI4 $394
ADDRLP4 1036
CNSTI4 1
ASGNI4
ADDRGP4 $395
JUMPV
LABELV $394
ADDRLP4 1036
CNSTI4 0
ASGNI4
LABELV $395
ADDRLP4 1040
INDIRP4
CNSTI4 4972
ADDP4
ADDRLP4 1036
INDIRI4
ASGNI4
line 1729
;1729:	bs->inventory[INVENTORY_MACHINEGUN] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_MACHINEGUN)) != 0;
ADDRLP4 1048
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1048
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 4
BANDI4
CNSTI4 0
EQI4 $397
ADDRLP4 1044
CNSTI4 1
ASGNI4
ADDRGP4 $398
JUMPV
LABELV $397
ADDRLP4 1044
CNSTI4 0
ASGNI4
LABELV $398
ADDRLP4 1048
INDIRP4
CNSTI4 4976
ADDP4
ADDRLP4 1044
INDIRI4
ASGNI4
line 1730
;1730:	bs->inventory[INVENTORY_GRENADELAUNCHER] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_GRENADE_LAUNCHER)) != 0;
ADDRLP4 1056
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1056
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 16
BANDI4
CNSTI4 0
EQI4 $400
ADDRLP4 1052
CNSTI4 1
ASGNI4
ADDRGP4 $401
JUMPV
LABELV $400
ADDRLP4 1052
CNSTI4 0
ASGNI4
LABELV $401
ADDRLP4 1056
INDIRP4
CNSTI4 4980
ADDP4
ADDRLP4 1052
INDIRI4
ASGNI4
line 1731
;1731:	bs->inventory[INVENTORY_ROCKETLAUNCHER] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_ROCKET_LAUNCHER)) != 0;
ADDRLP4 1064
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1064
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 32
BANDI4
CNSTI4 0
EQI4 $403
ADDRLP4 1060
CNSTI4 1
ASGNI4
ADDRGP4 $404
JUMPV
LABELV $403
ADDRLP4 1060
CNSTI4 0
ASGNI4
LABELV $404
ADDRLP4 1064
INDIRP4
CNSTI4 4984
ADDP4
ADDRLP4 1060
INDIRI4
ASGNI4
line 1732
;1732:	bs->inventory[INVENTORY_LIGHTNING] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_LIGHTNING)) != 0;
ADDRLP4 1072
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1072
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 64
BANDI4
CNSTI4 0
EQI4 $406
ADDRLP4 1068
CNSTI4 1
ASGNI4
ADDRGP4 $407
JUMPV
LABELV $406
ADDRLP4 1068
CNSTI4 0
ASGNI4
LABELV $407
ADDRLP4 1072
INDIRP4
CNSTI4 4988
ADDP4
ADDRLP4 1068
INDIRI4
ASGNI4
line 1733
;1733:	bs->inventory[INVENTORY_RAILGUN] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_RAILGUN)) != 0;
ADDRLP4 1080
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1080
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 128
BANDI4
CNSTI4 0
EQI4 $409
ADDRLP4 1076
CNSTI4 1
ASGNI4
ADDRGP4 $410
JUMPV
LABELV $409
ADDRLP4 1076
CNSTI4 0
ASGNI4
LABELV $410
ADDRLP4 1080
INDIRP4
CNSTI4 4992
ADDP4
ADDRLP4 1076
INDIRI4
ASGNI4
line 1734
;1734:	bs->inventory[INVENTORY_PLASMAGUN] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_PLASMAGUN)) != 0;
ADDRLP4 1088
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1088
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 256
BANDI4
CNSTI4 0
EQI4 $412
ADDRLP4 1084
CNSTI4 1
ASGNI4
ADDRGP4 $413
JUMPV
LABELV $412
ADDRLP4 1084
CNSTI4 0
ASGNI4
LABELV $413
ADDRLP4 1088
INDIRP4
CNSTI4 4996
ADDP4
ADDRLP4 1084
INDIRI4
ASGNI4
line 1735
;1735:	bs->inventory[INVENTORY_BFG10K] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_BFG)) != 0;
ADDRLP4 1096
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1096
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 512
BANDI4
CNSTI4 0
EQI4 $415
ADDRLP4 1092
CNSTI4 1
ASGNI4
ADDRGP4 $416
JUMPV
LABELV $415
ADDRLP4 1092
CNSTI4 0
ASGNI4
LABELV $416
ADDRLP4 1096
INDIRP4
CNSTI4 5004
ADDP4
ADDRLP4 1092
INDIRI4
ASGNI4
line 1736
;1736:	bs->inventory[INVENTORY_GRAPPLINGHOOK] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_GRAPPLING_HOOK)) != 0;
ADDRLP4 1104
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1104
INDIRP4
CNSTI4 208
ADDP4
INDIRI4
CNSTI4 1024
BANDI4
CNSTI4 0
EQI4 $418
ADDRLP4 1100
CNSTI4 1
ASGNI4
ADDRGP4 $419
JUMPV
LABELV $418
ADDRLP4 1100
CNSTI4 0
ASGNI4
LABELV $419
ADDRLP4 1104
INDIRP4
CNSTI4 5008
ADDP4
ADDRLP4 1100
INDIRI4
ASGNI4
line 1743
;1737:#ifdef MISSIONPACK
;1738:	bs->inventory[INVENTORY_NAILGUN] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_NAILGUN)) != 0;;
;1739:	bs->inventory[INVENTORY_PROXLAUNCHER] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_PROX_LAUNCHER)) != 0;;
;1740:	bs->inventory[INVENTORY_CHAINGUN] = (bs->cur_ps.stats[STAT_WEAPONS] & (1 << WP_CHAINGUN)) != 0;;
;1741:#endif
;1742:	//ammo
;1743:	bs->inventory[INVENTORY_SHELLS] = bs->cur_ps.ammo[WP_SHOTGUN];
ADDRLP4 1108
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1108
INDIRP4
CNSTI4 5024
ADDP4
ADDRLP4 1108
INDIRP4
CNSTI4 404
ADDP4
INDIRI4
ASGNI4
line 1744
;1744:	bs->inventory[INVENTORY_BULLETS] = bs->cur_ps.ammo[WP_MACHINEGUN];
ADDRLP4 1112
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1112
INDIRP4
CNSTI4 5028
ADDP4
ADDRLP4 1112
INDIRP4
CNSTI4 400
ADDP4
INDIRI4
ASGNI4
line 1745
;1745:	bs->inventory[INVENTORY_GRENADES] = bs->cur_ps.ammo[WP_GRENADE_LAUNCHER];
ADDRLP4 1116
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1116
INDIRP4
CNSTI4 5032
ADDP4
ADDRLP4 1116
INDIRP4
CNSTI4 408
ADDP4
INDIRI4
ASGNI4
line 1746
;1746:	bs->inventory[INVENTORY_CELLS] = bs->cur_ps.ammo[WP_PLASMAGUN];
ADDRLP4 1120
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1120
INDIRP4
CNSTI4 5036
ADDP4
ADDRLP4 1120
INDIRP4
CNSTI4 424
ADDP4
INDIRI4
ASGNI4
line 1747
;1747:	bs->inventory[INVENTORY_LIGHTNINGAMMO] = bs->cur_ps.ammo[WP_LIGHTNING];
ADDRLP4 1124
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1124
INDIRP4
CNSTI4 5040
ADDP4
ADDRLP4 1124
INDIRP4
CNSTI4 416
ADDP4
INDIRI4
ASGNI4
line 1748
;1748:	bs->inventory[INVENTORY_ROCKETS] = bs->cur_ps.ammo[WP_ROCKET_LAUNCHER];
ADDRLP4 1128
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1128
INDIRP4
CNSTI4 5044
ADDP4
ADDRLP4 1128
INDIRP4
CNSTI4 412
ADDP4
INDIRI4
ASGNI4
line 1749
;1749:	bs->inventory[INVENTORY_SLUGS] = bs->cur_ps.ammo[WP_RAILGUN];
ADDRLP4 1132
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1132
INDIRP4
CNSTI4 5048
ADDP4
ADDRLP4 1132
INDIRP4
CNSTI4 420
ADDP4
INDIRI4
ASGNI4
line 1750
;1750:	bs->inventory[INVENTORY_BFGAMMO] = bs->cur_ps.ammo[WP_BFG];
ADDRLP4 1136
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1136
INDIRP4
CNSTI4 5052
ADDP4
ADDRLP4 1136
INDIRP4
CNSTI4 428
ADDP4
INDIRI4
ASGNI4
line 1757
;1751:#ifdef MISSIONPACK
;1752:	bs->inventory[INVENTORY_NAILS] = bs->cur_ps.ammo[WP_NAILGUN];
;1753:	bs->inventory[INVENTORY_MINES] = bs->cur_ps.ammo[WP_PROX_LAUNCHER];
;1754:	bs->inventory[INVENTORY_BELT] = bs->cur_ps.ammo[WP_CHAINGUN];
;1755:#endif
;1756:	//powerups
;1757:	bs->inventory[INVENTORY_HEALTH] = bs->cur_ps.stats[STAT_HEALTH];
ADDRLP4 1140
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1140
INDIRP4
CNSTI4 5068
ADDP4
ADDRLP4 1140
INDIRP4
CNSTI4 200
ADDP4
INDIRI4
ASGNI4
line 1758
;1758:	bs->inventory[INVENTORY_TELEPORTER] = bs->cur_ps.stats[STAT_HOLDABLE_ITEM] == MODELINDEX_TELEPORTER;
ADDRLP4 1148
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1148
INDIRP4
CNSTI4 204
ADDP4
INDIRI4
CNSTI4 26
NEI4 $421
ADDRLP4 1144
CNSTI4 1
ASGNI4
ADDRGP4 $422
JUMPV
LABELV $421
ADDRLP4 1144
CNSTI4 0
ASGNI4
LABELV $422
ADDRLP4 1148
INDIRP4
CNSTI4 5072
ADDP4
ADDRLP4 1144
INDIRI4
ASGNI4
line 1759
;1759:	bs->inventory[INVENTORY_MEDKIT] = bs->cur_ps.stats[STAT_HOLDABLE_ITEM] == MODELINDEX_MEDKIT;
ADDRLP4 1156
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1156
INDIRP4
CNSTI4 204
ADDP4
INDIRI4
CNSTI4 27
NEI4 $424
ADDRLP4 1152
CNSTI4 1
ASGNI4
ADDRGP4 $425
JUMPV
LABELV $424
ADDRLP4 1152
CNSTI4 0
ASGNI4
LABELV $425
ADDRLP4 1156
INDIRP4
CNSTI4 5076
ADDP4
ADDRLP4 1152
INDIRI4
ASGNI4
line 1765
;1760:#ifdef MISSIONPACK
;1761:	bs->inventory[INVENTORY_KAMIKAZE] = bs->cur_ps.stats[STAT_HOLDABLE_ITEM] == MODELINDEX_KAMIKAZE;
;1762:	bs->inventory[INVENTORY_PORTAL] = bs->cur_ps.stats[STAT_HOLDABLE_ITEM] == MODELINDEX_PORTAL;
;1763:	bs->inventory[INVENTORY_INVULNERABILITY] = bs->cur_ps.stats[STAT_HOLDABLE_ITEM] == MODELINDEX_INVULNERABILITY;
;1764:#endif
;1765:	bs->inventory[INVENTORY_QUAD] = bs->cur_ps.powerups[PW_QUAD] != 0;
ADDRLP4 1164
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1164
INDIRP4
CNSTI4 332
ADDP4
INDIRI4
CNSTI4 0
EQI4 $427
ADDRLP4 1160
CNSTI4 1
ASGNI4
ADDRGP4 $428
JUMPV
LABELV $427
ADDRLP4 1160
CNSTI4 0
ASGNI4
LABELV $428
ADDRLP4 1164
INDIRP4
CNSTI4 5092
ADDP4
ADDRLP4 1160
INDIRI4
ASGNI4
line 1766
;1766:	bs->inventory[INVENTORY_ENVIRONMENTSUIT] = bs->cur_ps.powerups[PW_BATTLESUIT] != 0;
ADDRLP4 1172
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1172
INDIRP4
CNSTI4 336
ADDP4
INDIRI4
CNSTI4 0
EQI4 $430
ADDRLP4 1168
CNSTI4 1
ASGNI4
ADDRGP4 $431
JUMPV
LABELV $430
ADDRLP4 1168
CNSTI4 0
ASGNI4
LABELV $431
ADDRLP4 1172
INDIRP4
CNSTI4 5096
ADDP4
ADDRLP4 1168
INDIRI4
ASGNI4
line 1767
;1767:	bs->inventory[INVENTORY_HASTE] = bs->cur_ps.powerups[PW_HASTE] != 0;
ADDRLP4 1180
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1180
INDIRP4
CNSTI4 340
ADDP4
INDIRI4
CNSTI4 0
EQI4 $433
ADDRLP4 1176
CNSTI4 1
ASGNI4
ADDRGP4 $434
JUMPV
LABELV $433
ADDRLP4 1176
CNSTI4 0
ASGNI4
LABELV $434
ADDRLP4 1180
INDIRP4
CNSTI4 5100
ADDP4
ADDRLP4 1176
INDIRI4
ASGNI4
line 1768
;1768:	bs->inventory[INVENTORY_INVISIBILITY] = bs->cur_ps.powerups[PW_INVIS] != 0;
ADDRLP4 1188
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1188
INDIRP4
CNSTI4 344
ADDP4
INDIRI4
CNSTI4 0
EQI4 $436
ADDRLP4 1184
CNSTI4 1
ASGNI4
ADDRGP4 $437
JUMPV
LABELV $436
ADDRLP4 1184
CNSTI4 0
ASGNI4
LABELV $437
ADDRLP4 1188
INDIRP4
CNSTI4 5104
ADDP4
ADDRLP4 1184
INDIRI4
ASGNI4
line 1769
;1769:	bs->inventory[INVENTORY_REGEN] = bs->cur_ps.powerups[PW_REGEN] != 0;
ADDRLP4 1196
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1196
INDIRP4
CNSTI4 348
ADDP4
INDIRI4
CNSTI4 0
EQI4 $439
ADDRLP4 1192
CNSTI4 1
ASGNI4
ADDRGP4 $440
JUMPV
LABELV $439
ADDRLP4 1192
CNSTI4 0
ASGNI4
LABELV $440
ADDRLP4 1196
INDIRP4
CNSTI4 5108
ADDP4
ADDRLP4 1192
INDIRI4
ASGNI4
line 1770
;1770:	bs->inventory[INVENTORY_FLIGHT] = bs->cur_ps.powerups[PW_FLIGHT] != 0;
ADDRLP4 1204
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1204
INDIRP4
CNSTI4 352
ADDP4
INDIRI4
CNSTI4 0
EQI4 $442
ADDRLP4 1200
CNSTI4 1
ASGNI4
ADDRGP4 $443
JUMPV
LABELV $442
ADDRLP4 1200
CNSTI4 0
ASGNI4
LABELV $443
ADDRLP4 1204
INDIRP4
CNSTI4 5112
ADDP4
ADDRLP4 1200
INDIRI4
ASGNI4
line 1777
;1771:#ifdef MISSIONPACK
;1772:	bs->inventory[INVENTORY_SCOUT] = bs->cur_ps.stats[STAT_PERSISTANT_POWERUP] == MODELINDEX_SCOUT;
;1773:	bs->inventory[INVENTORY_GUARD] = bs->cur_ps.stats[STAT_PERSISTANT_POWERUP] == MODELINDEX_GUARD;
;1774:	bs->inventory[INVENTORY_DOUBLER] = bs->cur_ps.stats[STAT_PERSISTANT_POWERUP] == MODELINDEX_DOUBLER;
;1775:	bs->inventory[INVENTORY_AMMOREGEN] = bs->cur_ps.stats[STAT_PERSISTANT_POWERUP] == MODELINDEX_AMMOREGEN;
;1776:#endif
;1777:	bs->inventory[INVENTORY_REDFLAG] = bs->cur_ps.powerups[PW_REDFLAG] != 0;
ADDRLP4 1212
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1212
INDIRP4
CNSTI4 356
ADDP4
INDIRI4
CNSTI4 0
EQI4 $445
ADDRLP4 1208
CNSTI4 1
ASGNI4
ADDRGP4 $446
JUMPV
LABELV $445
ADDRLP4 1208
CNSTI4 0
ASGNI4
LABELV $446
ADDRLP4 1212
INDIRP4
CNSTI4 5132
ADDP4
ADDRLP4 1208
INDIRI4
ASGNI4
line 1778
;1778:	bs->inventory[INVENTORY_BLUEFLAG] = bs->cur_ps.powerups[PW_BLUEFLAG] != 0;
ADDRLP4 1220
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1220
INDIRP4
CNSTI4 360
ADDP4
INDIRI4
CNSTI4 0
EQI4 $448
ADDRLP4 1216
CNSTI4 1
ASGNI4
ADDRGP4 $449
JUMPV
LABELV $448
ADDRLP4 1216
CNSTI4 0
ASGNI4
LABELV $449
ADDRLP4 1220
INDIRP4
CNSTI4 5136
ADDP4
ADDRLP4 1216
INDIRI4
ASGNI4
line 1790
;1779:#ifdef MISSIONPACK
;1780:	bs->inventory[INVENTORY_NEUTRALFLAG] = bs->cur_ps.powerups[PW_NEUTRALFLAG] != 0;
;1781:	if (BotTeam(bs) == TEAM_RED) {
;1782:		bs->inventory[INVENTORY_REDCUBE] = bs->cur_ps.generic1;
;1783:		bs->inventory[INVENTORY_BLUECUBE] = 0;
;1784:	}
;1785:	else {
;1786:		bs->inventory[INVENTORY_REDCUBE] = 0;
;1787:		bs->inventory[INVENTORY_BLUECUBE] = bs->cur_ps.generic1;
;1788:	}
;1789:#endif
;1790:	BotCheckItemPickup(bs, oldinventory);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ARGP4
ADDRGP4 BotCheckItemPickup
CALLV
pop
line 1791
;1791:}
LABELV $389
endproc BotUpdateInventory 1224 12
export BotUpdateBattleInventory
proc BotUpdateBattleInventory 160 8
line 1798
;1792:
;1793:/*
;1794:==================
;1795:BotUpdateBattleInventory
;1796:==================
;1797:*/
;1798:void BotUpdateBattleInventory(bot_state_t *bs, int enemy) {
line 1802
;1799:	vec3_t dir;
;1800:	aas_entityinfo_t entinfo;
;1801:
;1802:	BotEntityInfo(enemy, &entinfo);
ADDRFP4 4
INDIRI4
ARGI4
ADDRLP4 12
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 1803
;1803:	VectorSubtract(entinfo.origin, bs->origin, dir);
ADDRLP4 152
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
ADDRLP4 12+24
INDIRF4
ADDRLP4 152
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 12+24+4
INDIRF4
ADDRLP4 152
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 12+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 1804
;1804:	bs->inventory[ENEMY_HEIGHT] = (int) dir[2];
ADDRFP4 0
INDIRP4
CNSTI4 5756
ADDP4
ADDRLP4 0+8
INDIRF4
CVFI4 4
ASGNI4
line 1805
;1805:	dir[2] = 0;
ADDRLP4 0+8
CNSTF4 0
ASGNF4
line 1806
;1806:	bs->inventory[ENEMY_HORIZONTAL_DIST] = (int) VectorLength(dir);
ADDRLP4 0
ARGP4
ADDRLP4 156
ADDRGP4 VectorLength
CALLF4
ASGNF4
ADDRFP4 0
INDIRP4
CNSTI4 5752
ADDP4
ADDRLP4 156
INDIRF4
CVFI4 4
ASGNI4
line 1808
;1807:	//FIXME: add num visible enemies and num visible team mates to the inventory
;1808:}
LABELV $450
endproc BotUpdateBattleInventory 160 8
export BotBattleUseItems
proc BotBattleUseItems 4 4
line 2035
;1809:
;1810:#ifdef MISSIONPACK
;1811:/*
;1812:==================
;1813:BotUseKamikaze
;1814:==================
;1815:*/
;1816:#define KAMIKAZE_DIST		1024
;1817:
;1818:void BotUseKamikaze(bot_state_t *bs) {
;1819:	int c, teammates, enemies;
;1820:	aas_entityinfo_t entinfo;
;1821:	vec3_t dir, target;
;1822:	bot_goal_t *goal;
;1823:	bsp_trace_t trace;
;1824:
;1825:	//if the bot has no kamikaze
;1826:	if (bs->inventory[INVENTORY_KAMIKAZE] <= 0)
;1827:		return;
;1828:	if (bs->kamikaze_time > FloatTime())
;1829:		return;
;1830:	bs->kamikaze_time = FloatTime() + 0.2;
;1831:	if (gametype == GT_CTF) {
;1832:		//never use kamikaze if the team flag carrier is visible
;1833:		if (BotCTFCarryingFlag(bs))
;1834:			return;
;1835:		c = BotTeamFlagCarrierVisible(bs);
;1836:		if (c >= 0) {
;1837:			BotEntityInfo(c, &entinfo);
;1838:			VectorSubtract(entinfo.origin, bs->origin, dir);
;1839:			if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST))
;1840:				return;
;1841:		}
;1842:		c = BotEnemyFlagCarrierVisible(bs);
;1843:		if (c >= 0) {
;1844:			BotEntityInfo(c, &entinfo);
;1845:			VectorSubtract(entinfo.origin, bs->origin, dir);
;1846:			if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST)) {
;1847:				trap_EA_Use(bs->client);
;1848:				return;
;1849:			}
;1850:		}
;1851:	}
;1852:	else if (gametype == GT_1FCTF) {
;1853:		//never use kamikaze if the team flag carrier is visible
;1854:		if (Bot1FCTFCarryingFlag(bs))
;1855:			return;
;1856:		c = BotTeamFlagCarrierVisible(bs);
;1857:		if (c >= 0) {
;1858:			BotEntityInfo(c, &entinfo);
;1859:			VectorSubtract(entinfo.origin, bs->origin, dir);
;1860:			if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST))
;1861:				return;
;1862:		}
;1863:		c = BotEnemyFlagCarrierVisible(bs);
;1864:		if (c >= 0) {
;1865:			BotEntityInfo(c, &entinfo);
;1866:			VectorSubtract(entinfo.origin, bs->origin, dir);
;1867:			if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST)) {
;1868:				trap_EA_Use(bs->client);
;1869:				return;
;1870:			}
;1871:		}
;1872:	}
;1873:	else if (gametype == GT_OBELISK) {
;1874:		switch(BotTeam(bs)) {
;1875:			case TEAM_RED: goal = &blueobelisk; break;
;1876:			default: goal = &redobelisk; break;
;1877:		}
;1878:		//if the obelisk is visible
;1879:		VectorCopy(goal->origin, target);
;1880:		target[2] += 1;
;1881:		VectorSubtract(bs->origin, target, dir);
;1882:		if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST * 0.9)) {
;1883:			BotAI_Trace(&trace, bs->eye, NULL, NULL, target, bs->client, CONTENTS_SOLID);
;1884:			if (trace.fraction >= 1 || trace.ent == goal->entitynum) {
;1885:				trap_EA_Use(bs->client);
;1886:				return;
;1887:			}
;1888:		}
;1889:	}
;1890:	else if (gametype == GT_HARVESTER) {
;1891:		//
;1892:		if (BotHarvesterCarryingCubes(bs))
;1893:			return;
;1894:		//never use kamikaze if a team mate carrying cubes is visible
;1895:		c = BotTeamCubeCarrierVisible(bs);
;1896:		if (c >= 0) {
;1897:			BotEntityInfo(c, &entinfo);
;1898:			VectorSubtract(entinfo.origin, bs->origin, dir);
;1899:			if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST))
;1900:				return;
;1901:		}
;1902:		c = BotEnemyCubeCarrierVisible(bs);
;1903:		if (c >= 0) {
;1904:			BotEntityInfo(c, &entinfo);
;1905:			VectorSubtract(entinfo.origin, bs->origin, dir);
;1906:			if (VectorLengthSquared(dir) < Square(KAMIKAZE_DIST)) {
;1907:				trap_EA_Use(bs->client);
;1908:				return;
;1909:			}
;1910:		}
;1911:	}
;1912:	//
;1913:	BotVisibleTeamMatesAndEnemies(bs, &teammates, &enemies, KAMIKAZE_DIST);
;1914:	//
;1915:	if (enemies > 2 && enemies > teammates+1) {
;1916:		trap_EA_Use(bs->client);
;1917:		return;
;1918:	}
;1919:}
;1920:
;1921:/*
;1922:==================
;1923:BotUseInvulnerability
;1924:==================
;1925:*/
;1926:void BotUseInvulnerability(bot_state_t *bs) {
;1927:	int c;
;1928:	vec3_t dir, target;
;1929:	bot_goal_t *goal;
;1930:	bsp_trace_t trace;
;1931:
;1932:	//if the bot has no invulnerability
;1933:	if (bs->inventory[INVENTORY_INVULNERABILITY] <= 0)
;1934:		return;
;1935:	if (bs->invulnerability_time > FloatTime())
;1936:		return;
;1937:	bs->invulnerability_time = FloatTime() + 0.2;
;1938:	if (gametype == GT_CTF) {
;1939:		//never use kamikaze if the team flag carrier is visible
;1940:		if (BotCTFCarryingFlag(bs))
;1941:			return;
;1942:		c = BotEnemyFlagCarrierVisible(bs);
;1943:		if (c >= 0)
;1944:			return;
;1945:		//if near enemy flag and the flag is visible
;1946:		switch(BotTeam(bs)) {
;1947:			case TEAM_RED: goal = &ctf_blueflag; break;
;1948:			default: goal = &ctf_redflag; break;
;1949:		}
;1950:		//if the obelisk is visible
;1951:		VectorCopy(goal->origin, target);
;1952:		target[2] += 1;
;1953:		VectorSubtract(bs->origin, target, dir);
;1954:		if (VectorLengthSquared(dir) < Square(200)) {
;1955:			BotAI_Trace(&trace, bs->eye, NULL, NULL, target, bs->client, CONTENTS_SOLID);
;1956:			if (trace.fraction >= 1 || trace.ent == goal->entitynum) {
;1957:				trap_EA_Use(bs->client);
;1958:				return;
;1959:			}
;1960:		}
;1961:	}
;1962:	else if (gametype == GT_1FCTF) {
;1963:		//never use kamikaze if the team flag carrier is visible
;1964:		if (Bot1FCTFCarryingFlag(bs))
;1965:			return;
;1966:		c = BotEnemyFlagCarrierVisible(bs);
;1967:		if (c >= 0)
;1968:			return;
;1969:		//if near enemy flag and the flag is visible
;1970:		switch(BotTeam(bs)) {
;1971:			case TEAM_RED: goal = &ctf_blueflag; break;
;1972:			default: goal = &ctf_redflag; break;
;1973:		}
;1974:		//if the obelisk is visible
;1975:		VectorCopy(goal->origin, target);
;1976:		target[2] += 1;
;1977:		VectorSubtract(bs->origin, target, dir);
;1978:		if (VectorLengthSquared(dir) < Square(200)) {
;1979:			BotAI_Trace(&trace, bs->eye, NULL, NULL, target, bs->client, CONTENTS_SOLID);
;1980:			if (trace.fraction >= 1 || trace.ent == goal->entitynum) {
;1981:				trap_EA_Use(bs->client);
;1982:				return;
;1983:			}
;1984:		}
;1985:	}
;1986:	else if (gametype == GT_OBELISK) {
;1987:		switch(BotTeam(bs)) {
;1988:			case TEAM_RED: goal = &blueobelisk; break;
;1989:			default: goal = &redobelisk; break;
;1990:		}
;1991:		//if the obelisk is visible
;1992:		VectorCopy(goal->origin, target);
;1993:		target[2] += 1;
;1994:		VectorSubtract(bs->origin, target, dir);
;1995:		if (VectorLengthSquared(dir) < Square(300)) {
;1996:			BotAI_Trace(&trace, bs->eye, NULL, NULL, target, bs->client, CONTENTS_SOLID);
;1997:			if (trace.fraction >= 1 || trace.ent == goal->entitynum) {
;1998:				trap_EA_Use(bs->client);
;1999:				return;
;2000:			}
;2001:		}
;2002:	}
;2003:	else if (gametype == GT_HARVESTER) {
;2004:		//
;2005:		if (BotHarvesterCarryingCubes(bs))
;2006:			return;
;2007:		c = BotEnemyCubeCarrierVisible(bs);
;2008:		if (c >= 0)
;2009:			return;
;2010:		//if near enemy base and enemy base is visible
;2011:		switch(BotTeam(bs)) {
;2012:			case TEAM_RED: goal = &blueobelisk; break;
;2013:			default: goal = &redobelisk; break;
;2014:		}
;2015:		//if the obelisk is visible
;2016:		VectorCopy(goal->origin, target);
;2017:		target[2] += 1;
;2018:		VectorSubtract(bs->origin, target, dir);
;2019:		if (VectorLengthSquared(dir) < Square(200)) {
;2020:			BotAI_Trace(&trace, bs->eye, NULL, NULL, target, bs->client, CONTENTS_SOLID);
;2021:			if (trace.fraction >= 1 || trace.ent == goal->entitynum) {
;2022:				trap_EA_Use(bs->client);
;2023:				return;
;2024:			}
;2025:		}
;2026:	}
;2027:}
;2028:#endif
;2029:
;2030:/*
;2031:==================
;2032:BotBattleUseItems
;2033:==================
;2034:*/
;2035:void BotBattleUseItems(bot_state_t *bs) {
line 2036
;2036:	if (bs->inventory[INVENTORY_HEALTH] < 40) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 40
GEI4 $461
line 2037
;2037:		if (bs->inventory[INVENTORY_TELEPORTER] > 0) {
ADDRFP4 0
INDIRP4
CNSTI4 5072
ADDP4
INDIRI4
CNSTI4 0
LEI4 $463
line 2038
;2038:			if (!BotCTFCarryingFlag(bs)
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ADDRGP4 BotCTFCarryingFlag
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $465
line 2043
;2039:#ifdef MISSIONPACK
;2040:				&& !Bot1FCTFCarryingFlag(bs)
;2041:				&& !BotHarvesterCarryingCubes(bs)
;2042:#endif
;2043:				) {
line 2044
;2044:				trap_EA_Use(bs->client);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_Use
CALLV
pop
line 2045
;2045:			}
LABELV $465
line 2046
;2046:		}
LABELV $463
line 2047
;2047:	}
LABELV $461
line 2048
;2048:	if (bs->inventory[INVENTORY_HEALTH] < 60) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 60
GEI4 $467
line 2049
;2049:		if (bs->inventory[INVENTORY_MEDKIT] > 0) {
ADDRFP4 0
INDIRP4
CNSTI4 5076
ADDP4
INDIRI4
CNSTI4 0
LEI4 $469
line 2050
;2050:			trap_EA_Use(bs->client);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_Use
CALLV
pop
line 2051
;2051:		}
LABELV $469
line 2052
;2052:	}
LABELV $467
line 2057
;2053:#ifdef MISSIONPACK
;2054:	BotUseKamikaze(bs);
;2055:	BotUseInvulnerability(bs);
;2056:#endif
;2057:}
LABELV $460
endproc BotBattleUseItems 4 4
export BotSetTeleportTime
proc BotSetTeleportTime 8 0
line 2064
;2058:
;2059:/*
;2060:==================
;2061:BotSetTeleportTime
;2062:==================
;2063:*/
;2064:void BotSetTeleportTime(bot_state_t *bs) {
line 2065
;2065:	if ((bs->cur_ps.eFlags ^ bs->last_eFlags) & EF_TELEPORT_BIT) {
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
INDIRP4
CNSTI4 120
ADDP4
INDIRI4
ADDRLP4 0
INDIRP4
CNSTI4 484
ADDP4
INDIRI4
BXORI4
CNSTI4 4
BANDI4
CNSTI4 0
EQI4 $472
line 2066
;2066:		bs->teleport_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6180
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 2067
;2067:	}
LABELV $472
line 2068
;2068:	bs->last_eFlags = bs->cur_ps.eFlags;
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 484
ADDP4
ADDRLP4 4
INDIRP4
CNSTI4 120
ADDP4
INDIRI4
ASGNI4
line 2069
;2069:}
LABELV $471
endproc BotSetTeleportTime 8 0
export BotIsDead
proc BotIsDead 4 0
line 2076
;2070:
;2071:/*
;2072:==================
;2073:BotIsDead
;2074:==================
;2075:*/
;2076:qboolean BotIsDead(bot_state_t *bs) {
line 2077
;2077:	return (qboolean)(bs->cur_ps.pm_type == PM_DEAD); // ***GREGS_VC9_PORT_MOD*** -- added typecast(s)
ADDRFP4 0
INDIRP4
CNSTI4 20
ADDP4
INDIRI4
CNSTI4 3
NEI4 $476
ADDRLP4 0
CNSTI4 1
ASGNI4
ADDRGP4 $477
JUMPV
LABELV $476
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $477
ADDRLP4 0
INDIRI4
RETI4
LABELV $474
endproc BotIsDead 4 0
export BotIsObserver
proc BotIsObserver 1032 12
line 2085
;2078:}
;2079:
;2080:/*
;2081:==================
;2082:BotIsObserver
;2083:==================
;2084:*/
;2085:qboolean BotIsObserver(bot_state_t *bs) {
line 2087
;2086:	char buf[MAX_INFO_STRING];
;2087:	if (bs->cur_ps.pm_type == PM_SPECTATOR) return qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 20
ADDP4
INDIRI4
CNSTI4 2
NEI4 $479
CNSTI4 1
RETI4
ADDRGP4 $478
JUMPV
LABELV $479
line 2088
;2088:	trap_GetConfigstring(CS_PLAYERS+bs->client, buf, sizeof(buf));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 2089
;2089:	if (atoi(Info_ValueForKey(buf, "t")) == TEAM_SPECTATOR) return qtrue;
ADDRLP4 0
ARGP4
ADDRGP4 $67
ARGP4
ADDRLP4 1024
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 1024
INDIRP4
ARGP4
ADDRLP4 1028
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 1028
INDIRI4
CNSTI4 3
NEI4 $481
CNSTI4 1
RETI4
ADDRGP4 $478
JUMPV
LABELV $481
line 2090
;2090:	return qfalse;
CNSTI4 0
RETI4
LABELV $478
endproc BotIsObserver 1032 12
export BotIntermission
proc BotIntermission 8 0
line 2098
;2091:}
;2092:
;2093:/*
;2094:==================
;2095:BotIntermission
;2096:==================
;2097:*/
;2098:qboolean BotIntermission(bot_state_t *bs) {
line 2100
;2099:	//NOTE: we shouldn't be looking at the game code...
;2100:	if (level.intermissiontime) return qtrue;
ADDRGP4 level+9128
INDIRI4
CNSTI4 0
EQI4 $484
CNSTI4 1
RETI4
ADDRGP4 $483
JUMPV
LABELV $484
line 2101
;2101:	return (qboolean)(bs->cur_ps.pm_type == PM_FREEZE || bs->cur_ps.pm_type == PM_INTERMISSION); // ***GREGS_VC9_PORT_MOD*** -- added typecast(s)
ADDRLP4 4
ADDRFP4 0
INDIRP4
CNSTI4 20
ADDP4
INDIRI4
ASGNI4
ADDRLP4 4
INDIRI4
CNSTI4 4
EQI4 $490
ADDRLP4 4
INDIRI4
CNSTI4 5
NEI4 $488
LABELV $490
ADDRLP4 0
CNSTI4 1
ASGNI4
ADDRGP4 $489
JUMPV
LABELV $488
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $489
ADDRLP4 0
INDIRI4
RETI4
LABELV $483
endproc BotIntermission 8 0
export BotInLavaOrSlime
proc BotInLavaOrSlime 16 4
line 2109
;2102:}
;2103:
;2104:/*
;2105:==================
;2106:BotInLavaOrSlime
;2107:==================
;2108:*/
;2109:qboolean BotInLavaOrSlime(bot_state_t *bs) {
line 2112
;2110:	vec3_t feet;
;2111:
;2112:	VectorCopy(bs->origin, feet);
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 2113
;2113:	feet[2] -= 23;
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
CNSTF4 1102577664
SUBF4
ASGNF4
line 2114
;2114:	return (qboolean)(trap_AAS_PointContents(feet) & (CONTENTS_LAVA|CONTENTS_SLIME)); // ***GREGS_VC9_PORT_MOD*** -- added typecast(s)
ADDRLP4 0
ARGP4
ADDRLP4 12
ADDRGP4 trap_AAS_PointContents
CALLI4
ASGNI4
ADDRLP4 12
INDIRI4
CNSTI4 24
BANDI4
RETI4
LABELV $491
endproc BotInLavaOrSlime 16 4
lit
align 4
LABELV $494
byte 4 3238002688
byte 4 3238002688
byte 4 3238002688
align 4
LABELV $495
byte 4 1090519040
byte 4 1090519040
byte 4 1090519040
export BotCreateWayPoint
code
proc BotCreateWayPoint 32 12
line 2122
;2115:}
;2116:
;2117:/*
;2118:==================
;2119:BotCreateWayPoint
;2120:==================
;2121:*/
;2122:bot_waypoint_t *BotCreateWayPoint(char *name, vec3_t origin, int areanum) {
line 2124
;2123:	bot_waypoint_t *wp;
;2124:	vec3_t waypointmins = {-8, -8, -8}, waypointmaxs = {8, 8, 8};
ADDRLP4 4
ADDRGP4 $494
INDIRB
ASGNB 12
ADDRLP4 16
ADDRGP4 $495
INDIRB
ASGNB 12
line 2126
;2125:
;2126:	wp = botai_freewaypoints;
ADDRLP4 0
ADDRGP4 botai_freewaypoints
INDIRP4
ASGNP4
line 2127
;2127:	if ( !wp ) {
ADDRLP4 0
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $496
line 2128
;2128:		BotAI_Print( PRT_WARNING, "BotCreateWayPoint: Out of waypoints\n" );
CNSTI4 2
ARGI4
ADDRGP4 $498
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 2129
;2129:		return NULL;
CNSTP4 0
RETP4
ADDRGP4 $493
JUMPV
LABELV $496
line 2131
;2130:	}
;2131:	botai_freewaypoints = botai_freewaypoints->next;
ADDRLP4 28
ADDRGP4 botai_freewaypoints
ASGNP4
ADDRLP4 28
INDIRP4
ADDRLP4 28
INDIRP4
INDIRP4
CNSTI4 92
ADDP4
INDIRP4
ASGNP4
line 2133
;2132:
;2133:	Q_strncpyz( wp->name, name, sizeof(wp->name) );
ADDRLP4 0
INDIRP4
CNSTI4 4
ADDP4
ARGP4
ADDRFP4 0
INDIRP4
ARGP4
CNSTI4 32
ARGI4
ADDRGP4 Q_strncpyz
CALLV
pop
line 2134
;2134:	VectorCopy(origin, wp->goal.origin);
ADDRLP4 0
INDIRP4
CNSTI4 36
ADDP4
ADDRFP4 4
INDIRP4
INDIRB
ASGNB 12
line 2135
;2135:	VectorCopy(waypointmins, wp->goal.mins);
ADDRLP4 0
INDIRP4
CNSTI4 52
ADDP4
ADDRLP4 4
INDIRB
ASGNB 12
line 2136
;2136:	VectorCopy(waypointmaxs, wp->goal.maxs);
ADDRLP4 0
INDIRP4
CNSTI4 64
ADDP4
ADDRLP4 16
INDIRB
ASGNB 12
line 2137
;2137:	wp->goal.areanum = areanum;
ADDRLP4 0
INDIRP4
CNSTI4 48
ADDP4
ADDRFP4 8
INDIRI4
ASGNI4
line 2138
;2138:	wp->next = NULL;
ADDRLP4 0
INDIRP4
CNSTI4 92
ADDP4
CNSTP4 0
ASGNP4
line 2139
;2139:	wp->prev = NULL;
ADDRLP4 0
INDIRP4
CNSTI4 96
ADDP4
CNSTP4 0
ASGNP4
line 2140
;2140:	return wp;
ADDRLP4 0
INDIRP4
RETP4
LABELV $493
endproc BotCreateWayPoint 32 12
export BotFindWayPoint
proc BotFindWayPoint 8 8
line 2148
;2141:}
;2142:
;2143:/*
;2144:==================
;2145:BotFindWayPoint
;2146:==================
;2147:*/
;2148:bot_waypoint_t *BotFindWayPoint(bot_waypoint_t *waypoints, char *name) {
line 2151
;2149:	bot_waypoint_t *wp;
;2150:
;2151:	for (wp = waypoints; wp; wp = wp->next) {
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRGP4 $503
JUMPV
LABELV $500
line 2152
;2152:		if (!Q_stricmp(wp->name, name)) return wp;
ADDRLP4 0
INDIRP4
CNSTI4 4
ADDP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 4
ADDRGP4 Q_stricmp
CALLI4
ASGNI4
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $504
ADDRLP4 0
INDIRP4
RETP4
ADDRGP4 $499
JUMPV
LABELV $504
line 2153
;2153:	}
LABELV $501
line 2151
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 92
ADDP4
INDIRP4
ASGNP4
LABELV $503
ADDRLP4 0
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $500
line 2154
;2154:	return NULL;
CNSTP4 0
RETP4
LABELV $499
endproc BotFindWayPoint 8 8
export BotFreeWaypoints
proc BotFreeWaypoints 4 0
line 2162
;2155:}
;2156:
;2157:/*
;2158:==================
;2159:BotFreeWaypoints
;2160:==================
;2161:*/
;2162:void BotFreeWaypoints(bot_waypoint_t *wp) {
line 2165
;2163:	bot_waypoint_t *nextwp;
;2164:
;2165:	for (; wp; wp = nextwp) {
ADDRGP4 $510
JUMPV
LABELV $507
line 2166
;2166:		nextwp = wp->next;
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 92
ADDP4
INDIRP4
ASGNP4
line 2167
;2167:		wp->next = botai_freewaypoints;
ADDRFP4 0
INDIRP4
CNSTI4 92
ADDP4
ADDRGP4 botai_freewaypoints
INDIRP4
ASGNP4
line 2168
;2168:		botai_freewaypoints = wp;
ADDRGP4 botai_freewaypoints
ADDRFP4 0
INDIRP4
ASGNP4
line 2169
;2169:	}
LABELV $508
line 2165
ADDRFP4 0
ADDRLP4 0
INDIRP4
ASGNP4
LABELV $510
ADDRFP4 0
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $507
line 2170
;2170:}
LABELV $506
endproc BotFreeWaypoints 4 0
export BotInitWaypoints
proc BotInitWaypoints 4 0
line 2177
;2171:
;2172:/*
;2173:==================
;2174:BotInitWaypoints
;2175:==================
;2176:*/
;2177:void BotInitWaypoints(void) {
line 2180
;2178:	int i;
;2179:
;2180:	botai_freewaypoints = NULL;
ADDRGP4 botai_freewaypoints
CNSTP4 0
ASGNP4
line 2181
;2181:	for (i = 0; i < MAX_WAYPOINTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $512
line 2182
;2182:		botai_waypoints[i].next = botai_freewaypoints;
CNSTI4 100
ADDRLP4 0
INDIRI4
MULI4
ADDRGP4 botai_waypoints+92
ADDP4
ADDRGP4 botai_freewaypoints
INDIRP4
ASGNP4
line 2183
;2183:		botai_freewaypoints = &botai_waypoints[i];
ADDRGP4 botai_freewaypoints
CNSTI4 100
ADDRLP4 0
INDIRI4
MULI4
ADDRGP4 botai_waypoints
ADDP4
ASGNP4
line 2184
;2184:	}
LABELV $513
line 2181
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 128
LTI4 $512
line 2185
;2185:}
LABELV $511
endproc BotInitWaypoints 4 0
export TeamPlayIsOn
proc TeamPlayIsOn 4 0
line 2192
;2186:
;2187:/*
;2188:==================
;2189:TeamPlayIsOn
;2190:==================
;2191:*/
;2192:int TeamPlayIsOn(void) {
line 2193
;2193:	return ( gametype >= GT_TEAM );
ADDRGP4 gametype
INDIRI4
CNSTI4 3
LTI4 $519
ADDRLP4 0
CNSTI4 1
ASGNI4
ADDRGP4 $520
JUMPV
LABELV $519
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $520
ADDRLP4 0
INDIRI4
RETI4
LABELV $517
endproc TeamPlayIsOn 4 0
export BotAggression
proc BotAggression 28 0
line 2201
;2194:}
;2195:
;2196:/*
;2197:==================
;2198:BotAggression
;2199:==================
;2200:*/
;2201:float BotAggression(bot_state_t *bs) {
line 2203
;2202:	//if the bot has quad
;2203:	if (bs->inventory[INVENTORY_QUAD]) {
ADDRFP4 0
INDIRP4
CNSTI4 5092
ADDP4
INDIRI4
CNSTI4 0
EQI4 $522
line 2205
;2204:		//if the bot is not holding the gauntlet or the enemy is really nearby
;2205:		if (bs->weaponnum != WP_GAUNTLET ||
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
CNSTI4 1
NEI4 $526
ADDRLP4 0
INDIRP4
CNSTI4 5752
ADDP4
INDIRI4
CNSTI4 80
GEI4 $524
LABELV $526
line 2206
;2206:			bs->inventory[ENEMY_HORIZONTAL_DIST] < 80) {
line 2207
;2207:			return 70;
CNSTF4 1116471296
RETF4
ADDRGP4 $521
JUMPV
LABELV $524
line 2209
;2208:		}
;2209:	}
LABELV $522
line 2211
;2210:	//if the enemy is located way higher than the bot
;2211:	if (bs->inventory[ENEMY_HEIGHT] > 200) return 0;
ADDRFP4 0
INDIRP4
CNSTI4 5756
ADDP4
INDIRI4
CNSTI4 200
LEI4 $527
CNSTF4 0
RETF4
ADDRGP4 $521
JUMPV
LABELV $527
line 2213
;2212:	//if the bot is very low on health
;2213:	if (bs->inventory[INVENTORY_HEALTH] < 60) return 0;
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 60
GEI4 $529
CNSTF4 0
RETF4
ADDRGP4 $521
JUMPV
LABELV $529
line 2215
;2214:	//if the bot is low on health
;2215:	if (bs->inventory[INVENTORY_HEALTH] < 80) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 80
GEI4 $531
line 2217
;2216:		//if the bot has insufficient armor
;2217:		if (bs->inventory[INVENTORY_ARMOR] < 40) return 0;
ADDRFP4 0
INDIRP4
CNSTI4 4956
ADDP4
INDIRI4
CNSTI4 40
GEI4 $533
CNSTF4 0
RETF4
ADDRGP4 $521
JUMPV
LABELV $533
line 2218
;2218:	}
LABELV $531
line 2220
;2219:	//if the bot can use the bfg
;2220:	if (bs->inventory[INVENTORY_BFG10K] > 0 &&
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
INDIRP4
CNSTI4 5004
ADDP4
INDIRI4
CNSTI4 0
LEI4 $535
ADDRLP4 0
INDIRP4
CNSTI4 5052
ADDP4
INDIRI4
CNSTI4 7
LEI4 $535
line 2221
;2221:			bs->inventory[INVENTORY_BFGAMMO] > 7) return 100;
CNSTF4 1120403456
RETF4
ADDRGP4 $521
JUMPV
LABELV $535
line 2223
;2222:	//if the bot can use the railgun
;2223:	if (bs->inventory[INVENTORY_RAILGUN] > 0 &&
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 4992
ADDP4
INDIRI4
CNSTI4 0
LEI4 $537
ADDRLP4 4
INDIRP4
CNSTI4 5048
ADDP4
INDIRI4
CNSTI4 5
LEI4 $537
line 2224
;2224:			bs->inventory[INVENTORY_SLUGS] > 5) return 95;
CNSTF4 1119748096
RETF4
ADDRGP4 $521
JUMPV
LABELV $537
line 2226
;2225:	//if the bot can use the lightning gun
;2226:	if (bs->inventory[INVENTORY_LIGHTNING] > 0 &&
ADDRLP4 8
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 8
INDIRP4
CNSTI4 4988
ADDP4
INDIRI4
CNSTI4 0
LEI4 $539
ADDRLP4 8
INDIRP4
CNSTI4 5040
ADDP4
INDIRI4
CNSTI4 50
LEI4 $539
line 2227
;2227:			bs->inventory[INVENTORY_LIGHTNINGAMMO] > 50) return 90;
CNSTF4 1119092736
RETF4
ADDRGP4 $521
JUMPV
LABELV $539
line 2229
;2228:	//if the bot can use the rocketlauncher
;2229:	if (bs->inventory[INVENTORY_ROCKETLAUNCHER] > 0 &&
ADDRLP4 12
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 12
INDIRP4
CNSTI4 4984
ADDP4
INDIRI4
CNSTI4 0
LEI4 $541
ADDRLP4 12
INDIRP4
CNSTI4 5044
ADDP4
INDIRI4
CNSTI4 5
LEI4 $541
line 2230
;2230:			bs->inventory[INVENTORY_ROCKETS] > 5) return 90;
CNSTF4 1119092736
RETF4
ADDRGP4 $521
JUMPV
LABELV $541
line 2232
;2231:	//if the bot can use the plasmagun
;2232:	if (bs->inventory[INVENTORY_PLASMAGUN] > 0 &&
ADDRLP4 16
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 16
INDIRP4
CNSTI4 4996
ADDP4
INDIRI4
CNSTI4 0
LEI4 $543
ADDRLP4 16
INDIRP4
CNSTI4 5036
ADDP4
INDIRI4
CNSTI4 40
LEI4 $543
line 2233
;2233:			bs->inventory[INVENTORY_CELLS] > 40) return 85;
CNSTF4 1118437376
RETF4
ADDRGP4 $521
JUMPV
LABELV $543
line 2235
;2234:	//if the bot can use the grenade launcher
;2235:	if (bs->inventory[INVENTORY_GRENADELAUNCHER] > 0 &&
ADDRLP4 20
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 20
INDIRP4
CNSTI4 4980
ADDP4
INDIRI4
CNSTI4 0
LEI4 $545
ADDRLP4 20
INDIRP4
CNSTI4 5032
ADDP4
INDIRI4
CNSTI4 10
LEI4 $545
line 2236
;2236:			bs->inventory[INVENTORY_GRENADES] > 10) return 80;
CNSTF4 1117782016
RETF4
ADDRGP4 $521
JUMPV
LABELV $545
line 2238
;2237:	//if the bot can use the shotgun
;2238:	if (bs->inventory[INVENTORY_SHOTGUN] > 0 &&
ADDRLP4 24
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 24
INDIRP4
CNSTI4 4972
ADDP4
INDIRI4
CNSTI4 0
LEI4 $547
ADDRLP4 24
INDIRP4
CNSTI4 5024
ADDP4
INDIRI4
CNSTI4 10
LEI4 $547
line 2239
;2239:			bs->inventory[INVENTORY_SHELLS] > 10) return 50;
CNSTF4 1112014848
RETF4
ADDRGP4 $521
JUMPV
LABELV $547
line 2241
;2240:	//otherwise the bot is not feeling too good
;2241:	return 0;
CNSTF4 0
RETF4
LABELV $521
endproc BotAggression 28 0
export BotFeelingBad
proc BotFeelingBad 0 0
line 2249
;2242:}
;2243:
;2244:/*
;2245:==================
;2246:BotFeelingBad
;2247:==================
;2248:*/
;2249:float BotFeelingBad(bot_state_t *bs) {
line 2250
;2250:	if (bs->weaponnum == WP_GAUNTLET) {
ADDRFP4 0
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
CNSTI4 1
NEI4 $550
line 2251
;2251:		return 100;
CNSTF4 1120403456
RETF4
ADDRGP4 $549
JUMPV
LABELV $550
line 2253
;2252:	}
;2253:	if (bs->inventory[INVENTORY_HEALTH] < 40) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 40
GEI4 $552
line 2254
;2254:		return 100;
CNSTF4 1120403456
RETF4
ADDRGP4 $549
JUMPV
LABELV $552
line 2256
;2255:	}
;2256:	if (bs->weaponnum == WP_MACHINEGUN) {
ADDRFP4 0
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
CNSTI4 2
NEI4 $554
line 2257
;2257:		return 90;
CNSTF4 1119092736
RETF4
ADDRGP4 $549
JUMPV
LABELV $554
line 2259
;2258:	}
;2259:	if (bs->inventory[INVENTORY_HEALTH] < 60) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 60
GEI4 $556
line 2260
;2260:		return 80;
CNSTF4 1117782016
RETF4
ADDRGP4 $549
JUMPV
LABELV $556
line 2262
;2261:	}
;2262:	return 0;
CNSTF4 0
RETF4
LABELV $549
endproc BotFeelingBad 0 0
export BotWantsToRetreat
proc BotWantsToRetreat 144 8
line 2270
;2263:}
;2264:
;2265:/*
;2266:==================
;2267:BotWantsToRetreat
;2268:==================
;2269:*/
;2270:int BotWantsToRetreat(bot_state_t *bs) {
line 2273
;2271:	aas_entityinfo_t entinfo;
;2272:
;2273:	if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $559
line 2275
;2274:		//always retreat when carrying a CTF flag
;2275:		if (BotCTFCarryingFlag(bs))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
ADDRGP4 BotCTFCarryingFlag
CALLI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 0
EQI4 $561
line 2276
;2276:			return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $558
JUMPV
LABELV $561
line 2277
;2277:	}
LABELV $559
line 2303
;2278:#ifdef MISSIONPACK
;2279:	else if (gametype == GT_1FCTF) {
;2280:		//if carrying the flag then always retreat
;2281:		if (Bot1FCTFCarryingFlag(bs))
;2282:			return qtrue;
;2283:	}
;2284:	else if (gametype == GT_OBELISK) {
;2285:		//the bots should be dedicated to attacking the enemy obelisk
;2286:		if (bs->ltgtype == LTG_ATTACKENEMYBASE) {
;2287:			if (bs->enemy != redobelisk.entitynum ||
;2288:						bs->enemy != blueobelisk.entitynum) {
;2289:				return qtrue;
;2290:			}
;2291:		}
;2292:		if (BotFeelingBad(bs) > 50) {
;2293:			return qtrue;
;2294:		}
;2295:		return qfalse;
;2296:	}
;2297:	else if (gametype == GT_HARVESTER) {
;2298:		//if carrying cubes then always retreat
;2299:		if (BotHarvesterCarryingCubes(bs)) return qtrue;
;2300:	}
;2301:#endif
;2302:	//
;2303:	if (bs->enemy >= 0) {
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
CNSTI4 0
LTI4 $563
line 2305
;2304:		//if the enemy is carrying a flag
;2305:		BotEntityInfo(bs->enemy, &entinfo);
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 2306
;2306:		if (EntityCarriesFlag(&entinfo))
ADDRLP4 0
ARGP4
ADDRLP4 140
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 0
EQI4 $565
line 2307
;2307:			return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $558
JUMPV
LABELV $565
line 2308
;2308:	}
LABELV $563
line 2310
;2309:	//if the bot is getting the flag
;2310:	if (bs->ltgtype == LTG_GETFLAG)
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 4
NEI4 $567
line 2311
;2311:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $558
JUMPV
LABELV $567
line 2313
;2312:	//
;2313:	if (BotAggression(bs) < 50)
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
ADDRGP4 BotAggression
CALLF4
ASGNF4
ADDRLP4 140
INDIRF4
CNSTF4 1112014848
GEF4 $569
line 2314
;2314:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $558
JUMPV
LABELV $569
line 2315
;2315:	return qfalse;
CNSTI4 0
RETI4
LABELV $558
endproc BotWantsToRetreat 144 8
export BotWantsToChase
proc BotWantsToChase 148 8
line 2323
;2316:}
;2317:
;2318:/*
;2319:==================
;2320:BotWantsToChase
;2321:==================
;2322:*/
;2323:int BotWantsToChase(bot_state_t *bs) {
line 2326
;2324:	aas_entityinfo_t entinfo;
;2325:
;2326:	if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $572
line 2328
;2327:		//never chase when carrying a CTF flag
;2328:		if (BotCTFCarryingFlag(bs))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
ADDRGP4 BotCTFCarryingFlag
CALLI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 0
EQI4 $574
line 2329
;2329:			return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $571
JUMPV
LABELV $574
line 2331
;2330:		//always chase if the enemy is carrying a flag
;2331:		BotEntityInfo(bs->enemy, &entinfo);
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 2332
;2332:		if (EntityCarriesFlag(&entinfo))
ADDRLP4 0
ARGP4
ADDRLP4 144
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 144
INDIRI4
CNSTI4 0
EQI4 $576
line 2333
;2333:			return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $571
JUMPV
LABELV $576
line 2334
;2334:	}
LABELV $572
line 2361
;2335:#ifdef MISSIONPACK
;2336:	else if (gametype == GT_1FCTF) {
;2337:		//never chase if carrying the flag
;2338:		if (Bot1FCTFCarryingFlag(bs))
;2339:			return qfalse;
;2340:		//always chase if the enemy is carrying a flag
;2341:		BotEntityInfo(bs->enemy, &entinfo);
;2342:		if (EntityCarriesFlag(&entinfo))
;2343:			return qtrue;
;2344:	}
;2345:	else if (gametype == GT_OBELISK) {
;2346:		//the bots should be dedicated to attacking the enemy obelisk
;2347:		if (bs->ltgtype == LTG_ATTACKENEMYBASE) {
;2348:			if (bs->enemy != redobelisk.entitynum ||
;2349:						bs->enemy != blueobelisk.entitynum) {
;2350:				return qfalse;
;2351:			}
;2352:		}
;2353:	}
;2354:	else if (gametype == GT_HARVESTER) {
;2355:		//never chase if carrying cubes
;2356:		if (BotHarvesterCarryingCubes(bs))
;2357:			return qfalse;
;2358:	}
;2359:#endif
;2360:	//if the bot is getting the flag
;2361:	if (bs->ltgtype == LTG_GETFLAG)
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
CNSTI4 4
NEI4 $578
line 2362
;2362:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $571
JUMPV
LABELV $578
line 2364
;2363:	//
;2364:	if (BotAggression(bs) > 50)
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
ADDRGP4 BotAggression
CALLF4
ASGNF4
ADDRLP4 140
INDIRF4
CNSTF4 1112014848
LEF4 $580
line 2365
;2365:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $571
JUMPV
LABELV $580
line 2366
;2366:	return qfalse;
CNSTI4 0
RETI4
LABELV $571
endproc BotWantsToChase 148 8
export BotWantsToHelp
proc BotWantsToHelp 0 0
line 2374
;2367:}
;2368:
;2369:/*
;2370:==================
;2371:BotWantsToHelp
;2372:==================
;2373:*/
;2374:int BotWantsToHelp(bot_state_t *bs) {
line 2375
;2375:	return qtrue;
CNSTI4 1
RETI4
LABELV $582
endproc BotWantsToHelp 0 0
export BotCanAndWantsToRocketJump
proc BotCanAndWantsToRocketJump 8 16
line 2383
;2376:}
;2377:
;2378:/*
;2379:==================
;2380:BotCanAndWantsToRocketJump
;2381:==================
;2382:*/
;2383:int BotCanAndWantsToRocketJump(bot_state_t *bs) {
line 2387
;2384:	float rocketjumper;
;2385:
;2386:	//if rocket jumping is disabled
;2387:	if (!bot_rocketjump.integer) return qfalse;
ADDRGP4 bot_rocketjump+12
INDIRI4
CNSTI4 0
NEI4 $584
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $584
line 2389
;2388:	//if no rocket launcher
;2389:	if (bs->inventory[INVENTORY_ROCKETLAUNCHER] <= 0) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 4984
ADDP4
INDIRI4
CNSTI4 0
GTI4 $587
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $587
line 2391
;2390:	//if low on rockets
;2391:	if (bs->inventory[INVENTORY_ROCKETS] < 3) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 5044
ADDP4
INDIRI4
CNSTI4 3
GEI4 $589
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $589
line 2393
;2392:	//never rocket jump with the Quad
;2393:	if (bs->inventory[INVENTORY_QUAD]) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 5092
ADDP4
INDIRI4
CNSTI4 0
EQI4 $591
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $591
line 2395
;2394:	//if low on health
;2395:	if (bs->inventory[INVENTORY_HEALTH] < 60) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 60
GEI4 $593
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $593
line 2397
;2396:	//if not full health
;2397:	if (bs->inventory[INVENTORY_HEALTH] < 90) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 90
GEI4 $595
line 2399
;2398:		//if the bot has insufficient armor
;2399:		if (bs->inventory[INVENTORY_ARMOR] < 40) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 4956
ADDP4
INDIRI4
CNSTI4 40
GEI4 $597
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $597
line 2400
;2400:	}
LABELV $595
line 2401
;2401:	rocketjumper = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_WEAPONJUMPING, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 38
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 4
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 0
ADDRLP4 4
INDIRF4
ASGNF4
line 2402
;2402:	if (rocketjumper < 0.5) return qfalse;
ADDRLP4 0
INDIRF4
CNSTF4 1056964608
GEF4 $599
CNSTI4 0
RETI4
ADDRGP4 $583
JUMPV
LABELV $599
line 2403
;2403:	return qtrue;
CNSTI4 1
RETI4
LABELV $583
endproc BotCanAndWantsToRocketJump 8 16
export BotHasPersistantPowerupAndWeapon
proc BotHasPersistantPowerupAndWeapon 32 0
line 2411
;2404:}
;2405:
;2406:/*
;2407:==================
;2408:BotHasPersistantPowerupAndWeapon
;2409:==================
;2410:*/
;2411:int BotHasPersistantPowerupAndWeapon(bot_state_t *bs) {
line 2422
;2412:#ifdef MISSIONPACK
;2413:	// if the bot does not have a persistant powerup
;2414:	if (!bs->inventory[INVENTORY_SCOUT] &&
;2415:		!bs->inventory[INVENTORY_GUARD] &&
;2416:		!bs->inventory[INVENTORY_DOUBLER] &&
;2417:		!bs->inventory[INVENTORY_AMMOREGEN] ) {
;2418:		return qfalse;
;2419:	}
;2420:#endif
;2421:	//if the bot is very low on health
;2422:	if (bs->inventory[INVENTORY_HEALTH] < 60) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 60
GEI4 $602
CNSTI4 0
RETI4
ADDRGP4 $601
JUMPV
LABELV $602
line 2424
;2423:	//if the bot is low on health
;2424:	if (bs->inventory[INVENTORY_HEALTH] < 80) {
ADDRFP4 0
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
CNSTI4 80
GEI4 $604
line 2426
;2425:		//if the bot has insufficient armor
;2426:		if (bs->inventory[INVENTORY_ARMOR] < 40) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 4956
ADDP4
INDIRI4
CNSTI4 40
GEI4 $606
CNSTI4 0
RETI4
ADDRGP4 $601
JUMPV
LABELV $606
line 2427
;2427:	}
LABELV $604
line 2429
;2428:	//if the bot can use the bfg
;2429:	if (bs->inventory[INVENTORY_BFG10K] > 0 &&
ADDRLP4 0
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
INDIRP4
CNSTI4 5004
ADDP4
INDIRI4
CNSTI4 0
LEI4 $608
ADDRLP4 0
INDIRP4
CNSTI4 5052
ADDP4
INDIRI4
CNSTI4 7
LEI4 $608
line 2430
;2430:			bs->inventory[INVENTORY_BFGAMMO] > 7) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $608
line 2432
;2431:	//if the bot can use the railgun
;2432:	if (bs->inventory[INVENTORY_RAILGUN] > 0 &&
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 4992
ADDP4
INDIRI4
CNSTI4 0
LEI4 $610
ADDRLP4 4
INDIRP4
CNSTI4 5048
ADDP4
INDIRI4
CNSTI4 5
LEI4 $610
line 2433
;2433:			bs->inventory[INVENTORY_SLUGS] > 5) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $610
line 2435
;2434:	//if the bot can use the lightning gun
;2435:	if (bs->inventory[INVENTORY_LIGHTNING] > 0 &&
ADDRLP4 8
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 8
INDIRP4
CNSTI4 4988
ADDP4
INDIRI4
CNSTI4 0
LEI4 $612
ADDRLP4 8
INDIRP4
CNSTI4 5040
ADDP4
INDIRI4
CNSTI4 50
LEI4 $612
line 2436
;2436:			bs->inventory[INVENTORY_LIGHTNINGAMMO] > 50) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $612
line 2438
;2437:	//if the bot can use the rocketlauncher
;2438:	if (bs->inventory[INVENTORY_ROCKETLAUNCHER] > 0 &&
ADDRLP4 12
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 12
INDIRP4
CNSTI4 4984
ADDP4
INDIRI4
CNSTI4 0
LEI4 $614
ADDRLP4 12
INDIRP4
CNSTI4 5044
ADDP4
INDIRI4
CNSTI4 5
LEI4 $614
line 2439
;2439:			bs->inventory[INVENTORY_ROCKETS] > 5) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $614
line 2441
;2440:	//
;2441:	if (bs->inventory[INVENTORY_NAILGUN] > 0 &&
ADDRLP4 16
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 16
INDIRP4
CNSTI4 5012
ADDP4
INDIRI4
CNSTI4 0
LEI4 $616
ADDRLP4 16
INDIRP4
CNSTI4 5056
ADDP4
INDIRI4
CNSTI4 5
LEI4 $616
line 2442
;2442:			bs->inventory[INVENTORY_NAILS] > 5) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $616
line 2444
;2443:	//
;2444:	if (bs->inventory[INVENTORY_PROXLAUNCHER] > 0 &&
ADDRLP4 20
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 20
INDIRP4
CNSTI4 5016
ADDP4
INDIRI4
CNSTI4 0
LEI4 $618
ADDRLP4 20
INDIRP4
CNSTI4 5060
ADDP4
INDIRI4
CNSTI4 5
LEI4 $618
line 2445
;2445:			bs->inventory[INVENTORY_MINES] > 5) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $618
line 2447
;2446:	//
;2447:	if (bs->inventory[INVENTORY_CHAINGUN] > 0 &&
ADDRLP4 24
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 24
INDIRP4
CNSTI4 5020
ADDP4
INDIRI4
CNSTI4 0
LEI4 $620
ADDRLP4 24
INDIRP4
CNSTI4 5064
ADDP4
INDIRI4
CNSTI4 40
LEI4 $620
line 2448
;2448:			bs->inventory[INVENTORY_BELT] > 40) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $620
line 2450
;2449:	//if the bot can use the plasmagun
;2450:	if (bs->inventory[INVENTORY_PLASMAGUN] > 0 &&
ADDRLP4 28
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 28
INDIRP4
CNSTI4 4996
ADDP4
INDIRI4
CNSTI4 0
LEI4 $622
ADDRLP4 28
INDIRP4
CNSTI4 5036
ADDP4
INDIRI4
CNSTI4 20
LEI4 $622
line 2451
;2451:			bs->inventory[INVENTORY_CELLS] > 20) return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $601
JUMPV
LABELV $622
line 2452
;2452:	return qfalse;
CNSTI4 0
RETI4
LABELV $601
endproc BotHasPersistantPowerupAndWeapon 32 0
export BotGoCamp
proc BotGoCamp 16 16
line 2460
;2453:}
;2454:
;2455:/*
;2456:==================
;2457:BotGoCamp
;2458:==================
;2459:*/
;2460:void BotGoCamp(bot_state_t *bs, bot_goal_t *goal) {
line 2463
;2461:	float camper;
;2462:
;2463:	bs->decisionmaker = bs->client;
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 6608
ADDP4
ADDRLP4 4
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 2465
;2464:	//set message time to zero so bot will NOT show any message
;2465:	bs->teammessage_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6740
ADDP4
CNSTF4 0
ASGNF4
line 2467
;2466:	//set the ltg type
;2467:	bs->ltgtype = LTG_CAMP;
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
CNSTI4 7
ASGNI4
line 2469
;2468:	//set the team goal
;2469:	memcpy(&bs->teamgoal, goal, sizeof(bot_goal_t));
ADDRFP4 0
INDIRP4
CNSTI4 6624
ADDP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 2471
;2470:	//get the team goal time
;2471:	camper = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_CAMPER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 44
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 8
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 0
ADDRLP4 8
INDIRF4
ASGNF4
line 2472
;2472:	if (camper > 0.99) bs->teamgoal_time = FloatTime() + 99999;
ADDRLP4 0
INDIRF4
CNSTF4 1065185444
LEF4 $625
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1203982208
ADDF4
ASGNF4
ADDRGP4 $626
JUMPV
LABELV $625
line 2473
;2473:	else bs->teamgoal_time = FloatTime() + 120 + 180 * camper + random() * 15;
ADDRLP4 12
ADDRGP4 rand
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
CNSTI4 6744
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1123024896
ADDF4
CNSTF4 1127481344
ADDRLP4 0
INDIRF4
MULF4
ADDF4
CNSTF4 1097859072
ADDRLP4 12
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
ADDF4
ASGNF4
LABELV $626
line 2475
;2474:	//set the last time the bot started camping
;2475:	bs->camp_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6184
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 2477
;2476:	//the teammate that requested the camping
;2477:	bs->teammate = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6604
ADDP4
CNSTI4 0
ASGNI4
line 2479
;2478:	//do NOT type arrive message
;2479:	bs->arrive_time = 1;
ADDRFP4 0
INDIRP4
CNSTI4 6172
ADDP4
CNSTF4 1065353216
ASGNF4
line 2480
;2480:}
LABELV $624
endproc BotGoCamp 16 16
export BotWantsToCamp
proc BotWantsToCamp 176 16
line 2487
;2481:
;2482:/*
;2483:==================
;2484:BotWantsToCamp
;2485:==================
;2486:*/
;2487:int BotWantsToCamp(bot_state_t *bs) {
line 2492
;2488:	float camper;
;2489:	int cs, traveltime, besttraveltime;
;2490:	bot_goal_t goal, bestgoal;
;2491:
;2492:	camper = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_CAMPER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 44
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 128
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 124
ADDRLP4 128
INDIRF4
ASGNF4
line 2493
;2493:	if (camper < 0.1) return qfalse;
ADDRLP4 124
INDIRF4
CNSTF4 1036831949
GEF4 $628
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $628
line 2495
;2494:	//if the bot has a team goal
;2495:	if (bs->ltgtype == LTG_TEAMHELP ||
ADDRLP4 132
ADDRFP4 0
INDIRP4
CNSTI4 6600
ADDP4
INDIRI4
ASGNI4
ADDRLP4 132
INDIRI4
CNSTI4 1
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 2
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 3
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 4
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 5
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 7
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 8
EQI4 $638
ADDRLP4 132
INDIRI4
CNSTI4 9
NEI4 $630
LABELV $638
line 2502
;2496:			bs->ltgtype == LTG_TEAMACCOMPANY ||
;2497:			bs->ltgtype == LTG_DEFENDKEYAREA ||
;2498:			bs->ltgtype == LTG_GETFLAG ||
;2499:			bs->ltgtype == LTG_RUSHBASE ||
;2500:			bs->ltgtype == LTG_CAMP ||
;2501:			bs->ltgtype == LTG_CAMPORDER ||
;2502:			bs->ltgtype == LTG_PATROL) {
line 2503
;2503:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $630
line 2506
;2504:	}
;2505:	//if camped recently
;2506:	if (bs->camp_time > FloatTime() - 60 + 300 * (1-camper)) return qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6184
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1114636288
SUBF4
CNSTF4 1133903872
CNSTF4 1065353216
ADDRLP4 124
INDIRF4
SUBF4
MULF4
ADDF4
LEF4 $639
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $639
line 2508
;2507:	//
;2508:	if (random() > camper) {
ADDRLP4 136
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 136
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ADDRLP4 124
INDIRF4
LEF4 $641
line 2509
;2509:		bs->camp_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6184
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 2510
;2510:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $641
line 2513
;2511:	}
;2512:	//if the bot isn't healthy anough
;2513:	if (BotAggression(bs) < 50) return qfalse;
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
ADDRGP4 BotAggression
CALLF4
ASGNF4
ADDRLP4 140
INDIRF4
CNSTF4 1112014848
GEF4 $643
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $643
line 2515
;2514:	//the bot should have at least have the rocket launcher, the railgun or the bfg10k with some ammo
;2515:	if ((bs->inventory[INVENTORY_ROCKETLAUNCHER] <= 0 || bs->inventory[INVENTORY_ROCKETS < 10]) &&
ADDRLP4 144
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 148
CNSTI4 0
ASGNI4
ADDRLP4 144
INDIRP4
CNSTI4 4984
ADDP4
INDIRI4
ADDRLP4 148
INDIRI4
LEI4 $647
ADDRLP4 144
INDIRP4
CNSTI4 4952
ADDP4
INDIRI4
ADDRLP4 148
INDIRI4
EQI4 $645
LABELV $647
ADDRLP4 152
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 152
INDIRP4
CNSTI4 4992
ADDP4
INDIRI4
CNSTI4 0
LEI4 $648
ADDRLP4 152
INDIRP4
CNSTI4 5048
ADDP4
INDIRI4
CNSTI4 10
GEI4 $645
LABELV $648
ADDRLP4 156
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 156
INDIRP4
CNSTI4 5004
ADDP4
INDIRI4
CNSTI4 0
LEI4 $649
ADDRLP4 156
INDIRP4
CNSTI4 5052
ADDP4
INDIRI4
CNSTI4 10
GEI4 $645
LABELV $649
line 2517
;2516:		(bs->inventory[INVENTORY_RAILGUN] <= 0 || bs->inventory[INVENTORY_SLUGS] < 10) &&
;2517:		(bs->inventory[INVENTORY_BFG10K] <= 0 || bs->inventory[INVENTORY_BFGAMMO] < 10)) {
line 2518
;2518:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $645
line 2521
;2519:	}
;2520:	//find the closest camp spot
;2521:	besttraveltime = 99999;
ADDRLP4 64
CNSTI4 99999
ASGNI4
line 2522
;2522:	for (cs = trap_BotGetNextCampSpotGoal(0, &goal); cs; cs = trap_BotGetNextCampSpotGoal(cs, &goal)) {
CNSTI4 0
ARGI4
ADDRLP4 8
ARGP4
ADDRLP4 160
ADDRGP4 trap_BotGetNextCampSpotGoal
CALLI4
ASGNI4
ADDRLP4 4
ADDRLP4 160
INDIRI4
ASGNI4
ADDRGP4 $653
JUMPV
LABELV $650
line 2523
;2523:		traveltime = trap_AAS_AreaTravelTimeToGoalArea(bs->areanum, bs->origin, goal.areanum, TFL_DEFAULT);
ADDRLP4 164
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 164
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 164
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRLP4 8+12
INDIRI4
ARGI4
CNSTI4 18616254
ARGI4
ADDRLP4 168
ADDRGP4 trap_AAS_AreaTravelTimeToGoalArea
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 168
INDIRI4
ASGNI4
line 2524
;2524:		if (traveltime && traveltime < besttraveltime) {
ADDRLP4 0
INDIRI4
CNSTI4 0
EQI4 $655
ADDRLP4 0
INDIRI4
ADDRLP4 64
INDIRI4
GEI4 $655
line 2525
;2525:			besttraveltime = traveltime;
ADDRLP4 64
ADDRLP4 0
INDIRI4
ASGNI4
line 2526
;2526:			memcpy(&bestgoal, &goal, sizeof(bot_goal_t));
ADDRLP4 68
ARGP4
ADDRLP4 8
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 2527
;2527:		}
LABELV $655
line 2528
;2528:	}
LABELV $651
line 2522
ADDRLP4 4
INDIRI4
ARGI4
ADDRLP4 8
ARGP4
ADDRLP4 164
ADDRGP4 trap_BotGetNextCampSpotGoal
CALLI4
ASGNI4
ADDRLP4 4
ADDRLP4 164
INDIRI4
ASGNI4
LABELV $653
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $650
line 2529
;2529:	if (besttraveltime > 150) return qfalse;
ADDRLP4 64
INDIRI4
CNSTI4 150
LEI4 $657
CNSTI4 0
RETI4
ADDRGP4 $627
JUMPV
LABELV $657
line 2531
;2530:	//ok found a camp spot, go camp there
;2531:	BotGoCamp(bs, &bestgoal);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 68
ARGP4
ADDRGP4 BotGoCamp
CALLV
pop
line 2532
;2532:	bs->ordered = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6612
ADDP4
CNSTI4 0
ASGNI4
line 2534
;2533:	//
;2534:	return qtrue;
CNSTI4 1
RETI4
LABELV $627
endproc BotWantsToCamp 176 16
export BotDontAvoid
proc BotDontAvoid 68 12
line 2542
;2535:}
;2536:
;2537:/*
;2538:==================
;2539:BotDontAvoid
;2540:==================
;2541:*/
;2542:void BotDontAvoid(bot_state_t *bs, char *itemname) {
line 2546
;2543:	bot_goal_t goal;
;2544:	int num;
;2545:
;2546:	num = trap_BotGetLevelItemGoal(-1, itemname, &goal);
CNSTI4 -1
ARGI4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 4
ARGP4
ADDRLP4 60
ADDRGP4 trap_BotGetLevelItemGoal
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 60
INDIRI4
ASGNI4
ADDRGP4 $661
JUMPV
LABELV $660
line 2547
;2547:	while(num >= 0) {
line 2548
;2548:		trap_BotRemoveFromAvoidGoals(bs->gs, goal.number);
ADDRFP4 0
INDIRP4
CNSTI4 6528
ADDP4
INDIRI4
ARGI4
ADDRLP4 4+44
INDIRI4
ARGI4
ADDRGP4 trap_BotRemoveFromAvoidGoals
CALLV
pop
line 2549
;2549:		num = trap_BotGetLevelItemGoal(num, itemname, &goal);
ADDRLP4 0
INDIRI4
ARGI4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 4
ARGP4
ADDRLP4 64
ADDRGP4 trap_BotGetLevelItemGoal
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 64
INDIRI4
ASGNI4
line 2550
;2550:	}
LABELV $661
line 2547
ADDRLP4 0
INDIRI4
CNSTI4 0
GEI4 $660
line 2551
;2551:}
LABELV $659
endproc BotDontAvoid 68 12
export BotGoForPowerups
proc BotGoForPowerups 0 8
line 2558
;2552:
;2553:/*
;2554:==================
;2555:BotGoForPowerups
;2556:==================
;2557:*/
;2558:void BotGoForPowerups(bot_state_t *bs) {
line 2561
;2559:
;2560:	//don't avoid any of the powerups anymore
;2561:	BotDontAvoid(bs, "Quad Damage");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $665
ARGP4
ADDRGP4 BotDontAvoid
CALLV
pop
line 2562
;2562:	BotDontAvoid(bs, "Regeneration");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $666
ARGP4
ADDRGP4 BotDontAvoid
CALLV
pop
line 2563
;2563:	BotDontAvoid(bs, "Battle Suit");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $667
ARGP4
ADDRGP4 BotDontAvoid
CALLV
pop
line 2564
;2564:	BotDontAvoid(bs, "Speed");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $668
ARGP4
ADDRGP4 BotDontAvoid
CALLV
pop
line 2565
;2565:	BotDontAvoid(bs, "Invisibility");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $669
ARGP4
ADDRGP4 BotDontAvoid
CALLV
pop
line 2569
;2566:	//BotDontAvoid(bs, "Flight");
;2567:	//reset the long term goal time so the bot will go for the powerup
;2568:	//NOTE: the long term goal type doesn't change
;2569:	bs->ltg_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6068
ADDP4
CNSTF4 0
ASGNF4
line 2570
;2570:}
LABELV $664
endproc BotGoForPowerups 0 8
export BotRoamGoal
proc BotRoamGoal 180 28
line 2577
;2571:
;2572:/*
;2573:==================
;2574:BotRoamGoal
;2575:==================
;2576:*/
;2577:void BotRoamGoal(bot_state_t *bs, vec3_t goal) {
line 2583
;2578:	int pc, i;
;2579:	float len, rnd;
;2580:	vec3_t dir, bestorg, belowbestorg;
;2581:	bsp_trace_t trace;
;2582:
;2583:	for (i = 0; i < 10; i++) {
ADDRLP4 116
CNSTI4 0
ASGNI4
LABELV $671
line 2585
;2584:		//start at the bot origin
;2585:		VectorCopy(bs->origin, bestorg);
ADDRLP4 12
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 2586
;2586:		rnd = random();
ADDRLP4 136
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 112
ADDRLP4 136
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ASGNF4
line 2587
;2587:		if (rnd > 0.25) {
ADDRLP4 112
INDIRF4
CNSTF4 1048576000
LEF4 $675
line 2589
;2588:			//add a random value to the x-coordinate
;2589:			if (random() < 0.5) bestorg[0] -= 800 * random() + 100;
ADDRLP4 140
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
GEF4 $677
ADDRLP4 144
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 12
ADDRLP4 12
INDIRF4
CNSTF4 1145569280
ADDRLP4 144
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
CNSTF4 1120403456
ADDF4
SUBF4
ASGNF4
ADDRGP4 $678
JUMPV
LABELV $677
line 2590
;2590:			else bestorg[0] += 800 * random() + 100;
ADDRLP4 148
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 12
ADDRLP4 12
INDIRF4
CNSTF4 1145569280
ADDRLP4 148
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
CNSTF4 1120403456
ADDF4
ADDF4
ASGNF4
LABELV $678
line 2591
;2591:		}
LABELV $675
line 2592
;2592:		if (rnd < 0.75) {
ADDRLP4 112
INDIRF4
CNSTF4 1061158912
GEF4 $679
line 2594
;2593:			//add a random value to the y-coordinate
;2594:			if (random() < 0.5) bestorg[1] -= 800 * random() + 100;
ADDRLP4 140
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
GEF4 $681
ADDRLP4 144
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 12+4
ADDRLP4 12+4
INDIRF4
CNSTF4 1145569280
ADDRLP4 144
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
CNSTF4 1120403456
ADDF4
SUBF4
ASGNF4
ADDRGP4 $682
JUMPV
LABELV $681
line 2595
;2595:			else bestorg[1] += 800 * random() + 100;
ADDRLP4 148
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 12+4
ADDRLP4 12+4
INDIRF4
CNSTF4 1145569280
ADDRLP4 148
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
CNSTF4 1120403456
ADDF4
ADDF4
ASGNF4
LABELV $682
line 2596
;2596:		}
LABELV $679
line 2598
;2597:		//add a random value to the z-coordinate (NOTE: 48 = maxjump?)
;2598:		bestorg[2] += 2 * 48 * crandom();
ADDRLP4 140
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 12+8
ADDRLP4 12+8
INDIRF4
CNSTF4 1119879168
CNSTF4 1073741824
ADDRLP4 140
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
ADDF4
ASGNF4
line 2600
;2599:		//trace a line from the origin to the roam target
;2600:		BotAI_Trace(&trace, bs->origin, NULL, NULL, bestorg, bs->entitynum, MASK_SOLID);
ADDRLP4 24
ARGP4
ADDRLP4 144
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 144
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRLP4 148
CNSTP4 0
ASGNP4
ADDRLP4 148
INDIRP4
ARGP4
ADDRLP4 148
INDIRP4
ARGP4
ADDRLP4 12
ARGP4
ADDRLP4 144
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 1
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 2602
;2601:		//direction and length towards the roam target
;2602:		VectorSubtract(trace.endpos, bs->origin, dir);
ADDRLP4 152
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 0
ADDRLP4 24+12
INDIRF4
ADDRLP4 152
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 24+12+4
INDIRF4
ADDRLP4 152
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 24+12+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 2603
;2603:		len = VectorNormalize(dir);
ADDRLP4 0
ARGP4
ADDRLP4 156
ADDRGP4 VectorNormalize
CALLF4
ASGNF4
ADDRLP4 108
ADDRLP4 156
INDIRF4
ASGNF4
line 2605
;2604:		//if the roam target is far away anough
;2605:		if (len > 200) {
ADDRLP4 108
INDIRF4
CNSTF4 1128792064
LEF4 $693
line 2607
;2606:			//the roam target is in the given direction before walls
;2607:			VectorScale(dir, len * trace.fraction - 40, dir);
ADDRLP4 164
CNSTF4 1109393408
ASGNF4
ADDRLP4 0
ADDRLP4 0
INDIRF4
ADDRLP4 108
INDIRF4
ADDRLP4 24+8
INDIRF4
MULF4
ADDRLP4 164
INDIRF4
SUBF4
MULF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 108
INDIRF4
ADDRLP4 24+8
INDIRF4
MULF4
ADDRLP4 164
INDIRF4
SUBF4
MULF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
ADDRLP4 108
INDIRF4
ADDRLP4 24+8
INDIRF4
MULF4
CNSTF4 1109393408
SUBF4
MULF4
ASGNF4
line 2608
;2608:			VectorAdd(bs->origin, dir, bestorg);
ADDRLP4 168
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 12
ADDRLP4 168
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
ADDRLP4 0
INDIRF4
ADDF4
ASGNF4
ADDRLP4 12+4
ADDRLP4 168
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
ADDRLP4 0+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 12+8
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
ADDRLP4 0+8
INDIRF4
ADDF4
ASGNF4
line 2610
;2609:			//get the coordinates of the floor below the roam target
;2610:			belowbestorg[0] = bestorg[0];
ADDRLP4 120
ADDRLP4 12
INDIRF4
ASGNF4
line 2611
;2611:			belowbestorg[1] = bestorg[1];
ADDRLP4 120+4
ADDRLP4 12+4
INDIRF4
ASGNF4
line 2612
;2612:			belowbestorg[2] = bestorg[2] - 800;
ADDRLP4 120+8
ADDRLP4 12+8
INDIRF4
CNSTF4 1145569280
SUBF4
ASGNF4
line 2613
;2613:			BotAI_Trace(&trace, bestorg, NULL, NULL, belowbestorg, bs->entitynum, MASK_SOLID);
ADDRLP4 24
ARGP4
ADDRLP4 12
ARGP4
ADDRLP4 172
CNSTP4 0
ASGNP4
ADDRLP4 172
INDIRP4
ARGP4
ADDRLP4 172
INDIRP4
ARGP4
ADDRLP4 120
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 1
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 2615
;2614:			//
;2615:			if (!trace.startsolid) {
ADDRLP4 24+4
INDIRI4
CNSTI4 0
NEI4 $710
line 2616
;2616:				trace.endpos[2]++;
ADDRLP4 24+12+8
ADDRLP4 24+12+8
INDIRF4
CNSTF4 1065353216
ADDF4
ASGNF4
line 2617
;2617:				pc = trap_PointContents(trace.endpos, bs->entitynum);
ADDRLP4 24+12
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 176
ADDRGP4 trap_PointContents
CALLI4
ASGNI4
ADDRLP4 132
ADDRLP4 176
INDIRI4
ASGNI4
line 2618
;2618:				if (!(pc & (CONTENTS_LAVA | CONTENTS_SLIME))) {
ADDRLP4 132
INDIRI4
CNSTI4 24
BANDI4
CNSTI4 0
NEI4 $716
line 2619
;2619:					VectorCopy(bestorg, goal);
ADDRFP4 4
INDIRP4
ADDRLP4 12
INDIRB
ASGNB 12
line 2620
;2620:					return;
ADDRGP4 $670
JUMPV
LABELV $716
line 2622
;2621:				}
;2622:			}
LABELV $710
line 2623
;2623:		}
LABELV $693
line 2624
;2624:	}
LABELV $672
line 2583
ADDRLP4 116
ADDRLP4 116
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 116
INDIRI4
CNSTI4 10
LTI4 $671
line 2625
;2625:	VectorCopy(bestorg, goal);
ADDRFP4 4
INDIRP4
ADDRLP4 12
INDIRB
ASGNB 12
line 2626
;2626:}
LABELV $670
endproc BotRoamGoal 180 28
lit
align 4
LABELV $720
byte 4 0
byte 4 0
byte 4 1065353216
export BotAttackMove
code
proc BotAttackMove 392 16
line 2633
;2627:
;2628:/*
;2629:==================
;2630:BotAttackMove
;2631:==================
;2632:*/
;2633:bot_moveresult_t BotAttackMove(bot_state_t *bs, int tfl) {
line 2637
;2634:	int movetype, i, attackentity;
;2635:	float attack_skill, jumper, croucher, dist, strafechange_time;
;2636:	float attack_dist, attack_range;
;2637:	vec3_t forward, backward, sideward, hordir, up = {0, 0, 1};
ADDRLP4 56
ADDRGP4 $720
INDIRB
ASGNB 12
line 2642
;2638:	aas_entityinfo_t entinfo;
;2639:	bot_moveresult_t moveresult;
;2640:	bot_goal_t goal;
;2641:
;2642:	attackentity = bs->enemy;
ADDRLP4 332
ADDRFP4 4
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ASGNI4
line 2644
;2643:	//
;2644:	if (bs->attackchase_time > FloatTime()) {
ADDRFP4 4
INDIRP4
CNSTI4 6124
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
LEF4 $721
line 2646
;2645:		//create the chase goal
;2646:		goal.entitynum = attackentity;
ADDRLP4 136+40
ADDRLP4 332
INDIRI4
ASGNI4
line 2647
;2647:		goal.areanum = bs->lastenemyareanum;
ADDRLP4 136+12
ADDRFP4 4
INDIRP4
CNSTI4 6544
ADDP4
INDIRI4
ASGNI4
line 2648
;2648:		VectorCopy(bs->lastenemyorigin, goal.origin);
ADDRLP4 136
ADDRFP4 4
INDIRP4
CNSTI4 6548
ADDP4
INDIRB
ASGNB 12
line 2649
;2649:		VectorSet(goal.mins, -8, -8, -8);
ADDRLP4 136+16
CNSTF4 3238002688
ASGNF4
ADDRLP4 136+16+4
CNSTF4 3238002688
ASGNF4
ADDRLP4 136+16+8
CNSTF4 3238002688
ASGNF4
line 2650
;2650:		VectorSet(goal.maxs, 8, 8, 8);
ADDRLP4 136+28
CNSTF4 1090519040
ASGNF4
ADDRLP4 136+28+4
CNSTF4 1090519040
ASGNF4
ADDRLP4 136+28+8
CNSTF4 1090519040
ASGNF4
line 2652
;2651:		//initialize the movement state
;2652:		BotSetupForMovement(bs);
ADDRFP4 4
INDIRP4
ARGP4
ADDRGP4 BotSetupForMovement
CALLV
pop
line 2654
;2653:		//move towards the goal
;2654:		trap_BotMoveToGoal(&moveresult, bs->ms, &goal, tfl);
ADDRLP4 80
ARGP4
ADDRFP4 4
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 136
ARGP4
ADDRFP4 8
INDIRI4
ARGI4
ADDRGP4 trap_BotMoveToGoal
CALLV
pop
line 2655
;2655:		return moveresult;
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
ADDRGP4 $718
JUMPV
LABELV $721
line 2658
;2656:	}
;2657:	//
;2658:	memset(&moveresult, 0, sizeof(bot_moveresult_t));
ADDRLP4 80
ARGP4
CNSTI4 0
ARGI4
CNSTI4 52
ARGI4
ADDRGP4 memset
CALLP4
pop
line 2660
;2659:	//
;2660:	attack_skill = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_ATTACK_SKILL, 0, 1);
ADDRFP4 4
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 2
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 348
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 132
ADDRLP4 348
INDIRF4
ASGNF4
line 2661
;2661:	jumper = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_JUMPER, 0, 1);
ADDRFP4 4
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 37
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 352
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 340
ADDRLP4 352
INDIRF4
ASGNF4
line 2662
;2662:	croucher = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_CROUCHER, 0, 1);
ADDRFP4 4
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 36
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 356
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 344
ADDRLP4 356
INDIRF4
ASGNF4
line 2664
;2663:	//if the bot is really stupid
;2664:	if (attack_skill < 0.2) return moveresult;
ADDRLP4 132
INDIRF4
CNSTF4 1045220557
GEF4 $735
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
ADDRGP4 $718
JUMPV
LABELV $735
line 2666
;2665:	//initialize the movement state
;2666:	BotSetupForMovement(bs);
ADDRFP4 4
INDIRP4
ARGP4
ADDRGP4 BotSetupForMovement
CALLV
pop
line 2668
;2667:	//get the enemy entity info
;2668:	BotEntityInfo(attackentity, &entinfo);
ADDRLP4 332
INDIRI4
ARGI4
ADDRLP4 192
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 2670
;2669:	//direction towards the enemy
;2670:	VectorSubtract(entinfo.origin, bs->origin, forward);
ADDRLP4 360
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 24
ADDRLP4 192+24
INDIRF4
ADDRLP4 360
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 24+4
ADDRLP4 192+24+4
INDIRF4
ADDRLP4 360
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 24+8
ADDRLP4 192+24+8
INDIRF4
ADDRFP4 4
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 2672
;2671:	//the distance towards the enemy
;2672:	dist = VectorNormalize(forward);
ADDRLP4 24
ARGP4
ADDRLP4 364
ADDRGP4 VectorNormalize
CALLF4
ASGNF4
ADDRLP4 68
ADDRLP4 364
INDIRF4
ASGNF4
line 2673
;2673:	VectorNegate(forward, backward);
ADDRLP4 36
ADDRLP4 24
INDIRF4
NEGF4
ASGNF4
ADDRLP4 36+4
ADDRLP4 24+4
INDIRF4
NEGF4
ASGNF4
ADDRLP4 36+8
ADDRLP4 24+8
INDIRF4
NEGF4
ASGNF4
line 2675
;2674:	//walk, crouch or jump
;2675:	movetype = MOVE_WALK;
ADDRLP4 52
CNSTI4 1
ASGNI4
line 2677
;2676:	//
;2677:	if (bs->attackcrouch_time < FloatTime() - 1) {
ADDRFP4 4
INDIRP4
CNSTI4 6120
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1065353216
SUBF4
GEF4 $748
line 2678
;2678:		if (random() < jumper) {
ADDRLP4 368
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 368
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ADDRLP4 340
INDIRF4
GEF4 $750
line 2679
;2679:			movetype = MOVE_JUMP;
ADDRLP4 52
CNSTI4 4
ASGNI4
line 2680
;2680:		}
ADDRGP4 $751
JUMPV
LABELV $750
line 2682
;2681:		//wait at least one second before crouching again
;2682:		else if (bs->attackcrouch_time < FloatTime() - 1 && random() < croucher) {
ADDRFP4 4
INDIRP4
CNSTI4 6120
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1065353216
SUBF4
GEF4 $752
ADDRLP4 372
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 372
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ADDRLP4 344
INDIRF4
GEF4 $752
line 2683
;2683:			bs->attackcrouch_time = FloatTime() + croucher * 5;
ADDRFP4 4
INDIRP4
CNSTI4 6120
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1084227584
ADDRLP4 344
INDIRF4
MULF4
ADDF4
ASGNF4
line 2684
;2684:		}
LABELV $752
LABELV $751
line 2685
;2685:	}
LABELV $748
line 2686
;2686:	if (bs->attackcrouch_time > FloatTime()) movetype = MOVE_CROUCH;
ADDRFP4 4
INDIRP4
CNSTI4 6120
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
LEF4 $754
ADDRLP4 52
CNSTI4 2
ASGNI4
LABELV $754
line 2688
;2687:	//if the bot should jump
;2688:	if (movetype == MOVE_JUMP) {
ADDRLP4 52
INDIRI4
CNSTI4 4
NEI4 $756
line 2690
;2689:		//if jumped last frame
;2690:		if (bs->attackjump_time > FloatTime()) {
ADDRFP4 4
INDIRP4
CNSTI4 6128
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
LEF4 $758
line 2691
;2691:			movetype = MOVE_WALK;
ADDRLP4 52
CNSTI4 1
ASGNI4
line 2692
;2692:		}
ADDRGP4 $759
JUMPV
LABELV $758
line 2693
;2693:		else {
line 2694
;2694:			bs->attackjump_time = FloatTime() + 1;
ADDRFP4 4
INDIRP4
CNSTI4 6128
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1065353216
ADDF4
ASGNF4
line 2695
;2695:		}
LABELV $759
line 2696
;2696:	}
LABELV $756
line 2697
;2697:	if (bs->cur_ps.weapon == WP_GAUNTLET) {
ADDRFP4 4
INDIRP4
CNSTI4 160
ADDP4
INDIRI4
CNSTI4 1
NEI4 $760
line 2698
;2698:		attack_dist = 0;
ADDRLP4 72
CNSTF4 0
ASGNF4
line 2699
;2699:		attack_range = 0;
ADDRLP4 76
CNSTF4 0
ASGNF4
line 2700
;2700:	}
ADDRGP4 $761
JUMPV
LABELV $760
line 2701
;2701:	else {
line 2702
;2702:		attack_dist = IDEAL_ATTACKDIST;
ADDRLP4 72
CNSTF4 1124859904
ASGNF4
line 2703
;2703:		attack_range = 40;
ADDRLP4 76
CNSTF4 1109393408
ASGNF4
line 2704
;2704:	}
LABELV $761
line 2706
;2705:	//if the bot is stupid
;2706:	if (attack_skill <= 0.4) {
ADDRLP4 132
INDIRF4
CNSTF4 1053609165
GTF4 $762
line 2708
;2707:		//just walk to or away from the enemy
;2708:		if (dist > attack_dist + attack_range) {
ADDRLP4 68
INDIRF4
ADDRLP4 72
INDIRF4
ADDRLP4 76
INDIRF4
ADDF4
LEF4 $764
line 2709
;2709:			if (trap_BotMoveInDirection(bs->ms, forward, 400, movetype)) return moveresult;
ADDRFP4 4
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 24
ARGP4
CNSTF4 1137180672
ARGF4
ADDRLP4 52
INDIRI4
ARGI4
ADDRLP4 368
ADDRGP4 trap_BotMoveInDirection
CALLI4
ASGNI4
ADDRLP4 368
INDIRI4
CNSTI4 0
EQI4 $766
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
ADDRGP4 $718
JUMPV
LABELV $766
line 2710
;2710:		}
LABELV $764
line 2711
;2711:		if (dist < attack_dist - attack_range) {
ADDRLP4 68
INDIRF4
ADDRLP4 72
INDIRF4
ADDRLP4 76
INDIRF4
SUBF4
GEF4 $768
line 2712
;2712:			if (trap_BotMoveInDirection(bs->ms, backward, 400, movetype)) return moveresult;
ADDRFP4 4
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 36
ARGP4
CNSTF4 1137180672
ARGF4
ADDRLP4 52
INDIRI4
ARGI4
ADDRLP4 368
ADDRGP4 trap_BotMoveInDirection
CALLI4
ASGNI4
ADDRLP4 368
INDIRI4
CNSTI4 0
EQI4 $770
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
ADDRGP4 $718
JUMPV
LABELV $770
line 2713
;2713:		}
LABELV $768
line 2714
;2714:		return moveresult;
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
ADDRGP4 $718
JUMPV
LABELV $762
line 2717
;2715:	}
;2716:	//increase the strafe time
;2717:	bs->attackstrafe_time += bs->thinktime;
ADDRLP4 368
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 372
ADDRLP4 368
INDIRP4
CNSTI4 6116
ADDP4
ASGNP4
ADDRLP4 372
INDIRP4
ADDRLP4 372
INDIRP4
INDIRF4
ADDRLP4 368
INDIRP4
CNSTI4 4904
ADDP4
INDIRF4
ADDF4
ASGNF4
line 2719
;2718:	//get the strafe change time
;2719:	strafechange_time = 0.4 + (1 - attack_skill) * 0.2;
ADDRLP4 336
CNSTF4 1045220557
CNSTF4 1065353216
ADDRLP4 132
INDIRF4
SUBF4
MULF4
CNSTF4 1053609165
ADDF4
ASGNF4
line 2720
;2720:	if (attack_skill > 0.7) strafechange_time += crandom() * 0.2;
ADDRLP4 132
INDIRF4
CNSTF4 1060320051
LEF4 $772
ADDRLP4 376
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 336
ADDRLP4 336
INDIRF4
CNSTF4 1045220557
CNSTF4 1073741824
ADDRLP4 376
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
ADDF4
ASGNF4
LABELV $772
line 2722
;2721:	//if the strafe direction should be changed
;2722:	if (bs->attackstrafe_time > strafechange_time) {
ADDRFP4 4
INDIRP4
CNSTI4 6116
ADDP4
INDIRF4
ADDRLP4 336
INDIRF4
LEF4 $774
line 2724
;2723:		//some magic number :)
;2724:		if (random() > 0.935) {
ADDRLP4 380
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 380
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1064262697
LEF4 $776
line 2726
;2725:			//flip the strafe direction
;2726:			bs->flags ^= BFL_STRAFERIGHT;
ADDRLP4 384
ADDRFP4 4
INDIRP4
CNSTI4 5980
ADDP4
ASGNP4
ADDRLP4 384
INDIRP4
ADDRLP4 384
INDIRP4
INDIRI4
CNSTI4 1
BXORI4
ASGNI4
line 2727
;2727:			bs->attackstrafe_time = 0;
ADDRFP4 4
INDIRP4
CNSTI4 6116
ADDP4
CNSTF4 0
ASGNF4
line 2728
;2728:		}
LABELV $776
line 2729
;2729:	}
LABELV $774
line 2731
;2730:	//
;2731:	for (i = 0; i < 2; i++) {
ADDRLP4 48
CNSTI4 0
ASGNI4
LABELV $778
line 2732
;2732:		hordir[0] = forward[0];
ADDRLP4 12
ADDRLP4 24
INDIRF4
ASGNF4
line 2733
;2733:		hordir[1] = forward[1];
ADDRLP4 12+4
ADDRLP4 24+4
INDIRF4
ASGNF4
line 2734
;2734:		hordir[2] = 0;
ADDRLP4 12+8
CNSTF4 0
ASGNF4
line 2735
;2735:		VectorNormalize(hordir);
ADDRLP4 12
ARGP4
ADDRGP4 VectorNormalize
CALLF4
pop
line 2737
;2736:		//get the sideward vector
;2737:		CrossProduct(hordir, up, sideward);
ADDRLP4 12
ARGP4
ADDRLP4 56
ARGP4
ADDRLP4 0
ARGP4
ADDRGP4 CrossProduct
CALLV
pop
line 2739
;2738:		//reverse the vector depending on the strafe direction
;2739:		if (bs->flags & BFL_STRAFERIGHT) VectorNegate(sideward, sideward);
ADDRFP4 4
INDIRP4
CNSTI4 5980
ADDP4
INDIRI4
CNSTI4 1
BANDI4
CNSTI4 0
EQI4 $785
ADDRLP4 0
ADDRLP4 0
INDIRF4
NEGF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
NEGF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
NEGF4
ASGNF4
LABELV $785
line 2741
;2740:		//randomly go back a little
;2741:		if (random() > 0.9) {
ADDRLP4 380
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 380
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1063675494
LEF4 $791
line 2742
;2742:			VectorAdd(sideward, backward, sideward);
ADDRLP4 0
ADDRLP4 0
INDIRF4
ADDRLP4 36
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 36+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
ADDRLP4 36+8
INDIRF4
ADDF4
ASGNF4
line 2743
;2743:		}
ADDRGP4 $792
JUMPV
LABELV $791
line 2744
;2744:		else {
line 2746
;2745:			//walk forward or backward to get at the ideal attack distance
;2746:			if (dist > attack_dist + attack_range) {
ADDRLP4 68
INDIRF4
ADDRLP4 72
INDIRF4
ADDRLP4 76
INDIRF4
ADDF4
LEF4 $799
line 2747
;2747:				VectorAdd(sideward, forward, sideward);
ADDRLP4 0
ADDRLP4 0
INDIRF4
ADDRLP4 24
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 24+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
ADDRLP4 24+8
INDIRF4
ADDF4
ASGNF4
line 2748
;2748:			}
ADDRGP4 $800
JUMPV
LABELV $799
line 2749
;2749:			else if (dist < attack_dist - attack_range) {
ADDRLP4 68
INDIRF4
ADDRLP4 72
INDIRF4
ADDRLP4 76
INDIRF4
SUBF4
GEF4 $807
line 2750
;2750:				VectorAdd(sideward, backward, sideward);
ADDRLP4 0
ADDRLP4 0
INDIRF4
ADDRLP4 36
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 36+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
ADDRLP4 36+8
INDIRF4
ADDF4
ASGNF4
line 2751
;2751:			}
LABELV $807
LABELV $800
line 2752
;2752:		}
LABELV $792
line 2754
;2753:		//perform the movement
;2754:		if (trap_BotMoveInDirection(bs->ms, sideward, 400, movetype))
ADDRFP4 4
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
CNSTF4 1137180672
ARGF4
ADDRLP4 52
INDIRI4
ARGI4
ADDRLP4 384
ADDRGP4 trap_BotMoveInDirection
CALLI4
ASGNI4
ADDRLP4 384
INDIRI4
CNSTI4 0
EQI4 $815
line 2755
;2755:			return moveresult;
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
ADDRGP4 $718
JUMPV
LABELV $815
line 2757
;2756:		//movement failed, flip the strafe direction
;2757:		bs->flags ^= BFL_STRAFERIGHT;
ADDRLP4 388
ADDRFP4 4
INDIRP4
CNSTI4 5980
ADDP4
ASGNP4
ADDRLP4 388
INDIRP4
ADDRLP4 388
INDIRP4
INDIRI4
CNSTI4 1
BXORI4
ASGNI4
line 2758
;2758:		bs->attackstrafe_time = 0;
ADDRFP4 4
INDIRP4
CNSTI4 6116
ADDP4
CNSTF4 0
ASGNF4
line 2759
;2759:	}
LABELV $779
line 2731
ADDRLP4 48
ADDRLP4 48
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 48
INDIRI4
CNSTI4 2
LTI4 $778
line 2762
;2760:	//bot couldn't do any usefull movement
;2761://	bs->attackchase_time = AAS_Time() + 6;
;2762:	return moveresult;
ADDRFP4 0
INDIRP4
ADDRLP4 80
INDIRB
ASGNB 52
LABELV $718
endproc BotAttackMove 392 16
export BotSameTeam
proc BotSameTeam 2072 12
line 2770
;2763:}
;2764:
;2765:/*
;2766:==================
;2767:BotSameTeam
;2768:==================
;2769:*/
;2770:int BotSameTeam(bot_state_t *bs, int entnum) {
line 2773
;2771:	char info1[1024], info2[1024];
;2772:
;2773:	if (bs->client < 0 || bs->client >= MAX_CLIENTS) {
ADDRLP4 2048
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
ADDRLP4 2048
INDIRI4
CNSTI4 0
LTI4 $820
ADDRLP4 2048
INDIRI4
CNSTI4 64
LTI4 $818
LABELV $820
line 2775
;2774:		//BotAI_Print(PRT_ERROR, "BotSameTeam: client out of range\n");
;2775:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $817
JUMPV
LABELV $818
line 2777
;2776:	}
;2777:	if (entnum < 0 || entnum >= MAX_CLIENTS) {
ADDRLP4 2052
ADDRFP4 4
INDIRI4
ASGNI4
ADDRLP4 2052
INDIRI4
CNSTI4 0
LTI4 $823
ADDRLP4 2052
INDIRI4
CNSTI4 64
LTI4 $821
LABELV $823
line 2779
;2778:		//BotAI_Print(PRT_ERROR, "BotSameTeam: client out of range\n");
;2779:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $817
JUMPV
LABELV $821
line 2781
;2780:	}
;2781:	if ( gametype >= GT_TEAM ) {
ADDRGP4 gametype
INDIRI4
CNSTI4 3
LTI4 $824
line 2782
;2782:		trap_GetConfigstring(CS_PLAYERS+bs->client, info1, sizeof(info1));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 2783
;2783:		trap_GetConfigstring(CS_PLAYERS+entnum, info2, sizeof(info2));
ADDRFP4 4
INDIRI4
CNSTI4 544
ADDI4
ARGI4
ADDRLP4 1024
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 2785
;2784:		//
;2785:		if (atoi(Info_ValueForKey(info1, "t")) == atoi(Info_ValueForKey(info2, "t"))) return qtrue;
ADDRLP4 0
ARGP4
ADDRGP4 $67
ARGP4
ADDRLP4 2056
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 2056
INDIRP4
ARGP4
ADDRLP4 2060
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 1024
ARGP4
ADDRGP4 $67
ARGP4
ADDRLP4 2064
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 2064
INDIRP4
ARGP4
ADDRLP4 2068
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 2060
INDIRI4
ADDRLP4 2068
INDIRI4
NEI4 $826
CNSTI4 1
RETI4
ADDRGP4 $817
JUMPV
LABELV $826
line 2786
;2786:	}
LABELV $824
line 2787
;2787:	return qfalse;
CNSTI4 0
RETI4
LABELV $817
endproc BotSameTeam 2072 12
export InFieldOfVision
proc InFieldOfVision 24 4
line 2796
;2788:}
;2789:
;2790:/*
;2791:==================
;2792:InFieldOfVision
;2793:==================
;2794:*/
;2795:qboolean InFieldOfVision(vec3_t viewangles, float fov, vec3_t angles)
;2796:{
line 2800
;2797:	int i;
;2798:	float diff, angle;
;2799:
;2800:	for (i = 0; i < 2; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $829
line 2801
;2801:		angle = AngleMod(viewangles[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 0
INDIRP4
ADDP4
INDIRF4
ARGF4
ADDRLP4 12
ADDRGP4 AngleMod
CALLF4
ASGNF4
ADDRLP4 8
ADDRLP4 12
INDIRF4
ASGNF4
line 2802
;2802:		angles[i] = AngleMod(angles[i]);
ADDRLP4 16
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 8
INDIRP4
ADDP4
ASGNP4
ADDRLP4 16
INDIRP4
INDIRF4
ARGF4
ADDRLP4 20
ADDRGP4 AngleMod
CALLF4
ASGNF4
ADDRLP4 16
INDIRP4
ADDRLP4 20
INDIRF4
ASGNF4
line 2803
;2803:		diff = angles[i] - angle;
ADDRLP4 4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 8
INDIRP4
ADDP4
INDIRF4
ADDRLP4 8
INDIRF4
SUBF4
ASGNF4
line 2804
;2804:		if (angles[i] > angle) {
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 8
INDIRP4
ADDP4
INDIRF4
ADDRLP4 8
INDIRF4
LEF4 $833
line 2805
;2805:			if (diff > 180.0) diff -= 360.0;
ADDRLP4 4
INDIRF4
CNSTF4 1127481344
LEF4 $834
ADDRLP4 4
ADDRLP4 4
INDIRF4
CNSTF4 1135869952
SUBF4
ASGNF4
line 2806
;2806:		}
ADDRGP4 $834
JUMPV
LABELV $833
line 2807
;2807:		else {
line 2808
;2808:			if (diff < -180.0) diff += 360.0;
ADDRLP4 4
INDIRF4
CNSTF4 3274964992
GEF4 $837
ADDRLP4 4
ADDRLP4 4
INDIRF4
CNSTF4 1135869952
ADDF4
ASGNF4
LABELV $837
line 2809
;2809:		}
LABELV $834
line 2810
;2810:		if (diff > 0) {
ADDRLP4 4
INDIRF4
CNSTF4 0
LEF4 $839
line 2811
;2811:			if (diff > fov * 0.5) return qfalse;
ADDRLP4 4
INDIRF4
CNSTF4 1056964608
ADDRFP4 4
INDIRF4
MULF4
LEF4 $840
CNSTI4 0
RETI4
ADDRGP4 $828
JUMPV
line 2812
;2812:		}
LABELV $839
line 2813
;2813:		else {
line 2814
;2814:			if (diff < -fov * 0.5) return qfalse;
ADDRLP4 4
INDIRF4
CNSTF4 1056964608
ADDRFP4 4
INDIRF4
NEGF4
MULF4
GEF4 $843
CNSTI4 0
RETI4
ADDRGP4 $828
JUMPV
LABELV $843
line 2815
;2815:		}
LABELV $840
line 2816
;2816:	}
LABELV $830
line 2800
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 2
LTI4 $829
line 2817
;2817:	return qtrue;
CNSTI4 1
RETI4
LABELV $828
endproc InFieldOfVision 24 4
export BotEntityVisible
proc BotEntityVisible 376 28
line 2827
;2818:}
;2819:
;2820:/*
;2821:==================
;2822:BotEntityVisible
;2823:
;2824:returns visibility in the range [0, 1] taking fog and water surfaces into account
;2825:==================
;2826:*/
;2827:float BotEntityVisible(int viewer, vec3_t eye, vec3_t viewangles, float fov, int ent) {
line 2835
;2828:	int i, contents_mask, passent, hitent, infog, inwater, otherinfog, pc;
;2829:	float squaredfogdist, waterfactor, vis, bestvis;
;2830:	bsp_trace_t trace;
;2831:	aas_entityinfo_t entinfo;
;2832:	vec3_t dir, entangles, start, end, middle;
;2833:
;2834:	//calculate middle of bounding box
;2835:	BotEntityInfo(ent, &entinfo);
ADDRFP4 16
INDIRI4
ARGI4
ADDRLP4 148
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 2836
;2836:	VectorAdd(entinfo.mins, entinfo.maxs, middle);
ADDRLP4 84
ADDRLP4 148+72
INDIRF4
ADDRLP4 148+84
INDIRF4
ADDF4
ASGNF4
ADDRLP4 84+4
ADDRLP4 148+72+4
INDIRF4
ADDRLP4 148+84+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 84+8
ADDRLP4 148+72+8
INDIRF4
ADDRLP4 148+84+8
INDIRF4
ADDF4
ASGNF4
line 2837
;2837:	VectorScale(middle, 0.5, middle);
ADDRLP4 332
CNSTF4 1056964608
ASGNF4
ADDRLP4 84
ADDRLP4 332
INDIRF4
ADDRLP4 84
INDIRF4
MULF4
ASGNF4
ADDRLP4 84+4
ADDRLP4 332
INDIRF4
ADDRLP4 84+4
INDIRF4
MULF4
ASGNF4
ADDRLP4 84+8
CNSTF4 1056964608
ADDRLP4 84+8
INDIRF4
MULF4
ASGNF4
line 2838
;2838:	VectorAdd(entinfo.origin, middle, middle);
ADDRLP4 84
ADDRLP4 148+24
INDIRF4
ADDRLP4 84
INDIRF4
ADDF4
ASGNF4
ADDRLP4 84+4
ADDRLP4 148+24+4
INDIRF4
ADDRLP4 84+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 84+8
ADDRLP4 148+24+8
INDIRF4
ADDRLP4 84+8
INDIRF4
ADDF4
ASGNF4
line 2840
;2839:	//check if entity is within field of vision
;2840:	VectorSubtract(middle, eye, dir);
ADDRLP4 336
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 136
ADDRLP4 84
INDIRF4
ADDRLP4 336
INDIRP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+4
ADDRLP4 84+4
INDIRF4
ADDRLP4 336
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+8
ADDRLP4 84+8
INDIRF4
ADDRFP4 4
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
SUBF4
ASGNF4
line 2841
;2841:	vectoangles(dir, entangles);
ADDRLP4 136
ARGP4
ADDRLP4 320
ARGP4
ADDRGP4 vectoangles
CALLV
pop
line 2842
;2842:	if (!InFieldOfVision(viewangles, fov, entangles)) return 0;
ADDRFP4 8
INDIRP4
ARGP4
ADDRFP4 12
INDIRF4
ARGF4
ADDRLP4 320
ARGP4
ADDRLP4 340
ADDRGP4 InFieldOfVision
CALLI4
ASGNI4
ADDRLP4 340
INDIRI4
CNSTI4 0
NEI4 $875
CNSTF4 0
RETF4
ADDRGP4 $845
JUMPV
LABELV $875
line 2844
;2843:	//
;2844:	pc = trap_AAS_PointContents(eye);
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 344
ADDRGP4 trap_AAS_PointContents
CALLI4
ASGNI4
ADDRLP4 316
ADDRLP4 344
INDIRI4
ASGNI4
line 2845
;2845:	infog = (pc & CONTENTS_FOG);
ADDRLP4 312
ADDRLP4 316
INDIRI4
CNSTI4 64
BANDI4
ASGNI4
line 2846
;2846:	inwater = (pc & (CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER));
ADDRLP4 308
ADDRLP4 316
INDIRI4
CNSTI4 56
BANDI4
ASGNI4
line 2848
;2847:	//
;2848:	bestvis = 0;
ADDRLP4 296
CNSTF4 0
ASGNF4
line 2849
;2849:	for (i = 0; i < 3; i++) {
ADDRLP4 100
CNSTI4 0
ASGNI4
LABELV $877
line 2853
;2850:		//if the point is not in potential visible sight
;2851:		//if (!AAS_inPVS(eye, middle)) continue;
;2852:		//
;2853:		contents_mask = CONTENTS_SOLID|CONTENTS_PLAYERCLIP;
ADDRLP4 96
CNSTI4 65537
ASGNI4
line 2854
;2854:		passent = viewer;
ADDRLP4 116
ADDRFP4 0
INDIRI4
ASGNI4
line 2855
;2855:		hitent = ent;
ADDRLP4 132
ADDRFP4 16
INDIRI4
ASGNI4
line 2856
;2856:		VectorCopy(eye, start);
ADDRLP4 120
ADDRFP4 4
INDIRP4
INDIRB
ASGNB 12
line 2857
;2857:		VectorCopy(middle, end);
ADDRLP4 104
ADDRLP4 84
INDIRB
ASGNB 12
line 2859
;2858:		//if the entity is in water, lava or slime
;2859:		if (trap_AAS_PointContents(middle) & (CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER)) {
ADDRLP4 84
ARGP4
ADDRLP4 348
ADDRGP4 trap_AAS_PointContents
CALLI4
ASGNI4
ADDRLP4 348
INDIRI4
CNSTI4 56
BANDI4
CNSTI4 0
EQI4 $881
line 2860
;2860:			contents_mask |= (CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER);
ADDRLP4 96
ADDRLP4 96
INDIRI4
CNSTI4 56
BORI4
ASGNI4
line 2861
;2861:		}
LABELV $881
line 2863
;2862:		//if eye is in water, lava or slime
;2863:		if (inwater) {
ADDRLP4 308
INDIRI4
CNSTI4 0
EQI4 $883
line 2864
;2864:			if (!(contents_mask & (CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER))) {
ADDRLP4 96
INDIRI4
CNSTI4 56
BANDI4
CNSTI4 0
NEI4 $885
line 2865
;2865:				passent = ent;
ADDRLP4 116
ADDRFP4 16
INDIRI4
ASGNI4
line 2866
;2866:				hitent = viewer;
ADDRLP4 132
ADDRFP4 0
INDIRI4
ASGNI4
line 2867
;2867:				VectorCopy(middle, start);
ADDRLP4 120
ADDRLP4 84
INDIRB
ASGNB 12
line 2868
;2868:				VectorCopy(eye, end);
ADDRLP4 104
ADDRFP4 4
INDIRP4
INDIRB
ASGNB 12
line 2869
;2869:			}
LABELV $885
line 2870
;2870:			contents_mask ^= (CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER);
ADDRLP4 96
ADDRLP4 96
INDIRI4
CNSTI4 56
BXORI4
ASGNI4
line 2871
;2871:		}
LABELV $883
line 2873
;2872:		//trace from start to end
;2873:		BotAI_Trace(&trace, start, NULL, NULL, end, passent, contents_mask);
ADDRLP4 0
ARGP4
ADDRLP4 120
ARGP4
ADDRLP4 352
CNSTP4 0
ASGNP4
ADDRLP4 352
INDIRP4
ARGP4
ADDRLP4 352
INDIRP4
ARGP4
ADDRLP4 104
ARGP4
ADDRLP4 116
INDIRI4
ARGI4
ADDRLP4 96
INDIRI4
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 2875
;2874:		//if water was hit
;2875:		waterfactor = 1.0;
ADDRLP4 288
CNSTF4 1065353216
ASGNF4
line 2876
;2876:		if (trace.contents & (CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER)) {
ADDRLP4 0+76
INDIRI4
CNSTI4 56
BANDI4
CNSTI4 0
EQI4 $887
line 2878
;2877:			//if the water surface is translucent
;2878:			if (1) {
line 2880
;2879:				//trace through the water
;2880:				contents_mask &= ~(CONTENTS_LAVA|CONTENTS_SLIME|CONTENTS_WATER);
ADDRLP4 96
ADDRLP4 96
INDIRI4
CNSTI4 -57
BANDI4
ASGNI4
line 2881
;2881:				BotAI_Trace(&trace, trace.endpos, NULL, NULL, end, passent, contents_mask);
ADDRLP4 0
ARGP4
ADDRLP4 0+12
ARGP4
ADDRLP4 356
CNSTP4 0
ASGNP4
ADDRLP4 356
INDIRP4
ARGP4
ADDRLP4 356
INDIRP4
ARGP4
ADDRLP4 104
ARGP4
ADDRLP4 116
INDIRI4
ARGI4
ADDRLP4 96
INDIRI4
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 2882
;2882:				waterfactor = 0.5;
ADDRLP4 288
CNSTF4 1056964608
ASGNF4
line 2883
;2883:			}
LABELV $890
line 2884
;2884:		}
LABELV $887
line 2886
;2885:		//if a full trace or the hitent was hit
;2886:		if (trace.fraction >= 1 || trace.ent == hitent) {
ADDRLP4 0+8
INDIRF4
CNSTF4 1065353216
GEF4 $897
ADDRLP4 0+80
INDIRI4
ADDRLP4 132
INDIRI4
NEI4 $893
LABELV $897
line 2889
;2887:			//check for fog, assuming there's only one fog brush where
;2888:			//either the viewer or the entity is in or both are in
;2889:			otherinfog = (trap_AAS_PointContents(middle) & CONTENTS_FOG);
ADDRLP4 84
ARGP4
ADDRLP4 356
ADDRGP4 trap_AAS_PointContents
CALLI4
ASGNI4
ADDRLP4 304
ADDRLP4 356
INDIRI4
CNSTI4 64
BANDI4
ASGNI4
line 2890
;2890:			if (infog && otherinfog) {
ADDRLP4 360
CNSTI4 0
ASGNI4
ADDRLP4 312
INDIRI4
ADDRLP4 360
INDIRI4
EQI4 $898
ADDRLP4 304
INDIRI4
ADDRLP4 360
INDIRI4
EQI4 $898
line 2891
;2891:				VectorSubtract(trace.endpos, eye, dir);
ADDRLP4 364
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 136
ADDRLP4 0+12
INDIRF4
ADDRLP4 364
INDIRP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+4
ADDRLP4 0+12+4
INDIRF4
ADDRLP4 364
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+8
ADDRLP4 0+12+8
INDIRF4
ADDRFP4 4
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
SUBF4
ASGNF4
line 2892
;2892:				squaredfogdist = VectorLengthSquared(dir);
ADDRLP4 136
ARGP4
ADDRLP4 368
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 300
ADDRLP4 368
INDIRF4
ASGNF4
line 2893
;2893:			}
ADDRGP4 $899
JUMPV
LABELV $898
line 2894
;2894:			else if (infog) {
ADDRLP4 312
INDIRI4
CNSTI4 0
EQI4 $907
line 2895
;2895:				VectorCopy(trace.endpos, start);
ADDRLP4 120
ADDRLP4 0+12
INDIRB
ASGNB 12
line 2896
;2896:				BotAI_Trace(&trace, start, NULL, NULL, eye, viewer, CONTENTS_FOG);
ADDRLP4 0
ARGP4
ADDRLP4 120
ARGP4
ADDRLP4 364
CNSTP4 0
ASGNP4
ADDRLP4 364
INDIRP4
ARGP4
ADDRLP4 364
INDIRP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRFP4 0
INDIRI4
ARGI4
CNSTI4 64
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 2897
;2897:				VectorSubtract(eye, trace.endpos, dir);
ADDRLP4 368
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 136
ADDRLP4 368
INDIRP4
INDIRF4
ADDRLP4 0+12
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+4
ADDRLP4 368
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
ADDRLP4 0+12+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+8
ADDRFP4 4
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
ADDRLP4 0+12+8
INDIRF4
SUBF4
ASGNF4
line 2898
;2898:				squaredfogdist = VectorLengthSquared(dir);
ADDRLP4 136
ARGP4
ADDRLP4 372
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 300
ADDRLP4 372
INDIRF4
ASGNF4
line 2899
;2899:			}
ADDRGP4 $908
JUMPV
LABELV $907
line 2900
;2900:			else if (otherinfog) {
ADDRLP4 304
INDIRI4
CNSTI4 0
EQI4 $917
line 2901
;2901:				VectorCopy(trace.endpos, end);
ADDRLP4 104
ADDRLP4 0+12
INDIRB
ASGNB 12
line 2902
;2902:				BotAI_Trace(&trace, eye, NULL, NULL, end, viewer, CONTENTS_FOG);
ADDRLP4 0
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 364
CNSTP4 0
ASGNP4
ADDRLP4 364
INDIRP4
ARGP4
ADDRLP4 364
INDIRP4
ARGP4
ADDRLP4 104
ARGP4
ADDRFP4 0
INDIRI4
ARGI4
CNSTI4 64
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 2903
;2903:				VectorSubtract(end, trace.endpos, dir);
ADDRLP4 136
ADDRLP4 104
INDIRF4
ADDRLP4 0+12
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+4
ADDRLP4 104+4
INDIRF4
ADDRLP4 0+12+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 136+8
ADDRLP4 104+8
INDIRF4
ADDRLP4 0+12+8
INDIRF4
SUBF4
ASGNF4
line 2904
;2904:				squaredfogdist = VectorLengthSquared(dir);
ADDRLP4 136
ARGP4
ADDRLP4 368
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 300
ADDRLP4 368
INDIRF4
ASGNF4
line 2905
;2905:			}
ADDRGP4 $918
JUMPV
LABELV $917
line 2906
;2906:			else {
line 2908
;2907:				//if the entity and the viewer are not in fog assume there's no fog in between
;2908:				squaredfogdist = 0;
ADDRLP4 300
CNSTF4 0
ASGNF4
line 2909
;2909:			}
LABELV $918
LABELV $908
LABELV $899
line 2911
;2910:			//decrease visibility with the view distance through fog
;2911:			vis = 1 / ((squaredfogdist * 0.001) < 1 ? 1 : (squaredfogdist * 0.001));
ADDRLP4 368
CNSTF4 1065353216
ASGNF4
CNSTF4 981668463
ADDRLP4 300
INDIRF4
MULF4
ADDRLP4 368
INDIRF4
GEF4 $930
ADDRLP4 364
CNSTF4 1065353216
ASGNF4
ADDRGP4 $931
JUMPV
LABELV $930
ADDRLP4 364
CNSTF4 981668463
ADDRLP4 300
INDIRF4
MULF4
ASGNF4
LABELV $931
ADDRLP4 292
ADDRLP4 368
INDIRF4
ADDRLP4 364
INDIRF4
DIVF4
ASGNF4
line 2913
;2912:			//if entering water visibility is reduced
;2913:			vis *= waterfactor;
ADDRLP4 292
ADDRLP4 292
INDIRF4
ADDRLP4 288
INDIRF4
MULF4
ASGNF4
line 2915
;2914:			//
;2915:			if (vis > bestvis) bestvis = vis;
ADDRLP4 292
INDIRF4
ADDRLP4 296
INDIRF4
LEF4 $932
ADDRLP4 296
ADDRLP4 292
INDIRF4
ASGNF4
LABELV $932
line 2917
;2916:			//if pretty much no fog
;2917:			if (bestvis >= 0.95) return bestvis;
ADDRLP4 296
INDIRF4
CNSTF4 1064514355
LTF4 $934
ADDRLP4 296
INDIRF4
RETF4
ADDRGP4 $845
JUMPV
LABELV $934
line 2918
;2918:		}
LABELV $893
line 2920
;2919:		//check bottom and top of bounding box as well
;2920:		if (i == 0) middle[2] += entinfo.mins[2];
ADDRLP4 100
INDIRI4
CNSTI4 0
NEI4 $936
ADDRLP4 84+8
ADDRLP4 84+8
INDIRF4
ADDRLP4 148+72+8
INDIRF4
ADDF4
ASGNF4
ADDRGP4 $937
JUMPV
LABELV $936
line 2921
;2921:		else if (i == 1) middle[2] += entinfo.maxs[2] - entinfo.mins[2];
ADDRLP4 100
INDIRI4
CNSTI4 1
NEI4 $941
ADDRLP4 84+8
ADDRLP4 84+8
INDIRF4
ADDRLP4 148+84+8
INDIRF4
ADDRLP4 148+72+8
INDIRF4
SUBF4
ADDF4
ASGNF4
LABELV $941
LABELV $937
line 2922
;2922:	}
LABELV $878
line 2849
ADDRLP4 100
ADDRLP4 100
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 100
INDIRI4
CNSTI4 3
LTI4 $877
line 2923
;2923:	return bestvis;
ADDRLP4 296
INDIRF4
RETF4
LABELV $845
endproc BotEntityVisible 376 28
export BotFindEnemy
proc BotFindEnemy 432 20
line 2931
;2924:}
;2925:
;2926:/*
;2927:==================
;2928:BotFindEnemy
;2929:==================
;2930:*/
;2931:int BotFindEnemy(bot_state_t *bs, int curenemy) {
line 2938
;2932:	int i, healthdecrease;
;2933:	float f, alertness, easyfragger, vis;
;2934:	float squaredist, cursquaredist;
;2935:	aas_entityinfo_t entinfo, curenemyinfo;
;2936:	vec3_t dir, angles;
;2937:
;2938:	alertness = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_ALERTNESS, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 46
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 336
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 164
ADDRLP4 336
INDIRF4
ASGNF4
line 2939
;2939:	easyfragger = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_EASY_FRAGGER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 45
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 340
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 176
ADDRLP4 340
INDIRF4
ASGNF4
line 2941
;2940:	//check if the health decreased
;2941:	healthdecrease = bs->lasthealth > bs->inventory[INVENTORY_HEALTH];
ADDRLP4 348
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 348
INDIRP4
CNSTI4 5988
ADDP4
INDIRI4
ADDRLP4 348
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
LEI4 $950
ADDRLP4 344
CNSTI4 1
ASGNI4
ADDRGP4 $951
JUMPV
LABELV $950
ADDRLP4 344
CNSTI4 0
ASGNI4
LABELV $951
ADDRLP4 160
ADDRLP4 344
INDIRI4
ASGNI4
line 2943
;2942:	//remember the current health value
;2943:	bs->lasthealth = bs->inventory[INVENTORY_HEALTH];
ADDRLP4 352
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 352
INDIRP4
CNSTI4 5988
ADDP4
ADDRLP4 352
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
ASGNI4
line 2945
;2944:	//
;2945:	if (curenemy >= 0) {
ADDRFP4 4
INDIRI4
CNSTI4 0
LTI4 $952
line 2946
;2946:		BotEntityInfo(curenemy, &curenemyinfo);
ADDRFP4 4
INDIRI4
ARGI4
ADDRLP4 196
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 2947
;2947:		if (EntityCarriesFlag(&curenemyinfo)) return qfalse;
ADDRLP4 196
ARGP4
ADDRLP4 356
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 356
INDIRI4
CNSTI4 0
EQI4 $954
CNSTI4 0
RETI4
ADDRGP4 $948
JUMPV
LABELV $954
line 2948
;2948:		VectorSubtract(curenemyinfo.origin, bs->origin, dir);
ADDRLP4 360
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 144
ADDRLP4 196+24
INDIRF4
ADDRLP4 360
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+4
ADDRLP4 196+24+4
INDIRF4
ADDRLP4 360
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+8
ADDRLP4 196+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 2949
;2949:		cursquaredist = VectorLengthSquared(dir);
ADDRLP4 144
ARGP4
ADDRLP4 364
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 192
ADDRLP4 364
INDIRF4
ASGNF4
line 2950
;2950:	}
ADDRGP4 $953
JUMPV
LABELV $952
line 2951
;2951:	else {
line 2952
;2952:		cursquaredist = 0;
ADDRLP4 192
CNSTF4 0
ASGNF4
line 2953
;2953:	}
LABELV $953
line 2982
;2954:#ifdef MISSIONPACK
;2955:	if (gametype == GT_OBELISK) {
;2956:		vec3_t target;
;2957:		bot_goal_t *goal;
;2958:		bsp_trace_t trace;
;2959:
;2960:		if (BotTeam(bs) == TEAM_RED)
;2961:			goal = &blueobelisk;
;2962:		else
;2963:			goal = &redobelisk;
;2964:		//if the obelisk is visible
;2965:		VectorCopy(goal->origin, target);
;2966:		target[2] += 1;
;2967:		BotAI_Trace(&trace, bs->eye, NULL, NULL, target, bs->client, CONTENTS_SOLID);
;2968:		if (trace.fraction >= 1 || trace.ent == goal->entitynum) {
;2969:			if (goal->entitynum == bs->enemy) {
;2970:				return qfalse;
;2971:			}
;2972:			bs->enemy = goal->entitynum;
;2973:			bs->enemysight_time = FloatTime();
;2974:			bs->enemysuicide = qfalse;
;2975:			bs->enemydeath_time = 0;
;2976:			bs->enemyvisible_time = FloatTime();
;2977:			return qtrue;
;2978:		}
;2979:	}
;2980:#endif
;2981:	//
;2982:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 140
CNSTI4 0
ASGNI4
ADDRGP4 $966
JUMPV
LABELV $963
line 2984
;2983:
;2984:		if (i == bs->client) continue;
ADDRLP4 140
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $967
ADDRGP4 $964
JUMPV
LABELV $967
line 2986
;2985:		//if it's the current enemy
;2986:		if (i == curenemy) continue;
ADDRLP4 140
INDIRI4
ADDRFP4 4
INDIRI4
NEI4 $969
ADDRGP4 $964
JUMPV
LABELV $969
line 2988
;2987:		//
;2988:		BotEntityInfo(i, &entinfo);
ADDRLP4 140
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 2990
;2989:		//
;2990:		if (!entinfo.valid) continue;
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $971
ADDRGP4 $964
JUMPV
LABELV $971
line 2992
;2991:		//if the enemy isn't dead and the enemy isn't the bot self
;2992:		if (EntityIsDead(&entinfo) || entinfo.number == bs->entitynum) continue;
ADDRLP4 0
ARGP4
ADDRLP4 356
ADDRGP4 EntityIsDead
CALLI4
ASGNI4
ADDRLP4 356
INDIRI4
CNSTI4 0
NEI4 $976
ADDRLP4 0+20
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
NEI4 $973
LABELV $976
ADDRGP4 $964
JUMPV
LABELV $973
line 2994
;2993:		//if the enemy is invisible and not shooting
;2994:		if (EntityIsInvisible(&entinfo) && !EntityIsShooting(&entinfo)) {
ADDRLP4 0
ARGP4
ADDRLP4 360
ADDRGP4 EntityIsInvisible
CALLI4
ASGNI4
ADDRLP4 360
INDIRI4
CNSTI4 0
EQI4 $977
ADDRLP4 0
ARGP4
ADDRLP4 364
ADDRGP4 EntityIsShooting
CALLI4
ASGNI4
ADDRLP4 364
INDIRI4
CNSTI4 0
NEI4 $977
line 2995
;2995:			continue;
ADDRGP4 $964
JUMPV
LABELV $977
line 2998
;2996:		}
;2997:		//if not an easy fragger don't shoot at chatting players
;2998:		if (easyfragger < 0.5 && EntityIsChatting(&entinfo)) continue;
ADDRLP4 176
INDIRF4
CNSTF4 1056964608
GEF4 $979
ADDRLP4 0
ARGP4
ADDRLP4 368
ADDRGP4 EntityIsChatting
CALLI4
ASGNI4
ADDRLP4 368
INDIRI4
CNSTI4 0
EQI4 $979
ADDRGP4 $964
JUMPV
LABELV $979
line 3000
;2999:		//
;3000:		if (lastteleport_time > FloatTime() - 3) {
ADDRGP4 lastteleport_time
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1077936128
SUBF4
LEF4 $981
line 3001
;3001:			VectorSubtract(entinfo.origin, lastteleport_origin, dir);
ADDRLP4 144
ADDRLP4 0+24
INDIRF4
ADDRGP4 lastteleport_origin
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+4
ADDRLP4 0+24+4
INDIRF4
ADDRGP4 lastteleport_origin+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+8
ADDRLP4 0+24+8
INDIRF4
ADDRGP4 lastteleport_origin+8
INDIRF4
SUBF4
ASGNF4
line 3002
;3002:			if (VectorLengthSquared(dir) < Square(70)) continue;
ADDRLP4 144
ARGP4
ADDRLP4 372
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 372
INDIRF4
CNSTF4 1167663104
GEF4 $992
ADDRGP4 $964
JUMPV
LABELV $992
line 3003
;3003:		}
LABELV $981
line 3005
;3004:		//calculate the distance towards the enemy
;3005:		VectorSubtract(entinfo.origin, bs->origin, dir);
ADDRLP4 372
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 144
ADDRLP4 0+24
INDIRF4
ADDRLP4 372
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 372
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+8
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3006
;3006:		squaredist = VectorLengthSquared(dir);
ADDRLP4 144
ARGP4
ADDRLP4 376
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 376
INDIRF4
ASGNF4
line 3008
;3007:		//if this entity is not carrying a flag
;3008:		if (!EntityCarriesFlag(&entinfo))
ADDRLP4 0
ARGP4
ADDRLP4 380
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 380
INDIRI4
CNSTI4 0
NEI4 $1001
line 3009
;3009:		{
line 3011
;3010:			//if this enemy is further away than the current one
;3011:			if (curenemy >= 0 && squaredist > cursquaredist) continue;
ADDRFP4 4
INDIRI4
CNSTI4 0
LTI4 $1003
ADDRLP4 156
INDIRF4
ADDRLP4 192
INDIRF4
LEF4 $1003
ADDRGP4 $964
JUMPV
LABELV $1003
line 3012
;3012:		} //end if
LABELV $1001
line 3014
;3013:		//if the bot has no
;3014:		if (squaredist > Square(900.0 + alertness * 4000.0)) continue;
ADDRLP4 384
CNSTF4 1165623296
ADDRLP4 164
INDIRF4
MULF4
CNSTF4 1147207680
ADDF4
ASGNF4
ADDRLP4 156
INDIRF4
ADDRLP4 384
INDIRF4
ADDRLP4 384
INDIRF4
MULF4
LEF4 $1005
ADDRGP4 $964
JUMPV
LABELV $1005
line 3016
;3015:		//if on the same team
;3016:		if (BotSameTeam(bs, i)) continue;
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
INDIRI4
ARGI4
ADDRLP4 388
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 388
INDIRI4
CNSTI4 0
EQI4 $1007
ADDRGP4 $964
JUMPV
LABELV $1007
line 3018
;3017:		//if the bot's health decreased or the enemy is shooting
;3018:		if (curenemy < 0 && (healthdecrease || EntityIsShooting(&entinfo)))
ADDRLP4 392
CNSTI4 0
ASGNI4
ADDRFP4 4
INDIRI4
ADDRLP4 392
INDIRI4
GEI4 $1009
ADDRLP4 160
INDIRI4
ADDRLP4 392
INDIRI4
NEI4 $1011
ADDRLP4 0
ARGP4
ADDRLP4 396
ADDRGP4 EntityIsShooting
CALLI4
ASGNI4
ADDRLP4 396
INDIRI4
CNSTI4 0
EQI4 $1009
LABELV $1011
line 3019
;3019:			f = 360;
ADDRLP4 168
CNSTF4 1135869952
ASGNF4
ADDRGP4 $1010
JUMPV
LABELV $1009
line 3021
;3020:		else
;3021:			f = 90 + 90 - (90 - (squaredist > Square(810) ? Square(810) : squaredist) / (810 * 9));
ADDRLP4 156
INDIRF4
CNSTF4 1226845760
LEF4 $1013
ADDRLP4 400
CNSTF4 1226845760
ASGNF4
ADDRGP4 $1014
JUMPV
LABELV $1013
ADDRLP4 400
ADDRLP4 156
INDIRF4
ASGNF4
LABELV $1014
ADDRLP4 168
CNSTF4 1127481344
CNSTF4 1119092736
ADDRLP4 400
INDIRF4
CNSTF4 1172557824
DIVF4
SUBF4
SUBF4
ASGNF4
LABELV $1010
line 3023
;3022:		//check if the enemy is visible
;3023:		vis = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, f, i);
ADDRLP4 404
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 404
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 404
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 404
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
ADDRLP4 168
INDIRF4
ARGF4
ADDRLP4 140
INDIRI4
ARGI4
ADDRLP4 408
ADDRGP4 BotEntityVisible
CALLF4
ASGNF4
ADDRLP4 172
ADDRLP4 408
INDIRF4
ASGNF4
line 3024
;3024:		if (vis <= 0) continue;
ADDRLP4 172
INDIRF4
CNSTF4 0
GTF4 $1015
ADDRGP4 $964
JUMPV
LABELV $1015
line 3026
;3025:		//if the enemy is quite far away, not shooting and the bot is not damaged
;3026:		if (curenemy < 0 && squaredist > Square(100) && !healthdecrease && !EntityIsShooting(&entinfo))
ADDRLP4 412
CNSTI4 0
ASGNI4
ADDRFP4 4
INDIRI4
ADDRLP4 412
INDIRI4
GEI4 $1017
ADDRLP4 156
INDIRF4
CNSTF4 1176256512
LEF4 $1017
ADDRLP4 160
INDIRI4
ADDRLP4 412
INDIRI4
NEI4 $1017
ADDRLP4 0
ARGP4
ADDRLP4 416
ADDRGP4 EntityIsShooting
CALLI4
ASGNI4
ADDRLP4 416
INDIRI4
CNSTI4 0
NEI4 $1017
line 3027
;3027:		{
line 3029
;3028:			//check if we can avoid this enemy
;3029:			VectorSubtract(bs->origin, entinfo.origin, dir);
ADDRLP4 420
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 144
ADDRLP4 420
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
ADDRLP4 0+24
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+4
ADDRLP4 420
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
ADDRLP4 0+24+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+8
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
ADDRLP4 0+24+8
INDIRF4
SUBF4
ASGNF4
line 3030
;3030:			vectoangles(dir, angles);
ADDRLP4 144
ARGP4
ADDRLP4 180
ARGP4
ADDRGP4 vectoangles
CALLV
pop
line 3032
;3031:			//if the bot isn't in the fov of the enemy
;3032:			if (!InFieldOfVision(entinfo.angles, 90, angles)) {
ADDRLP4 0+36
ARGP4
CNSTF4 1119092736
ARGF4
ADDRLP4 180
ARGP4
ADDRLP4 424
ADDRGP4 InFieldOfVision
CALLI4
ASGNI4
ADDRLP4 424
INDIRI4
CNSTI4 0
NEI4 $1026
line 3034
;3033:				//update some stuff for this enemy
;3034:				BotUpdateBattleInventory(bs, i);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
INDIRI4
ARGI4
ADDRGP4 BotUpdateBattleInventory
CALLV
pop
line 3036
;3035:				//if the bot doesn't really want to fight
;3036:				if (BotWantsToRetreat(bs)) continue;
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 428
ADDRGP4 BotWantsToRetreat
CALLI4
ASGNI4
ADDRLP4 428
INDIRI4
CNSTI4 0
EQI4 $1029
ADDRGP4 $964
JUMPV
LABELV $1029
line 3037
;3037:			}
LABELV $1026
line 3038
;3038:		}
LABELV $1017
line 3040
;3039:		//found an enemy
;3040:		bs->enemy = entinfo.number;
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
ADDRLP4 0+20
INDIRI4
ASGNI4
line 3041
;3041:		if (curenemy >= 0) bs->enemysight_time = FloatTime() - 2;
ADDRFP4 4
INDIRI4
CNSTI4 0
LTI4 $1032
ADDRFP4 0
INDIRP4
CNSTI4 6132
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1073741824
SUBF4
ASGNF4
ADDRGP4 $1033
JUMPV
LABELV $1032
line 3042
;3042:		else bs->enemysight_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6132
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
LABELV $1033
line 3043
;3043:		bs->enemysuicide = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6012
ADDP4
CNSTI4 0
ASGNI4
line 3044
;3044:		bs->enemydeath_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6136
ADDP4
CNSTF4 0
ASGNF4
line 3045
;3045:		bs->enemyvisible_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6088
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 3046
;3046:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $948
JUMPV
LABELV $964
line 2982
ADDRLP4 140
ADDRLP4 140
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $966
ADDRLP4 140
INDIRI4
ADDRGP4 maxclients
INDIRI4
GEI4 $1034
ADDRLP4 140
INDIRI4
CNSTI4 64
LTI4 $963
LABELV $1034
line 3048
;3047:	}
;3048:	return qfalse;
CNSTI4 0
RETI4
LABELV $948
endproc BotFindEnemy 432 20
export BotTeamFlagCarrierVisible
proc BotTeamFlagCarrierVisible 164 20
line 3056
;3049:}
;3050:
;3051:/*
;3052:==================
;3053:BotTeamFlagCarrierVisible
;3054:==================
;3055:*/
;3056:int BotTeamFlagCarrierVisible(bot_state_t *bs) {
line 3061
;3057:	int i;
;3058:	float vis;
;3059:	aas_entityinfo_t entinfo;
;3060:
;3061:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1039
JUMPV
LABELV $1036
line 3062
;3062:		if (i == bs->client)
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $1040
line 3063
;3063:			continue;
ADDRGP4 $1037
JUMPV
LABELV $1040
line 3065
;3064:		//
;3065:		BotEntityInfo(i, &entinfo);
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3067
;3066:		//if this player is active
;3067:		if (!entinfo.valid)
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $1042
line 3068
;3068:			continue;
ADDRGP4 $1037
JUMPV
LABELV $1042
line 3070
;3069:		//if this player is carrying a flag
;3070:		if (!EntityCarriesFlag(&entinfo))
ADDRLP4 4
ARGP4
ADDRLP4 148
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
NEI4 $1044
line 3071
;3071:			continue;
ADDRGP4 $1037
JUMPV
LABELV $1044
line 3073
;3072:		//if the flag carrier is not on the same team
;3073:		if (!BotSameTeam(bs, i))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 152
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 152
INDIRI4
CNSTI4 0
NEI4 $1046
line 3074
;3074:			continue;
ADDRGP4 $1037
JUMPV
LABELV $1046
line 3076
;3075:		//if the flag carrier is not visible
;3076:		vis = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, 360, i);
ADDRLP4 156
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 156
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 156
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 156
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
CNSTF4 1135869952
ARGF4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 160
ADDRGP4 BotEntityVisible
CALLF4
ASGNF4
ADDRLP4 144
ADDRLP4 160
INDIRF4
ASGNF4
line 3077
;3077:		if (vis <= 0)
ADDRLP4 144
INDIRF4
CNSTF4 0
GTF4 $1048
line 3078
;3078:			continue;
ADDRGP4 $1037
JUMPV
LABELV $1048
line 3080
;3079:		//
;3080:		return i;
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $1035
JUMPV
LABELV $1037
line 3061
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1039
ADDRLP4 0
INDIRI4
ADDRGP4 maxclients
INDIRI4
GEI4 $1050
ADDRLP4 0
INDIRI4
CNSTI4 64
LTI4 $1036
LABELV $1050
line 3082
;3081:	}
;3082:	return -1;
CNSTI4 -1
RETI4
LABELV $1035
endproc BotTeamFlagCarrierVisible 164 20
export BotTeamFlagCarrier
proc BotTeamFlagCarrier 152 8
line 3090
;3083:}
;3084:
;3085:/*
;3086:==================
;3087:BotTeamFlagCarrier
;3088:==================
;3089:*/
;3090:int BotTeamFlagCarrier(bot_state_t *bs) {
line 3094
;3091:	int i;
;3092:	aas_entityinfo_t entinfo;
;3093:
;3094:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1055
JUMPV
LABELV $1052
line 3095
;3095:		if (i == bs->client)
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $1056
line 3096
;3096:			continue;
ADDRGP4 $1053
JUMPV
LABELV $1056
line 3098
;3097:		//
;3098:		BotEntityInfo(i, &entinfo);
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3100
;3099:		//if this player is active
;3100:		if (!entinfo.valid)
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $1058
line 3101
;3101:			continue;
ADDRGP4 $1053
JUMPV
LABELV $1058
line 3103
;3102:		//if this player is carrying a flag
;3103:		if (!EntityCarriesFlag(&entinfo))
ADDRLP4 4
ARGP4
ADDRLP4 144
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 144
INDIRI4
CNSTI4 0
NEI4 $1060
line 3104
;3104:			continue;
ADDRGP4 $1053
JUMPV
LABELV $1060
line 3106
;3105:		//if the flag carrier is not on the same team
;3106:		if (!BotSameTeam(bs, i))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 148
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
NEI4 $1062
line 3107
;3107:			continue;
ADDRGP4 $1053
JUMPV
LABELV $1062
line 3109
;3108:		//
;3109:		return i;
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $1051
JUMPV
LABELV $1053
line 3094
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1055
ADDRLP4 0
INDIRI4
ADDRGP4 maxclients
INDIRI4
GEI4 $1064
ADDRLP4 0
INDIRI4
CNSTI4 64
LTI4 $1052
LABELV $1064
line 3111
;3110:	}
;3111:	return -1;
CNSTI4 -1
RETI4
LABELV $1051
endproc BotTeamFlagCarrier 152 8
export BotEnemyFlagCarrierVisible
proc BotEnemyFlagCarrierVisible 164 20
line 3119
;3112:}
;3113:
;3114:/*
;3115:==================
;3116:BotEnemyFlagCarrierVisible
;3117:==================
;3118:*/
;3119:int BotEnemyFlagCarrierVisible(bot_state_t *bs) {
line 3124
;3120:	int i;
;3121:	float vis;
;3122:	aas_entityinfo_t entinfo;
;3123:
;3124:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1069
JUMPV
LABELV $1066
line 3125
;3125:		if (i == bs->client)
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $1070
line 3126
;3126:			continue;
ADDRGP4 $1067
JUMPV
LABELV $1070
line 3128
;3127:		//
;3128:		BotEntityInfo(i, &entinfo);
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3130
;3129:		//if this player is active
;3130:		if (!entinfo.valid)
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $1072
line 3131
;3131:			continue;
ADDRGP4 $1067
JUMPV
LABELV $1072
line 3133
;3132:		//if this player is carrying a flag
;3133:		if (!EntityCarriesFlag(&entinfo))
ADDRLP4 4
ARGP4
ADDRLP4 148
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
NEI4 $1074
line 3134
;3134:			continue;
ADDRGP4 $1067
JUMPV
LABELV $1074
line 3136
;3135:		//if the flag carrier is on the same team
;3136:		if (BotSameTeam(bs, i))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 152
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 152
INDIRI4
CNSTI4 0
EQI4 $1076
line 3137
;3137:			continue;
ADDRGP4 $1067
JUMPV
LABELV $1076
line 3139
;3138:		//if the flag carrier is not visible
;3139:		vis = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, 360, i);
ADDRLP4 156
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 156
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 156
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 156
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
CNSTF4 1135869952
ARGF4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 160
ADDRGP4 BotEntityVisible
CALLF4
ASGNF4
ADDRLP4 144
ADDRLP4 160
INDIRF4
ASGNF4
line 3140
;3140:		if (vis <= 0)
ADDRLP4 144
INDIRF4
CNSTF4 0
GTF4 $1078
line 3141
;3141:			continue;
ADDRGP4 $1067
JUMPV
LABELV $1078
line 3143
;3142:		//
;3143:		return i;
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $1065
JUMPV
LABELV $1067
line 3124
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1069
ADDRLP4 0
INDIRI4
ADDRGP4 maxclients
INDIRI4
GEI4 $1080
ADDRLP4 0
INDIRI4
CNSTI4 64
LTI4 $1066
LABELV $1080
line 3145
;3144:	}
;3145:	return -1;
CNSTI4 -1
RETI4
LABELV $1065
endproc BotEnemyFlagCarrierVisible 164 20
export BotVisibleTeamMatesAndEnemies
proc BotVisibleTeamMatesAndEnemies 192 20
line 3153
;3146:}
;3147:
;3148:/*
;3149:==================
;3150:BotVisibleTeamMatesAndEnemies
;3151:==================
;3152:*/
;3153:void BotVisibleTeamMatesAndEnemies(bot_state_t *bs, int *teammates, int *enemies, float range) {
line 3159
;3154:	int i;
;3155:	float vis;
;3156:	aas_entityinfo_t entinfo;
;3157:	vec3_t dir;
;3158:
;3159:	if (teammates)
ADDRFP4 4
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1082
line 3160
;3160:		*teammates = 0;
ADDRFP4 4
INDIRP4
CNSTI4 0
ASGNI4
LABELV $1082
line 3161
;3161:	if (enemies)
ADDRFP4 8
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1084
line 3162
;3162:		*enemies = 0;
ADDRFP4 8
INDIRP4
CNSTI4 0
ASGNI4
LABELV $1084
line 3163
;3163:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1089
JUMPV
LABELV $1086
line 3164
;3164:		if (i == bs->client)
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $1090
line 3165
;3165:			continue;
ADDRGP4 $1087
JUMPV
LABELV $1090
line 3167
;3166:		//
;3167:		BotEntityInfo(i, &entinfo);
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3169
;3168:		//if this player is active
;3169:		if (!entinfo.valid)
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $1092
line 3170
;3170:			continue;
ADDRGP4 $1087
JUMPV
LABELV $1092
line 3172
;3171:		//if this player is carrying a flag
;3172:		if (!EntityCarriesFlag(&entinfo))
ADDRLP4 4
ARGP4
ADDRLP4 160
ADDRGP4 EntityCarriesFlag
CALLI4
ASGNI4
ADDRLP4 160
INDIRI4
CNSTI4 0
NEI4 $1094
line 3173
;3173:			continue;
ADDRGP4 $1087
JUMPV
LABELV $1094
line 3175
;3174:		//if not within range
;3175:		VectorSubtract(entinfo.origin, bs->origin, dir);
ADDRLP4 164
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 144
ADDRLP4 4+24
INDIRF4
ADDRLP4 164
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+4
ADDRLP4 4+24+4
INDIRF4
ADDRLP4 164
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 144+8
ADDRLP4 4+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3176
;3176:		if (VectorLengthSquared(dir) > Square(range))
ADDRLP4 144
ARGP4
ADDRLP4 168
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 172
ADDRFP4 12
INDIRF4
ASGNF4
ADDRLP4 168
INDIRF4
ADDRLP4 172
INDIRF4
ADDRLP4 172
INDIRF4
MULF4
LEF4 $1103
line 3177
;3177:			continue;
ADDRGP4 $1087
JUMPV
LABELV $1103
line 3179
;3178:		//if the flag carrier is not visible
;3179:		vis = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, 360, i);
ADDRLP4 176
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 176
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 176
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 176
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
CNSTF4 1135869952
ARGF4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 180
ADDRGP4 BotEntityVisible
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 180
INDIRF4
ASGNF4
line 3180
;3180:		if (vis <= 0)
ADDRLP4 156
INDIRF4
CNSTF4 0
GTF4 $1105
line 3181
;3181:			continue;
ADDRGP4 $1087
JUMPV
LABELV $1105
line 3183
;3182:		//if the flag carrier is on the same team
;3183:		if (BotSameTeam(bs, i)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 184
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 184
INDIRI4
CNSTI4 0
EQI4 $1107
line 3184
;3184:			if (teammates)
ADDRFP4 4
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1108
line 3185
;3185:				(*teammates)++;
ADDRLP4 188
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 188
INDIRP4
ADDRLP4 188
INDIRP4
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
line 3186
;3186:		}
ADDRGP4 $1108
JUMPV
LABELV $1107
line 3187
;3187:		else {
line 3188
;3188:			if (enemies)
ADDRFP4 8
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1111
line 3189
;3189:				(*enemies)++;
ADDRLP4 188
ADDRFP4 8
INDIRP4
ASGNP4
ADDRLP4 188
INDIRP4
ADDRLP4 188
INDIRP4
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1111
line 3190
;3190:		}
LABELV $1108
line 3191
;3191:	}
LABELV $1087
line 3163
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1089
ADDRLP4 0
INDIRI4
ADDRGP4 maxclients
INDIRI4
GEI4 $1113
ADDRLP4 0
INDIRI4
CNSTI4 64
LTI4 $1086
LABELV $1113
line 3192
;3192:}
LABELV $1081
endproc BotVisibleTeamMatesAndEnemies 192 20
lit
align 4
LABELV $1115
byte 4 3229614080
byte 4 3229614080
byte 4 3229614080
align 4
LABELV $1116
byte 4 1082130432
byte 4 1082130432
byte 4 1082130432
export BotAimAtEnemy
code
proc BotAimAtEnemy 1144 52
line 3263
;3193:
;3194:#ifdef MISSIONPACK
;3195:/*
;3196:==================
;3197:BotTeamCubeCarrierVisible
;3198:==================
;3199:*/
;3200:int BotTeamCubeCarrierVisible(bot_state_t *bs) {
;3201:	int i;
;3202:	float vis;
;3203:	aas_entityinfo_t entinfo;
;3204:
;3205:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
;3206:		if (i == bs->client) continue;
;3207:		//
;3208:		BotEntityInfo(i, &entinfo);
;3209:		//if this player is active
;3210:		if (!entinfo.valid) continue;
;3211:		//if this player is carrying a flag
;3212:		if (!EntityCarriesCubes(&entinfo)) continue;
;3213:		//if the flag carrier is not on the same team
;3214:		if (!BotSameTeam(bs, i)) continue;
;3215:		//if the flag carrier is not visible
;3216:		vis = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, 360, i);
;3217:		if (vis <= 0) continue;
;3218:		//
;3219:		return i;
;3220:	}
;3221:	return -1;
;3222:}
;3223:
;3224:/*
;3225:==================
;3226:BotEnemyCubeCarrierVisible
;3227:==================
;3228:*/
;3229:int BotEnemyCubeCarrierVisible(bot_state_t *bs) {
;3230:	int i;
;3231:	float vis;
;3232:	aas_entityinfo_t entinfo;
;3233:
;3234:	for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
;3235:		if (i == bs->client)
;3236:			continue;
;3237:		//
;3238:		BotEntityInfo(i, &entinfo);
;3239:		//if this player is active
;3240:		if (!entinfo.valid)
;3241:			continue;
;3242:		//if this player is carrying a flag
;3243:		if (!EntityCarriesCubes(&entinfo)) continue;
;3244:		//if the flag carrier is on the same team
;3245:		if (BotSameTeam(bs, i))
;3246:			continue;
;3247:		//if the flag carrier is not visible
;3248:		vis = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, 360, i);
;3249:		if (vis <= 0)
;3250:			continue;
;3251:		//
;3252:		return i;
;3253:	}
;3254:	return -1;
;3255:}
;3256:#endif
;3257:
;3258:/*
;3259:==================
;3260:BotAimAtEnemy
;3261:==================
;3262:*/
;3263:void BotAimAtEnemy(bot_state_t *bs) {
line 3267
;3264:	int i, enemyvisible;
;3265:	float dist, f, aim_skill, aim_accuracy, speed, reactiontime;
;3266:	vec3_t dir, bestorigin, end, start, groundtarget, cmdmove, enemyvelocity;
;3267:	vec3_t mins = {-4,-4,-4}, maxs = {4, 4, 4};
ADDRLP4 860
ADDRGP4 $1115
INDIRB
ASGNB 12
ADDRLP4 872
ADDRGP4 $1116
INDIRB
ASGNB 12
line 3275
;3268:	weaponinfo_t wi;
;3269:	aas_entityinfo_t entinfo;
;3270:	bot_goal_t goal;
;3271:	bsp_trace_t trace;
;3272:	vec3_t target;
;3273:
;3274:	//if the bot has no enemy
;3275:	if (bs->enemy < 0) {
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
CNSTI4 0
GEI4 $1117
line 3276
;3276:		return;
ADDRGP4 $1114
JUMPV
LABELV $1117
line 3279
;3277:	}
;3278:	//get the enemy entity information
;3279:	BotEntityInfo(bs->enemy, &entinfo);
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3281
;3280:	//if this is not a player (should be an obelisk)
;3281:	if (bs->enemy >= MAX_CLIENTS) {
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
CNSTI4 64
LTI4 $1119
line 3283
;3282:		//if the obelisk is visible
;3283:		VectorCopy(entinfo.origin, target);
ADDRLP4 828
ADDRLP4 0+24
INDIRB
ASGNB 12
line 3292
;3284:#ifdef MISSIONPACK
;3285:		// if attacking an obelisk
;3286:		if ( bs->enemy == redobelisk.entitynum ||
;3287:			bs->enemy == blueobelisk.entitynum ) {
;3288:			target[2] += 32;
;3289:		}
;3290:#endif
;3291:		//aim at the obelisk
;3292:		VectorSubtract(target, bs->eye, dir);
ADDRLP4 984
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 828
INDIRF4
ADDRLP4 984
INDIRP4
CNSTI4 4936
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 828+4
INDIRF4
ADDRLP4 984
INDIRP4
CNSTI4 4940
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 828+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4944
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3293
;3293:		vectoangles(dir, bs->ideal_viewangles);
ADDRLP4 140
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ARGP4
ADDRGP4 vectoangles
CALLV
pop
line 3295
;3294:		//set the aim target before trying to attack
;3295:		VectorCopy(target, bs->aimtarget);
ADDRFP4 0
INDIRP4
CNSTI4 6220
ADDP4
ADDRLP4 828
INDIRB
ASGNB 12
line 3296
;3296:		return;
ADDRGP4 $1114
JUMPV
LABELV $1119
line 3301
;3297:	}
;3298:	//
;3299:	//BotAI_Print(PRT_MESSAGE, "client %d: aiming at client %d\n", bs->entitynum, bs->enemy);
;3300:	//
;3301:	aim_skill = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_SKILL, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 16
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 984
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 736
ADDRLP4 984
INDIRF4
ASGNF4
line 3302
;3302:	aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 7
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 988
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 988
INDIRF4
ASGNF4
line 3304
;3303:	//
;3304:	if (aim_skill > 0.95) {
ADDRLP4 736
INDIRF4
CNSTF4 1064514355
LEF4 $1126
line 3306
;3305:		//don't aim too early
;3306:		reactiontime = 0.5 * trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_REACTIONTIME, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 6
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 992
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 856
CNSTF4 1056964608
ADDRLP4 992
INDIRF4
MULF4
ASGNF4
line 3307
;3307:		if (bs->enemysight_time > FloatTime() - reactiontime) return;
ADDRFP4 0
INDIRP4
CNSTI4 6132
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
ADDRLP4 856
INDIRF4
SUBF4
LEF4 $1128
ADDRGP4 $1114
JUMPV
LABELV $1128
line 3308
;3308:		if (bs->teleport_time > FloatTime() - reactiontime) return;
ADDRFP4 0
INDIRP4
CNSTI4 6180
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
ADDRLP4 856
INDIRF4
SUBF4
LEF4 $1130
ADDRGP4 $1114
JUMPV
LABELV $1130
line 3309
;3309:	}
LABELV $1126
line 3312
;3310:
;3311:	//get the weapon information
;3312:	trap_BotGetWeaponInfo(bs->ws, bs->weaponnum, &wi);
ADDRLP4 992
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 992
INDIRP4
CNSTI4 6536
ADDP4
INDIRI4
ARGI4
ADDRLP4 992
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
ARGI4
ADDRLP4 160
ARGP4
ADDRGP4 trap_BotGetWeaponInfo
CALLV
pop
line 3314
;3313:	//get the weapon specific aim accuracy and or aim skill
;3314:	if (wi.number == WP_MACHINEGUN) {
ADDRLP4 160+4
INDIRI4
CNSTI4 2
NEI4 $1132
line 3315
;3315:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_MACHINEGUN, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 8
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3316
;3316:	}
ADDRGP4 $1133
JUMPV
LABELV $1132
line 3317
;3317:	else if (wi.number == WP_SHOTGUN) {
ADDRLP4 160+4
INDIRI4
CNSTI4 3
NEI4 $1135
line 3318
;3318:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_SHOTGUN, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 9
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3319
;3319:	}
ADDRGP4 $1136
JUMPV
LABELV $1135
line 3320
;3320:	else if (wi.number == WP_GRENADE_LAUNCHER) {
ADDRLP4 160+4
INDIRI4
CNSTI4 4
NEI4 $1138
line 3321
;3321:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_GRENADELAUNCHER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 11
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3322
;3322:		aim_skill = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_SKILL_GRENADELAUNCHER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 18
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 1000
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 736
ADDRLP4 1000
INDIRF4
ASGNF4
line 3323
;3323:	}
ADDRGP4 $1139
JUMPV
LABELV $1138
line 3324
;3324:	else if (wi.number == WP_ROCKET_LAUNCHER) {
ADDRLP4 160+4
INDIRI4
CNSTI4 5
NEI4 $1141
line 3325
;3325:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_ROCKETLAUNCHER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 10
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3326
;3326:		aim_skill = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_SKILL_ROCKETLAUNCHER, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 17
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 1000
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 736
ADDRLP4 1000
INDIRF4
ASGNF4
line 3327
;3327:	}
ADDRGP4 $1142
JUMPV
LABELV $1141
line 3328
;3328:	else if (wi.number == WP_LIGHTNING) {
ADDRLP4 160+4
INDIRI4
CNSTI4 6
NEI4 $1144
line 3329
;3329:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_LIGHTNING, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 12
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3330
;3330:	}
ADDRGP4 $1145
JUMPV
LABELV $1144
line 3331
;3331:	else if (wi.number == WP_RAILGUN) {
ADDRLP4 160+4
INDIRI4
CNSTI4 7
NEI4 $1147
line 3332
;3332:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_RAILGUN, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 14
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3333
;3333:	}
ADDRGP4 $1148
JUMPV
LABELV $1147
line 3334
;3334:	else if (wi.number == WP_PLASMAGUN) {
ADDRLP4 160+4
INDIRI4
CNSTI4 8
NEI4 $1150
line 3335
;3335:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_PLASMAGUN, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 13
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3336
;3336:		aim_skill = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_SKILL_PLASMAGUN, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 19
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 1000
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 736
ADDRLP4 1000
INDIRF4
ASGNF4
line 3337
;3337:	}
ADDRGP4 $1151
JUMPV
LABELV $1150
line 3338
;3338:	else if (wi.number == WP_BFG) {
ADDRLP4 160+4
INDIRI4
CNSTI4 9
NEI4 $1153
line 3339
;3339:		aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY_BFG10K, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 15
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 996
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 156
ADDRLP4 996
INDIRF4
ASGNF4
line 3340
;3340:		aim_skill = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_SKILL_BFG10K, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 20
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 1000
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 736
ADDRLP4 1000
INDIRF4
ASGNF4
line 3341
;3341:	}
LABELV $1153
LABELV $1151
LABELV $1148
LABELV $1145
LABELV $1142
LABELV $1139
LABELV $1136
LABELV $1133
line 3343
;3342:	//
;3343:	if (aim_accuracy <= 0) aim_accuracy = 0.0001f;
ADDRLP4 156
INDIRF4
CNSTF4 0
GTF4 $1156
ADDRLP4 156
CNSTF4 953267991
ASGNF4
LABELV $1156
line 3345
;3344:	//get the enemy entity information
;3345:	BotEntityInfo(bs->enemy, &entinfo);
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3347
;3346:	//if the enemy is invisible then shoot crappy most of the time
;3347:	if (EntityIsInvisible(&entinfo)) {
ADDRLP4 0
ARGP4
ADDRLP4 996
ADDRGP4 EntityIsInvisible
CALLI4
ASGNI4
ADDRLP4 996
INDIRI4
CNSTI4 0
EQI4 $1158
line 3348
;3348:		if (random() > 0.1) aim_accuracy *= 0.4f;
ADDRLP4 1000
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 1000
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1036831949
LEF4 $1160
ADDRLP4 156
CNSTF4 1053609165
ADDRLP4 156
INDIRF4
MULF4
ASGNF4
LABELV $1160
line 3349
;3349:	}
LABELV $1158
line 3351
;3350:	//
;3351:	VectorSubtract(entinfo.origin, entinfo.lastvisorigin, enemyvelocity);
ADDRLP4 712
ADDRLP4 0+24
INDIRF4
ADDRLP4 0+60
INDIRF4
SUBF4
ASGNF4
ADDRLP4 712+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 0+60+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 712+8
ADDRLP4 0+24+8
INDIRF4
ADDRLP4 0+60+8
INDIRF4
SUBF4
ASGNF4
line 3352
;3352:	VectorScale(enemyvelocity, 1 / entinfo.update_time, enemyvelocity);
ADDRLP4 1000
CNSTF4 1065353216
ASGNF4
ADDRLP4 712
ADDRLP4 712
INDIRF4
ADDRLP4 1000
INDIRF4
ADDRLP4 0+16
INDIRF4
DIVF4
MULF4
ASGNF4
ADDRLP4 712+4
ADDRLP4 712+4
INDIRF4
ADDRLP4 1000
INDIRF4
ADDRLP4 0+16
INDIRF4
DIVF4
MULF4
ASGNF4
ADDRLP4 712+8
ADDRLP4 712+8
INDIRF4
CNSTF4 1065353216
ADDRLP4 0+16
INDIRF4
DIVF4
MULF4
ASGNF4
line 3354
;3353:	//enemy origin and velocity is remembered every 0.5 seconds
;3354:	if (bs->enemyposition_time < FloatTime()) {
ADDRFP4 0
INDIRP4
CNSTI4 6140
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
GEF4 $1181
line 3356
;3355:		//
;3356:		bs->enemyposition_time = FloatTime() + 0.5;
ADDRFP4 0
INDIRP4
CNSTI4 6140
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1056964608
ADDF4
ASGNF4
line 3357
;3357:		VectorCopy(enemyvelocity, bs->enemyvelocity);
ADDRFP4 0
INDIRP4
CNSTI4 6232
ADDP4
ADDRLP4 712
INDIRB
ASGNB 12
line 3358
;3358:		VectorCopy(entinfo.origin, bs->enemyorigin);
ADDRFP4 0
INDIRP4
CNSTI4 6244
ADDP4
ADDRLP4 0+24
INDIRB
ASGNB 12
line 3359
;3359:	}
LABELV $1181
line 3361
;3360:	//if not extremely skilled
;3361:	if (aim_skill < 0.9) {
ADDRLP4 736
INDIRF4
CNSTF4 1063675494
GEF4 $1184
line 3362
;3362:		VectorSubtract(entinfo.origin, bs->enemyorigin, dir);
ADDRLP4 1004
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 0+24
INDIRF4
ADDRLP4 1004
INDIRP4
CNSTI4 6244
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 1004
INDIRP4
CNSTI4 6248
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 6252
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3364
;3363:		//if the enemy moved a bit
;3364:		if (VectorLengthSquared(dir) > Square(48)) {
ADDRLP4 140
ARGP4
ADDRLP4 1008
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 1008
INDIRF4
CNSTF4 1158676480
LEF4 $1193
line 3366
;3365:			//if the enemy changed direction
;3366:			if (DotProduct(bs->enemyvelocity, enemyvelocity) < 0) {
ADDRLP4 1012
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1012
INDIRP4
CNSTI4 6232
ADDP4
INDIRF4
ADDRLP4 712
INDIRF4
MULF4
ADDRLP4 1012
INDIRP4
CNSTI4 6236
ADDP4
INDIRF4
ADDRLP4 712+4
INDIRF4
MULF4
ADDF4
ADDRLP4 1012
INDIRP4
CNSTI4 6240
ADDP4
INDIRF4
ADDRLP4 712+8
INDIRF4
MULF4
ADDF4
CNSTF4 0
GEF4 $1195
line 3368
;3367:				//aim accuracy should be worse now
;3368:				aim_accuracy *= 0.7f;
ADDRLP4 156
CNSTF4 1060320051
ADDRLP4 156
INDIRF4
MULF4
ASGNF4
line 3369
;3369:			}
LABELV $1195
line 3370
;3370:		}
LABELV $1193
line 3371
;3371:	}
LABELV $1184
line 3373
;3372:	//check visibility of enemy
;3373:	enemyvisible = BotEntityVisible(bs->entitynum, bs->eye, bs->viewangles, 360, bs->enemy);
ADDRLP4 1004
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1004
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 1004
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 1004
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
CNSTF4 1135869952
ARGF4
ADDRLP4 1004
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ARGI4
ADDRLP4 1008
ADDRGP4 BotEntityVisible
CALLF4
ASGNF4
ADDRLP4 824
ADDRLP4 1008
INDIRF4
CVFI4 4
ASGNI4
line 3375
;3374:	//if the enemy is visible
;3375:	if (enemyvisible) {
ADDRLP4 824
INDIRI4
CNSTI4 0
EQI4 $1199
line 3377
;3376:		//
;3377:		VectorCopy(entinfo.origin, bestorigin);
ADDRLP4 724
ADDRLP4 0+24
INDIRB
ASGNB 12
line 3378
;3378:		bestorigin[2] += 8;
ADDRLP4 724+8
ADDRLP4 724+8
INDIRF4
CNSTF4 1090519040
ADDF4
ASGNF4
line 3381
;3379:		//get the start point shooting from
;3380:		//NOTE: the x and y projectile start offsets are ignored
;3381:		VectorCopy(bs->origin, start);
ADDRLP4 844
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 3382
;3382:		start[2] += bs->cur_ps.viewheight;
ADDRLP4 844+8
ADDRLP4 844+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 180
ADDP4
INDIRI4
CVIF4 4
ADDF4
ASGNF4
line 3383
;3383:		start[2] += wi.offset[2];
ADDRLP4 844+8
ADDRLP4 844+8
INDIRF4
ADDRLP4 160+292+8
INDIRF4
ADDF4
ASGNF4
line 3385
;3384:		//
;3385:		BotAI_Trace(&trace, start, mins, maxs, bestorigin, bs->entitynum, MASK_SHOT);
ADDRLP4 740
ARGP4
ADDRLP4 844
ARGP4
ADDRLP4 860
ARGP4
ADDRLP4 872
ARGP4
ADDRLP4 724
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3387
;3386:		//if the enemy is NOT hit
;3387:		if (trace.fraction <= 1 && trace.ent != entinfo.number) {
ADDRLP4 740+8
INDIRF4
CNSTF4 1065353216
GTF4 $1207
ADDRLP4 740+80
INDIRI4
ADDRLP4 0+20
INDIRI4
EQI4 $1207
line 3388
;3388:			bestorigin[2] += 16;
ADDRLP4 724+8
ADDRLP4 724+8
INDIRF4
CNSTF4 1098907648
ADDF4
ASGNF4
line 3389
;3389:		}
LABELV $1207
line 3391
;3390:		//if it is not an instant hit weapon the bot might want to predict the enemy
;3391:		if (wi.speed) {
ADDRLP4 160+272
INDIRF4
CNSTF4 0
EQF4 $1213
line 3393
;3392:			//
;3393:			VectorSubtract(bestorigin, bs->origin, dir);
ADDRLP4 1012
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 724
INDIRF4
ADDRLP4 1012
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 724+4
INDIRF4
ADDRLP4 1012
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 724+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3394
;3394:			dist = VectorLength(dir);
ADDRLP4 140
ARGP4
ADDRLP4 1016
ADDRGP4 VectorLength
CALLF4
ASGNF4
ADDRLP4 840
ADDRLP4 1016
INDIRF4
ASGNF4
line 3395
;3395:			VectorSubtract(entinfo.origin, bs->enemyorigin, dir);
ADDRLP4 1020
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 0+24
INDIRF4
ADDRLP4 1020
INDIRP4
CNSTI4 6244
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 1020
INDIRP4
CNSTI4 6248
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 6252
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3397
;3396:			//if the enemy is NOT pretty far away and strafing just small steps left and right
;3397:			if (!(dist > 100 && VectorLengthSquared(dir) < Square(32))) {
ADDRLP4 840
INDIRF4
CNSTF4 1120403456
LEF4 $1229
ADDRLP4 140
ARGP4
ADDRLP4 1024
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 1024
INDIRF4
CNSTF4 1149239296
LTF4 $1227
LABELV $1229
line 3399
;3398:				//if skilled anough do exact prediction
;3399:				if (aim_skill > 0.8 &&
ADDRLP4 736
INDIRF4
CNSTF4 1061997773
LEF4 $1230
ADDRFP4 0
INDIRP4
CNSTI4 164
ADDP4
INDIRI4
CNSTI4 0
NEI4 $1230
line 3401
;3400:						//if the weapon is ready to fire
;3401:						bs->cur_ps.weaponstate == WEAPON_READY) {
line 3405
;3402:					aas_clientmove_t move;
;3403:					vec3_t origin;
;3404:
;3405:					VectorSubtract(entinfo.origin, bs->origin, dir);
ADDRLP4 1124
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 0+24
INDIRF4
ADDRLP4 1124
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 1124
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3407
;3406:					//distance towards the enemy
;3407:					dist = VectorLength(dir);
ADDRLP4 140
ARGP4
ADDRLP4 1128
ADDRGP4 VectorLength
CALLF4
ASGNF4
ADDRLP4 840
ADDRLP4 1128
INDIRF4
ASGNF4
line 3409
;3408:					//direction the enemy is moving in
;3409:					VectorSubtract(entinfo.origin, entinfo.lastvisorigin, dir);
ADDRLP4 140
ADDRLP4 0+24
INDIRF4
ADDRLP4 0+60
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 0+60+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 0+24+8
INDIRF4
ADDRLP4 0+60+8
INDIRF4
SUBF4
ASGNF4
line 3411
;3410:					//
;3411:					VectorScale(dir, 1 / entinfo.update_time, dir);
ADDRLP4 1132
CNSTF4 1065353216
ASGNF4
ADDRLP4 140
ADDRLP4 140
INDIRF4
ADDRLP4 1132
INDIRF4
ADDRLP4 0+16
INDIRF4
DIVF4
MULF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 140+4
INDIRF4
ADDRLP4 1132
INDIRF4
ADDRLP4 0+16
INDIRF4
DIVF4
MULF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 140+8
INDIRF4
CNSTF4 1065353216
ADDRLP4 0+16
INDIRF4
DIVF4
MULF4
ASGNF4
line 3413
;3412:					//
;3413:					VectorCopy(entinfo.origin, origin);
ADDRLP4 1028
ADDRLP4 0+24
INDIRB
ASGNB 12
line 3414
;3414:					origin[2] += 1;
ADDRLP4 1028+8
ADDRLP4 1028+8
INDIRF4
CNSTF4 1065353216
ADDF4
ASGNF4
line 3416
;3415:					//
;3416:					VectorClear(cmdmove);
ADDRLP4 1136
CNSTF4 0
ASGNF4
ADDRLP4 968+8
ADDRLP4 1136
INDIRF4
ASGNF4
ADDRLP4 968+4
ADDRLP4 1136
INDIRF4
ASGNF4
ADDRLP4 968
ADDRLP4 1136
INDIRF4
ASGNF4
line 3418
;3417:					//AAS_ClearShownDebugLines();
;3418:					trap_AAS_PredictClientMovement(&move, bs->enemy, origin,
ADDRLP4 1040
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ARGI4
ADDRLP4 1028
ARGP4
CNSTI4 4
ARGI4
ADDRLP4 1140
CNSTI4 0
ASGNI4
ADDRLP4 1140
INDIRI4
ARGI4
ADDRLP4 140
ARGP4
ADDRLP4 968
ARGP4
ADDRLP4 1140
INDIRI4
ARGI4
CNSTF4 1092616192
ADDRLP4 840
INDIRF4
MULF4
ADDRLP4 160+272
INDIRF4
DIVF4
CVFI4 4
ARGI4
CNSTF4 1036831949
ARGF4
ADDRLP4 1140
INDIRI4
ARGI4
ADDRLP4 1140
INDIRI4
ARGI4
ADDRLP4 1140
INDIRI4
ARGI4
ADDRGP4 trap_AAS_PredictClientMovement
CALLI4
pop
line 3422
;3419:														PRESENCE_CROUCH, qfalse,
;3420:														dir, cmdmove, 0,
;3421:														dist * 10 / wi.speed, 0.1f, 0, 0, qfalse);
;3422:					VectorCopy(move.endpos, bestorigin);
ADDRLP4 724
ADDRLP4 1040
INDIRB
ASGNB 12
line 3424
;3423:					//BotAI_Print(PRT_MESSAGE, "%1.1f predicted speed = %f, frames = %f\n", FloatTime(), VectorLength(dir), dist * 10 / wi.speed);
;3424:				}
ADDRGP4 $1231
JUMPV
LABELV $1230
line 3426
;3425:				//if not that skilled do linear prediction
;3426:				else if (aim_skill > 0.4) {
ADDRLP4 736
INDIRF4
CNSTF4 1053609165
LEF4 $1263
line 3427
;3427:					VectorSubtract(entinfo.origin, bs->origin, dir);
ADDRLP4 1028
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 0+24
INDIRF4
ADDRLP4 1028
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 1028
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3429
;3428:					//distance towards the enemy
;3429:					dist = VectorLength(dir);
ADDRLP4 140
ARGP4
ADDRLP4 1032
ADDRGP4 VectorLength
CALLF4
ASGNF4
ADDRLP4 840
ADDRLP4 1032
INDIRF4
ASGNF4
line 3431
;3430:					//direction the enemy is moving in
;3431:					VectorSubtract(entinfo.origin, entinfo.lastvisorigin, dir);
ADDRLP4 140
ADDRLP4 0+24
INDIRF4
ADDRLP4 0+60
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 0+60+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 0+24+8
INDIRF4
ADDRLP4 0+60+8
INDIRF4
SUBF4
ASGNF4
line 3432
;3432:					dir[2] = 0;
ADDRLP4 140+8
CNSTF4 0
ASGNF4
line 3434
;3433:					//
;3434:					speed = VectorNormalize(dir) / entinfo.update_time;
ADDRLP4 140
ARGP4
ADDRLP4 1036
ADDRGP4 VectorNormalize
CALLF4
ASGNF4
ADDRLP4 980
ADDRLP4 1036
INDIRF4
ADDRLP4 0+16
INDIRF4
DIVF4
ASGNF4
line 3437
;3435:					//botimport.Print(PRT_MESSAGE, "speed = %f, wi->speed = %f\n", speed, wi->speed);
;3436:					//best spot to aim at
;3437:					VectorMA(entinfo.origin, (dist / wi.speed) * speed, dir, bestorigin);
ADDRLP4 1040
ADDRLP4 840
INDIRF4
ASGNF4
ADDRLP4 1044
ADDRLP4 980
INDIRF4
ASGNF4
ADDRLP4 724
ADDRLP4 0+24
INDIRF4
ADDRLP4 140
INDIRF4
ADDRLP4 1040
INDIRF4
ADDRLP4 160+272
INDIRF4
DIVF4
ADDRLP4 1044
INDIRF4
MULF4
MULF4
ADDF4
ASGNF4
ADDRLP4 724+4
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 140+4
INDIRF4
ADDRLP4 1040
INDIRF4
ADDRLP4 160+272
INDIRF4
DIVF4
ADDRLP4 1044
INDIRF4
MULF4
MULF4
ADDF4
ASGNF4
ADDRLP4 724+8
ADDRLP4 0+24+8
INDIRF4
ADDRLP4 140+8
INDIRF4
ADDRLP4 840
INDIRF4
ADDRLP4 160+272
INDIRF4
DIVF4
ADDRLP4 980
INDIRF4
MULF4
MULF4
ADDF4
ASGNF4
line 3438
;3438:				}
LABELV $1263
LABELV $1231
line 3439
;3439:			}
LABELV $1227
line 3440
;3440:		}
LABELV $1213
line 3442
;3441:		//if the projectile does radial damage
;3442:		if (aim_skill > 0.6 && wi.proj.damagetype & DAMAGETYPE_RADIAL) {
ADDRLP4 736
INDIRF4
CNSTF4 1058642330
LEF4 $1298
ADDRLP4 160+344+180
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $1298
line 3444
;3443:			//if the enemy isn't standing significantly higher than the bot
;3444:			if (entinfo.origin[2] < bs->origin[2] + 16) {
ADDRLP4 0+24+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
CNSTF4 1098907648
ADDF4
GEF4 $1302
line 3446
;3445:				//try to aim at the ground in front of the enemy
;3446:				VectorCopy(entinfo.origin, end);
ADDRLP4 956
ADDRLP4 0+24
INDIRB
ASGNB 12
line 3447
;3447:				end[2] -= 64;
ADDRLP4 956+8
ADDRLP4 956+8
INDIRF4
CNSTF4 1115684864
SUBF4
ASGNF4
line 3448
;3448:				BotAI_Trace(&trace, entinfo.origin, NULL, NULL, end, entinfo.number, MASK_SHOT);
ADDRLP4 740
ARGP4
ADDRLP4 0+24
ARGP4
ADDRLP4 1012
CNSTP4 0
ASGNP4
ADDRLP4 1012
INDIRP4
ARGP4
ADDRLP4 1012
INDIRP4
ARGP4
ADDRLP4 956
ARGP4
ADDRLP4 0+20
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3450
;3449:				//
;3450:				VectorCopy(bestorigin, groundtarget);
ADDRLP4 944
ADDRLP4 724
INDIRB
ASGNB 12
line 3451
;3451:				if (trace.startsolid) groundtarget[2] = entinfo.origin[2] - 16;
ADDRLP4 740+4
INDIRI4
CNSTI4 0
EQI4 $1310
ADDRLP4 944+8
ADDRLP4 0+24+8
INDIRF4
CNSTF4 1098907648
SUBF4
ASGNF4
ADDRGP4 $1311
JUMPV
LABELV $1310
line 3452
;3452:				else groundtarget[2] = trace.endpos[2] - 8;
ADDRLP4 944+8
ADDRLP4 740+12+8
INDIRF4
CNSTF4 1090519040
SUBF4
ASGNF4
LABELV $1311
line 3454
;3453:				//trace a line from projectile start to ground target
;3454:				BotAI_Trace(&trace, start, NULL, NULL, groundtarget, bs->entitynum, MASK_SHOT);
ADDRLP4 740
ARGP4
ADDRLP4 844
ARGP4
ADDRLP4 1016
CNSTP4 0
ASGNP4
ADDRLP4 1016
INDIRP4
ARGP4
ADDRLP4 1016
INDIRP4
ARGP4
ADDRLP4 944
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3456
;3455:				//if hitpoint is not vertically too far from the ground target
;3456:				if (fabs(trace.endpos[2] - groundtarget[2]) < 50) {
ADDRLP4 740+12+8
INDIRF4
ADDRLP4 944+8
INDIRF4
SUBF4
ARGF4
ADDRLP4 1020
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 1020
INDIRF4
CNSTF4 1112014848
GEF4 $1319
line 3457
;3457:					VectorSubtract(trace.endpos, groundtarget, dir);
ADDRLP4 140
ADDRLP4 740+12
INDIRF4
ADDRLP4 944
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 740+12+4
INDIRF4
ADDRLP4 944+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 740+12+8
INDIRF4
ADDRLP4 944+8
INDIRF4
SUBF4
ASGNF4
line 3459
;3458:					//if the hitpoint is near anough the ground target
;3459:					if (VectorLengthSquared(dir) < Square(60)) {
ADDRLP4 140
ARGP4
ADDRLP4 1024
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 1024
INDIRF4
CNSTF4 1163984896
GEF4 $1333
line 3460
;3460:						VectorSubtract(trace.endpos, start, dir);
ADDRLP4 140
ADDRLP4 740+12
INDIRF4
ADDRLP4 844
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 740+12+4
INDIRF4
ADDRLP4 844+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 740+12+8
INDIRF4
ADDRLP4 844+8
INDIRF4
SUBF4
ASGNF4
line 3462
;3461:						//if the hitpoint is far anough from the bot
;3462:						if (VectorLengthSquared(dir) > Square(100)) {
ADDRLP4 140
ARGP4
ADDRLP4 1028
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 1028
INDIRF4
CNSTF4 1176256512
LEF4 $1344
line 3464
;3463:							//check if the bot is visible from the ground target
;3464:							trace.endpos[2] += 1;
ADDRLP4 740+12+8
ADDRLP4 740+12+8
INDIRF4
CNSTF4 1065353216
ADDF4
ASGNF4
line 3465
;3465:							BotAI_Trace(&trace, trace.endpos, NULL, NULL, entinfo.origin, entinfo.number, MASK_SHOT);
ADDRLP4 740
ARGP4
ADDRLP4 740+12
ARGP4
ADDRLP4 1032
CNSTP4 0
ASGNP4
ADDRLP4 1032
INDIRP4
ARGP4
ADDRLP4 1032
INDIRP4
ARGP4
ADDRLP4 0+24
ARGP4
ADDRLP4 0+20
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3466
;3466:							if (trace.fraction >= 1) {
ADDRLP4 740+8
INDIRF4
CNSTF4 1065353216
LTF4 $1351
line 3468
;3467:								//botimport.Print(PRT_MESSAGE, "%1.1f aiming at ground\n", AAS_Time());
;3468:								VectorCopy(groundtarget, bestorigin);
ADDRLP4 724
ADDRLP4 944
INDIRB
ASGNB 12
line 3469
;3469:							}
LABELV $1351
line 3470
;3470:						}
LABELV $1344
line 3471
;3471:					}
LABELV $1333
line 3472
;3472:				}
LABELV $1319
line 3473
;3473:			}
LABELV $1302
line 3474
;3474:		}
LABELV $1298
line 3475
;3475:		bestorigin[0] += 20 * crandom() * (1 - aim_accuracy);
ADDRLP4 1012
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 724
ADDRLP4 724
INDIRF4
CNSTF4 1101004800
CNSTF4 1073741824
ADDRLP4 1012
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 156
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3476
;3476:		bestorigin[1] += 20 * crandom() * (1 - aim_accuracy);
ADDRLP4 1016
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 724+4
ADDRLP4 724+4
INDIRF4
CNSTF4 1101004800
CNSTF4 1073741824
ADDRLP4 1016
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 156
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3477
;3477:		bestorigin[2] += 10 * crandom() * (1 - aim_accuracy);
ADDRLP4 1020
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 724+8
ADDRLP4 724+8
INDIRF4
CNSTF4 1092616192
CNSTF4 1073741824
ADDRLP4 1020
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 156
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3478
;3478:	}
ADDRGP4 $1200
JUMPV
LABELV $1199
line 3479
;3479:	else {
line 3481
;3480:		//
;3481:		VectorCopy(bs->lastenemyorigin, bestorigin);
ADDRLP4 724
ADDRFP4 0
INDIRP4
CNSTI4 6548
ADDP4
INDIRB
ASGNB 12
line 3482
;3482:		bestorigin[2] += 8;
ADDRLP4 724+8
ADDRLP4 724+8
INDIRF4
CNSTF4 1090519040
ADDF4
ASGNF4
line 3484
;3483:		//if the bot is skilled anough
;3484:		if (aim_skill > 0.5) {
ADDRLP4 736
INDIRF4
CNSTF4 1056964608
LEF4 $1357
line 3486
;3485:			//do prediction shots around corners
;3486:			if (wi.number == WP_BFG ||
ADDRLP4 160+4
INDIRI4
CNSTI4 9
EQI4 $1365
ADDRLP4 160+4
INDIRI4
CNSTI4 5
EQI4 $1365
ADDRLP4 160+4
INDIRI4
CNSTI4 4
NEI4 $1359
LABELV $1365
line 3488
;3487:				wi.number == WP_ROCKET_LAUNCHER ||
;3488:				wi.number == WP_GRENADE_LAUNCHER) {
line 3490
;3489:				//create the chase goal
;3490:				goal.entitynum = bs->client;
ADDRLP4 884+40
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ASGNI4
line 3491
;3491:				goal.areanum = bs->areanum;
ADDRLP4 884+12
ADDRFP4 0
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ASGNI4
line 3492
;3492:				VectorCopy(bs->eye, goal.origin);
ADDRLP4 884
ADDRFP4 0
INDIRP4
CNSTI4 4936
ADDP4
INDIRB
ASGNB 12
line 3493
;3493:				VectorSet(goal.mins, -8, -8, -8);
ADDRLP4 884+16
CNSTF4 3238002688
ASGNF4
ADDRLP4 884+16+4
CNSTF4 3238002688
ASGNF4
ADDRLP4 884+16+8
CNSTF4 3238002688
ASGNF4
line 3494
;3494:				VectorSet(goal.maxs, 8, 8, 8);
ADDRLP4 884+28
CNSTF4 1090519040
ASGNF4
ADDRLP4 884+28+4
CNSTF4 1090519040
ASGNF4
ADDRLP4 884+28+8
CNSTF4 1090519040
ASGNF4
line 3496
;3495:				//
;3496:				if (trap_BotPredictVisiblePosition(bs->lastenemyorigin, bs->lastenemyareanum, &goal, TFL_DEFAULT, target)) {
ADDRLP4 1012
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1012
INDIRP4
CNSTI4 6548
ADDP4
ARGP4
ADDRLP4 1012
INDIRP4
CNSTI4 6544
ADDP4
INDIRI4
ARGI4
ADDRLP4 884
ARGP4
CNSTI4 18616254
ARGI4
ADDRLP4 828
ARGP4
ADDRLP4 1016
ADDRGP4 trap_BotPredictVisiblePosition
CALLI4
ASGNI4
ADDRLP4 1016
INDIRI4
CNSTI4 0
EQI4 $1378
line 3497
;3497:					VectorSubtract(target, bs->eye, dir);
ADDRLP4 1020
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 828
INDIRF4
ADDRLP4 1020
INDIRP4
CNSTI4 4936
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 828+4
INDIRF4
ADDRLP4 1020
INDIRP4
CNSTI4 4940
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 828+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4944
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3498
;3498:					if (VectorLengthSquared(dir) > Square(80)) {
ADDRLP4 140
ARGP4
ADDRLP4 1024
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 1024
INDIRF4
CNSTF4 1170735104
LEF4 $1384
line 3499
;3499:						VectorCopy(target, bestorigin);
ADDRLP4 724
ADDRLP4 828
INDIRB
ASGNB 12
line 3500
;3500:						bestorigin[2] -= 20;
ADDRLP4 724+8
ADDRLP4 724+8
INDIRF4
CNSTF4 1101004800
SUBF4
ASGNF4
line 3501
;3501:					}
LABELV $1384
line 3502
;3502:				}
LABELV $1378
line 3503
;3503:				aim_accuracy = 1;
ADDRLP4 156
CNSTF4 1065353216
ASGNF4
line 3504
;3504:			}
LABELV $1359
line 3505
;3505:		}
LABELV $1357
line 3506
;3506:	}
LABELV $1200
line 3508
;3507:	//
;3508:	if (enemyvisible) {
ADDRLP4 824
INDIRI4
CNSTI4 0
EQI4 $1387
line 3509
;3509:		BotAI_Trace(&trace, bs->eye, NULL, NULL, bestorigin, bs->entitynum, MASK_SHOT);
ADDRLP4 740
ARGP4
ADDRLP4 1012
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1012
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 1016
CNSTP4 0
ASGNP4
ADDRLP4 1016
INDIRP4
ARGP4
ADDRLP4 1016
INDIRP4
ARGP4
ADDRLP4 724
ARGP4
ADDRLP4 1012
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3510
;3510:		VectorCopy(trace.endpos, bs->aimtarget);
ADDRFP4 0
INDIRP4
CNSTI4 6220
ADDP4
ADDRLP4 740+12
INDIRB
ASGNB 12
line 3511
;3511:	}
ADDRGP4 $1388
JUMPV
LABELV $1387
line 3512
;3512:	else {
line 3513
;3513:		VectorCopy(bestorigin, bs->aimtarget);
ADDRFP4 0
INDIRP4
CNSTI4 6220
ADDP4
ADDRLP4 724
INDIRB
ASGNB 12
line 3514
;3514:	}
LABELV $1388
line 3516
;3515:	//get aim direction
;3516:	VectorSubtract(bestorigin, bs->eye, dir);
ADDRLP4 1012
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 140
ADDRLP4 724
INDIRF4
ADDRLP4 1012
INDIRP4
CNSTI4 4936
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+4
ADDRLP4 724+4
INDIRF4
ADDRLP4 1012
INDIRP4
CNSTI4 4940
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 140+8
ADDRLP4 724+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4944
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3518
;3517:	//
;3518:	if (wi.number == WP_MACHINEGUN ||
ADDRLP4 160+4
INDIRI4
CNSTI4 2
EQI4 $1402
ADDRLP4 160+4
INDIRI4
CNSTI4 3
EQI4 $1402
ADDRLP4 160+4
INDIRI4
CNSTI4 6
EQI4 $1402
ADDRLP4 160+4
INDIRI4
CNSTI4 7
NEI4 $1394
LABELV $1402
line 3521
;3519:		wi.number == WP_SHOTGUN ||
;3520:		wi.number == WP_LIGHTNING ||
;3521:		wi.number == WP_RAILGUN) {
line 3523
;3522:		//distance towards the enemy
;3523:		dist = VectorLength(dir);
ADDRLP4 140
ARGP4
ADDRLP4 1016
ADDRGP4 VectorLength
CALLF4
ASGNF4
ADDRLP4 840
ADDRLP4 1016
INDIRF4
ASGNF4
line 3524
;3524:		if (dist > 150) dist = 150;
ADDRLP4 840
INDIRF4
CNSTF4 1125515264
LEF4 $1403
ADDRLP4 840
CNSTF4 1125515264
ASGNF4
LABELV $1403
line 3525
;3525:		f = 0.6 + dist / 150 * 0.4;
ADDRLP4 940
CNSTF4 1053609165
ADDRLP4 840
INDIRF4
CNSTF4 1125515264
DIVF4
MULF4
CNSTF4 1058642330
ADDF4
ASGNF4
line 3526
;3526:		aim_accuracy *= f;
ADDRLP4 156
ADDRLP4 156
INDIRF4
ADDRLP4 940
INDIRF4
MULF4
ASGNF4
line 3527
;3527:	}
LABELV $1394
line 3529
;3528:	//add some random stuff to the aim direction depending on the aim accuracy
;3529:	if (aim_accuracy < 0.8) {
ADDRLP4 156
INDIRF4
CNSTF4 1061997773
GEF4 $1405
line 3530
;3530:		VectorNormalize(dir);
ADDRLP4 140
ARGP4
ADDRGP4 VectorNormalize
CALLF4
pop
line 3531
;3531:		for (i = 0; i < 3; i++) dir[i] += 0.3 * crandom() * (1 - aim_accuracy);
ADDRLP4 152
CNSTI4 0
ASGNI4
LABELV $1407
ADDRLP4 1016
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 1020
ADDRLP4 152
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 140
ADDP4
ASGNP4
ADDRLP4 1020
INDIRP4
ADDRLP4 1020
INDIRP4
INDIRF4
CNSTF4 1050253722
CNSTF4 1073741824
ADDRLP4 1016
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 156
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
LABELV $1408
ADDRLP4 152
ADDRLP4 152
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 152
INDIRI4
CNSTI4 3
LTI4 $1407
line 3532
;3532:	}
LABELV $1405
line 3534
;3533:	//set the ideal view angles
;3534:	vectoangles(dir, bs->ideal_viewangles);
ADDRLP4 140
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ARGP4
ADDRGP4 vectoangles
CALLV
pop
line 3536
;3535:	//take the weapon spread into account for lower skilled bots
;3536:	bs->ideal_viewangles[PITCH] += 6 * wi.vspread * crandom() * (1 - aim_accuracy);
ADDRLP4 1016
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 1020
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ASGNP4
ADDRLP4 1020
INDIRP4
ADDRLP4 1020
INDIRP4
INDIRF4
CNSTF4 1086324736
ADDRLP4 160+268
INDIRF4
MULF4
CNSTF4 1073741824
ADDRLP4 1016
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 156
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3537
;3537:	bs->ideal_viewangles[PITCH] = AngleMod(bs->ideal_viewangles[PITCH]);
ADDRLP4 1024
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ASGNP4
ADDRLP4 1024
INDIRP4
INDIRF4
ARGF4
ADDRLP4 1028
ADDRGP4 AngleMod
CALLF4
ASGNF4
ADDRLP4 1024
INDIRP4
ADDRLP4 1028
INDIRF4
ASGNF4
line 3538
;3538:	bs->ideal_viewangles[YAW] += 6 * wi.hspread * crandom() * (1 - aim_accuracy);
ADDRLP4 1032
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 1036
ADDRFP4 0
INDIRP4
CNSTI4 6580
ADDP4
ASGNP4
ADDRLP4 1036
INDIRP4
ADDRLP4 1036
INDIRP4
INDIRF4
CNSTF4 1086324736
ADDRLP4 160+264
INDIRF4
MULF4
CNSTF4 1073741824
ADDRLP4 1032
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 156
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3539
;3539:	bs->ideal_viewangles[YAW] = AngleMod(bs->ideal_viewangles[YAW]);
ADDRLP4 1040
ADDRFP4 0
INDIRP4
CNSTI4 6580
ADDP4
ASGNP4
ADDRLP4 1040
INDIRP4
INDIRF4
ARGF4
ADDRLP4 1044
ADDRGP4 AngleMod
CALLF4
ASGNF4
ADDRLP4 1040
INDIRP4
ADDRLP4 1044
INDIRF4
ASGNF4
line 3541
;3540:	//if the bots should be really challenging
;3541:	if (bot_challenge.integer) {
ADDRGP4 bot_challenge+12
INDIRI4
CNSTI4 0
EQI4 $1413
line 3543
;3542:		//if the bot is really accurate and has the enemy in view for some time
;3543:		if (aim_accuracy > 0.9 && bs->enemysight_time < FloatTime() - 1) {
ADDRLP4 156
INDIRF4
CNSTF4 1063675494
LEF4 $1416
ADDRFP4 0
INDIRP4
CNSTI4 6132
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1065353216
SUBF4
GEF4 $1416
line 3545
;3544:			//set the view angles directly
;3545:			if (bs->ideal_viewangles[PITCH] > 180) bs->ideal_viewangles[PITCH] -= 360;
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
INDIRF4
CNSTF4 1127481344
LEF4 $1418
ADDRLP4 1048
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ASGNP4
ADDRLP4 1048
INDIRP4
ADDRLP4 1048
INDIRP4
INDIRF4
CNSTF4 1135869952
SUBF4
ASGNF4
LABELV $1418
line 3546
;3546:			VectorCopy(bs->ideal_viewangles, bs->viewangles);
ADDRLP4 1052
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1052
INDIRP4
CNSTI4 6564
ADDP4
ADDRLP4 1052
INDIRP4
CNSTI4 6576
ADDP4
INDIRB
ASGNB 12
line 3547
;3547:			trap_EA_View(bs->client, bs->viewangles);
ADDRLP4 1056
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1056
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 1056
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
ADDRGP4 trap_EA_View
CALLV
pop
line 3548
;3548:		}
LABELV $1416
line 3549
;3549:	}
LABELV $1413
line 3550
;3550:}
LABELV $1114
endproc BotAimAtEnemy 1144 52
lit
align 4
LABELV $1421
byte 4 3238002688
byte 4 3238002688
byte 4 3238002688
align 4
LABELV $1422
byte 4 1090519040
byte 4 1090519040
byte 4 1090519040
export BotCheckAttack
code
proc BotCheckAttack 1028 28
line 3557
;3551:
;3552:/*
;3553:==================
;3554:BotCheckAttack
;3555:==================
;3556:*/
;3557:void BotCheckAttack(bot_state_t *bs) {
line 3566
;3558:	float points, reactiontime, fov, firethrottle;
;3559:	int attackentity;
;3560:	bsp_trace_t bsptrace;
;3561:	//float selfpreservation;
;3562:	vec3_t forward, right, start, end, dir, angles;
;3563:	weaponinfo_t wi;
;3564:	bsp_trace_t trace;
;3565:	aas_entityinfo_t entinfo;
;3566:	vec3_t mins = {-8, -8, -8}, maxs = {8, 8, 8};
ADDRLP4 808
ADDRGP4 $1421
INDIRB
ASGNB 12
ADDRLP4 820
ADDRGP4 $1422
INDIRB
ASGNB 12
line 3568
;3567:
;3568:	attackentity = bs->enemy;
ADDRLP4 576
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
ASGNI4
line 3570
;3569:	//
;3570:	BotEntityInfo(attackentity, &entinfo);
ADDRLP4 576
INDIRI4
ARGI4
ADDRLP4 832
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3572
;3571:	// if not attacking a player
;3572:	if (attackentity >= MAX_CLIENTS) {
ADDRLP4 576
INDIRI4
CNSTI4 64
LTI4 $1423
line 3584
;3573:#ifdef MISSIONPACK
;3574:		// if attacking an obelisk
;3575:		if ( entinfo.number == redobelisk.entitynum ||
;3576:			entinfo.number == blueobelisk.entitynum ) {
;3577:			// if obelisk is respawning return
;3578:			if ( g_entities[entinfo.number].activator &&
;3579:				g_entities[entinfo.number].activator->s.frame == 2 ) {
;3580:				return;
;3581:			}
;3582:		}
;3583:#endif
;3584:	}
LABELV $1423
line 3586
;3585:	//
;3586:	reactiontime = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_REACTIONTIME, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 6
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 976
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 700
ADDRLP4 976
INDIRF4
ASGNF4
line 3587
;3587:	if (bs->enemysight_time > FloatTime() - reactiontime) return;
ADDRFP4 0
INDIRP4
CNSTI4 6132
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
ADDRLP4 700
INDIRF4
SUBF4
LEF4 $1425
ADDRGP4 $1420
JUMPV
LABELV $1425
line 3588
;3588:	if (bs->teleport_time > FloatTime() - reactiontime) return;
ADDRFP4 0
INDIRP4
CNSTI4 6180
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
ADDRLP4 700
INDIRF4
SUBF4
LEF4 $1427
ADDRGP4 $1420
JUMPV
LABELV $1427
line 3590
;3589:	//if changing weapons
;3590:	if (bs->weaponchange_time > FloatTime() - 0.1) return;
ADDRFP4 0
INDIRP4
CNSTI4 6192
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1036831949
SUBF4
LEF4 $1429
ADDRGP4 $1420
JUMPV
LABELV $1429
line 3592
;3591:	//check fire throttle characteristic
;3592:	if (bs->firethrottlewait_time > FloatTime()) return;
ADDRFP4 0
INDIRP4
CNSTI4 6196
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
LEF4 $1431
ADDRGP4 $1420
JUMPV
LABELV $1431
line 3593
;3593:	firethrottle = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_FIRETHROTTLE, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 47
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 980
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 792
ADDRLP4 980
INDIRF4
ASGNF4
line 3594
;3594:	if (bs->firethrottleshoot_time < FloatTime()) {
ADDRFP4 0
INDIRP4
CNSTI4 6200
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
GEF4 $1433
line 3595
;3595:		if (random() > firethrottle) {
ADDRLP4 984
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 984
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ADDRLP4 792
INDIRF4
LEF4 $1435
line 3596
;3596:			bs->firethrottlewait_time = FloatTime() + firethrottle;
ADDRFP4 0
INDIRP4
CNSTI4 6196
ADDP4
ADDRGP4 floattime
INDIRF4
ADDRLP4 792
INDIRF4
ADDF4
ASGNF4
line 3597
;3597:			bs->firethrottleshoot_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6200
ADDP4
CNSTF4 0
ASGNF4
line 3598
;3598:		}
ADDRGP4 $1436
JUMPV
LABELV $1435
line 3599
;3599:		else {
line 3600
;3600:			bs->firethrottleshoot_time = FloatTime() + 1 - firethrottle;
ADDRFP4 0
INDIRP4
CNSTI4 6200
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1065353216
ADDF4
ADDRLP4 792
INDIRF4
SUBF4
ASGNF4
line 3601
;3601:			bs->firethrottlewait_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6196
ADDP4
CNSTF4 0
ASGNF4
line 3602
;3602:		}
LABELV $1436
line 3603
;3603:	}
LABELV $1433
line 3606
;3604:	//
;3605:	//
;3606:	VectorSubtract(bs->aimtarget, bs->eye, dir);
ADDRLP4 984
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 580
ADDRLP4 984
INDIRP4
CNSTI4 6220
ADDP4
INDIRF4
ADDRLP4 984
INDIRP4
CNSTI4 4936
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 580+4
ADDRLP4 984
INDIRP4
CNSTI4 6224
ADDP4
INDIRF4
ADDRLP4 984
INDIRP4
CNSTI4 4940
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 988
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 580+8
ADDRLP4 988
INDIRP4
CNSTI4 6228
ADDP4
INDIRF4
ADDRLP4 988
INDIRP4
CNSTI4 4944
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3608
;3607:	//
;3608:	if (bs->weaponnum == WP_GAUNTLET) {
ADDRFP4 0
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
CNSTI4 1
NEI4 $1439
line 3609
;3609:		if (VectorLengthSquared(dir) > Square(60)) {
ADDRLP4 580
ARGP4
ADDRLP4 992
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 992
INDIRF4
CNSTF4 1163984896
LEF4 $1441
line 3610
;3610:			return;
ADDRGP4 $1420
JUMPV
LABELV $1441
line 3612
;3611:		}
;3612:	}
LABELV $1439
line 3613
;3613:	if (VectorLengthSquared(dir) < Square(100))
ADDRLP4 580
ARGP4
ADDRLP4 992
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 992
INDIRF4
CNSTF4 1176256512
GEF4 $1443
line 3614
;3614:		fov = 120;
ADDRLP4 788
CNSTF4 1123024896
ASGNF4
ADDRGP4 $1444
JUMPV
LABELV $1443
line 3616
;3615:	else
;3616:		fov = 50;
ADDRLP4 788
CNSTF4 1112014848
ASGNF4
LABELV $1444
line 3618
;3617:	//
;3618:	vectoangles(dir, angles);
ADDRLP4 580
ARGP4
ADDRLP4 796
ARGP4
ADDRGP4 vectoangles
CALLV
pop
line 3619
;3619:	if (!InFieldOfVision(bs->viewangles, fov, angles))
ADDRFP4 0
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
ADDRLP4 788
INDIRF4
ARGF4
ADDRLP4 796
ARGP4
ADDRLP4 996
ADDRGP4 InFieldOfVision
CALLI4
ASGNI4
ADDRLP4 996
INDIRI4
CNSTI4 0
NEI4 $1445
line 3620
;3620:		return;
ADDRGP4 $1420
JUMPV
LABELV $1445
line 3621
;3621:	BotAI_Trace(&bsptrace, bs->eye, NULL, NULL, bs->aimtarget, bs->client, CONTENTS_SOLID|CONTENTS_PLAYERCLIP);
ADDRLP4 704
ARGP4
ADDRLP4 1000
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1000
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 1004
CNSTP4 0
ASGNP4
ADDRLP4 1004
INDIRP4
ARGP4
ADDRLP4 1004
INDIRP4
ARGP4
ADDRLP4 1000
INDIRP4
CNSTI4 6220
ADDP4
ARGP4
ADDRLP4 1000
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
CNSTI4 65537
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3622
;3622:	if (bsptrace.fraction < 1 && bsptrace.ent != attackentity)
ADDRLP4 704+8
INDIRF4
CNSTF4 1065353216
GEF4 $1447
ADDRLP4 704+80
INDIRI4
ADDRLP4 576
INDIRI4
EQI4 $1447
line 3623
;3623:		return;
ADDRGP4 $1420
JUMPV
LABELV $1447
line 3626
;3624:
;3625:	//get the weapon info
;3626:	trap_BotGetWeaponInfo(bs->ws, bs->weaponnum, &wi);
ADDRLP4 1008
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1008
INDIRP4
CNSTI4 6536
ADDP4
INDIRI4
ARGI4
ADDRLP4 1008
INDIRP4
CNSTI4 6560
ADDP4
INDIRI4
ARGI4
ADDRLP4 24
ARGP4
ADDRGP4 trap_BotGetWeaponInfo
CALLV
pop
line 3628
;3627:	//get the start point shooting from
;3628:	VectorCopy(bs->origin, start);
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 3629
;3629:	start[2] += bs->cur_ps.viewheight;
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 180
ADDP4
INDIRI4
CVIF4 4
ADDF4
ASGNF4
line 3630
;3630:	AngleVectors(bs->viewangles, forward, right, NULL);
ADDRFP4 0
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
ADDRLP4 12
ARGP4
ADDRLP4 676
ARGP4
CNSTP4 0
ARGP4
ADDRGP4 AngleVectors
CALLV
pop
line 3631
;3631:	start[0] += forward[0] * wi.offset[0] + right[0] * wi.offset[1];
ADDRLP4 0
ADDRLP4 0
INDIRF4
ADDRLP4 12
INDIRF4
ADDRLP4 24+292
INDIRF4
MULF4
ADDRLP4 676
INDIRF4
ADDRLP4 24+292+4
INDIRF4
MULF4
ADDF4
ADDF4
ASGNF4
line 3632
;3632:	start[1] += forward[1] * wi.offset[0] + right[1] * wi.offset[1];
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 12+4
INDIRF4
ADDRLP4 24+292
INDIRF4
MULF4
ADDRLP4 676+4
INDIRF4
ADDRLP4 24+292+4
INDIRF4
MULF4
ADDF4
ADDF4
ASGNF4
line 3633
;3633:	start[2] += forward[2] * wi.offset[0] + right[2] * wi.offset[1] + wi.offset[2];
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
ADDRLP4 12+8
INDIRF4
ADDRLP4 24+292
INDIRF4
MULF4
ADDRLP4 676+8
INDIRF4
ADDRLP4 24+292+4
INDIRF4
MULF4
ADDF4
ADDRLP4 24+292+8
INDIRF4
ADDF4
ADDF4
ASGNF4
line 3635
;3634:	//end point aiming at
;3635:	VectorMA(start, 1000, forward, end);
ADDRLP4 1012
CNSTF4 1148846080
ASGNF4
ADDRLP4 688
ADDRLP4 0
INDIRF4
ADDRLP4 1012
INDIRF4
ADDRLP4 12
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 688+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 1012
INDIRF4
ADDRLP4 12+4
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 688+8
ADDRLP4 0+8
INDIRF4
CNSTF4 1148846080
ADDRLP4 12+8
INDIRF4
MULF4
ADDF4
ASGNF4
line 3637
;3636:	//a little back to make sure not inside a very close enemy
;3637:	VectorMA(start, -12, forward, start);
ADDRLP4 1016
CNSTF4 3242196992
ASGNF4
ADDRLP4 0
ADDRLP4 0
INDIRF4
ADDRLP4 1016
INDIRF4
ADDRLP4 12
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 0+4
INDIRF4
ADDRLP4 1016
INDIRF4
ADDRLP4 12+4
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 0+8
INDIRF4
CNSTF4 3242196992
ADDRLP4 12+8
INDIRF4
MULF4
ADDF4
ASGNF4
line 3638
;3638:	BotAI_Trace(&trace, start, mins, maxs, end, bs->entitynum, MASK_SHOT);
ADDRLP4 592
ARGP4
ADDRLP4 0
ARGP4
ADDRLP4 808
ARGP4
ADDRLP4 820
ARGP4
ADDRLP4 688
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3640
;3639:	//if the entity is a client
;3640:	if (trace.ent > 0 && trace.ent <= MAX_CLIENTS) {
ADDRLP4 592+80
INDIRI4
CNSTI4 0
LEI4 $1481
ADDRLP4 592+80
INDIRI4
CNSTI4 64
GTI4 $1481
line 3641
;3641:		if (trace.ent != attackentity) {
ADDRLP4 592+80
INDIRI4
ADDRLP4 576
INDIRI4
EQI4 $1485
line 3643
;3642:			//if a teammate is hit
;3643:			if (BotSameTeam(bs, trace.ent))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 592+80
INDIRI4
ARGI4
ADDRLP4 1020
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 1020
INDIRI4
CNSTI4 0
EQI4 $1488
line 3644
;3644:				return;
ADDRGP4 $1420
JUMPV
LABELV $1488
line 3645
;3645:		}
LABELV $1485
line 3646
;3646:	}
LABELV $1481
line 3648
;3647:	//if won't hit the enemy or not attacking a player (obelisk)
;3648:	if (trace.ent != attackentity || attackentity >= MAX_CLIENTS) {
ADDRLP4 592+80
INDIRI4
ADDRLP4 576
INDIRI4
NEI4 $1494
ADDRLP4 576
INDIRI4
CNSTI4 64
LTI4 $1491
LABELV $1494
line 3650
;3649:		//if the projectile does radial damage
;3650:		if (wi.proj.damagetype & DAMAGETYPE_RADIAL) {
ADDRLP4 24+344+180
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $1495
line 3651
;3651:			if (trace.fraction * 1000 < wi.proj.radius) {
CNSTF4 1148846080
ADDRLP4 592+8
INDIRF4
MULF4
ADDRLP4 24+344+172
INDIRF4
GEF4 $1499
line 3652
;3652:				points = (wi.proj.damage - 0.5 * trace.fraction * 1000) * 0.5;
ADDRLP4 1024
CNSTF4 1056964608
ASGNF4
ADDRLP4 972
ADDRLP4 1024
INDIRF4
ADDRLP4 24+344+168
INDIRI4
CVIF4 4
CNSTF4 1148846080
ADDRLP4 1024
INDIRF4
ADDRLP4 592+8
INDIRF4
MULF4
MULF4
SUBF4
MULF4
ASGNF4
line 3653
;3653:				if (points > 0) {
ADDRLP4 972
INDIRF4
CNSTF4 0
LEF4 $1507
line 3654
;3654:					return;
ADDRGP4 $1420
JUMPV
LABELV $1507
line 3656
;3655:				}
;3656:			}
LABELV $1499
line 3658
;3657:			//FIXME: check if a teammate gets radial damage
;3658:		}
LABELV $1495
line 3659
;3659:	}
LABELV $1491
line 3661
;3660:	//if fire has to be release to activate weapon
;3661:	if (wi.flags & WFL_FIRERELEASED) {
ADDRLP4 24+176
INDIRI4
CNSTI4 1
BANDI4
CNSTI4 0
EQI4 $1509
line 3662
;3662:		if (bs->flags & BFL_ATTACKED) {
ADDRFP4 0
INDIRP4
CNSTI4 5980
ADDP4
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $1510
line 3663
;3663:			trap_EA_Attack(bs->client);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_Attack
CALLV
pop
line 3664
;3664:		}
line 3665
;3665:	}
ADDRGP4 $1510
JUMPV
LABELV $1509
line 3666
;3666:	else {
line 3667
;3667:		trap_EA_Attack(bs->client);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_Attack
CALLV
pop
line 3668
;3668:	}
LABELV $1510
line 3669
;3669:	bs->flags ^= BFL_ATTACKED;
ADDRLP4 1024
ADDRFP4 0
INDIRP4
CNSTI4 5980
ADDP4
ASGNP4
ADDRLP4 1024
INDIRP4
ADDRLP4 1024
INDIRP4
INDIRI4
CNSTI4 2
BXORI4
ASGNI4
line 3670
;3670:}
LABELV $1420
endproc BotCheckAttack 1028 28
lit
align 4
LABELV $1520
byte 4 1143930880
byte 4 1129054208
byte 4 1143472128
align 4
LABELV $1521
byte 4 1148256256
byte 4 1139408896
byte 4 1143603200
align 4
LABELV $1522
byte 4 1134034944
byte 4 1135607808
byte 4 1147535360
export BotMapScripts
code
proc BotMapScripts 1424 16
line 3677
;3671:
;3672:/*
;3673:==================
;3674:BotMapScripts
;3675:==================
;3676:*/
;3677:void BotMapScripts(bot_state_t *bs) {
line 3685
;3678:	char info[1024];
;3679:	char mapname[128];
;3680:	int i, shootbutton;
;3681:	float aim_accuracy;
;3682:	aas_entityinfo_t entinfo;
;3683:	vec3_t dir;
;3684:
;3685:	trap_GetServerinfo(info, sizeof(info));
ADDRLP4 272
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetServerinfo
CALLV
pop
line 3687
;3686:
;3687:	strncpy(mapname, Info_ValueForKey( info, "mapname" ), sizeof(mapname)-1);
ADDRLP4 272
ARGP4
ADDRGP4 $1515
ARGP4
ADDRLP4 1316
ADDRGP4 Info_ValueForKey
CALLP4
ASGNP4
ADDRLP4 144
ARGP4
ADDRLP4 1316
INDIRP4
ARGP4
CNSTI4 127
ARGI4
ADDRGP4 strncpy
CALLP4
pop
line 3688
;3688:	mapname[sizeof(mapname)-1] = '\0';
ADDRLP4 144+127
CNSTI1 0
ASGNI1
line 3690
;3689:
;3690:	if (!Q_stricmp(mapname, "q3tourney6")) {
ADDRLP4 144
ARGP4
ADDRGP4 $1519
ARGP4
ADDRLP4 1320
ADDRGP4 Q_stricmp
CALLI4
ASGNI4
ADDRLP4 1320
INDIRI4
CNSTI4 0
NEI4 $1517
line 3691
;3691:		vec3_t mins = {700, 204, 672}, maxs = {964, 468, 680};
ADDRLP4 1324
ADDRGP4 $1520
INDIRB
ASGNB 12
ADDRLP4 1336
ADDRGP4 $1521
INDIRB
ASGNB 12
line 3692
;3692:		vec3_t buttonorg = {304, 352, 920};
ADDRLP4 1348
ADDRGP4 $1522
INDIRB
ASGNB 12
line 3694
;3693:		//NOTE: NEVER use the func_bobbing in q3tourney6
;3694:		bs->tfl &= ~TFL_FUNCBOB;
ADDRLP4 1360
ADDRFP4 0
INDIRP4
CNSTI4 5976
ADDP4
ASGNP4
ADDRLP4 1360
INDIRP4
ADDRLP4 1360
INDIRP4
INDIRI4
CNSTI4 -16777217
BANDI4
ASGNI4
line 3696
;3695:		//if the bot is below the bounding box
;3696:		if (bs->origin[0] > mins[0] && bs->origin[0] < maxs[0]) {
ADDRLP4 1364
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRF4
ASGNF4
ADDRLP4 1364
INDIRF4
ADDRLP4 1324
INDIRF4
LEF4 $1523
ADDRLP4 1364
INDIRF4
ADDRLP4 1336
INDIRF4
GEF4 $1523
line 3697
;3697:			if (bs->origin[1] > mins[1] && bs->origin[1] < maxs[1]) {
ADDRLP4 1368
ADDRFP4 0
INDIRP4
CNSTI4 4912
ADDP4
INDIRF4
ASGNF4
ADDRLP4 1368
INDIRF4
ADDRLP4 1324+4
INDIRF4
LEF4 $1525
ADDRLP4 1368
INDIRF4
ADDRLP4 1336+4
INDIRF4
GEF4 $1525
line 3698
;3698:				if (bs->origin[2] < mins[2]) {
ADDRFP4 0
INDIRP4
CNSTI4 4916
ADDP4
INDIRF4
ADDRLP4 1324+8
INDIRF4
GEF4 $1529
line 3699
;3699:					return;
ADDRGP4 $1514
JUMPV
LABELV $1529
line 3701
;3700:				}
;3701:			}
LABELV $1525
line 3702
;3702:		}
LABELV $1523
line 3703
;3703:		shootbutton = qfalse;
ADDRLP4 1296
CNSTI4 0
ASGNI4
line 3705
;3704:		//if an enemy is below this bounding box then shoot the button
;3705:		for (i = 0; i < maxclients && i < MAX_CLIENTS; i++) {
ADDRLP4 140
CNSTI4 0
ASGNI4
ADDRGP4 $1535
JUMPV
LABELV $1532
line 3707
;3706:
;3707:			if (i == bs->client) continue;
ADDRLP4 140
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $1536
ADDRGP4 $1533
JUMPV
LABELV $1536
line 3709
;3708:			//
;3709:			BotEntityInfo(i, &entinfo);
ADDRLP4 140
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 3711
;3710:			//
;3711:			if (!entinfo.valid) continue;
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $1538
ADDRGP4 $1533
JUMPV
LABELV $1538
line 3713
;3712:			//if the enemy isn't dead and the enemy isn't the bot self
;3713:			if (EntityIsDead(&entinfo) || entinfo.number == bs->entitynum) continue;
ADDRLP4 0
ARGP4
ADDRLP4 1368
ADDRGP4 EntityIsDead
CALLI4
ASGNI4
ADDRLP4 1368
INDIRI4
CNSTI4 0
NEI4 $1543
ADDRLP4 0+20
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
NEI4 $1540
LABELV $1543
ADDRGP4 $1533
JUMPV
LABELV $1540
line 3715
;3714:			//
;3715:			if (entinfo.origin[0] > mins[0] && entinfo.origin[0] < maxs[0]) {
ADDRLP4 0+24
INDIRF4
ADDRLP4 1324
INDIRF4
LEF4 $1544
ADDRLP4 0+24
INDIRF4
ADDRLP4 1336
INDIRF4
GEF4 $1544
line 3716
;3716:				if (entinfo.origin[1] > mins[1] && entinfo.origin[1] < maxs[1]) {
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 1324+4
INDIRF4
LEF4 $1548
ADDRLP4 0+24+4
INDIRF4
ADDRLP4 1336+4
INDIRF4
GEF4 $1548
line 3717
;3717:					if (entinfo.origin[2] < mins[2]) {
ADDRLP4 0+24+8
INDIRF4
ADDRLP4 1324+8
INDIRF4
GEF4 $1556
line 3719
;3718:						//if there's a team mate below the crusher
;3719:						if (BotSameTeam(bs, i)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 140
INDIRI4
ARGI4
ADDRLP4 1372
ADDRGP4 BotSameTeam
CALLI4
ASGNI4
ADDRLP4 1372
INDIRI4
CNSTI4 0
EQI4 $1561
line 3720
;3720:							shootbutton = qfalse;
ADDRLP4 1296
CNSTI4 0
ASGNI4
line 3721
;3721:							break;
ADDRGP4 $1534
JUMPV
LABELV $1561
line 3723
;3722:						}
;3723:						else {
line 3724
;3724:							shootbutton = qtrue;
ADDRLP4 1296
CNSTI4 1
ASGNI4
line 3725
;3725:						}
line 3726
;3726:					}
LABELV $1556
line 3727
;3727:				}
LABELV $1548
line 3728
;3728:			}
LABELV $1544
line 3729
;3729:		}
LABELV $1533
line 3705
ADDRLP4 140
ADDRLP4 140
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1535
ADDRLP4 140
INDIRI4
ADDRGP4 maxclients
INDIRI4
GEI4 $1563
ADDRLP4 140
INDIRI4
CNSTI4 64
LTI4 $1532
LABELV $1563
LABELV $1534
line 3730
;3730:		if (shootbutton) {
ADDRLP4 1296
INDIRI4
CNSTI4 0
EQI4 $1518
line 3731
;3731:			bs->flags |= BFL_IDEALVIEWSET;
ADDRLP4 1372
ADDRFP4 0
INDIRP4
CNSTI4 5980
ADDP4
ASGNP4
ADDRLP4 1372
INDIRP4
ADDRLP4 1372
INDIRP4
INDIRI4
CNSTI4 32
BORI4
ASGNI4
line 3732
;3732:			VectorSubtract(buttonorg, bs->eye, dir);
ADDRLP4 1376
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1300
ADDRLP4 1348
INDIRF4
ADDRLP4 1376
INDIRP4
CNSTI4 4936
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 1300+4
ADDRLP4 1348+4
INDIRF4
ADDRLP4 1376
INDIRP4
CNSTI4 4940
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 1300+8
ADDRLP4 1348+8
INDIRF4
ADDRFP4 0
INDIRP4
CNSTI4 4944
ADDP4
INDIRF4
SUBF4
ASGNF4
line 3733
;3733:			vectoangles(dir, bs->ideal_viewangles);
ADDRLP4 1300
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ARGP4
ADDRGP4 vectoangles
CALLV
pop
line 3734
;3734:			aim_accuracy = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_AIM_ACCURACY, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 7
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 1380
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 1312
ADDRLP4 1380
INDIRF4
ASGNF4
line 3735
;3735:			bs->ideal_viewangles[PITCH] += 8 * crandom() * (1 - aim_accuracy);
ADDRLP4 1384
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 1388
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ASGNP4
ADDRLP4 1388
INDIRP4
ADDRLP4 1388
INDIRP4
INDIRF4
CNSTF4 1090519040
CNSTF4 1073741824
ADDRLP4 1384
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 1312
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3736
;3736:			bs->ideal_viewangles[PITCH] = AngleMod(bs->ideal_viewangles[PITCH]);
ADDRLP4 1392
ADDRFP4 0
INDIRP4
CNSTI4 6576
ADDP4
ASGNP4
ADDRLP4 1392
INDIRP4
INDIRF4
ARGF4
ADDRLP4 1396
ADDRGP4 AngleMod
CALLF4
ASGNF4
ADDRLP4 1392
INDIRP4
ADDRLP4 1396
INDIRF4
ASGNF4
line 3737
;3737:			bs->ideal_viewangles[YAW] += 8 * crandom() * (1 - aim_accuracy);
ADDRLP4 1400
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 1404
ADDRFP4 0
INDIRP4
CNSTI4 6580
ADDP4
ASGNP4
ADDRLP4 1404
INDIRP4
ADDRLP4 1404
INDIRP4
INDIRF4
CNSTF4 1090519040
CNSTF4 1073741824
ADDRLP4 1400
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1056964608
SUBF4
MULF4
MULF4
CNSTF4 1065353216
ADDRLP4 1312
INDIRF4
SUBF4
MULF4
ADDF4
ASGNF4
line 3738
;3738:			bs->ideal_viewangles[YAW] = AngleMod(bs->ideal_viewangles[YAW]);
ADDRLP4 1408
ADDRFP4 0
INDIRP4
CNSTI4 6580
ADDP4
ASGNP4
ADDRLP4 1408
INDIRP4
INDIRF4
ARGF4
ADDRLP4 1412
ADDRGP4 AngleMod
CALLF4
ASGNF4
ADDRLP4 1408
INDIRP4
ADDRLP4 1412
INDIRF4
ASGNF4
line 3740
;3739:			//
;3740:			if (InFieldOfVision(bs->viewangles, 20, bs->ideal_viewangles)) {
ADDRLP4 1416
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1416
INDIRP4
CNSTI4 6564
ADDP4
ARGP4
CNSTF4 1101004800
ARGF4
ADDRLP4 1416
INDIRP4
CNSTI4 6576
ADDP4
ARGP4
ADDRLP4 1420
ADDRGP4 InFieldOfVision
CALLI4
ASGNI4
ADDRLP4 1420
INDIRI4
CNSTI4 0
EQI4 $1518
line 3741
;3741:				trap_EA_Attack(bs->client);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_Attack
CALLV
pop
line 3742
;3742:			}
line 3743
;3743:		}
line 3744
;3744:	}
ADDRGP4 $1518
JUMPV
LABELV $1517
line 3745
;3745:	else if (!Q_stricmp(mapname, "mpq3tourney6")) {
ADDRLP4 144
ARGP4
ADDRGP4 $1574
ARGP4
ADDRLP4 1324
ADDRGP4 Q_stricmp
CALLI4
ASGNI4
ADDRLP4 1324
INDIRI4
CNSTI4 0
NEI4 $1572
line 3747
;3746:		//NOTE: NEVER use the func_bobbing in mpq3tourney6
;3747:		bs->tfl &= ~TFL_FUNCBOB;
ADDRLP4 1328
ADDRFP4 0
INDIRP4
CNSTI4 5976
ADDP4
ASGNP4
ADDRLP4 1328
INDIRP4
ADDRLP4 1328
INDIRP4
INDIRI4
CNSTI4 -16777217
BANDI4
ASGNI4
line 3748
;3748:	}
LABELV $1572
LABELV $1518
line 3749
;3749:}
LABELV $1514
endproc BotMapScripts 1424 16
data
align 4
LABELV VEC_UP
byte 4 0
byte 4 3212836864
byte 4 0
align 4
LABELV MOVEDIR_UP
byte 4 0
byte 4 0
byte 4 1065353216
align 4
LABELV VEC_DOWN
byte 4 0
byte 4 3221225472
byte 4 0
align 4
LABELV MOVEDIR_DOWN
byte 4 0
byte 4 0
byte 4 3212836864
export BotSetMovedir
code
proc BotSetMovedir 12 16
line 3762
;3750:
;3751:/*
;3752:==================
;3753:BotSetMovedir
;3754:==================
;3755:*/
;3756:// bk001205 - made these static
;3757:static vec3_t VEC_UP		= {0, -1,  0};
;3758:static vec3_t MOVEDIR_UP	= {0,  0,  1};
;3759:static vec3_t VEC_DOWN		= {0, -2,  0};
;3760:static vec3_t MOVEDIR_DOWN	= {0,  0, -1};
;3761:
;3762:void BotSetMovedir(vec3_t angles, vec3_t movedir) {
line 3763
;3763:	if (VectorCompare(angles, VEC_UP)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 VEC_UP
ARGP4
ADDRLP4 0
ADDRGP4 VectorCompare
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 0
EQI4 $1576
line 3764
;3764:		VectorCopy(MOVEDIR_UP, movedir);
ADDRFP4 4
INDIRP4
ADDRGP4 MOVEDIR_UP
INDIRB
ASGNB 12
line 3765
;3765:	}
ADDRGP4 $1577
JUMPV
LABELV $1576
line 3766
;3766:	else if (VectorCompare(angles, VEC_DOWN)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 VEC_DOWN
ARGP4
ADDRLP4 4
ADDRGP4 VectorCompare
CALLI4
ASGNI4
ADDRLP4 4
INDIRI4
CNSTI4 0
EQI4 $1578
line 3767
;3767:		VectorCopy(MOVEDIR_DOWN, movedir);
ADDRFP4 4
INDIRP4
ADDRGP4 MOVEDIR_DOWN
INDIRB
ASGNB 12
line 3768
;3768:	}
ADDRGP4 $1579
JUMPV
LABELV $1578
line 3769
;3769:	else {
line 3770
;3770:		AngleVectors(angles, movedir, NULL, NULL);
ADDRFP4 0
INDIRP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 8
CNSTP4 0
ASGNP4
ADDRLP4 8
INDIRP4
ARGP4
ADDRLP4 8
INDIRP4
ARGP4
ADDRGP4 AngleVectors
CALLV
pop
line 3771
;3771:	}
LABELV $1579
LABELV $1577
line 3772
;3772:}
LABELV $1575
endproc BotSetMovedir 12 16
export BotModelMinsMaxs
proc BotModelMinsMaxs 40 0
line 3781
;3773:
;3774:/*
;3775:==================
;3776:BotModelMinsMaxs
;3777:
;3778:this is ugly
;3779:==================
;3780:*/
;3781:int BotModelMinsMaxs(int modelindex, int eType, int contents, vec3_t mins, vec3_t maxs) {
line 3785
;3782:	gentity_t *ent;
;3783:	int i;
;3784:
;3785:	ent = &g_entities[0];
ADDRLP4 0
ADDRGP4 g_entities
ASGNP4
line 3786
;3786:	for (i = 0; i < level.num_entities; i++, ent++) {
ADDRLP4 4
CNSTI4 0
ASGNI4
ADDRGP4 $1584
JUMPV
LABELV $1581
line 3787
;3787:		if ( !ent->inuse ) {
ADDRLP4 0
INDIRP4
CNSTI4 520
ADDP4
INDIRI4
CNSTI4 0
NEI4 $1586
line 3788
;3788:			continue;
ADDRGP4 $1582
JUMPV
LABELV $1586
line 3790
;3789:		}
;3790:		if ( eType && ent->s.eType != eType) {
ADDRLP4 8
ADDRFP4 4
INDIRI4
ASGNI4
ADDRLP4 8
INDIRI4
CNSTI4 0
EQI4 $1588
ADDRLP4 0
INDIRP4
CNSTI4 4
ADDP4
INDIRI4
ADDRLP4 8
INDIRI4
EQI4 $1588
line 3791
;3791:			continue;
ADDRGP4 $1582
JUMPV
LABELV $1588
line 3793
;3792:		}
;3793:		if ( contents && ent->r.contents != contents) {
ADDRLP4 12
ADDRFP4 8
INDIRI4
ASGNI4
ADDRLP4 12
INDIRI4
CNSTI4 0
EQI4 $1590
ADDRLP4 0
INDIRP4
CNSTI4 460
ADDP4
INDIRI4
ADDRLP4 12
INDIRI4
EQI4 $1590
line 3794
;3794:			continue;
ADDRGP4 $1582
JUMPV
LABELV $1590
line 3796
;3795:		}
;3796:		if (ent->s.modelindex == modelindex) {
ADDRLP4 0
INDIRP4
CNSTI4 160
ADDP4
INDIRI4
ADDRFP4 0
INDIRI4
NEI4 $1592
line 3797
;3797:			if (mins)
ADDRFP4 12
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1594
line 3798
;3798:				VectorAdd(ent->r.currentOrigin, ent->r.mins, mins);
ADDRFP4 12
INDIRP4
ADDRLP4 0
INDIRP4
CNSTI4 488
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 436
ADDP4
INDIRF4
ADDF4
ASGNF4
ADDRFP4 12
INDIRP4
CNSTI4 4
ADDP4
ADDRLP4 0
INDIRP4
CNSTI4 492
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 440
ADDP4
INDIRF4
ADDF4
ASGNF4
ADDRFP4 12
INDIRP4
CNSTI4 8
ADDP4
ADDRLP4 0
INDIRP4
CNSTI4 496
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 444
ADDP4
INDIRF4
ADDF4
ASGNF4
LABELV $1594
line 3799
;3799:			if (maxs)
ADDRFP4 16
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1596
line 3800
;3800:				VectorAdd(ent->r.currentOrigin, ent->r.maxs, maxs);
ADDRFP4 16
INDIRP4
ADDRLP4 0
INDIRP4
CNSTI4 488
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 448
ADDP4
INDIRF4
ADDF4
ASGNF4
ADDRFP4 16
INDIRP4
CNSTI4 4
ADDP4
ADDRLP4 0
INDIRP4
CNSTI4 492
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 452
ADDP4
INDIRF4
ADDF4
ASGNF4
ADDRFP4 16
INDIRP4
CNSTI4 8
ADDP4
ADDRLP4 0
INDIRP4
CNSTI4 496
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 456
ADDP4
INDIRF4
ADDF4
ASGNF4
LABELV $1596
line 3801
;3801:			return i;
ADDRLP4 4
INDIRI4
RETI4
ADDRGP4 $1580
JUMPV
LABELV $1592
line 3803
;3802:		}
;3803:	}
LABELV $1582
line 3786
ADDRLP4 4
ADDRLP4 4
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 808
ADDP4
ASGNP4
LABELV $1584
ADDRLP4 4
INDIRI4
ADDRGP4 level+12
INDIRI4
LTI4 $1581
line 3804
;3804:	if (mins)
ADDRFP4 12
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1598
line 3805
;3805:		VectorClear(mins);
ADDRLP4 8
ADDRFP4 12
INDIRP4
ASGNP4
ADDRLP4 12
CNSTF4 0
ASGNF4
ADDRLP4 8
INDIRP4
CNSTI4 8
ADDP4
ADDRLP4 12
INDIRF4
ASGNF4
ADDRLP4 8
INDIRP4
CNSTI4 4
ADDP4
ADDRLP4 12
INDIRF4
ASGNF4
ADDRLP4 8
INDIRP4
ADDRLP4 12
INDIRF4
ASGNF4
LABELV $1598
line 3806
;3806:	if (maxs)
ADDRFP4 16
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1600
line 3807
;3807:		VectorClear(maxs);
ADDRLP4 16
ADDRFP4 16
INDIRP4
ASGNP4
ADDRLP4 20
CNSTF4 0
ASGNF4
ADDRLP4 16
INDIRP4
CNSTI4 8
ADDP4
ADDRLP4 20
INDIRF4
ASGNF4
ADDRLP4 16
INDIRP4
CNSTI4 4
ADDP4
ADDRLP4 20
INDIRF4
ASGNF4
ADDRLP4 16
INDIRP4
ADDRLP4 20
INDIRF4
ASGNF4
LABELV $1600
line 3808
;3808:	return 0;
CNSTI4 0
RETI4
LABELV $1580
endproc BotModelMinsMaxs 40 0
lit
align 4
LABELV $1603
byte 4 1065353216
byte 4 1065353216
byte 4 1065353216
align 4
LABELV $1604
byte 4 3212836864
byte 4 3212836864
byte 4 3212836864
export BotFuncButtonActivateGoal
code
proc BotFuncButtonActivateGoal 648 28
line 3816
;3809:}
;3810:
;3811:/*
;3812:==================
;3813:BotFuncButtonGoal
;3814:==================
;3815:*/
;3816:int BotFuncButtonActivateGoal(bot_state_t *bs, int bspent, bot_activategoal_t *activategoal) {
line 3822
;3817:	int i, areas[10], numareas, modelindex, entitynum;
;3818:	char model[128];
;3819:	float lip, dist, health, angle;
;3820:	vec3_t size, start, end, mins, maxs, angles, points[10];
;3821:	vec3_t movedir, origin, goalorigin, bboxmins, bboxmaxs;
;3822:	vec3_t extramins = {1, 1, 1}, extramaxs = {-1, -1, -1};
ADDRLP4 304
ADDRGP4 $1603
INDIRB
ASGNB 12
ADDRLP4 316
ADDRGP4 $1604
INDIRB
ASGNB 12
line 3825
;3823:	bsp_trace_t bsptrace;
;3824:
;3825:	activategoal->shoot = qfalse;
ADDRFP4 8
INDIRP4
CNSTI4 72
ADDP4
CNSTI4 0
ASGNI4
line 3826
;3826:	VectorClear(activategoal->target);
ADDRLP4 560
ADDRFP4 8
INDIRP4
ASGNP4
ADDRLP4 564
CNSTF4 0
ASGNF4
ADDRLP4 560
INDIRP4
CNSTI4 88
ADDP4
ADDRLP4 564
INDIRF4
ASGNF4
ADDRLP4 560
INDIRP4
CNSTI4 84
ADDP4
ADDRLP4 564
INDIRF4
ASGNF4
ADDRLP4 560
INDIRP4
CNSTI4 80
ADDP4
ADDRLP4 564
INDIRF4
ASGNF4
line 3828
;3827:	//create a bot goal towards the button
;3828:	trap_AAS_ValueForBSPEpairKey(bspent, "model", model, sizeof(model));
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 $274
ARGP4
ADDRLP4 160
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
pop
line 3829
;3829:	if (!*model)
ADDRLP4 160
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $1605
line 3830
;3830:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1602
JUMPV
LABELV $1605
line 3831
;3831:	modelindex = atoi(model+1);
ADDRLP4 160+1
ARGP4
ADDRLP4 568
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 288
ADDRLP4 568
INDIRI4
ASGNI4
line 3832
;3832:	if (!modelindex)
ADDRLP4 288
INDIRI4
CNSTI4 0
NEI4 $1608
line 3833
;3833:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1602
JUMPV
LABELV $1608
line 3834
;3834:	VectorClear(angles);
ADDRLP4 572
CNSTF4 0
ASGNF4
ADDRLP4 96+8
ADDRLP4 572
INDIRF4
ASGNF4
ADDRLP4 96+4
ADDRLP4 572
INDIRF4
ASGNF4
ADDRLP4 96
ADDRLP4 572
INDIRF4
ASGNF4
line 3835
;3835:	entitynum = BotModelMinsMaxs(modelindex, ET_MOVER, 0, mins, maxs);
ADDRLP4 288
INDIRI4
ARGI4
CNSTI4 4
ARGI4
CNSTI4 0
ARGI4
ADDRLP4 72
ARGP4
ADDRLP4 84
ARGP4
ADDRLP4 576
ADDRGP4 BotModelMinsMaxs
CALLI4
ASGNI4
ADDRLP4 344
ADDRLP4 576
INDIRI4
ASGNI4
line 3837
;3836:	//get the lip of the button
;3837:	trap_AAS_FloatForBSPEpairKey(bspent, "lip", &lip);
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 $1612
ARGP4
ADDRLP4 328
ARGP4
ADDRGP4 trap_AAS_FloatForBSPEpairKey
CALLI4
pop
line 3838
;3838:	if (!lip) lip = 4;
ADDRLP4 328
INDIRF4
CNSTF4 0
NEF4 $1613
ADDRLP4 328
CNSTF4 1082130432
ASGNF4
LABELV $1613
line 3840
;3839:	//get the move direction from the angle
;3840:	trap_AAS_FloatForBSPEpairKey(bspent, "angle", &angle);
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 $1615
ARGP4
ADDRLP4 352
ARGP4
ADDRGP4 trap_AAS_FloatForBSPEpairKey
CALLI4
pop
line 3841
;3841:	VectorSet(angles, 0, angle, 0);
ADDRLP4 96
CNSTF4 0
ASGNF4
ADDRLP4 96+4
ADDRLP4 352
INDIRF4
ASGNF4
ADDRLP4 96+8
CNSTF4 0
ASGNF4
line 3842
;3842:	BotSetMovedir(angles, movedir);
ADDRLP4 96
ARGP4
ADDRLP4 4
ARGP4
ADDRGP4 BotSetMovedir
CALLV
pop
line 3844
;3843:	//button size
;3844:	VectorSubtract(maxs, mins, size);
ADDRLP4 112
ADDRLP4 84
INDIRF4
ADDRLP4 72
INDIRF4
SUBF4
ASGNF4
ADDRLP4 112+4
ADDRLP4 84+4
INDIRF4
ADDRLP4 72+4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 112+8
ADDRLP4 84+8
INDIRF4
ADDRLP4 72+8
INDIRF4
SUBF4
ASGNF4
line 3846
;3845:	//button origin
;3846:	VectorAdd(mins, maxs, origin);
ADDRLP4 16
ADDRLP4 72
INDIRF4
ADDRLP4 84
INDIRF4
ADDF4
ASGNF4
ADDRLP4 16+4
ADDRLP4 72+4
INDIRF4
ADDRLP4 84+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 16+8
ADDRLP4 72+8
INDIRF4
ADDRLP4 84+8
INDIRF4
ADDF4
ASGNF4
line 3847
;3847:	VectorScale(origin, 0.5, origin);
ADDRLP4 580
CNSTF4 1056964608
ASGNF4
ADDRLP4 16
ADDRLP4 580
INDIRF4
ADDRLP4 16
INDIRF4
MULF4
ASGNF4
ADDRLP4 16+4
ADDRLP4 580
INDIRF4
ADDRLP4 16+4
INDIRF4
MULF4
ASGNF4
ADDRLP4 16+8
CNSTF4 1056964608
ADDRLP4 16+8
INDIRF4
MULF4
ASGNF4
line 3849
;3848:	//touch distance of the button
;3849:	dist = fabs(movedir[0]) * size[0] + fabs(movedir[1]) * size[1] + fabs(movedir[2]) * size[2];
ADDRLP4 4
INDIRF4
ARGF4
ADDRLP4 584
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 4+4
INDIRF4
ARGF4
ADDRLP4 588
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 4+8
INDIRF4
ARGF4
ADDRLP4 592
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 28
ADDRLP4 584
INDIRF4
ADDRLP4 112
INDIRF4
MULF4
ADDRLP4 588
INDIRF4
ADDRLP4 112+4
INDIRF4
MULF4
ADDF4
ADDRLP4 592
INDIRF4
ADDRLP4 112+8
INDIRF4
MULF4
ADDF4
ASGNF4
line 3850
;3850:	dist *= 0.5;
ADDRLP4 28
CNSTF4 1056964608
ADDRLP4 28
INDIRF4
MULF4
ASGNF4
line 3852
;3851:	//
;3852:	trap_AAS_FloatForBSPEpairKey(bspent, "health", &health);
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 $1638
ARGP4
ADDRLP4 348
ARGP4
ADDRGP4 trap_AAS_FloatForBSPEpairKey
CALLI4
pop
line 3854
;3853:	//if the button is shootable
;3854:	if (health) {
ADDRLP4 348
INDIRF4
CNSTF4 0
EQF4 $1639
line 3856
;3855:		//calculate the shoot target
;3856:		VectorMA(origin, -dist, movedir, goalorigin);
ADDRLP4 596
ADDRLP4 28
INDIRF4
NEGF4
ASGNF4
ADDRLP4 124
ADDRLP4 16
INDIRF4
ADDRLP4 4
INDIRF4
ADDRLP4 596
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 124+4
ADDRLP4 16+4
INDIRF4
ADDRLP4 4+4
INDIRF4
ADDRLP4 596
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 124+8
ADDRLP4 16+8
INDIRF4
ADDRLP4 4+8
INDIRF4
ADDRLP4 28
INDIRF4
NEGF4
MULF4
ADDF4
ASGNF4
line 3858
;3857:		//
;3858:		VectorCopy(goalorigin, activategoal->target);
ADDRFP4 8
INDIRP4
CNSTI4 80
ADDP4
ADDRLP4 124
INDIRB
ASGNB 12
line 3859
;3859:		activategoal->shoot = qtrue;
ADDRFP4 8
INDIRP4
CNSTI4 72
ADDP4
CNSTI4 1
ASGNI4
line 3861
;3860:		//
;3861:		BotAI_Trace(&bsptrace, bs->eye, NULL, NULL, goalorigin, bs->entitynum, MASK_SHOT);
ADDRLP4 356
ARGP4
ADDRLP4 600
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 600
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 604
CNSTP4 0
ASGNP4
ADDRLP4 604
INDIRP4
ARGP4
ADDRLP4 604
INDIRP4
ARGP4
ADDRLP4 124
ARGP4
ADDRLP4 600
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
CNSTI4 100663297
ARGI4
ADDRGP4 BotAI_Trace
CALLV
pop
line 3863
;3862:		// if the button is visible from the current position
;3863:		if (bsptrace.fraction >= 1.0 || bsptrace.ent == entitynum) {
ADDRLP4 356+8
INDIRF4
CNSTF4 1065353216
GEF4 $1651
ADDRLP4 356+80
INDIRI4
ADDRLP4 344
INDIRI4
NEI4 $1647
LABELV $1651
line 3865
;3864:			//
;3865:			activategoal->goal.entitynum = entitynum; //NOTE: this is the entity number of the shootable button
ADDRFP4 8
INDIRP4
CNSTI4 44
ADDP4
ADDRLP4 344
INDIRI4
ASGNI4
line 3866
;3866:			activategoal->goal.number = 0;
ADDRFP4 8
INDIRP4
CNSTI4 48
ADDP4
CNSTI4 0
ASGNI4
line 3867
;3867:			activategoal->goal.flags = 0;
ADDRFP4 8
INDIRP4
CNSTI4 52
ADDP4
CNSTI4 0
ASGNI4
line 3868
;3868:			VectorCopy(bs->origin, activategoal->goal.origin);
ADDRFP4 8
INDIRP4
CNSTI4 4
ADDP4
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 3869
;3869:			activategoal->goal.areanum = bs->areanum;
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
ADDRFP4 0
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ASGNI4
line 3870
;3870:			VectorSet(activategoal->goal.mins, -8, -8, -8);
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 24
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 28
ADDP4
CNSTF4 3238002688
ASGNF4
line 3871
;3871:			VectorSet(activategoal->goal.maxs, 8, 8, 8);
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 36
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 40
ADDP4
CNSTF4 1090519040
ASGNF4
line 3873
;3872:			//
;3873:			return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1602
JUMPV
LABELV $1647
line 3875
;3874:		}
;3875:		else {
line 3878
;3876:			//create a goal from where the button is visible and shoot at the button from there
;3877:			//add bounding box size to the dist
;3878:			trap_AAS_PresenceTypeBoundingBox(PRESENCE_CROUCH, bboxmins, bboxmaxs);
CNSTI4 4
ARGI4
ADDRLP4 136
ARGP4
ADDRLP4 148
ARGP4
ADDRGP4 trap_AAS_PresenceTypeBoundingBox
CALLV
pop
line 3879
;3879:			for (i = 0; i < 3; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $1652
line 3880
;3880:				if (movedir[i] < 0) dist += fabs(movedir[i]) * fabs(bboxmaxs[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
CNSTF4 0
GEF4 $1656
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 608
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 148
ADDP4
INDIRF4
ARGF4
ADDRLP4 612
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 28
ADDRLP4 28
INDIRF4
ADDRLP4 608
INDIRF4
ADDRLP4 612
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRGP4 $1657
JUMPV
LABELV $1656
line 3881
;3881:				else dist += fabs(movedir[i]) * fabs(bboxmins[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 616
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 136
ADDP4
INDIRF4
ARGF4
ADDRLP4 620
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 28
ADDRLP4 28
INDIRF4
ADDRLP4 616
INDIRF4
ADDRLP4 620
INDIRF4
MULF4
ADDF4
ASGNF4
LABELV $1657
line 3882
;3882:			}
LABELV $1653
line 3879
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 3
LTI4 $1652
line 3884
;3883:			//calculate the goal origin
;3884:			VectorMA(origin, -dist, movedir, goalorigin);
ADDRLP4 608
ADDRLP4 28
INDIRF4
NEGF4
ASGNF4
ADDRLP4 124
ADDRLP4 16
INDIRF4
ADDRLP4 4
INDIRF4
ADDRLP4 608
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 124+4
ADDRLP4 16+4
INDIRF4
ADDRLP4 4+4
INDIRF4
ADDRLP4 608
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 124+8
ADDRLP4 16+8
INDIRF4
ADDRLP4 4+8
INDIRF4
ADDRLP4 28
INDIRF4
NEGF4
MULF4
ADDF4
ASGNF4
line 3886
;3885:			//
;3886:			VectorCopy(goalorigin, start);
ADDRLP4 292
ADDRLP4 124
INDIRB
ASGNB 12
line 3887
;3887:			start[2] += 24;
ADDRLP4 292+8
ADDRLP4 292+8
INDIRF4
CNSTF4 1103101952
ADDF4
ASGNF4
line 3888
;3888:			VectorCopy(start, end);
ADDRLP4 332
ADDRLP4 292
INDIRB
ASGNB 12
line 3889
;3889:			end[2] -= 512;
ADDRLP4 332+8
ADDRLP4 332+8
INDIRF4
CNSTF4 1140850688
SUBF4
ASGNF4
line 3890
;3890:			numareas = trap_AAS_TraceAreas(start, end, areas, points, 10);
ADDRLP4 292
ARGP4
ADDRLP4 332
ARGP4
ADDRLP4 32
ARGP4
ADDRLP4 440
ARGP4
CNSTI4 10
ARGI4
ADDRLP4 612
ADDRGP4 trap_AAS_TraceAreas
CALLI4
ASGNI4
ADDRLP4 108
ADDRLP4 612
INDIRI4
ASGNI4
line 3892
;3891:			//
;3892:			for (i = numareas-1; i >= 0; i--) {
ADDRLP4 0
ADDRLP4 108
INDIRI4
CNSTI4 1
SUBI4
ASGNI4
ADDRGP4 $1669
JUMPV
LABELV $1666
line 3893
;3893:				if (trap_AAS_AreaReachability(areas[i])) {
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 32
ADDP4
INDIRI4
ARGI4
ADDRLP4 616
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 616
INDIRI4
CNSTI4 0
EQI4 $1670
line 3894
;3894:					break;
ADDRGP4 $1668
JUMPV
LABELV $1670
line 3896
;3895:				}
;3896:			}
LABELV $1667
line 3892
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
SUBI4
ASGNI4
LABELV $1669
ADDRLP4 0
INDIRI4
CNSTI4 0
GEI4 $1666
LABELV $1668
line 3897
;3897:			if (i < 0) {
ADDRLP4 0
INDIRI4
CNSTI4 0
GEI4 $1672
line 3899
;3898:				// FIXME: trace forward and maybe in other directions to find a valid area
;3899:			}
LABELV $1672
line 3900
;3900:			if (i >= 0) {
ADDRLP4 0
INDIRI4
CNSTI4 0
LTI4 $1674
line 3902
;3901:				//
;3902:				VectorCopy(points[i], activategoal->goal.origin);
ADDRFP4 8
INDIRP4
CNSTI4 4
ADDP4
CNSTI4 12
ADDRLP4 0
INDIRI4
MULI4
ADDRLP4 440
ADDP4
INDIRB
ASGNB 12
line 3903
;3903:				activategoal->goal.areanum = areas[i];
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 32
ADDP4
INDIRI4
ASGNI4
line 3904
;3904:				VectorSet(activategoal->goal.mins, 8, 8, 8);
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 24
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 28
ADDP4
CNSTF4 1090519040
ASGNF4
line 3905
;3905:				VectorSet(activategoal->goal.maxs, -8, -8, -8);
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 36
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 40
ADDP4
CNSTF4 3238002688
ASGNF4
line 3907
;3906:				//
;3907:				for (i = 0; i < 3; i++)
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $1676
line 3908
;3908:				{
line 3909
;3909:					if (movedir[i] < 0) activategoal->goal.maxs[i] += fabs(movedir[i]) * fabs(extramaxs[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
CNSTF4 0
GEF4 $1680
ADDRLP4 616
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ASGNI4
ADDRLP4 616
INDIRI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 620
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 316
ADDP4
INDIRF4
ARGF4
ADDRLP4 624
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 628
ADDRLP4 616
INDIRI4
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
ADDP4
ASGNP4
ADDRLP4 628
INDIRP4
ADDRLP4 628
INDIRP4
INDIRF4
ADDRLP4 620
INDIRF4
ADDRLP4 624
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRGP4 $1681
JUMPV
LABELV $1680
line 3910
;3910:					else activategoal->goal.mins[i] += fabs(movedir[i]) * fabs(extramins[i]);
ADDRLP4 632
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ASGNI4
ADDRLP4 632
INDIRI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 636
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 304
ADDP4
INDIRF4
ARGF4
ADDRLP4 640
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 644
ADDRLP4 632
INDIRI4
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
ADDP4
ASGNP4
ADDRLP4 644
INDIRP4
ADDRLP4 644
INDIRP4
INDIRF4
ADDRLP4 636
INDIRF4
ADDRLP4 640
INDIRF4
MULF4
ADDF4
ASGNF4
LABELV $1681
line 3911
;3911:				} //end for
LABELV $1677
line 3907
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 3
LTI4 $1676
line 3913
;3912:				//
;3913:				activategoal->goal.entitynum = entitynum;
ADDRFP4 8
INDIRP4
CNSTI4 44
ADDP4
ADDRLP4 344
INDIRI4
ASGNI4
line 3914
;3914:				activategoal->goal.number = 0;
ADDRFP4 8
INDIRP4
CNSTI4 48
ADDP4
CNSTI4 0
ASGNI4
line 3915
;3915:				activategoal->goal.flags = 0;
ADDRFP4 8
INDIRP4
CNSTI4 52
ADDP4
CNSTI4 0
ASGNI4
line 3916
;3916:				return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1602
JUMPV
LABELV $1674
line 3918
;3917:			}
;3918:		}
line 3919
;3919:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1602
JUMPV
LABELV $1639
line 3921
;3920:	}
;3921:	else {
line 3923
;3922:		//add bounding box size to the dist
;3923:		trap_AAS_PresenceTypeBoundingBox(PRESENCE_CROUCH, bboxmins, bboxmaxs);
CNSTI4 4
ARGI4
ADDRLP4 136
ARGP4
ADDRLP4 148
ARGP4
ADDRGP4 trap_AAS_PresenceTypeBoundingBox
CALLV
pop
line 3924
;3924:		for (i = 0; i < 3; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $1682
line 3925
;3925:			if (movedir[i] < 0) dist += fabs(movedir[i]) * fabs(bboxmaxs[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
CNSTF4 0
GEF4 $1686
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 596
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 148
ADDP4
INDIRF4
ARGF4
ADDRLP4 600
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 28
ADDRLP4 28
INDIRF4
ADDRLP4 596
INDIRF4
ADDRLP4 600
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRGP4 $1687
JUMPV
LABELV $1686
line 3926
;3926:			else dist += fabs(movedir[i]) * fabs(bboxmins[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 604
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 136
ADDP4
INDIRF4
ARGF4
ADDRLP4 608
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 28
ADDRLP4 28
INDIRF4
ADDRLP4 604
INDIRF4
ADDRLP4 608
INDIRF4
MULF4
ADDF4
ASGNF4
LABELV $1687
line 3927
;3927:		}
LABELV $1683
line 3924
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 3
LTI4 $1682
line 3929
;3928:		//calculate the goal origin
;3929:		VectorMA(origin, -dist, movedir, goalorigin);
ADDRLP4 596
ADDRLP4 28
INDIRF4
NEGF4
ASGNF4
ADDRLP4 124
ADDRLP4 16
INDIRF4
ADDRLP4 4
INDIRF4
ADDRLP4 596
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 124+4
ADDRLP4 16+4
INDIRF4
ADDRLP4 4+4
INDIRF4
ADDRLP4 596
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 124+8
ADDRLP4 16+8
INDIRF4
ADDRLP4 4+8
INDIRF4
ADDRLP4 28
INDIRF4
NEGF4
MULF4
ADDF4
ASGNF4
line 3931
;3930:		//
;3931:		VectorCopy(goalorigin, start);
ADDRLP4 292
ADDRLP4 124
INDIRB
ASGNB 12
line 3932
;3932:		start[2] += 24;
ADDRLP4 292+8
ADDRLP4 292+8
INDIRF4
CNSTF4 1103101952
ADDF4
ASGNF4
line 3933
;3933:		VectorCopy(start, end);
ADDRLP4 332
ADDRLP4 292
INDIRB
ASGNB 12
line 3934
;3934:		end[2] -= 100;
ADDRLP4 332+8
ADDRLP4 332+8
INDIRF4
CNSTF4 1120403456
SUBF4
ASGNF4
line 3935
;3935:		numareas = trap_AAS_TraceAreas(start, end, areas, NULL, 10);
ADDRLP4 292
ARGP4
ADDRLP4 332
ARGP4
ADDRLP4 32
ARGP4
CNSTP4 0
ARGP4
CNSTI4 10
ARGI4
ADDRLP4 600
ADDRGP4 trap_AAS_TraceAreas
CALLI4
ASGNI4
ADDRLP4 108
ADDRLP4 600
INDIRI4
ASGNI4
line 3937
;3936:		//
;3937:		for (i = 0; i < numareas; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1699
JUMPV
LABELV $1696
line 3938
;3938:			if (trap_AAS_AreaReachability(areas[i])) {
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 32
ADDP4
INDIRI4
ARGI4
ADDRLP4 604
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 604
INDIRI4
CNSTI4 0
EQI4 $1700
line 3939
;3939:				break;
ADDRGP4 $1698
JUMPV
LABELV $1700
line 3941
;3940:			}
;3941:		}
LABELV $1697
line 3937
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1699
ADDRLP4 0
INDIRI4
ADDRLP4 108
INDIRI4
LTI4 $1696
LABELV $1698
line 3942
;3942:		if (i < numareas) {
ADDRLP4 0
INDIRI4
ADDRLP4 108
INDIRI4
GEI4 $1702
line 3944
;3943:			//
;3944:			VectorCopy(origin, activategoal->goal.origin);
ADDRFP4 8
INDIRP4
CNSTI4 4
ADDP4
ADDRLP4 16
INDIRB
ASGNB 12
line 3945
;3945:			activategoal->goal.areanum = areas[i];
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 32
ADDP4
INDIRI4
ASGNI4
line 3946
;3946:			VectorSubtract(mins, origin, activategoal->goal.mins);
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
ADDRLP4 72
INDIRF4
ADDRLP4 16
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 24
ADDP4
ADDRLP4 72+4
INDIRF4
ADDRLP4 16+4
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 28
ADDP4
ADDRLP4 72+8
INDIRF4
ADDRLP4 16+8
INDIRF4
SUBF4
ASGNF4
line 3947
;3947:			VectorSubtract(maxs, origin, activategoal->goal.maxs);
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
ADDRLP4 84
INDIRF4
ADDRLP4 16
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 36
ADDP4
ADDRLP4 84+4
INDIRF4
ADDRLP4 16+4
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 40
ADDP4
ADDRLP4 84+8
INDIRF4
ADDRLP4 16+8
INDIRF4
SUBF4
ASGNF4
line 3949
;3948:			//
;3949:			for (i = 0; i < 3; i++)
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $1712
line 3950
;3950:			{
line 3951
;3951:				if (movedir[i] < 0) activategoal->goal.maxs[i] += fabs(movedir[i]) * fabs(extramaxs[i]);
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 4
ADDP4
INDIRF4
CNSTF4 0
GEF4 $1716
ADDRLP4 604
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ASGNI4
ADDRLP4 604
INDIRI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 608
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 316
ADDP4
INDIRF4
ARGF4
ADDRLP4 612
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 616
ADDRLP4 604
INDIRI4
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
ADDP4
ASGNP4
ADDRLP4 616
INDIRP4
ADDRLP4 616
INDIRP4
INDIRF4
ADDRLP4 608
INDIRF4
ADDRLP4 612
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRGP4 $1717
JUMPV
LABELV $1716
line 3952
;3952:				else activategoal->goal.mins[i] += fabs(movedir[i]) * fabs(extramins[i]);
ADDRLP4 620
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ASGNI4
ADDRLP4 620
INDIRI4
ADDRLP4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 624
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 304
ADDP4
INDIRF4
ARGF4
ADDRLP4 628
ADDRGP4 fabs
CALLF4
ASGNF4
ADDRLP4 632
ADDRLP4 620
INDIRI4
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
ADDP4
ASGNP4
ADDRLP4 632
INDIRP4
ADDRLP4 632
INDIRP4
INDIRF4
ADDRLP4 624
INDIRF4
ADDRLP4 628
INDIRF4
MULF4
ADDF4
ASGNF4
LABELV $1717
line 3953
;3953:			} //end for
LABELV $1713
line 3949
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 3
LTI4 $1712
line 3955
;3954:			//
;3955:			activategoal->goal.entitynum = entitynum;
ADDRFP4 8
INDIRP4
CNSTI4 44
ADDP4
ADDRLP4 344
INDIRI4
ASGNI4
line 3956
;3956:			activategoal->goal.number = 0;
ADDRFP4 8
INDIRP4
CNSTI4 48
ADDP4
CNSTI4 0
ASGNI4
line 3957
;3957:			activategoal->goal.flags = 0;
ADDRFP4 8
INDIRP4
CNSTI4 52
ADDP4
CNSTI4 0
ASGNI4
line 3958
;3958:			return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1602
JUMPV
LABELV $1702
line 3960
;3959:		}
;3960:	}
line 3961
;3961:	return qfalse;
CNSTI4 0
RETI4
LABELV $1602
endproc BotFuncButtonActivateGoal 648 28
export BotFuncDoorActivateGoal
proc BotFuncDoorActivateGoal 1096 20
line 3969
;3962:}
;3963:
;3964:/*
;3965:==================
;3966:BotFuncDoorGoal
;3967:==================
;3968:*/
;3969:int BotFuncDoorActivateGoal(bot_state_t *bs, int bspent, bot_activategoal_t *activategoal) {
line 3975
;3970:	int modelindex, entitynum;
;3971:	char model[MAX_INFO_STRING];
;3972:	vec3_t mins, maxs, origin, angles;
;3973:
;3974:	//shoot at the shootable door
;3975:	trap_AAS_ValueForBSPEpairKey(bspent, "model", model, sizeof(model));
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 $274
ARGP4
ADDRLP4 12
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
pop
line 3976
;3976:	if (!*model)
ADDRLP4 12
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $1719
line 3977
;3977:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1718
JUMPV
LABELV $1719
line 3978
;3978:	modelindex = atoi(model+1);
ADDRLP4 12+1
ARGP4
ADDRLP4 1080
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 1060
ADDRLP4 1080
INDIRI4
ASGNI4
line 3979
;3979:	if (!modelindex)
ADDRLP4 1060
INDIRI4
CNSTI4 0
NEI4 $1722
line 3980
;3980:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1718
JUMPV
LABELV $1722
line 3981
;3981:	VectorClear(angles);
ADDRLP4 1084
CNSTF4 0
ASGNF4
ADDRLP4 1064+8
ADDRLP4 1084
INDIRF4
ASGNF4
ADDRLP4 1064+4
ADDRLP4 1084
INDIRF4
ASGNF4
ADDRLP4 1064
ADDRLP4 1084
INDIRF4
ASGNF4
line 3982
;3982:	entitynum = BotModelMinsMaxs(modelindex, ET_MOVER, 0, mins, maxs);
ADDRLP4 1060
INDIRI4
ARGI4
CNSTI4 4
ARGI4
CNSTI4 0
ARGI4
ADDRLP4 1036
ARGP4
ADDRLP4 1048
ARGP4
ADDRLP4 1088
ADDRGP4 BotModelMinsMaxs
CALLI4
ASGNI4
ADDRLP4 1076
ADDRLP4 1088
INDIRI4
ASGNI4
line 3984
;3983:	//door origin
;3984:	VectorAdd(mins, maxs, origin);
ADDRLP4 0
ADDRLP4 1036
INDIRF4
ADDRLP4 1048
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 1036+4
INDIRF4
ADDRLP4 1048+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 0+8
ADDRLP4 1036+8
INDIRF4
ADDRLP4 1048+8
INDIRF4
ADDF4
ASGNF4
line 3985
;3985:	VectorScale(origin, 0.5, origin);
ADDRLP4 1092
CNSTF4 1056964608
ASGNF4
ADDRLP4 0
ADDRLP4 1092
INDIRF4
ADDRLP4 0
INDIRF4
MULF4
ASGNF4
ADDRLP4 0+4
ADDRLP4 1092
INDIRF4
ADDRLP4 0+4
INDIRF4
MULF4
ASGNF4
ADDRLP4 0+8
CNSTF4 1056964608
ADDRLP4 0+8
INDIRF4
MULF4
ASGNF4
line 3986
;3986:	VectorCopy(origin, activategoal->target);
ADDRFP4 8
INDIRP4
CNSTI4 80
ADDP4
ADDRLP4 0
INDIRB
ASGNB 12
line 3987
;3987:	activategoal->shoot = qtrue;
ADDRFP4 8
INDIRP4
CNSTI4 72
ADDP4
CNSTI4 1
ASGNI4
line 3989
;3988:	//
;3989:	activategoal->goal.entitynum = entitynum; //NOTE: this is the entity number of the shootable door
ADDRFP4 8
INDIRP4
CNSTI4 44
ADDP4
ADDRLP4 1076
INDIRI4
ASGNI4
line 3990
;3990:	activategoal->goal.number = 0;
ADDRFP4 8
INDIRP4
CNSTI4 48
ADDP4
CNSTI4 0
ASGNI4
line 3991
;3991:	activategoal->goal.flags = 0;
ADDRFP4 8
INDIRP4
CNSTI4 52
ADDP4
CNSTI4 0
ASGNI4
line 3992
;3992:	VectorCopy(bs->origin, activategoal->goal.origin);
ADDRFP4 8
INDIRP4
CNSTI4 4
ADDP4
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 3993
;3993:	activategoal->goal.areanum = bs->areanum;
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
ADDRFP4 0
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ASGNI4
line 3994
;3994:	VectorSet(activategoal->goal.mins, -8, -8, -8);
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 24
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 28
ADDP4
CNSTF4 3238002688
ASGNF4
line 3995
;3995:	VectorSet(activategoal->goal.maxs, 8, 8, 8);
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 36
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 40
ADDP4
CNSTF4 1090519040
ASGNF4
line 3996
;3996:	return qtrue;
CNSTI4 1
RETI4
LABELV $1718
endproc BotFuncDoorActivateGoal 1096 20
export BotTriggerMultipleActivateGoal
proc BotTriggerMultipleActivateGoal 300 20
line 4004
;3997:}
;3998:
;3999:/*
;4000:==================
;4001:BotTriggerMultipleGoal
;4002:==================
;4003:*/
;4004:int BotTriggerMultipleActivateGoal(bot_state_t *bs, int bspent, bot_activategoal_t *activategoal) {
line 4010
;4005:	int i, areas[10], numareas, modelindex, entitynum;
;4006:	char model[128];
;4007:	vec3_t start, end, mins, maxs, angles;
;4008:	vec3_t origin, goalorigin;
;4009:
;4010:	activategoal->shoot = qfalse;
ADDRFP4 8
INDIRP4
CNSTI4 72
ADDP4
CNSTI4 0
ASGNI4
line 4011
;4011:	VectorClear(activategoal->target);
ADDRLP4 268
ADDRFP4 8
INDIRP4
ASGNP4
ADDRLP4 272
CNSTF4 0
ASGNF4
ADDRLP4 268
INDIRP4
CNSTI4 88
ADDP4
ADDRLP4 272
INDIRF4
ASGNF4
ADDRLP4 268
INDIRP4
CNSTI4 84
ADDP4
ADDRLP4 272
INDIRF4
ASGNF4
ADDRLP4 268
INDIRP4
CNSTI4 80
ADDP4
ADDRLP4 272
INDIRF4
ASGNF4
line 4013
;4012:	//create a bot goal towards the trigger
;4013:	trap_AAS_ValueForBSPEpairKey(bspent, "model", model, sizeof(model));
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 $274
ARGP4
ADDRLP4 84
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
pop
line 4014
;4014:	if (!*model)
ADDRLP4 84
INDIRI1
CVII4 1
CNSTI4 0
NEI4 $1737
line 4015
;4015:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1736
JUMPV
LABELV $1737
line 4016
;4016:	modelindex = atoi(model+1);
ADDRLP4 84+1
ARGP4
ADDRLP4 276
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 224
ADDRLP4 276
INDIRI4
ASGNI4
line 4017
;4017:	if (!modelindex)
ADDRLP4 224
INDIRI4
CNSTI4 0
NEI4 $1740
line 4018
;4018:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1736
JUMPV
LABELV $1740
line 4019
;4019:	VectorClear(angles);
ADDRLP4 280
CNSTF4 0
ASGNF4
ADDRLP4 240+8
ADDRLP4 280
INDIRF4
ASGNF4
ADDRLP4 240+4
ADDRLP4 280
INDIRF4
ASGNF4
ADDRLP4 240
ADDRLP4 280
INDIRF4
ASGNF4
line 4020
;4020:	entitynum = BotModelMinsMaxs(modelindex, 0, CONTENTS_TRIGGER, mins, maxs);
ADDRLP4 224
INDIRI4
ARGI4
CNSTI4 0
ARGI4
CNSTI4 1073741824
ARGI4
ADDRLP4 60
ARGP4
ADDRLP4 72
ARGP4
ADDRLP4 284
ADDRGP4 BotModelMinsMaxs
CALLI4
ASGNI4
ADDRLP4 264
ADDRLP4 284
INDIRI4
ASGNI4
line 4022
;4021:	//trigger origin
;4022:	VectorAdd(mins, maxs, origin);
ADDRLP4 4
ADDRLP4 60
INDIRF4
ADDRLP4 72
INDIRF4
ADDF4
ASGNF4
ADDRLP4 4+4
ADDRLP4 60+4
INDIRF4
ADDRLP4 72+4
INDIRF4
ADDF4
ASGNF4
ADDRLP4 4+8
ADDRLP4 60+8
INDIRF4
ADDRLP4 72+8
INDIRF4
ADDF4
ASGNF4
line 4023
;4023:	VectorScale(origin, 0.5, origin);
ADDRLP4 288
CNSTF4 1056964608
ASGNF4
ADDRLP4 4
ADDRLP4 288
INDIRF4
ADDRLP4 4
INDIRF4
MULF4
ASGNF4
ADDRLP4 4+4
ADDRLP4 288
INDIRF4
ADDRLP4 4+4
INDIRF4
MULF4
ASGNF4
ADDRLP4 4+8
CNSTF4 1056964608
ADDRLP4 4+8
INDIRF4
MULF4
ASGNF4
line 4024
;4024:	VectorCopy(origin, goalorigin);
ADDRLP4 252
ADDRLP4 4
INDIRB
ASGNB 12
line 4026
;4025:	//
;4026:	VectorCopy(goalorigin, start);
ADDRLP4 212
ADDRLP4 252
INDIRB
ASGNB 12
line 4027
;4027:	start[2] += 24;
ADDRLP4 212+8
ADDRLP4 212+8
INDIRF4
CNSTF4 1103101952
ADDF4
ASGNF4
line 4028
;4028:	VectorCopy(start, end);
ADDRLP4 228
ADDRLP4 212
INDIRB
ASGNB 12
line 4029
;4029:	end[2] -= 100;
ADDRLP4 228+8
ADDRLP4 228+8
INDIRF4
CNSTF4 1120403456
SUBF4
ASGNF4
line 4030
;4030:	numareas = trap_AAS_TraceAreas(start, end, areas, NULL, 10);
ADDRLP4 212
ARGP4
ADDRLP4 228
ARGP4
ADDRLP4 20
ARGP4
CNSTP4 0
ARGP4
CNSTI4 10
ARGI4
ADDRLP4 292
ADDRGP4 trap_AAS_TraceAreas
CALLI4
ASGNI4
ADDRLP4 16
ADDRLP4 292
INDIRI4
ASGNI4
line 4032
;4031:	//
;4032:	for (i = 0; i < numareas; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1759
JUMPV
LABELV $1756
line 4033
;4033:		if (trap_AAS_AreaReachability(areas[i])) {
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 20
ADDP4
INDIRI4
ARGI4
ADDRLP4 296
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 296
INDIRI4
CNSTI4 0
EQI4 $1760
line 4034
;4034:			break;
ADDRGP4 $1758
JUMPV
LABELV $1760
line 4036
;4035:		}
;4036:	}
LABELV $1757
line 4032
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1759
ADDRLP4 0
INDIRI4
ADDRLP4 16
INDIRI4
LTI4 $1756
LABELV $1758
line 4037
;4037:	if (i < numareas) {
ADDRLP4 0
INDIRI4
ADDRLP4 16
INDIRI4
GEI4 $1762
line 4038
;4038:		VectorCopy(origin, activategoal->goal.origin);
ADDRFP4 8
INDIRP4
CNSTI4 4
ADDP4
ADDRLP4 4
INDIRB
ASGNB 12
line 4039
;4039:		activategoal->goal.areanum = areas[i];
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 20
ADDP4
INDIRI4
ASGNI4
line 4040
;4040:		VectorSubtract(mins, origin, activategoal->goal.mins);
ADDRFP4 8
INDIRP4
CNSTI4 20
ADDP4
ADDRLP4 60
INDIRF4
ADDRLP4 4
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 24
ADDP4
ADDRLP4 60+4
INDIRF4
ADDRLP4 4+4
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 28
ADDP4
ADDRLP4 60+8
INDIRF4
ADDRLP4 4+8
INDIRF4
SUBF4
ASGNF4
line 4041
;4041:		VectorSubtract(maxs, origin, activategoal->goal.maxs);
ADDRFP4 8
INDIRP4
CNSTI4 32
ADDP4
ADDRLP4 72
INDIRF4
ADDRLP4 4
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 36
ADDP4
ADDRLP4 72+4
INDIRF4
ADDRLP4 4+4
INDIRF4
SUBF4
ASGNF4
ADDRFP4 8
INDIRP4
CNSTI4 40
ADDP4
ADDRLP4 72+8
INDIRF4
ADDRLP4 4+8
INDIRF4
SUBF4
ASGNF4
line 4043
;4042:		//
;4043:		activategoal->goal.entitynum = entitynum;
ADDRFP4 8
INDIRP4
CNSTI4 44
ADDP4
ADDRLP4 264
INDIRI4
ASGNI4
line 4044
;4044:		activategoal->goal.number = 0;
ADDRFP4 8
INDIRP4
CNSTI4 48
ADDP4
CNSTI4 0
ASGNI4
line 4045
;4045:		activategoal->goal.flags = 0;
ADDRFP4 8
INDIRP4
CNSTI4 52
ADDP4
CNSTI4 0
ASGNI4
line 4046
;4046:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1736
JUMPV
LABELV $1762
line 4048
;4047:	}
;4048:	return qfalse;
CNSTI4 0
RETI4
LABELV $1736
endproc BotTriggerMultipleActivateGoal 300 20
export BotPopFromActivateGoalStack
proc BotPopFromActivateGoalStack 4 8
line 4056
;4049:}
;4050:
;4051:/*
;4052:==================
;4053:BotPopFromActivateGoalStack
;4054:==================
;4055:*/
;4056:int BotPopFromActivateGoalStack(bot_state_t *bs) {
line 4057
;4057:	if (!bs->activatestack)
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $1773
line 4058
;4058:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $1772
JUMPV
LABELV $1773
line 4059
;4059:	BotEnableActivateGoalAreas(bs->activatestack, qtrue);
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ARGP4
CNSTI4 1
ARGI4
ADDRGP4 BotEnableActivateGoalAreas
CALLV
pop
line 4060
;4060:	bs->activatestack->inuse = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
CNSTI4 0
ASGNI4
line 4061
;4061:	bs->activatestack->justused_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
CNSTI4 68
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 4062
;4062:	bs->activatestack = bs->activatestack->next;
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
ASGNP4
ADDRLP4 0
INDIRP4
ADDRLP4 0
INDIRP4
INDIRP4
CNSTI4 240
ADDP4
INDIRP4
ASGNP4
line 4063
;4063:	return qtrue;
CNSTI4 1
RETI4
LABELV $1772
endproc BotPopFromActivateGoalStack 4 8
export BotPushOntoActivateGoalStack
proc BotPushOntoActivateGoalStack 24 12
line 4071
;4064:}
;4065:
;4066:/*
;4067:==================
;4068:BotPushOntoActivateGoalStack
;4069:==================
;4070:*/
;4071:int BotPushOntoActivateGoalStack(bot_state_t *bs, bot_activategoal_t *activategoal) {
line 4075
;4072:	int i, best;
;4073:	float besttime;
;4074:
;4075:	best = -1;
ADDRLP4 8
CNSTI4 -1
ASGNI4
line 4076
;4076:	besttime = FloatTime() + 9999;
ADDRLP4 4
ADDRGP4 floattime
INDIRF4
CNSTF4 1176255488
ADDF4
ASGNF4
line 4078
;4077:	//
;4078:	for (i = 0; i < MAX_ACTIVATESTACK; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $1776
line 4079
;4079:		if (!bs->activategoalheap[i].inuse) {
CNSTI4 244
ADDRLP4 0
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
INDIRI4
CNSTI4 0
NEI4 $1780
line 4080
;4080:			if (bs->activategoalheap[i].justused_time < besttime) {
CNSTI4 244
ADDRLP4 0
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
CNSTI4 68
ADDP4
INDIRF4
ADDRLP4 4
INDIRF4
GEF4 $1782
line 4081
;4081:				besttime = bs->activategoalheap[i].justused_time;
ADDRLP4 4
CNSTI4 244
ADDRLP4 0
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
CNSTI4 68
ADDP4
INDIRF4
ASGNF4
line 4082
;4082:				best = i;
ADDRLP4 8
ADDRLP4 0
INDIRI4
ASGNI4
line 4083
;4083:			}
LABELV $1782
line 4084
;4084:		}
LABELV $1780
line 4085
;4085:	}
LABELV $1777
line 4078
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 8
LTI4 $1776
line 4086
;4086:	if (best != -1) {
ADDRLP4 8
INDIRI4
CNSTI4 -1
EQI4 $1784
line 4087
;4087:		memcpy(&bs->activategoalheap[best], activategoal, sizeof(bot_activategoal_t));
ADDRLP4 12
CNSTI4 244
ASGNI4
ADDRLP4 12
INDIRI4
ADDRLP4 8
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 12
INDIRI4
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 4088
;4088:		bs->activategoalheap[best].inuse = qtrue;
CNSTI4 244
ADDRLP4 8
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
CNSTI4 1
ASGNI4
line 4089
;4089:		bs->activategoalheap[best].next = bs->activatestack;
ADDRLP4 16
ADDRFP4 0
INDIRP4
ASGNP4
CNSTI4 244
ADDRLP4 8
INDIRI4
MULI4
ADDRLP4 16
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
CNSTI4 240
ADDP4
ADDRLP4 16
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ASGNP4
line 4090
;4090:		bs->activatestack = &bs->activategoalheap[best];
ADDRLP4 20
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 20
INDIRP4
CNSTI4 7116
ADDP4
CNSTI4 244
ADDRLP4 8
INDIRI4
MULI4
ADDRLP4 20
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
ASGNP4
line 4091
;4091:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1775
JUMPV
LABELV $1784
line 4093
;4092:	}
;4093:	return qfalse;
CNSTI4 0
RETI4
LABELV $1775
endproc BotPushOntoActivateGoalStack 24 12
export BotClearActivateGoalStack
proc BotClearActivateGoalStack 0 4
line 4101
;4094:}
;4095:
;4096:/*
;4097:==================
;4098:BotClearActivateGoalStack
;4099:==================
;4100:*/
;4101:void BotClearActivateGoalStack(bot_state_t *bs) {
ADDRGP4 $1788
JUMPV
LABELV $1787
line 4103
;4102:	while(bs->activatestack)
;4103:		BotPopFromActivateGoalStack(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotPopFromActivateGoalStack
CALLI4
pop
LABELV $1788
line 4102
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $1787
line 4104
;4104:}
LABELV $1786
endproc BotClearActivateGoalStack 0 4
export BotEnableActivateGoalAreas
proc BotEnableActivateGoalAreas 12 8
line 4111
;4105:
;4106:/*
;4107:==================
;4108:BotEnableActivateGoalAreas
;4109:==================
;4110:*/
;4111:void BotEnableActivateGoalAreas(bot_activategoal_t *activategoal, int enable) {
line 4114
;4112:	int i;
;4113:
;4114:	if (activategoal->areasdisabled == !enable)
ADDRFP4 4
INDIRI4
CNSTI4 0
NEI4 $1794
ADDRLP4 4
CNSTI4 1
ASGNI4
ADDRGP4 $1795
JUMPV
LABELV $1794
ADDRLP4 4
CNSTI4 0
ASGNI4
LABELV $1795
ADDRFP4 0
INDIRP4
CNSTI4 236
ADDP4
INDIRI4
ADDRLP4 4
INDIRI4
NEI4 $1791
line 4115
;4115:		return;
ADDRGP4 $1790
JUMPV
LABELV $1791
line 4116
;4116:	for (i = 0; i < activategoal->numareas; i++)
ADDRLP4 0
CNSTI4 0
ASGNI4
ADDRGP4 $1799
JUMPV
LABELV $1796
line 4117
;4117:		trap_AAS_EnableRoutingArea( activategoal->areas[i], enable );
ADDRLP4 0
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 0
INDIRP4
CNSTI4 104
ADDP4
ADDP4
INDIRI4
ARGI4
ADDRFP4 4
INDIRI4
ARGI4
ADDRGP4 trap_AAS_EnableRoutingArea
CALLI4
pop
LABELV $1797
line 4116
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1799
ADDRLP4 0
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 232
ADDP4
INDIRI4
LTI4 $1796
line 4118
;4118:	activategoal->areasdisabled = !enable;
ADDRFP4 4
INDIRI4
CNSTI4 0
NEI4 $1801
ADDRLP4 8
CNSTI4 1
ASGNI4
ADDRGP4 $1802
JUMPV
LABELV $1801
ADDRLP4 8
CNSTI4 0
ASGNI4
LABELV $1802
ADDRFP4 0
INDIRP4
CNSTI4 236
ADDP4
ADDRLP4 8
INDIRI4
ASGNI4
line 4119
;4119:}
LABELV $1790
endproc BotEnableActivateGoalAreas 12 8
export BotIsGoingToActivateEntity
proc BotIsGoingToActivateEntity 8 0
line 4126
;4120:
;4121:/*
;4122:==================
;4123:BotIsGoingToActivateEntity
;4124:==================
;4125:*/
;4126:int BotIsGoingToActivateEntity(bot_state_t *bs, int entitynum) {
line 4130
;4127:	bot_activategoal_t *a;
;4128:	int i;
;4129:
;4130:	for (a = bs->activatestack; a; a = a->next) {
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ASGNP4
ADDRGP4 $1807
JUMPV
LABELV $1804
line 4131
;4131:		if (a->time < FloatTime())
ADDRLP4 0
INDIRP4
CNSTI4 60
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
GEF4 $1808
line 4132
;4132:			continue;
ADDRGP4 $1805
JUMPV
LABELV $1808
line 4133
;4133:		if (a->goal.entitynum == entitynum)
ADDRLP4 0
INDIRP4
CNSTI4 44
ADDP4
INDIRI4
ADDRFP4 4
INDIRI4
NEI4 $1810
line 4134
;4134:			return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1803
JUMPV
LABELV $1810
line 4135
;4135:	}
LABELV $1805
line 4130
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 240
ADDP4
INDIRP4
ASGNP4
LABELV $1807
ADDRLP4 0
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $1804
line 4136
;4136:	for (i = 0; i < MAX_ACTIVATESTACK; i++) {
ADDRLP4 4
CNSTI4 0
ASGNI4
LABELV $1812
line 4137
;4137:		if (bs->activategoalheap[i].inuse)
CNSTI4 244
ADDRLP4 4
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
INDIRI4
CNSTI4 0
EQI4 $1816
line 4138
;4138:			continue;
ADDRGP4 $1813
JUMPV
LABELV $1816
line 4140
;4139:		//
;4140:		if (bs->activategoalheap[i].goal.entitynum == entitynum) {
CNSTI4 244
ADDRLP4 4
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
CNSTI4 44
ADDP4
INDIRI4
ADDRFP4 4
INDIRI4
NEI4 $1818
line 4142
;4141:			// if the bot went for this goal less than 2 seconds ago
;4142:			if (bs->activategoalheap[i].justused_time > FloatTime() - 2)
CNSTI4 244
ADDRLP4 4
INDIRI4
MULI4
ADDRFP4 0
INDIRP4
CNSTI4 7120
ADDP4
ADDP4
CNSTI4 68
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1073741824
SUBF4
LEF4 $1820
line 4143
;4143:				return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1803
JUMPV
LABELV $1820
line 4144
;4144:		}
LABELV $1818
line 4145
;4145:	}
LABELV $1813
line 4136
ADDRLP4 4
ADDRLP4 4
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 4
INDIRI4
CNSTI4 8
LTI4 $1812
line 4146
;4146:	return qfalse;
CNSTI4 0
RETI4
LABELV $1803
endproc BotIsGoingToActivateEntity 8 0
export BotGetActivateGoal
proc BotGetActivateGoal 3320 20
line 4159
;4147:}
;4148:
;4149:/*
;4150:==================
;4151:BotGetActivateGoal
;4152:
;4153:  returns the number of the bsp entity to activate
;4154:  goal->entitynum will be set to the game entity to activate
;4155:==================
;4156:*/
;4157://#define OBSTACLEDEBUG
;4158:
;4159:int BotGetActivateGoal(bot_state_t *bs, int entitynum, bot_activategoal_t *activategoal) {
line 4169
;4160:	int i, ent, cur_entities[10], spawnflags, modelindex, areas[MAX_ACTIVATEAREAS*2], numareas, t;
;4161:	char model[MAX_INFO_STRING], tmpmodel[128];
;4162:	char target[128], classname[128];
;4163:	float health;
;4164:	char targetname[10][128];
;4165:	aas_entityinfo_t entinfo;
;4166:	aas_areainfo_t areainfo;
;4167:	vec3_t origin, angles, absmins, absmaxs;
;4168:
;4169:	memset(activategoal, 0, sizeof(bot_activategoal_t));
ADDRFP4 8
INDIRP4
ARGP4
CNSTI4 0
ARGI4
CNSTI4 244
ARGI4
ADDRGP4 memset
CALLP4
pop
line 4170
;4170:	BotEntityInfo(entitynum, &entinfo);
ADDRFP4 4
INDIRI4
ARGI4
ADDRLP4 3052
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 4171
;4171:	Com_sprintf(model, sizeof( model ), "*%d", entinfo.modelindex);
ADDRLP4 1712
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 $1823
ARGP4
ADDRLP4 3052+104
INDIRI4
ARGI4
ADDRGP4 Com_sprintf
CALLV
pop
line 4172
;4172:	for (ent = trap_AAS_NextBSPEntity(0); ent; ent = trap_AAS_NextBSPEntity(ent)) {
CNSTI4 0
ARGI4
ADDRLP4 3252
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 3252
INDIRI4
ASGNI4
ADDRGP4 $1828
JUMPV
LABELV $1825
line 4173
;4173:		if (!trap_AAS_ValueForBSPEpairKey(ent, "model", tmpmodel, sizeof(tmpmodel))) continue;
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $274
ARGP4
ADDRLP4 1584
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 3256
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3256
INDIRI4
CNSTI4 0
NEI4 $1829
ADDRGP4 $1826
JUMPV
LABELV $1829
line 4174
;4174:		if (!strcmp(model, tmpmodel)) break;
ADDRLP4 1712
ARGP4
ADDRLP4 1584
ARGP4
ADDRLP4 3260
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3260
INDIRI4
CNSTI4 0
NEI4 $1831
ADDRGP4 $1827
JUMPV
LABELV $1831
line 4175
;4175:	}
LABELV $1826
line 4172
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 3256
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 3256
INDIRI4
ASGNI4
LABELV $1828
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $1825
LABELV $1827
line 4176
;4176:	if (!ent) {
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $1833
line 4177
;4177:		BotAI_Print(PRT_ERROR, "BotGetActivateGoal: no entity found with model %s\n", model);
CNSTI4 3
ARGI4
ADDRGP4 $1835
ARGP4
ADDRLP4 1712
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4178
;4178:		return 0;
CNSTI4 0
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1833
line 4180
;4179:	}
;4180:	trap_AAS_ValueForBSPEpairKey(ent, "classname", classname, sizeof(classname));
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1836
ARGP4
ADDRLP4 1456
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
pop
line 4181
;4181:	if (!classname) {
ADDRLP4 1456
CVPU4 4
CNSTU4 0
NEU4 $1837
line 4182
;4182:		BotAI_Print(PRT_ERROR, "BotGetActivateGoal: entity with model %s has no classname\n", model);
CNSTI4 3
ARGI4
ADDRGP4 $1839
ARGP4
ADDRLP4 1712
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4183
;4183:		return 0;
CNSTI4 0
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1837
line 4186
;4184:	}
;4185:	//if it is a door
;4186:	if (!strcmp(classname, "func_door")) {
ADDRLP4 1456
ARGP4
ADDRGP4 $1842
ARGP4
ADDRLP4 3260
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3260
INDIRI4
CNSTI4 0
NEI4 $1840
line 4187
;4187:		if (trap_AAS_FloatForBSPEpairKey(ent, "health", &health)) {
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1638
ARGP4
ADDRLP4 3208
ARGP4
ADDRLP4 3264
ADDRGP4 trap_AAS_FloatForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3264
INDIRI4
CNSTI4 0
EQI4 $1843
line 4189
;4188:			//if the door has health then the door must be shot to open
;4189:			if (health) {
ADDRLP4 3208
INDIRF4
CNSTF4 0
EQF4 $1845
line 4190
;4190:				BotFuncDoorActivateGoal(bs, ent, activategoal);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRFP4 8
INDIRP4
ARGP4
ADDRGP4 BotFuncDoorActivateGoal
CALLI4
pop
line 4191
;4191:				return ent;
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1845
line 4193
;4192:			}
;4193:		}
LABELV $1843
line 4195
;4194:		//
;4195:		trap_AAS_IntForBSPEpairKey(ent, "spawnflags", &spawnflags);
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1847
ARGP4
ADDRLP4 3204
ARGP4
ADDRGP4 trap_AAS_IntForBSPEpairKey
CALLI4
pop
line 4197
;4196:		// if the door starts open then just wait for the door to return
;4197:		if ( spawnflags & 1 )
ADDRLP4 3204
INDIRI4
CNSTI4 1
BANDI4
CNSTI4 0
EQI4 $1848
line 4198
;4198:			return 0;
CNSTI4 0
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1848
line 4200
;4199:		//get the door origin
;4200:		if (!trap_AAS_VectorForBSPEpairKey(ent, "origin", origin)) {
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1852
ARGP4
ADDRLP4 3192
ARGP4
ADDRLP4 3268
ADDRGP4 trap_AAS_VectorForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3268
INDIRI4
CNSTI4 0
NEI4 $1850
line 4201
;4201:			VectorClear(origin);
ADDRLP4 3272
CNSTF4 0
ASGNF4
ADDRLP4 3192+8
ADDRLP4 3272
INDIRF4
ASGNF4
ADDRLP4 3192+4
ADDRLP4 3272
INDIRF4
ASGNF4
ADDRLP4 3192
ADDRLP4 3272
INDIRF4
ASGNF4
line 4202
;4202:		}
LABELV $1850
line 4204
;4203:		//if the door is open or opening already
;4204:		if (!VectorCompare(origin, entinfo.origin))
ADDRLP4 3192
ARGP4
ADDRLP4 3052+24
ARGP4
ADDRLP4 3272
ADDRGP4 VectorCompare
CALLI4
ASGNI4
ADDRLP4 3272
INDIRI4
CNSTI4 0
NEI4 $1855
line 4205
;4205:			return 0;
CNSTI4 0
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1855
line 4207
;4206:		// store all the areas the door is in
;4207:		trap_AAS_ValueForBSPEpairKey(ent, "model", model, sizeof(model));
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $274
ARGP4
ADDRLP4 1712
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
pop
line 4208
;4208:		if (*model) {
ADDRLP4 1712
INDIRI1
CVII4 1
CNSTI4 0
EQI4 $1858
line 4209
;4209:			modelindex = atoi(model+1);
ADDRLP4 1712+1
ARGP4
ADDRLP4 3276
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 3212
ADDRLP4 3276
INDIRI4
ASGNI4
line 4210
;4210:			if (modelindex) {
ADDRLP4 3212
INDIRI4
CNSTI4 0
EQI4 $1861
line 4211
;4211:				VectorClear(angles);
ADDRLP4 3280
CNSTF4 0
ASGNF4
ADDRLP4 3216+8
ADDRLP4 3280
INDIRF4
ASGNF4
ADDRLP4 3216+4
ADDRLP4 3280
INDIRF4
ASGNF4
ADDRLP4 3216
ADDRLP4 3280
INDIRF4
ASGNF4
line 4212
;4212:				BotModelMinsMaxs(modelindex, ET_MOVER, 0, absmins, absmaxs);
ADDRLP4 3212
INDIRI4
ARGI4
CNSTI4 4
ARGI4
CNSTI4 0
ARGI4
ADDRLP4 3228
ARGP4
ADDRLP4 3240
ARGP4
ADDRGP4 BotModelMinsMaxs
CALLI4
pop
line 4214
;4213:				//
;4214:				numareas = trap_AAS_BBoxAreas(absmins, absmaxs, areas, MAX_ACTIVATEAREAS*2);
ADDRLP4 3228
ARGP4
ADDRLP4 3240
ARGP4
ADDRLP4 2740
ARGP4
CNSTI4 64
ARGI4
ADDRLP4 3284
ADDRGP4 trap_AAS_BBoxAreas
CALLI4
ASGNI4
ADDRLP4 3048
ADDRLP4 3284
INDIRI4
ASGNI4
line 4216
;4215:				// store the areas with reachabilities first
;4216:				for (i = 0; i < numareas; i++) {
ADDRLP4 132
CNSTI4 0
ASGNI4
ADDRGP4 $1868
JUMPV
LABELV $1865
line 4217
;4217:					if (activategoal->numareas >= MAX_ACTIVATEAREAS)
ADDRFP4 8
INDIRP4
CNSTI4 232
ADDP4
INDIRI4
CNSTI4 32
LTI4 $1869
line 4218
;4218:						break;
ADDRGP4 $1867
JUMPV
LABELV $1869
line 4219
;4219:					if ( !trap_AAS_AreaReachability(areas[i]) ) {
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 2740
ADDP4
INDIRI4
ARGI4
ADDRLP4 3288
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 3288
INDIRI4
CNSTI4 0
NEI4 $1871
line 4220
;4220:						continue;
ADDRGP4 $1866
JUMPV
LABELV $1871
line 4222
;4221:					}
;4222:					trap_AAS_AreaInfo(areas[i], &areainfo);
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 2740
ADDP4
INDIRI4
ARGI4
ADDRLP4 2996
ARGP4
ADDRGP4 trap_AAS_AreaInfo
CALLI4
pop
line 4223
;4223:					if (areainfo.contents & AREACONTENTS_MOVER) {
ADDRLP4 2996
INDIRI4
CNSTI4 1024
BANDI4
CNSTI4 0
EQI4 $1873
line 4224
;4224:						activategoal->areas[activategoal->numareas++] = areas[i];
ADDRLP4 3296
ADDRFP4 8
INDIRP4
CNSTI4 232
ADDP4
ASGNP4
ADDRLP4 3292
ADDRLP4 3296
INDIRP4
INDIRI4
ASGNI4
ADDRLP4 3296
INDIRP4
ADDRLP4 3292
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 3300
CNSTI4 2
ASGNI4
ADDRLP4 3292
INDIRI4
ADDRLP4 3300
INDIRI4
LSHI4
ADDRFP4 8
INDIRP4
CNSTI4 104
ADDP4
ADDP4
ADDRLP4 132
INDIRI4
ADDRLP4 3300
INDIRI4
LSHI4
ADDRLP4 2740
ADDP4
INDIRI4
ASGNI4
line 4225
;4225:					}
LABELV $1873
line 4226
;4226:				}
LABELV $1866
line 4216
ADDRLP4 132
ADDRLP4 132
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1868
ADDRLP4 132
INDIRI4
ADDRLP4 3048
INDIRI4
LTI4 $1865
LABELV $1867
line 4228
;4227:				// store any remaining areas
;4228:				for (i = 0; i < numareas; i++) {
ADDRLP4 132
CNSTI4 0
ASGNI4
ADDRGP4 $1878
JUMPV
LABELV $1875
line 4229
;4229:					if (activategoal->numareas >= MAX_ACTIVATEAREAS)
ADDRFP4 8
INDIRP4
CNSTI4 232
ADDP4
INDIRI4
CNSTI4 32
LTI4 $1879
line 4230
;4230:						break;
ADDRGP4 $1877
JUMPV
LABELV $1879
line 4231
;4231:					if ( trap_AAS_AreaReachability(areas[i]) ) {
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 2740
ADDP4
INDIRI4
ARGI4
ADDRLP4 3288
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 3288
INDIRI4
CNSTI4 0
EQI4 $1881
line 4232
;4232:						continue;
ADDRGP4 $1876
JUMPV
LABELV $1881
line 4234
;4233:					}
;4234:					trap_AAS_AreaInfo(areas[i], &areainfo);
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 2740
ADDP4
INDIRI4
ARGI4
ADDRLP4 2996
ARGP4
ADDRGP4 trap_AAS_AreaInfo
CALLI4
pop
line 4235
;4235:					if (areainfo.contents & AREACONTENTS_MOVER) {
ADDRLP4 2996
INDIRI4
CNSTI4 1024
BANDI4
CNSTI4 0
EQI4 $1883
line 4236
;4236:						activategoal->areas[activategoal->numareas++] = areas[i];
ADDRLP4 3296
ADDRFP4 8
INDIRP4
CNSTI4 232
ADDP4
ASGNP4
ADDRLP4 3292
ADDRLP4 3296
INDIRP4
INDIRI4
ASGNI4
ADDRLP4 3296
INDIRP4
ADDRLP4 3292
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 3300
CNSTI4 2
ASGNI4
ADDRLP4 3292
INDIRI4
ADDRLP4 3300
INDIRI4
LSHI4
ADDRFP4 8
INDIRP4
CNSTI4 104
ADDP4
ADDP4
ADDRLP4 132
INDIRI4
ADDRLP4 3300
INDIRI4
LSHI4
ADDRLP4 2740
ADDP4
INDIRI4
ASGNI4
line 4237
;4237:					}
LABELV $1883
line 4238
;4238:				}
LABELV $1876
line 4228
ADDRLP4 132
ADDRLP4 132
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
LABELV $1878
ADDRLP4 132
INDIRI4
ADDRLP4 3048
INDIRI4
LTI4 $1875
LABELV $1877
line 4239
;4239:			}
LABELV $1861
line 4240
;4240:		}
LABELV $1858
line 4241
;4241:	}
LABELV $1840
line 4243
;4242:	// if the bot is blocked by or standing on top of a button
;4243:	if (!strcmp(classname, "func_button")) {
ADDRLP4 1456
ARGP4
ADDRGP4 $1887
ARGP4
ADDRLP4 3264
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3264
INDIRI4
CNSTI4 0
NEI4 $1885
line 4244
;4244:		return 0;
CNSTI4 0
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1885
line 4247
;4245:	}
;4246:	// get the targetname so we can find an entity with a matching target
;4247:	if (!trap_AAS_ValueForBSPEpairKey(ent, "targetname", targetname[0], sizeof(targetname[0]))) {
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1890
ARGP4
ADDRLP4 136
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 3268
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3268
INDIRI4
CNSTI4 0
NEI4 $1888
line 4248
;4248:		if (bot_developer.integer) {
ADDRGP4 bot_developer+12
INDIRI4
CNSTI4 0
EQI4 $1891
line 4249
;4249:			BotAI_Print(PRT_ERROR, "BotGetActivateGoal: entity with model \"%s\" has no targetname\n", model);
CNSTI4 3
ARGI4
ADDRGP4 $1894
ARGP4
ADDRLP4 1712
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4250
;4250:		}
LABELV $1891
line 4251
;4251:		return 0;
CNSTI4 0
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1888
line 4254
;4252:	}
;4253:	// allow tree-like activation
;4254:	cur_entities[0] = trap_AAS_NextBSPEntity(0);
CNSTI4 0
ARGI4
ADDRLP4 3272
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 1416
ADDRLP4 3272
INDIRI4
ASGNI4
line 4255
;4255:	for (i = 0; i >= 0 && i < 10;) {
ADDRLP4 132
CNSTI4 0
ASGNI4
ADDRGP4 $1898
JUMPV
LABELV $1895
line 4256
;4256:		for (ent = cur_entities[i]; ent; ent = trap_AAS_NextBSPEntity(ent)) {
ADDRLP4 0
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 1416
ADDP4
INDIRI4
ASGNI4
ADDRGP4 $1902
JUMPV
LABELV $1899
line 4257
;4257:			if (!trap_AAS_ValueForBSPEpairKey(ent, "target", target, sizeof(target))) continue;
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1905
ARGP4
ADDRLP4 4
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 3276
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3276
INDIRI4
CNSTI4 0
NEI4 $1903
ADDRGP4 $1900
JUMPV
LABELV $1903
line 4258
;4258:			if (!strcmp(targetname[i], target)) {
ADDRLP4 132
INDIRI4
CNSTI4 7
LSHI4
ADDRLP4 136
ADDP4
ARGP4
ADDRLP4 4
ARGP4
ADDRLP4 3280
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3280
INDIRI4
CNSTI4 0
NEI4 $1906
line 4259
;4259:				cur_entities[i] = trap_AAS_NextBSPEntity(ent);
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 3284
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 1416
ADDP4
ADDRLP4 3284
INDIRI4
ASGNI4
line 4260
;4260:				break;
ADDRGP4 $1901
JUMPV
LABELV $1906
line 4262
;4261:			}
;4262:		}
LABELV $1900
line 4256
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 3276
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 3276
INDIRI4
ASGNI4
LABELV $1902
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $1899
LABELV $1901
line 4263
;4263:		if (!ent) {
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $1908
line 4264
;4264:			if (bot_developer.integer) {
ADDRGP4 bot_developer+12
INDIRI4
CNSTI4 0
EQI4 $1910
line 4265
;4265:				BotAI_Print(PRT_ERROR, "BotGetActivateGoal: no entity with target \"%s\"\n", targetname[i]);
CNSTI4 3
ARGI4
ADDRGP4 $1913
ARGP4
ADDRLP4 132
INDIRI4
CNSTI4 7
LSHI4
ADDRLP4 136
ADDP4
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4266
;4266:			}
LABELV $1910
line 4267
;4267:			i--;
ADDRLP4 132
ADDRLP4 132
INDIRI4
CNSTI4 1
SUBI4
ASGNI4
line 4268
;4268:			continue;
ADDRGP4 $1896
JUMPV
LABELV $1908
line 4270
;4269:		}
;4270:		if (!trap_AAS_ValueForBSPEpairKey(ent, "classname", classname, sizeof(classname))) {
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1836
ARGP4
ADDRLP4 1456
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 3280
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3280
INDIRI4
CNSTI4 0
NEI4 $1914
line 4271
;4271:			if (bot_developer.integer) {
ADDRGP4 bot_developer+12
INDIRI4
CNSTI4 0
EQI4 $1896
line 4272
;4272:				BotAI_Print(PRT_ERROR, "BotGetActivateGoal: entity with target \"%s\" has no classname\n", targetname[i]);
CNSTI4 3
ARGI4
ADDRGP4 $1919
ARGP4
ADDRLP4 132
INDIRI4
CNSTI4 7
LSHI4
ADDRLP4 136
ADDP4
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4273
;4273:			}
line 4274
;4274:			continue;
ADDRGP4 $1896
JUMPV
LABELV $1914
line 4277
;4275:		}
;4276:		// BSP button model
;4277:		if (!strcmp(classname, "func_button")) {
ADDRLP4 1456
ARGP4
ADDRGP4 $1887
ARGP4
ADDRLP4 3284
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3284
INDIRI4
CNSTI4 0
NEI4 $1920
line 4279
;4278:			//
;4279:			if (!BotFuncButtonActivateGoal(bs, ent, activategoal))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRFP4 8
INDIRP4
ARGP4
ADDRLP4 3288
ADDRGP4 BotFuncButtonActivateGoal
CALLI4
ASGNI4
ADDRLP4 3288
INDIRI4
CNSTI4 0
NEI4 $1922
line 4280
;4280:				continue;
ADDRGP4 $1896
JUMPV
LABELV $1922
line 4282
;4281:			// if the bot tries to activate this button already
;4282:			if ( bs->activatestack && bs->activatestack->inuse &&
ADDRLP4 3292
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ASGNP4
ADDRLP4 3292
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1924
ADDRLP4 3292
INDIRP4
INDIRI4
CNSTI4 0
EQI4 $1924
ADDRLP4 3296
CNSTI4 44
ASGNI4
ADDRLP4 3292
INDIRP4
ADDRLP4 3296
INDIRI4
ADDP4
INDIRI4
ADDRFP4 8
INDIRP4
ADDRLP4 3296
INDIRI4
ADDP4
INDIRI4
NEI4 $1924
ADDRLP4 3300
ADDRGP4 floattime
INDIRF4
ASGNF4
ADDRLP4 3292
INDIRP4
CNSTI4 60
ADDP4
INDIRF4
ADDRLP4 3300
INDIRF4
LEF4 $1924
ADDRLP4 3292
INDIRP4
CNSTI4 64
ADDP4
INDIRF4
ADDRLP4 3300
INDIRF4
CNSTF4 1073741824
SUBF4
GEF4 $1924
line 4286
;4283:				 bs->activatestack->goal.entitynum == activategoal->goal.entitynum &&
;4284:				 bs->activatestack->time > FloatTime() &&
;4285:				 bs->activatestack->start_time < FloatTime() - 2)
;4286:				continue;
ADDRGP4 $1896
JUMPV
LABELV $1924
line 4288
;4287:			// if the bot is in a reachability area
;4288:			if ( trap_AAS_AreaReachability(bs->areanum) ) {
ADDRFP4 0
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 3304
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 3304
INDIRI4
CNSTI4 0
EQI4 $1926
line 4290
;4289:				// disable all areas the blocking entity is in
;4290:				BotEnableActivateGoalAreas( activategoal, qfalse );
ADDRFP4 8
INDIRP4
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 BotEnableActivateGoalAreas
CALLV
pop
line 4292
;4291:				//
;4292:				t = trap_AAS_AreaTravelTimeToGoalArea(bs->areanum, bs->origin, activategoal->goal.areanum, bs->tfl);
ADDRLP4 3308
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 3308
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 3308
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
INDIRI4
ARGI4
ADDRLP4 3308
INDIRP4
CNSTI4 5976
ADDP4
INDIRI4
ARGI4
ADDRLP4 3312
ADDRGP4 trap_AAS_AreaTravelTimeToGoalArea
CALLI4
ASGNI4
ADDRLP4 2736
ADDRLP4 3312
INDIRI4
ASGNI4
line 4294
;4293:				// if the button is not reachable
;4294:				if (!t) {
ADDRLP4 2736
INDIRI4
CNSTI4 0
NEI4 $1928
line 4295
;4295:					continue;
ADDRGP4 $1896
JUMPV
LABELV $1928
line 4297
;4296:				}
;4297:				activategoal->time = FloatTime() + t * 0.01 + 5;
ADDRFP4 8
INDIRP4
CNSTI4 60
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1008981770
ADDRLP4 2736
INDIRI4
CVIF4 4
MULF4
ADDF4
CNSTF4 1084227584
ADDF4
ASGNF4
line 4298
;4298:			}
LABELV $1926
line 4299
;4299:			return ent;
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1920
line 4302
;4300:		}
;4301:		// invisible trigger multiple box
;4302:		else if (!strcmp(classname, "trigger_multiple")) {
ADDRLP4 1456
ARGP4
ADDRGP4 $1932
ARGP4
ADDRLP4 3288
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3288
INDIRI4
CNSTI4 0
NEI4 $1930
line 4304
;4303:			//
;4304:			if (!BotTriggerMultipleActivateGoal(bs, ent, activategoal))
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
INDIRI4
ARGI4
ADDRFP4 8
INDIRP4
ARGP4
ADDRLP4 3292
ADDRGP4 BotTriggerMultipleActivateGoal
CALLI4
ASGNI4
ADDRLP4 3292
INDIRI4
CNSTI4 0
NEI4 $1933
line 4305
;4305:				continue;
ADDRGP4 $1896
JUMPV
LABELV $1933
line 4307
;4306:			// if the bot tries to activate this trigger already
;4307:			if ( bs->activatestack && bs->activatestack->inuse &&
ADDRLP4 3296
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ASGNP4
ADDRLP4 3296
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1935
ADDRLP4 3296
INDIRP4
INDIRI4
CNSTI4 0
EQI4 $1935
ADDRLP4 3300
CNSTI4 44
ASGNI4
ADDRLP4 3296
INDIRP4
ADDRLP4 3300
INDIRI4
ADDP4
INDIRI4
ADDRFP4 8
INDIRP4
ADDRLP4 3300
INDIRI4
ADDP4
INDIRI4
NEI4 $1935
ADDRLP4 3304
ADDRGP4 floattime
INDIRF4
ASGNF4
ADDRLP4 3296
INDIRP4
CNSTI4 60
ADDP4
INDIRF4
ADDRLP4 3304
INDIRF4
LEF4 $1935
ADDRLP4 3296
INDIRP4
CNSTI4 64
ADDP4
INDIRF4
ADDRLP4 3304
INDIRF4
CNSTF4 1073741824
SUBF4
GEF4 $1935
line 4311
;4308:				 bs->activatestack->goal.entitynum == activategoal->goal.entitynum &&
;4309:				 bs->activatestack->time > FloatTime() &&
;4310:				 bs->activatestack->start_time < FloatTime() - 2)
;4311:				continue;
ADDRGP4 $1896
JUMPV
LABELV $1935
line 4313
;4312:			// if the bot is in a reachability area
;4313:			if ( trap_AAS_AreaReachability(bs->areanum) ) {
ADDRFP4 0
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 3308
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 3308
INDIRI4
CNSTI4 0
EQI4 $1937
line 4315
;4314:				// disable all areas the blocking entity is in
;4315:				BotEnableActivateGoalAreas( activategoal, qfalse );
ADDRFP4 8
INDIRP4
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 BotEnableActivateGoalAreas
CALLV
pop
line 4317
;4316:				//
;4317:				t = trap_AAS_AreaTravelTimeToGoalArea(bs->areanum, bs->origin, activategoal->goal.areanum, bs->tfl);
ADDRLP4 3312
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 3312
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 3312
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRFP4 8
INDIRP4
CNSTI4 16
ADDP4
INDIRI4
ARGI4
ADDRLP4 3312
INDIRP4
CNSTI4 5976
ADDP4
INDIRI4
ARGI4
ADDRLP4 3316
ADDRGP4 trap_AAS_AreaTravelTimeToGoalArea
CALLI4
ASGNI4
ADDRLP4 2736
ADDRLP4 3316
INDIRI4
ASGNI4
line 4319
;4318:				// if the trigger is not reachable
;4319:				if (!t) {
ADDRLP4 2736
INDIRI4
CNSTI4 0
NEI4 $1939
line 4320
;4320:					continue;
ADDRGP4 $1896
JUMPV
LABELV $1939
line 4322
;4321:				}
;4322:				activategoal->time = FloatTime() + t * 0.01 + 5;
ADDRFP4 8
INDIRP4
CNSTI4 60
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1008981770
ADDRLP4 2736
INDIRI4
CVIF4 4
MULF4
ADDF4
CNSTF4 1084227584
ADDF4
ASGNF4
line 4323
;4323:			}
LABELV $1937
line 4324
;4324:			return ent;
ADDRLP4 0
INDIRI4
RETI4
ADDRGP4 $1822
JUMPV
LABELV $1930
line 4326
;4325:		}
;4326:		else if (!strcmp(classname, "func_timer")) {
ADDRLP4 1456
ARGP4
ADDRGP4 $1943
ARGP4
ADDRLP4 3292
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3292
INDIRI4
CNSTI4 0
NEI4 $1941
line 4328
;4327:			// just skip the func_timer
;4328:			continue;
ADDRGP4 $1896
JUMPV
LABELV $1941
line 4331
;4329:		}
;4330:		// the actual button or trigger might be linked through a target_relay or target_delay
;4331:		else if (!strcmp(classname, "target_relay") || !strcmp(classname, "target_delay")) {
ADDRLP4 1456
ARGP4
ADDRGP4 $1946
ARGP4
ADDRLP4 3296
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3296
INDIRI4
CNSTI4 0
EQI4 $1948
ADDRLP4 1456
ARGP4
ADDRGP4 $1947
ARGP4
ADDRLP4 3300
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 3300
INDIRI4
CNSTI4 0
NEI4 $1944
LABELV $1948
line 4332
;4332:			if (trap_AAS_ValueForBSPEpairKey(ent, "targetname", targetname[i+1], sizeof(targetname[0]))) {
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1890
ARGP4
ADDRLP4 132
INDIRI4
CNSTI4 7
LSHI4
ADDRLP4 136+128
ADDP4
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 3304
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 3304
INDIRI4
CNSTI4 0
EQI4 $1949
line 4333
;4333:				i++;
ADDRLP4 132
ADDRLP4 132
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
line 4334
;4334:				cur_entities[i] = trap_AAS_NextBSPEntity(0);
CNSTI4 0
ARGI4
ADDRLP4 3308
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRLP4 1416
ADDP4
ADDRLP4 3308
INDIRI4
ASGNI4
line 4335
;4335:			}
LABELV $1949
line 4336
;4336:		}
LABELV $1944
line 4337
;4337:	}
LABELV $1896
line 4255
LABELV $1898
ADDRLP4 132
INDIRI4
CNSTI4 0
LTI4 $1952
ADDRLP4 132
INDIRI4
CNSTI4 10
LTI4 $1895
LABELV $1952
line 4341
;4338:#ifdef OBSTACLEDEBUG
;4339:	BotAI_Print(PRT_ERROR, "BotGetActivateGoal: no valid activator for entity with target \"%s\"\n", targetname[0]);
;4340:#endif
;4341:	return 0;
CNSTI4 0
RETI4
LABELV $1822
endproc BotGetActivateGoal 3320 20
export BotGoForActivateGoal
proc BotGoForActivateGoal 144 8
line 4349
;4342:}
;4343:
;4344:/*
;4345:==================
;4346:BotGoForActivateGoal
;4347:==================
;4348:*/
;4349:int BotGoForActivateGoal(bot_state_t *bs, bot_activategoal_t *activategoal) {
line 4352
;4350:	aas_entityinfo_t activateinfo;
;4351:
;4352:	activategoal->inuse = qtrue;
ADDRFP4 4
INDIRP4
CNSTI4 1
ASGNI4
line 4353
;4353:	if (!activategoal->time)
ADDRFP4 4
INDIRP4
CNSTI4 60
ADDP4
INDIRF4
CNSTF4 0
NEF4 $1954
line 4354
;4354:		activategoal->time = FloatTime() + 10;
ADDRFP4 4
INDIRP4
CNSTI4 60
ADDP4
ADDRGP4 floattime
INDIRF4
CNSTF4 1092616192
ADDF4
ASGNF4
LABELV $1954
line 4355
;4355:	activategoal->start_time = FloatTime();
ADDRFP4 4
INDIRP4
CNSTI4 64
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 4356
;4356:	BotEntityInfo(activategoal->goal.entitynum, &activateinfo);
ADDRFP4 4
INDIRP4
CNSTI4 44
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 4357
;4357:	VectorCopy(activateinfo.origin, activategoal->origin);
ADDRFP4 4
INDIRP4
CNSTI4 92
ADDP4
ADDRLP4 0+24
INDIRB
ASGNB 12
line 4359
;4358:	//
;4359:	if (BotPushOntoActivateGoalStack(bs, activategoal)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 140
ADDRGP4 BotPushOntoActivateGoalStack
CALLI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 0
EQI4 $1957
line 4361
;4360:		// enter the activate entity AI node
;4361:		AIEnter_Seek_ActivateEntity(bs, "BotGoForActivateGoal");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $1959
ARGP4
ADDRGP4 AIEnter_Seek_ActivateEntity
CALLV
pop
line 4362
;4362:		return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $1953
JUMPV
LABELV $1957
line 4364
;4363:	}
;4364:	else {
line 4366
;4365:		// enable any routing areas that were disabled
;4366:		BotEnableActivateGoalAreas(activategoal, qtrue);
ADDRFP4 4
INDIRP4
ARGP4
CNSTI4 1
ARGI4
ADDRGP4 BotEnableActivateGoalAreas
CALLV
pop
line 4367
;4367:		return qfalse;
CNSTI4 0
RETI4
LABELV $1953
endproc BotGoForActivateGoal 144 8
export BotPrintActivateGoalInfo
proc BotPrintActivateGoalInfo 296 36
line 4376
;4368:	}
;4369:}
;4370:
;4371:/*
;4372:==================
;4373:BotPrintActivateGoalInfo
;4374:==================
;4375:*/
;4376:void BotPrintActivateGoalInfo(bot_state_t *bs, bot_activategoal_t *activategoal, int bspent) {
line 4381
;4377:	char netname[MAX_NETNAME];
;4378:	char classname[128];
;4379:	char buf[128];
;4380:
;4381:	ClientName(bs->client, netname, sizeof(netname));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
CNSTI4 36
ARGI4
ADDRGP4 ClientName
CALLP4
pop
line 4382
;4382:	trap_AAS_ValueForBSPEpairKey(bspent, "classname", classname, sizeof(classname));
ADDRFP4 8
INDIRI4
ARGI4
ADDRGP4 $1836
ARGP4
ADDRLP4 36
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
pop
line 4383
;4383:	if (activategoal->shoot) {
ADDRFP4 4
INDIRP4
CNSTI4 72
ADDP4
INDIRI4
CNSTI4 0
EQI4 $1961
line 4384
;4384:		Com_sprintf(buf, sizeof(buf), "%s: I have to shoot at a %s from %1.1f %1.1f %1.1f in area %d\n",
ADDRLP4 164
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 $1963
ARGP4
ADDRLP4 0
ARGP4
ADDRLP4 36
ARGP4
ADDRLP4 292
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 292
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 292
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
ARGF4
ADDRLP4 292
INDIRP4
CNSTI4 12
ADDP4
INDIRF4
ARGF4
ADDRLP4 292
INDIRP4
CNSTI4 16
ADDP4
INDIRI4
ARGI4
ADDRGP4 Com_sprintf
CALLV
pop
line 4390
;4385:						netname, classname,
;4386:						activategoal->goal.origin[0],
;4387:						activategoal->goal.origin[1],
;4388:						activategoal->goal.origin[2],
;4389:						activategoal->goal.areanum);
;4390:	}
ADDRGP4 $1962
JUMPV
LABELV $1961
line 4391
;4391:	else {
line 4392
;4392:		Com_sprintf(buf, sizeof(buf), "%s: I have to activate a %s at %1.1f %1.1f %1.1f in area %d\n",
ADDRLP4 164
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 $1964
ARGP4
ADDRLP4 0
ARGP4
ADDRLP4 36
ARGP4
ADDRLP4 292
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 292
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
ARGF4
ADDRLP4 292
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
ARGF4
ADDRLP4 292
INDIRP4
CNSTI4 12
ADDP4
INDIRF4
ARGF4
ADDRLP4 292
INDIRP4
CNSTI4 16
ADDP4
INDIRI4
ARGI4
ADDRGP4 Com_sprintf
CALLV
pop
line 4398
;4393:						netname, classname,
;4394:						activategoal->goal.origin[0],
;4395:						activategoal->goal.origin[1],
;4396:						activategoal->goal.origin[2],
;4397:						activategoal->goal.areanum);
;4398:	}
LABELV $1962
line 4399
;4399:	trap_EA_Say(bs->client, buf);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 164
ARGP4
ADDRGP4 trap_EA_Say
CALLV
pop
line 4400
;4400:}
LABELV $1960
endproc BotPrintActivateGoalInfo 296 36
export BotRandomMove
proc BotRandomMove 32 16
line 4407
;4401:
;4402:/*
;4403:==================
;4404:BotRandomMove
;4405:==================
;4406:*/
;4407:void BotRandomMove(bot_state_t *bs, bot_moveresult_t *moveresult) {
line 4410
;4408:	vec3_t dir, angles;
;4409:
;4410:	angles[0] = 0;
ADDRLP4 0
CNSTF4 0
ASGNF4
line 4411
;4411:	angles[1] = random() * 360;
ADDRLP4 24
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 0+4
CNSTF4 1135869952
ADDRLP4 24
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
ASGNF4
line 4412
;4412:	angles[2] = 0;
ADDRLP4 0+8
CNSTF4 0
ASGNF4
line 4413
;4413:	AngleVectors(angles, dir, NULL, NULL);
ADDRLP4 0
ARGP4
ADDRLP4 12
ARGP4
ADDRLP4 28
CNSTP4 0
ASGNP4
ADDRLP4 28
INDIRP4
ARGP4
ADDRLP4 28
INDIRP4
ARGP4
ADDRGP4 AngleVectors
CALLV
pop
line 4415
;4414:
;4415:	trap_BotMoveInDirection(bs->ms, dir, 400, MOVE_WALK);
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 12
ARGP4
CNSTF4 1137180672
ARGF4
CNSTI4 1
ARGI4
ADDRGP4 trap_BotMoveInDirection
CALLI4
pop
line 4417
;4416:
;4417:	moveresult->failure = qfalse;
ADDRFP4 4
INDIRP4
CNSTI4 0
ASGNI4
line 4418
;4418:	VectorCopy(dir, moveresult->movedir);
ADDRFP4 4
INDIRP4
CNSTI4 28
ADDP4
ADDRLP4 12
INDIRB
ASGNB 12
line 4419
;4419:}
LABELV $1965
endproc BotRandomMove 32 16
lit
align 4
LABELV $1969
byte 4 0
byte 4 0
byte 4 1065353216
export BotAIBlocked
code
proc BotAIBlocked 528 16
line 4432
;4420:
;4421:/*
;4422:==================
;4423:BotAIBlocked
;4424:
;4425:Very basic handling of bots being blocked by other entities.
;4426:Check what kind of entity is blocking the bot and try to activate
;4427:it. If that's not an option then try to walk around or over the entity.
;4428:Before the bot ends in this part of the AI it should predict which doors to
;4429:open, which buttons to activate etc.
;4430:==================
;4431:*/
;4432:void BotAIBlocked(bot_state_t *bs, bot_moveresult_t *moveresult, int activate) {
line 4434
;4433:	int movetype, bspent;
;4434:	vec3_t hordir, start, end, mins, maxs, sideward, angles, up = {0, 0, 1};
ADDRLP4 228
ADDRGP4 $1969
INDIRB
ASGNB 12
line 4439
;4435:	aas_entityinfo_t entinfo;
;4436:	bot_activategoal_t activategoal;
;4437:
;4438:	// if the bot is not blocked by anything
;4439:	if (!moveresult->blocked) {
ADDRFP4 4
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
CNSTI4 0
NEI4 $1970
line 4440
;4440:		bs->notblocked_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6204
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 4441
;4441:		return;
ADDRGP4 $1968
JUMPV
LABELV $1970
line 4444
;4442:	}
;4443:	// if stuck in a solid area
;4444:	if ( moveresult->type == RESULTTYPE_INSOLIDAREA ) {
ADDRFP4 4
INDIRP4
CNSTI4 4
ADDP4
INDIRI4
CNSTI4 8
NEI4 $1972
line 4446
;4445:		// move in a random direction in the hope to get out
;4446:		BotRandomMove(bs, moveresult);
ADDRFP4 0
INDIRP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRGP4 BotRandomMove
CALLV
pop
line 4448
;4447:		//
;4448:		return;
ADDRGP4 $1968
JUMPV
LABELV $1972
line 4451
;4449:	}
;4450:	// get info for the entity that is blocking the bot
;4451:	BotEntityInfo(moveresult->blockentity, &entinfo);
ADDRFP4 4
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 40
ARGP4
ADDRGP4 BotEntityInfo
CALLV
pop
line 4457
;4452:#ifdef OBSTACLEDEBUG
;4453:	ClientName(bs->client, netname, sizeof(netname));
;4454:	BotAI_Print(PRT_MESSAGE, "%s: I'm blocked by model %d\n", netname, entinfo.modelindex);
;4455:#endif // OBSTACLEDEBUG
;4456:	// if blocked by a bsp model and the bot wants to activate it
;4457:	if (activate && entinfo.modelindex > 0 && entinfo.modelindex <= max_bspmodelindex) {
ADDRLP4 488
CNSTI4 0
ASGNI4
ADDRFP4 8
INDIRI4
ADDRLP4 488
INDIRI4
EQI4 $1974
ADDRLP4 40+104
INDIRI4
ADDRLP4 488
INDIRI4
LEI4 $1974
ADDRLP4 40+104
INDIRI4
ADDRGP4 max_bspmodelindex
INDIRI4
GTI4 $1974
line 4459
;4458:		// find the bsp entity which should be activated in order to get the blocking entity out of the way
;4459:		bspent = BotGetActivateGoal(bs, entinfo.number, &activategoal);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 40+20
INDIRI4
ARGI4
ADDRLP4 240
ARGP4
ADDRLP4 492
ADDRGP4 BotGetActivateGoal
CALLI4
ASGNI4
ADDRLP4 484
ADDRLP4 492
INDIRI4
ASGNI4
line 4460
;4460:		if (bspent) {
ADDRLP4 484
INDIRI4
CNSTI4 0
EQI4 $1979
line 4462
;4461:			//
;4462:			if (bs->activatestack && !bs->activatestack->inuse)
ADDRLP4 496
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ASGNP4
ADDRLP4 496
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $1981
ADDRLP4 496
INDIRP4
INDIRI4
CNSTI4 0
NEI4 $1981
line 4463
;4463:				bs->activatestack = NULL;
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
CNSTP4 0
ASGNP4
LABELV $1981
line 4465
;4464:			// if not already trying to activate this entity
;4465:			if (!BotIsGoingToActivateEntity(bs, activategoal.goal.entitynum)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 240+4+40
INDIRI4
ARGI4
ADDRLP4 500
ADDRGP4 BotIsGoingToActivateEntity
CALLI4
ASGNI4
ADDRLP4 500
INDIRI4
CNSTI4 0
NEI4 $1983
line 4467
;4466:				//
;4467:				BotGoForActivateGoal(bs, &activategoal);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 240
ARGP4
ADDRGP4 BotGoForActivateGoal
CALLI4
pop
line 4468
;4468:			}
LABELV $1983
line 4472
;4469:			// if ontop of an obstacle or
;4470:			// if the bot is not in a reachability area it'll still
;4471:			// need some dynamic obstacle avoidance, otherwise return
;4472:			if (!(moveresult->flags & MOVERESULT_ONTOPOFOBSTACLE) &&
ADDRFP4 4
INDIRP4
CNSTI4 20
ADDP4
INDIRI4
CNSTI4 32
BANDI4
CNSTI4 0
NEI4 $1980
ADDRFP4 0
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 504
ADDRGP4 trap_AAS_AreaReachability
CALLI4
ASGNI4
ADDRLP4 504
INDIRI4
CNSTI4 0
EQI4 $1980
line 4474
;4473:				trap_AAS_AreaReachability(bs->areanum))
;4474:				return;
ADDRGP4 $1968
JUMPV
line 4475
;4475:		}
LABELV $1979
line 4476
;4476:		else {
line 4478
;4477:			// enable any routing areas that were disabled
;4478:			BotEnableActivateGoalAreas(&activategoal, qtrue);
ADDRLP4 240
ARGP4
CNSTI4 1
ARGI4
ADDRGP4 BotEnableActivateGoalAreas
CALLV
pop
line 4479
;4479:		}
LABELV $1980
line 4480
;4480:	}
LABELV $1974
line 4482
;4481:	// just some basic dynamic obstacle avoidance code
;4482:	hordir[0] = moveresult->movedir[0];
ADDRLP4 0
ADDRFP4 4
INDIRP4
CNSTI4 28
ADDP4
INDIRF4
ASGNF4
line 4483
;4483:	hordir[1] = moveresult->movedir[1];
ADDRLP4 0+4
ADDRFP4 4
INDIRP4
CNSTI4 32
ADDP4
INDIRF4
ASGNF4
line 4484
;4484:	hordir[2] = 0;
ADDRLP4 0+8
CNSTF4 0
ASGNF4
line 4486
;4485:	// if no direction just take a random direction
;4486:	if (VectorNormalize(hordir) < 0.1) {
ADDRLP4 0
ARGP4
ADDRLP4 492
ADDRGP4 VectorNormalize
CALLF4
ASGNF4
ADDRLP4 492
INDIRF4
CNSTF4 1036831949
GEF4 $1991
line 4487
;4487:		VectorSet(angles, 0, 360 * random(), 0);
ADDRLP4 216
CNSTF4 0
ASGNF4
ADDRLP4 496
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 216+4
CNSTF4 1135869952
ADDRLP4 496
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
MULF4
ASGNF4
ADDRLP4 216+8
CNSTF4 0
ASGNF4
line 4488
;4488:		AngleVectors(angles, hordir, NULL, NULL);
ADDRLP4 216
ARGP4
ADDRLP4 0
ARGP4
ADDRLP4 500
CNSTP4 0
ASGNP4
ADDRLP4 500
INDIRP4
ARGP4
ADDRLP4 500
INDIRP4
ARGP4
ADDRGP4 AngleVectors
CALLV
pop
line 4489
;4489:	}
LABELV $1991
line 4493
;4490:	//
;4491:	//if (moveresult->flags & MOVERESULT_ONTOPOFOBSTACLE) movetype = MOVE_JUMP;
;4492:	//else
;4493:	movetype = MOVE_WALK;
ADDRLP4 36
CNSTI4 1
ASGNI4
line 4496
;4494:	// if there's an obstacle at the bot's feet and head then
;4495:	// the bot might be able to crouch through
;4496:	VectorCopy(bs->origin, start);
ADDRLP4 24
ADDRFP4 0
INDIRP4
CNSTI4 4908
ADDP4
INDIRB
ASGNB 12
line 4497
;4497:	start[2] += 18;
ADDRLP4 24+8
ADDRLP4 24+8
INDIRF4
CNSTF4 1099956224
ADDF4
ASGNF4
line 4498
;4498:	VectorMA(start, 5, hordir, end);
ADDRLP4 496
CNSTF4 1084227584
ASGNF4
ADDRLP4 180
ADDRLP4 24
INDIRF4
ADDRLP4 496
INDIRF4
ADDRLP4 0
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 180+4
ADDRLP4 24+4
INDIRF4
ADDRLP4 496
INDIRF4
ADDRLP4 0+4
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 180+8
ADDRLP4 24+8
INDIRF4
CNSTF4 1084227584
ADDRLP4 0+8
INDIRF4
MULF4
ADDF4
ASGNF4
line 4499
;4499:	VectorSet(mins, -16, -16, -24);
ADDRLP4 500
CNSTF4 3246391296
ASGNF4
ADDRLP4 192
ADDRLP4 500
INDIRF4
ASGNF4
ADDRLP4 192+4
ADDRLP4 500
INDIRF4
ASGNF4
ADDRLP4 192+8
CNSTF4 3250585600
ASGNF4
line 4500
;4500:	VectorSet(maxs, 16, 16, 4);
ADDRLP4 504
CNSTF4 1098907648
ASGNF4
ADDRLP4 204
ADDRLP4 504
INDIRF4
ASGNF4
ADDRLP4 204+4
ADDRLP4 504
INDIRF4
ASGNF4
ADDRLP4 204+8
CNSTF4 1082130432
ASGNF4
line 4505
;4501:	//
;4502:	//bsptrace = AAS_Trace(start, mins, maxs, end, bs->entitynum, MASK_PLAYERSOLID);
;4503:	//if (bsptrace.fraction >= 1) movetype = MOVE_CROUCH;
;4504:	// get the sideward vector
;4505:	CrossProduct(hordir, up, sideward);
ADDRLP4 0
ARGP4
ADDRLP4 228
ARGP4
ADDRLP4 12
ARGP4
ADDRGP4 CrossProduct
CALLV
pop
line 4507
;4506:	//
;4507:	if (bs->flags & BFL_AVOIDRIGHT) VectorNegate(sideward, sideward);
ADDRFP4 0
INDIRP4
CNSTI4 5980
ADDP4
INDIRI4
CNSTI4 16
BANDI4
CNSTI4 0
EQI4 $2006
ADDRLP4 12
ADDRLP4 12
INDIRF4
NEGF4
ASGNF4
ADDRLP4 12+4
ADDRLP4 12+4
INDIRF4
NEGF4
ASGNF4
ADDRLP4 12+8
ADDRLP4 12+8
INDIRF4
NEGF4
ASGNF4
LABELV $2006
line 4509
;4508:	// try to crouch straight forward?
;4509:	if (movetype != MOVE_CROUCH || !trap_BotMoveInDirection(bs->ms, hordir, 400, movetype)) {
ADDRLP4 36
INDIRI4
CNSTI4 2
NEI4 $2014
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
CNSTF4 1137180672
ARGF4
ADDRLP4 36
INDIRI4
ARGI4
ADDRLP4 512
ADDRGP4 trap_BotMoveInDirection
CALLI4
ASGNI4
ADDRLP4 512
INDIRI4
CNSTI4 0
NEI4 $2012
LABELV $2014
line 4511
;4510:		// perform the movement
;4511:		if (!trap_BotMoveInDirection(bs->ms, sideward, 400, movetype)) {
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 12
ARGP4
CNSTF4 1137180672
ARGF4
ADDRLP4 36
INDIRI4
ARGI4
ADDRLP4 516
ADDRGP4 trap_BotMoveInDirection
CALLI4
ASGNI4
ADDRLP4 516
INDIRI4
CNSTI4 0
NEI4 $2015
line 4513
;4512:			// flip the avoid direction flag
;4513:			bs->flags ^= BFL_AVOIDRIGHT;
ADDRLP4 520
ADDRFP4 0
INDIRP4
CNSTI4 5980
ADDP4
ASGNP4
ADDRLP4 520
INDIRP4
ADDRLP4 520
INDIRP4
INDIRI4
CNSTI4 16
BXORI4
ASGNI4
line 4516
;4514:			// flip the direction
;4515:			// VectorNegate(sideward, sideward);
;4516:			VectorMA(sideward, -1, hordir, sideward);
ADDRLP4 524
CNSTF4 3212836864
ASGNF4
ADDRLP4 12
ADDRLP4 12
INDIRF4
ADDRLP4 524
INDIRF4
ADDRLP4 0
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 12+4
ADDRLP4 12+4
INDIRF4
ADDRLP4 524
INDIRF4
ADDRLP4 0+4
INDIRF4
MULF4
ADDF4
ASGNF4
ADDRLP4 12+8
ADDRLP4 12+8
INDIRF4
CNSTF4 3212836864
ADDRLP4 0+8
INDIRF4
MULF4
ADDF4
ASGNF4
line 4518
;4517:			// move in the other direction
;4518:			trap_BotMoveInDirection(bs->ms, sideward, 400, movetype);
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRLP4 12
ARGP4
CNSTF4 1137180672
ARGF4
ADDRLP4 36
INDIRI4
ARGI4
ADDRGP4 trap_BotMoveInDirection
CALLI4
pop
line 4519
;4519:		}
LABELV $2015
line 4520
;4520:	}
LABELV $2012
line 4522
;4521:	//
;4522:	if (bs->notblocked_time < FloatTime() - 0.4) {
ADDRFP4 0
INDIRP4
CNSTI4 6204
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1053609165
SUBF4
GEF4 $2023
line 4525
;4523:		// just reset goals and hope the bot will go into another direction?
;4524:		// is this still needed??
;4525:		if (bs->ainode == AINode_Seek_NBG) bs->nbg_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 4900
ADDP4
INDIRP4
CVPU4 4
ADDRGP4 AINode_Seek_NBG
CVPU4 4
NEU4 $2025
ADDRFP4 0
INDIRP4
CNSTI4 6072
ADDP4
CNSTF4 0
ASGNF4
ADDRGP4 $2026
JUMPV
LABELV $2025
line 4526
;4526:		else if (bs->ainode == AINode_Seek_LTG) bs->ltg_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 4900
ADDP4
INDIRP4
CVPU4 4
ADDRGP4 AINode_Seek_LTG
CVPU4 4
NEU4 $2027
ADDRFP4 0
INDIRP4
CNSTI4 6068
ADDP4
CNSTF4 0
ASGNF4
LABELV $2027
LABELV $2026
line 4527
;4527:	}
LABELV $2023
line 4528
;4528:}
LABELV $1968
endproc BotAIBlocked 528 16
export BotAIPredictObstacles
proc BotAIPredictObstacles 324 44
line 4540
;4529:
;4530:/*
;4531:==================
;4532:BotAIPredictObstacles
;4533:
;4534:Predict the route towards the goal and check if the bot
;4535:will be blocked by certain obstacles. When the bot has obstacles
;4536:on it's path the bot should figure out if they can be removed
;4537:by activating certain entities.
;4538:==================
;4539:*/
;4540:int BotAIPredictObstacles(bot_state_t *bs, bot_goal_t *goal) {
line 4545
;4541:	int modelnum, entitynum, bspent;
;4542:	bot_activategoal_t activategoal;
;4543:	aas_predictroute_t route;
;4544:
;4545:	if (!bot_predictobstacles.integer)
ADDRGP4 bot_predictobstacles+12
INDIRI4
CNSTI4 0
NEI4 $2030
line 4546
;4546:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $2029
JUMPV
LABELV $2030
line 4549
;4547:
;4548:	// always predict when the goal change or at regular intervals
;4549:	if (bs->predictobstacles_goalareanum == goal->areanum &&
ADDRLP4 292
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 292
INDIRP4
CNSTI4 6216
ADDP4
INDIRI4
ADDRFP4 4
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
NEI4 $2033
ADDRLP4 292
INDIRP4
CNSTI4 6212
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1086324736
SUBF4
LEF4 $2033
line 4550
;4550:		bs->predictobstacles_time > FloatTime() - 6) {
line 4551
;4551:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $2029
JUMPV
LABELV $2033
line 4553
;4552:	}
;4553:	bs->predictobstacles_goalareanum = goal->areanum;
ADDRFP4 0
INDIRP4
CNSTI4 6216
ADDP4
ADDRFP4 4
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ASGNI4
line 4554
;4554:	bs->predictobstacles_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6212
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 4557
;4555:
;4556:	// predict at most 100 areas or 10 seconds ahead
;4557:	trap_AAS_PredictRoute(&route, bs->areanum, bs->origin,
ADDRLP4 0
ARGP4
ADDRLP4 296
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 296
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 296
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRFP4 4
INDIRP4
CNSTI4 12
ADDP4
INDIRI4
ARGI4
ADDRLP4 296
INDIRP4
CNSTI4 5976
ADDP4
INDIRI4
ARGI4
CNSTI4 100
ARGI4
CNSTI4 1000
ARGI4
CNSTI4 6
ARGI4
CNSTI4 1024
ARGI4
CNSTI4 67108864
ARGI4
CNSTI4 0
ARGI4
ADDRGP4 trap_AAS_PredictRoute
CALLI4
pop
line 4562
;4558:							goal->areanum, bs->tfl, 100, 1000,
;4559:							RSE_USETRAVELTYPE|RSE_ENTERCONTENTS,
;4560:							AREACONTENTS_MOVER, TFL_BRIDGE, 0);
;4561:	// if bot has to travel through an area with a mover
;4562:	if (route.stopevent & RSE_ENTERCONTENTS) {
ADDRLP4 0+16
INDIRI4
CNSTI4 4
BANDI4
CNSTI4 0
EQI4 $2035
line 4564
;4563:		// if the bot will run into a mover
;4564:		if (route.endcontents & AREACONTENTS_MOVER) {
ADDRLP4 0+20
INDIRI4
CNSTI4 1024
BANDI4
CNSTI4 0
EQI4 $2036
line 4566
;4565:			//NOTE: this only works with bspc 2.1 or higher
;4566:			modelnum = (route.endcontents & AREACONTENTS_MODELNUM) >> AREACONTENTS_MODELNUMSHIFT;
ADDRLP4 300
CNSTI4 24
ASGNI4
ADDRLP4 36
ADDRLP4 0+20
INDIRI4
CNSTI4 255
ADDRLP4 300
INDIRI4
LSHI4
BANDI4
ADDRLP4 300
INDIRI4
RSHI4
ASGNI4
line 4567
;4567:			if (modelnum) {
ADDRLP4 36
INDIRI4
CNSTI4 0
EQI4 $2036
line 4569
;4568:				//
;4569:				entitynum = BotModelMinsMaxs(modelnum, ET_MOVER, 0, NULL, NULL);
ADDRLP4 36
INDIRI4
ARGI4
CNSTI4 4
ARGI4
CNSTI4 0
ARGI4
ADDRLP4 304
CNSTP4 0
ASGNP4
ADDRLP4 304
INDIRP4
ARGP4
ADDRLP4 304
INDIRP4
ARGP4
ADDRLP4 308
ADDRGP4 BotModelMinsMaxs
CALLI4
ASGNI4
ADDRLP4 40
ADDRLP4 308
INDIRI4
ASGNI4
line 4570
;4570:				if (entitynum) {
ADDRLP4 40
INDIRI4
CNSTI4 0
EQI4 $2036
line 4572
;4571:					//NOTE: BotGetActivateGoal already checks if the door is open or not
;4572:					bspent = BotGetActivateGoal(bs, entitynum, &activategoal);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 40
INDIRI4
ARGI4
ADDRLP4 48
ARGP4
ADDRLP4 312
ADDRGP4 BotGetActivateGoal
CALLI4
ASGNI4
ADDRLP4 44
ADDRLP4 312
INDIRI4
ASGNI4
line 4573
;4573:					if (bspent) {
ADDRLP4 44
INDIRI4
CNSTI4 0
EQI4 $2036
line 4575
;4574:						//
;4575:						if (bs->activatestack && !bs->activatestack->inuse)
ADDRLP4 316
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
INDIRP4
ASGNP4
ADDRLP4 316
INDIRP4
CVPU4 4
CNSTU4 0
EQU4 $2048
ADDRLP4 316
INDIRP4
INDIRI4
CNSTI4 0
NEI4 $2048
line 4576
;4576:							bs->activatestack = NULL;
ADDRFP4 0
INDIRP4
CNSTI4 7116
ADDP4
CNSTP4 0
ASGNP4
LABELV $2048
line 4578
;4577:						// if not already trying to activate this entity
;4578:						if (!BotIsGoingToActivateEntity(bs, activategoal.goal.entitynum)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 48+4+40
INDIRI4
ARGI4
ADDRLP4 320
ADDRGP4 BotIsGoingToActivateEntity
CALLI4
ASGNI4
ADDRLP4 320
INDIRI4
CNSTI4 0
NEI4 $2050
line 4582
;4579:							//
;4580:							//BotAI_Print(PRT_MESSAGE, "blocked by mover model %d, entity %d ?\n", modelnum, entitynum);
;4581:							//
;4582:							BotGoForActivateGoal(bs, &activategoal);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 48
ARGP4
ADDRGP4 BotGoForActivateGoal
CALLI4
pop
line 4583
;4583:							return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $2029
JUMPV
LABELV $2050
line 4585
;4584:						}
;4585:						else {
line 4587
;4586:							// enable any routing areas that were disabled
;4587:							BotEnableActivateGoalAreas(&activategoal, qtrue);
ADDRLP4 48
ARGP4
CNSTI4 1
ARGI4
ADDRGP4 BotEnableActivateGoalAreas
CALLV
pop
line 4588
;4588:						}
line 4589
;4589:					}
line 4590
;4590:				}
line 4591
;4591:			}
line 4592
;4592:		}
line 4593
;4593:	}
ADDRGP4 $2036
JUMPV
LABELV $2035
line 4594
;4594:	else if (route.stopevent & RSE_USETRAVELTYPE) {
ADDRLP4 0+16
INDIRI4
CNSTI4 2
BANDI4
CNSTI4 0
EQI4 $2054
line 4595
;4595:		if (route.endtravelflags & TFL_BRIDGE) {
ADDRLP4 0+24
INDIRI4
CNSTI4 67108864
BANDI4
CNSTI4 0
EQI4 $2057
line 4597
;4596:			//FIXME: check if the bridge is available to travel over
;4597:		}
LABELV $2057
line 4598
;4598:	}
LABELV $2054
LABELV $2036
line 4599
;4599:	return qfalse;
CNSTI4 0
RETI4
LABELV $2029
endproc BotAIPredictObstacles 324 44
export BotCheckConsoleMessages
proc BotCheckConsoleMessages 1012 48
line 4607
;4600:}
;4601:
;4602:/*
;4603:==================
;4604:BotCheckConsoleMessages
;4605:==================
;4606:*/
;4607:void BotCheckConsoleMessages(bot_state_t *bs) {
line 4615
;4608:	char botname[MAX_NETNAME], message[MAX_MESSAGE_SIZE], netname[MAX_NETNAME], *ptr;
;4609:	float chat_reply;
;4610:	int context, handle;
;4611:	bot_consolemessage_t m;
;4612:	bot_match_t match;
;4613:
;4614:	//the name of this bot
;4615:	ClientName(bs->client, botname, sizeof(botname));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 908
ARGP4
CNSTI4 36
ARGI4
ADDRGP4 ClientName
CALLP4
pop
ADDRGP4 $2062
JUMPV
LABELV $2061
line 4617
;4616:	//
;4617:	while((handle = trap_BotNextConsoleMessage(bs->cs, &m)) != 0) {
line 4619
;4618:		//if the chat state is flooded with messages the bot will read them quickly
;4619:		if (trap_BotNumConsoleMessages(bs->cs) < 10) {
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 948
ADDRGP4 trap_BotNumConsoleMessages
CALLI4
ASGNI4
ADDRLP4 948
INDIRI4
CNSTI4 10
GEI4 $2064
line 4621
;4620:			//if it is a chat message the bot needs some time to read it
;4621:			if (m.type == CMS_CHAT && m.time > FloatTime() - (1 + random())) break;
ADDRLP4 0+8
INDIRI4
CNSTI4 1
NEI4 $2066
ADDRLP4 952
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 0+4
INDIRF4
ADDRGP4 floattime
INDIRF4
ADDRLP4 952
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1065353216
ADDF4
SUBF4
LEF4 $2066
ADDRGP4 $2063
JUMPV
LABELV $2066
line 4622
;4622:		}
LABELV $2064
line 4624
;4623:		//
;4624:		ptr = m.message;
ADDRLP4 276
ADDRLP4 0+12
ASGNP4
line 4627
;4625:		//if it is a chat message then don't unify white spaces and don't
;4626:		//replace synonyms in the netname
;4627:		if (m.type == CMS_CHAT) {
ADDRLP4 0+8
INDIRI4
CNSTI4 1
NEI4 $2071
line 4629
;4628:			//
;4629:			if (trap_BotFindMatch(m.message, &match, MTCONTEXT_REPLYCHAT)) {
ADDRLP4 0+12
ARGP4
ADDRLP4 288
ARGP4
CNSTU4 128
ARGU4
ADDRLP4 952
ADDRGP4 trap_BotFindMatch
CALLI4
ASGNI4
ADDRLP4 952
INDIRI4
CNSTI4 0
EQI4 $2074
line 4630
;4630:				ptr = m.message + match.variables[MESSAGE].offset;
ADDRLP4 276
ADDRLP4 288+264+16
INDIRI1
CVII4 1
ADDRLP4 0+12
ADDP4
ASGNP4
line 4631
;4631:			}
LABELV $2074
line 4632
;4632:		}
LABELV $2071
line 4634
;4633:		//unify the white spaces in the message
;4634:		trap_UnifyWhiteSpaces(ptr);
ADDRLP4 276
INDIRP4
ARGP4
ADDRGP4 trap_UnifyWhiteSpaces
CALLV
pop
line 4636
;4635:		//replace synonyms in the right context
;4636:		context = BotSynonymContext(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 952
ADDRGP4 BotSynonymContext
CALLI4
ASGNI4
ADDRLP4 284
ADDRLP4 952
INDIRI4
ASGNI4
line 4637
;4637:		trap_BotReplaceSynonyms(ptr, context);
ADDRLP4 276
INDIRP4
ARGP4
ADDRLP4 284
INDIRI4
CVIU4 4
ARGU4
ADDRGP4 trap_BotReplaceSynonyms
CALLV
pop
line 4639
;4638:		//if there's no match
;4639:		if (!BotMatchMessage(bs, m.message)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0+12
ARGP4
ADDRLP4 956
ADDRGP4 BotMatchMessage
CALLI4
ASGNI4
ADDRLP4 956
INDIRI4
CNSTI4 0
NEI4 $2080
line 4641
;4640:			//if it is a chat message
;4641:			if (m.type == CMS_CHAT && !bot_nochat.integer) {
ADDRLP4 0+8
INDIRI4
CNSTI4 1
NEI4 $2083
ADDRGP4 bot_nochat+12
INDIRI4
CNSTI4 0
NEI4 $2083
line 4643
;4642:				//
;4643:				if (!trap_BotFindMatch(m.message, &match, MTCONTEXT_REPLYCHAT)) {
ADDRLP4 0+12
ARGP4
ADDRLP4 288
ARGP4
CNSTU4 128
ARGU4
ADDRLP4 960
ADDRGP4 trap_BotFindMatch
CALLI4
ASGNI4
ADDRLP4 960
INDIRI4
CNSTI4 0
NEI4 $2087
line 4644
;4644:					trap_BotRemoveConsoleMessage(bs->cs, handle);
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 280
INDIRI4
ARGI4
ADDRGP4 trap_BotRemoveConsoleMessage
CALLV
pop
line 4645
;4645:					continue;
ADDRGP4 $2062
JUMPV
LABELV $2087
line 4648
;4646:				}
;4647:				//don't use eliza chats with team messages
;4648:				if (match.subtype & ST_TEAM) {
ADDRLP4 288+260
INDIRI4
CNSTI4 32768
BANDI4
CNSTI4 0
EQI4 $2090
line 4649
;4649:					trap_BotRemoveConsoleMessage(bs->cs, handle);
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 280
INDIRI4
ARGI4
ADDRGP4 trap_BotRemoveConsoleMessage
CALLV
pop
line 4650
;4650:					continue;
ADDRGP4 $2062
JUMPV
LABELV $2090
line 4653
;4651:				}
;4652:				//
;4653:				trap_BotMatchVariable(&match, NETNAME, netname, sizeof(netname));
ADDRLP4 288
ARGP4
CNSTI4 0
ARGI4
ADDRLP4 872
ARGP4
CNSTI4 36
ARGI4
ADDRGP4 trap_BotMatchVariable
CALLV
pop
line 4654
;4654:				trap_BotMatchVariable(&match, MESSAGE, message, sizeof(message));
ADDRLP4 288
ARGP4
CNSTI4 2
ARGI4
ADDRLP4 616
ARGP4
CNSTI4 256
ARGI4
ADDRGP4 trap_BotMatchVariable
CALLV
pop
line 4656
;4655:				//if this is a message from the bot self
;4656:				if (bs->client == ClientFromName(netname)) {
ADDRLP4 872
ARGP4
ADDRLP4 964
ADDRGP4 ClientFromName
CALLI4
ASGNI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ADDRLP4 964
INDIRI4
NEI4 $2093
line 4657
;4657:					trap_BotRemoveConsoleMessage(bs->cs, handle);
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 280
INDIRI4
ARGI4
ADDRGP4 trap_BotRemoveConsoleMessage
CALLV
pop
line 4658
;4658:					continue;
ADDRGP4 $2062
JUMPV
LABELV $2093
line 4661
;4659:				}
;4660:				//unify the message
;4661:				trap_UnifyWhiteSpaces(message);
ADDRLP4 616
ARGP4
ADDRGP4 trap_UnifyWhiteSpaces
CALLV
pop
line 4663
;4662:				//
;4663:				trap_Cvar_Update(&bot_testrchat);
ADDRGP4 bot_testrchat
ARGP4
ADDRGP4 trap_Cvar_Update
CALLV
pop
line 4664
;4664:				if (bot_testrchat.integer) {
ADDRGP4 bot_testrchat+12
INDIRI4
CNSTI4 0
EQI4 $2095
line 4666
;4665:					//
;4666:					trap_BotLibVarSet("bot_testrchat", "1");
ADDRGP4 $2098
ARGP4
ADDRGP4 $2099
ARGP4
ADDRGP4 trap_BotLibVarSet
CALLI4
pop
line 4668
;4667:					//if bot replies with a chat message
;4668:					if (trap_BotReplyChat(bs->cs, message, context, CONTEXT_REPLY,
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 616
ARGP4
ADDRLP4 284
INDIRI4
ARGI4
CNSTI4 16
ARGI4
ADDRLP4 968
CNSTP4 0
ASGNP4
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 908
ARGP4
ADDRLP4 872
ARGP4
ADDRLP4 972
ADDRGP4 trap_BotReplyChat
CALLI4
ASGNI4
ADDRLP4 972
INDIRI4
CNSTI4 0
EQI4 $2100
line 4672
;4669:															NULL, NULL,
;4670:															NULL, NULL,
;4671:															NULL, NULL,
;4672:															botname, netname)) {
line 4673
;4673:						BotAI_Print(PRT_MESSAGE, "------------------------\n");
CNSTI4 1
ARGI4
ADDRGP4 $2102
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4674
;4674:					}
ADDRGP4 $2096
JUMPV
LABELV $2100
line 4675
;4675:					else {
line 4676
;4676:						BotAI_Print(PRT_MESSAGE, "**** no valid reply ****\n");
CNSTI4 1
ARGI4
ADDRGP4 $2103
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
line 4677
;4677:					}
line 4678
;4678:				}
ADDRGP4 $2096
JUMPV
LABELV $2095
line 4680
;4679:				//if at a valid chat position and not chatting already and not in teamplay
;4680:				else if (bs->ainode != AINode_Stand && BotValidChatPosition(bs) && !TeamPlayIsOn()) {
ADDRLP4 968
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 968
INDIRP4
CNSTI4 4900
ADDP4
INDIRP4
CVPU4 4
ADDRGP4 AINode_Stand
CVPU4 4
EQU4 $2104
ADDRLP4 968
INDIRP4
ARGP4
ADDRLP4 972
ADDRGP4 BotValidChatPosition
CALLI4
ASGNI4
ADDRLP4 972
INDIRI4
CNSTI4 0
EQI4 $2104
ADDRLP4 976
ADDRGP4 TeamPlayIsOn
CALLI4
ASGNI4
ADDRLP4 976
INDIRI4
CNSTI4 0
NEI4 $2104
line 4681
;4681:					chat_reply = trap_Characteristic_BFloat(bs->character, CHARACTERISTIC_CHAT_REPLY, 0, 1);
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 35
ARGI4
CNSTF4 0
ARGF4
CNSTF4 1065353216
ARGF4
ADDRLP4 980
ADDRGP4 trap_Characteristic_BFloat
CALLF4
ASGNF4
ADDRLP4 944
ADDRLP4 980
INDIRF4
ASGNF4
line 4682
;4682:					if (random() < 1.5 / (NumBots()+1) && random() < chat_reply) {
ADDRLP4 984
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 988
ADDRGP4 NumBots
CALLI4
ASGNI4
ADDRLP4 984
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
CNSTF4 1069547520
ADDRLP4 988
INDIRI4
CNSTI4 1
ADDI4
CVIF4 4
DIVF4
GEF4 $2106
ADDRLP4 992
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 992
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ADDRLP4 944
INDIRF4
GEF4 $2106
line 4684
;4683:						//if bot replies with a chat message
;4684:						if (trap_BotReplyChat(bs->cs, message, context, CONTEXT_REPLY,
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 616
ARGP4
ADDRLP4 284
INDIRI4
ARGI4
CNSTI4 16
ARGI4
ADDRLP4 996
CNSTP4 0
ASGNP4
ADDRLP4 996
INDIRP4
ARGP4
ADDRLP4 996
INDIRP4
ARGP4
ADDRLP4 996
INDIRP4
ARGP4
ADDRLP4 996
INDIRP4
ARGP4
ADDRLP4 996
INDIRP4
ARGP4
ADDRLP4 996
INDIRP4
ARGP4
ADDRLP4 908
ARGP4
ADDRLP4 872
ARGP4
ADDRLP4 1000
ADDRGP4 trap_BotReplyChat
CALLI4
ASGNI4
ADDRLP4 1000
INDIRI4
CNSTI4 0
EQI4 $2108
line 4688
;4685:																NULL, NULL,
;4686:																NULL, NULL,
;4687:																NULL, NULL,
;4688:																botname, netname)) {
line 4690
;4689:							//remove the console message
;4690:							trap_BotRemoveConsoleMessage(bs->cs, handle);
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 280
INDIRI4
ARGI4
ADDRGP4 trap_BotRemoveConsoleMessage
CALLV
pop
line 4691
;4691:							bs->stand_time = FloatTime() + BotChatTime(bs);
ADDRLP4 1004
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1004
INDIRP4
ARGP4
ADDRLP4 1008
ADDRGP4 BotChatTime
CALLF4
ASGNF4
ADDRLP4 1004
INDIRP4
CNSTI4 6096
ADDP4
ADDRGP4 floattime
INDIRF4
ADDRLP4 1008
INDIRF4
ADDF4
ASGNF4
line 4692
;4692:							AIEnter_Stand(bs, "BotCheckConsoleMessages: reply chat");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $2110
ARGP4
ADDRGP4 AIEnter_Stand
CALLV
pop
line 4694
;4693:							//EA_Say(bs->client, bs->cs.chatmessage);
;4694:							break;
ADDRGP4 $2063
JUMPV
LABELV $2108
line 4696
;4695:						}
;4696:					}
LABELV $2106
line 4697
;4697:				}
LABELV $2104
LABELV $2096
line 4698
;4698:			}
LABELV $2083
line 4699
;4699:		}
LABELV $2080
line 4701
;4700:		//remove the console message
;4701:		trap_BotRemoveConsoleMessage(bs->cs, handle);
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 280
INDIRI4
ARGI4
ADDRGP4 trap_BotRemoveConsoleMessage
CALLV
pop
line 4702
;4702:	}
LABELV $2062
line 4617
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRLP4 948
ADDRGP4 trap_BotNextConsoleMessage
CALLI4
ASGNI4
ADDRLP4 280
ADDRLP4 948
INDIRI4
ASGNI4
ADDRLP4 948
INDIRI4
CNSTI4 0
NEI4 $2061
LABELV $2063
line 4703
;4703:}
LABELV $2060
endproc BotCheckConsoleMessages 1012 48
export BotCheckForGrenades
proc BotCheckForGrenades 8 16
line 4710
;4704:
;4705:/*
;4706:==================
;4707:BotCheckEvents
;4708:==================
;4709:*/
;4710:void BotCheckForGrenades(bot_state_t *bs, entityState_t *state) {
line 4712
;4711:	// if this is not a grenade
;4712:	if (state->eType != ET_MISSILE || state->weapon != WP_GRENADE_LAUNCHER)
ADDRLP4 0
ADDRFP4 4
INDIRP4
ASGNP4
ADDRLP4 4
CNSTI4 4
ASGNI4
ADDRLP4 0
INDIRP4
ADDRLP4 4
INDIRI4
ADDP4
INDIRI4
CNSTI4 3
NEI4 $2114
ADDRLP4 0
INDIRP4
CNSTI4 192
ADDP4
INDIRI4
ADDRLP4 4
INDIRI4
EQI4 $2112
LABELV $2114
line 4713
;4713:		return;
ADDRGP4 $2111
JUMPV
LABELV $2112
line 4715
;4714:	// try to avoid the grenade
;4715:	trap_BotAddAvoidSpot(bs->ms, state->pos.trBase, 160, AVOID_ALWAYS);
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRFP4 4
INDIRP4
CNSTI4 24
ADDP4
ARGP4
CNSTF4 1126170624
ARGF4
CNSTI4 1
ARGI4
ADDRGP4 trap_BotAddAvoidSpot
CALLV
pop
line 4716
;4716:}
LABELV $2111
endproc BotCheckForGrenades 8 16
export BotCheckEvents
proc BotCheckEvents 164 12
line 4768
;4717:
;4718:#ifdef MISSIONPACK
;4719:/*
;4720:==================
;4721:BotCheckForProxMines
;4722:==================
;4723:*/
;4724:void BotCheckForProxMines(bot_state_t *bs, entityState_t *state) {
;4725:	// if this is not a prox mine
;4726:	if (state->eType != ET_MISSILE || state->weapon != WP_PROX_LAUNCHER)
;4727:		return;
;4728:	// if this prox mine is from someone on our own team
;4729:	if (state->generic1 == BotTeam(bs))
;4730:		return;
;4731:	// if the bot doesn't have a weapon to deactivate the mine
;4732:	if (!(bs->inventory[INVENTORY_PLASMAGUN] > 0 && bs->inventory[INVENTORY_CELLS] > 0) &&
;4733:		!(bs->inventory[INVENTORY_ROCKETLAUNCHER] > 0 && bs->inventory[INVENTORY_ROCKETS] > 0) &&
;4734:		!(bs->inventory[INVENTORY_BFG10K] > 0 && bs->inventory[INVENTORY_BFGAMMO] > 0) ) {
;4735:		return;
;4736:	}
;4737:	// try to avoid the prox mine
;4738:	trap_BotAddAvoidSpot(bs->ms, state->pos.trBase, 160, AVOID_ALWAYS);
;4739:	//
;4740:	if (bs->numproxmines >= MAX_PROXMINES)
;4741:		return;
;4742:	bs->proxmines[bs->numproxmines] = state->number;
;4743:	bs->numproxmines++;
;4744:}
;4745:
;4746:/*
;4747:==================
;4748:BotCheckForKamikazeBody
;4749:==================
;4750:*/
;4751:void BotCheckForKamikazeBody(bot_state_t *bs, entityState_t *state) {
;4752:	// if this entity is not wearing the kamikaze
;4753:	if (!(state->eFlags & EF_KAMIKAZE))
;4754:		return;
;4755:	// if this entity isn't dead
;4756:	if (!(state->eFlags & EF_DEAD))
;4757:		return;
;4758:	//remember this kamikaze body
;4759:	bs->kamikazebody = state->number;
;4760:}
;4761:#endif
;4762:
;4763:/*
;4764:==================
;4765:BotCheckEvents
;4766:==================
;4767:*/
;4768:void BotCheckEvents(bot_state_t *bs, entityState_t *state) {
line 4777
;4769:	int event;
;4770:	char buf[128];
;4771:#ifdef MISSIONPACK
;4772:	aas_entityinfo_t entinfo;
;4773:#endif
;4774:
;4775:	//NOTE: this sucks, we're accessing the gentity_t directly
;4776:	//but there's no other fast way to do it right now
;4777:	if (bs->entityeventTime[state->number] == g_entities[state->number].eventTime) {
ADDRLP4 132
ADDRFP4 4
INDIRP4
INDIRI4
ASGNI4
ADDRLP4 132
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 0
INDIRP4
CNSTI4 512
ADDP4
ADDP4
INDIRI4
CNSTI4 808
ADDRLP4 132
INDIRI4
MULI4
ADDRGP4 g_entities+552
ADDP4
INDIRI4
NEI4 $2116
line 4778
;4778:		return;
ADDRGP4 $2115
JUMPV
LABELV $2116
line 4780
;4779:	}
;4780:	bs->entityeventTime[state->number] = g_entities[state->number].eventTime;
ADDRLP4 136
ADDRFP4 4
INDIRP4
INDIRI4
ASGNI4
ADDRLP4 136
INDIRI4
CNSTI4 2
LSHI4
ADDRFP4 0
INDIRP4
CNSTI4 512
ADDP4
ADDP4
CNSTI4 808
ADDRLP4 136
INDIRI4
MULI4
ADDRGP4 g_entities+552
ADDP4
INDIRI4
ASGNI4
line 4782
;4781:	//if it's an event only entity
;4782:	if (state->eType > ET_EVENTS) {
ADDRFP4 4
INDIRP4
CNSTI4 4
ADDP4
INDIRI4
CNSTI4 13
LEI4 $2120
line 4783
;4783:		event = (state->eType - ET_EVENTS) & ~EV_EVENT_BITS;
ADDRLP4 0
ADDRFP4 4
INDIRP4
CNSTI4 4
ADDP4
INDIRI4
CNSTI4 13
SUBI4
CNSTI4 -769
BANDI4
ASGNI4
line 4784
;4784:	}
ADDRGP4 $2121
JUMPV
LABELV $2120
line 4785
;4785:	else {
line 4786
;4786:		event = state->event & ~EV_EVENT_BITS;
ADDRLP4 0
ADDRFP4 4
INDIRP4
CNSTI4 180
ADDP4
INDIRI4
CNSTI4 -769
BANDI4
ASGNI4
line 4787
;4787:	}
LABELV $2121
line 4789
;4788:	//
;4789:	switch(event) {
ADDRLP4 140
ADDRLP4 0
INDIRI4
ASGNI4
ADDRLP4 140
INDIRI4
CNSTI4 1
LTI4 $2122
ADDRLP4 140
INDIRI4
CNSTI4 76
GTI4 $2122
ADDRLP4 140
INDIRI4
CNSTI4 2
LSHI4
ADDRGP4 $2171-4
ADDP4
INDIRP4
JUMPV
lit
align 4
LABELV $2171
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2123
address $2122
address $2122
address $2122
address $2156
address $2122
address $2122
address $2157
address $2135
address $2143
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2124
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2122
address $2123
code
LABELV $2124
line 4792
;4790:		//client obituary event
;4791:		case EV_OBITUARY:
;4792:		{
line 4795
;4793:			int target, attacker, mod;
;4794:
;4795:			target = state->otherEntityNum;
ADDRLP4 144
ADDRFP4 4
INDIRP4
CNSTI4 140
ADDP4
INDIRI4
ASGNI4
line 4796
;4796:			attacker = state->otherEntityNum2;
ADDRLP4 148
ADDRFP4 4
INDIRP4
CNSTI4 144
ADDP4
INDIRI4
ASGNI4
line 4797
;4797:			mod = state->eventParm;
ADDRLP4 152
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
ASGNI4
line 4799
;4798:			//
;4799:			if (target == bs->client) {
ADDRLP4 144
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $2125
line 4800
;4800:				bs->botdeathtype = mod;
ADDRFP4 0
INDIRP4
CNSTI4 6000
ADDP4
ADDRLP4 152
INDIRI4
ASGNI4
line 4801
;4801:				bs->lastkilledby = attacker;
ADDRFP4 0
INDIRP4
CNSTI4 5996
ADDP4
ADDRLP4 148
INDIRI4
ASGNI4
line 4803
;4802:				//
;4803:				if (target == attacker ||
ADDRLP4 156
ADDRLP4 144
INDIRI4
ASGNI4
ADDRLP4 156
INDIRI4
ADDRLP4 148
INDIRI4
EQI4 $2130
ADDRLP4 156
INDIRI4
CNSTI4 1023
EQI4 $2130
ADDRLP4 156
INDIRI4
CNSTI4 1022
NEI4 $2127
LABELV $2130
line 4805
;4804:					target == ENTITYNUM_NONE ||
;4805:					target == ENTITYNUM_WORLD) bs->botsuicide = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6008
ADDP4
CNSTI4 1
ASGNI4
ADDRGP4 $2128
JUMPV
LABELV $2127
line 4806
;4806:				else bs->botsuicide = qfalse;
ADDRFP4 0
INDIRP4
CNSTI4 6008
ADDP4
CNSTI4 0
ASGNI4
LABELV $2128
line 4808
;4807:				//
;4808:				bs->num_deaths++;
ADDRLP4 160
ADDRFP4 0
INDIRP4
CNSTI4 6028
ADDP4
ASGNP4
ADDRLP4 160
INDIRP4
ADDRLP4 160
INDIRP4
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
line 4809
;4809:			}
ADDRGP4 $2123
JUMPV
LABELV $2125
line 4811
;4810:			//else if this client was killed by the bot
;4811:			else if (attacker == bs->client) {
ADDRLP4 148
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $2131
line 4812
;4812:				bs->enemydeathtype = mod;
ADDRFP4 0
INDIRP4
CNSTI4 6004
ADDP4
ADDRLP4 152
INDIRI4
ASGNI4
line 4813
;4813:				bs->lastkilledplayer = target;
ADDRFP4 0
INDIRP4
CNSTI4 5992
ADDP4
ADDRLP4 144
INDIRI4
ASGNI4
line 4814
;4814:				bs->killedenemy_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6168
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 4816
;4815:				//
;4816:				bs->num_kills++;
ADDRLP4 156
ADDRFP4 0
INDIRP4
CNSTI4 6032
ADDP4
ASGNP4
ADDRLP4 156
INDIRP4
ADDRLP4 156
INDIRP4
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
line 4817
;4817:			}
ADDRGP4 $2123
JUMPV
LABELV $2131
line 4818
;4818:			else if (attacker == bs->enemy && target == attacker) {
ADDRLP4 156
ADDRLP4 148
INDIRI4
ASGNI4
ADDRLP4 156
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 6540
ADDP4
INDIRI4
NEI4 $2123
ADDRLP4 144
INDIRI4
ADDRLP4 156
INDIRI4
NEI4 $2123
line 4819
;4819:				bs->enemysuicide = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6012
ADDP4
CNSTI4 1
ASGNI4
line 4820
;4820:			}
line 4834
;4821:			//
;4822:#ifdef MISSIONPACK			
;4823:			if (gametype == GT_1FCTF) {
;4824:				//
;4825:				BotEntityInfo(target, &entinfo);
;4826:				if ( entinfo.powerups & ( 1 << PW_NEUTRALFLAG ) ) {
;4827:					if (!BotSameTeam(bs, target)) {
;4828:						bs->neutralflagstatus = 3;	//enemy dropped the flag
;4829:						bs->flagstatuschanged = qtrue;
;4830:					}
;4831:				}
;4832:			}
;4833:#endif
;4834:			break;
ADDRGP4 $2123
JUMPV
LABELV $2135
line 4837
;4835:		}
;4836:		case EV_GLOBAL_SOUND:
;4837:		{
line 4838
;4838:			if (state->eventParm < 0 || state->eventParm > MAX_SOUNDS) {
ADDRLP4 144
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
ASGNI4
ADDRLP4 144
INDIRI4
CNSTI4 0
LTI4 $2138
ADDRLP4 144
INDIRI4
CNSTI4 256
LEI4 $2136
LABELV $2138
line 4839
;4839:				BotAI_Print(PRT_ERROR, "EV_GLOBAL_SOUND: eventParm (%d) out of range\n", state->eventParm);
CNSTI4 3
ARGI4
ADDRGP4 $2139
ARGP4
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
ARGI4
ADDRGP4 BotAI_Print
CALLV
pop
line 4840
;4840:				break;
ADDRGP4 $2123
JUMPV
LABELV $2136
line 4842
;4841:			}
;4842:			trap_GetConfigstring(CS_SOUNDS + state->eventParm, buf, sizeof(buf));
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
CNSTI4 288
ADDI4
ARGI4
ADDRLP4 4
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 4862
;4843:			/*
;4844:			if (!strcmp(buf, "sound/teamplay/flagret_red.wav")) {
;4845:				//red flag is returned
;4846:				bs->redflagstatus = 0;
;4847:				bs->flagstatuschanged = qtrue;
;4848:			}
;4849:			else if (!strcmp(buf, "sound/teamplay/flagret_blu.wav")) {
;4850:				//blue flag is returned
;4851:				bs->blueflagstatus = 0;
;4852:				bs->flagstatuschanged = qtrue;
;4853:			}
;4854:			else*/
;4855:#ifdef MISSIONPACK
;4856:			if (!strcmp(buf, "sound/items/kamikazerespawn.wav" )) {
;4857:				//the kamikaze respawned so dont avoid it
;4858:				BotDontAvoid(bs, "Kamikaze");
;4859:			}
;4860:			else
;4861:#endif
;4862:				if (!strcmp(buf, "sound/items/poweruprespawn.wav")) {
ADDRLP4 4
ARGP4
ADDRGP4 $2142
ARGP4
ADDRLP4 148
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
NEI4 $2123
line 4864
;4863:				//powerup respawned... go get it
;4864:				BotGoForPowerups(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotGoForPowerups
CALLV
pop
line 4865
;4865:			}
line 4866
;4866:			break;
ADDRGP4 $2123
JUMPV
LABELV $2143
line 4869
;4867:		}
;4868:		case EV_GLOBAL_TEAM_SOUND:
;4869:		{
line 4870
;4870:			if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $2123
line 4871
;4871:				switch(state->eventParm) {
ADDRLP4 144
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
ASGNI4
ADDRLP4 144
INDIRI4
CNSTI4 0
LTI4 $2123
ADDRLP4 144
INDIRI4
CNSTI4 5
GTI4 $2123
ADDRLP4 144
INDIRI4
CNSTI4 2
LSHI4
ADDRGP4 $2155
ADDP4
INDIRP4
JUMPV
lit
align 4
LABELV $2155
address $2149
address $2150
address $2151
address $2152
address $2153
address $2154
code
LABELV $2149
line 4873
;4872:					case GTS_RED_CAPTURE:
;4873:						bs->blueflagstatus = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6956
ADDP4
CNSTI4 0
ASGNI4
line 4874
;4874:						bs->redflagstatus = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6952
ADDP4
CNSTI4 0
ASGNI4
line 4875
;4875:						bs->flagstatuschanged = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6964
ADDP4
CNSTI4 1
ASGNI4
line 4876
;4876:						break; //see BotMatch_CTF
ADDRGP4 $2123
JUMPV
LABELV $2150
line 4878
;4877:					case GTS_BLUE_CAPTURE:
;4878:						bs->blueflagstatus = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6956
ADDP4
CNSTI4 0
ASGNI4
line 4879
;4879:						bs->redflagstatus = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6952
ADDP4
CNSTI4 0
ASGNI4
line 4880
;4880:						bs->flagstatuschanged = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6964
ADDP4
CNSTI4 1
ASGNI4
line 4881
;4881:						break; //see BotMatch_CTF
ADDRGP4 $2123
JUMPV
LABELV $2151
line 4884
;4882:					case GTS_RED_RETURN:
;4883:						//blue flag is returned
;4884:						bs->blueflagstatus = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6956
ADDP4
CNSTI4 0
ASGNI4
line 4885
;4885:						bs->flagstatuschanged = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6964
ADDP4
CNSTI4 1
ASGNI4
line 4886
;4886:						break;
ADDRGP4 $2123
JUMPV
LABELV $2152
line 4889
;4887:					case GTS_BLUE_RETURN:
;4888:						//red flag is returned
;4889:						bs->redflagstatus = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6952
ADDP4
CNSTI4 0
ASGNI4
line 4890
;4890:						bs->flagstatuschanged = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6964
ADDP4
CNSTI4 1
ASGNI4
line 4891
;4891:						break;
ADDRGP4 $2123
JUMPV
LABELV $2153
line 4894
;4892:					case GTS_RED_TAKEN:
;4893:						//blue flag is taken
;4894:						bs->blueflagstatus = 1;
ADDRFP4 0
INDIRP4
CNSTI4 6956
ADDP4
CNSTI4 1
ASGNI4
line 4895
;4895:						bs->flagstatuschanged = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6964
ADDP4
CNSTI4 1
ASGNI4
line 4896
;4896:						break; //see BotMatch_CTF
ADDRGP4 $2123
JUMPV
LABELV $2154
line 4899
;4897:					case GTS_BLUE_TAKEN:
;4898:						//red flag is taken
;4899:						bs->redflagstatus = 1;
ADDRFP4 0
INDIRP4
CNSTI4 6952
ADDP4
CNSTI4 1
ASGNI4
line 4900
;4900:						bs->flagstatuschanged = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6964
ADDP4
CNSTI4 1
ASGNI4
line 4901
;4901:						break; //see BotMatch_CTF
line 4903
;4902:				}
;4903:			}
line 4936
;4904:#ifdef MISSIONPACK
;4905:			else if (gametype == GT_1FCTF) {
;4906:				switch(state->eventParm) {
;4907:					case GTS_RED_CAPTURE:
;4908:						bs->neutralflagstatus = 0;
;4909:						bs->flagstatuschanged = qtrue;
;4910:						break;
;4911:					case GTS_BLUE_CAPTURE:
;4912:						bs->neutralflagstatus = 0;
;4913:						bs->flagstatuschanged = qtrue;
;4914:						break;
;4915:					case GTS_RED_RETURN:
;4916:						//flag has returned
;4917:						bs->neutralflagstatus = 0;
;4918:						bs->flagstatuschanged = qtrue;
;4919:						break;
;4920:					case GTS_BLUE_RETURN:
;4921:						//flag has returned
;4922:						bs->neutralflagstatus = 0;
;4923:						bs->flagstatuschanged = qtrue;
;4924:						break;
;4925:					case GTS_RED_TAKEN:
;4926:						bs->neutralflagstatus = BotTeam(bs) == TEAM_RED ? 2 : 1; //FIXME: check Team_TakeFlagSound in g_team.c
;4927:						bs->flagstatuschanged = qtrue;
;4928:						break;
;4929:					case GTS_BLUE_TAKEN:
;4930:						bs->neutralflagstatus = BotTeam(bs) == TEAM_BLUE ? 2 : 1; //FIXME: check Team_TakeFlagSound in g_team.c
;4931:						bs->flagstatuschanged = qtrue;
;4932:						break;
;4933:				}
;4934:			}
;4935:#endif
;4936:			break;
ADDRGP4 $2123
JUMPV
LABELV $2156
line 4939
;4937:		}
;4938:		case EV_PLAYER_TELEPORT_IN:
;4939:		{
line 4940
;4940:			VectorCopy(state->origin, lastteleport_origin);
ADDRGP4 lastteleport_origin
ADDRFP4 4
INDIRP4
CNSTI4 92
ADDP4
INDIRB
ASGNB 12
line 4941
;4941:			lastteleport_time = FloatTime();
ADDRGP4 lastteleport_time
ADDRGP4 floattime
INDIRF4
ASGNF4
line 4942
;4942:			break;
ADDRGP4 $2123
JUMPV
LABELV $2157
line 4945
;4943:		}
;4944:		case EV_GENERAL_SOUND:
;4945:		{
line 4947
;4946:			//if this sound is played on the bot
;4947:			if (state->number == bs->client) {
ADDRFP4 4
INDIRP4
INDIRI4
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
NEI4 $2123
line 4948
;4948:				if (state->eventParm < 0 || state->eventParm > MAX_SOUNDS) {
ADDRLP4 144
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
ASGNI4
ADDRLP4 144
INDIRI4
CNSTI4 0
LTI4 $2162
ADDRLP4 144
INDIRI4
CNSTI4 256
LEI4 $2160
LABELV $2162
line 4949
;4949:					BotAI_Print(PRT_ERROR, "EV_GENERAL_SOUND: eventParm (%d) out of range\n", state->eventParm);
CNSTI4 3
ARGI4
ADDRGP4 $2163
ARGP4
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
ARGI4
ADDRGP4 BotAI_Print
CALLV
pop
line 4950
;4950:					break;
ADDRGP4 $2123
JUMPV
LABELV $2160
line 4953
;4951:				}
;4952:				//check out the sound
;4953:				trap_GetConfigstring(CS_SOUNDS + state->eventParm, buf, sizeof(buf));
ADDRFP4 4
INDIRP4
CNSTI4 184
ADDP4
INDIRI4
CNSTI4 288
ADDI4
ARGI4
ADDRLP4 4
ARGP4
CNSTI4 128
ARGI4
ADDRGP4 trap_GetConfigstring
CALLV
pop
line 4955
;4954:				//if falling into a death pit
;4955:				if (!strcmp(buf, "*falling1.wav")) {
ADDRLP4 4
ARGP4
ADDRGP4 $2166
ARGP4
ADDRLP4 148
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
NEI4 $2123
line 4957
;4956:					//if the bot has a personal teleporter
;4957:					if (bs->inventory[INVENTORY_TELEPORTER] > 0) {
ADDRFP4 0
INDIRP4
CNSTI4 5072
ADDP4
INDIRI4
CNSTI4 0
LEI4 $2123
line 4959
;4958:						//use the holdable item
;4959:						trap_EA_Use(bs->client);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_EA_Use
CALLV
pop
line 4960
;4960:					}
line 4961
;4961:				}
line 4962
;4962:			}
line 4963
;4963:			break;
line 4990
;4964:		}
;4965:		case EV_FOOTSTEP:
;4966:		case EV_FOOTSTEP_METAL:
;4967:		case EV_FOOTSPLASH:
;4968:		case EV_FOOTWADE:
;4969:		case EV_SWIM:
;4970:		case EV_FALL_SHORT:
;4971:		case EV_FALL_MEDIUM:
;4972:		case EV_FALL_FAR:
;4973:		case EV_STEP_4:
;4974:		case EV_STEP_8:
;4975:		case EV_STEP_12:
;4976:		case EV_STEP_16:
;4977:		case EV_JUMP_PAD:
;4978:		case EV_JUMP:
;4979:		case EV_TAUNT:
;4980:		case EV_WATER_TOUCH:
;4981:		case EV_WATER_LEAVE:
;4982:		case EV_WATER_UNDER:
;4983:		case EV_WATER_CLEAR:
;4984:		case EV_ITEM_PICKUP:
;4985:		case EV_GLOBAL_ITEM_PICKUP:
;4986:		case EV_NOAMMO:
;4987:		case EV_CHANGE_WEAPON:
;4988:		case EV_FIRE_WEAPON:
;4989:			//FIXME: either add to sound queue or mark player as someone making noise
;4990:			break;
line 5006
;4991:		case EV_USE_ITEM0:
;4992:		case EV_USE_ITEM1:
;4993:		case EV_USE_ITEM2:
;4994:		case EV_USE_ITEM3:
;4995:		case EV_USE_ITEM4:
;4996:		case EV_USE_ITEM5:
;4997:		case EV_USE_ITEM6:
;4998:		case EV_USE_ITEM7:
;4999:		case EV_USE_ITEM8:
;5000:		case EV_USE_ITEM9:
;5001:		case EV_USE_ITEM10:
;5002:		case EV_USE_ITEM11:
;5003:		case EV_USE_ITEM12:
;5004:		case EV_USE_ITEM13:
;5005:		case EV_USE_ITEM14:
;5006:			break;
LABELV $2122
LABELV $2123
line 5008
;5007:	}
;5008:}
LABELV $2115
endproc BotCheckEvents 164 12
export BotCheckSnapshot
proc BotCheckSnapshot 216 16
line 5015
;5009:
;5010:/*
;5011:==================
;5012:BotCheckSnapshot
;5013:==================
;5014:*/
;5015:void BotCheckSnapshot(bot_state_t *bs) {
line 5020
;5016:	int ent;
;5017:	entityState_t state;
;5018:
;5019:	//remove all avoid spots
;5020:	trap_BotAddAvoidSpot(bs->ms, vec3_origin, 0, AVOID_CLEAR);
ADDRFP4 0
INDIRP4
CNSTI4 6524
ADDP4
INDIRI4
ARGI4
ADDRGP4 vec3_origin
ARGP4
CNSTF4 0
ARGF4
CNSTI4 0
ARGI4
ADDRGP4 trap_BotAddAvoidSpot
CALLV
pop
line 5022
;5021:	//reset kamikaze body
;5022:	bs->kamikazebody = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6256
ADDP4
CNSTI4 0
ASGNI4
line 5024
;5023:	//reset number of proxmines
;5024:	bs->numproxmines = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6516
ADDP4
CNSTI4 0
ASGNI4
line 5026
;5025:	//
;5026:	ent = 0;
ADDRLP4 208
CNSTI4 0
ASGNI4
ADDRGP4 $2175
JUMPV
LABELV $2174
line 5027
;5027:	while( ( ent = BotAI_GetSnapshotEntity( bs->client, ent, &state ) ) != -1 ) {
line 5029
;5028:		//check the entity state for events
;5029:		BotCheckEvents(bs, &state);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ARGP4
ADDRGP4 BotCheckEvents
CALLV
pop
line 5031
;5030:		//check for grenades the bot should avoid
;5031:		BotCheckForGrenades(bs, &state);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ARGP4
ADDRGP4 BotCheckForGrenades
CALLV
pop
line 5039
;5032:		//
;5033:#ifdef MISSIONPACK
;5034:		//check for proximity mines which the bot should deactivate
;5035:		BotCheckForProxMines(bs, &state);
;5036:		//check for dead bodies with the kamikaze effect which should be gibbed
;5037:		BotCheckForKamikazeBody(bs, &state);
;5038:#endif
;5039:	}
LABELV $2175
line 5027
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 208
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRLP4 212
ADDRGP4 BotAI_GetSnapshotEntity
CALLI4
ASGNI4
ADDRLP4 208
ADDRLP4 212
INDIRI4
ASGNI4
ADDRLP4 212
INDIRI4
CNSTI4 -1
NEI4 $2174
line 5041
;5040:	//check the player state for events
;5041:	BotAI_GetEntityState(bs->client, &state);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 0
ARGP4
ADDRGP4 BotAI_GetEntityState
CALLI4
pop
line 5043
;5042:	//copy the player state events to the entity state
;5043:	state.event = bs->cur_ps.externalEvent;
ADDRLP4 0+180
ADDRFP4 0
INDIRP4
CNSTI4 144
ADDP4
INDIRI4
ASGNI4
line 5044
;5044:	state.eventParm = bs->cur_ps.externalEventParm;
ADDRLP4 0+184
ADDRFP4 0
INDIRP4
CNSTI4 148
ADDP4
INDIRI4
ASGNI4
line 5046
;5045:	//
;5046:	BotCheckEvents(bs, &state);
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 0
ARGP4
ADDRGP4 BotCheckEvents
CALLV
pop
line 5047
;5047:}
LABELV $2173
endproc BotCheckSnapshot 216 16
export BotCheckAir
proc BotCheckAir 4 4
line 5054
;5048:
;5049:/*
;5050:==================
;5051:BotCheckAir
;5052:==================
;5053:*/
;5054:void BotCheckAir(bot_state_t *bs) {
line 5055
;5055:	if (bs->inventory[INVENTORY_ENVIRONMENTSUIT] <= 0) {
ADDRFP4 0
INDIRP4
CNSTI4 5096
ADDP4
INDIRI4
CNSTI4 0
GTI4 $2180
line 5056
;5056:		if (trap_AAS_PointContents(bs->eye) & (CONTENTS_WATER|CONTENTS_SLIME|CONTENTS_LAVA)) {
ADDRFP4 0
INDIRP4
CNSTI4 4936
ADDP4
ARGP4
ADDRLP4 0
ADDRGP4 trap_AAS_PointContents
CALLI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 56
BANDI4
CNSTI4 0
EQI4 $2182
line 5057
;5057:			return;
ADDRGP4 $2179
JUMPV
LABELV $2182
line 5059
;5058:		}
;5059:	}
LABELV $2180
line 5060
;5060:	bs->lastair_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6176
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 5061
;5061:}
LABELV $2179
endproc BotCheckAir 4 4
export BotAlternateRoute
proc BotAlternateRoute 16 16
line 5068
;5062:
;5063:/*
;5064:==================
;5065:BotAlternateRoute
;5066:==================
;5067:*/
;5068:bot_goal_t *BotAlternateRoute(bot_state_t *bs, bot_goal_t *goal) {
line 5072
;5069:	int t;
;5070:
;5071:	// if the bot has an alternative route goal
;5072:	if (bs->altroutegoal.areanum) {
ADDRFP4 0
INDIRP4
CNSTI4 6692
ADDP4
INDIRI4
CNSTI4 0
EQI4 $2185
line 5074
;5073:		//
;5074:		if (bs->reachedaltroutegoal_time)
ADDRFP4 0
INDIRP4
CNSTI4 6736
ADDP4
INDIRF4
CNSTF4 0
EQF4 $2187
line 5075
;5075:			return goal;
ADDRFP4 4
INDIRP4
RETP4
ADDRGP4 $2184
JUMPV
LABELV $2187
line 5077
;5076:		// travel time towards alternative route goal
;5077:		t = trap_AAS_AreaTravelTimeToGoalArea(bs->areanum, bs->origin, bs->altroutegoal.areanum, bs->tfl);
ADDRLP4 4
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
INDIRP4
CNSTI4 4948
ADDP4
INDIRI4
ARGI4
ADDRLP4 4
INDIRP4
CNSTI4 4908
ADDP4
ARGP4
ADDRLP4 4
INDIRP4
CNSTI4 6692
ADDP4
INDIRI4
ARGI4
ADDRLP4 4
INDIRP4
CNSTI4 5976
ADDP4
INDIRI4
ARGI4
ADDRLP4 8
ADDRGP4 trap_AAS_AreaTravelTimeToGoalArea
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 8
INDIRI4
ASGNI4
line 5078
;5078:		if (t && t < 20) {
ADDRLP4 12
ADDRLP4 0
INDIRI4
ASGNI4
ADDRLP4 12
INDIRI4
CNSTI4 0
EQI4 $2189
ADDRLP4 12
INDIRI4
CNSTI4 20
GEI4 $2189
line 5080
;5079:			//BotAI_Print(PRT_MESSAGE, "reached alternate route goal\n");
;5080:			bs->reachedaltroutegoal_time = FloatTime();
ADDRFP4 0
INDIRP4
CNSTI4 6736
ADDP4
ADDRGP4 floattime
INDIRF4
ASGNF4
line 5081
;5081:		}
LABELV $2189
line 5082
;5082:		memcpy(goal, &bs->altroutegoal, sizeof(bot_goal_t));
ADDRFP4 4
INDIRP4
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 6680
ADDP4
ARGP4
CNSTI4 56
ARGI4
ADDRGP4 memcpy
CALLP4
pop
line 5083
;5083:		return &bs->altroutegoal;
ADDRFP4 0
INDIRP4
CNSTI4 6680
ADDP4
RETP4
ADDRGP4 $2184
JUMPV
LABELV $2185
line 5085
;5084:	}
;5085:	return goal;
ADDRFP4 4
INDIRP4
RETP4
LABELV $2184
endproc BotAlternateRoute 16 16
export BotGetAlternateRouteGoal
proc BotGetAlternateRouteGoal 24 0
line 5093
;5086:}
;5087:
;5088:/*
;5089:==================
;5090:BotGetAlternateRouteGoal
;5091:==================
;5092:*/
;5093:int BotGetAlternateRouteGoal(bot_state_t *bs, int base) {
line 5098
;5094:	aas_altroutegoal_t *altroutegoals;
;5095:	bot_goal_t *goal;
;5096:	int numaltroutegoals, rnd;
;5097:
;5098:	if (base == TEAM_RED) {
ADDRFP4 4
INDIRI4
CNSTI4 1
NEI4 $2192
line 5099
;5099:		altroutegoals = red_altroutegoals;
ADDRLP4 12
ADDRGP4 red_altroutegoals
ASGNP4
line 5100
;5100:		numaltroutegoals = red_numaltroutegoals;
ADDRLP4 4
ADDRGP4 red_numaltroutegoals
INDIRI4
ASGNI4
line 5101
;5101:	}
ADDRGP4 $2193
JUMPV
LABELV $2192
line 5102
;5102:	else {
line 5103
;5103:		altroutegoals = blue_altroutegoals;
ADDRLP4 12
ADDRGP4 blue_altroutegoals
ASGNP4
line 5104
;5104:		numaltroutegoals = blue_numaltroutegoals;
ADDRLP4 4
ADDRGP4 blue_numaltroutegoals
INDIRI4
ASGNI4
line 5105
;5105:	}
LABELV $2193
line 5106
;5106:	if (!numaltroutegoals)
ADDRLP4 4
INDIRI4
CNSTI4 0
NEI4 $2194
line 5107
;5107:		return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $2191
JUMPV
LABELV $2194
line 5108
;5108:	rnd = (float) random() * numaltroutegoals;
ADDRLP4 16
ADDRGP4 rand
CALLI4
ASGNI4
ADDRLP4 8
ADDRLP4 16
INDIRI4
CNSTI4 32767
BANDI4
CVIF4 4
CNSTF4 1191181824
DIVF4
ADDRLP4 4
INDIRI4
CVIF4 4
MULF4
CVFI4 4
ASGNI4
line 5109
;5109:	if (rnd >= numaltroutegoals)
ADDRLP4 8
INDIRI4
ADDRLP4 4
INDIRI4
LTI4 $2196
line 5110
;5110:		rnd = numaltroutegoals-1;
ADDRLP4 8
ADDRLP4 4
INDIRI4
CNSTI4 1
SUBI4
ASGNI4
LABELV $2196
line 5111
;5111:	goal = &bs->altroutegoal;
ADDRLP4 0
ADDRFP4 0
INDIRP4
CNSTI4 6680
ADDP4
ASGNP4
line 5112
;5112:	goal->areanum = altroutegoals[rnd].areanum;
ADDRLP4 20
CNSTI4 12
ASGNI4
ADDRLP4 0
INDIRP4
ADDRLP4 20
INDIRI4
ADDP4
CNSTI4 24
ADDRLP4 8
INDIRI4
MULI4
ADDRLP4 12
INDIRP4
ADDP4
ADDRLP4 20
INDIRI4
ADDP4
INDIRI4
ASGNI4
line 5113
;5113:	VectorCopy(altroutegoals[rnd].origin, goal->origin);
ADDRLP4 0
INDIRP4
CNSTI4 24
ADDRLP4 8
INDIRI4
MULI4
ADDRLP4 12
INDIRP4
ADDP4
INDIRB
ASGNB 12
line 5114
;5114:	VectorSet(goal->mins, -8, -8, -8);
ADDRLP4 0
INDIRP4
CNSTI4 16
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRLP4 0
INDIRP4
CNSTI4 20
ADDP4
CNSTF4 3238002688
ASGNF4
ADDRLP4 0
INDIRP4
CNSTI4 24
ADDP4
CNSTF4 3238002688
ASGNF4
line 5115
;5115:	VectorSet(goal->maxs, 8, 8, 8);
ADDRLP4 0
INDIRP4
CNSTI4 28
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRLP4 0
INDIRP4
CNSTI4 32
ADDP4
CNSTF4 1090519040
ASGNF4
ADDRLP4 0
INDIRP4
CNSTI4 36
ADDP4
CNSTF4 1090519040
ASGNF4
line 5116
;5116:	goal->entitynum = 0;
ADDRLP4 0
INDIRP4
CNSTI4 40
ADDP4
CNSTI4 0
ASGNI4
line 5117
;5117:	goal->iteminfo = 0;
ADDRLP4 0
INDIRP4
CNSTI4 52
ADDP4
CNSTI4 0
ASGNI4
line 5118
;5118:	goal->number = 0;
ADDRLP4 0
INDIRP4
CNSTI4 44
ADDP4
CNSTI4 0
ASGNI4
line 5119
;5119:	goal->flags = 0;
ADDRLP4 0
INDIRP4
CNSTI4 48
ADDP4
CNSTI4 0
ASGNI4
line 5121
;5120:	//
;5121:	bs->reachedaltroutegoal_time = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6736
ADDP4
CNSTF4 0
ASGNF4
line 5122
;5122:	return qtrue;
CNSTI4 1
RETI4
LABELV $2191
endproc BotGetAlternateRouteGoal 24 0
export BotSetupAlternativeRouteGoals
proc BotSetupAlternativeRouteGoals 0 0
line 5130
;5123:}
;5124:
;5125:/*
;5126:==================
;5127:BotSetupAlternateRouteGoals
;5128:==================
;5129:*/
;5130:void BotSetupAlternativeRouteGoals(void) {
line 5132
;5131:
;5132:	if (altroutegoals_setup)
ADDRGP4 altroutegoals_setup
INDIRI4
CNSTI4 0
EQI4 $2199
line 5133
;5133:		return;
ADDRGP4 $2198
JUMPV
LABELV $2199
line 5202
;5134:#ifdef MISSIONPACK
;5135:	if (gametype == GT_CTF) {
;5136:		if (trap_BotGetLevelItemGoal(-1, "Neutral Flag", &ctf_neutralflag) < 0)
;5137:			BotAI_Print(PRT_WARNING, "no alt routes without Neutral Flag\n");
;5138:		if (ctf_neutralflag.areanum) {
;5139:			//
;5140:			red_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5141:										ctf_neutralflag.origin, ctf_neutralflag.areanum,
;5142:										ctf_redflag.origin, ctf_redflag.areanum, TFL_DEFAULT,
;5143:										red_altroutegoals, MAX_ALTROUTEGOALS,
;5144:										ALTROUTEGOAL_CLUSTERPORTALS|
;5145:										ALTROUTEGOAL_VIEWPORTALS);
;5146:			blue_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5147:										ctf_neutralflag.origin, ctf_neutralflag.areanum,
;5148:										ctf_blueflag.origin, ctf_blueflag.areanum, TFL_DEFAULT,
;5149:										blue_altroutegoals, MAX_ALTROUTEGOALS,
;5150:										ALTROUTEGOAL_CLUSTERPORTALS|
;5151:										ALTROUTEGOAL_VIEWPORTALS);
;5152:		}
;5153:	}
;5154:	else if (gametype == GT_1FCTF) {
;5155:		//
;5156:		red_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5157:									ctf_neutralflag.origin, ctf_neutralflag.areanum,
;5158:									ctf_redflag.origin, ctf_redflag.areanum, TFL_DEFAULT,
;5159:									red_altroutegoals, MAX_ALTROUTEGOALS,
;5160:									ALTROUTEGOAL_CLUSTERPORTALS|
;5161:									ALTROUTEGOAL_VIEWPORTALS);
;5162:		blue_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5163:									ctf_neutralflag.origin, ctf_neutralflag.areanum,
;5164:									ctf_blueflag.origin, ctf_blueflag.areanum, TFL_DEFAULT,
;5165:									blue_altroutegoals, MAX_ALTROUTEGOALS,
;5166:									ALTROUTEGOAL_CLUSTERPORTALS|
;5167:									ALTROUTEGOAL_VIEWPORTALS);
;5168:	}
;5169:	else if (gametype == GT_OBELISK) {
;5170:		if (trap_BotGetLevelItemGoal(-1, "Neutral Obelisk", &neutralobelisk) < 0)
;5171:			BotAI_Print(PRT_WARNING, "Harvester without neutral obelisk\n");
;5172:		//
;5173:		red_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5174:									neutralobelisk.origin, neutralobelisk.areanum,
;5175:									redobelisk.origin, redobelisk.areanum, TFL_DEFAULT,
;5176:									red_altroutegoals, MAX_ALTROUTEGOALS,
;5177:									ALTROUTEGOAL_CLUSTERPORTALS|
;5178:									ALTROUTEGOAL_VIEWPORTALS);
;5179:		blue_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5180:									neutralobelisk.origin, neutralobelisk.areanum,
;5181:									blueobelisk.origin, blueobelisk.areanum, TFL_DEFAULT,
;5182:									blue_altroutegoals, MAX_ALTROUTEGOALS,
;5183:									ALTROUTEGOAL_CLUSTERPORTALS|
;5184:									ALTROUTEGOAL_VIEWPORTALS);
;5185:	}
;5186:	else if (gametype == GT_HARVESTER) {
;5187:		//
;5188:		red_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5189:									neutralobelisk.origin, neutralobelisk.areanum,
;5190:									redobelisk.origin, redobelisk.areanum, TFL_DEFAULT,
;5191:									red_altroutegoals, MAX_ALTROUTEGOALS,
;5192:									ALTROUTEGOAL_CLUSTERPORTALS|
;5193:									ALTROUTEGOAL_VIEWPORTALS);
;5194:		blue_numaltroutegoals = trap_AAS_AlternativeRouteGoals(
;5195:									neutralobelisk.origin, neutralobelisk.areanum,
;5196:									blueobelisk.origin, blueobelisk.areanum, TFL_DEFAULT,
;5197:									blue_altroutegoals, MAX_ALTROUTEGOALS,
;5198:									ALTROUTEGOAL_CLUSTERPORTALS|
;5199:									ALTROUTEGOAL_VIEWPORTALS);
;5200:	}
;5201:#endif
;5202:	altroutegoals_setup = qtrue;
ADDRGP4 altroutegoals_setup
CNSTI4 1
ASGNI4
line 5203
;5203:}
LABELV $2198
endproc BotSetupAlternativeRouteGoals 0 0
export BotDeathmatchAI
proc BotDeathmatchAI 1492 20
line 5210
;5204:
;5205:/*
;5206:==================
;5207:BotDeathmatchAI
;5208:==================
;5209:*/
;5210:void BotDeathmatchAI(bot_state_t *bs, float thinktime) {
line 5216
;5211:	char gender[144], name[144], buf[144];
;5212:	char userinfo[MAX_INFO_STRING];
;5213:	int i;
;5214:
;5215:	//if the bot has just been setup
;5216:	if (bs->setupcount > 0) {
ADDRFP4 0
INDIRP4
CNSTI4 6016
ADDP4
INDIRI4
CNSTI4 0
LEI4 $2202
line 5217
;5217:		bs->setupcount--;
ADDRLP4 1460
ADDRFP4 0
INDIRP4
CNSTI4 6016
ADDP4
ASGNP4
ADDRLP4 1460
INDIRP4
ADDRLP4 1460
INDIRP4
INDIRI4
CNSTI4 1
SUBI4
ASGNI4
line 5218
;5218:		if (bs->setupcount > 0) return;
ADDRFP4 0
INDIRP4
CNSTI4 6016
ADDP4
INDIRI4
CNSTI4 0
LEI4 $2204
ADDRGP4 $2201
JUMPV
LABELV $2204
line 5220
;5219:		//get the gender characteristic
;5220:		trap_Characteristic_String(bs->character, CHARACTERISTIC_GENDER, gender, sizeof(gender));
ADDRFP4 0
INDIRP4
CNSTI4 6520
ADDP4
INDIRI4
ARGI4
CNSTI4 1
ARGI4
ADDRLP4 148
ARGP4
CNSTI4 144
ARGI4
ADDRGP4 trap_Characteristic_String
CALLV
pop
line 5222
;5221:		//set the bot gender
;5222:		trap_GetUserinfo(bs->client, userinfo, sizeof(userinfo));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 292
ARGP4
CNSTI4 1024
ARGI4
ADDRGP4 trap_GetUserinfo
CALLV
pop
line 5223
;5223:		Info_SetValueForKey(userinfo, "sex", gender);
ADDRLP4 292
ARGP4
ADDRGP4 $2206
ARGP4
ADDRLP4 148
ARGP4
ADDRGP4 Info_SetValueForKey
CALLV
pop
line 5224
;5224:		trap_SetUserinfo(bs->client, userinfo);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 292
ARGP4
ADDRGP4 trap_SetUserinfo
CALLV
pop
line 5226
;5225:		//set the team
;5226:		if ( !bs->map_restart && g_gametype.integer != GT_TOURNAMENT ) {
ADDRFP4 0
INDIRP4
CNSTI4 6020
ADDP4
INDIRI4
CNSTI4 0
NEI4 $2207
ADDRGP4 g_gametype+12
INDIRI4
CNSTI4 1
EQI4 $2207
line 5227
;5227:			Com_sprintf(buf, sizeof(buf), "team %s", bs->settings.team);
ADDRLP4 1316
ARGP4
CNSTI4 144
ARGI4
ADDRGP4 $2210
ARGP4
ADDRFP4 0
INDIRP4
CNSTI4 4756
ADDP4
ARGP4
ADDRGP4 Com_sprintf
CALLV
pop
line 5228
;5228:			trap_EA_Command(bs->client, buf);
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 1316
ARGP4
ADDRGP4 trap_EA_Command
CALLV
pop
line 5229
;5229:		}
LABELV $2207
line 5231
;5230:		//set the chat gender
;5231:		if (gender[0] == 'm') trap_BotSetChatGender(bs->cs, CHAT_GENDERMALE);
ADDRLP4 148
INDIRI1
CVII4 1
CNSTI4 109
NEI4 $2211
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
CNSTI4 2
ARGI4
ADDRGP4 trap_BotSetChatGender
CALLV
pop
ADDRGP4 $2212
JUMPV
LABELV $2211
line 5232
;5232:		else if (gender[0] == 'f')  trap_BotSetChatGender(bs->cs, CHAT_GENDERFEMALE);
ADDRLP4 148
INDIRI1
CVII4 1
CNSTI4 102
NEI4 $2213
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
CNSTI4 1
ARGI4
ADDRGP4 trap_BotSetChatGender
CALLV
pop
ADDRGP4 $2214
JUMPV
LABELV $2213
line 5233
;5233:		else  trap_BotSetChatGender(bs->cs, CHAT_GENDERLESS);
ADDRFP4 0
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
CNSTI4 0
ARGI4
ADDRGP4 trap_BotSetChatGender
CALLV
pop
LABELV $2214
LABELV $2212
line 5235
;5234:		//set the chat name
;5235:		ClientName(bs->client, name, sizeof(name));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
CNSTI4 144
ARGI4
ADDRGP4 ClientName
CALLP4
pop
line 5236
;5236:		trap_BotSetChatName(bs->cs, name, bs->client);
ADDRLP4 1464
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1464
INDIRP4
CNSTI4 6532
ADDP4
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
ADDRLP4 1464
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_BotSetChatName
CALLV
pop
line 5238
;5237:		//
;5238:		bs->lastframe_health = bs->inventory[INVENTORY_HEALTH];
ADDRLP4 1468
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1468
INDIRP4
CNSTI4 6044
ADDP4
ADDRLP4 1468
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
ASGNI4
line 5239
;5239:		bs->lasthitcount = bs->cur_ps.persistant[PERS_HITS];
ADDRLP4 1472
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1472
INDIRP4
CNSTI4 6048
ADDP4
ADDRLP4 1472
INDIRP4
CNSTI4 268
ADDP4
INDIRI4
ASGNI4
line 5241
;5240:		//
;5241:		bs->setupcount = 0;
ADDRFP4 0
INDIRP4
CNSTI4 6016
ADDP4
CNSTI4 0
ASGNI4
line 5243
;5242:		//
;5243:		BotSetupAlternativeRouteGoals();
ADDRGP4 BotSetupAlternativeRouteGoals
CALLV
pop
line 5244
;5244:	}
LABELV $2202
line 5246
;5245:	//no ideal view set
;5246:	bs->flags &= ~BFL_IDEALVIEWSET;
ADDRLP4 1460
ADDRFP4 0
INDIRP4
CNSTI4 5980
ADDP4
ASGNP4
ADDRLP4 1460
INDIRP4
ADDRLP4 1460
INDIRP4
INDIRI4
CNSTI4 -33
BANDI4
ASGNI4
line 5248
;5247:	//
;5248:	if (!BotIntermission(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 1464
ADDRGP4 BotIntermission
CALLI4
ASGNI4
ADDRLP4 1464
INDIRI4
CNSTI4 0
NEI4 $2215
line 5250
;5249:		//set the teleport time
;5250:		BotSetTeleportTime(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotSetTeleportTime
CALLV
pop
line 5252
;5251:		//update some inventory values
;5252:		BotUpdateInventory(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotUpdateInventory
CALLV
pop
line 5254
;5253:		//check out the snapshot
;5254:		BotCheckSnapshot(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotCheckSnapshot
CALLV
pop
line 5256
;5255:		//check for air
;5256:		BotCheckAir(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotCheckAir
CALLV
pop
line 5257
;5257:	}
LABELV $2215
line 5259
;5258:	//check the console messages
;5259:	BotCheckConsoleMessages(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotCheckConsoleMessages
CALLV
pop
line 5261
;5260:	//if not in the intermission and not in observer mode
;5261:	if (!BotIntermission(bs) && !BotIsObserver(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 1468
ADDRGP4 BotIntermission
CALLI4
ASGNI4
ADDRLP4 1468
INDIRI4
CNSTI4 0
NEI4 $2217
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 1472
ADDRGP4 BotIsObserver
CALLI4
ASGNI4
ADDRLP4 1472
INDIRI4
CNSTI4 0
NEI4 $2217
line 5263
;5262:		//do team AI
;5263:		BotTeamAI(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotTeamAI
CALLV
pop
line 5264
;5264:	}
LABELV $2217
line 5266
;5265:	//if the bot has no ai node
;5266:	if (!bs->ainode) {
ADDRFP4 0
INDIRP4
CNSTI4 4900
ADDP4
INDIRP4
CVPU4 4
CNSTU4 0
NEU4 $2219
line 5267
;5267:		AIEnter_Seek_LTG(bs, "BotDeathmatchAI: no ai node");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $2221
ARGP4
ADDRGP4 AIEnter_Seek_LTG
CALLV
pop
line 5268
;5268:	}
LABELV $2219
line 5270
;5269:	//if the bot entered the game less than 8 seconds ago
;5270:	if (!bs->entergamechat && bs->entergame_time > FloatTime() - 8) {
ADDRLP4 1476
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1476
INDIRP4
CNSTI4 6024
ADDP4
INDIRI4
CNSTI4 0
NEI4 $2222
ADDRLP4 1476
INDIRP4
CNSTI4 6064
ADDP4
INDIRF4
ADDRGP4 floattime
INDIRF4
CNSTF4 1090519040
SUBF4
LEF4 $2222
line 5271
;5271:		if (BotChat_EnterGame(bs)) {
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 1480
ADDRGP4 BotChat_EnterGame
CALLI4
ASGNI4
ADDRLP4 1480
INDIRI4
CNSTI4 0
EQI4 $2224
line 5272
;5272:			bs->stand_time = FloatTime() + BotChatTime(bs);
ADDRLP4 1484
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1484
INDIRP4
ARGP4
ADDRLP4 1488
ADDRGP4 BotChatTime
CALLF4
ASGNF4
ADDRLP4 1484
INDIRP4
CNSTI4 6096
ADDP4
ADDRGP4 floattime
INDIRF4
ADDRLP4 1488
INDIRF4
ADDF4
ASGNF4
line 5273
;5273:			AIEnter_Stand(bs, "BotDeathmatchAI: chat enter game");
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 $2226
ARGP4
ADDRGP4 AIEnter_Stand
CALLV
pop
line 5274
;5274:		}
LABELV $2224
line 5275
;5275:		bs->entergamechat = qtrue;
ADDRFP4 0
INDIRP4
CNSTI4 6024
ADDP4
CNSTI4 1
ASGNI4
line 5276
;5276:	}
LABELV $2222
line 5278
;5277:	//reset the node switches from the previous frame
;5278:	BotResetNodeSwitches();
ADDRGP4 BotResetNodeSwitches
CALLV
pop
line 5280
;5279:	//execute AI nodes
;5280:	for (i = 0; i < MAX_NODESWITCHES; i++) {
ADDRLP4 0
CNSTI4 0
ASGNI4
LABELV $2227
line 5281
;5281:		if (bs->ainode(bs)) break;
ADDRLP4 1480
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1480
INDIRP4
ARGP4
ADDRLP4 1484
ADDRLP4 1480
INDIRP4
CNSTI4 4900
ADDP4
INDIRP4
CALLI4
ASGNI4
ADDRLP4 1484
INDIRI4
CNSTI4 0
EQI4 $2231
ADDRGP4 $2229
JUMPV
LABELV $2231
line 5282
;5282:	}
LABELV $2228
line 5280
ADDRLP4 0
ADDRLP4 0
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
INDIRI4
CNSTI4 50
LTI4 $2227
LABELV $2229
line 5284
;5283:	//if the bot removed itself :)
;5284:	if (!bs->inuse) return;
ADDRFP4 0
INDIRP4
INDIRI4
CNSTI4 0
NEI4 $2233
ADDRGP4 $2201
JUMPV
LABELV $2233
line 5286
;5285:	//if the bot executed too many AI nodes
;5286:	if (i >= MAX_NODESWITCHES) {
ADDRLP4 0
INDIRI4
CNSTI4 50
LTI4 $2235
line 5287
;5287:		trap_BotDumpGoalStack(bs->gs);
ADDRFP4 0
INDIRP4
CNSTI4 6528
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_BotDumpGoalStack
CALLV
pop
line 5288
;5288:		trap_BotDumpAvoidGoals(bs->gs);
ADDRFP4 0
INDIRP4
CNSTI4 6528
ADDP4
INDIRI4
ARGI4
ADDRGP4 trap_BotDumpAvoidGoals
CALLV
pop
line 5289
;5289:		BotDumpNodeSwitches(bs);
ADDRFP4 0
INDIRP4
ARGP4
ADDRGP4 BotDumpNodeSwitches
CALLV
pop
line 5290
;5290:		ClientName(bs->client, name, sizeof(name));
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRI4
ARGI4
ADDRLP4 4
ARGP4
CNSTI4 144
ARGI4
ADDRGP4 ClientName
CALLP4
pop
line 5291
;5291:		BotAI_Print(PRT_ERROR, "%s at %1.1f switched more than %d AI nodes\n", name, FloatTime(), MAX_NODESWITCHES);
CNSTI4 3
ARGI4
ADDRGP4 $2237
ARGP4
ADDRLP4 4
ARGP4
ADDRGP4 floattime
INDIRF4
ARGF4
CNSTI4 50
ARGI4
ADDRGP4 BotAI_Print
CALLV
pop
line 5292
;5292:	}
LABELV $2235
line 5294
;5293:	//
;5294:	bs->lastframe_health = bs->inventory[INVENTORY_HEALTH];
ADDRLP4 1480
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1480
INDIRP4
CNSTI4 6044
ADDP4
ADDRLP4 1480
INDIRP4
CNSTI4 5068
ADDP4
INDIRI4
ASGNI4
line 5295
;5295:	bs->lasthitcount = bs->cur_ps.persistant[PERS_HITS];
ADDRLP4 1484
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 1484
INDIRP4
CNSTI4 6048
ADDP4
ADDRLP4 1484
INDIRP4
CNSTI4 268
ADDP4
INDIRI4
ASGNI4
line 5296
;5296:}
LABELV $2201
endproc BotDeathmatchAI 1492 20
export BotSetEntityNumForGoalWithModel
proc BotSetEntityNumForGoalWithModel 44 4
line 5303
;5297:
;5298:/*
;5299:==================
;5300:BotSetEntityNumForGoalWithModel
;5301:==================
;5302:*/
;5303:void BotSetEntityNumForGoalWithModel(bot_goal_t *goal, int eType, char *modelname) {
line 5308
;5304:	gentity_t *ent;
;5305:	int i, modelindex;
;5306:	vec3_t dir;
;5307:
;5308:	modelindex = G_ModelIndex( modelname );
ADDRFP4 8
INDIRP4
ARGP4
ADDRLP4 24
ADDRGP4 G_ModelIndex
CALLI4
ASGNI4
ADDRLP4 20
ADDRLP4 24
INDIRI4
ASGNI4
line 5309
;5309:	ent = &g_entities[0];
ADDRLP4 0
ADDRGP4 g_entities
ASGNP4
line 5310
;5310:	for (i = 0; i < level.num_entities; i++, ent++) {
ADDRLP4 16
CNSTI4 0
ASGNI4
ADDRGP4 $2242
JUMPV
LABELV $2239
line 5311
;5311:		if ( !ent->inuse ) {
ADDRLP4 0
INDIRP4
CNSTI4 520
ADDP4
INDIRI4
CNSTI4 0
NEI4 $2244
line 5312
;5312:			continue;
ADDRGP4 $2240
JUMPV
LABELV $2244
line 5314
;5313:		}
;5314:		if ( eType && ent->s.eType != eType) {
ADDRLP4 28
ADDRFP4 4
INDIRI4
ASGNI4
ADDRLP4 28
INDIRI4
CNSTI4 0
EQI4 $2246
ADDRLP4 0
INDIRP4
CNSTI4 4
ADDP4
INDIRI4
ADDRLP4 28
INDIRI4
EQI4 $2246
line 5315
;5315:			continue;
ADDRGP4 $2240
JUMPV
LABELV $2246
line 5317
;5316:		}
;5317:		if (ent->s.modelindex != modelindex) {
ADDRLP4 0
INDIRP4
CNSTI4 160
ADDP4
INDIRI4
ADDRLP4 20
INDIRI4
EQI4 $2248
line 5318
;5318:			continue;
ADDRGP4 $2240
JUMPV
LABELV $2248
line 5320
;5319:		}
;5320:		VectorSubtract(goal->origin, ent->s.origin, dir);
ADDRLP4 32
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
ADDRLP4 32
INDIRP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 92
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 4+4
ADDRLP4 32
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 96
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 4+8
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 100
ADDP4
INDIRF4
SUBF4
ASGNF4
line 5321
;5321:		if (VectorLengthSquared(dir) < Square(10)) {
ADDRLP4 4
ARGP4
ADDRLP4 40
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 40
INDIRF4
CNSTF4 1120403456
GEF4 $2252
line 5322
;5322:			goal->entitynum = i;
ADDRFP4 0
INDIRP4
CNSTI4 40
ADDP4
ADDRLP4 16
INDIRI4
ASGNI4
line 5323
;5323:			return;
ADDRGP4 $2238
JUMPV
LABELV $2252
line 5325
;5324:		}
;5325:	}
LABELV $2240
line 5310
ADDRLP4 16
ADDRLP4 16
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 808
ADDP4
ASGNP4
LABELV $2242
ADDRLP4 16
INDIRI4
ADDRGP4 level+12
INDIRI4
LTI4 $2239
line 5326
;5326:}
LABELV $2238
endproc BotSetEntityNumForGoalWithModel 44 4
export BotSetEntityNumForGoal
proc BotSetEntityNumForGoal 36 8
line 5333
;5327:
;5328:/*
;5329:==================
;5330:BotSetEntityNumForGoal
;5331:==================
;5332:*/
;5333:void BotSetEntityNumForGoal(bot_goal_t *goal, char *classname) {
line 5338
;5334:	gentity_t *ent;
;5335:	int i;
;5336:	vec3_t dir;
;5337:
;5338:	ent = &g_entities[0];
ADDRLP4 0
ADDRGP4 g_entities
ASGNP4
line 5339
;5339:	for (i = 0; i < level.num_entities; i++, ent++) {
ADDRLP4 16
CNSTI4 0
ASGNI4
ADDRGP4 $2258
JUMPV
LABELV $2255
line 5340
;5340:		if ( !ent->inuse ) {
ADDRLP4 0
INDIRP4
CNSTI4 520
ADDP4
INDIRI4
CNSTI4 0
NEI4 $2260
line 5341
;5341:			continue;
ADDRGP4 $2256
JUMPV
LABELV $2260
line 5343
;5342:		}
;5343:		if ( !Q_stricmp(ent->classname, classname) ) {
ADDRLP4 0
INDIRP4
CNSTI4 524
ADDP4
INDIRP4
ARGP4
ADDRFP4 4
INDIRP4
ARGP4
ADDRLP4 20
ADDRGP4 Q_stricmp
CALLI4
ASGNI4
ADDRLP4 20
INDIRI4
CNSTI4 0
NEI4 $2262
line 5344
;5344:			continue;
ADDRGP4 $2256
JUMPV
LABELV $2262
line 5346
;5345:		}
;5346:		VectorSubtract(goal->origin, ent->s.origin, dir);
ADDRLP4 24
ADDRFP4 0
INDIRP4
ASGNP4
ADDRLP4 4
ADDRLP4 24
INDIRP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 92
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 4+4
ADDRLP4 24
INDIRP4
CNSTI4 4
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 96
ADDP4
INDIRF4
SUBF4
ASGNF4
ADDRLP4 4+8
ADDRFP4 0
INDIRP4
CNSTI4 8
ADDP4
INDIRF4
ADDRLP4 0
INDIRP4
CNSTI4 100
ADDP4
INDIRF4
SUBF4
ASGNF4
line 5347
;5347:		if (VectorLengthSquared(dir) < Square(10)) {
ADDRLP4 4
ARGP4
ADDRLP4 32
ADDRGP4 VectorLengthSquared
CALLF4
ASGNF4
ADDRLP4 32
INDIRF4
CNSTF4 1120403456
GEF4 $2266
line 5348
;5348:			goal->entitynum = i;
ADDRFP4 0
INDIRP4
CNSTI4 40
ADDP4
ADDRLP4 16
INDIRI4
ASGNI4
line 5349
;5349:			return;
ADDRGP4 $2254
JUMPV
LABELV $2266
line 5351
;5350:		}
;5351:	}
LABELV $2256
line 5339
ADDRLP4 16
ADDRLP4 16
INDIRI4
CNSTI4 1
ADDI4
ASGNI4
ADDRLP4 0
ADDRLP4 0
INDIRP4
CNSTI4 808
ADDP4
ASGNP4
LABELV $2258
ADDRLP4 16
INDIRI4
ADDRGP4 level+12
INDIRI4
LTI4 $2255
line 5352
;5352:}
LABELV $2254
endproc BotSetEntityNumForGoal 36 8
export BotGoalForBSPEntity
proc BotGoalForBSPEntity 1128 20
line 5359
;5353:
;5354:/*
;5355:==================
;5356:BotGoalForBSPEntity
;5357:==================
;5358:*/
;5359:int BotGoalForBSPEntity( char *classname, bot_goal_t *goal ) {
line 5364
;5360:	char value[MAX_INFO_STRING];
;5361:	vec3_t origin, start, end;
;5362:	int ent, numareas, areas[10];
;5363:
;5364:	memset(goal, 0, sizeof(bot_goal_t));
ADDRFP4 4
INDIRP4
ARGP4
CNSTI4 0
ARGI4
CNSTI4 56
ARGI4
ADDRGP4 memset
CALLP4
pop
line 5365
;5365:	for (ent = trap_AAS_NextBSPEntity(0); ent; ent = trap_AAS_NextBSPEntity(ent)) {
CNSTI4 0
ARGI4
ADDRLP4 1108
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 1108
INDIRI4
ASGNI4
ADDRGP4 $2272
JUMPV
LABELV $2269
line 5366
;5366:		if (!trap_AAS_ValueForBSPEpairKey(ent, "classname", value, sizeof(value)))
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1836
ARGP4
ADDRLP4 4
ARGP4
CNSTI4 1024
ARGI4
ADDRLP4 1112
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 1112
INDIRI4
CNSTI4 0
NEI4 $2273
line 5367
;5367:			continue;
ADDRGP4 $2270
JUMPV
LABELV $2273
line 5368
;5368:		if (!strcmp(value, classname)) {
ADDRLP4 4
ARGP4
ADDRFP4 0
INDIRP4
ARGP4
ADDRLP4 1116
ADDRGP4 strcmp
CALLI4
ASGNI4
ADDRLP4 1116
INDIRI4
CNSTI4 0
NEI4 $2275
line 5369
;5369:			if (!trap_AAS_VectorForBSPEpairKey(ent, "origin", origin))
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $1852
ARGP4
ADDRLP4 1028
ARGP4
ADDRLP4 1120
ADDRGP4 trap_AAS_VectorForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 1120
INDIRI4
CNSTI4 0
NEI4 $2277
line 5370
;5370:				return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $2268
JUMPV
LABELV $2277
line 5371
;5371:			VectorCopy(origin, goal->origin);
ADDRFP4 4
INDIRP4
ADDRLP4 1028
INDIRB
ASGNB 12
line 5372
;5372:			VectorCopy(origin, start);
ADDRLP4 1040
ADDRLP4 1028
INDIRB
ASGNB 12
line 5373
;5373:			start[2] -= 32;
ADDRLP4 1040+8
ADDRLP4 1040+8
INDIRF4
CNSTF4 1107296256
SUBF4
ASGNF4
line 5374
;5374:			VectorCopy(origin, end);
ADDRLP4 1052
ADDRLP4 1028
INDIRB
ASGNB 12
line 5375
;5375:			end[2] += 32;
ADDRLP4 1052+8
ADDRLP4 1052+8
INDIRF4
CNSTF4 1107296256
ADDF4
ASGNF4
line 5376
;5376:			numareas = trap_AAS_TraceAreas(start, end, areas, NULL, 10);
ADDRLP4 1040
ARGP4
ADDRLP4 1052
ARGP4
ADDRLP4 1068
ARGP4
CNSTP4 0
ARGP4
CNSTI4 10
ARGI4
ADDRLP4 1124
ADDRGP4 trap_AAS_TraceAreas
CALLI4
ASGNI4
ADDRLP4 1064
ADDRLP4 1124
INDIRI4
ASGNI4
line 5377
;5377:			if (!numareas)
ADDRLP4 1064
INDIRI4
CNSTI4 0
NEI4 $2281
line 5378
;5378:				return qfalse;
CNSTI4 0
RETI4
ADDRGP4 $2268
JUMPV
LABELV $2281
line 5379
;5379:			goal->areanum = areas[0];
ADDRFP4 4
INDIRP4
CNSTI4 12
ADDP4
ADDRLP4 1068
INDIRI4
ASGNI4
line 5380
;5380:			return qtrue;
CNSTI4 1
RETI4
ADDRGP4 $2268
JUMPV
LABELV $2275
line 5382
;5381:		}
;5382:	}
LABELV $2270
line 5365
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 1112
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 1112
INDIRI4
ASGNI4
LABELV $2272
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $2269
line 5383
;5383:	return qfalse;
CNSTI4 0
RETI4
LABELV $2268
endproc BotGoalForBSPEntity 1128 20
export BotSetupDeathmatchAI
proc BotSetupDeathmatchAI 156 16
line 5391
;5384:}
;5385:
;5386:/*
;5387:==================
;5388:BotSetupDeathmatchAI
;5389:==================
;5390:*/
;5391:void BotSetupDeathmatchAI(void) {
line 5395
;5392:	int ent, modelnum;
;5393:	char model[128];
;5394:
;5395:	gametype = trap_Cvar_VariableIntegerValue("g_gametype");
ADDRGP4 $2284
ARGP4
ADDRLP4 136
ADDRGP4 trap_Cvar_VariableIntegerValue
CALLI4
ASGNI4
ADDRGP4 gametype
ADDRLP4 136
INDIRI4
ASGNI4
line 5396
;5396:	maxclients = trap_Cvar_VariableIntegerValue("sv_maxclients");
ADDRGP4 $279
ARGP4
ADDRLP4 140
ADDRGP4 trap_Cvar_VariableIntegerValue
CALLI4
ASGNI4
ADDRGP4 maxclients
ADDRLP4 140
INDIRI4
ASGNI4
line 5398
;5397:
;5398:	trap_Cvar_Register(&bot_rocketjump, "bot_rocketjump", "1", 0);
ADDRGP4 bot_rocketjump
ARGP4
ADDRGP4 $2285
ARGP4
ADDRGP4 $2099
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5399
;5399:	trap_Cvar_Register(&bot_grapple, "bot_grapple", "0", 0);
ADDRGP4 bot_grapple
ARGP4
ADDRGP4 $2286
ARGP4
ADDRGP4 $2287
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5400
;5400:	trap_Cvar_Register(&bot_fastchat, "bot_fastchat", "0", 0);
ADDRGP4 bot_fastchat
ARGP4
ADDRGP4 $2288
ARGP4
ADDRGP4 $2287
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5401
;5401:	trap_Cvar_Register(&bot_nochat, "bot_nochat", "0", 0);
ADDRGP4 bot_nochat
ARGP4
ADDRGP4 $2289
ARGP4
ADDRGP4 $2287
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5402
;5402:	trap_Cvar_Register(&bot_testrchat, "bot_testrchat", "0", 0);
ADDRGP4 bot_testrchat
ARGP4
ADDRGP4 $2098
ARGP4
ADDRGP4 $2287
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5403
;5403:	trap_Cvar_Register(&bot_challenge, "bot_challenge", "0", 0);
ADDRGP4 bot_challenge
ARGP4
ADDRGP4 $2290
ARGP4
ADDRGP4 $2287
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5404
;5404:	trap_Cvar_Register(&bot_predictobstacles, "bot_predictobstacles", "1", 0);
ADDRGP4 bot_predictobstacles
ARGP4
ADDRGP4 $2291
ARGP4
ADDRGP4 $2099
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5405
;5405:	trap_Cvar_Register(&g_spSkill, "g_spSkill", "2", 0);
ADDRGP4 g_spSkill
ARGP4
ADDRGP4 $2292
ARGP4
ADDRGP4 $2293
ARGP4
CNSTI4 0
ARGI4
ADDRGP4 trap_Cvar_Register
CALLV
pop
line 5407
;5406:	//
;5407:	if (gametype == GT_CTF) {
ADDRGP4 gametype
INDIRI4
CNSTI4 4
NEI4 $2294
line 5408
;5408:		if (trap_BotGetLevelItemGoal(-1, "Red Flag", &ctf_redflag) < 0)
CNSTI4 -1
ARGI4
ADDRGP4 $2298
ARGP4
ADDRGP4 ctf_redflag
ARGP4
ADDRLP4 144
ADDRGP4 trap_BotGetLevelItemGoal
CALLI4
ASGNI4
ADDRLP4 144
INDIRI4
CNSTI4 0
GEI4 $2296
line 5409
;5409:			BotAI_Print(PRT_WARNING, "CTF without Red Flag\n");
CNSTI4 2
ARGI4
ADDRGP4 $2299
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
LABELV $2296
line 5410
;5410:		if (trap_BotGetLevelItemGoal(-1, "Blue Flag", &ctf_blueflag) < 0)
CNSTI4 -1
ARGI4
ADDRGP4 $2302
ARGP4
ADDRGP4 ctf_blueflag
ARGP4
ADDRLP4 148
ADDRGP4 trap_BotGetLevelItemGoal
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
GEI4 $2300
line 5411
;5411:			BotAI_Print(PRT_WARNING, "CTF without Blue Flag\n");
CNSTI4 2
ARGI4
ADDRGP4 $2303
ARGP4
ADDRGP4 BotAI_Print
CALLV
pop
LABELV $2300
line 5412
;5412:	}
LABELV $2294
line 5443
;5413:#ifdef MISSIONPACK
;5414:	else if (gametype == GT_1FCTF) {
;5415:		if (trap_BotGetLevelItemGoal(-1, "Neutral Flag", &ctf_neutralflag) < 0)
;5416:			BotAI_Print(PRT_WARNING, "One Flag CTF without Neutral Flag\n");
;5417:		if (trap_BotGetLevelItemGoal(-1, "Red Flag", &ctf_redflag) < 0)
;5418:			BotAI_Print(PRT_WARNING, "CTF without Red Flag\n");
;5419:		if (trap_BotGetLevelItemGoal(-1, "Blue Flag", &ctf_blueflag) < 0)
;5420:			BotAI_Print(PRT_WARNING, "CTF without Blue Flag\n");
;5421:	}
;5422:	else if (gametype == GT_OBELISK) {
;5423:		if (trap_BotGetLevelItemGoal(-1, "Red Obelisk", &redobelisk) < 0)
;5424:			BotAI_Print(PRT_WARNING, "Obelisk without red obelisk\n");
;5425:		BotSetEntityNumForGoal(&redobelisk, "team_redobelisk");
;5426:		if (trap_BotGetLevelItemGoal(-1, "Blue Obelisk", &blueobelisk) < 0)
;5427:			BotAI_Print(PRT_WARNING, "Obelisk without blue obelisk\n");
;5428:		BotSetEntityNumForGoal(&blueobelisk, "team_blueobelisk");
;5429:	}
;5430:	else if (gametype == GT_HARVESTER) {
;5431:		if (trap_BotGetLevelItemGoal(-1, "Red Obelisk", &redobelisk) < 0)
;5432:			BotAI_Print(PRT_WARNING, "Harvester without red obelisk\n");
;5433:		BotSetEntityNumForGoal(&redobelisk, "team_redobelisk");
;5434:		if (trap_BotGetLevelItemGoal(-1, "Blue Obelisk", &blueobelisk) < 0)
;5435:			BotAI_Print(PRT_WARNING, "Harvester without blue obelisk\n");
;5436:		BotSetEntityNumForGoal(&blueobelisk, "team_blueobelisk");
;5437:		if (trap_BotGetLevelItemGoal(-1, "Neutral Obelisk", &neutralobelisk) < 0)
;5438:			BotAI_Print(PRT_WARNING, "Harvester without neutral obelisk\n");
;5439:		BotSetEntityNumForGoal(&neutralobelisk, "team_neutralobelisk");
;5440:	}
;5441:#endif
;5442:
;5443:	max_bspmodelindex = 0;
ADDRGP4 max_bspmodelindex
CNSTI4 0
ASGNI4
line 5444
;5444:	for (ent = trap_AAS_NextBSPEntity(0); ent; ent = trap_AAS_NextBSPEntity(ent)) {
CNSTI4 0
ARGI4
ADDRLP4 144
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 144
INDIRI4
ASGNI4
ADDRGP4 $2307
JUMPV
LABELV $2304
line 5445
;5445:		if (!trap_AAS_ValueForBSPEpairKey(ent, "model", model, sizeof(model))) continue;
ADDRLP4 0
INDIRI4
ARGI4
ADDRGP4 $274
ARGP4
ADDRLP4 4
ARGP4
CNSTI4 128
ARGI4
ADDRLP4 148
ADDRGP4 trap_AAS_ValueForBSPEpairKey
CALLI4
ASGNI4
ADDRLP4 148
INDIRI4
CNSTI4 0
NEI4 $2308
ADDRGP4 $2305
JUMPV
LABELV $2308
line 5446
;5446:		if (model[0] == '*') {
ADDRLP4 4
INDIRI1
CVII4 1
CNSTI4 42
NEI4 $2310
line 5447
;5447:			modelnum = atoi(model+1);
ADDRLP4 4+1
ARGP4
ADDRLP4 152
ADDRGP4 atoi
CALLI4
ASGNI4
ADDRLP4 132
ADDRLP4 152
INDIRI4
ASGNI4
line 5448
;5448:			if (modelnum > max_bspmodelindex)
ADDRLP4 132
INDIRI4
ADDRGP4 max_bspmodelindex
INDIRI4
LEI4 $2313
line 5449
;5449:				max_bspmodelindex = modelnum;
ADDRGP4 max_bspmodelindex
ADDRLP4 132
INDIRI4
ASGNI4
LABELV $2313
line 5450
;5450:		}
LABELV $2310
line 5451
;5451:	}
LABELV $2305
line 5444
ADDRLP4 0
INDIRI4
ARGI4
ADDRLP4 148
ADDRGP4 trap_AAS_NextBSPEntity
CALLI4
ASGNI4
ADDRLP4 0
ADDRLP4 148
INDIRI4
ASGNI4
LABELV $2307
ADDRLP4 0
INDIRI4
CNSTI4 0
NEI4 $2304
line 5453
;5452:	//initialize the waypoint heap
;5453:	BotInitWaypoints();
ADDRGP4 BotInitWaypoints
CALLV
pop
line 5454
;5454:}
LABELV $2283
endproc BotSetupDeathmatchAI 156 16
export BotShutdownDeathmatchAI
proc BotShutdownDeathmatchAI 0 0
line 5461
;5455:
;5456:/*
;5457:==================
;5458:BotShutdownDeathmatchAI
;5459:==================
;5460:*/
;5461:void BotShutdownDeathmatchAI(void) {
line 5462
;5462:	altroutegoals_setup = qfalse;
ADDRGP4 altroutegoals_setup
CNSTI4 0
ASGNI4
line 5463
;5463:}
LABELV $2315
endproc BotShutdownDeathmatchAI 0 0
bss
export blue_numaltroutegoals
align 4
LABELV blue_numaltroutegoals
skip 4
export blue_altroutegoals
align 4
LABELV blue_altroutegoals
skip 768
export red_numaltroutegoals
align 4
LABELV red_numaltroutegoals
skip 4
export red_altroutegoals
align 4
LABELV red_altroutegoals
skip 768
export altroutegoals_setup
align 4
LABELV altroutegoals_setup
skip 4
export max_bspmodelindex
align 4
LABELV max_bspmodelindex
skip 4
export lastteleport_time
align 4
LABELV lastteleport_time
skip 4
export lastteleport_origin
align 4
LABELV lastteleport_origin
skip 12
import bot_developer
export g_spSkill
align 4
LABELV g_spSkill
skip 272
export bot_predictobstacles
align 4
LABELV bot_predictobstacles
skip 272
export botai_freewaypoints
align 4
LABELV botai_freewaypoints
skip 4
export botai_waypoints
align 4
LABELV botai_waypoints
skip 12800
import BotVoiceChatOnly
import BotVoiceChat
import BotSetTeamMateTaskPreference
import BotGetTeamMateTaskPreference
import BotTeamAI
import BotDumpNodeSwitches
import BotResetNodeSwitches
import AINode_Battle_NBG
import AINode_Battle_Retreat
import AINode_Battle_Chase
import AINode_Battle_Fight
import AINode_Seek_LTG
import AINode_Seek_NBG
import AINode_Seek_ActivateEntity
import AINode_Stand
import AINode_Respawn
import AINode_Observer
import AINode_Intermission
import AIEnter_Battle_NBG
import AIEnter_Battle_Retreat
import AIEnter_Battle_Chase
import AIEnter_Battle_Fight
import AIEnter_Seek_Camp
import AIEnter_Seek_LTG
import AIEnter_Seek_NBG
import AIEnter_Seek_ActivateEntity
import AIEnter_Stand
import AIEnter_Respawn
import AIEnter_Observer
import AIEnter_Intermission
import BotPrintTeamGoal
import BotMatchMessage
import notleader
import BotChatTest
import BotValidChatPosition
import BotChatTime
import BotChat_Random
import BotChat_EnemySuicide
import BotChat_Kill
import BotChat_Death
import BotChat_HitNoKill
import BotChat_HitNoDeath
import BotChat_HitTalking
import BotChat_EndLevel
import BotChat_StartLevel
import BotChat_ExitGame
import BotChat_EnterGame
export ctf_blueflag
align 4
LABELV ctf_blueflag
skip 56
export ctf_redflag
align 4
LABELV ctf_redflag
skip 56
export bot_challenge
align 4
LABELV bot_challenge
skip 272
export bot_testrchat
align 4
LABELV bot_testrchat
skip 272
export bot_nochat
align 4
LABELV bot_nochat
skip 272
export bot_fastchat
align 4
LABELV bot_fastchat
skip 272
export bot_rocketjump
align 4
LABELV bot_rocketjump
skip 272
export bot_grapple
align 4
LABELV bot_grapple
skip 272
export maxclients
align 4
LABELV maxclients
skip 4
export gametype
align 4
LABELV gametype
skip 4
import BotTeamLeader
import BotAI_GetSnapshotEntity
import BotAI_GetEntityState
import BotAI_GetClientState
import BotAI_Trace
import BotAI_BotInitialChat
import BotAI_Print
import floattime
import BotEntityInfo
import NumBots
import BotResetState
import BotResetWeaponState
import BotFreeWeaponState
import BotAllocWeaponState
import BotLoadWeaponWeights
import BotGetWeaponInfo
import BotChooseBestFightWeapon
import BotShutdownWeaponAI
import BotSetupWeaponAI
import BotShutdownMoveAI
import BotSetupMoveAI
import BotSetBrushModelTypes
import BotAddAvoidSpot
import BotInitMoveState
import BotFreeMoveState
import BotAllocMoveState
import BotPredictVisiblePosition
import BotMovementViewTarget
import BotReachabilityArea
import BotResetLastAvoidReach
import BotResetAvoidReach
import BotMoveInDirection
import BotMoveToGoal
import BotResetMoveState
import BotShutdownGoalAI
import BotSetupGoalAI
import BotFreeGoalState
import BotAllocGoalState
import BotFreeItemWeights
import BotLoadItemWeights
import BotMutateGoalFuzzyLogic
import BotSaveGoalFuzzyLogic
import BotInterbreedGoalFuzzyLogic
import BotUpdateEntityItems
import BotInitLevelItems
import BotSetAvoidGoalTime
import BotAvoidGoalTime
import BotGetMapLocationGoal
import BotGetNextCampSpotGoal
import BotGetLevelItemGoal
import BotItemGoalInVisButNotVisible
import BotTouchingGoal
import BotChooseNBGItem
import BotChooseLTGItem
import BotGetSecondGoal
import BotGetTopGoal
import BotGoalName
import BotDumpGoalStack
import BotDumpAvoidGoals
import BotEmptyGoalStack
import BotPopGoal
import BotPushGoal
import BotRemoveFromAvoidGoals
import BotResetAvoidGoals
import BotResetGoalState
import GeneticParentsAndChildSelection
import BotSetChatName
import BotSetChatGender
import BotLoadChatFile
import BotReplaceSynonyms
import UnifyWhiteSpaces
import BotMatchVariable
import BotFindMatch
import StringContains
import BotGetChatMessage
import BotEnterChat
import BotChatLength
import BotReplyChat
import BotNumInitialChats
import BotInitialChat
import BotNumConsoleMessages
import BotNextConsoleMessage
import BotRemoveConsoleMessage
import BotQueueConsoleMessage
import BotFreeChatState
import BotAllocChatState
import BotShutdownChatAI
import BotSetupChatAI
import BotShutdownCharacters
import Characteristic_String
import Characteristic_BInteger
import Characteristic_Integer
import Characteristic_BFloat
import Characteristic_Float
import BotFreeCharacter
import BotLoadCharacter
import EA_Shutdown
import EA_Setup
import EA_ResetInput
import EA_GetInput
import EA_EndRegular
import EA_View
import EA_Move
import EA_DelayedJump
import EA_Jump
import EA_SelectWeapon
import EA_Use
import EA_Gesture
import EA_Talk
import EA_Respawn
import EA_Attack
import EA_MoveRight
import EA_MoveLeft
import EA_MoveBack
import EA_MoveForward
import EA_MoveDown
import EA_MoveUp
import EA_Walk
import EA_Crouch
import EA_Action
import EA_Command
import EA_SayTeam
import EA_Say
import GetBotLibAPI
import trap_SnapVector
import trap_GeneticParentsAndChildSelection
import trap_BotResetWeaponState
import trap_BotFreeWeaponState
import trap_BotAllocWeaponState
import trap_BotLoadWeaponWeights
import trap_BotGetWeaponInfo
import trap_BotChooseBestFightWeapon
import trap_BotAddAvoidSpot
import trap_BotInitMoveState
import trap_BotFreeMoveState
import trap_BotAllocMoveState
import trap_BotPredictVisiblePosition
import trap_BotMovementViewTarget
import trap_BotReachabilityArea
import trap_BotResetLastAvoidReach
import trap_BotResetAvoidReach
import trap_BotMoveInDirection
import trap_BotMoveToGoal
import trap_BotResetMoveState
import trap_BotFreeGoalState
import trap_BotAllocGoalState
import trap_BotMutateGoalFuzzyLogic
import trap_BotSaveGoalFuzzyLogic
import trap_BotInterbreedGoalFuzzyLogic
import trap_BotFreeItemWeights
import trap_BotLoadItemWeights
import trap_BotUpdateEntityItems
import trap_BotInitLevelItems
import trap_BotSetAvoidGoalTime
import trap_BotAvoidGoalTime
import trap_BotGetLevelItemGoal
import trap_BotGetMapLocationGoal
import trap_BotGetNextCampSpotGoal
import trap_BotItemGoalInVisButNotVisible
import trap_BotTouchingGoal
import trap_BotChooseNBGItem
import trap_BotChooseLTGItem
import trap_BotGetSecondGoal
import trap_BotGetTopGoal
import trap_BotGoalName
import trap_BotDumpGoalStack
import trap_BotDumpAvoidGoals
import trap_BotEmptyGoalStack
import trap_BotPopGoal
import trap_BotPushGoal
import trap_BotResetAvoidGoals
import trap_BotRemoveFromAvoidGoals
import trap_BotResetGoalState
import trap_BotSetChatName
import trap_BotSetChatGender
import trap_BotLoadChatFile
import trap_BotReplaceSynonyms
import trap_UnifyWhiteSpaces
import trap_BotMatchVariable
import trap_BotFindMatch
import trap_StringContains
import trap_BotGetChatMessage
import trap_BotEnterChat
import trap_BotChatLength
import trap_BotReplyChat
import trap_BotNumInitialChats
import trap_BotInitialChat
import trap_BotNumConsoleMessages
import trap_BotNextConsoleMessage
import trap_BotRemoveConsoleMessage
import trap_BotQueueConsoleMessage
import trap_BotFreeChatState
import trap_BotAllocChatState
import trap_Characteristic_String
import trap_Characteristic_BInteger
import trap_Characteristic_Integer
import trap_Characteristic_BFloat
import trap_Characteristic_Float
import trap_BotFreeCharacter
import trap_BotLoadCharacter
import trap_EA_ResetInput
import trap_EA_GetInput
import trap_EA_EndRegular
import trap_EA_View
import trap_EA_Move
import trap_EA_DelayedJump
import trap_EA_Jump
import trap_EA_SelectWeapon
import trap_EA_MoveRight
import trap_EA_MoveLeft
import trap_EA_MoveBack
import trap_EA_MoveForward
import trap_EA_MoveDown
import trap_EA_MoveUp
import trap_EA_Crouch
import trap_EA_Respawn
import trap_EA_Use
import trap_EA_Attack
import trap_EA_Talk
import trap_EA_Gesture
import trap_EA_Action
import trap_EA_Command
import trap_EA_SayTeam
import trap_EA_Say
import trap_AAS_PredictClientMovement
import trap_AAS_Swimming
import trap_AAS_AlternativeRouteGoals
import trap_AAS_PredictRoute
import trap_AAS_EnableRoutingArea
import trap_AAS_AreaTravelTimeToGoalArea
import trap_AAS_AreaReachability
import trap_AAS_IntForBSPEpairKey
import trap_AAS_FloatForBSPEpairKey
import trap_AAS_VectorForBSPEpairKey
import trap_AAS_ValueForBSPEpairKey
import trap_AAS_NextBSPEntity
import trap_AAS_PointContents
import trap_AAS_TraceAreas
import trap_AAS_PointReachabilityAreaIndex
import trap_AAS_PointAreaNum
import trap_AAS_Time
import trap_AAS_PresenceTypeBoundingBox
import trap_AAS_Initialized
import trap_AAS_EntityInfo
import trap_AAS_AreaInfo
import trap_AAS_BBoxAreas
import trap_BotUserCommand
import trap_BotGetServerCommand
import trap_BotGetSnapshotEntity
import trap_BotLibTest
import trap_BotLibUpdateEntity
import trap_BotLibLoadMap
import trap_BotLibStartFrame
import trap_BotLibDefine
import trap_BotLibVarGet
import trap_BotLibVarSet
import trap_BotLibShutdown
import trap_BotLibSetup
import trap_DebugPolygonDelete
import trap_DebugPolygonCreate
import trap_GetEntityToken
import trap_GetUsercmd
import trap_BotFreeClient
import trap_BotAllocateClient
import trap_EntityContact
import trap_EntitiesInBox
import trap_UnlinkEntity
import trap_LinkEntity
import trap_AreasConnected
import trap_AdjustAreaPortalState
import trap_InPVSIgnorePortals
import trap_InPVS
import trap_PointContents
import trap_Trace
import trap_SetBrushModel
import trap_GetServerinfo
import trap_SetUserinfo
import trap_GetUserinfo
import trap_GetConfigstring
import trap_SetConfigstring
import trap_SendServerCommand
import trap_DropClient
import trap_LocateGameData
import trap_Cvar_VariableStringBuffer
import trap_Cvar_VariableValue
import trap_Cvar_VariableIntegerValue
import trap_Cvar_Set
import trap_Cvar_Update
import trap_Cvar_Register
import trap_SendConsoleCommand
import trap_FS_Seek
import trap_FS_GetFileList
import trap_FS_FCloseFile
import trap_FS_Write
import trap_FS_Read
import trap_FS_FOpenFile
import trap_Args
import trap_Argv
import trap_Argc
import trap_Milliseconds
import trap_Error
import trap_Printf
import g_proxMineTimeout
import g_singlePlayer
import g_enableBreath
import g_enableDust
import g_rankings
import pmove_msec
import pmove_fixed
import g_smoothClients
import g_blueteam
import g_redteam
import g_cubeTimeout
import g_obeliskRespawnDelay
import g_obeliskRegenAmount
import g_obeliskRegenPeriod
import g_obeliskHealth
import g_filterBan
import g_banIPs
import g_teamForceBalance
import g_teamAutoJoin
import g_allowVote
import g_blood
import g_doWarmup
import g_warmup
import g_motd
import g_synchronousClients
import g_weaponTeamRespawn
import g_weaponRespawn
import g_debugDamage
import g_debugAlloc
import g_debugMove
import g_inactivity
import g_forcerespawn
import g_quadfactor
import g_knockback
import g_speed
import g_gravity
import g_needpass
import g_password
import g_friendlyFire
import g_capturelimit
import g_timelimit
import g_fraglimit
import g_dmflags
import g_restarted
import g_maxGameClients
import g_maxclients
import g_cheats
import g_dedicated
import g_gametype
import g_entities
import level
import Pickup_Team
import CheckTeamStatus
import TeamplayInfoMessage
import Team_GetLocationMsg
import Team_GetLocation
import SelectCTFSpawnPoint
import Team_FreeEntity
import Team_ReturnFlag
import Team_InitGame
import Team_CheckHurtCarrier
import Team_FragBonuses
import Team_DroppedFlagThink
import AddTeamScore
import TeamColorString
import OtherTeamName
import TeamName
import OtherTeam
import BotTestAAS
import BotAIStartFrame
import BotAIShutdownClient
import BotAISetupClient
import BotAILoadMap
import BotAIShutdown
import BotAISetup
import BotInterbreedEndMatch
import Svcmd_BotList_f
import Svcmd_AddBot_f
import G_BotConnect
import G_RemoveQueuedBotBegin
import G_CheckBotSpawn
import G_GetBotInfoByName
import G_GetBotInfoByNumber
import G_InitBots
import Svcmd_AbortPodium_f
import SpawnModelsOnVictoryPads
import UpdateTournamentInfo
import G_WriteSessionData
import G_InitWorldSession
import G_InitSessionData
import G_ReadSessionData
import Svcmd_GameMem_f
import G_InitMemory
import G_Alloc
import CheckObeliskAttack
import Team_CheckDroppedItem
import OnSameTeam
import G_RunClient
import ClientEndFrame
import ClientThink
import ClientCommand
import ClientBegin
import ClientDisconnect
import ClientUserinfoChanged
import ClientConnect
import G_Error
import G_Printf
import SendScoreboardMessageToAllClients
import G_LogPrintf
import G_RunThink
import CheckTeamLeader
import SetLeader
import FindIntermissionPoint
import DeathmatchScoreboardMessage
import G_SetStats
import MoveClientToIntermission
import FireWeapon
import G_FilterPacket
import G_ProcessIPBans
import ConsoleCommand
import SpotWouldTelefrag
import CalculateRanks
import AddScore
import player_die
import ClientSpawn
import InitBodyQue
import InitClientResp
import InitClientPersistant
import BeginIntermission
import respawn
import CopyToBodyQue
import SelectSpawnPoint
import SetClientViewAngle
import PickTeam
import TeamLeader
import TeamCount
import Weapon_HookThink
import Weapon_HookFree
import CheckGauntletAttack
import SnapVectorTowards
import CalcMuzzlePoint
import LogAccuracyHit
import TeleportPlayer
import trigger_teleporter_touch
import Touch_DoorTrigger
import G_RunMover
import fire_grapple
import fire_bfg
import fire_rocket
import fire_grenade
import fire_plasma
import fire_blaster
import G_RunMissile
import TossClientCubes
import TossClientItems
import body_die
import G_InvulnerabilityEffect
import G_RadiusDamage
import G_Damage
import CanDamage
import BuildShaderStateConfig
import AddRemap
import G_SetOrigin
import G_AddEvent
import G_AddPredictableEvent
import vectoyaw
import vtos
import tv
import G_TouchSolids
import G_TouchTriggers
import G_EntitiesFree
import G_FreeEntity
import G_Sound
import G_TempEntity
import G_Spawn
import G_InitGentity
import G_SetMovedir
import G_UseTargets
import G_PickTarget
import G_Find
import G_KillBox
import G_TeamCommand
import G_SoundIndex
import G_ModelIndex
import SaveRegisteredItems
import RegisterItem
import ClearRegisteredItems
import Touch_Item
import Add_Ammo
import ArmorIndex
import Think_Weapon
import FinishSpawningItem
import G_SpawnItem
import SetRespawn
import LaunchItem
import Drop_Item
import PrecacheItem
import UseHoldableItem
import RespawnItem
import G_RunItem
import G_CheckTeamItems
import Cmd_FollowCycle_f
import SetTeam
import BroadcastTeamChange
import StopFollowing
import Cmd_Score_f
import G_NewString
import G_SpawnEntitiesFromString
import G_SpawnVector
import G_SpawnInt
import G_SpawnFloat
import G_SpawnString
import BG_PlayerTouchesItem
import BG_PlayerStateToEntityStateExtraPolate
import BG_PlayerStateToEntityState
import BG_TouchJumpPad
import BG_AddPredictableEventToPlayerstate
import BG_EvaluateTrajectoryDelta
import BG_EvaluateTrajectory
import BG_CanItemBeGrabbed
import BG_FindItemForHoldable
import BG_FindItemForPowerup
import BG_FindItemForWeapon
import BG_FindItem
import bg_numItems
import bg_itemlist
import Pmove
import PM_UpdateViewAngles
import Com_Printf
import Com_Error
import Info_NextPair
import Info_Validate
import Info_SetValueForKey_Big
import Info_SetValueForKey
import Info_RemoveKey_big
import Info_RemoveKey
import Info_ValueForKey
import va
import Q_CleanStr
import Q_PrintStrlen
import Q_strcat
import Q_strncpyz
import Q_strrchr
import Q_strupr
import Q_strlwr
import Q_stricmpn
import Q_strncmp
import Q_stricmp
import Q_isalpha
import Q_isupper
import Q_islower
import Q_isprint
import Com_sprintf
import Parse3DMatrix
import Parse2DMatrix
import Parse1DMatrix
import SkipRestOfLine
import SkipBracedSection
import COM_MatchToken
import COM_ParseWarning
import COM_ParseError
import COM_Compress
import COM_ParseExt
import COM_Parse
import COM_GetCurrentParseLine
import COM_BeginParseSession
import COM_DefaultExtension
import COM_StripExtension
import COM_SkipPath
import Com_Clamp
import PerpendicularVector
import AngleVectors
import MatrixMultiply
import MakeNormalVectors
import RotateAroundDirection
import RotatePointAroundVector
import ProjectPointOnPlane
import PlaneFromPoints
import AngleDelta
import AngleNormalize180
import AngleNormalize360
import AnglesSubtract
import AngleSubtract
import LerpAngle
import AngleMod
import BoxOnPlaneSide
import SetPlaneSignbits
import AxisCopy
import AxisClear
import AnglesToAxis
import vectoangles
import Q_crandom
import Q_random
import Q_rand
import Q_acos
import Q_log2
import VectorRotate
import Vector4Scale
import VectorNormalize2
import VectorNormalize
import CrossProduct
import VectorInverse
import VectorNormalizeFast
import DistanceSquared
import Distance
import VectorLengthSquared
import VectorLength
import VectorCompare
import AddPointToBounds
import ClearBounds
import RadiusFromBounds
import NormalizeColor
import ColorBytes4
import ColorBytes3
import _VectorMA
import _VectorScale
import _VectorCopy
import _VectorAdd
import _VectorSubtract
import _DotProduct
import ByteToDir
import DirToByte
import ClampShort
import ClampChar
import Q_rsqrt
import Q_fabs
import axisDefault
import vec3_origin
import g_color_table
import colorDkGrey
import colorMdGrey
import colorLtGrey
import colorWhite
import colorCyan
import colorMagenta
import colorYellow
import colorBlue
import colorGreen
import colorRed
import colorBlack
import bytedirs
import Com_Memcpy
import Com_Memset
import Hunk_Alloc
import FloatSwap
import LongSwap
import ShortSwap
import acos
import fabs
import abs
import tan
import atan2
import cos
import sin
import sqrt
import floor
import ceil
import memcpy
import memset
import memmove
import sscanf
import vsprintf
import _atoi
import atoi
import _atof
import atof
import toupper
import tolower
import strncpy
import strstr
import strchr
import strcmp
import strcpy
import strcat
import strlen
import rand
import srand
import qsort
lit
align 1
LABELV $2303
byte 1 67
byte 1 84
byte 1 70
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 66
byte 1 108
byte 1 117
byte 1 101
byte 1 32
byte 1 70
byte 1 108
byte 1 97
byte 1 103
byte 1 10
byte 1 0
align 1
LABELV $2302
byte 1 66
byte 1 108
byte 1 117
byte 1 101
byte 1 32
byte 1 70
byte 1 108
byte 1 97
byte 1 103
byte 1 0
align 1
LABELV $2299
byte 1 67
byte 1 84
byte 1 70
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 82
byte 1 101
byte 1 100
byte 1 32
byte 1 70
byte 1 108
byte 1 97
byte 1 103
byte 1 10
byte 1 0
align 1
LABELV $2298
byte 1 82
byte 1 101
byte 1 100
byte 1 32
byte 1 70
byte 1 108
byte 1 97
byte 1 103
byte 1 0
align 1
LABELV $2293
byte 1 50
byte 1 0
align 1
LABELV $2292
byte 1 103
byte 1 95
byte 1 115
byte 1 112
byte 1 83
byte 1 107
byte 1 105
byte 1 108
byte 1 108
byte 1 0
align 1
LABELV $2291
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 112
byte 1 114
byte 1 101
byte 1 100
byte 1 105
byte 1 99
byte 1 116
byte 1 111
byte 1 98
byte 1 115
byte 1 116
byte 1 97
byte 1 99
byte 1 108
byte 1 101
byte 1 115
byte 1 0
align 1
LABELV $2290
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 99
byte 1 104
byte 1 97
byte 1 108
byte 1 108
byte 1 101
byte 1 110
byte 1 103
byte 1 101
byte 1 0
align 1
LABELV $2289
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 110
byte 1 111
byte 1 99
byte 1 104
byte 1 97
byte 1 116
byte 1 0
align 1
LABELV $2288
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 102
byte 1 97
byte 1 115
byte 1 116
byte 1 99
byte 1 104
byte 1 97
byte 1 116
byte 1 0
align 1
LABELV $2287
byte 1 48
byte 1 0
align 1
LABELV $2286
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 103
byte 1 114
byte 1 97
byte 1 112
byte 1 112
byte 1 108
byte 1 101
byte 1 0
align 1
LABELV $2285
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 114
byte 1 111
byte 1 99
byte 1 107
byte 1 101
byte 1 116
byte 1 106
byte 1 117
byte 1 109
byte 1 112
byte 1 0
align 1
LABELV $2284
byte 1 103
byte 1 95
byte 1 103
byte 1 97
byte 1 109
byte 1 101
byte 1 116
byte 1 121
byte 1 112
byte 1 101
byte 1 0
align 1
LABELV $2237
byte 1 37
byte 1 115
byte 1 32
byte 1 97
byte 1 116
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 115
byte 1 119
byte 1 105
byte 1 116
byte 1 99
byte 1 104
byte 1 101
byte 1 100
byte 1 32
byte 1 109
byte 1 111
byte 1 114
byte 1 101
byte 1 32
byte 1 116
byte 1 104
byte 1 97
byte 1 110
byte 1 32
byte 1 37
byte 1 100
byte 1 32
byte 1 65
byte 1 73
byte 1 32
byte 1 110
byte 1 111
byte 1 100
byte 1 101
byte 1 115
byte 1 10
byte 1 0
align 1
LABELV $2226
byte 1 66
byte 1 111
byte 1 116
byte 1 68
byte 1 101
byte 1 97
byte 1 116
byte 1 104
byte 1 109
byte 1 97
byte 1 116
byte 1 99
byte 1 104
byte 1 65
byte 1 73
byte 1 58
byte 1 32
byte 1 99
byte 1 104
byte 1 97
byte 1 116
byte 1 32
byte 1 101
byte 1 110
byte 1 116
byte 1 101
byte 1 114
byte 1 32
byte 1 103
byte 1 97
byte 1 109
byte 1 101
byte 1 0
align 1
LABELV $2221
byte 1 66
byte 1 111
byte 1 116
byte 1 68
byte 1 101
byte 1 97
byte 1 116
byte 1 104
byte 1 109
byte 1 97
byte 1 116
byte 1 99
byte 1 104
byte 1 65
byte 1 73
byte 1 58
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 97
byte 1 105
byte 1 32
byte 1 110
byte 1 111
byte 1 100
byte 1 101
byte 1 0
align 1
LABELV $2210
byte 1 116
byte 1 101
byte 1 97
byte 1 109
byte 1 32
byte 1 37
byte 1 115
byte 1 0
align 1
LABELV $2206
byte 1 115
byte 1 101
byte 1 120
byte 1 0
align 1
LABELV $2166
byte 1 42
byte 1 102
byte 1 97
byte 1 108
byte 1 108
byte 1 105
byte 1 110
byte 1 103
byte 1 49
byte 1 46
byte 1 119
byte 1 97
byte 1 118
byte 1 0
align 1
LABELV $2163
byte 1 69
byte 1 86
byte 1 95
byte 1 71
byte 1 69
byte 1 78
byte 1 69
byte 1 82
byte 1 65
byte 1 76
byte 1 95
byte 1 83
byte 1 79
byte 1 85
byte 1 78
byte 1 68
byte 1 58
byte 1 32
byte 1 101
byte 1 118
byte 1 101
byte 1 110
byte 1 116
byte 1 80
byte 1 97
byte 1 114
byte 1 109
byte 1 32
byte 1 40
byte 1 37
byte 1 100
byte 1 41
byte 1 32
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 111
byte 1 102
byte 1 32
byte 1 114
byte 1 97
byte 1 110
byte 1 103
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $2142
byte 1 115
byte 1 111
byte 1 117
byte 1 110
byte 1 100
byte 1 47
byte 1 105
byte 1 116
byte 1 101
byte 1 109
byte 1 115
byte 1 47
byte 1 112
byte 1 111
byte 1 119
byte 1 101
byte 1 114
byte 1 117
byte 1 112
byte 1 114
byte 1 101
byte 1 115
byte 1 112
byte 1 97
byte 1 119
byte 1 110
byte 1 46
byte 1 119
byte 1 97
byte 1 118
byte 1 0
align 1
LABELV $2139
byte 1 69
byte 1 86
byte 1 95
byte 1 71
byte 1 76
byte 1 79
byte 1 66
byte 1 65
byte 1 76
byte 1 95
byte 1 83
byte 1 79
byte 1 85
byte 1 78
byte 1 68
byte 1 58
byte 1 32
byte 1 101
byte 1 118
byte 1 101
byte 1 110
byte 1 116
byte 1 80
byte 1 97
byte 1 114
byte 1 109
byte 1 32
byte 1 40
byte 1 37
byte 1 100
byte 1 41
byte 1 32
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 111
byte 1 102
byte 1 32
byte 1 114
byte 1 97
byte 1 110
byte 1 103
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $2110
byte 1 66
byte 1 111
byte 1 116
byte 1 67
byte 1 104
byte 1 101
byte 1 99
byte 1 107
byte 1 67
byte 1 111
byte 1 110
byte 1 115
byte 1 111
byte 1 108
byte 1 101
byte 1 77
byte 1 101
byte 1 115
byte 1 115
byte 1 97
byte 1 103
byte 1 101
byte 1 115
byte 1 58
byte 1 32
byte 1 114
byte 1 101
byte 1 112
byte 1 108
byte 1 121
byte 1 32
byte 1 99
byte 1 104
byte 1 97
byte 1 116
byte 1 0
align 1
LABELV $2103
byte 1 42
byte 1 42
byte 1 42
byte 1 42
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 118
byte 1 97
byte 1 108
byte 1 105
byte 1 100
byte 1 32
byte 1 114
byte 1 101
byte 1 112
byte 1 108
byte 1 121
byte 1 32
byte 1 42
byte 1 42
byte 1 42
byte 1 42
byte 1 10
byte 1 0
align 1
LABELV $2102
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 45
byte 1 10
byte 1 0
align 1
LABELV $2099
byte 1 49
byte 1 0
align 1
LABELV $2098
byte 1 98
byte 1 111
byte 1 116
byte 1 95
byte 1 116
byte 1 101
byte 1 115
byte 1 116
byte 1 114
byte 1 99
byte 1 104
byte 1 97
byte 1 116
byte 1 0
align 1
LABELV $1964
byte 1 37
byte 1 115
byte 1 58
byte 1 32
byte 1 73
byte 1 32
byte 1 104
byte 1 97
byte 1 118
byte 1 101
byte 1 32
byte 1 116
byte 1 111
byte 1 32
byte 1 97
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 32
byte 1 97
byte 1 32
byte 1 37
byte 1 115
byte 1 32
byte 1 97
byte 1 116
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 105
byte 1 110
byte 1 32
byte 1 97
byte 1 114
byte 1 101
byte 1 97
byte 1 32
byte 1 37
byte 1 100
byte 1 10
byte 1 0
align 1
LABELV $1963
byte 1 37
byte 1 115
byte 1 58
byte 1 32
byte 1 73
byte 1 32
byte 1 104
byte 1 97
byte 1 118
byte 1 101
byte 1 32
byte 1 116
byte 1 111
byte 1 32
byte 1 115
byte 1 104
byte 1 111
byte 1 111
byte 1 116
byte 1 32
byte 1 97
byte 1 116
byte 1 32
byte 1 97
byte 1 32
byte 1 37
byte 1 115
byte 1 32
byte 1 102
byte 1 114
byte 1 111
byte 1 109
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 37
byte 1 49
byte 1 46
byte 1 49
byte 1 102
byte 1 32
byte 1 105
byte 1 110
byte 1 32
byte 1 97
byte 1 114
byte 1 101
byte 1 97
byte 1 32
byte 1 37
byte 1 100
byte 1 10
byte 1 0
align 1
LABELV $1959
byte 1 66
byte 1 111
byte 1 116
byte 1 71
byte 1 111
byte 1 70
byte 1 111
byte 1 114
byte 1 65
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 71
byte 1 111
byte 1 97
byte 1 108
byte 1 0
align 1
LABELV $1947
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 95
byte 1 100
byte 1 101
byte 1 108
byte 1 97
byte 1 121
byte 1 0
align 1
LABELV $1946
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 95
byte 1 114
byte 1 101
byte 1 108
byte 1 97
byte 1 121
byte 1 0
align 1
LABELV $1943
byte 1 102
byte 1 117
byte 1 110
byte 1 99
byte 1 95
byte 1 116
byte 1 105
byte 1 109
byte 1 101
byte 1 114
byte 1 0
align 1
LABELV $1932
byte 1 116
byte 1 114
byte 1 105
byte 1 103
byte 1 103
byte 1 101
byte 1 114
byte 1 95
byte 1 109
byte 1 117
byte 1 108
byte 1 116
byte 1 105
byte 1 112
byte 1 108
byte 1 101
byte 1 0
align 1
LABELV $1919
byte 1 66
byte 1 111
byte 1 116
byte 1 71
byte 1 101
byte 1 116
byte 1 65
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 71
byte 1 111
byte 1 97
byte 1 108
byte 1 58
byte 1 32
byte 1 101
byte 1 110
byte 1 116
byte 1 105
byte 1 116
byte 1 121
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 32
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 32
byte 1 34
byte 1 37
byte 1 115
byte 1 34
byte 1 32
byte 1 104
byte 1 97
byte 1 115
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 99
byte 1 108
byte 1 97
byte 1 115
byte 1 115
byte 1 110
byte 1 97
byte 1 109
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $1913
byte 1 66
byte 1 111
byte 1 116
byte 1 71
byte 1 101
byte 1 116
byte 1 65
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 71
byte 1 111
byte 1 97
byte 1 108
byte 1 58
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 101
byte 1 110
byte 1 116
byte 1 105
byte 1 116
byte 1 121
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 32
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 32
byte 1 34
byte 1 37
byte 1 115
byte 1 34
byte 1 10
byte 1 0
align 1
LABELV $1905
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 0
align 1
LABELV $1894
byte 1 66
byte 1 111
byte 1 116
byte 1 71
byte 1 101
byte 1 116
byte 1 65
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 71
byte 1 111
byte 1 97
byte 1 108
byte 1 58
byte 1 32
byte 1 101
byte 1 110
byte 1 116
byte 1 105
byte 1 116
byte 1 121
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 32
byte 1 109
byte 1 111
byte 1 100
byte 1 101
byte 1 108
byte 1 32
byte 1 34
byte 1 37
byte 1 115
byte 1 34
byte 1 32
byte 1 104
byte 1 97
byte 1 115
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 110
byte 1 97
byte 1 109
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $1890
byte 1 116
byte 1 97
byte 1 114
byte 1 103
byte 1 101
byte 1 116
byte 1 110
byte 1 97
byte 1 109
byte 1 101
byte 1 0
align 1
LABELV $1887
byte 1 102
byte 1 117
byte 1 110
byte 1 99
byte 1 95
byte 1 98
byte 1 117
byte 1 116
byte 1 116
byte 1 111
byte 1 110
byte 1 0
align 1
LABELV $1852
byte 1 111
byte 1 114
byte 1 105
byte 1 103
byte 1 105
byte 1 110
byte 1 0
align 1
LABELV $1847
byte 1 115
byte 1 112
byte 1 97
byte 1 119
byte 1 110
byte 1 102
byte 1 108
byte 1 97
byte 1 103
byte 1 115
byte 1 0
align 1
LABELV $1842
byte 1 102
byte 1 117
byte 1 110
byte 1 99
byte 1 95
byte 1 100
byte 1 111
byte 1 111
byte 1 114
byte 1 0
align 1
LABELV $1839
byte 1 66
byte 1 111
byte 1 116
byte 1 71
byte 1 101
byte 1 116
byte 1 65
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 71
byte 1 111
byte 1 97
byte 1 108
byte 1 58
byte 1 32
byte 1 101
byte 1 110
byte 1 116
byte 1 105
byte 1 116
byte 1 121
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 32
byte 1 109
byte 1 111
byte 1 100
byte 1 101
byte 1 108
byte 1 32
byte 1 37
byte 1 115
byte 1 32
byte 1 104
byte 1 97
byte 1 115
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 99
byte 1 108
byte 1 97
byte 1 115
byte 1 115
byte 1 110
byte 1 97
byte 1 109
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $1836
byte 1 99
byte 1 108
byte 1 97
byte 1 115
byte 1 115
byte 1 110
byte 1 97
byte 1 109
byte 1 101
byte 1 0
align 1
LABELV $1835
byte 1 66
byte 1 111
byte 1 116
byte 1 71
byte 1 101
byte 1 116
byte 1 65
byte 1 99
byte 1 116
byte 1 105
byte 1 118
byte 1 97
byte 1 116
byte 1 101
byte 1 71
byte 1 111
byte 1 97
byte 1 108
byte 1 58
byte 1 32
byte 1 110
byte 1 111
byte 1 32
byte 1 101
byte 1 110
byte 1 116
byte 1 105
byte 1 116
byte 1 121
byte 1 32
byte 1 102
byte 1 111
byte 1 117
byte 1 110
byte 1 100
byte 1 32
byte 1 119
byte 1 105
byte 1 116
byte 1 104
byte 1 32
byte 1 109
byte 1 111
byte 1 100
byte 1 101
byte 1 108
byte 1 32
byte 1 37
byte 1 115
byte 1 10
byte 1 0
align 1
LABELV $1823
byte 1 42
byte 1 37
byte 1 100
byte 1 0
align 1
LABELV $1638
byte 1 104
byte 1 101
byte 1 97
byte 1 108
byte 1 116
byte 1 104
byte 1 0
align 1
LABELV $1615
byte 1 97
byte 1 110
byte 1 103
byte 1 108
byte 1 101
byte 1 0
align 1
LABELV $1612
byte 1 108
byte 1 105
byte 1 112
byte 1 0
align 1
LABELV $1574
byte 1 109
byte 1 112
byte 1 113
byte 1 51
byte 1 116
byte 1 111
byte 1 117
byte 1 114
byte 1 110
byte 1 101
byte 1 121
byte 1 54
byte 1 0
align 1
LABELV $1519
byte 1 113
byte 1 51
byte 1 116
byte 1 111
byte 1 117
byte 1 114
byte 1 110
byte 1 101
byte 1 121
byte 1 54
byte 1 0
align 1
LABELV $1515
byte 1 109
byte 1 97
byte 1 112
byte 1 110
byte 1 97
byte 1 109
byte 1 101
byte 1 0
align 1
LABELV $669
byte 1 73
byte 1 110
byte 1 118
byte 1 105
byte 1 115
byte 1 105
byte 1 98
byte 1 105
byte 1 108
byte 1 105
byte 1 116
byte 1 121
byte 1 0
align 1
LABELV $668
byte 1 83
byte 1 112
byte 1 101
byte 1 101
byte 1 100
byte 1 0
align 1
LABELV $667
byte 1 66
byte 1 97
byte 1 116
byte 1 116
byte 1 108
byte 1 101
byte 1 32
byte 1 83
byte 1 117
byte 1 105
byte 1 116
byte 1 0
align 1
LABELV $666
byte 1 82
byte 1 101
byte 1 103
byte 1 101
byte 1 110
byte 1 101
byte 1 114
byte 1 97
byte 1 116
byte 1 105
byte 1 111
byte 1 110
byte 1 0
align 1
LABELV $665
byte 1 81
byte 1 117
byte 1 97
byte 1 100
byte 1 32
byte 1 68
byte 1 97
byte 1 109
byte 1 97
byte 1 103
byte 1 101
byte 1 0
align 1
LABELV $498
byte 1 66
byte 1 111
byte 1 116
byte 1 67
byte 1 114
byte 1 101
byte 1 97
byte 1 116
byte 1 101
byte 1 87
byte 1 97
byte 1 121
byte 1 80
byte 1 111
byte 1 105
byte 1 110
byte 1 116
byte 1 58
byte 1 32
byte 1 79
byte 1 117
byte 1 116
byte 1 32
byte 1 111
byte 1 102
byte 1 32
byte 1 119
byte 1 97
byte 1 121
byte 1 112
byte 1 111
byte 1 105
byte 1 110
byte 1 116
byte 1 115
byte 1 10
byte 1 0
align 1
LABELV $324
byte 1 93
byte 1 0
align 1
LABELV $323
byte 1 91
byte 1 0
align 1
LABELV $322
byte 1 32
byte 1 0
align 1
LABELV $279
byte 1 115
byte 1 118
byte 1 95
byte 1 109
byte 1 97
byte 1 120
byte 1 99
byte 1 108
byte 1 105
byte 1 101
byte 1 110
byte 1 116
byte 1 115
byte 1 0
align 1
LABELV $274
byte 1 109
byte 1 111
byte 1 100
byte 1 101
byte 1 108
byte 1 0
align 1
LABELV $273
byte 1 67
byte 1 108
byte 1 105
byte 1 101
byte 1 110
byte 1 116
byte 1 83
byte 1 107
byte 1 105
byte 1 110
byte 1 58
byte 1 32
byte 1 99
byte 1 108
byte 1 105
byte 1 101
byte 1 110
byte 1 116
byte 1 32
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 111
byte 1 102
byte 1 32
byte 1 114
byte 1 97
byte 1 110
byte 1 103
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $268
byte 1 110
byte 1 0
align 1
LABELV $267
byte 1 91
byte 1 99
byte 1 108
byte 1 105
byte 1 101
byte 1 110
byte 1 116
byte 1 32
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 111
byte 1 102
byte 1 32
byte 1 114
byte 1 97
byte 1 110
byte 1 103
byte 1 101
byte 1 93
byte 1 0
align 1
LABELV $266
byte 1 67
byte 1 108
byte 1 105
byte 1 101
byte 1 110
byte 1 116
byte 1 78
byte 1 97
byte 1 109
byte 1 101
byte 1 58
byte 1 32
byte 1 99
byte 1 108
byte 1 105
byte 1 101
byte 1 110
byte 1 116
byte 1 32
byte 1 111
byte 1 117
byte 1 116
byte 1 32
byte 1 111
byte 1 102
byte 1 32
byte 1 114
byte 1 97
byte 1 110
byte 1 103
byte 1 101
byte 1 10
byte 1 0
align 1
LABELV $185
byte 1 111
byte 1 110
byte 1 102
byte 1 111
byte 1 108
byte 1 108
byte 1 111
byte 1 119
byte 1 0
align 1
LABELV $160
byte 1 105
byte 1 104
byte 1 97
byte 1 118
byte 1 101
byte 1 102
byte 1 108
byte 1 97
byte 1 103
byte 1 0
align 1
LABELV $159
byte 1 37
byte 1 100
byte 1 0
align 1
LABELV $158
byte 1 116
byte 1 101
byte 1 97
byte 1 109
byte 1 116
byte 1 97
byte 1 115
byte 1 107
byte 1 0
align 1
LABELV $135
byte 1 110
byte 1 111
byte 1 0
align 1
LABELV $67
byte 1 116
byte 1 0
