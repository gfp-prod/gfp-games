import { useEffect, useRef, useState } from "react";
import { loadState, resetState, saveState } from "./game/state";

type Room="briefing"|"road"|"yard"|"porch"|"hall"|"parlor";
type G={room:Room;turn:number;woman:boolean;children:boolean;painting:boolean;reed:boolean;done:boolean};
const start:G={room:"briefing",turn:0,woman:false,children:false,painting:false,reed:false,done:false};

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

function App(){
 const saved:any=loadState(); const [g,setG]=useState<G>(saved.game||start);
 const [lines,setLines]=useState<string[]>(saved.lines||intro); const [cmd,setCmd]=useState("");
 const bottom=useRef<HTMLDivElement>(null);
 useEffect(()=>{saveState({...saved,game:g,lines} as any);bottom.current?.scrollIntoView({behavior:"smooth"})},[g,lines]);
 function say(raw:string,out:string[],patch:Partial<G>={}){setLines(x=>[...x,"","> "+raw.toUpperCase(),...out]);setG(x=>({...x,turn:x.turn+1,...patch}));}
 function act(e:React.FormEvent){e.preventDefault();const raw=cmd.trim();if(!raw)return;const c=raw.toLowerCase();setCmd("");
  if(c==="help")return say(raw,["LOOK, WALK, ENTER, TALK, SEARCH, TAKE, INVENTORY."]);
  if(g.room==="briefing"){if(["begin","start","continue"].includes(c))return say(raw,["Three hours later.","","The government sedan ticks as it cools behind you.","Yellow grass runs to the horizon. At the end of a dirt track, a white house leans beneath the afternoon heat.","Its siding is chipped nearly gray.","","Something pale stands far out in the field.",""],{room:"road"});return say(raw,["AWAITING CONFIRMATION. Type BEGIN."])}
  if(c==="inventory")return say(raw,["Company field terminal.","Artifact sleeve.","Vehicle key.","Recovery authorization 04-771."]);
  if(c.startsWith("look")){
   if(g.room==="road")return say(raw,["Yellow grass. Dirt road. The leaning house perhaps a quarter mile ahead.",g.turn<4?"At the far edge of the field, a pale figure is standing still.":"The place where you saw the figure is empty."]);
   if(g.room==="yard")return say(raw,["The porch sags toward the earth. Flakes of white paint lie among the weeds.","A curtain moves in an upstairs window.","The property was listed as unoccupied."]);
   if(g.room==="porch")return say(raw,["The front door is open by two inches.","From inside comes the slow scrape of something crossing wood."]);
   if(g.room==="hall")return say(raw,["The house smells of dust, old cooking grease, and hot timber.","Family photographs crowd the walls. In every one, the subjects face slightly away from the camera—toward the same room.",g.children?"A toddler watches you from the end of the hall. His eyes are clouded white.":""]);
   if(g.room==="parlor")return say(raw,["The family has arranged itself around the far wall.","The painting hangs above a bare table.","The canvas is almost colorless. Whatever was painted there has been worn down to stains and ghost-lines.","Every blind face in the room is turned directly toward it."],{painting:true});
  }
  if((c.includes("figure")||c==="watch")&&g.room==="road")return say(raw,["You shade your eyes.","There is no one there.","Something moves in the grass much closer to the house."]);
  if(["walk","walk to house","house","approach","go house"].includes(c)&&g.room==="road")return say(raw,["The grass whispers against your trousers.","Halfway there, you look back.","A pale shape stands beside the sedan.","When you blink, it is gone."],{room:"yard"});
  if(["walk","porch","approach house"].includes(c)&&g.room==="yard")return say(raw,["Three wooden steps complain beneath your weight.","Before you can knock, the door shifts inward."],{room:"porch"});
  if(["enter","open door","go inside"].includes(c)&&g.room==="porch")return say(raw,["A woman stands ten feet inside.","Her hair hangs in ropes. Her dress is stained at the hem. Both eyes are milk-white.","She tilts her head toward you.","","\"Dreed?\""],{room:"hall",woman:true});
  if((c.startsWith("talk")||c.includes("woman"))&&g.room==="hall")return say(raw,["\"Red Company. I'm here for the painting.\"","The woman smiles without looking at you.","","\"Dreed,\" she says.","","A small voice farther inside answers her.","","\"Dreed.\""],{children:true});
  if((c.includes("follow")||c.includes("painting")||c==="parlor"||c==="go room")&&g.room==="hall")return say(raw,["The woman turns and walks without touching the walls.","You follow.","Two children sit on the floor. One cannot be older than three. Both are blind.","A man stands behind them, pale and thin.","","\"Dreed,\" the little one says happily."],{room:"parlor",children:true});
  if((c.includes("painting")||c==="inspect"||c==="examine")&&g.room==="parlor")return say(raw,["Up close, the artifact is worse than you thought.","The varnish is cracked. The image has faded almost completely away.","You cannot tell what it depicts.","","The little girl points precisely to the lower right corner.","","\"His hand,\" she says.","","There is nothing there you can see."],{painting:true});
  if((c.startsWith("take")||c.includes("remove"))&&g.room==="parlor"&&g.painting)return say(raw,["You lift the frame from its nail.","Every member of the family inhales at once.","On the back, beneath decades of dust, are two faded characters:","","D. REED","","Behind you, the woman begins to weep.","","\"Dreed.\""],{reed:true});
  if((c.includes("search")||c.includes("terminal")||c.includes("reed"))&&g.reed)return say(raw,["FIELD TERMINAL SEARCHING...","","D. REED","CROSS-REFERENCE FOUND.","","REED, DANTE","DANTE REED","","[ RECORD RESTRICTED ]","","DO NOT QUERY THIS NAME AGAIN."]);
  return say(raw,["You cannot do that here."]);
 }
 function restart(){resetState();setG(start);setLines(intro);setCmd("")}
 return <main className="shell"><article className="reader terminal"><div className="story">{lines.map((l,i)=><p key={i}>{l||"\u00a0"}</p>)}</div><form onSubmit={act} className="command-line"><span>&gt;</span><input autoFocus value={cmd} onChange={e=>setCmd(e.target.value)} aria-label="Command" autoComplete="off"/></form><button className="reset" onClick={restart}>RESET</button><div ref={bottom}/></article></main>
}
export default App;