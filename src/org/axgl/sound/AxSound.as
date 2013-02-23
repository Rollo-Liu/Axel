package org.axgl.sound {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;

	import org.axgl.Ax;
	import org.axgl.AxEntity;

	/**
	 * A sound object. For simple use cases, this class will be completely managed by Axel. However,
	 * whenever you play a sound or music you will get the instance of this class returned to you in
	 * order to do more advanced effects.
	 */
	public class AxSound extends AxEntity implements IEventDispatcher {
		/** The internal flash sound object. */
		private var sound:Sound;
		/** The internal flash sound channel. */
		protected var soundChannel:SoundChannel;
		/** The internal flash sound transform. */
		protected var soundTransform:SoundTransform;
		/** EventDispatcher we wrap to implement IEventDispatcher **/
		protected var eventDispatcher:EventDispatcher;

		public static const DESTROYED:String = "destroyed";
		
		/**
		 * The volume of the sound.
		 * @default 1
		 */
		public var volume:Number;
		/**
		 * Whether or not the sound should loop.
		 */
		public var loop:Boolean;
		/**
		 * The time (in ms) of how far into the sound it should start playing.
		 * @default 0
		 */
		public var start:Number;

		/**
		 * Creates a new sound object, but does not start playing the sound.
		 *
		 * @param sound The embedded sound file to play.
		 * @param volume The volume to play the sound at.
		 * @param loop Whether or not the sound should loop.
		 * @param start The time (in ms) of how far into the sound it should start playing.
		 */
		public function AxSound(sound:Class, volume:Number = 1, loop:Boolean = false, start:Number = 0) {
			this.sound = new sound();
			this.volume = volume;
			this.loop = loop;
			this.start = start;
			this.soundTransform = new SoundTransform(volume);
			this.eventDispatcher = new EventDispatcher();
		}

		/**
		 * Plays the sound. If loop is true, will repeat once it reaches the end.
		 *
		 * @return
		 */
		public function play():Boolean {
			soundChannel = sound.play(start, loop ? int.MAX_VALUE : 0, soundTransform);
			//If we failed to play a sound (e.g. run out of available sound channels) soundChannel will be null
			if (soundChannel) {
				soundChannel.addEventListener(Event.SOUND_COMPLETE, onSoundChannelComplete);
				return true;
			} else {
				return false;
			}
		}

		public function get initialized():Boolean {
			return soundChannel != null;
		}

		protected function onSoundChannelComplete(sender:Event):void {
			destroy();
		}

		/**
		 * Destroys the sound, freeing up resources used.
		 */
		override public function destroy():void {
			dispatchEvent(new Event(DESTROYED));
			soundChannel.removeEventListener(Event.SOUND_COMPLETE, onSoundChannelComplete);
			sound = null;
			soundChannel = null;
			soundTransform = null;
			super.destroy();
		}

		/**
		 * @inheritDoc
		 */
		override public function update():void {
			updateVolume();
		}

		/**
		 * Updates the sound transform and sound channel after the volume is changed.
		 */
		protected function updateVolume():void {
			if (!initialized) return;
			soundTransform.volume = Ax.soundMuted ? 0 : volume * Ax.soundVolume;
			soundChannel.soundTransform = soundTransform;
		}

		//Event dispatcher implementation
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, 
		                                 useWeakReference:Boolean = false):void {
			eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}

		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			eventDispatcher.removeEventListener(type, listener, useCapture);
		}

		public function dispatchEvent(event:Event):Boolean {
			return eventDispatcher.dispatchEvent(event);
		}

		public function hasEventListener(type:String):Boolean {
			return eventDispatcher.hasEventListener(type);
		}

		public function willTrigger(type:String):Boolean {
			return eventDispatcher.willTrigger(type);
		}
	}
}
