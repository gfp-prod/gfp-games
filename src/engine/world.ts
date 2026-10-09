import type {Verb} from "./parser";
export type RoomId="road"|"yard"|"porch"|"hall"|"parlor"|"kitchen"|"bedroom"|"outside";
export type Entity={id:string;aliases:string[];verbs?:Verb[]};
export const WORLD:Record<RoomId,Entity[]>={
road:[{id:"field",aliases:["grass","yellow grass","field","yellow field","weeds","horizon"],verbs:["move","look"]},{id:"figure",aliases:["figure","pale figure","person","shape","pale shape"],verbs:["move","look"]},{id:"house",aliases:["house","white house","farmhouse","home","property"],verbs:["move","look"]},{id:"road",aliases:["road","dirt road","track"],verbs:["move","look"]},{id:"car",aliases:["car","sedan","vehicle"],verbs:["move","look","leave"]}],
yard:[{id:"porch",aliases:["porch","steps","front steps"],verbs:["move","look"]},{id:"window",aliases:["window","upstairs window","curtain"],verbs:["move","look"]},{id:"field",aliases:["grass","field","weeds"],verbs:["move","look"]},{id:"house-side",aliases:["side","back","rear","behind house","around house"],verbs:["move","look"]}],
porch:[{id:"door",aliases:["door","front door","inside","house"],verbs:["move","enter","look"]},{id:"yard",aliases:["yard","grass","field"],verbs:["move","look"]}],
hall:[{id:"woman",aliases:["woman","lady","her"],verbs:["move","look","talk","attack"]},{id:"parlor",aliases:["parlor","room","painting room"],verbs:["move"]},{id:"photos",aliases:["photos","photographs","pictures","walls"],verbs:["look"]}],
parlor:[{id:"painting",aliases:["painting","picture","portrait","canvas","artifact","frame","wall"],verbs:["move","look","take"]},{id:"family",aliases:["family","man","husband","children","child","kids","kid","toddler"],verbs:["move","look","talk","attack"]},{id:"kitchen",aliases:["kitchen"],verbs:["move"]},{id:"hall",aliases:["hall","hallway"],verbs:["move"]}],
kitchen:[{id:"stairs",aliases:["stairs","staircase","upstairs","bedroom"],verbs:["move"]},{id:"jars",aliases:["jars","canning jars","sink","refrigerator","fridge","notches"],verbs:["look"]},{id:"hall",aliases:["hall","hallway"],verbs:["move"]},{id:"parlor",aliases:["parlor","painting"],verbs:["move"]}],
bedroom:[{id:"chest",aliases:["chest","cedar chest","photos","photographs","pictures"],verbs:["look","search"]},{id:"bed",aliases:["bed"],verbs:["look"]},{id:"stairs",aliases:["stairs","downstairs","hall"],verbs:["move"]}],
outside:[{id:"figures",aliases:["figures","people","horizon","pale figures"],verbs:["look","move"]},{id:"car",aliases:["car","sedan","vehicle"],verbs:["move"]}]
};
export function resolve(room:RoomId,target:string){const t=target.replace(/^(to|toward|towards|into|through|at) /,"").trim();let best:Entity|undefined;let score=0;for(const e of WORLD[room])for(const a of e.aliases){if(t===a)return e;if(t.includes(a)&&a.length>score){best=e;score=a.length}}return best}
