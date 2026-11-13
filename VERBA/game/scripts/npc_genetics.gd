extends RefCounted
## Stable, data-driven inherited morphology. Never reseeds on reload or walk state.
## Numeric traits can be blended from two parents; clothing and occupations cannot.
const FOUNDERS := {
	"mara": {"sex":"female","height":0.94,"shoulders":0.55,"waist":0.42,"hips":0.67,"face":1.03,"nose":0.83,"skin":"b09a85","hair":"352521","style":"long","outfit":"coat"},
	"tomas": {"sex":"male","height":1.07,"shoulders":0.71,"waist":0.54,"hips":0.58,"face":0.93,"nose":1.16,"skin":"9d7f69","hair":"6c6255","style":"short","beard":2,"outfit":"tunic"},
	"ida": {"sex":"female","height":0.92,"shoulders":0.55,"waist":0.46,"hips":0.72,"chest":0.17,"face":1.01,"nose":0.93,"skin":"b69b82","hair":"4c312a","style":"braid","outfit":"dress"},
	"orin": {"sex":"male","height":1.08,"shoulders":0.79,"waist":0.64,"hips":0.64,"face":1.10,"nose":1.17,"skin":"8d6c57","hair":"292524","style":"crop","beard":2,"outfit":"work"},
	"ves": {"sex":"female","height":0.98,"shoulders":0.58,"waist":0.46,"hips":0.66,"face":0.94,"nose":0.96,"skin":"a98573","hair":"363334","style":"bun","outfit":"coat"},
	"titus": {"sex":"male","height":1.13,"shoulders":0.75,"waist":0.53,"hips":0.57,"face":1.01,"nose":1.12,"skin":"997b67","hair":"332c29","style":"short","beard":1,"outfit":"jerkin"},
	"lena": {"sex":"female","height":0.91,"shoulders":0.52,"waist":0.39,"hips":0.64,"face":0.96,"nose":0.81,"skin":"bb957b","hair":"332b26","style":"long","outfit":"dress"},
	"daro": {"sex":"male","height":1.01,"shoulders":0.68,"waist":0.53,"hips":0.58,"face":1.05,"nose":1.05,"skin":"ad896b","hair":"4c3c2b","style":"messy","beard":1,"outfit":"work"},
	"nima": {"sex":"female","height":0.96,"shoulders":0.54,"waist":0.43,"hips":0.68,"face":1.06,"nose":1.03,"skin":"75564b","hair":"231c1c","style":"curly","outfit":"dress"},
	"cass": {"sex":"male","height":0.97,"shoulders":0.64,"waist":0.48,"hips":0.55,"face":0.91,"nose":0.89,"skin":"c2a18a","hair":"69584a","style":"medium","beard":1,"outfit":"coat"},
	"brin": {"sex":"male","height":1.06,"shoulders":0.76,"waist":0.60,"hips":0.61,"face":1.10,"nose":1.21,"skin":"9d7965","hair":"4e4036","style":"short","beard":2,"outfit":"work"},
	"sela": {"sex":"female","height":0.95,"shoulders":0.51,"waist":0.43,"hips":0.67,"face":0.98,"nose":0.98,"skin":"9c745e","hair":"271e20","style":"braid","outfit":"coat"},
	"juno": {"sex":"female","height":1.00,"shoulders":0.59,"waist":0.46,"hips":0.65,"face":1.02,"nose":1.09,"skin":"9c7e67","hair":"342820","style":"bob","outfit":"uniform"}
}
const INHERITED := ["height","shoulders","waist","hips","chest","face","nose","eyes","brows"]

static func profile(data: Dictionary, mother: Dictionary = {}, father: Dictionary = {}) -> Dictionary:
	var id := String(data.get("id","newcomer"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(id.hash()) + 723451
	var sex := String(data.get("sex", FOUNDERS.get(id, {}).get("sex", "female" if rng.randf()<.5 else "male")))
	var feminine := sex == "female"
	var p: Dictionary = {
		"sex": sex,
		"height":rng.randf_range(.89,1.03) if feminine else rng.randf_range(.96,1.13),
		"shoulders":rng.randf_range(.48,.61) if feminine else rng.randf_range(.63,.78),
		"waist":rng.randf_range(.38,.49) if feminine else rng.randf_range(.48,.62),
		"hips":rng.randf_range(.61,.74) if feminine else rng.randf_range(.53,.65),
		"chest":rng.randf_range(.08,.20) if feminine else rng.randf_range(.06,.14),
		"face":rng.randf_range(.90,1.10),
		"nose":rng.randf_range(.78,1.23),
		"eyes":rng.randf_range(.88,1.14),
		"brows":rng.randf_range(.80,1.25),
		"skin":"9e816c",
		"hair":"322621",
		"style":"long" if feminine else "short",
		"beard":0,
		"outfit":"dress" if feminine else "tunic"
	}
	if not mother.is_empty() and not father.is_empty():
		for key in INHERITED:
			p[key] = lerpf(float(mother.get(key,p[key])), float(father.get(key,p[key])), rng.randf_range(.30,.70)) + rng.randf_range(-.018,.018)
		var mom_color := Color(String(mother.get("skin", p["skin"])))
		var dad_color := Color(String(father.get("skin", p["skin"])))
		p["skin"] = mom_color.lerp(dad_color,rng.randf_range(.3,.7)).to_html(false)
		var mom_hair := Color(String(mother.get("hair",p["hair"])))
		var dad_hair := Color(String(father.get("hair",p["hair"])))
		p["hair"] = mom_hair.lerp(dad_hair,rng.randf_range(.3,.7)).to_html(false)
		p["style"] = String(mother.get("style",p["style"])) if rng.randf()<.5 else String(father.get("style",p["style"]))
		p["beard"] = int(mother.get("beard",0)) if rng.randf()<.5 else int(father.get("beard",0))
	var founder: Dictionary = FOUNDERS.get(id,{})
	for key in founder.keys():
		p[key] = founder[key]
	# Save data can override founders for descendants, appearance edits and migrations.
	for key in (data.get("genes",{}) as Dictionary).keys():
		p[key] = data["genes"][key]
	p["height"] = clampf(float(p["height"]),.77,1.24)
	p["shoulders"] = clampf(float(p["shoulders"]),.43,.87)
	p["waist"] = clampf(float(p["waist"]),.34,.70)
	p["hips"] = clampf(float(p["hips"]),.47,.84)
	p["beard"] = clampi(int(p["beard"]),0,3)
	return p
