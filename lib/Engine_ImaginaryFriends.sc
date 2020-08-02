Engine_ImaginaryFriends : CroneEngine {
	var voices;

	alloc {
		SynthDef.new(\friend, {
			arg out,
				t_trigger,
				level = 1,
				freq = 440,
				ratio = 0.5,
				index = 1.0,
				time = 1.0,
				curve = 0.0,
				ramp = 0.5,
				pan = 0.0;
			var modulator = SinOsc.ar(freq * ratio) * index;
			var envelope = EnvGen.ar(Env.perc(0.005, time), t_trigger) * level;
			var tri = VarSaw.ar(freq * (1 + modulator), 0.0, ramp);
			var pulse = (Slope.ar(tri) > 0.0);
			var scaled_curve = K2A.ar(curve.clip(-1, 0.5).abs.lincurve(0, 1, 0, 80, 6) * curve.sign);
			var curve1 = tri.lincurve(-1, 1, -1, 1, scaled_curve.neg);
			var curve2 = tri.lincurve(-1, 1, -1, 1, scaled_curve);
			var blend = Select.ar(pulse, [curve1, curve2]);
			blend = LinSelectX.ar(curve.linlin(0.5, 1, 0, 1), [
				blend,
				(tri * 2.1).tanh
			]);
			blend = blend * envelope;
			blend = RLPF.ar(blend, envelope.linexp(0, 1, 2000, SampleRate.ir * 0.4));
			Out.ar(out, Pan2.ar(blend * 0.2, pan));
		}).send(context.server);
		
		context.server.sync;
		
		voices = Array.fill(6, {
			Synth.new(\friend);
		});

		context.server.sync;

		this.addCommand(\note, "iff", {
			arg msg;
			voices[msg[1] - 1].set(\freq, msg[2]);
			// TODO: level
			voices[msg[1] - 1].set(\t_trigger, 1.0);
		});

		this.addCommand(\pan, "if", {
			arg msg;
			voices[msg[1] - 1].set(\pan, msg[2]);
		});

		// ramp range [0, 1.0]
		this.addCommand(\ramp, "f", {
			arg msg;
			voices.do({ |voice| voice.set(\ramp, msg[1])});
		});
		
		// time
		this.addCommand(\time, "f", {
			arg msg;
			voices.do({ |voice| voice.set(\time, msg[1])});
		});

		// curve range [-1.0, 1.0]
		this.addCommand(\curve, "f", {
			arg msg;
			voices.do({ |voice| voice.set(\curve, msg[1])});
		});

		// ratio
		this.addCommand(\ratio, "f", {
			arg msg;
			voices.do({ |voice| voice.set(\ratio, msg[1])});
		});

		// index
		this.addCommand(\index, "f", {
			arg msg;
			voices.do({ |voice| voice.set(\index, msg[1])});
		});
	}

	free {
		voices.do({ |synth| synth.free; })
	}
}