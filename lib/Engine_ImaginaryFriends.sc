Engine_ImaginaryFriends : CroneEngine {
	var voices;

	alloc {
		SynthDef.new(\friend, {
			arg out,
			t_trigger,
			level = 0.2,
			freq = 440,
			ratio = 0.5,
			index = 1.0,
			time = 1.0,
			shape = 0.1,
			curve = 0,
			pan = 0.5;
			var modulator = SinOsc.ar(freq * ratio) * index;
			var carrier = SinOsc.ar(freq + modulator);
			var envelope = Env.new(
				levels: [0, 1, 0],
				times: [shape * time, 1 - shape * time],
				curve: [curve * -1, curve]
			);
			carrier = carrier * EnvGen.ar(envelope, t_trigger) * level;
			Out.ar(out, Pan2.ar(carrier, pan));
		}).send(context.server);
		
		context.server.sync;
		
		voices = Array.fill(6, {
			Synth.new(\friend);
		});

		context.server.sync;

		this.addCommand(\note, "iff", {
			arg msg;
			voices[msg[1]].set(\freq, msg[2]);
			// TODO: level
			voices[msg[1]].set(\t_trigger, 1.0);
		});

		this.addCommand(\pan, "if", {
			arg msg;
			voices[msg[1]].set(\pan, msg[2]);
		});

		// shape range [0, 1.0]
		this.addCommand(\shape, "f", {
			arg msg;
			voices.do({ |voice| voice.set(\shape, msg[1])});
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