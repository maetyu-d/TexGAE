/*
    Run with sclang to write .scsyndef files used by JUCE /d_loadDir.
    Example:
    sclang SuperCollider/CompileDefs.scd
*/

(
var defsDir = "GAE_DEFS_DIR".getenv;
if(defsDir.isNil) { defsDir = PathName(thisProcess.nowExecutingPath).pathOnly ++ "defs"; };

File.mkdir(defsDir);

SynthDef(\proc_hit, { |out=0, amp=0.5, gate=1, seed=0,
    x=0, y=0, z=0, bright=0.7, size=0.5, damp=0.3, send=0.15, fxBus=2|
    var env, tone, noise, sig, freq, noiseAmt, toneAmt;

    RandSeed.ir(seed);

    env = EnvGen.kr(Env.perc(0.001, 0.14, 1.0, curve: -4), gate, doneAction:2);
    freq = (180 + (z.clip2(1) * 120) + (size * 100)).clip(80, 1200);
    toneAmt = (0.45 + (0.45 * bright)).clip(0, 1);
    noiseAmt = (0.02 + (0.10 * (1 - damp))).clip(0, 0.18);
    tone = SinOsc.ar(freq, 0, toneAmt);
    noise = BPF.ar(PinkNoise.ar(noiseAmt), (freq * 2.2).clip(200, 4000), 0.5);
    sig = LPF.ar(tone + noise, (1500 + (bright * 3000)).clip(500, 6000)) * amp * env;
    sig = Pan2.ar(sig, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\footstep, { |out=0, amp=0.4, gate=1, seed=0,
    x=0, y=0, z=0, hardness=0.5, damp=0.4, send=0.12, fxBus=2|
    var env, body, click, sig, freq;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.002, 0.18, 1.0, curve: -5), gate, doneAction:2);
    freq = (90 + (hardness * 130) + (z.clip2(1) * 40)).clip(50, 350);
    body = SinOsc.ar(freq, 0, 0.7) * env;
    click = BPF.ar(WhiteNoise.ar(0.08 * hardness), 1800 + (hardness * 2200), 0.4) * env;
    sig = LPF.ar(body + click, (1400 + ((1 - damp) * 2600)).clip(400, 5000));
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\impact, { |out=0, amp=0.6, gate=1, seed=0,
    x=0, y=0, z=0, force=0.8, metal=0.4, damp=0.3, send=0.2, fxBus=2|
    var env, low, ring, noise, sig, f0;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.35 + (force * 0.25), 1.0, curve: -6), gate, doneAction:2);
    f0 = (70 + (force * 120) + (z.clip2(1) * 45)).clip(40, 280);
    low = SinOsc.ar(f0, 0, 0.75) * env;
    ring = Ringz.ar(Impulse.ar(0), 500 + (metal * 3500), 0.08 + (metal * 0.25)) * 0.5;
    noise = BPF.ar(PinkNoise.ar(0.12), 900 + (metal * 2800), 0.35) * env;
    sig = tanh((low + ring + noise) * (0.9 + force));
    sig = LPF.ar(sig, (1800 + ((1 - damp) * 4500)).clip(600, 7000));
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\ui_blip, { |out=0, amp=0.25, gate=1, seed=0,
    x=0, y=0, z=0, pitch=0.5, bright=0.7, send=0.05, fxBus=2|
    var env, freq, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.08, 1.0, curve: -4), gate, doneAction:2);
    freq = (500 + (pitch.clip(0, 1) * 1800) + (z.clip2(1) * 180)).clip(250, 3200);
    sig = SinOsc.ar(freq, 0, 0.7) + (LFTri.ar(freq * 2, 0, 0.15 * bright));
    sig = HPF.ar(sig * env, 300);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\wind_loop, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, speed=0.35, bright=0.45, damp=0.35, send=0.25, fxBus=2|
    var env, mod, noise, sig, cf;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.2, 1.0, 0.35), gate, doneAction:2);
    mod = LFNoise2.kr((0.15 + (speed * 1.2)).clip(0.05, 2.0)).range(0.7, 1.3);
    cf = (400 + (bright * 2400) + (z.clip2(1) * 350)).clip(150, 4500) * mod;
    noise = PinkNoise.ar(1);
    sig = BPF.ar(noise, cf, 0.22 + (0.25 * (1 - damp)));
    sig = HPF.ar(sig, 60 + (speed * 120));
    sig = Pan2.ar(sig * amp * env, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\ambience_grain, { |out=0, amp=0.18, gate=1, seed=0,
    x=0, y=0, z=0, density=0.35, spread=0.5, tone=0.45, send=0.25, fxBus=2|
    var env, trig, freq, grain, sig, jitterPan;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.25, 1.0, 0.35), gate, doneAction:2);
    trig = Dust.kr((1 + (density.clip(0, 1) * 20)).clip(0.2, 25));
    freq = TExpRand.kr(180, 1800 + (tone * 2600), trig);
    grain = SinOsc.ar(freq, 0, Decay2.kr(trig, 0.003, 0.08));
    sig = LPF.ar(grain, (1200 + (tone * 3600)).clip(500, 6000));
    jitterPan = (LFNoise1.kr(0.3).range(0.0, 1.0) * (spread * 2.0)) - spread;
    sig = Pan2.ar(sig * amp * env, (x + jitterPan).clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\music_pulse, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, freq=220, rate=2.0, tone=0.5, send=0.18, fxBus=2|
    var env, pulse, base, sig, cut;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.05, 1.0, 0.2), gate, doneAction:2);
    pulse = Decay2.kr(Impulse.kr(rate.clip(0.2, 12.0)), 0.002, 0.09);
    base = Saw.ar(freq.clip(60, 1200), 0.35) + Pulse.ar(freq.clip(60, 1200) * 0.5, 0.45, 0.2);
    cut = (700 + (tone.clip(0, 1) * 4500) + (z.clip2(1) * 200)).clip(250, 7000);
    sig = LPF.ar(base * pulse, cut);
    sig = Pan2.ar(sig * amp * env, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

"Wrote SynthDefs to: ".post; defsDir.postln;
)
