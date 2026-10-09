import { useEffect, useRef, useState } from "react";
import { loadState, resetState, saveState } from "./game/state";

type Room="briefing"|"road"|"yard"|"porch"|"hall"|"parlor"|"kitchen"|"bedroom"|"outside";
type G={room:Room;turn:number;woman:boolean;children:boolean;painting:boolean;reed:boolean;photos:boolean;taken:boolean;done:boolean;strikes:number;monitored:boolean;terminated:boolean;lastThing:string;failed:boolean;ending:string};
const start:G={room:"briefing",turn:0,woman:false,children:false,painting:false,reed:false,photos:false,taken:false,done:false,strikes:0,monitored:false,terminated:false,lastThing:"",failed:false,ending:""};

const intro=[
"RED COMPANY // RECLAIMED CULTURAL MATERIALS",
"FIELD ASSIGNMENT 04-771",
"",
"OBJECTIVE: Locate and reclaim one designated cultural artifact.",
"ARTIFACT: Oil painting. Dimensions unknown.",
"LOCATION: Rural residential property. Southern District.",
"OCCUPANCY: None recorded.",
"",
"Do not remove undesignated materials.",
"Do not remain on site following recovery.",
"",
"Transportation has been arranged.",
"",
"Type BEGIN."
];

function Scene({g}:{g:G}){const family=g.room==="parlor";return <svg className="scene" viewBox="0 0 640 300" role="img" aria-label="Terminal reconstruction of current surroundings">
<g className="wire">
{["road","yard","porch","outside"].includes(g.room)?<><path d="M0 245 Q170 218 320 238 T640 225"/><path d="M0 270 Q190 250 350 265 T640 250"/><path d="M360 215 L382 88 L520 80 L558 218 Z"/><path d="M382 88 L448 42 L520 80"/><rect x="426" y="130" width="43" height="88"/><rect x="486" y="111" width="35" height="42"/><path d="M410 104h105M399 125h125M390 150h140M382 178h153M375 205h170"/></>:null}
{g.room==="road"?<><path d="M105 240 q5-54 12-72 q8 18 12 72M111 184h13"/><circle cx="117" cy="158" r="10"/></>:null}
{g.room==="porch"?<><path d="M90 270V35h420v235M190 270V78h230v192"/><path d="M190 78l230 0M215 270V100h180v170"/><path d="M395 100l-18 170"/></>:null}
{g.room==="hall"?<><path d="M40 285L165 30h310l125 255M165 30v255M475 30v255"/><path d="M285 270q-18-65 0-115q14-35 35-36q22 1 35 36q18 50 0 115"/><ellipse cx="320" cy="94" rx="34" ry="43"/><path d="M293 91q27 12 54 0"/><circle className="blind" cx="307" cy="88" r="5"/><circle className="blind" cx="333" cy="88" r="5"/><path d="M286 143q34 22 68 0M305 118l-6 18M335 118l6 18"/></>:null}
{family?<><rect x="205" y="42" width="230" height="135"/><path d="M215 52q95 45 210 5M218 164q90-65 205-10"/><g className="person"><ellipse cx="120" cy="132" rx="29" ry="38"/><path d="M82 270q8-105 38-100q30-5 38 100"/><circle className="blind" cx="109" cy="130" r="5"/><circle className="blind" cx="131" cy="130" r="5"/></g><g className="person"><ellipse cx="515" cy="122" rx="31" ry="40"/><path d="M474 270q8-112 41-105q33-7 41 105"/><circle className="blind" cx="503" cy="120" r="5"/><circle className="blind" cx="527" cy="120" r="5"/></g><g className="person"><circle cx="245" cy="215" r="23"/><path d="M215 290q5-61 30-58q25-3 30 58"/><circle className="blind" cx="237" cy="213" r="4"/><circle className="blind" cx="253" cy="213" r="4"/></g><g className="person"><circle cx="390" cy="218" r="21"/><path d="M363 290q5-58 27-55q22-3 27 55"/><circle className="blind" cx="383" cy="216" r="4"/><circle className="blind" cx="397" cy="216" r="4"/></g></>:null}
{g.room==="kitchen"?<><path d="M30 270V65h580v205M55 205h220v65M340 105h220v165M70 150h170M385 150h130"/><circle cx="155" cy="113" r="35"/><path d="M145 113h20M155 103v20"/></>:null}
{g.room==="bedroom"?<><path d="M30 270V45h580v225M65 210h290v60M65 210l75-72h215v72M410 175h150v95M420 185l65 45l65-45M420 255l65-45l65 45"/><path d="M425 160q55-45 125 0"/></>:null}
{g.room==="outside"&&g.taken?<>{[70,130,190,450,510,570].map((x,i)=><g key={i}><circle cx={x} cy={170+(i%2)*8} r="8"/><path d={`M${x} 178v48M${x-12} 195h24`}/></g>)}</>:null}
</g></svg>}
function App(){
 const saved:any=loadState(); const [g,setG]=useState<G>(saved.game||start);
 const [lines,setLines]=useState<string[]>(saved.lines||intro); const [cmd,setCmd]=useState("");
 const bottom=useRef<HTMLDivElement>(null);
 useEffect(()=>{saveState({...saved,game:g,lines} as any);bottom.current?.scrollIntoView({behavior:"smooth"})},[g,lines]);
 function say(raw:string,out:string[],patch:Partial<G>={}){setLines(x=>[...x,"","> "+raw.toUpperCase(),...out]);setG(x=>({...x,turn:x.turn+1,...patch}));}
 function remember(thing:string){setG(x=>({...x,lastThing:thing}));}
 function act(e:React.FormEvent){e.preventDefault();const raw=cmd.trim();if(!raw)return;let c=raw.toLowerCase().replace(/[^a-z0-9' ]/g," ").replace(/\\s+/g," ").trim();setCmd("");
  const profanity=/\\b(fuck|fucking|shit|bitch|cunt|asshole|motherfucker|nigger|nigga|faggot|fag|retard|retarded)\\b/i;
  if(g.failed){if(["restart","reset","retry"].includes(c)){resetState();setG(start);setLines(intro);return;}return say(raw,["ASSIGNMENT CLOSED.","Type RETRY to begin again."]);}
  if(g.terminated){
    if(["restart","reset","reconnect"].includes(c)){const watched={...start,monitored:true};resetState();setG(watched);setLines(["RED COMPANY TERMINAL // CONNECTION RESTORED","","MONITORING STATUS: ACTIVE","","Prior communication irregularities remain attached to this employee record.","","Type BEGIN."]);return;}
    return say(raw,["TERMINAL ACCESS SUSPENDED.","Type RECONNECT to request monitored access."]);
  }
  const aggression=/\b(hit|punch|kick|attack|fight|hurt|kill|threaten)\b/i;
  const family=/\b(woman|man|husband|child|children|kid|family|her|him|them|toddler)\b/i;
  const abandon=/\b(leave|drive away|go home|quit|abandon|abscond)\b/i;
  if(aggression.test(c)&&family.test(c)&&["hall","parlor","kitchen","bedroom"].includes(g.room))return say(raw,["You make the first move.","","The house answers all at once.","The family is on you before you reach the door.","","FIELD ASSIGNMENT 04-771: FAILED","CAUSE: HOSTILE CONTACT","ARTIFACT STATUS: UNRECOVERED","EMPLOYEE STATUS: DECEASED","","Type RETRY."],{failed:true,ending:"hostile-contact"});
  if(abandon.test(c)&&!g.taken&&g.room==="road")return say(raw,["You turn the sedan around without approaching the property.","","FIELD ASSIGNMENT 04-771: FAILED","CAUSE: REFUSAL OF ASSIGNED LABOR","ARTIFACT STATUS: UNRECOVERED","","RECOVERY PERSONNEL DISPATCHED.","TRANSPORT TO ABSOLUTION AUTHORIZED.","","Type RETRY."],{failed:true,ending:"early-desertion"});
  if(abandon.test(c)&&!g.taken&&["yard","porch"].includes(g.room))return say(raw,["You return to the sedan.","","FIELD ASSIGNMENT 04-771: FAILED","CAUSE: PREMATURE WITHDRAWAL","ARTIFACT STATUS: UNRECOVERED","","ABSOLUTION: MANDATORY.","","Type RETRY."],{failed:true,ending:"threshold-desertion"});
  if(abandon.test(c)&&!g.taken&&["hall","parlor","kitchen","bedroom"].includes(g.room))return say(raw,["You leave the property without the artifact.","At the sedan, the engine does not start.","The doors lock.","","FIELD ASSIGNMENT 04-771: FAILED","CAUSE: ABANDONMENT AFTER CONTACT","ARTIFACT STATUS: CONFIRMED / UNRECOVERED","","A Company vehicle appears on the dirt road.","Your terminal displays one word:","","ABSOLUTION","","Type RETRY."],{failed:true,ending:"late-desertion"});
  if(profanity.test(c)&&family.test(c)&&["hall","parlor","kitchen","bedroom"].includes(g.room))return say(raw,["The insult leaves your mouth.","Every blind face turns toward you.","","The family moves.","","FIELD ASSIGNMENT 04-771: FAILED","CAUSE: PROVOCATION OF OCCUPANTS","ARTIFACT STATUS: UNRECOVERED","EMPLOYEE STATUS: DECEASED","","Type RETRY."],{failed:true,ending:"provoked-family"});
  if(profanity.test(c)){
    const next=g.strikes+1;
    if(next>=2)return say(raw,["LANGUAGE VIOLATION DETECTED.","","SESSION TERMINATED.","EMPLOYEE COMMUNICATION REVIEW COMPLETE.","","YOUR RESPONSES HAVE BEEN FORWARDED TO","INTERNAL CONDUCT AND DOCTRINAL COMPLIANCE.","","YOU HAVE BEEN SELECTED FOR MONITORING.","","Remain available.","","Type RECONNECT when instructed."],{strikes:next,monitored:true,terminated:true});
    return say(raw,["LANGUAGE VIOLATION DETECTED.","COMMUNICATION IRREGULARITY RECORDED.","Further noncompliance may result in monitoring."],{strikes:next});
  }
  const aliases:[RegExp,string][]=[
    [/^(x|inspect|check out|study)\\b/,"examine"],
    [/^(grab|get|pick up|collect|retrieve)\\b/,"take"],
    [/^(speak to|speak with|ask|question)\\b/,"talk"],
    [/^(walk to|head to|move to|walk toward|approach)\\b/,"go"],
    [/^(exit|depart|go back to car)\\b/,"leave"],
    [/^(i want to |i would like to |please )/,""]
  ];
  aliases.forEach(([r,v])=>{c=c.replace(r,v).trim()});
  c=c.replace(/\\b(picture|portrait|canvas|artifact)\\b/g,"painting").replace(/\\b(lady|mother)\\b/g,"woman").replace(/\\b(photo|photos|pictures)\\b/g,"photograph");
  if(/\\b(it|that|this)\\b/.test(c)&&g.lastThing)c=c.replace(/\\b(it|that|this)\\b/g,g.lastThing);

  if(c==="help")return say(raw,["LOOK, GO [PLACE], ENTER, TALK [PERSON], EXAMINE [THING], SEARCH [THING], TAKE [THING], INVENTORY, LEAVE."]);
  if(g.room==="briefing"){if(["begin","start","continue"].includes(c))return say(raw,["Three hours later.","","The government sedan ticks as it cools behind you.","Yellow grass runs to the horizon. At the end of a dirt track, a white house leans beneath the afternoon heat.","Its siding is chipped nearly gray.","","Something pale stands far out in the field.",""],{room:"road"});return say(raw,["AWAITING CONFIRMATION. Type BEGIN."])}
  if(c==="inventory")return say(raw,[g.taken?"Recovered painting.":"Artifact sleeve.","Company field terminal.","Vehicle key.","Recovery authorization 04-771."]);
  if(c.startsWith("look")){
   if(g.room==="road")return say(raw,["Yellow grass. Dirt road. The leaning house perhaps a quarter mile ahead.",g.turn<4?"At the far edge of the field, a pale figure is standing still.":"The place where you saw the figure is empty."]);
   if(g.room==="yard")return say(raw,["The porch sags toward the earth. Flakes of white paint lie among the weeds.","A curtain moves in an upstairs window.","The property was listed as unoccupied."]);
   if(g.room==="porch")return say(raw,["The front door is open by two inches.","From inside comes the slow scrape of something crossing wood."]);
   if(g.room==="hall")return say(raw,["The house smells of dust, old cooking grease, and hot timber.","Family photographs crowd the walls. In every one, the subjects face slightly away from the camera—toward the same room.",g.children?"A toddler watches you from the end of the hall. His eyes are clouded white.":""]);
   if(g.room==="parlor")return say(raw,["The family has arranged itself around the far wall.","The painting hangs above a bare table.","The canvas is almost colorless. Whatever was painted there has been worn down to stains and ghost-lines.","Every blind face in the room is turned directly toward it.","Doorways lead back to the hall and into a kitchen."],{painting:true});
   if(g.room==="kitchen")return say(raw,["A sink. Canning jars. A dead refrigerator.","Notches have been cut into the doorframe at child-height. Some are dated decades apart.","A doorway leads to the hall. Narrow stairs climb to a bedroom."]);
   if(g.room==="bedroom")return say(raw,["A narrow bed and a cedar chest.","Old photographs cover the inside of the chest lid.",g.photos?"You have already seen enough of them.":"The oldest have curled almost into tubes."]);
  }
  if((c.includes("figure")||c==="watch")&&g.room==="road")return say(raw,["You shade your eyes.","There is no one there.","Something moves in the grass much closer to the house."]);
  if(["walk","walk to house","house","approach","go house"].includes(c)&&g.room==="road")return say(raw,["The grass whispers against your trousers.","Halfway there, you look back.","A pale shape stands beside the sedan.","When you blink, it is gone."],{room:"yard"});
  if(["walk","porch","approach house"].includes(c)&&g.room==="yard")return say(raw,["Three wooden steps complain beneath your weight.","Before you can knock, the door shifts inward."],{room:"porch"});
  if(["enter","open door","go inside"].includes(c)&&g.room==="porch")return say(raw,["A woman stands ten feet inside.","Her hair hangs in ropes. Her dress is stained at the hem. Both eyes are milk-white.","She tilts her head toward you.","","\"Dreed?\""],{room:"hall",woman:true});
  if((c.startsWith("talk")||c.includes("woman"))&&g.room==="hall")return say(raw,["\"Red Company. I'm here for the painting.\"","The woman smiles without looking at you.","","\"Dreed,\" she says.","","A small voice farther inside answers her.","","\"Dreed.\""],{children:true});
  if((c.includes("follow")||c.includes("painting")||c==="parlor"||c==="go room")&&g.room==="hall")return say(raw,["The woman turns and walks without touching the walls.","You follow.","Two children sit on the floor. One cannot be older than three. Both are blind.","A man stands behind them, pale and thin.","","\"Dreed,\" the little one says happily."],{room:"parlor",children:true});
  if((c.includes("photo")||c.includes("chest"))&&g.room==="bedroom")return say(raw,["The photographs span generations.","Children become parents. Parents become old.","The painting is present in every room, every decade.","No one in the photographs is looking at the camera.","They are all facing the painting."],{photos:true});
  if((c.includes("painting")||c==="inspect"||c==="examine")&&g.room==="parlor"){remember("painting");return say(raw,["Up close, the artifact is worse than you thought.","The varnish is cracked. The image has faded almost completely away.","You cannot tell what it depicts.","","The little girl points precisely to the lower right corner.","","\"His hand,\" she says.","","There is nothing there you can see."],{painting:true});}
  if((c.startsWith("take")||c.includes("remove")||c.includes("pull painting")||c.includes("painting down"))&&g.room==="parlor"&&g.painting)return say(raw,["You lift the frame from its nail.","Every member of the family inhales at once.","The husband takes one step toward you. The woman catches his wrist.","On the back, beneath decades of dust, are two faded characters:","","D. REED","","The toddlers begin saying it together.","","\"Dreed. Dreed. Dreed.\""],{reed:true,taken:true});
  if((c.includes("search")||c.includes("terminal")||c.includes("reed"))&&g.reed)return say(raw,["FIELD TERMINAL SEARCHING...","","D. REED","CROSS-REFERENCE FOUND.","","REED, DANTE","DANTE REED","","[ RECORD RESTRICTED ]","","DO NOT QUERY THIS NAME AGAIN."]);
  if((c==="kitchen"||c.includes("go kitchen"))&&["hall","parlor"].includes(g.room))return say(raw,["You leave the family behind and enter the kitchen."],{room:"kitchen"});
  if((c.includes("upstairs")||c.includes("bedroom")||c==="stairs")&&g.room==="kitchen")return say(raw,["The stairs bend under your weight.","At the top is a single bedroom."],{room:"bedroom"});
  if((c==="downstairs"||c.includes("go hall")||c==="hall")&&["bedroom","kitchen"].includes(g.room))return say(raw,["You return to the hall."],{room:"hall"});
  if((c.includes("parlor")||c.includes("painting"))&&g.room==="kitchen")return say(raw,["You return to the parlor. Every head turns with you."],{room:"parlor"});
  if((c==="leave"||c.includes("go outside")||c.includes("return car"))&&g.taken)return say(raw,["You step out into the yellow field with the painting.","No one follows.","","Halfway to the sedan, you notice pale figures standing along the horizon.","Five. Then seven. Then more.","","All of them face you.","","The artifact sleeve shifts under your arm.","From the house, faint across the field:","","\"Dreed.\"","","RECOVERY OBJECTIVE COMPLETE.","RETURN ARTIFACT TO RED COMPANY CUSTODY."],{room:"outside",done:true});
  const understood=/\\b(look|go|walk|enter|open|talk|examine|take|search|leave|inventory|help|painting|woman|man|child|door|house|road|car|kitchen|bedroom|hall|parlor|photograph)\\b/.test(c);
  if(understood)return say(raw,["REQUEST UNDERSTOOD.","That action is not available from your present position."]);
  const next=g.strikes+1;
  if(next>=3)return say(raw,["NON-RED COMPANY COMPLIANT RESPONSE.","COMMUNICATION IRREGULARITY RECORDED.","Continued irregular input may be referred for review."],{strikes:next});
  return say(raw,["NON-RED COMPANY COMPLIANT RESPONSE.","Rephrase your request."],{strikes:next});
 }
 function restart(){resetState();setG(start);setLines(intro);setCmd("")}
 return <main className="shell"><article className="reader terminal"><div className="story">{lines.map((l,i)=><p key={i}>{l||"\u00a0"}</p>)}</div><Scene g={g}/><form onSubmit={act} className="command-line"><span>&gt;</span><input autoFocus value={cmd} onChange={e=>setCmd(e.target.value)} aria-label="Command" autoComplete="off"/></form><button className="reset" onClick={restart}>RESET</button><div ref={bottom}/></article></main>
}
export default App;