/*
    Game Audio Engine - SuperCollider Audio Plane
    - keeps DSP in scsynth
    - stable params: amp, gate, seed, x, y, z, send, fxBus
*/

(
s.waitForBoot {
    // Audio buses
    ~dryBus = Bus.audio(s, 2);
    ~fxBus = Bus.audio(s, 2);

    // Stem gain controls (mapped by JUCE /mix/bus -> /c_set)
    ~cMusic = Bus.control(s, 1);  ~cMusic.set(1.0);
    ~cUi    = Bus.control(s, 1);  ~cUi.set(1.0);
    ~cAmb   = Bus.control(s, 1);  ~cAmb.set(1.0);
    ~cDry   = Bus.control(s, 1);  ~cDry.set(1.0);
    ~cFx    = Bus.control(s, 1);  ~cFx.set(1.0);

    SynthDef(\proc_hit, { |out=0, amp=0.2, gate=1, seed=0,
        x=0, y=0, z=0, bright=0.5, size=0.5, damp=0.3, send=0.15, fxBus=2|
        var env, n, body, click, sig;

        RandSeed.ir(seed);

        env = EnvGen.kr(Env.asr(0.001, 1.0, 0.08), gate, doneAction:2);
        click = HPF.ar(Impulse.ar(0) + Dust2.ar(3000 * bright), 1500) * 0.1;
        n = PinkNoise.ar(1) * (0.15 + (0.75 * bright));

        body = DynKlank.ar(
            `[
                Array.exprand(8, 80, 2200) * (0.6 + (0.8 * size)),
                Array.fill(8, { 0.05 + 0.2.rand }),
                Array.exprand(8, 0.03, 0.25) * (0.3 + (1.2 * (1 - damp)))
            ],
            (n + click) * 0.7
        );

        sig = tanh(body) * amp * env;
        sig = Balance2.ar(sig, sig, x.clip2(1));
        sig = LPF.ar(sig, (4000 + (z.clip2(1) * 3000)).clip(300, 12000));

        Out.ar(out, sig);
        Out.ar(fxBus, sig * send);
    }).add;

    SynthDef(\fx_verb, { |inBus=2, out=0, wet=0.25, rt=2.0|
        var in, v, mixed;
        in = In.ar(inBus, 2);
        v = JPverb.ar(in, t60: rt, damp: 0.5, size: 1.5);
        mixed = XFade2.ar(in, v, (wet * 2) - 1);
        Out.ar(out, mixed);
    }).add;

    // Launch default global return.
    ~verb = Synth(\fx_verb, [\inBus, ~fxBus.index, \out, 0, \wet, 0.2, \rt, 2.3]);

    "EngineLib ready".postln;
};
)
