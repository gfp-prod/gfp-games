import type {Intent} from "../../engine/parser";
import {resolve,type RoomId} from "../../engine/world";
export type Result={text:string[];room?:RoomId;target?:string};
export function interact(room:RoomId,i:Intent):Result|undefined{const e=resolve(room,i.target);if(!e)return;const target=e.id;
if(i.verb==="move"){
 if(room==="road"&&target==="field")return{text:["You leave the dirt track and push into the yellow grass.","It closes around your knees. The ground is wet beneath the baked surface.","Something moves against the wind farther in.","You can continue deeper, or return toward the house."],target};
 if(room==="road"&&target==="figure")return{text:["You approach the pale figure.","It does not grow larger as you close the distance.","The house and sedan both seem farther away.","When you look forward again, the figure is gone."],target};
 if(room==="road"&&target==="house")return{text:["You follow the dirt track toward the leaning house.","Halfway there, a pale shape is standing beside your sedan.","You blink. It is gone."],room:"yard",target};
 if(room==="yard"&&target==="porch")return{text:["You cross the weeds to the porch.","Three wooden steps complain beneath your weight."],room:"porch",target};
 if(room==="yard"&&target==="window")return{text:["You circle beneath the upstairs window.","The curtain stops moving.","A small hand presses flat against the glass."],target};
 if((room==="yard"||room==="porch")&&target==="field")return{text:["You step back into the yellow grass.","The house disappears behind the stalks faster than it should.","Something pale keeps pace to your right."],target};
 if(room==="hall"&&target==="woman")return{text:["You close the distance.","Her clouded eyes remain fixed slightly above your shoulder.","Old scars ring both eyelids.","\"Dreed,\" she whispers."],target};
 if(room==="hall"&&target==="parlor")return{text:["You move past the woman into the parlor."],room:"parlor",target};
 if(room==="parlor"&&target==="painting")return{text:["You approach the painting.","Every blind face follows you with impossible precision.","At arm's length the ruined surface resolves into scratches and almost-figures."],target};
 if(room==="parlor"&&target==="family")return{text:["You step toward the family.","They make room without being asked.","Their blind eyes remain trained on the painting behind you."],target};
 if(room==="parlor"&&target==="kitchen")return{text:["You enter the kitchen."],room:"kitchen",target};
 if(room==="kitchen"&&target==="stairs")return{text:["The stairs bend under your weight.","At the top is a single bedroom."],room:"bedroom",target};
 if(room==="bedroom"&&target==="stairs")return{text:["You return downstairs to the hall."],room:"hall",target};
}
return{text:["You can reach "+target+", but that action has no useful effect."],target}}
