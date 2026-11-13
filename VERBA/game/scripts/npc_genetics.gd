extends RefCounted
## Compact, fictional polygenic appearance model. Two alleles per locus are
## persisted, one transmitted from each parent; no locus encodes ethnicity,
## morality, intelligence, sex, social role or an individual's choices.
const VERSION: int=2
# Version 2 extends the physique and facial-control genome without changing
# any of the original 28 loci or their transmitted parental alleles.
const EXTRA_MORPH_TRAITS: Array[String]=[
	"chest_width","bust_volume","waist_width","hip_width",
	"muscle_tone","eye_aperture","nostril_width","lip_curve"
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
	"muscle_tone","eye_aperture","nostril_width","lip_curve"
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
	# Persisted v1 founders and their children keep EVERY historical allele.
	# Only the new morphological loci are deterministically populated. Old
	# relationships, life stages, careers and anatomy do not change.
	if validate(g): return normalize(g)
	if not (g is Dictionary) or int(g.get("version",0))!=1:
		return {}
	var source: Variant=g.get("alleles",{})
	if not (source is Dictionary): return {}
	if source.size()!=TRAITS.size()-EXTRA_MORPH_TRAITS.size(): return {}
	for locus in TRAITS:
		if locus in EXTRA_MORPH_TRAITS: continue
		if not source.has(locus) or not (source[locus] is Array):
			return {}
		if source[locus].size()!=2: return {}
		for allele in source[locus]:
			if not (allele is int or allele is float): return {}
			if int(allele)<0 or int(allele)>CAP or float(allele)!=float(int(allele)):
				return {}
	var result: Dictionary={"version":VERSION,"alleles":{}}
	var baseline: Dictionary=founder(person_id,salt)
	for locus in TRAITS:
		var pair: Array=source[locus] if source.has(locus) else baseline["alleles"][locus]
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
	var height_gene: float=value(g,"stature")
	var shoulders: float=value(g,"shoulder_width")
	var depth: float=value(g,"body_depth")
	var female: bool=sex=="female"
	var height: float=(.82+.34*height_gene) if female else (.90+.30*height_gene)
	var breadth: float=lerpf(.87,1.20,shoulders)
	if female:
		# Broad-shouldered women retain their width; fine-boned women
		# average narrower, without overriding their transmitted genes.
		breadth*=lerpf(.945,1.012,shoulders)
	var thickness: float=lerpf(.86,1.16,depth)
	if female:
		thickness*=lerpf(.955,1.01,depth)
	return Vector3(breadth,height,thickness)

static func forearm_length(g: Dictionary) -> float:
	# Use the inherited limb_ratio locus instead of arbitrary per-role
	# or per-sex limb lengths. Stature is handled by body_scale's Y.
	return lerpf(.375,.525,value(g,"limb_ratio"))

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
