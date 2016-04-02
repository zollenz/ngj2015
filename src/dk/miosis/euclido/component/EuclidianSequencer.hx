package dk.miosis.euclido.component;

import luxe.Log.*;
import luxe.options.ComponentOptions;
import luxe.resource.Resource.AudioResource;

import dk.miosis.euclido.component.EuclidianVisualiser;
import dk.miosis.euclido.utility.EuclidianRhythmGenerator;
import dk.miosis.euclido.utility.MiosisUtilities;

class EuclidianSequencer extends luxe.Component
{
    var _note_masks:Array<Int>;
    var _note_offsets:Array<Float>;
    var _sounds:Array<AudioResource>;

    var _current_time:Float;
    var _note_time:Float;
    var _time_per_bar:Float;
    var _next_note:Int;
    var _test_note_mask:Int;
    
    public var note_count(default, null):Int;

    public function new(sound_count:Int, tempo:Int, note_count:Int, ?_options:ComponentOptions) 
    {
        _debug("---------- Sequencer.new ----------");

        if (_options == null) 
        {
            _options = { name : "euclidian_sequencer_component"};
        } 
        else if (_options.name == null)
        {
            _options.name = "euclidian_sequencer_component";
        }

        _next_note = 0;
        _current_time = 0.0;
        
        _note_offsets = new Array<Float>();
        _note_masks = new Array<Int>();

        this.note_count = note_count;

        _note_time = 60 / (tempo * (note_count / 4));

        _time_per_bar = _note_time * note_count;

        var min_note_time = 1 / 60;

        _debug("min_note_time = " + min_note_time);
        _debug("_note_time = " + _note_time);        

        if (_note_time < min_note_time)
        {
            _debug("Framerate too low for tempo");
        }

        for (i in 0...note_count)
        {
            _note_offsets.push(i * _note_time);
        }

        log(_note_offsets);

        // Init sounds

        _sounds = new Array<AudioResource>();

        for (i in 0...sound_count)
        {
            var resource = Luxe.resources.audio('assets/audio/sound_' + i + '.wav');
            _sounds.push(resource);
        }

        log(_sounds);

        var rhythm_generator = new EuclidianRhythmGenerator();

        rhythm_generator.generate(16, 4);
        _note_masks.push(rhythm_generator.get_bitmask());

        rhythm_generator.generate(16, 2);
        _note_masks.push(rhythm_generator.get_bitmask());

        rhythm_generator.generate(16, 8);
        _note_masks.push(rhythm_generator.get_bitmask());

        rhythm_generator.generate(16, 3);
        _note_masks.push(rhythm_generator.get_bitmask());

        _debug(_note_masks);

        super(_options);
    }

    override public function update(dt:Float):Void 
    {
        var epsilon = 0.1;

        if (_current_time >= _note_offsets[_next_note] - epsilon && _current_time <= _note_offsets[_next_note] + epsilon)
        {
            log("TICK " + _next_note);

            for (i in 0..._sounds.length)
            {
                if (_note_masks[i] != 0 && should_play_note(i, _next_note))
                {
                    _debug("Playing sound " + i);

                    var handle = Luxe.audio.play(_sounds[i].source);

                    if (i == 3)
                    {
                        Luxe.audio.volume(handle, 0.1);
                    }
                }
            }

            if (++_next_note == note_count)
            {
                _next_note = 0;
            }            
        }

        _current_time += dt;

        if (_current_time >= _time_per_bar)
        {
            _current_time = 0.0;
        }

        super.update(dt);
    }

    override public function onremoved():Void 
    {
        MiosisUtilities.clear(_note_offsets);
        _note_offsets = null;
        
        MiosisUtilities.clear(_note_masks);
        _note_masks = null;        

        for (i in 0..._sounds.length)
        {
            _sounds[i];
        }

        MiosisUtilities.clear(_sounds);
        _sounds = null;
    }

    public function get_current_cycle_ratio(sound_id):Float
    {
        return _current_time / _time_per_bar;
    }

    function should_play_note(soundIndex:Int, note:Int):Bool
    {
        log(_note_masks[soundIndex]);
        return (_note_masks[soundIndex] & (32768 >> note)) > 0;
    }
}