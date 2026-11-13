extends RefCounted
## Compact, fictional polygenic appearance model. Two alleles per locus are
## persisted, one transmitted from each parent; no locus encodes ethnicity,
## morality, intelligence, sex, social role or an individual's choices.
const VERSION: int=3
# Version 2 extends the physique and facial-control genome without changing
# any of the original 28 loci or their transmitted parental alleles.
const EXTRA_MORPH_TRAITS: Array[String]=[
	"chest_width","bust_volume","waist_width","hip_width",
	"muscle_tone","eye_aperture","nostril_width","lip_curve"
]
# Version 3: visual grooming, hair silhouette and biologically inherited
# beard potential. Expression is age/sex-sensitive; alleles are not.
const GROOM_TRAITS: Array[String]=[
	"hair_length","hair_style","hair_parting","facial_hair_density",
	"facial_hair_pattern","facial_hair_length","mustache_weight",
	"sideburn_weight"
]
const TRAITS: Array[String]=[
	"pigment","warmth","eye_pigment","hair_pigment","hair_curl",
	"face_width","face_length","jaw_width","jaw_angle",
	"cheek_height","cheek_fullness","nose_width","nose_bridge",
	"nose_projection","eye_spacing","eye_shape","brow_height",
	"brow_angle","mouth_width","lip_fullness","ear_size",
	"stature","shoulder_width","body_depth","limb_ratio",
	"hair_volume","freckles","magic_sensitivity",
	"chest_width","bust_volume","waist_width","hip_width",
	"muscle_tone","eye_aperture","nostril_width","lip_curve",
	"hair_length","hair_style","hair_parting","facial_hair_density",
	"facial_hair_pattern","facial_hair_length","mustache_weight",
	"sideburn_weight"
]
const CAP: int=1000
const MAX_ANCIENT: int=64

static func _seeded(id: String, salt: int=1938) -> RandomNumberGenerator:
	var value: int=2166136261
	for i in range(id.length()):
		value=posmod((value*16777619)^id.unicode_at(i),2147483647)
	var r:=RandomNumberGenerator.new()
	r.seed=(value ^ (salt*1013904223)) & 0x7fffffffffffffff
	return r

static func founder(id: String, salt: int=1938) -> Dictionary:
	var r:=_seeded(id,salt)
	var alleles: Dictionary={}
	for locus in TRAITS:
		# A founder is born with two related alleles, not two independent
		# uniform draws. Uniform averaging previously concentrated nearly
		# every face, complexion and physique around the same midpoint.
		# A per-locus inherited baseline preserves a broad natural range,
		# while individual alleles leave meaningful room for siblings to
		# receive different combinations from the SAME parents.
		var base: int=r.randi_range(70,930)
		var variation: int=175 if locus in ["pigment","warmth",
			"eye_pigment","hair_pigment","hair_curl"] else 205
		alleles[locus]=[
			clampi(base+r.randi_range(-variation,variation),0,CAP),
			clampi(base+r.randi_range(-variation,variation),0,CAP)]
	return {"version":VERSION,"alleles":alleles}

static func validate(g: Variant) -> bool:
	if not (g is Dictionary) or int(g.get("version",0))!=VERSION: return false
	var alleles: Variant=g.get("alleles",{})
	if not (alleles is Dictionary) or alleles.size()!=TRAITS.size(): return false
	for locus in TRAITS:
		if not alleles.has(locus) or not (alleles[locus] is Array) or alleles[locus].size()!=2:
			return false
		for value in alleles[locus]:
			if not (value is int or value is float): return false
			if value<0 or value>CAP or float(value)!=float(int(value)): return false
	return true

static func upgrade(g: Variant,person_id: String,salt: int=1938) -> Dictionary:
	# Migrate real v1 and v2 saves without changing a single existing gene.
	# Saved families retain every parent, child and historical inherited trait.
	if validate(g): return normalize(g)
	if not (g is Dictionary): return {}
	var saved_version: int=int(g.get("version",0))
	if saved_version not in [1,2]: return {}
	var source: Variant=g.get("alleles",{})
	if not (source is Dictionary): return {}
	var missing: Array[String]=[]
	for locus in TRAITS:
		if saved_version==1 and locus in EXTRA_MORPH_TRAITS:
			missing.append(locus)
		elif locus in GROOM_TRAITS:
			missing.append(locus)
	if source.size()!=TRAITS.size()-missing.size(): return {}
	for locus in TRAITS:
		if locus in missing: continue
		if not source.has(locus) or not (source[locus] is Array): return {}
		if source[locus].size()!=2: return {}
		for allele in source[locus]:
			if not (allele is int or allele is float): return {}
			if int(allele)<0 or int(allele)>CAP or float(allele)!=float(int(allele)):
				return {}
	var result: Dictionary={"version":VERSION,"alleles":{}}
	var baseline: Dictionary=founder(person_id,salt)
	for locus in TRAITS:
		var pair: Array=baseline["alleles"][locus] if locus in missing else source[locus]
		result["alleles"][locus]=[int(pair[0]),int(pair[1])]
	return result

