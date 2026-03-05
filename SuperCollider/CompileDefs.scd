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

SynthDef(\ui_click, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, bright=0.6, send=0.03, fxBus=2|
    var env, freq, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0008, 0.03, 1.0, curve: -6), gate, doneAction:2);
    freq = (1200 + (bright.clip(0, 1) * 2600) + (z.clip2(1) * 120)).clip(600, 5000);
    sig = SinOsc.ar(freq, 0, 0.75) + BPF.ar(WhiteNoise.ar(0.06), freq * 1.2, 0.2);
    sig = HPF.ar(sig, 350) * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\laser_zap, { |out=0, amp=0.3, gate=1, seed=0,
    x=0, y=0, z=0, rate=0.5, bright=0.8, send=0.08, fxBus=2|
    var env, fEnv, freq, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.16, 1.0, curve: -5), gate, doneAction:2);
    fEnv = EnvGen.kr(Env([1.0, 0.2], [0.12], curve: -4), gate);
    freq = (500 + (rate.clip(0, 1) * 2200)) * fEnv;
    sig = LFTri.ar(freq, 0, 0.7) + Pulse.ar(freq * 1.99, 0.35, 0.25 * bright);
    sig = BPF.ar(sig, (freq * (1.5 + bright)).clip(500, 7000), 0.25);
    sig = Pan2.ar((sig * env * amp).tanh, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\explosion, { |out=0, amp=0.7, gate=1, seed=0,
    x=0, y=0, z=0, force=0.8, bright=0.35, send=0.28, fxBus=2|
    var env, low, rumble, blast, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.003, 0.9 + (force * 0.8), 1.0, curve: -4), gate, doneAction:2);
    low = SinOsc.ar((45 + (force * 90)).clip(35, 180), 0, 0.9);
    rumble = LPF.ar(BrownNoise.ar(0.8), (120 + (force * 260)).clip(80, 450));
    blast = BPF.ar(WhiteNoise.ar(0.45), (600 + (bright * 2800)).clip(350, 4800), 0.35);
    sig = (low + rumble + blast) * env;
    sig = Pan2.ar(CompanderD.ar(sig * amp, 0.7, 1.0, 0.35), x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\pickup_chime, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, pitch=0.55, bright=0.75, send=0.12, fxBus=2|
    var env, base, tones, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.002, 0.45, 1.0, curve: -4), gate, doneAction:2);
    base = (420 + (pitch.clip(0, 1) * 720)).clip(300, 1300);
    tones = SinOsc.ar(base, 0, 0.5)
          + SinOsc.ar(base * 1.5, 0, 0.3)
          + SinOsc.ar(base * 2.0, 0, 0.2 * bright);
    sig = HPF.ar(tones * env, 250);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\whoosh, { |out=0, amp=0.28, gate=1, seed=0,
    x=0, y=0, z=0, speed=0.55, bright=0.6, send=0.2, fxBus=2|
    var env, rise, noise, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.01, 0.5, 1.0, curve: -3), gate, doneAction:2);
    rise = XLine.kr(250 + (speed * 400), 1600 + (speed * 2400), 0.45);
    noise = WhiteNoise.ar(1);
    sig = BPF.ar(noise, rise, 0.18 + (0.1 * bright)) * env;
    sig = HPF.ar(sig, 80);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\engine_idle, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, rpm=0.35, rough=0.3, send=0.16, fxBus=2|
    var env, f, hum, buzz, knock, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.08, 1.0, 0.2), gate, doneAction:2);
    f = (28 + (rpm.clip(0, 1) * 140)).clip(20, 220);
    hum = SinOsc.ar(f, 0, 0.6) + SinOsc.ar(f * 2, 0, 0.25);
    buzz = BPF.ar(PinkNoise.ar(0.3 + (rough * 0.35)), (f * 9).clip(150, 3000), 0.22);
    knock = Decay2.ar(Impulse.ar((f * 0.5).clip(4, 80)), 0.002, 0.03) * BrownNoise.ar(0.2);
    sig = LPF.ar((hum + buzz + knock) * env, 3800);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\rain_loop, { |out=0, amp=0.18, gate=1, seed=0,
    x=0, y=0, z=0, density=0.45, bright=0.35, send=0.22, fxBus=2|
    var env, rain, drops, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.15, 1.0, 0.25), gate, doneAction:2);
    rain = PinkNoise.ar(0.7);
    rain = HPF.ar(rain, 350 + (bright * 1200));
    drops = Decay2.ar(Dust2.ar((30 + (density * 130)).clip(10, 260)), 0.001, 0.02)
        * BPF.ar(WhiteNoise.ar(0.5), 1200 + TRand.kr(0, 2800, Dust2.kr(20)), 0.2);
    sig = (rain * 0.25) + (drops * 0.5);
    sig = Pan2.ar(sig * amp * env, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\alarm_loop, { |out=0, amp=0.24, gate=1, seed=0,
    x=0, y=0, z=0, rate=2.0, bright=0.7, send=0.12, fxBus=2|
    var env, toneEnv, f1, f2, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.02, 1.0, 0.08), gate, doneAction:2);
    toneEnv = LFPulse.kr(rate.clip(0.3, 8.0), 0, 0.5).lag(0.02);
    f1 = 620 + (bright * 420);
    f2 = 930 + (bright * 610);
    sig = SelectX.ar(toneEnv, [Saw.ar(f1, 0.35), Saw.ar(f2, 0.35)]);
    sig = HPF.ar(sig, 200);
    sig = Pan2.ar(sig * amp * env, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

"Wrote SynthDefs to: ".post; defsDir.postln;
)
