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

SynthDef(\gunshot, { |out=0, amp=0.75, gate=1, seed=0,
    x=0, y=0, z=0, punch=0.8, bright=0.65, send=0.18, fxBus=2|
    var env, pop, crack, tail, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0005, 0.22, 1.0, curve: -7), gate, doneAction:2);
    pop = SinOsc.ar((90 + (punch * 140)).clip(60, 260), 0, 0.95) * EnvGen.kr(Env.perc(0.0004, 0.03), gate);
    crack = HPF.ar(WhiteNoise.ar(0.9), 1200 + (bright * 3200)) * EnvGen.kr(Env.perc(0.0002, 0.025), gate);
    tail = BPF.ar(PinkNoise.ar(0.45), 900 + (bright * 2500), 0.25) * EnvGen.kr(Env.perc(0.003, 0.15), gate);
    sig = (pop + crack + tail).tanh * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\jump_blip, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, pitch=0.55, send=0.07, fxBus=2|
    var env, fEnv, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.12, 1.0, curve: -5), gate, doneAction:2);
    fEnv = EnvGen.kr(Env([0.7, 1.3], [0.09], curve: 3), gate);
    sig = LFTri.ar((280 + (pitch.clip(0, 1) * 700)) * fEnv, 0, 0.7);
    sig = HPF.ar(sig * env, 180);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\coin_pickup, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, pitch=0.6, bright=0.85, send=0.12, fxBus=2|
    var env, base, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.28, 1.0, curve: -4), gate, doneAction:2);
    base = (680 + (pitch.clip(0, 1) * 1100)).clip(450, 2200);
    sig = SinOsc.ar(base, 0, 0.55)
        + SinOsc.ar(base * 1.49, 0, 0.32)
        + SinOsc.ar(base * 2.02, 0, 0.18 * bright);
    sig = HPF.ar(sig * env, 350);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\error_buzz, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, harsh=0.65, send=0.05, fxBus=2|
    var env, f, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.2, 1.0, curve: -3), gate, doneAction:2);
    f = 140 + (harsh.clip(0, 1) * 220);
    sig = LFPulse.ar(f, 0, 0.42, 0.5) + LFSaw.ar(f * 0.5, 0, 0.35);
    sig = LPF.ar(sig, 900 + (harsh * 1700));
    sig = Pan2.ar((sig * env * amp).tanh, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\powerup_swirl, { |out=0, amp=0.24, gate=1, seed=0,
    x=0, y=0, z=0, rise=0.7, bright=0.75, send=0.18, fxBus=2|
    var env, f, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.01, 0.7, 1.0, curve: -3), gate, doneAction:2);
    f = XLine.kr(240 + (rise * 120), 1300 + (rise * 2100), 0.62);
    sig = SinOsc.ar(f, 0, 0.5) + LFTri.ar(f * 1.5, 0, 0.32 * bright);
    sig = BPF.ar(sig, (f * 1.2).clip(300, 6000), 0.25);
    sig = Pan2.ar(sig * env * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\door_thud, { |out=0, amp=0.5, gate=1, seed=0,
    x=0, y=0, z=0, weight=0.7, damp=0.35, send=0.16, fxBus=2|
    var env, low, wood, sig, f;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.35, 1.0, curve: -5), gate, doneAction:2);
    f = (70 + (weight.clip(0, 1) * 130)).clip(45, 260);
    low = SinOsc.ar(f, 0, 0.8) * env;
    wood = BPF.ar(BrownNoise.ar(0.5), 250 + (weight * 700), 0.3) * env;
    sig = LPF.ar((low + wood).tanh, (900 + ((1 - damp.clip(0, 1)) * 2600)).clip(500, 4500));
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\thunder_rumble, { |out=0, amp=0.35, gate=1, seed=0,
    x=0, y=0, z=0, depth=0.7, send=0.35, fxBus=2|
    var env, low, mid, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.02, 2.0, 1.0, curve: -2), gate, doneAction:2);
    low = LPF.ar(BrownNoise.ar(0.9), 90 + (depth.clip(0, 1) * 140));
    mid = BPF.ar(PinkNoise.ar(0.35), 220 + (depth * 380), 0.25);
    sig = (low + mid) * env;
    sig = Pan2.ar(CompanderD.ar(sig * amp, 0.7, 1.0, 0.45), x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\magic_cast, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, tone=0.6, sparkle=0.8, send=0.2, fxBus=2|
    var env, f, body, spark, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.004, 0.55, 1.0, curve: -3), gate, doneAction:2);
    f = 320 + (tone.clip(0, 1) * 900);
    body = SinOsc.ar(f, 0, 0.5) + SinOsc.ar(f * 1.33, 0, 0.25);
    spark = HPF.ar(WhiteNoise.ar(0.25 * sparkle), 2000 + (sparkle * 3000)) * EnvGen.kr(Env.perc(0.001, 0.2), gate);
    sig = BPF.ar(body + spark, (f * 2.1).clip(700, 5000), 0.35) * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\rifle_shot, { |out=0, amp=0.75, gate=1, seed=0,
    x=0, y=0, z=0, snap=0.85, tail=0.45, send=0.2, fxBus=2|
    var env, thump, crack, air, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0003, 0.2, 1.0, curve: -8), gate, doneAction:2);
    thump = SinOsc.ar(95 + (tail * 90), 0, 0.7) * EnvGen.kr(Env.perc(0.0004, 0.025), gate);
    crack = HPF.ar(WhiteNoise.ar(1.0), 1800 + (snap * 4200)) * EnvGen.kr(Env.perc(0.0002, 0.016), gate);
    air = BPF.ar(PinkNoise.ar(0.35), 1200 + (snap * 3000), 0.2) * EnvGen.kr(Env.perc(0.002, 0.11), gate);
    sig = (thump + crack + air).tanh * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\shotgun_blast, { |out=0, amp=0.85, gate=1, seed=0,
    x=0, y=0, z=0, body=0.8, scatter=0.7, send=0.24, fxBus=2|
    var env, boom, pellets, burst, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0005, 0.32, 1.0, curve: -7), gate, doneAction:2);
    boom = SinOsc.ar(70 + (body * 85), 0, 0.85) * EnvGen.kr(Env.perc(0.0005, 0.06), gate);
    pellets = HPF.ar(WhiteNoise.ar(0.95), 1400 + (scatter * 2600)) * EnvGen.kr(Env.perc(0.0003, 0.03), gate);
    burst = BPF.ar(PinkNoise.ar(0.5), 700 + (scatter * 2200), 0.25) * EnvGen.kr(Env.perc(0.002, 0.2), gate);
    sig = (boom + pellets + burst).tanh * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\smg_burst, { |out=0, amp=0.55, gate=1, seed=0,
    x=0, y=0, z=0, rate=12, snap=0.75, send=0.14, fxBus=2|
    var env, trig, body, crack, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.26, 1.0, curve: -5), gate, doneAction:2);
    trig = Impulse.ar(rate.clip(4, 24));
    body = Decay2.ar(trig, 0.0004, 0.015) * SinOsc.ar(130, 0, 0.5);
    crack = Decay2.ar(trig, 0.0001, 0.008) * HPF.ar(WhiteNoise.ar(0.7), 2200 + (snap * 2600));
    sig = (body + crack) * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\ricochet_ping, { |out=0, amp=0.35, gate=1, seed=0,
    x=0, y=0, z=0, pitch=0.7, ring=0.6, send=0.16, fxBus=2|
    var env, f, excite, ringz, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0004, 0.24, 1.0, curve: -5), gate, doneAction:2);
    f = (1200 + (pitch.clip(0, 1) * 3200)).clip(900, 5200);
    excite = HPF.ar(WhiteNoise.ar(0.8), 2500) * EnvGen.kr(Env.perc(0.0002, 0.01), gate);
    ringz = Ringz.ar(excite, f, 0.08 + (ring * 0.35));
    sig = BPF.ar(ringz, f, 0.25) * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\sword_clash, { |out=0, amp=0.45, gate=1, seed=0,
    x=0, y=0, z=0, metal=0.75, force=0.65, send=0.18, fxBus=2|
    var env, hit, ring, scrape, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0007, 0.35, 1.0, curve: -5), gate, doneAction:2);
    hit = SinOsc.ar(180 + (force * 160), 0, 0.35) * EnvGen.kr(Env.perc(0.0008, 0.05), gate);
    ring = Ringz.ar(HPF.ar(WhiteNoise.ar(0.8), 1600), 1600 + (metal * 2800), 0.1 + (metal * 0.25));
    scrape = BPF.ar(PinkNoise.ar(0.4), 900 + (metal * 2300), 0.22) * EnvGen.kr(Env.perc(0.002, 0.18), gate);
    sig = (hit + ring + scrape).tanh * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\bow_release, { |out=0, amp=0.3, gate=1, seed=0,
    x=0, y=0, z=0, tension=0.65, snap=0.7, send=0.1, fxBus=2|
    var env, twang, whip, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0006, 0.22, 1.0, curve: -4), gate, doneAction:2);
    twang = Pluck.ar(WhiteNoise.ar(0.35), Impulse.ar(0), 0.05, (0.012 - (tension * 0.006)).clip(0.004, 0.02), 0.18, 0.35);
    whip = HPF.ar(WhiteNoise.ar(0.6), 1800 + (snap * 2000)) * EnvGen.kr(Env.perc(0.0002, 0.018), gate);
    sig = LPF.ar((twang + whip) * env, 4500);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\reload_click, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, tight=0.7, bright=0.7, send=0.05, fxBus=2|
    var env, clack, tick, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.0005, 0.11, 1.0, curve: -5), gate, doneAction:2);
    clack = BPF.ar(WhiteNoise.ar(0.5), 700 + (tight * 1600), 0.2) * EnvGen.kr(Env.perc(0.0008, 0.04), gate);
    tick = HPF.ar(WhiteNoise.ar(0.5), 2300 + (bright * 2200)) * EnvGen.kr(Env.perc(0.0002, 0.01), gate);
    sig = (clack + tick) * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\rocket_launcher_blast, { |out=0, amp=0.95, gate=1, seed=0,
    x=0, y=0, z=0, force=0.9, bright=0.45, send=0.35, fxBus=2|
    var env, lowBoom, pressure, crack, tail, sig;

    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 1.3 + (force * 0.8), 1.0, curve: -4), gate, doneAction:2);
    lowBoom = SinOsc.ar((42 + (force * 70)).clip(30, 140), 0, 1.0) * EnvGen.kr(Env.perc(0.001, 0.16), gate);
    pressure = LPF.ar(BrownNoise.ar(0.9), (140 + (force * 220)).clip(90, 500));
    crack = HPF.ar(WhiteNoise.ar(0.8), 1200 + (bright * 2800)) * EnvGen.kr(Env.perc(0.0003, 0.028), gate);
    tail = BPF.ar(PinkNoise.ar(0.5), 500 + (bright * 1700), 0.24) * EnvGen.kr(Env.perc(0.004, 0.65), gate);
    sig = (lowBoom + pressure + crack + tail) * env;
    sig = CompanderD.ar(sig, 0.7, 1.0, 0.35);
    sig = Pan2.ar(sig * amp, x.clip2(1));

    Out.ar(out, sig);
    Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\pedestrians_loop, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, pace=0.45, send=0.14, fxBus=2|
    var env, trig, step, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.08, 1.0, 0.18), gate, doneAction:2);
    trig = Impulse.kr((1.2 + (pace.clip(0, 1) * 2.8)).clip(0.6, 5.0));
    step = Decay2.kr(trig, 0.002, 0.12) * (SinOsc.ar(90 + TRand.kr(0, 70, trig), 0, 0.7) + BPF.ar(PinkNoise.ar(0.25), 900, 0.4));
    sig = Pan2.ar((step * amp * env).tanh, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\phone_tone, { |out=0, amp=0.12, gate=1, seed=0,
    x=0, y=0, z=0, tone=0.5, send=0.03, fxBus=2|
    var env, f1, f2, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.01, 1.0, 0.05), gate, doneAction:2);
    f1 = 350 + (tone.clip(0, 1) * 30); f2 = 440 + (tone.clip(0, 1) * 40);
    sig = SinOsc.ar(f1, 0, 0.55) + SinOsc.ar(f2, 0, 0.55);
    sig = Pan2.ar(sig * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\dtmf_tone, { |out=0, amp=0.14, gate=1, seed=0,
    x=0, y=0, z=0, row=0.0, col=0.0, send=0.02, fxBus=2|
    var env, rows, cols, fr, fc, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.2, 1.0, curve: -4), gate, doneAction:2);
    rows = [697, 770, 852, 941];
    cols = [1209, 1336, 1477, 1633];
    fr = Select.kr((row.clip(0, 0.999) * 4).floor, rows);
    fc = Select.kr((col.clip(0, 0.999) * 4).floor, cols);
    sig = (SinOsc.ar(fr, 0, 0.55) + SinOsc.ar(fc, 0, 0.55)) * env;
    sig = Pan2.ar(sig * amp, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\siren_wail, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, rate=0.5, bright=0.6, send=0.12, fxBus=2|
    var env, mod, f, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.03, 1.0, 0.08), gate, doneAction:2);
    mod = SinOsc.kr(rate.clip(0.08, 2.5), 0).range(0, 1);
    f = 450 + (mod * 620) + (bright * 160);
    sig = Saw.ar(f, 0.35) + Pulse.ar(f * 0.5, 0.45, 0.2);
    sig = Pan2.ar(HPF.ar(sig, 120) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\telephone_bell, { |out=0, amp=0.3, gate=1, seed=0,
    x=0, y=0, z=0, ring=0.65, send=0.12, fxBus=2|
    var env, trig, hit, reson, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 1.0, 1.0, curve: -3), gate, doneAction:2);
    trig = Impulse.kr(6);
    hit = Decay2.kr(trig, 0.001, 0.03) * WhiteNoise.ar(0.7);
    reson = Ringz.ar(hit, 1050 + (ring * 700), 0.2) + Ringz.ar(hit, 1500 + (ring * 1200), 0.18);
    sig = Pan2.ar(reson * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\bouncing_ball, { |out=0, amp=0.26, gate=1, seed=0,
    x=0, y=0, z=0, bounces=0.6, send=0.08, fxBus=2|
    var env, t, decay, freq, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 1.2, 1.0, curve: -3), gate, doneAction:2);
    t = Impulse.kr(2 + (bounces.clip(0, 1) * 10));
    decay = Decay2.kr(t, 0.001, 0.08);
    freq = TExpRand.kr(180, 1100, t);
    sig = SinOsc.ar(freq, 0, decay) + BPF.ar(WhiteNoise.ar(0.1), freq * 2, 0.3) * decay;
    sig = Pan2.ar(sig * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\rolling_can, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, speed=0.5, send=0.14, fxBus=2|
    var env, rumble, clink, trig, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.01, 1.1, 1.0, curve: -3), gate, doneAction:2);
    rumble = LPF.ar(BrownNoise.ar(0.45), 180 + (speed.clip(0, 1) * 500));
    trig = Dust.kr(8 + (speed * 30));
    clink = Ringz.ar(Decay2.kr(trig, 0.001, 0.03) * WhiteNoise.ar(0.7), TExpRand.kr(500, 2800, trig), 0.05);
    sig = Pan2.ar((rumble + clink) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\creaking_door, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, tension=0.6, send=0.12, fxBus=2|
    var env, mod, squeal, grind, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.02, 1.0, 1.0, curve: -2), gate, doneAction:2);
    mod = LFNoise2.kr(1.5).range(0.7, 1.25);
    squeal = SinOsc.ar((520 + (tension * 1200)) * mod, 0, 0.3);
    grind = BPF.ar(PinkNoise.ar(0.45), 400 + (tension * 1200), 0.2);
    sig = Pan2.ar((squeal + grind).tanh * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\boing_spring, { |out=0, amp=0.3, gate=1, seed=0,
    x=0, y=0, z=0, spring=0.6, send=0.12, fxBus=2|
    var env, fEnv, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.001, 0.6, 1.0, curve: -4), gate, doneAction:2);
    fEnv = EnvGen.kr(Env([1.6, 0.7], [0.45], curve: -6), gate);
    sig = SinOsc.ar((180 + (spring.clip(0, 1) * 480)) * fEnv, 0, 0.7)
        + Ringz.ar(Impulse.ar(0), 320 + (spring * 1400), 0.15);
    sig = Pan2.ar(sig * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\fire_loop, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, crackle=0.55, send=0.2, fxBus=2|
    var env, hiss, pops, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.1, 1.0, 0.2), gate, doneAction:2);
    hiss = HPF.ar(WhiteNoise.ar(0.45), 1200) * LFNoise2.kr(1).squared.squared;
    pops = Decay2.ar(Dust2.ar(6 + (crackle.clip(0, 1) * 35)), 0.001, 0.02) * WhiteNoise.ar(0.9);
    sig = Pan2.ar((hiss + pops) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\bubbles_loop, { |out=0, amp=0.16, gate=1, seed=0,
    x=0, y=0, z=0, density=0.45, send=0.16, fxBus=2|
    var env, trig, bubble, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.1, 1.0, 0.2), gate, doneAction:2);
    trig = Dust.kr(3 + (density.clip(0, 1) * 22));
    bubble = SinOsc.ar(TExpRand.kr(180, 1400, trig), 0, Decay2.kr(trig, 0.002, 0.05));
    sig = Pan2.ar(HPF.ar(bubble, 120) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\running_water, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, flow=0.55, send=0.22, fxBus=2|
    var env, n, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.1, 1.0, 0.2), gate, doneAction:2);
    n = PinkNoise.ar(1);
    sig = BPF.ar(n, 500 + (flow.clip(0, 1) * 2200), 0.25) + HPF.ar(n, 1600 + (flow * 1800)) * 0.35;
    sig = Pan2.ar(sig * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\electricity_arc, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, zap=0.7, send=0.14, fxBus=2|
    var env, buzz, sparks, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.01, 1.0, 0.05), gate, doneAction:2);
    buzz = BPF.ar(LFPulse.ar(90 + (zap.clip(0, 1) * 280), 0, 0.22, 0.6), 1800, 0.18);
    sparks = Decay2.ar(Dust2.ar(10 + (zap * 80)), 0.0004, 0.02) * HPF.ar(WhiteNoise.ar(0.8), 2600);
    sig = Pan2.ar((buzz + sparks).tanh * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\motor_loop, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, rpm=0.45, send=0.16, fxBus=2|
    var env, f, hum, noise, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.08, 1.0, 0.18), gate, doneAction:2);
    f = 35 + (rpm.clip(0, 1) * 150);
    hum = SinOsc.ar(f, 0, 0.5) + SinOsc.ar(f * 2, 0, 0.2);
    noise = BPF.ar(PinkNoise.ar(0.35), (f * 8).clip(120, 3200), 0.2);
    sig = Pan2.ar((hum + noise) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\car_passby, { |out=0, amp=0.3, gate=1, seed=0,
    x=0, y=0, z=0, speed=0.6, send=0.2, fxBus=2|
    var env, fEnv, eng, noise, pan, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.03, 1.4, 1.0, curve: -3), gate, doneAction:2);
    fEnv = EnvGen.kr(Env([180, 500 + (speed.clip(0, 1) * 700), 220], [0.45, 0.7], curve: -2), gate);
    eng = Saw.ar(fEnv, 0.3) + SinOsc.ar(fEnv * 0.5, 0, 0.2);
    noise = BPF.ar(WhiteNoise.ar(0.25), fEnv * 2.5, 0.25);
    pan = EnvGen.kr(Env([-1, 1], [1.2], curve: 2), gate);
    sig = Pan2.ar((eng + noise) * amp * env, (x + pan).clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\insects_loop, { |out=0, amp=0.14, gate=1, seed=0,
    x=0, y=0, z=0, density=0.6, send=0.16, fxBus=2|
    var env, chirpTrig, chirp, buzz, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.05, 1.0, 0.1), gate, doneAction:2);
    chirpTrig = Dust.kr(8 + (density.clip(0, 1) * 45));
    chirp = Decay2.kr(chirpTrig, 0.001, 0.03) * SinOsc.ar(TExpRand.kr(2500, 9000, chirpTrig), 0, 0.35);
    buzz = BPF.ar(WhiteNoise.ar(0.1), 4500 + (density * 2500), 0.1);
    sig = Pan2.ar((chirp + buzz) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\transporter_beam, { |out=0, amp=0.24, gate=1, seed=0,
    x=0, y=0, z=0, rise=0.65, send=0.24, fxBus=2|
    var env, f, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.perc(0.01, 1.0, 1.0, curve: -3), gate, doneAction:2);
    f = XLine.kr(160 + (rise * 200), 1800 + (rise * 2600), 0.85);
    sig = SinOsc.ar(f, 0, 0.45) + LFTri.ar(f * 1.33, 0, 0.25);
    sig = Pan2.ar(BPF.ar(sig, f * 1.2, 0.25) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\red_alert_loop, { |out=0, amp=0.22, gate=1, seed=0,
    x=0, y=0, z=0, rate=1.8, send=0.12, fxBus=2|
    var env, pulse, f, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.02, 1.0, 0.08), gate, doneAction:2);
    pulse = LFPulse.kr(rate.clip(0.4, 6), 0, 0.4).lag(0.01);
    f = SelectX.kr(pulse, [540, 780]);
    sig = Pan2.ar(Saw.ar(f, 0.35) * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\r2d2_bleeps, { |out=0, amp=0.2, gate=1, seed=0,
    x=0, y=0, z=0, activity=0.65, send=0.08, fxBus=2|
    var env, trig, f, beep, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.01, 1.0, 0.08), gate, doneAction:2);
    trig = Dust.kr(3 + (activity.clip(0, 1) * 22));
    f = TExpRand.kr(350, 2800, trig);
    beep = Decay2.kr(trig, 0.001, 0.07) * (SinOsc.ar(f, 0, 0.65) + LFTri.ar(f * 1.5, 0, 0.2));
    sig = Pan2.ar(beep * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

SynthDef(\additive_pad, { |out=0, amp=0.15, gate=1, seed=0,
    x=0, y=0, z=0, tone=0.55, send=0.2, fxBus=2|
    var env, f, sig;
    RandSeed.ir(seed);
    env = EnvGen.kr(Env.asr(0.4, 1.0, 0.6), gate, doneAction:2);
    f = 120 + (tone.clip(0, 1) * 260);
    sig = Mix.fill(8, { |i| SinOsc.ar(f * (i + 1), 0, 0.35 / (i + 1)) });
    sig = LPF.ar(sig, 1200 + (tone * 2800));
    sig = Pan2.ar(sig * amp * env, x.clip2(1));
    Out.ar(out, sig); Out.ar(fxBus, sig * send.clip(0, 1));
}).writeDefFile(defsDir);

"Wrote SynthDefs to: ".post; defsDir.postln;
)