static func normalize(g: Dictionary) -> Dictionary:
	# JSON parses integer-looking values as numeric variants that may
	# differ in type; canonize all alleles before simulation comparison.
	if not validate(g): return {}
	var canonical: Dictionary={"version":VERSION,"alleles":{}}
	for locus in TRAITS:
		var pair: Array=g["alleles"][locus]
		canonical["alleles"][locus]=[int(pair[0]),int(pair[1])]
	return canonical

static func value(g: Dictionary, locus: String) -> float:
	# Per-vertex geometry evaluation calls this many times. Full schema
	# validation runs once at the boundary, never for each face vertex.
	if not g.has("alleles") or not g["alleles"].has(locus): return .5
	var pair: Array=g["alleles"][locus]
	return (float(pair[0])+float(pair[1]))/(2.0*CAP)

## Sex is a saved physical phenotype, not an intelligence/personality
## allele or a shortcut for occupation. It influences population averages,
## never imposes a hard upper or lower bound on inherited adult body size.
static func offspring_sex(child_id: String,salt: int=1938) -> String:
	return "female" if _seeded(child_id,salt+313).randi_range(0,1)==0 else "male"

static func body_scale(g: Dictionary,sex: String="unspecified") -> Vector3:
	# Broad overlap: a large-statured daughter can tower over a small man.
	# Both parents transmit the actual stature alleles; sex shifts only the
	# baseline expression and does not replace the heritable signal.
	# A little more leg/torso height and less universal X/Z mass prevents
	# every moderate-allele adult reading as stocky. Extremes still overlap.
	var height_gene: float=value(g,"stature")
	var shoulders: float=value(g,"shoulder_width")
	var depth: float=value(g,"body_depth")
	var female: bool=sex=="female"
	var height: float=(.875+.325*height_gene) if female else (.94+.32*height_gene)
	var breadth: float=lerpf(.855,1.095,shoulders)
	if female:
		# Broad-shouldered women retain their width; fine-boned women
		# average narrower, without overriding their transmitted genes.
		breadth*=lerpf(.945,1.012,shoulders)
	var thickness: float=lerpf(.855,1.085,depth)
	if female:
		thickness*=lerpf(.955,1.01,depth)
	return Vector3(breadth,height,thickness)

static func forearm_length(g: Dictionary) -> float:
	# The original 0.475–0.635 lower-arm span, added to the 0.41
	# upper arm and full hands, put fingertips at knee height. Restore a
	# human elbow-to-wrist ratio while still expressing inherited reach.
	# Stature is handled by body_scale's Y; limb_ratio remains heritable.
	return lerpf(.285,.385,value(g,"limb_ratio"))

## Potential for facial hair is inherited by all, but normally expressed
## by adult male phenotypes. Individual genetic variation is broad.
static func beard_profile(g: Dictionary,sex: String,age_years: float=28.0) -> Dictionary:
	var maturity: float=smoothstep(16.0,24.0,age_years)
	var density: float=value(g,"facial_hair_density")
	var length: float=value(g,"facial_hair_length")
	var pattern: float=value(g,"facial_hair_pattern")
	var mustache: float=value(g,"mustache_weight")
	var sideburn: float=value(g,"sideburn_weight")
	var expressed: float=density*maturity if sex=="male" else 0.0
	var style: String="clean"
	if expressed>.19:
		style="stubble"
	if expressed>.35 and mustache>.59 and pattern<.39:
		style="moustache"
	elif expressed>.42 and pattern<.39:
		style="goatee"
	elif expressed>.48 and length>.38:
		style="full" if pattern>.53 else "short"
	elif expressed>.34 and sideburn>.68:
		style="sideburns"
	return {"style":style,"density":expressed,
		"length":length,"pattern":pattern,"mustache":mustache,
		"sideburns":sideburn}

