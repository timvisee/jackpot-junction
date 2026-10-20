// The Arcade's lamps, GAME.md 8.1c: the light of a playfield's inserts as play lights them, laid a
// hair over their printed selves and added to the floor, so the print is the dark plastic and this
// is the bulb under it. Every lamp is an instance of one MultiMesh, a flat square, and the insert's
// shape is drawn in it here: a ring round a coin pad, a disc under an item pad, a chevron down a
// turbo lane and an arrow pointing a Jackpot out, each with the soft light it throws on the coat
// round it. The instance's custom data says which shape it is, how lit, its flash, and its place
// in a chase; its color is its light, and for a chevron how far across its lane it reaches. The
// chase runs here from the clock, so nothing is written per frame. See PinballLamps.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

// The shapes, in cells, as PinballInserts prints them: a coin ring's inner and outer radius, an
// item disc's radius, a chevron's length along its lane and its arms' thickness, and an arrow's
// length, its head's length and half width and its shaft's half width.
uniform vec2 coin_ring = vec2(0.4, 0.47);
uniform float item_disc = 0.62;
uniform vec2 chevron = vec2(0.44, 0.17);
uniform vec4 arrow = vec4(1.8, 0.63, 0.45, 0.2);
// Half each kind's square, along and across, in cells: the shape and the light round it.
uniform vec2 coin_square = vec2(1.1);
uniform vec2 item_square = vec2(1.25);
uniform vec2 chevron_square = vec2(0.95);
uniform vec2 arrow_square = vec2(1.6, 1.0);
// How far the light a lit insert throws reaches past its edge, in cells, and how strong it is
// beside it, by kind: coin, item, chevron, arrow.
uniform vec4 halo_reach = vec4(0.6, 0.6, 0.6, 0.8);
uniform vec4 halo_strength = vec4(0.3, 0.22, 0.22, 0.16);
// How strong the lamps are, all told, and how much a lamp's flash adds as it lights.
uniform float energy = 1.0;
uniform float flash_gain = 1.2;
// A chase: steps a second, the lamps in a run and the rest after them, how many lamps behind its
// head are still lit, fading, and how lit the rest of the run stays.
uniform float chase_rate = 2.0;
uniform float chase_steps = 4.0;
uniform float chase_tail = 1.4;
uniform float chase_floor = 0.3;
// Run out down the lane as a kart rides the plate: how much brighter, and how many lamps a second.
uniform float launch_gain = 1.6;
// A full Jackpot's arrow: pulses a second, and how far it swings.
uniform float pulse_rate = 0.8;
uniform float pulse_swing = 0.45;
// For a player who asked for fewer flashes, GAME.md 8.5: lamps steady, no flash, no chase.
uniform float steady = 0.0;
// The room's fog, which the floor under the lamps is in too.
uniform float fog_density = 0.0;

varying vec2 local;
varying flat vec4 state;
varying flat vec4 light;

const int COIN = 0;
const int ITEM = 1;
const int CHEVRON = 2;
const int ARROW = 3;

vec2 square(int kind) {
	if (kind == COIN) {
		return coin_square;
	} else if (kind == ITEM) {
		return item_square;
	} else if (kind == CHEVRON) {
		return chevron_square;
	}
	return arrow_square;
}

void vertex() {
	state = INSTANCE_CUSTOM;
	light = COLOR;
	local = VERTEX.xz * 2.0 * square(int(INSTANCE_CUSTOM.r + 0.5));
}

// How far a point is outside a chevron pointing along x, its tip half its length ahead of its
// middle and its arms reaching [param reach] to either side; less than nothing inside it.
float chevron_edge(vec2 at, float reach) {
	vec2 folded = vec2(at.x, abs(at.y));
	float tip = chevron.x * 0.5;
	vec2 out_of = normalize(vec2(reach, chevron.x));
	float ahead = dot(folded - vec2(tip, 0.0), out_of);
	float behind = dot(folded - vec2(tip - chevron.y, 0.0), out_of);
	return max(max(ahead, -behind), folded.y - reach);
}

// How far a point is outside an arrow pointing along x, centered on its middle.
float arrow_edge(vec2 at) {
	vec2 folded = vec2(at.x, abs(at.y));
	float tip = arrow.x * 0.5;
	float neck = tip - arrow.y;
	vec2 side = normalize(vec2(arrow.z, arrow.y));
	float head = max(dot(folded - vec2(tip, 0.0), side), neck - folded.x);
	vec2 shaft = abs(vec2(folded.x - (neck - tip) * 0.5, folded.y))
		- vec2((neck + tip) * 0.5, arrow.w);
	float stick = length(max(shaft, 0.0)) + min(max(shaft.x, shaft.y), 0.0);
	return min(head, stick);
}

// How lit a chevron [param place] lamps from its plate is: the chase running out down the lane,
// or held steady brightest by the plate; and with [param launch], 1 as a kart rides the plate and
// down to 0, a quick run of light out down it.
float chevron_lit(float place, float launch) {
	if (steady > 0.5) {
		float held = mix(0.85, 0.4, place / 2.0);
		return held * (1.0 + 0.6 * sin(3.14159 * launch));
	}
	float head = mod(TIME * chase_rate, chase_steps);
	float behind = mod(head - place, chase_steps);
	float lit = mix(chase_floor, 1.0, pow(clamp(1.0 - behind / chase_tail, 0.0, 1.0), 1.5));
	if (launch > 0.0) {
		float run = (1.0 - launch) * (2.0 + chase_tail) - place;
		float out_of = run < 0.0 ? 0.0 : clamp(1.0 - run / chase_tail, 0.0, 1.0);
		lit = max(lit, out_of * launch_gain);
	}
	return lit;
}

void fragment() {
	int kind = int(state.r + 0.5);
	float edge;
	float reach;
	float strength;
	if (kind == COIN) {
		edge = abs(length(local) - (coin_ring.x + coin_ring.y) * 0.5)
			- (coin_ring.y - coin_ring.x) * 0.5;
		reach = halo_reach.x;
		strength = halo_strength.x;
	} else if (kind == ITEM) {
		edge = length(local) - item_disc;
		reach = halo_reach.y;
		strength = halo_strength.y;
	} else if (kind == CHEVRON) {
		edge = chevron_edge(local, light.a);
		reach = halo_reach.z;
		strength = halo_strength.z;
	} else {
		edge = arrow_edge(local);
		reach = halo_reach.w;
		strength = halo_strength.w;
	}
	float soft = max(fwidth(edge), 0.0001);
	float face = clamp(0.5 - edge / soft, 0.0, 1.0);
	float halo = pow(clamp(1.0 - max(edge, 0.0) / reach, 0.0, 1.0), 2.0);
	float lit = state.g;
	if (kind == CHEVRON) {
		lit *= chevron_lit(state.a, state.b);
	} else if (kind == ARROW) {
		float swing = steady > 0.5 ? 0.5 : 0.5 + 0.5 * sin(TIME * pulse_rate * 6.28318);
		lit *= 1.0 + state.b * pulse_swing * swing;
	} else if (steady < 0.5) {
		lit *= 1.0 + state.b * flash_gain;
	}
	float fogged = exp(-length(VERTEX) * fog_density);
	ALBEDO = light.rgb * lit * energy * (face + halo * strength) * fogged;
}
