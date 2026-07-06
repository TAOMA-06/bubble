using UnityEngine;

namespace BeadWorks.Feedback
{
    /// <summary>
    /// Short audio cues and light mobile haptics for bead placement interactions.
    /// </summary>
    public class WorkshopFeedback : MonoBehaviour
    {
        [SerializeField] private AudioClip _pickUpClip;
        [SerializeField] private AudioClip _placeClip;
        [SerializeField] private AudioClip _rejectClip;
        [SerializeField] private AudioClip _eraseClip;
        [SerializeField] private float _pickUpVolume = 0.55f;
        [SerializeField] private float _placeVolume = 0.65f;
        [SerializeField] private float _rejectVolume = 0.45f;
        [SerializeField] private float _eraseVolume = 0.5f;

        private AudioSource _audioSource;
        private AudioSource _loopSource;
        private float _sizzleTarget;
        private float _frictionTarget;

        private void Awake()
        {
            _audioSource = gameObject.AddComponent<AudioSource>();
            _audioSource.playOnAwake = false;
            _audioSource.spatialBlend = 0f;

            _loopSource = gameObject.AddComponent<AudioSource>();
            _loopSource.playOnAwake = false;
            _loopSource.spatialBlend = 0f;
            _loopSource.loop = true;
            _loopSource.clip = CreateSizzleLoop();
            _loopSource.volume = 0f;

            _pickUpClip ??= CreateTone(920f, 0.04f);
            _placeClip ??= CreateTone(640f, 0.05f);
            _rejectClip ??= CreateTone(280f, 0.07f);
            _eraseClip ??= CreateTone(480f, 0.04f);
        }

        private void Update()
        {
            if (_loopSource == null)
            {
                return;
            }

            var targetVolume = Mathf.Clamp01(_sizzleTarget * 0.35f + Mathf.Clamp01(_frictionTarget * 0.08f) * 0.25f);
            _loopSource.volume = Mathf.Lerp(_loopSource.volume, targetVolume, Time.deltaTime * 8f);
            _loopSource.pitch = 0.85f + (_sizzleTarget * 0.35f) + (Mathf.Clamp01(_frictionTarget * 0.05f) * 0.2f);

            if (targetVolume > 0.02f && !_loopSource.isPlaying)
            {
                _loopSource.Play();
            }
            else if (targetVolume <= 0.02f && _loopSource.isPlaying)
            {
                _loopSource.Stop();
            }

            _sizzleTarget = Mathf.Lerp(_sizzleTarget, 0f, Time.deltaTime * 4f);
            _frictionTarget = Mathf.Lerp(_frictionTarget, 0f, Time.deltaTime * 6f);
        }

        public void PlayPickUp() => Play(_pickUpClip, _pickUpVolume);

        public void PlayPlace() => Play(_placeClip, _placeVolume);

        public void PlayReject() => Play(_rejectClip, _rejectVolume);

        public void PlayErase() => Play(_eraseClip, _eraseVolume);

        public void UpdateIroningAudio(float sizzleIntensity, float moveSpeed)
        {
            _sizzleTarget = Mathf.Max(_sizzleTarget, sizzleIntensity);
            _frictionTarget = Mathf.Max(_frictionTarget, moveSpeed);
        }

        public void StopIroningAudio()
        {
            _sizzleTarget = 0f;
            _frictionTarget = 0f;
        }

        public void LightHaptic()
        {
#if UNITY_IOS || UNITY_ANDROID
            if (Application.isMobilePlatform)
            {
                Handheld.Vibrate();
            }
#endif
        }

        private void Play(AudioClip clip, float volume)
        {
            if (clip == null || _audioSource == null)
            {
                return;
            }

            _audioSource.PlayOneShot(clip, volume);
        }

        private static AudioClip CreateTone(float frequency, float duration)
        {
            const int sampleRate = 44100;
            var sampleCount = Mathf.Max(1, Mathf.RoundToInt(sampleRate * duration));
            var samples = new float[sampleCount];

            for (var i = 0; i < sampleCount; i++)
            {
                var t = i / (float)sampleRate;
                var envelope = 1f - (i / (float)sampleCount);
                samples[i] = Mathf.Sin(2f * Mathf.PI * frequency * t) * envelope * 0.35f;
            }

            var clip = AudioClip.Create($"Tone_{frequency}", sampleCount, 1, sampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }

        private static AudioClip CreateSizzleLoop()
        {
            const int sampleRate = 44100;
            const float duration = 0.35f;
            var sampleCount = Mathf.RoundToInt(sampleRate * duration);
            var samples = new float[sampleCount];

            for (var i = 0; i < sampleCount; i++)
            {
                var t = i / (float)sampleRate;
                var noise = (Random.value * 2f) - 1f;
                var tone = Mathf.Sin(2f * Mathf.PI * 180f * t) * 0.15f;
                var envelope = 0.65f + (Mathf.Sin(t * 40f) * 0.2f);
                samples[i] = (noise * 0.22f + tone) * envelope;
            }

            var clip = AudioClip.Create("IronSizzleLoop", sampleCount, 1, sampleRate, false);
            clip.SetData(samples, 0);
            return clip;
        }
    }
}