static func hair_profile(g: Dictionary,sex: String,person_id: String="") -> Dictionary:
	# A grooming preference is not a sex allele, but historical townsfolk
	# can adopt culturally distinct styling without changing their DNA.
	var length: float=value(g,"hair_length")
	var style_gene: float=value(g,"hair_style")
	var part: float=value(g,"hair_parting")
	var curl: float=value(g,"hair_curl")
	var full: float=value(g,"hair_volume")
	var long_hair: bool=(sex=="female" and length>.15) or (
		sex=="male" and length>.82)
	var style: String="crop"
	if long_hair:
		style="braids" if style_gene>.74 else (
			"bun" if style_gene>.52 else (
			"wave" if curl>.51 else "loose"))
	elif length>.48:
		style="swept" if style_gene<.50 else "shaggy"
	elif curl>.54:
		style="curly_crop"
	# A household can choose a practical hairstyle; not a hereditary role.
	if person_id=="ida": style="bun"
	if person_id=="juno": style="ponytail"
	if person_id=="mara": style="braids"
	if person_id=="sela": style="wave"
	if person_id=="lena": style="loose"
	if person_id=="orin": style="curly_crop"
	if person_id=="titus": style="swept"
	if person_id=="daro": style="shaggy"
	return {"style":style,"length":length,"curl":curl,
		"part":part,"volume":full}

static func child(a: Dictionary,b: Dictionary,child_id: String,salt: int=1938) -> Dictionary:
	if not validate(a) or not validate(b): return {}
	var rng:=_seeded(child_id,salt+71)
	var next: Dictionary={}
	for locus in TRAITS:
		var one: Array=a["alleles"][locus]
		var two: Array=b["alleles"][locus]
		# A rare minor mutation is enough for siblings to differ. Most
		# differences simply arise from independently chosen parental alleles.
		var paternal: int=int(one[rng.randi_range(0,1)])
		var maternal: int=int(two[rng.randi_range(0,1)])
		if rng.randf()<.035: paternal=clampi(paternal+rng.randi_range(-45,45),0,CAP)
		if rng.randf()<.035: maternal=clampi(maternal+rng.randi_range(-45,45),0,CAP)
		next[locus]=[paternal,maternal]
	return {"version":VERSION,"alleles":next}

static func founder_family(person_id: String,birthday: int=0) -> Dictionary:
	return {"parents":[],"children":[],"ancestors":[],
		"founder_ids":[person_id],"generation":0,
		"birth_day":birthday,"death_day":-1}

static func descendant_family(child_id: String,parent_a_id: String,
		parent_b_id: String,parents: Dictionary,birthday: int) -> Dictionary:
	if child_id in [parent_a_id,parent_b_id] or parent_a_id==parent_b_id:
		return {}
	if not parents.has(parent_a_id) or not parents.has(parent_b_id): return {}
	var parent_a: Dictionary=parents[parent_a_id]
	var parent_b: Dictionary=parents[parent_b_id]
	var known: Array=[]
	var founding: Array=[]
	for source in [parent_a,parent_b]:
		var family: Dictionary=source.get("family",{})
		if not (family is Dictionary): return {}
		for ancestor in family.get("ancestors",[]):
			if not known.has(ancestor): known.append(ancestor)
		if not known.has(source["id"]): known.append(source["id"])
		for founder_id in family.get("founder_ids",[source["id"]]):
			if not founding.has(founder_id): founding.append(founder_id)
	known.sort()
	founding.sort()
	if known.size()>MAX_ANCIENT:
		known=known.slice(known.size()-MAX_ANCIENT)
	return {"parents":[parent_a_id,parent_b_id],"children":[],
		"ancestors":known,"founder_ids":founding,
		"generation":maxi(int(parent_a["family"].get("generation",0)),
			int(parent_b["family"].get("generation",0)))+1,
		"birth_day":birthday,"death_day":-1}

static func validate_family(f: Variant,person_id: String,people: Dictionary) -> bool:
	if not (f is Dictionary): return false
	for key in ["parents","children","ancestors","founder_ids"]:
		if not (f.get(key,null) is Array): return false
		var arr: Array=f[key]
		if arr.size()>MAX_ANCIENT or (key!="founder_ids" and arr.has(person_id)): return false
		for id in arr:
			if not (id is String) or id.is_empty() or not people.has(id): return false
			if arr.count(id)>1: return false
	if f["parents"].size()>2 or f["founder_ids"].is_empty(): return false
	if int(f.get("generation",-1))<0: return false
	return int(f.get("birth_day",-1))>=-100000 and int(f.get("death_day",-2))>=-1

static func skin_color(g: Dictionary) -> Color:
	# Painterly complexion gradient; heritage is not an arbitrary name/role
	# lookup and undertone varies independently of overall pigmentation.
	var t: float=value(g,"pigment")
	var warm: float=value(g,"warmth")
	var cool_end:=Color("cba98e").lerp(Color("392a2b"),pow(t,.87))
	var warm_end:=Color("e8bd99").lerp(Color("513127"),pow(t,.87))
	return cool_end.lerp(warm_end,warm)

static func hair_color(g: Dictionary) -> Color:
	var t: float=value(g,"hair_pigment")
	return Color("9e7955").lerp(Color("211b1d"),pow(t,.6))

static func eye_color(g: Dictionary) -> Color:
	return Color("728478").lerp(Color("2f2525"),value(g,"eye_pigment"))
